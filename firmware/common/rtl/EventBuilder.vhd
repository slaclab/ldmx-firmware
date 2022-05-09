-------------------------------------------------------------------------------
-- Title      : HPS Event Builder
-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Takes data from multiple APV data processing pipelines and
-- formats into an event frame.
-------------------------------------------------------------------------------
-- This file is part of HPS. It is subject to
-- the license terms in the LICENSE.txt file found in the top-level directory
-- of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of HPS, including this file, may be
-- copied, modified, propagated, or distributed except according to the terms
-- contained in the LICENSE.txt file.
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


library surf;
use surf.StdRtlPkg.all;
use surf.AxiStreamPkg.all;
use surf.AxiLitePkg.all;
use surf.SsiPkg.all;


library ldmx;
use ldmx.HpsPkg.all;
use ldmx.DataPathPkg.all;
use ldmx.FebConfigPkg.all;

entity EventBuilder is

   generic (
      TPD_G             : time                  := 1 ns;
      HYBRIDS_G         : natural range 1 to 12 := 4;
      APVS_PER_HYBRID_G : natural               := 5);

   port (
      sysClk         : in sl;
      sysRst         : in sl;
      sysPipelineRst : in sl := '0';

      -- Axi Bus for status and debug
      axiReadMaster  : in  AxiLiteReadMasterType  := AXI_LITE_READ_MASTER_INIT_C;
      axiReadSlave   : out AxiLiteReadSlaveType;
      axiWriteMaster : in  AxiLiteWriteMasterType := AXI_LITE_WRITE_MASTER_INIT_C;
      axiWriteSlave  : out AxiLiteWriteSlaveType;

      trigger          : in  sl;
      triggerFifoValid : in  sl;
      triggerFifoData  : in  slv(63 downto 0);
      triggerFifoRdEn  : out sl;

      febConfig : in FebConfigType;

      dataPathOut : in  DataPathOutArray(HYBRIDS_G-1 downto 0);
      dataPathIn  : out DataPathInArray(HYBRIDS_G-1 downto 0);

      eventAxisMaster : out AxiStreamMasterType;
      eventAxisSlave  : in  AxiStreamSlaveType;
      eventAxisCtrl   : in  AxiStreamCtrlType);

end entity EventBuilder;

architecture rtl of EventBuilder is

   constant APV_STREAMS_C        : natural := HYBRIDS_G * 5;  -- 5 APVs per hybrid
   constant ALL_HEADER_TIMEOUT_C : natural := 100;
   constant ALL_DATA_TIMEOUT_C   : natural := 50000;

   subtype ApvSlv is slv(APVS_PER_HYBRID_G-1 downto 0);
   type HybridSlv is array (HYBRIDS_G-1 downto 0) of ApvSlv;

   type StateType is (WAIT_TRIGGER_S, DO_DATA_S, EOF_S, FROZEN_S);

   type RegType is record
      state                  : StateType;
      triggerFifoRdEn        : sl;
      runTime                : slv(31 downto 0);
      rollover               : sl;
      apvNum                 : integer range 0 to APVS_PER_HYBRID_G-1;
      hybridNum              : integer range 0 to HYBRIDS_G;
      allValid               : sl;
      anyValid               : sl;
      allHead                : sl;
      anyHead                : sl;
      allTails               : sl;
      gotApvBufferAddresses  : sl;
      syncError              : sl;
      syncErrorLatch         : sl;
      syncErrorCount         : slv(15 downto 0);
      burnFrame              : sl;
      eventCount             : slv(31 downto 0);
      burnCount              : slv(15 downto 0);  -- Number of EOFE frames
      gotHeadError           : sl;
      headerMode             : slv(1 downto 0);
      headErrorCount         : slv(15 downto 0);
      eventErrorCount        : slv(15 downto 0);
      maxSampleCount         : slv(11 downto 0);
      maxTriggersOutstanding : slv(5 downto 0);
      dataPathEn             : slv(3 downto 0);
      sampleCount            : slv(11 downto 0);
      sampleCountLast        : slv(11 downto 0);
      peakOccupancy          : slv(11 downto 0);
      skipCount              : slv(11 downto 0);
      gotTail                : HybridSlv;
      apvBufferAddresses     : slv8Array(5 downto 0);

      -- Outputs
      eventSsiMaster : SsiMasterType;
      dataPathIn     : DataPathInArray(HYBRIDS_G-1 downto 0);

      axiReadSlave  : AxiLiteReadSlaveType;
      axiWriteSlave : AxiLiteWriteSlaveType;
      sofCount      : slv(15 downto 0);
      eofCount      : slv(15 downto 0);
   end record RegType;

   constant REG_INIT_C : RegType := (
      state                  => WAIT_TRIGGER_S,
      triggerFifoRdEn        => '0',
      runTime                => (others => '0'),
      rollover               => '0',
      apvNum                 => 0,
      hybridNum              => 0,
      allValid               => '0',
      anyValid               => '0',
      allHead                => '0',
      anyHead                => '0',
      allTails               => '0',
      gotApvBufferAddresses  => '0',
      syncError              => '0',
      syncErrorLatch         => '0',
      syncErrorCount         => (others => '0'),
      burnFrame              => '0',
      eventCount             => toSlv(1, 32),
      burnCount              => (others => '0'),
      gotHeadError           => '0',
      headerMode             => (others => '0'),
      headErrorCount         => (others => '0'),
      eventErrorCount        => (others => '0'),
      maxSampleCount         => X"FFF",  -- sampleCountLimit
      maxTriggersOutstanding => (others => '0'),
      dataPathEn             => X"F",
      sampleCount            => (others => '0'),
      sampleCountLast        => (others => '0'),
      peakOccupancy          => (others => '0'),
      skipCount              => (others => '0'),
      gotTail                => (others => (others => '0')),
      apvBufferAddresses     => (others => (others => '0')),
      eventSsiMaster         => ssiMasterInit(EVENT_SSI_CONFIG_C),
      dataPathIn             => (others => (others => '0')),
      axiReadSlave           => AXI_LITE_READ_SLAVE_INIT_C,
      axiWriteSlave          => AXI_LITE_WRITE_SLAVE_INIT_C,
      sofCount               => (others => '0'),
      eofCount               => (others => '0'));

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal eventSsiSlave : SsiSlaveType;

--   signal triggersOutstanding : slv(5 downto 0);

begin

   -- Convert AXIS bus into SSI Bus
   eventSsiSlave <= axis2SsiSlave(EVENT_SSI_CONFIG_C, eventAxisSlave, eventAxisCtrl);

   comb : process (axiReadMaster, axiWriteMaster, dataPathOut, eventSsiSlave, r, febConfig,
                   sysPipelineRst, sysRst, triggerFifoData) is
      variable v         : RegType;
      variable apvInt    : natural;
      variable hybridInt : natural;
      variable axiEp     : AxiLiteEndpointType;

   begin
      v := r;

      v.runTime := r.runTime + 1;

      ----------------------------------------------------------------------------------------------
      -- Cycle through each apv/hybrid in round robin fashion
      ----------------------------------------------------------------------------------------------
      v.rollover := '0';
      v.apvNum   := r.apvNum + 1;
      if (r.apvNum = APVS_PER_HYBRID_G-1) then
         v.apvNum    := 0;
         v.hybridNum := r.hybridNum + 1;
         if (r.hybridNum = HYBRIDS_G-1) then
            v.hybridNum := 0;
            v.rollover  := '1';
         end if;
      end if;

      ----------------------------------------------------------------------------------------------
      -- Determine if any or all enabled apv streams have data and header
      ----------------------------------------------------------------------------------------------
      v.allValid := '1';
      v.anyValid := '0';
      v.allHead  := '1';
      v.anyHead  := '0';
      v.allTails := '1';
      for hybrid in HYBRIDS_G-1 downto 0 loop
         for apv in APVS_PER_HYBRID_G-1 downto 0 loop
            if (dataPathOut(hybrid)(apv).valid = '0') then
               v.allValid := '0';
            else
               v.anyValid := '1';
            end if;
            if (dataPathOut(hybrid)(apv).head = '0') then
               v.allHead := '0';
            else
               v.anyHead := '1';
            end if;
            if (r.gotTail(hybrid)(apv) = '0') then
               v.allTails := '0';
            end if;
         end loop;
      end loop;

      -- By default, don't output anything to event buffer
      v.eventSsiMaster  := ssiMasterInit(EVENT_SSI_CONFIG_C);
      v.dataPathIn      := (others => (others => '0'));
      v.triggerFifoRdEn := '0';
--      v.gotApvBufferAddresses := '0';

      -- Latch for sync erros
      if (r.syncError = '1') then
         v.syncErrorLatch := '1';
      end if;

--       if (triggersOutstanding > r.maxTriggersOutstanding and triggerFifoEmpty = '0') then
--          v.maxTriggersOutstanding := triggersOutstanding;
--       end if;

      if (r.sampleCountLast > r.peakOccupancy) then
         v.peakOccupancy := r.sampleCountLast;
      end if;


      ----------------------------------------------------------------------------------------------
      -- Main State Machine
      ----------------------------------------------------------------------------------------------
      case (r.state) is
         when WAIT_TRIGGER_S =>
            -- Wait for any headers to be ready before starting
            v.syncError             := '0';
            v.burnFrame             := '0';
            v.gotTail               := (others => (others => '0'));
            v.gotApvBufferAddresses := '0';
            v.sampleCount           := (others => '0');
            v.skipCount             := (others => '0');
            v.gotHeadError          := '0';
            if (r.anyValid = '1') then
               -- Put data on both low 32 bit words
               v.eventSsiMaster.data(31 downto 0)   := r.eventCount;
               v.eventSsiMaster.data(55 downto 32)  := triggerFifoData(23 downto 0);
               v.eventSsiMaster.data(87 downto 64)  := triggerFifoData(47 downto 24);
               v.eventSsiMaster.data(103 downto 96) := (others => '0');  -- Was RCE address,
                                                                        -- probably no longer
                                                                        -- needed
              v.eventSsiMaster.data(127 downto 104) := (others => '0');
               v.eventSsiMaster.keep(15 downto 0) := X"FFFF";
               v.eventSsiMaster.sof               := '1';
               v.eventSsiMaster.valid             := '1';
               v.eventCount                       := r.eventCount + 1;
               v.hybridNum                        := 0;

               v.state := DO_DATA_S;    --WAIT_ALL_SAMPLE_HEADERS_S;

               v.sofCount := r.sofCount + 1;
            end if;


         when DO_DATA_S =>
            if (eventSsiSlave.pause = '1') then
               v.burnFrame := '1';
            end if;

            if (dataPathOut(r.hybridNum)(r.apvNum).valid = '1' and
                r.gotTail(r.hybridNum)(r.apvNum) = '0') then

               v.eventSsiMaster.data(127 downto 0) := toSlv(dataPathOut(r.hybridNum)(r.apvNum))(127 downto 0);
               v.dataPathIn(r.hybridNum)(r.apvNum) := '1';

               v.eventSsiMaster.valid := '1';
               if (r.dataPathEn(r.hybridNum) = '0' or
                   ((dataPathOut(r.hybridNum)(r.apvNum).head = '1' or dataPathOut(r.hybridNum)(r.apvNum).tail = '1') and
                    dataPathOut(r.hybridNum)(r.apvNum).filter = '1')) then
                  v.eventSsiMaster.valid := '0';
               end if;

               if (v.eventSsiMaster.valid = '1') then
                  if (r.burnFrame = '1' or r.sampleCount = r.maxSampleCount) then
                     v.skipCount            := r.skipCount + 1;
                     v.eventSsiMaster.valid := '0';
                  else
                     v.sampleCount := r.sampleCount + 1;
                  end if;
               end if;

               -- If header, check apv buffer addresses against last header
               -- Remove all headers from event stream if headerMode(1) set.
               -- Remove all but one header from data stream of headerMode(0) set.
               if (dataPathOut(r.hybridNum)(r.apvNum).head = '1' and dataPathOut(r.hybridNum)(r.apvNum).readError = '0' and
                   dataPathOut(r.hybridNum)(r.apvNum).filter = '0') then
                  v.gotApvBufferAddresses := '1';
                  if (r.headerMode(1) = '1') then
                     v.eventSsiMaster.valid := '0';
                     v.sampleCount          := r.sampleCount;
                  end if;
                  for i in 5 downto 0 loop
                     v.apvBufferAddresses(i) := dataPathOut(r.hybridNum)(r.apvNum).data(i)(8 downto 1);
                     if (r.gotApvBufferAddresses = '1') then
                        if (r.headerMode(1) = '1' or r.headerMode(0) = '1') then
                           v.eventSsiMaster.valid := '0';
                           v.sampleCount          := r.sampleCount;
                        end if;
                        if (r.apvBufferAddresses(i) /= dataPathOut(r.hybridNum)(r.apvNum).data(i)(8 downto 1)) then
                           v.syncError      := '1';
                           v.syncErrorCount := r.syncErrorCount + 1;
                        end if;
                     end if;
                  end loop;
               end if;

               -- If tail, mark apv channel as being done
               -- Don't put tail samples in data stream
               if (dataPathOut(r.hybridNum)(r.apvNum).tail = '1') then
                  v.gotTail(r.hybridNum)(r.apvNum) := '1';
                  v.sampleCount                    := r.sampleCount;
                  v.skipCount                      := r.skipCount;
                  v.eventSsiMaster.valid           := '0';
               end if;

               -- Count error headers
               if (dataPathOut(r.hybridNum)(r.apvNum).head = '1' and dataPathOut(r.hybridNum)(r.apvNum).readError = '1') then
                  v.headErrorCount := r.headErrorCount + 1;
                  if (r.headErrorCount = X"FFFF") then
                     v.headErrorCount := X"FFFF";
                  end if;

                  v.gotHeadError := '1';
                  if (r.gotHeadError = '0') then
                     v.eventErrorCount := r.eventErrorCount + 1;
                     if (r.eventErrorCount = X"FFFF") then
                        v.eventErrorCount := X"FFFF";
                     end if;
                  end if;
               end if;

            end if;

            if (r.allTails = '1') then
               v.state := EOF_S;
            end if;

         when EOF_S =>
            v.eventSsiMaster.valid              := '1';
            v.eventSsiMaster.eof                := '1';
            v.eventSsiMaster.eofe               := r.burnFrame;
            v.eventSsiMaster.data(11 downto 0)  := r.sampleCount;
            v.eventSsiMaster.data(23 downto 12) := r.skipCount;
            v.eventSsiMaster.data(24)           := '0';
            v.eventSsiMaster.data(25)           := '0';
            v.eventSsiMaster.data(26)           := r.syncError;
            v.eventSsiMaster.data(27)           := r.burnFrame;
            v.eventSsiMaster.keep(15 downto 0)  := X"FFFF";
            v.gotTail                           := (others => (others => '0'));
            v.state                             := WAIT_TRIGGER_S;
            v.eofCount                          := r.eofCount + 1;
            v.sampleCountLast                   := r.sampleCount;
            v.triggerFifoRdEn                   := '1';
            if (r.burnFrame = '1') then
               v.burnCount := r.burnCount + 1;
            end if;

            v.syncError := '0';
--             if (r.syncError = '1') then
--                v.state := FROZEN_S;
--             end if;

         when FROZEN_S =>
            v.state := FROZEN_S;

      end case;

      -- Dont let error count roll over
      if (r.syncErrorCount = X"FFFF") then
         v.syncErrorCount := r.syncErrorCount;
      end if;

      -- In case of sysPipeline reset, reset all registers except AXI
      if (sysPipelineRst = '1') then
         v                := REG_INIT_C;
         v.axiWriteSlave  := r.axiWriteSlave;
         v.axiReadSlave   := r.axiReadSlave;
         v.maxSampleCount := r.maxSampleCount;
         v.dataPathEn     := r.dataPathEn;
         v.headerMode     := r.headerMode;
      end if;

      ----------------------------------------------------------------------------------------------
      -- Axi Lite Interface
      ----------------------------------------------------------------------------------------------
      axiSlaveWaitTxn(axiEp, axiWriteMaster, axiReadMaster, v.axiWriteSlave, v.axiReadSlave);

      v.axiReadSlave.rdata := (others => '0');

      axiSlaveRegisterR(axiEp, X"00", 0, ite(r.state = WAIT_TRIGGER_S, "00",
                                             ite(r.state = DO_DATA_S, "01",
                                                 ite(r.state = EOF_S, "10",
                                                     ite(r.state = FROZEN_S, "11", "00")))));

      axiSlaveRegisterR(axiEp, X"04", 0, toSlv(r.apvNum, 3));
      axiSlaveRegisterR(axiEp, X"04", 10, toSlv(r.hybridNum, 4));
      axiSlaveRegisterR(axiEp, X"04", 5, r.allValid);
      axiSlaveRegisterR(axiEp, X"04", 6, r.anyValid);
      axiSlaveRegisterR(axiEp, X"04", 7, r.allHead);
      axiSlaveRegisterR(axiEp, X"04", 8, r.anyHead);
      axiSlaveRegisterR(axiEp, X"04", 9, r.allTails);
      axiSlaveRegisterR(axiEp, X"08", 0, r.eventCount);
      axiSlaveRegisterR(axiEp, X"0C", 0, r.sampleCount);

      for i in 0 to HYBRIDS_G-1 loop
         axiSlaveRegisterR(axiEp, X"40", i*8, r.gotTail(i));
      end loop;

      axiSlaveRegisterR(axiEp, X"14", 0, r.sofCount);
      axiSlaveRegisterR(axiEp, X"18", 0, r.eofCount);
      axiSlaveRegister(axiEp, X"1C", 0, v.maxSampleCount);
      axiSlaveRegister(axiEp, X"1C", 12, v.dataPathEn);
      axiSlaveRegister(axiEp, X"1C", 16, v.headerMode);
      axiSlaveRegisterR(axiEp, X"20", 0, r.burnCount);
      axiSlaveRegisterR(axiEp, X"24", 0, r.sampleCountLast);
      axiSlaveRegisterR(axiEp, X"24", 12, r.syncErrorLatch);
      axiSlaveRegisterR(axiEp, X"28", 0, r.headErrorCount);
      axiSlaveRegisterR(axiEp, X"28", 16, r.eventErrorCount);
--       axiSlaveRegisterR(axiEp, X"2C", 0, triggersOutstanding);
--       axiSlaveRegisterR(axiEp, X"2C", 16, r.maxTriggersOutstanding);
      axiSlaveRegisterR(axiEp, X"30", 0, r.peakOccupancy);
      axiSlaveRegisterR(axiEp, X"34", 0, r.syncErrorCount);

      axiSlaveDefault(axiEp, v.axiWriteSlave, v.axiReadSlave, AXI_RESP_DECERR_C);

      ----------------------------------------------------------------------------------------------
      -- Reset and outputs
      ----------------------------------------------------------------------------------------------
      if (sysRst = '1') then
         v := REG_INIT_C;
      end if;

      rin <= v;

      eventAxisMaster <= ssi2AxisMaster(EVENT_SSI_CONFIG_C, r.eventSsiMaster);
      dataPathIn      <= r.dataPathIn;
      axiWriteSlave   <= r.axiWriteSlave;
      axiReadSlave    <= r.axiReadSlave;
      triggerFifoRdEn <= r.triggerFifoRdEn;

   end process comb;

   sync : process (sysClk) is
   begin
      if (rising_edge(sysClk)) then
         r <= rin after TPD_G;
      end if;
   end process sync;

end architecture rtl;
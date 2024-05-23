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
use surf.SsiPkg.all;
use surf.AxiLitePkg.all;

library ldmx_tracker;
use ldmx_tracker.LdmxPkg.all;
use ldmx_tracker.DataPathPkg.all;
use ldmx_tracker.FebConfigPkg.all;

library ldmx_tdaq;
use ldmx_tdaq.FcPkg.all;

entity EventBuilder is

   generic (
      TPD_G             : time                  := 1 ns;
      HYBRIDS_G         : natural range 1 to 12 := 8;
      APVS_PER_HYBRID_G : natural               := 6);

   port (
      axilClk         : in sl;
      axilRst         : in sl;
      axilPipelineRst : in sl := '0';

      -- Axi Bus for status and debug
      axiReadMaster  : in  AxiLiteReadMasterType  := AXI_LITE_READ_MASTER_INIT_C;
      axiReadSlave   : out AxiLiteReadSlaveType;
      axiWriteMaster : in  AxiLiteWriteMasterType := AXI_LITE_WRITE_MASTER_INIT_C;
      axiWriteSlave  : out AxiLiteWriteSlaveType;

      rorFifoTimestamp : in FcTimestampType;
      rorFifoRdEn      : out sl;

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

   type StateType is (
      WAIT_ROR_S,
      HEADER_TIMESTAMP_S,
      HEADER_FC_MSG_S,
      WAIT_ALL_VALID_S,
      DO_DATA_S,
      EOF_S,
      DONE_FRAME_S);

   type RegType is record
      state                 : StateType;
      rorFifoRdEn           : sl;
      runTime               : slv(31 downto 0);
      rollover              : sl;
      apvNum                : integer range 0 to APVS_PER_HYBRID_G;
      hybridNum             : integer range 0 to HYBRIDS_G;
      allValid              : sl;
      anyValid              : sl;
      allHead               : sl;
      anyHead               : sl;
      allTails              : sl;
      gotApvBufferAddresses : sl;
      syncError             : sl;
      syncErrorLatch        : sl;
      syncErrorCount        : slv(15 downto 0);
      burnFrame             : sl;
      eventCount            : slv(31 downto 0);
      burnCount             : slv(15 downto 0);  -- Number of EOFE frames
      gotHeadError          : sl;
      headerMode            : slv(1 downto 0);
      headErrorCount        : slv(15 downto 0);
      eventErrorCount       : slv(15 downto 0);
      maxSampleCount        : slv(15 downto 0);
      maxRorsOutstanding    : slv(5 downto 0);
      dataPathEn            : slv(HYBRIDS_G-1 downto 0);
      sampleCount           : slv(15 downto 0);
      sampleCountLast       : slv(15 downto 0);
      peakOccupancy         : slv(15 downto 0);
      skipCount             : slv(15 downto 0);
      gotTail               : HybridSlv;
      apvBufferAddresses    : slv8Array(2 downto 0);

      -- Outputs
      eventAxisMaster : AxiStreamMasterType;
      dataPathIn      : DataPathInArray(HYBRIDS_G-1 downto 0);

      axiReadSlave  : AxiLiteReadSlaveType;
      axiWriteSlave : AxiLiteWriteSlaveType;
      sofCount      : slv(15 downto 0);
      eofCount      : slv(15 downto 0);
   end record RegType;

   constant REG_INIT_C : RegType := (
      state                 => WAIT_ROR_S,
      rorFifoRdEn           => '0',
      runTime               => (others => '0'),
      rollover              => '0',
      apvNum                => 0,
      hybridNum             => 0,
      allValid              => '0',
      anyValid              => '0',
      allHead               => '0',
      anyHead               => '0',
      allTails              => '0',
      gotApvBufferAddresses => '0',
      syncError             => '0',
      syncErrorLatch        => '0',
      syncErrorCount        => (others => '0'),
      burnFrame             => '0',
      eventCount            => toSlv(1, 32),
      burnCount             => (others => '0'),
      gotHeadError          => '0',
      headerMode            => (others => '0'),
      headErrorCount        => (others => '0'),
      eventErrorCount       => (others => '0'),
      maxSampleCount        => (others => '1'),
      maxRorsOutstanding    => (others => '0'),
      dataPathEn            => (others => '1'),
      sampleCount           => (others => '0'),
      sampleCountLast       => (others => '0'),
      peakOccupancy         => (others => '0'),
      skipCount             => (others => '0'),
      gotTail               => (others => (others => '0')),
      apvBufferAddresses    => (others => (others => '0')),
      eventAxisMaster       => axiStreamMasterInit(EVENT_SSI_CONFIG_C),
      dataPathIn            => (others => (others => '0')),
      axiReadSlave          => AXI_LITE_READ_SLAVE_INIT_C,
      axiWriteSlave         => AXI_LITE_WRITE_SLAVE_INIT_C,
      sofCount              => (others => '0'),
      eofCount              => (others => '0'));

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

begin

   comb : process (axiReadMaster, axiWriteMaster, axilPipelineRst, axilRst, dataPathOut,
                   eventAxisCtrl, r, rorFifoTimestamp) is
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
      v.eventAxisMaster := axiStreamMasterInit(EVENT_SSI_CONFIG_C);
      v.dataPathIn      := (others => (others => '0'));
      v.rorFifoRdEn     := '0';
--      v.gotApvBufferAddresses := '0';

      -- Latch for sync erros
      if (r.syncError = '1') then
         v.syncErrorLatch := '1';
      end if;

--       if (rorsOutstanding > r.maxRorsOutstanding and rorFifoEmpty = '0') then
--          v.maxRorsOutstanding := rorsOutstanding;
--       end if;

      if (r.sampleCountLast > r.peakOccupancy) then
         v.peakOccupancy := r.sampleCountLast;
      end if;


      ----------------------------------------------------------------------------------------------
      -- Main State Machine
      ----------------------------------------------------------------------------------------------
      case (r.state) is
         when WAIT_ROR_S =>
            -- Wait for any headers to be ready before starting
            v.syncError             := '0';
            v.burnFrame             := '0';
            v.gotTail               := (others => (others => '0'));
            v.gotApvBufferAddresses := '0';
            v.sampleCount           := (others => '0');
            v.skipCount             := (others => '0');
            v.gotHeadError          := '0';
            v.hybridNum             := 0;

            if (rorFifoTimestamp.valid = '1') then
               -- Put first header txn on stream
               ssiSetUserSof(EVENT_SSI_CONFIG_C, v.eventAxisMaster, '1');
               v.eventAxisMaster.tValid             := '1';
               v.eventAxisMaster.tData(31 downto 0) := r.eventCount;


               -- Update counts
               v.eventCount := r.eventCount + 1;
               v.sofCount   := r.sofCount + 1;
               -- Skip other header stuff
               -- Applied in DAQ framer
               v.state      := WAIT_ALL_VALID_S;
            end if;

--          when HEADER_TIMESTAMP_S =>
--             v.eventAxisMaster.tValid             := '1';
--             -- This is applied by DAQ Framer
--             v.eventAxisMaster.tData(63 downto 0) := (others => '1'); -- rorFifoTimestamp;
--             v.state                              := HEADER_FC_MSG_S;

--          when HEADER_FC_MSG_S =>
--             v.hybridNum                          := 0;
--             -- Put second header word on stream
--             v.eventAxisMaster.tValid             := '1';
--             v.eventAxisMaster.tData(79 downto 0) := rorFifoMsg.message;

--             v.state := WAIT_ALL_VALID_S;

         when WAIT_ALL_VALID_S =>
            v.hybridNum := 0;
            if (r.allHead = '1') then
               v.state := DO_DATA_S;
            end if;

         when DO_DATA_S =>
            if (eventAxisCtrl.pause = '1') then
               v.burnFrame := '1';
            end if;

            if (dataPathOut(r.hybridNum)(r.apvNum).valid = '1' and
                r.gotTail(r.hybridNum)(r.apvNum) = '0') then

               v.eventAxisMaster.tdata(MULTI_SAMPLE_LENGTH_C-1 downto 0) := toSlv(dataPathOut(r.hybridNum)(r.apvNum));
               v.dataPathIn(r.hybridNum)(r.apvNum)                       := '1';

               v.eventAxisMaster.tvalid := '1';
               if (r.dataPathEn(r.hybridNum) = '0' or
                   ((dataPathOut(r.hybridNum)(r.apvNum).head = '1' or dataPathOut(r.hybridNum)(r.apvNum).tail = '1') and
                    dataPathOut(r.hybridNum)(r.apvNum).filter = '1')) then
                  v.eventAxisMaster.tValid := '0';
               end if;

               if (v.eventAxisMaster.tValid = '1') then
                  if (r.burnFrame = '1' or r.sampleCount = r.maxSampleCount) then
                     v.skipCount              := r.skipCount + 1;
                     v.eventAxisMaster.tValid := '0';
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
                     v.eventAxisMaster.tValid := '0';
                     v.sampleCount            := r.sampleCount;
                  end if;
                  for i in 2 downto 0 loop
                     v.apvBufferAddresses(i) := dataPathOut(r.hybridNum)(r.apvNum).data(i)(8 downto 1);
                     if (r.gotApvBufferAddresses = '1') then
                        if (r.headerMode(1) = '1' or r.headerMode(0) = '1') then
                           v.eventAxisMaster.tValid := '0';
                           v.sampleCount            := r.sampleCount;
                        end if;
                        if (r.apvBufferAddresses(i) /= dataPathOut(r.hybridNum)(r.apvNum).data(i)(8 downto 1)) then
                           v.syncError := '1';
                        --v.syncErrorCount := r.syncErrorCount + 1;
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
                  v.eventAxisMaster.tValid         := '0';
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
            v.eventAxisMaster.tValid              := '1';
            v.eventAxisMaster.tLast               := '1';
            ssiSetUserEofe(EVENT_SSI_CONFIG_C, v.eventAxisMaster, r.burnFrame);
            v.eventAxisMaster.tData(15 downto 0)  := r.sampleCount;
            v.eventAxisMaster.tData(31 downto 16) := r.skipCount;
            v.eventAxisMaster.tData(32)           := '0';
            v.eventAxisMaster.tData(33)           := '0';
            v.eventAxisMaster.tData(34)           := r.syncError;
            v.eventAxisMaster.tData(35)           := r.burnFrame;
            v.gotTail                             := (others => (others => '0'));

            v.eofCount        := r.eofCount + 1;
            v.sampleCountLast := r.sampleCount;
            v.rorFifoRdEn     := '1';
            if (r.burnFrame = '1') then
               v.burnCount := r.burnCount + 1;
            end if;
            v.syncError := '0';

            v.state := DONE_FRAME_S;

         when DONE_FRAME_S =>
            -- Need to wait one cycle for rorFifoRdEn to be asserted
            v.state := WAIT_ROR_S;

         when others =>
            null;

      end case;

      -- Dont let error count roll over
      if (r.syncErrorCount = X"FFFF") then
         v.syncErrorCount := r.syncErrorCount;
      end if;

      -- In case of axilPipeline reset, reset all registers except AXI
      if (axilPipelineRst = '1') then
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

      axiSlaveRegisterR(axiEp, X"00", 0, ite(r.state = WAIT_ROR_S, "000",
                                             ite(r.state = WAIT_ALL_VALID_S, "001",
                                                 ite(r.state = DO_DATA_S, "010",
                                                     ite(r.state = EOF_S, "011",
                                                         ite(r.state = DONE_FRAME_S, "100", "111"))))));


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
      axiSlaveRegister(axiEp, X"1C", 16, v.headerMode);
      axiSlaveRegisterR(axiEp, X"20", 0, r.burnCount);
      axiSlaveRegisterR(axiEp, X"24", 0, r.sampleCountLast);
      axiSlaveRegisterR(axiEp, X"24", 12, r.syncErrorLatch);
      axiSlaveRegisterR(axiEp, X"28", 0, r.headErrorCount);
      axiSlaveRegisterR(axiEp, X"28", 16, r.eventErrorCount);
      axiSlaveRegisterR(axiEp, X"30", 0, r.peakOccupancy);
      axiSlaveRegisterR(axiEp, X"34", 0, r.syncErrorCount);
      axiSlaveRegister(axiEp, X"38", 0, v.dataPathEn);

      axiSlaveDefault(axiEp, v.axiWriteSlave, v.axiReadSlave, AXI_RESP_DECERR_C);

      ----------------------------------------------------------------------------------------------
      -- Reset and outputs
      ----------------------------------------------------------------------------------------------
      if (axilRst = '1') then
         v := REG_INIT_C;
      end if;

      rin <= v;

      eventAxisMaster <= r.eventAxisMaster;
      dataPathIn      <= r.dataPathIn;
      axiWriteSlave   <= r.axiWriteSlave;
      axiReadSlave    <= r.axiReadSlave;
      rorFifoRdEn     <= r.rorFifoRdEn;

   end process comb;

   sync : process (axilClk) is
   begin
      if (rising_edge(axilClk)) then
         r <= rin after TPD_G;
      end if;
   end process sync;

end architecture rtl;

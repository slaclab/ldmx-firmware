-------------------------------------------------------------------------------
-- Title      : ApvDataFormatter
-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: Takes 6 APV bursts with 128 channels of data each and
-- transforms them into 128 "MultiSamples" with 6 samples each.
-- This implementation uses AxiStreamScatterGather.
-------------------------------------------------------------------------------
-- Copyright (c) 2015 SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
use surf.SsiPkg.all;


library ldmx_tracker;
use ldmx_tracker.LdmxPkg.all;
use ldmx_tracker.DataPathPkg.all;
use ldmx_tracker.FebConfigPkg.all;

entity ApvDataFormatter is

   generic (
      TPD_G           : time             := 1 ns;
      HYBRID_NUM_G    : integer          := 0;
      APV_NUM_G       : integer          := 0;
      AXI_DEBUG_EN_G  : boolean          := false;
      AXI_BASE_ADDR_G : slv(31 downto 0) := (others => '0'));

   port (
      -- Master system clock, 125Mhz
      axilClk        : in sl;
      axilRst        : in sl;
      sysPipelineRst : in sl := '0';

      -- Axi Bus for status and debug
      axiReadMaster  : in  AxiLiteReadMasterType  := AXI_LITE_READ_MASTER_INIT_C;
      axiReadSlave   : out AxiLiteReadSlaveType;
      axiWriteMaster : in  AxiLiteWriteMasterType := AXI_LITE_WRITE_MASTER_INIT_C;
      axiWriteSlave  : out AxiLiteWriteSlaveType;

      apvFrameAxisMaster : in  AxiStreamMasterType;
      apvFrameAxisSlave  : out AxiStreamSlaveType;

      -- Trigger
      readoutReq : in sl;

      -- Configuration
      febConfig  : in FebConfigType;
      syncStatus : in sl;

      -- Outbound transfers
      dataOut : out MultiSampleType
      );

end entity ApvDataFormatter;

architecture rtl of ApvDataFormatter is

   constant SG_MASTER_AXIS_CONFIG_C : AxiStreamConfigType := ssiAxiStreamConfig(6);

   -- Determines the APV channel number based on the order in which it was received
   -- Based on function in Section 8.5 of APV User Guide 2.2
   function mapApvChannels return Slv7Array is
      variable ret : Slv7Array(0 to 127);
   begin
      for i in 0 to 127 loop
         ret(i) := toSlv(32 * (i mod 4) + 8 * (i / 4) - 31 * (i /16), 7);
      end loop;
      return ret;
   end function mapApvChannels;

   constant APV_CHANNEL_MAP_C : Slv7Array(0 to 127) := mapApvChannels;

   --------------------------------------------------------------------------------------------------
   type RxStateType is (RUN_S, INSERT_S, TAIL_S, RESUME_S, FREEZE_S);
   type TxStateType is (WAIT_ROR_S, BLANK_HEAD_S, TAIL_S, DATA_S, LOCKED_S);

   type RegType is record
      -- rx regs
      rxState           : RxStateType;
      sgInAxisMaster    : AxiStreamMasterType;
      apvFrameAxisSlave : AxiStreamSlaveType;
      sofData           : slv(15 downto 0);
      gotApvSof         : sl;
      -- rx debug regs
      lastSofApvFrame   : slv16Array(7 downto 0);
      lastTxnCount      : slv16Array(7 downto 0);
      insertedFrames    : slv16Array(15 downto 0);
      insertCount       : slv(3 downto 0);
      sofIn             : slv(31 downto 0);
      eofIn             : slv(31 downto 0);
      eofeIn            : slv(15 downto 0);
      -- tx regs
      txState           : TxStateType;
      multiSample       : MultiSampleType;
      rorFifoRdEn       : sl;
      channelNumber     : slv(6 downto 0);
      axiWriteSlave     : AxiLiteWriteSlaveType;
      axiReadSlave      : AxiLiteReadSlaveType;
      -- tx debug regs
      rorsIn            : slv(15 downto 0);
      rorsOut           : slv(15 downto 0);
      normalHeads       : slv(15 downto 0);
      normalTails       : slv(15 downto 0);
      blankHeads        : slv(15 downto 0);
      totalTails        : slv(15 downto 0);
   end record RegType;

   constant REG_INIT_C : RegType := (
      rxState           => RUN_S,
      sgInAxisMaster    => AXI_STREAM_MASTER_INIT_C,
      apvFrameAxisSlave => AXI_STREAM_SLAVE_INIT_C,
      sofData           => (others => '0'),
      gotApvSof         => '0',
      lastSofApvFrame   => (others => (others => '0')),
      lastTxnCount      => (others => (others => '0')),
      insertedFrames    => (others => (others => '0')),
      insertCount       => (others => '0'),
      sofIn             => (others => '0'),
      eofIn             => (others => '0'),
      eofeIn            => (others => '0'),
      txState           => WAIT_ROR_S,
      multiSample       => MULTI_SAMPLE_ZERO_C,
      rorFifoRdEn       => '0',
      channelNumber     => (others => '0'),
      axiWriteSlave     => AXI_LITE_WRITE_SLAVE_INIT_C,
      axiReadSlave      => AXI_LITE_READ_SLAVE_INIT_C,
      rorsIn            => (others => '0'),
      rorsOut           => (others => '0'),
      normalHeads       => (others => '0'),
      normalTails       => (others => '0'),
      blankHeads        => (others => '0'),
      totalTails        => (others => '0'));

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   -------------------------------------------------------------------------------------------------
   -- ScatterGataher AXI-Stream and AXI-Lite signals
   -------------------------------------------------------------------------------------------------
   signal sgSsiMaster  : SsiMasterType;
   signal sgAxisMaster : AxiStreamMasterType;
   signal sgAxisSlave  : AxiStreamSlaveType;
   signal sgAxisCtrl   : AxiStreamCtrlType;

   signal sgAxiWriteMaster : AxiLiteWriteMasterType;
   signal sgAxiWriteSlave  : AxiLiteWriteSlaveType := AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C;
   signal sgAxiReadMaster  : AxiLiteReadMasterType;
   signal sgAxiReadSlave   : AxiLiteReadSlaveType  := AXI_LITE_READ_SLAVE_EMPTY_DECERR_C;


   signal locAxiWriteMaster : AxiLiteWriteMasterType;
   signal locAxiWriteSlave  : AxiLiteWriteSlaveType := AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C;
   signal locAxiReadMaster  : AxiLiteReadMasterType;
   signal locAxiReadSlave   : AxiLiteReadSlaveType  := AXI_LITE_READ_SLAVE_EMPTY_DECERR_C;

   signal rorFifoValid : sl;
   signal synced       : sl;

   signal axilRstLoc : sl;


begin

   AxiLiteCrossbar_1 : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => 2,
         MASTERS_CONFIG_G   => (
            0               => (
               baseAddr     => AXI_BASE_ADDR_G,
               addrBits     => 8,
               connectivity => X"0001"),
            1               => (
               baseAddr     => AXI_BASE_ADDR_G + X"100",
               addrBits     => 8,
               connectivity => X"0001")))
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilRst,
         sAxiWriteMasters(0) => axiWriteMaster,
         sAxiWriteSlaves(0)  => axiWriteSlave,
         sAxiReadMasters(0)  => axiReadMaster,
         sAxiReadSlaves(0)   => axiReadSlave,
         mAxiWriteMasters(0) => locAxiWriteMaster,
         mAxiWriteMasters(1) => sgAxiWriteMaster,
         mAxiWriteSlaves(0)  => locAxiWriteSlave,
         mAxiWriteSlaves(1)  => sgAxiWriteSlave,
         mAxiReadMasters(0)  => locAxiReadMaster,
         mAxiReadMasters(1)  => sgAxiReadMaster,
         mAxiReadSlaves(0)   => locAxiReadSlave,
         mAxiReadSlaves(1)   => sgAxiReadSlave);

   axilRstLoc <= axilRst or sysPipelineRst;

   -- Queue up incomming rors
   -- Save sync status with each one
   ROR_FIFO : entity surf.Fifo
      generic map (
         TPD_G           => TPD_G,
         GEN_SYNC_FIFO_G => true,
         MEMORY_TYPE_G   => "distributed",
         FWFT_EN_G       => true,
         DATA_WIDTH_G    => 1,
         ADDR_WIDTH_G    => 6,
         FULL_THRES_G    => 5)
      port map (
         rst     => axilRstLoc,
         wr_clk  => axilClk,
         wr_en   => readoutReq,
         din(0)  => syncStatus,         --hybridInfo.syncStatus(APV_NUM_G),
         rd_clk  => axilClk,
         rd_en   => r.rorFifoRdEn,
         dout(0) => synced,
         valid   => rorFifoValid);

   AxiStreamScatterGather_1 : entity surf.AxiStreamScatterGather
      generic map (
         TPD_G                   => TPD_G,
         AXIS_SLAVE_FRAME_SIZE_G => 129,
         SLAVE_AXIS_CONFIG_G     => APV_DATA_SSI_CONFIG_C,
         MASTER_AXIS_CONFIG_G    => SG_MASTER_AXIS_CONFIG_C)
      port map (
         axiClk          => axilClk,
         axiRst          => axilRstLoc,
         axilReadMaster  => sgAxiReadMaster,
         axilReadSlave   => sgAxiReadSlave,
         axilWriteMaster => sgAxiWriteMaster,
         axilWriteSlave  => sgAxiWriteSlave,
         sAxisMaster     => r.sgInAxisMaster,
         sAxisSlave      => open,
         sAxisCtrl       => open,
         mAxisMaster     => sgAxisMaster,
         mAxisSlave      => sgAxisSlave,
         mAxisCtrl       => sgAxisCtrl);



   sgSsiMaster <= axis2SsiMaster(SG_MASTER_AXIS_CONFIG_C, sgAxisMaster);
   sgAxisSlave <= AXI_STREAM_SLAVE_FORCE_C;
   sgAxisCtrl  <= AXI_STREAM_CTRL_UNUSED_C;

   comb : process (apvFrameAxisMaster, axilRst, febConfig, locAxiReadMaster, locAxiWriteMaster, r,
                   readoutReq, rorFifoValid, sgSsiMaster, synced, sysPipelineRst) is
      variable v      : RegType;
      variable axilEp : AxiLiteEndpointType;
   begin
      v := r;

      v.rorFifoRdEn := '0';

      ----------------------------------------------------------------------------------------------
      -- Watch data as it comes in. Insert blank frames when necessary
      ----------------------------------------------------------------------------------------------
      -- Default assignments
      v.sgInAxisMaster           := apvFrameAxisMaster;
      v.apvFrameAxisSlave.tReady := '1';

      -- Watch incomming APV frames and lock the state machine when the count field in the SOF txn
      -- does not increment correctly
      case (r.rxState) is
         when RUN_S =>

            if (apvFrameAxisMaster.tValid = '1' and r.apvFrameAxisSlave.tReady = '1') then
               v.lastTxnCount(0) := r.lastTxnCount(0) + 1;
            end if;

            if (apvFrameAxisMaster.tValid = '1' and apvFrameAxisMaster.tLast = '1') then
               v.eofIn := r.eofIn + 1;
            end if;


            if (apvFrameAxisMaster.tValid = '1' and ssiGetUserSof(APV_DATA_SSI_CONFIG_C, apvFrameAxisMaster) = '1') then

               v.sofIn := r.sofIn + 1;
            end if;

         when INSERT_S =>
            v.apvFrameAxisSlave.tReady           := '0';
            v.sgInAxisMaster.tValid              := '1';
            v.insertCount                        := r.insertCount - 1;
            v.sgInAxisMaster.tData(15 downto 13) := toSlv(APV_NUM_G, 3);
            v.sgInAxisMaster.tData(12 downto 0)  := (others => '0');
            ssiSetUserSof(APV_DATA_SSI_CONFIG_C, v.sgInAxisMaster, '1');
            v.rxState                            := TAIL_S;

         when TAIL_S =>
            -- Insert blank header into stream
            v.apvFrameAxisSlave.tReady          := '0';
            v.sgInAxisMaster.tValid             := '1';
            v.sgInAxisMaster.tData(15 downto 0) := (others => '0');
            v.sgInAxisMaster.tLast              := '1';
            ssiSetUserEofe(APV_DATA_SSI_CONFIG_C, v.sgInAxisMaster, '1');
            v.rxState                           := INSERT_S;
            if (r.insertCount = 0) then
               v.rxState := RESUME_S;
            end if;


         when RESUME_S =>
            v.apvFrameAxisSlave.tReady          := '1';
            v.sgInAxisMaster.tValid             := '1';
            v.sgInAxisMaster.tData(15 downto 0) := r.sofData;
            ssiSetUserSof(APV_DATA_SSI_CONFIG_C, v.sgInAxisMaster, '1');
            v.rxState                           := RUN_S;

         when FREEZE_S =>
            v.sgInAxisMaster := AXI_STREAM_MASTER_INIT_C;

         when others => null;
      end case;


      ----------------------------------------------------------------------------------------------
      -- 
      ----------------------------------------------------------------------------------------------

      -- Debugging counters
      if (readoutReq = '1') then
         v.rorsIn := r.rorsIn + 1;
      end if;



      -- Assign default multi sample value
      v.multiSample := multiSampleReset(
         HYBRID_NUM_G, APV_NUM_G, febConfig.febAddress);

      -- State machine
      -- Assign ScatterGather output to multiSample frame structure.
      -- Send blank frames if not sync'd
      case (r.txState) is
         when WAIT_ROR_S =>

            v.channelNumber := (others => '0');
            if (rorFifoValid = '1' and r.rorFifoRdEn = '0') then
               v.rorsOut := r.rorsOut + 1;
               if (synced = '1') then
                  v.txState := DATA_S;
               else
                  v.txState := BLANK_HEAD_S;
               end if;
            end if;

         when BLANK_HEAD_S =>
            v.blankHeads         := r.blankHeads+1;
            v.multiSample.valid  := '1';
            v.multiSample.head   := '1';
            v.multiSample.filter := '1';
            v.txState            := TAIL_S;

         when TAIL_S =>
            v.totalTails            := r.totalTails +1;
            v.multiSample.valid     := '1';
            v.multiSample.tail      := '1';
            v.multiSample.filter    := '1';
            v.multiSample.readError := r.multiSample.readError;
            v.rorFifoRdEn           := '1';
            v.txState               := WAIT_ROR_S;

         when DATA_S =>
            v.multiSample.valid      := sgSsiMaster.valid;
            v.multiSample.apvChannel := APV_CHANNEL_MAP_C(conv_integer(r.channelNumber));
            v.multiSample.readError  := r.multiSample.readError;
            for i in 2 downto 0 loop
               v.multiSample.data(i)(15 downto 0) := sgSsiMaster.data(i*16+15 downto i*16);
            end loop;
            v.multiSample.head := sgSsiMaster.sof;
            v.multiSample.tail := '0';
            if (sgSsiMaster.valid = '1' and sgSsiMaster.sof = '0') then
               v.channelNumber := r.channelNumber + 1;
            end if;

            -- Latch readError on sofe
            if (sgSsiMaster.valid = '1' and sgSsiMaster.sof = '1' and sgSsiMaster.eofe = '1') then
               v.multiSample.readError := '1';
            end if;

            -- Debugging
            if (sgSsiMaster.valid = '1' and sgSsiMaster.sof = '1') then
               v.normalHeads := r.normalHeads + 1;
            end if;

            -- End of frame
            if (sgSsiMaster.valid = '1' and sgSsiMaster.eof = '1') then
               v.txState     := TAIL_S;
               v.normalTails := r.normalTails + 1;
            end if;

         when others => null;
      end case;



      -- In case of soft reset, reset all registers except AXI
      if (sysPipelineRst = '1') then
         v               := REG_INIT_C;
         v.axiWriteSlave := r.axiWriteSlave;
         v.axiReadSlave  := r.axiReadSlave;
      end if;

      ----------------------------------------------------------------------------------------------
      -- AXI Interface
      ----------------------------------------------------------------------------------------------


      axiSlaveWaitTxn(axilEp, locAxiWriteMaster, locAxiReadMaster, v.axiWriteSlave, v.axiReadSlave);

--      if (AXI_DEBUG_EN_G) then

      axiSlaveRegisterR(axilEp, X"00", 0, ite(r.txState = WAIT_ROR_S, "00",
                                              ite(r.txState = BLANK_HEAD_S, "01",
                                                  ite(r.txState = TAIL_S, "10",
                                                      ite(r.txState = DATA_S, "11", "00")))));
      axiSlaveRegisterR(axilEp, X"04", 0, r.rorsOut);
      axiSlaveRegisterR(axilEp, X"04", 16, r.rorsIn);
      axiSlaveRegisterR(axilEp, X"08", 0, r.normalHeads);
      axiSlaveRegisterR(axilEp, X"0C", 0, r.totalTails);
      axiSlaveRegisterR(axilEp, X"0C", 16, r.blankHeads);
      axiSlaveRegisterR(axilEp, X"10", 0, r.sofIn);
      axiSlaveRegisterR(axilEp, X"14", 0, r.eofIn);
      axiSlaveRegisterR(axilEp, X"18", 0, r.eofeIn);
      axiSlaveRegisterR(axilEp, X"1C", 0, ite(r.rxState = RUN_S, "000",
                                              ite(r.rxState = INSERT_S, "001",
                                                  ite(r.rxState = TAIL_S, "010",
                                                      ite(r.rxState = RESUME_S, "011",
                                                          ite(r.rxState = FREEZE_S, "100", "000"))))));


      axiSlaveDefault(axilEp, v.axiWriteSlave, v.axiReadSlave, AXI_RESP_DECERR_C);

      ----------------------------------------------------------------------------------------------
      -- Reset 
      ----------------------------------------------------------------------------------------------
      if (axilRst = '1') then
         v := REG_INIT_C;
      end if;

      ----------------------------------------------------------------------------------------------
      -- Outputs
      ----------------------------------------------------------------------------------------------

      rin               <= v;
      dataOut           <= r.multiSample;
      locAxiWriteSlave  <= r.axiWriteSlave;
      locAxiReadSlave   <= r.axiReadSlave;
      apvFrameAxisSlave <= r.apvFrameAxisSlave;

   end process comb;



   sync : process (axilClk) is
   begin
      if (rising_edge(axilClk)) then
         r <= rin after TPD_G;
      end if;
   end process sync;


end architecture rtl;

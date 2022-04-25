-------------------------------------------------------------------------------
-- Title      : FebSemWrapper
-------------------------------------------------------------------------------
-- File       : FebSemWrapper.vhd
-- Author     : Benjamin Reese  <bareese@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-06-15
-- Last update: 2020-07-27
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2015 SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;


library surf;
use surf.StdRtlPkg.all;
use surf.TextUtilPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
use surf.SsiPkg.all;
use surf.Pgp2bPkg.all;


library hps_daq;
use hps_daq.FebConfigPkg.all;


library unisim;
use unisim.vcomponents.all;

entity FebSemWrapper is

   generic (
      TPD_G : time := 1 ns);

   port (
      semClk    : in sl;
      semClkRst : in sl;

      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      febConfig       : in  FebConfigType;
      fpgaReload      : in  sl;
      fpgaReloadAddr  : in  slv(31 downto 0);

      axisClk         : in  sl;
      axisRst         : in  sl;
      semTxAxisMaster : out AxiStreamMasterType;
      semTxAxisSlave  : in  AxiStreamSlaveType;
      semRxAxisMaster : in  AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
      semRxAxisSlave  : out AxiStreamSlaveType

      );

end entity FebSemWrapper;

architecture rtl of FebSemWrapper is

   -------------------------------------------------------------------------------------------------
   -- SEM module signals
   -------------------------------------------------------------------------------------------------
   signal status_heartbeat      : sl;
   signal status_initialization : sl;
   signal status_observation    : sl;
   signal status_correction     : sl;
   signal status_classification : sl;
   signal status_injection      : sl;
   signal status_essential      : sl;
   signal status_uncorrectable  : sl;
   signal status_idle           : sl;
   signal status_halted         : sl;
   signal monitor_txdata        : slv(7 downto 0);
   signal monitor_txwrite       : sl;
   signal monitor_txfull        : sl;
   signal monitor_rxdata        : slv(7 downto 0);
   signal monitor_rxread        : sl;
   signal monitor_rxempty       : sl;
--   signal inject_strobe         : sl;
--   signal inject_address        : slv(39 downto 0);
   signal fecc_crcerr           : sl;
   signal fecc_eccerr           : sl;
   signal fecc_eccerrsingle     : sl;
   signal fecc_syndromevalid    : sl;
   signal fecc_syndrome         : slv(12 downto 0);
   signal fecc_far              : slv(25 downto 0);
   signal fecc_synbit           : slv(4 downto 0);
   signal fecc_synword          : slv(6 downto 0);
--   signal sem_icap_o                : slv(31 downto 0);
   signal sem_icap_i            : slv(31 downto 0);
   signal sem_icap_csib         : sl;
   signal sem_icap_rdwrb        : sl;
--   signal sem_icap_unused           : sl;
--   signal sem_icap_grant            : sl;
--   signal sem_icap_clk              : sl;



   -------------------------------------------------------------------------------------------------
   -- IPROG signals
   -------------------------------------------------------------------------------------------------
   signal iprogIcapReq   : sl;
   signal iprogIcapGrant : sl;
   signal iprogIcapCsl   : sl;
   signal iprogIcapRnw   : sl;
   signal iprogIcapI     : slv(31 downto 0);


   -------------------------------------------------------------------------------------------------
   -- ICAP signals
   -------------------------------------------------------------------------------------------------
   signal icap_o     : slv(31 downto 0);
   signal icap_i     : slv(31 downto 0);
   signal icap_csib  : sl;
   signal icap_rdwrb : sl;

   -------------------------------------------------------------------------------------------------
   -- SEM clk logic constants and signals
   -------------------------------------------------------------------------------------------------
   constant SEM_AXIS_CONFIG_C : AxiStreamConfigType := ssiAxiStreamConfig(8);
   constant RET_CHAR_C        : character           := cr;
   constant RET_SLV_C         : slv(7 downto 0)     := conv_std_logic_vector(character'pos(RET_CHAR_C), 8);

   -- SemClk domain registers/signals
   signal semAxilReadMaster  : AxiLiteReadMasterType;
   signal semAxilReadSlave   : AxiLiteReadSlaveType;
   signal semAxilWriteMaster : AxiLiteWriteMasterType;
   signal semAxilWriteSlave  : AxiLiteWriteSlaveType;

   type SemRegType is record
      axilWriteSlave   : AxiLiteWriteSlaveType;
      axilReadSlave    : AxiLiteReadSlaveType;
      txSsiMaster      : SsiMasterType;
      sofNext          : sl;
      heartbeatCount   : slv(31 downto 0);
      count            : slv(2 downto 0);
      statusVector     : slv8Array(1 downto 0);
      statusCounters   : slv12Array(7 downto 0);
      iprogIcapReqLast : sl;
      injectStrobe     : sl;
      injectAddress    : slv(39 downto 0);
   end record SemRegType;

   constant REG_INIT_C : SemRegType := (
      axilWriteSlave   => AXI_LITE_WRITE_SLAVE_INIT_C,
      axilReadSlave    => AXI_LITE_READ_SLAVE_INIT_C,
      txSsiMaster      => ssiMasterInit(SEM_AXIS_CONFIG_C),
      sofNext          => '1',
      heartbeatCount   => (others => '0'),
      count            => (others => '0'),
      statusVector     => (others => (others => '0')),
      statusCounters   => (others => (others => '0')),
      iprogIcapReqLast => '0',
      injectStrobe     => '0',
      injectAddress    => (others => '0'));

   signal r   : SemRegType := REG_INIT_C;
   signal rin : SemRegType;

   signal febAddrSync  : slv(3 downto 0);
   signal statusCounts : SlVectorArray(7 downto 0, 11 downto 0);
   -------------------------------------------------------------------------------------------------
   -- SemClk domain AxiStream signals
   -------------------------------------------------------------------------------------------------
   signal txAxisMaster : AxiStreamMasterType;
   signal txAxisCtrl   : AxiStreamCtrlType;
   signal rxAxisMaster : AxiStreamMasterType;
   signal rxAxisSlave  : AxiStreamSlaveType;


   -------------------------------------------------------------------------------------------------
   -- Components
   -------------------------------------------------------------------------------------------------
   component FebSem
      port (
         status_heartbeat      : out sl;
         status_initialization : out sl;
         status_observation    : out sl;
         status_correction     : out sl;
         status_classification : out sl;
         status_injection      : out sl;
         status_essential      : out sl;
         status_uncorrectable  : out sl;
         monitor_txdata        : out slv(7 downto 0);
         monitor_txwrite       : out sl;
         monitor_txfull        : in  sl;
         monitor_rxdata        : in  slv(7 downto 0);
         monitor_rxread        : out sl;
         monitor_rxempty       : in  sl;
         inject_strobe         : in  sl;
         inject_address        : in  slv(39 downto 0);
         fecc_crcerr           : in  sl;
         fecc_eccerr           : in  sl;
         fecc_eccerrsingle     : in  sl;
         fecc_syndromevalid    : in  sl;
         fecc_syndrome         : in  slv(12 downto 0);
         fecc_far              : in  slv(25 downto 0);
         fecc_synbit           : in  slv(4 downto 0);
         fecc_synword          : in  slv(6 downto 0);
         icap_o                : in  slv(31 downto 0);
         icap_i                : out slv(31 downto 0);
         icap_csib             : out sl;
         icap_rdwrb            : out sl;
         icap_clk              : in  sl;
         icap_request          : out sl;
         icap_grant            : in  sl
         );
   end component;

begin

   -- Synchronize Axi-Lite bus to semClk
   AxiLiteAsync_1 : entity surf.AxiLiteAsync
      generic map (
         TPD_G           => TPD_G,
         NUM_ADDR_BITS_G => 32)
      port map (
         sAxiClk         => axilClk,
         sAxiClkRst      => axilRst,
         sAxiReadMaster  => axilReadMaster,
         sAxiReadSlave   => axilReadSlave,
         sAxiWriteMaster => axilWriteMaster,
         sAxiWriteSlave  => axilWriteSlave,
         mAxiClk         => semClk,
         mAxiClkRst      => semClkRst,
         mAxiReadMaster  => semAxilReadMaster,
         mAxiReadSlave   => semAxilReadSlave,
         mAxiWriteMaster => semAxilWriteMaster,
         mAxiWriteSlave  => semAxilWriteSlave);

   example_frame_ecc : FRAME_ECCE2
      generic map (
         FRAME_RBT_IN_FILENAME => "NONE",
         FARSRC                => "EFAR"
         )
      port map (
         CRCERROR       => fecc_crcerr,
         ECCERROR       => fecc_eccerr,
         ECCERRORSINGLE => fecc_eccerrsingle,
         FAR            => fecc_far,
         SYNBIT         => fecc_synbit,
         SYNDROME       => fecc_syndrome,
         SYNDROMEVALID  => fecc_syndromevalid,
         SYNWORD        => fecc_synword
         );

   example_icap : ICAPE2
      generic map (
         SIM_CFG_FILE_NAME => "NONE",
         DEVICE_ID         => X"FFFFFFFF",
         ICAP_WIDTH        => "X32"
         )
      port map (
         O     => icap_o,
         CLK   => semClk,
         CSIB  => icap_csib,
         I     => icap_i,
         RDWRB => icap_rdwrb
         );

   Iprog7Core_1 : entity surf.Iprog7SeriesCore
      generic map (
         TPD_G         => TPD_G,
         SYNC_RELOAD_G => true)
      port map (
         reload     => fpgaReload,
         reloadAddr => fpgaReloadAddr,
         icapClk    => semClk,
         icapClkRst => semClkRst,
         icapReq    => iprogIcapReq,
         icapGrant  => iprogIcapGrant,
         icapCsl    => iprogIcapCsl,
         icapRnw    => iprogIcapRnw,
         icapI      => iprogIcapI);

   example_controller : FebSem
      port map (
         status_heartbeat      => status_heartbeat,
         status_initialization => status_initialization,
         status_observation    => status_observation,
         status_correction     => status_correction,
         status_classification => status_classification,
         status_injection      => status_injection,
         status_essential      => status_essential,
         status_uncorrectable  => status_uncorrectable,
         monitor_txdata        => monitor_txdata,
         monitor_txwrite       => monitor_txwrite,
         monitor_txfull        => monitor_txfull,
         monitor_rxdata        => monitor_rxdata,
         monitor_rxread        => monitor_rxread,
         monitor_rxempty       => monitor_rxempty,
         inject_strobe         => r.injectStrobe,
         inject_address        => r.injectAddress,
         fecc_crcerr           => fecc_crcerr,
         fecc_eccerr           => fecc_eccerr,
         fecc_eccerrsingle     => fecc_eccerrsingle,
         fecc_syndromevalid    => fecc_syndromevalid,
         fecc_syndrome         => fecc_syndrome,
         fecc_far              => fecc_far,
         fecc_synbit           => fecc_synbit,
         fecc_synword          => fecc_synword,
         icap_o                => icap_o,
         icap_i                => sem_icap_i,
         icap_csib             => sem_icap_csib,
         icap_rdwrb            => sem_icap_rdwrb,
         icap_clk              => semClk,
         icap_request          => open,
         icap_grant            => '1'
         );

   status_idle <= not (status_initialization or status_observation or status_correction or
                       status_classification or status_injection);

   status_halted <= (status_initialization and status_observation and status_correction and
                     status_classification and status_injection);

   SynchronizerFifo_Config : entity surf.SynchronizerFifo
      generic map (
         TPD_G         => TPD_G,
         COMMON_CLK_G  => false,
         MEMORY_TYPE_G => "distributed",
         DATA_WIDTH_G  => 4,
         ADDR_WIDTH_G  => 4)
      port map (
         rst    => axilRst,
         wr_clk => axilClk,
         din    => febConfig.febAddress,
         rd_clk => semClk,
         dout   => febAddrSync);

--    U_SyncStatusVector_1 : entity surf.SyncStatusVector
--       generic map (
--          TPD_G          => TPD_G,
--          COMMON_CLK_G   => true,
--          CNT_RST_EDGE_G => true,
--          CNT_WIDTH_G    => 12,
--          SYNTH_CNT_G    => "11111111",
--          WIDTH_G        => 8)
--       port map (
--          statusIn(0) => status_initialization,  -- [in]
--          statusIn(1) => status_observation,     -- [in]
--          statusIn(2) => status_correction,      -- [in]
--          statusIn(3) => status_classification,  -- [in]
--          statusIn(4) => status_injection,       -- [in]
--          statusIn(5) => status_idle,            -- [in]
--          statusIn(6) => status_essential,       -- [in]
--          statusIn(7) => status_uncorrectable,   -- [in]
--          cntRstIn    => '0',                    -- [in]
--          cntOut      => statusCounts,           -- [out]
--          wrClk       => semClk,                 -- [in]
--          wrRst       => '0',                    -- [in]
--          rdClk       => semClk,                 -- [in]
--          rdRst       => '0');                   -- [in]

   -------------------------------------------------------------------------------------------------
   -- Transform monitor interface into AxiStream streams
   -------------------------------------------------------------------------------------------------
   mon2axis : process (febAddrSync, iprogIcapCsl, iprogIcapGrant, iprogIcapI, iprogIcapReq,
                       iprogIcapRnw, monitor_rxread, monitor_txdata, monitor_txwrite, r,
                       rxAxisMaster, semAxilReadMaster, semAxilWriteMaster, semClkRst,
                       sem_icap_csib, sem_icap_i, sem_icap_rdwrb, status_classification,
                       status_correction, status_essential, status_halted, status_heartbeat,
                       status_idle, status_initialization, status_injection, status_observation,
                       status_uncorrectable, txAxisCtrl) is
      variable v : SemRegType;
      variable c : integer range 0 to 7;

      variable axilEp : AxiLiteEndpointType;

   begin
      v := r;

      -- Count heartbeats
      if (status_heartbeat = '1') then
         v.heartbeatCount := r.heartbeatCount + 1;
      end if;

      ----------------------------------------------------------------------------------------------
      -- Transition Counters
      ----------------------------------------------------------------------------------------------
      v.statusVector(0)(0) := status_initialization;
      v.statusVector(0)(1) := status_observation;
      v.statusVector(0)(2) := status_correction;
      v.statusVector(0)(3) := status_classification;
      v.statusVector(0)(4) := status_injection;
      v.statusVector(0)(5) := status_idle;
--      v.statusVector(0)(6) := status_halted;
      v.statusVector(0)(6) := status_essential;
      v.statusVector(0)(7) := status_uncorrectable;
      v.statusVector(1)    := r.statusVector(0);

      for i in 7 downto 0 loop
         if (r.statusVector(0)(i) = '1' and r.statusVector(1)(i) = '0') then
            v.statusCounters(i) := r.statusCounters(i) + 1;
         end if;
         if (r.statusCounters(i) = X"FFF") then
            v.statusCounters(i) := r.statusCounters(i);
         end if;
      end loop;


      ----------------------------------------------------------------------------------------------
      -- Convert tx data stream to 64-bit wide SSI frames
      -- This assures that every frame will be at least 4x16-bits for PGP
      ----------------------------------------------------------------------------------------------
      if (r.sofNext = '1') then
         v.txSsiMaster.data(7 downto 0)   := toSlv(character'pos('F'), 8);
         v.txSsiMaster.data(15 downto 8)  := toSlv(character'pos('E'), 8);
         v.txSsiMaster.data(23 downto 16) := toSlv(character'pos('B'), 8);
         v.txSsiMaster.data(31 downto 24) := toSlv(character'pos(' '), 8);
         v.txSsiMaster.data(39 downto 32) := toSlv(character'pos('0'), 8);
         case febAddrSync is
            when X"0" =>
               v.txSsiMaster.data(47 downto 40) := toSlv(character'pos('0'), 8);
            when X"1" =>
               v.txSsiMaster.data(47 downto 40) := toSlv(character'pos('1'), 8);
            when X"2" =>
               v.txSsiMaster.data(47 downto 40) := toSlv(character'pos('2'), 8);
            when X"3" =>
               v.txSsiMaster.data(47 downto 40) := toSlv(character'pos('3'), 8);
            when X"4" =>
               v.txSsiMaster.data(47 downto 40) := toSlv(character'pos('4'), 8);
            when X"5" =>
               v.txSsiMaster.data(47 downto 40) := toSlv(character'pos('5'), 8);
            when X"6" =>
               v.txSsiMaster.data(47 downto 40) := toSlv(character'pos('6'), 8);
            when X"7" =>
               v.txSsiMaster.data(47 downto 40) := toSlv(character'pos('7'), 8);
            when X"8" =>
               v.txSsiMaster.data(47 downto 40) := toSlv(character'pos('8'), 8);
            when X"9" =>
               v.txSsiMaster.data(47 downto 40) := toSlv(character'pos('9'), 8);
            when others =>
               v.txSsiMaster.data(47 downto 40) := toSlv(character'pos('?'), 8);
         end case;
         v.txSsiMaster.data(55 downto 48) := toSlv(character'pos(':'), 8);
         v.txSsiMaster.data(63 downto 56) := toSlv(character'pos(' '), 8);
         v.txSsiMaster.valid              := '1';
         v.txSsiMaster.sof                := '1';
         v.txSsiMaster.eof                := '0';
         v.count                          := (others => '0');
         v.sofNext                        := '0';
      else
         if (monitor_txwrite = '1') then
            v.count := r.count + 1;
         end if;
         -- Stupid Vivado can't handle dynamic ranges properly so we have to do this shit instead
         c := conv_integer(r.count);
         case c is
            when 0 => v.txSsiMaster.data := (others => '0');
                      v.txSsiMaster.data(7 downto 0) := monitor_txdata;
            when 1 => v.txSsiMaster.data(15 downto 8)  := monitor_txdata;
            when 2 => v.txSsiMaster.data(23 downto 16) := monitor_txdata;
            when 3 => v.txSsiMaster.data(31 downto 24) := monitor_txdata;
            when 4 => v.txSsiMaster.data(39 downto 32) := monitor_txdata;
            when 5 => v.txSsiMaster.data(47 downto 40) := monitor_txdata;
            when 6 => v.txSsiMaster.data(55 downto 48) := monitor_txdata;
            when 7 => v.txSsiMaster.data(63 downto 56) := monitor_txdata;
         end case;

         v.txSsiMaster.valid := toSl((c = 7) or (monitor_txdata = RET_SLV_C)) and monitor_txwrite;
         v.txSsiMaster.sof   := '0';
         v.txSsiMaster.eof   := toSl(monitor_txdata = RET_SLV_C) and monitor_txwrite;

         if (v.txSsiMaster.valid = '1') then
            -- Reset count on EOF so next frame starts at 0
            if (v.txSsiMaster.eof = '1') then
               v.sofNext := '1';
            end if;
         end if;
      end if;

      monitor_txfull <= txAxisCtrl.pause;
      txAxisMaster   <= ssi2AxisMaster(SEM_AXIS_CONFIG_C, r.txSsiMaster);

      -- Convert rx AxiStream into monitor interface
      monitor_rxdata     <= rxAxisMaster.tData(7 downto 0);
      monitor_rxempty    <= not rxAxisMaster.tValid;
      rxAxisSlave.tReady <= monitor_rxread;





      ----------------------------------------------------------------------------------------------
      -- AXI-Lite registers
      ----------------------------------------------------------------------------------------------
      v.injectStrobe := '0';

      -- Determine the transaction type
      axiSlaveWaitTxn(axilEp, semAxilWriteMaster, semAxilReadMaster, v.axilWriteSlave, v.axilReadSlave);

      axiSlaveRegisterR(axilEp, X"00", 0, status_initialization);
      axiSlaveRegisterR(axilEp, X"00", 1, status_observation);
      axiSlaveRegisterR(axilEp, X"00", 2, status_correction);
      axiSlaveRegisterR(axilEp, X"00", 3, status_classification);
      axiSlaveRegisterR(axilEp, X"00", 4, status_injection);
      axiSlaveRegisterR(axilEp, X"00", 5, status_idle);
      axiSlaveRegisterR(axilEp, X"00", 6, status_halted);
      axiSlaveRegisterR(axilEp, X"00", 7, status_essential);
      axiSlaveRegisterR(axilEp, X"00", 8, status_uncorrectable);
      axiSlaveRegisterR(axilEp, X"04", 0, r.heartbeatCount);
      axiSlaveRegister(axilEp, X"0C", 0, v.injectStrobe);
      axiSlaveRegister(axilEp, X"10", 0, v.injectAddress(31 downto 0));
      axiSlaveRegister(axilEp, X"14", 0, v.injectAddress(39 downto 32));

--       axiSlaveRegisterR(axilEp, X"20", 0, muxSlVectorArray(statusCounts, 0));
--       axiSlaveRegisterR(axilEp, X"24", 0, muxSlVectorArray(statusCounts, 1));
--       axiSlaveRegisterR(axilEp, X"28", 0, muxSlVectorArray(statusCounts, 2));
--       axiSlaveRegisterR(axilEp, X"2C", 0, muxSlVectorArray(statusCounts, 3));
--       axiSlaveRegisterR(axilEp, X"30", 0, muxSlVectorArray(statusCounts, 4));
--       axiSlaveRegisterR(axilEp, X"34", 0, muxSlVectorArray(statusCounts, 5));
--       axiSlaveRegisterR(axilEp, X"38", 0, muxSlVectorArray(statusCounts, 6));
--       axiSlaveRegisterR(axilEp, X"3C", 0, muxSlVectorArray(statusCounts, 7));
      axiSlaveRegisterR(axilEp, X"20", 0, r.statusCounters(0));
      axiSlaveRegisterR(axilEp, X"24", 0, r.statusCounters(1));
      axiSlaveRegisterR(axilEp, X"28", 0, r.statusCounters(2));
      axiSlaveRegisterR(axilEp, X"2C", 0, r.statusCounters(3));
      axiSlaveRegisterR(axilEp, X"30", 0, r.statusCounters(4));
      axiSlaveRegisterR(axilEp, X"34", 0, r.statusCounters(5));
      axiSlaveRegisterR(axilEp, X"38", 0, r.statusCounters(6));
      axiSlaveRegisterR(axilEp, X"3C", 0, r.statusCounters(7));


      axiSlaveDefault(axilEp, v.axilWriteSlave, v.axilReadSlave, AXI_RESP_DECERR_C);

      semAxilReadSlave  <= r.axilReadSlave;
      semAxilWriteSlave <= r.axilWriteSlave;


      ----------------------------------------------------------------------------------------------
      -- Allow IPROG access to ICAP
      ----------------------------------------------------------------------------------------------
      v.iprogIcapReqLast := iprogIcapReq;
      if (iprogIcapReq = '1' and r.iprogIcapReqLast = '0') then
         v.injectStrobe  := '1';
         v.injectAddress := X"E000000000";
      end if;

      iprogIcapGrant <= status_idle and iprogIcapReq;

      -- ICAP mux. IPROG has access when SEM is idle
      if (iprogIcapGrant = '1') then
         icap_rdwrb <= iprogIcapRnw;
         icap_csib  <= iprogIcapCsl;
         icap_i     <= iprogIcapI;
      else
         icap_rdwrb <= sem_icap_rdwrb;
         icap_csib  <= sem_icap_csib;
         icap_i     <= sem_icap_i;
      end if;

      ----------------------------------------------------------------------------------------------
      -- Synchronous reset
      ----------------------------------------------------------------------------------------------
      if (semClkRst = '1') then
         v := REG_INIT_C;
      end if;

      ----------------------------------------------------------------------------------------------
      -- Rin assignment
      ----------------------------------------------------------------------------------------------
      rin <= v;

   end process mon2axis;

   mon2AxisSeq : process (semClk) is
   begin
      if (rising_edge(semClk)) then
         r <= rin after TPD_G;
      end if;
   end process mon2AxisSeq;

   -------------------------------------------------------------------------------------------------
   -- Convert streams to PGP format and clock
   -------------------------------------------------------------------------------------------------
   AxiStreamFifo_TX : entity surf.AxiStreamFifoV2
      generic map (
         TPD_G               => TPD_G,
         SLAVE_READY_EN_G    => false,
         VALID_THOLD_G       => 0,
         SYNTH_MODE_G        => "xpm",
         MEMORY_TYPE_G       => "block",
         GEN_SYNC_FIFO_G     => false,
         CASCADE_SIZE_G      => 1,
         FIFO_ADDR_WIDTH_G   => 4,
         FIFO_FIXED_THRESH_G => true,
         FIFO_PAUSE_THRESH_G => 14,
         SLAVE_AXI_CONFIG_G  => SEM_AXIS_CONFIG_C,
         MASTER_AXI_CONFIG_G => SSI_PGP2B_CONFIG_C)
      port map (
         sAxisClk    => semClk,
         sAxisRst    => '0',
         sAxisMaster => txAxisMaster,
         sAxisCtrl   => txAxisCtrl,
         mAxisClk    => axisClk,
         mAxisRst    => axisRst,
         mAxisMaster => semTxAxisMaster,
         mAxisSlave  => semTxAxisSlave);

   AxiStreamFifo_RX : entity surf.AxiStreamFifoV2
      generic map (
         TPD_G               => TPD_G,
         SLAVE_READY_EN_G    => true,
         VALID_THOLD_G       => 1,
         SYNTH_MODE_G        => "xpm",
         MEMORY_TYPE_G       => "block",
         GEN_SYNC_FIFO_G     => false,
         CASCADE_SIZE_G      => 1,
         FIFO_ADDR_WIDTH_G   => 4,
         FIFO_FIXED_THRESH_G => true,
         FIFO_PAUSE_THRESH_G => 14,
         SLAVE_AXI_CONFIG_G  => SSI_PGP2B_CONFIG_C,
         MASTER_AXI_CONFIG_G => SEM_AXIS_CONFIG_C)
      port map (
         sAxisClk    => axisClk,
         sAxisRst    => axisRst,
         sAxisMaster => semRxAxisMaster,
         sAxisSlave  => semRxAxisSlave,
         mAxisClk    => semClk,
         mAxisRst    => '0',
         mAxisMaster => rxAxisMaster,
         mAxisSlave  => rxAxisSlave);


end architecture rtl;

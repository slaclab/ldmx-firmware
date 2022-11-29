-------------------------------------------------------------------------------
-- Title      : Coulter PGP 
-------------------------------------------------------------------------------
-- File       : FetPgp.vhd
-- Author     : Benjamin Reese  <bareese@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2016-06-03
-- Last update: 2022-11-29
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- This file is part of Coulter. It is subject to
-- the license terms in the LICENSE.txt file found in the top-level directory
-- of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of Coulter, including this file, may be
-- copied, modified, propagated, or distributed except according to the terms
-- contained in the LICENSE.txt file.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library unisim;
use unisim.vcomponents.all;


library surf;
use surf.StdRtlPkg.all;
use surf.Pgp4Pkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
use surf.SsiPkg.all;
use surf.SsiCmdMasterPkg.all;


library hps_daq;
use hps_daq.HpsPkg.all;

entity LdmxFebPgp is
   generic (
      TPD_G                : time                        := 1 ns;
      ROGUE_SIM_EN_G       : boolean                     := false;
      ROGUE_SIM_SIDEBAND_G : boolean                     := true;
      ROGUE_SIM_PORT_NUM_G : natural range 1024 to 49151 := 9000;
      AXIL_BASE_ADDR_G     : slv(31 downto 0)            := (others => '0');
      AXIL_CLK_FREQ_G      : real                        := 156.25e6);
   port (
      -- Reference clocks for PGP MGTs
      gtRefClk185P : in sl;
      gtRefClk185N : in sl;
      gtRefClk250P : in sl;
      gtRefClk250N : in sl;

      userRefClk250G : out sl;
      userRefRst250  : out sl;

      -- MGT IO
      pgpGtTxP : out slv(1 downto 0);
      pgpGtTxN : out slv(1 downto 0);
      pgpGtRxP : in  slv(1 downto 0);
      pgpGtRxN : in  slv(1 downto 0);

      -- Status output for LEDs
      ctrlTxLink : out slv(1 downto 0);
      ctrlRxLink : out slv(1 downto 0);

      -- Control link Opcode and AXI-Stream interface
      daqClk       : out sl;            -- Recovered fixed-latency clock
      daqRst       : out sl;
      daqRxFcWord  : out slv(79 downto 0);
      daqRxFcValid : out sl;

      -- All AXI-Lite and AXI-Stream interfaces are synchronous with this clock
      axilClk : in sl;                  -- Also Drives PGP stableClk input
      axilRst : in sl;

      -- AXI-Lite Master (Register interface)
      mAxilReadMaster  : out AxiLiteReadMasterType;
      mAxilReadSlave   : in  AxiLiteReadSlaveType;
      mAxilWriteMaster : out AxiLiteWriteMasterType;
      mAxilWriteSlave  : in  AxiLiteWriteSlaveType;

      -- AXI-Lite slave interface for PGP statuses
      sAxilReadMaster  : in  AxiLiteReadMasterType;
      sAxilReadSlave   : out AxiLiteReadSlaveType;
      sAxilWriteMaster : in  AxiLiteWriteMasterType;
      sAxilWriteSlave  : out AxiLiteWriteSlaveType;

      -- Streaming data
      dataClk        : in  sl;
      dataRst        : in  sl;
      dataAxisMaster : in  AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
      dataAxisSlave  : out AxiStreamSlaveType;
      dataAxisCtrl   : out AxiStreamCtrlType);

end LdmxFebPgp;

architecture rtl of LdmxFebPgp is

   -------------------------------------------------------------------------------------------------
   -- Clocks
   -------------------------------------------------------------------------------------------------

   -------------------------------------------------------------------------------------------------
   -- PGP
   -------------------------------------------------------------------------------------------------
   constant SAS_INDEX_C : integer := 0;
   constant SFP_INDEX_C : integer := 1;

   signal pgpTxClk     : slv(1 downto 0);
   signal pgpTxRst     : slv(1 downto 0);
   signal pgpRxClk     : slv(1 downto 0);
   signal pgpRxRst     : slv(1 downto 0);
   signal pgpRxIn      : Pgp2fcRxInArray(1 downto 0)          := (others => PGP2FC_RX_IN_INIT_C);
   signal pgpRxOut     : Pgp2fcRxOutArray(1 downto 0);
   signal pgpTxIn      : Pgp2fcTxInArray(1 downto 0)          := (others => PGP2FC_TX_IN_INIT_C);
   signal pgpTxOut     : Pgp2fcTxOutArray(1 downto 0);
   signal pgpRxFcWord  : slv80Array(1 downto 0)               := (others => (others => '0'));
   signal pgpRxFcValid : slv(1 downto 0);
   signal pgpTxFcWord  : slv80Array(1 downto 0)               := (others => (others => '0'));
   signal pgpTxFcValid : slv(1 downto 0)                      := "00";
   signal pgpRxMasters : AxiStreamQuadMasterArray(1 downto 0);
   signal pgpRxSlaves  : AxiStreamQuadSlaveArray(1 downto 0)  := (others => (others => AXI_STREAM_SLAVE_FORCE_C));
   signal pgpRxCtrl    : AxiStreamQuadCtrlArray(1 downto 0)   := (others => (others => AXI_STREAM_CTRL_UNUSED_C));
   signal pgpTxMasters : AxiStreamQuadMasterArray(1 downto 0) := (others => (others => AXI_STREAM_MASTER_INIT_C));
   signal pgpTxSlaves  : AxiStreamQuadSlaveArray(1 downto 0);



   -------------------------------------------------------------------------------------------------
   -- AXI-Lite
   -------------------------------------------------------------------------------------------------
   constant MAIN_XBAR_CFG_C : AxiLiteCrossbarMasterConfigArray(1 downto 0) := genAxiLiteConfig(2, AXI_BASE_ADDR_G, 24, 20);

   signal locAxilReadMasters  : AxiLiteReadMasterArray(1 downto 0);
   signal locAxilReadSlaves   : AxiLiteReadSlaveArray(1 downto 0);
   signal locAxilWriteMasters : AxiLiteWriteMasterArray(1 downto 0);
   signal locAxilWriteSlaves  : AxiLiteWriteSlaveArray(1 downto 0);



begin

   -------------------------------------------------------------------------------------------------
   -- Reference Clocks
   -------------------------------------------------------------------------------------------------
   U_IBUFDS_GTE4_185 : IBUFDS_GTE4
      generic map (
         REFCLK_EN_TX_PATH  => '0',
         REFCLK_HROW_CK_SEL => "00",    -- 2'b00: ODIV2 = O
         REFCLK_ICNTL_RX    => "00")
      port map (
         I     => gtRefClk185P,
         IB    => gtRefClk185N,
         CEB   => '0',
         ODIV2 => userRefClk185Tmp,
         O     => gtRefClk185);

   U_BUFG_185 : BUFG_GT
      port map (
         I       => userRefClk185,
         CE      => '1',
         CEMASK  => '1',
         CLR     => '0',
         CLRMASK => '1',
         DIV     => "000",              -- Divide-by-1
         O       => userRefClk185G);

   U_PwrUpRst_185 : entity surf.PwrUpRst
      generic map (
         TPD_G          => TPD_G,
         SIM_SPEEDUP_G  => ROGUE_SIM_G,
         IN_POLARITY_G  => '1',
         OUT_POLARITY_G => '1')
      port map (
         clk    => userRefClk185G,
         rstOut => userRefRst185G);
   

   U_QsfpRef0 : IBUFDS_GTE4
      generic map (
         REFCLK_EN_TX_PATH  => '0',
         REFCLK_HROW_CK_SEL => "00",    -- 2'b00: ODIV2 = O
         REFCLK_ICNTL_RX    => "00")
      port map (
         I     => gtRefClk250P,
         IB    => gtRefClk250N,
         CEB   => '0',
         ODIV2 => userRefClk250Tmp,
         O     => open);

   U_BUFG : BUFG_GT
      port map (
         I       => userRefClk250Tmp,
         CE      => '1',
         CEMASK  => '1',
         CLR     => '0',
         CLRMASK => '1',
         DIV     => "000",              -- Divide-by-1
         O       => userRefClk250G);

   PwrUpRst_1 : entity surf.PwrUpRst
      generic map (
         TPD_G          => TPD_G,
         SIM_SPEEDUP_G  => ROGUE_SIM_G,
         IN_POLARITY_G  => '1',
         OUT_POLARITY_G => '1')
      port map (
         clk    => userRefClk250G,
         rstOut => userRefRst250G);

   userRefClk250 <= userRefClk250G;
   userRefRst250 <= userRefRst250G;


   NO_SIM : if (not ROGUE_SIM_G) generate

      ---------------------
      -- AXI-Lite Crossbar
      ---------------------
      U_MAIN_XBAR : entity surf.AxiLiteCrossbar
         generic map (
            TPD_G              => TPD_G,
            NUM_SLAVE_SLOTS_G  => 1,
            NUM_MASTER_SLOTS_G => 2,
            MASTERS_CONFIG_G   => MAIN_AXIL_XBAR_CFG_G)
         port map (
            axiClk              => axilClk,
            axiClkRst           => axilRst,
            sAxiWriteMasters(0) => sAxilWriteMaster,
            sAxiWriteSlaves(0)  => sAxilWriteSlave,
            sAxiReadMasters(0)  => sAxilReadMaster,
            sAxiReadSlaves(0)   => sAxilReadSlave,
            mAxiWriteMasters    => locAxilWriteMasters,
            mAxiWriteSlaves     => locAxilWriteSlaves,
            mAxiReadMasters     => locAxilReadMasters,
            mAxiReadSlaves      => locAxilReadSlaves);

      PGP_GEN : for i in 1 downto 0 generate

         U_PGP_XBAR : entity surf.AxiLiteCrossbar
            generic map (
               TPD_G              => TPD_G,
               NUM_SLAVE_SLOTS_G  => 1,
               NUM_MASTER_SLOTS_G => PGP_AXIL_MASTERS_G,
               MASTERS_CONFIG_G   => PGP_AXIL_XBAR_CFG_G)
            port map (
               axiClk              => axilClk,
               axiClkRst           => axilRst,
               sAxiWriteMasters(0) => locAxilWriteMasters(i),
               sAxiWriteSlaves(0)  => locAxilWriteSlaves(i),
               sAxiReadMasters(0)  => locAxilReadMasters(i),
               sAxiReadSlaves(0)   => locAxilReadSlaves(i),
               mAxiWriteMasters    => pgpAxilWriteMasters(i),
               mAxiWriteSlaves     => pgpAxilWriteSlaves(i),
               mAxiReadMasters     => pgpAxilReadMasters(i),
               mAxiReadSlaves      => pgpAxilReadSlaves(i));



         -------------------------------
         --       PGP Core            --
         -------------------------------
         U_Pgp2fcGtyUltra_SAS : entity surf.Pgp2fcGtyUltra
            generic map (
               TPD_G           => TPD_G,
               SIMULATION_G    => false,
               FC_WORDS_G      => 5,
               VC_INTERLEAVE_G => true,
               NUM_VC_EN_G     => 2)
            port map (
               stableClk       => userRefClk250G,            -- [in]
               stableRst       => userRefRst250G,            -- [in]
               gtRefClk        => gtRefClk185,               -- [in]
               pgpGtTxP        => pgpGtTxP(i),               -- [out]
               pgpGtTxN        => pgpGtTxN(i),               -- [out]
               pgpGtRxP        => pgpGtRxP(i),               -- [in]
               pgpGtRxN        => pgpGtRxN(i),               -- [in]
               pgpTxReset      => pgpTxReset,                -- [in]
--            pgpTxResetDone   => pgpTxResetDone,    -- [out]
               pgpTxOutClk     => pgpTxOutClk(i),            -- [out]
               pgpTxClk        => pgpTxClk(i),               -- [in]
               pgpTxMmcmLocked => '1',                       -- [in]
               pgpRxReset      => pgpRxReset,                -- [in]
--            pgpRxResetDone   => pgpRxResetDone,    -- [out]
               pgpRxOutClk     => pgpRxOutClk(i),            -- [out]
               pgpRxClk        => pgpRxClk(i),               -- [in]
               pgpRxMmcmLocked => '1',                       -- [in]
               pgpRxIn         => pgpRxIn(i),                -- [in]
               pgpRxOut        => pgpRxOut(i),               -- [out]
               pgpTxIn         => pgpTxIn(i),                -- [in]
               pgpTxOut        => pgpTxOut(i),               -- [out]
               pgpTxMasters    => pgpTxMasters(i),           -- [in]
               pgpTxSlaves     => pgpTxSlaves(i),            -- [out]
               pgpRxMasters    => pgpRxMasters(i),           -- [out]
--            pgpRxMasterMuxed => pgpRxMasterMuxed,  -- [out]
               pgpRxCtrl       => pgpRxCtrl(i),              -- [in]
               axilClk         => axilClk,                   -- [in]
               axilRst         => axilRst,                   -- [in]
               axilReadMaster  => pgpAxilReadMasters(i)(PGP_AXIL_GTY_C),   -- [in]
               axilReadSlave   => pgpAxilReadSlaves(i)(PGP_AXIL_GTY_C),    -- [out]
               axilWriteMaster => pgpAxilWriteMasters(i)(PGP_AXIL_GTY_C),  -- [in]
               axilWriteSlave  => pgpAxilWriteSlaves(i)(PGP_AXIL_GTY_C));  -- [out]

         U_BUFG_TX : BUFG_GT
            port map (
               I       => pgpTxOutClk(i),
               CE      => '1',
               CEMASK  => '1',
               CLR     => '0',
               CLRMASK => '1',
               DIV     => "000",        -- Divide by 1
               O       => pgpTxClk(i));

         U_BUFG_RX : BUFG_GT
            port map (
               I       => pgpRxOutClk(i),
               CE      => '1',
               CEMASK  => '1',
               CLR     => '0',
               CLRMASK => '1',
               DIV     => "000",        -- Divide by 1
               O       => pgpRxClk(i));

         --------------
         -- PGP Monitor
         --------------
         U_PgpMon : entity surf.Pgp2fcAxi
            generic map (
               TPD_G              => TPD_G,
               COMMON_TX_CLK_G    => false,
               COMMON_RX_CLK_G    => false,
               WRITE_EN_G         => false,
               AXI_CLK_FREQ_G     => AXIL_CLK_FREQ_G,
               STATUS_CNT_WIDTH_G => 16,
               ERROR_CNT_WIDTH_G  => 16)
            port map (
               -- TX PGP Interface (pgpTxClk)
               pgpTxClk        => pgpTxClk(i),
               pgpTxClkRst     => pgpTxReset(i),
               pgpTxIn         => pgpTxIn(i),
               pgpTxOut        => pgpTxOut(i),
               -- RX PGP Interface (pgpRxClk)
               pgpRxClk        => pgpRxClk(i),
               pgpRxClkRst     => pgpRxReset(i),
               pgpRxIn         => pgpRxIn(i),
               pgpRxOut        => pgpRxOut(i),
               -- AXI-Lite Register Interface (axilClk domain)
               axilClk         => axilClk,
               axilRst         => axilRst,
               axilReadMaster  => pgpAxilReadMasters(i)(PGP_AXIL_PGP_C),
               axilReadSlave   => pgpAxilReadSlaves(i(PGP_AXIL_PGP_C)),
               axilWriteMaster => pgpAxilWriteMasters(i)(PGP_AXIL_PGP_C),
               axilWriteSlave  => pgpAxilWriteSlaves(i)(PGP_AXIL_PGP_C))

            U_PgpMiscCtrl : entity ldmx.PgpMiscCtrl
            generic map (
               TPD_G => TPD_G)
            port map (
               -- Control/Status  (axilClk domain)
               config          => config,
               txUserRst       => pgpTxRst,
               rxUserRst       => pgpRxRst,
               -- AXI Lite interface
               axilClk         => axilClk,
               axilRst         => axilRst,
               axilReadMaster  => pgpAxilReadMasters(i)(PGP_AXIL_MISC_C),
               axilReadSlave   => pgpAxilReadSlaves(i)(PGP_AXIL_MISC_C),
               axilWriteMaster => pgpAxilWriteMasters(i)(PGP_AXIL_MISC_C),
               axilWriteSlave  => pgpAxilWriteSlaves(i)(PGP_AXIL_MISC_C));



         pgpRxIn(i).resetRx  <= '0';
         pgpRxIn(i).loopback <= "000";

      end generate PGP_GEN;

      ----------------------------------------------------------------------------------------------
      -- Multiplex the two PGP Lanes
      ----------------------------------------------------------------------------------------------
      U_AxiStreamMux_1: entity surf.AxiStreamMux
         generic map (
            TPD_G                => TPD_G,
            NUM_SLAVES_G         => 2,
            MODE_G               => "INDEXED",
            TID_MODE_G           => "INDEXED",
            ILEAVE_EN_G          => false)
         port map (
            axisClk      => userRefClk185G,       -- [in]
            axisRst      => userRefRst185G,       -- [in]
            sAxisMasters(0) => pgpRxMasters(0)(i),  -- [in]
            sAxisMasters(1) => pgpRxMasters(1)(i),  -- [in]            
            sAxisSlaves(0)  => pgpRxSlaves(0)(i),   -- [out]
            sAxisSlaves(1)  => pgpRxSlaves(1)(i),   -- [out]            
            mAxisMaster  => mAxisMaster,   -- [out]
            mAxisSlave   => mAxisSlave);   -- [in]

   end generate NO_SIM;


-- Lane 0, VC0 RX/TX, Register access control        
   U_Vc0AxiMasterRegisters : entity surf.SrpV3AxiLite
      generic map (
         TPD_G               => TPD_G,
         SLAVE_READY_EN_G    => ROGUE_SIM_EN_G,
--          RESP_THOLD_G        => 1,
--          SLAVE_READY_EN_G    => false,
--          EN_32BIT_ADDR_G     => false,
--          USE_BUILT_IN_G      => false,
--          GEN_SYNC_FIFO_G     => false,
--          FIFO_ADDR_WIDTH_G   => 9,
--          FIFO_PAUSE_THRESH_G => 2**8,
         AXI_STREAM_CONFIG_G => PGP4_AXIS_CONFIG_C
         )
      port map (
         -- Streaming Slave (Rx) Interface (sAxisClk domain) 
         sAxisClk         => pgpClk,
         sAxisRst         => pgpRst,
         sAxisMaster      => pgpRxMasters(0),
         sAxisSlave       => pgpRxSlaves(0),
         sAxisCtrl        => pgpRxCtrl(0),
         -- Streaming Master (Tx) Data Interface (mAxisClk domain)
         mAxisClk         => pgpClk,
         mAxisRst         => pgpRst,
         mAxisMaster      => pgpTxMasters(0),
         mAxisSlave       => pgpTxSlaves(0),
         -- AXI Lite Bus (axiLiteClk domain)
         axilClk          => pgpClk,
         axilRst          => pgpRst,
         mAxilWriteMaster => mAxilWriteMaster,
         mAxilWriteSlave  => mAxilWriteSlave,
         mAxilReadMaster  => mAxilReadMaster,
         mAxilReadSlave   => mAxilReadSlave);

   -- Lane 0, VC1 TX, streaming data out
   U_AxiStreamFifoV2_1 : entity surf.AxiStreamFifoV2
      generic map (
         TPD_G                  => TPD_G,
         INT_PIPE_STAGES_G      => 1,
         PIPE_STAGES_G          => 1,
         SLAVE_READY_EN_G       => ROGUE_SIM_EN_G,  -- Check his
         VALID_THOLD_G          => 1,
         VALID_BURST_MODE_G     => false,
         MEMORY_TYPE_G          => "block",
         GEN_SYNC_FIFO_G        => true,
         CASCADE_SIZE_G         => 1,
         CASCADE_PAUSE_SEL_G    => 0,
         FIFO_ADDR_WIDTH_G      => 10,              --13,
         FIFO_FIXED_THRESH_G    => true,
         FIFO_PAUSE_THRESH_G    => 2**10-8,         --2**13-6200,
         INT_WIDTH_SELECT_G     => "WIDE",
--         INT_DATA_WIDTH_G       => INT_DATA_WIDTH_G,
         LAST_FIFO_ADDR_WIDTH_G => 0,
         SLAVE_AXI_CONFIG_G     => EVENT_SSI_CONFIG_C,
         MASTER_AXI_CONFIG_G    => PGP4_AXIS_CONFIG_C)
      port map (
         sAxisClk    => dataClk,                    -- [in]
         sAxisRst    => dataRst,                    -- [in]
         sAxisMaster => dataAxisMaster,             -- [in]
         sAxisSlave  => dataAxisSlave,              -- [out]
         sAxisCtrl   => dataAxisCtrl,               -- [out]
         mAxisClk    => pgpClk,                     -- [in]
         mAxisRst    => pgpRst,                     -- [in]
         mAxisMaster => pgpTxMasters(1),            -- [out]
         mAxisSlave  => pgpTxSlaves(1));            -- [in]




end rtl;


-------------------------------------------------------------------------------
-- Title      : LDMX FEB PGP
-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-- Platform   :
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: PGP block for LDMX Tracker FEB
-------------------------------------------------------------------------------
-- This file is part of LDMX. It is subject to
-- the license terms in the LICENSE.txt file found in the top-level directory
-- of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of LDMX, including this file, may be
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
use surf.Pgp2FcPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;

library ldmx;
use ldmx.LdmxPkg.all;
use ldmx.FcPkg.all;

entity LdmxFebPgp is
   generic (
      TPD_G                : time                        := 1 ns;
      ROGUE_SIM_EN_G       : boolean                     := false;
      ROGUE_SIM_SIDEBAND_G : boolean                     := true;
      ROGUE_SIM_PORT_NUM_G : natural range 1024 to 49151 := 9000;
      AXIL_BASE_ADDR_G     : slv(31 downto 0)            := (others => '0');
      AXIL_CLK_FREQ_G      : real                        := 125.0e6);
   port (
      -- Reference clocks for PGP MGTs
      gtRefClk185P : in sl;
      gtRefClk185N : in sl;
      gtRefClk250P : in sl;
      gtRefClk250N : in sl;

      userRefClk125 : out sl;
      userRefRst125 : out sl;

      -- MGT IO
      pgpGtTxP : out slv(2 downto 0);
      pgpGtTxN : out slv(2 downto 0);
      pgpGtRxP : in  slv(2 downto 0);
      pgpGtRxN : in  slv(2 downto 0);

      -- Status output for LEDs
      pgpTxLink : out slv(2 downto 0);
      pgpRxLink : out slv(2 downto 0);

      -- Control link Opcode and AXI-Stream interface
      fcClk185 : out sl;                -- Recovered fixed-latency clock
      fcRst185 : out sl;
      fcMsg    : out FastControlMessageType;
--       daqRxFcWord  : out slv(79 downto 0);
--       daqRxFcValid : out sl;

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
   signal userRefClk185Tmp : sl;
   signal userRefClk185G   : sl;
   signal userRefRst185G   : sl;
   signal gtRefClk185      : sl;

   signal userRefClk250Tmp : sl;
   signal userRefClk125G   : sl;
   signal userRefRst125G   : sl;

   -------------------------------------------------------------------------------------------------
   -- PGP
   -------------------------------------------------------------------------------------------------
   constant NUM_AXIL_C   : integer := 4;
   constant SFP_INDEX_C  : integer := 0;
   constant SAS_INDEX_C  : integer := 1;
   constant QSFP_INDEX_C : integer := 2;
   constant SIM_INDEX_C  : integer := 3;


   signal pgpTxClk     : slv(2 downto 0);
   signal pgpTxRst     : slv(2 downto 0);
   signal pgpRxClk     : slv(2 downto 0);
   signal pgpRxRst     : slv(2 downto 0);
   signal pgpRxIn      : Pgp2fcRxInArray(2 downto 0)          := (others => PGP2FC_RX_IN_INIT_C);
   signal pgpRxOut     : Pgp2fcRxOutArray(2 downto 0);
   signal pgpTxIn      : Pgp2fcTxInArray(2 downto 0)          := (others => PGP2FC_TX_IN_INIT_C);
   signal pgpTxOut     : Pgp2fcTxOutArray(2 downto 0);
   signal pgpRxMasters : AxiStreamQuadMasterArray(2 downto 0);
   signal pgpRxSlaves  : AxiStreamQuadSlaveArray(2 downto 0)  := (others => (others => AXI_STREAM_SLAVE_FORCE_C));
   signal pgpRxCtrl    : AxiStreamQuadCtrlArray(2 downto 0)   := (others => (others => AXI_STREAM_CTRL_UNUSED_C));
   signal pgpTxMasters : AxiStreamQuadMasterArray(2 downto 0) := (others => (others => AXI_STREAM_MASTER_INIT_C));
   signal pgpTxSlaves  : AxiStreamQuadSlaveArray(2 downto 0);

   -------------------------------------------------------------------------------------------------
   -- AXI-Lite
   -------------------------------------------------------------------------------------------------
   constant MAIN_XBAR_CFG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXIL_C-1 downto 0) := genAxiLiteConfig(NUM_AXIL_C, AXIL_BASE_ADDR_G, 24, 20);

   signal locAxilReadMasters  : AxiLiteReadMasterArray(NUM_AXIL_C-1 downto 0)  := (others => AXI_LITE_READ_MASTER_INIT_C);
   signal locAxilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXIL_C-1 downto 0)   := (others => AXI_LITE_READ_SLAVE_EMPTY_DECERR_C);
   signal locAxilWriteMasters : AxiLiteWriteMasterArray(NUM_AXIL_C-1 downto 0) := (others => AXI_LITE_WRITE_MASTER_INIT_C);
   signal locAxilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXIL_C-1 downto 0)  := (others => AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);

   signal fcClk185Tmp : sl;
   signal fcRst185Tmp : sl;

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
         I       => userRefClk185Tmp,
         CE      => '1',
         CEMASK  => '1',
         CLR     => '0',
         CLRMASK => '1',
         DIV     => "000",              -- Divide-by-1
         O       => userRefClk185G);

   U_PwrUpRst_185 : entity surf.PwrUpRst
      generic map (
         TPD_G          => TPD_G,
         SIM_SPEEDUP_G  => ROGUE_SIM_EN_G,
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
         DIV     => "001",              -- Divide-by-2
         O       => userRefClk125G);

   PwrUpRst_1 : entity surf.PwrUpRst
      generic map (
         TPD_G          => TPD_G,
         SIM_SPEEDUP_G  => ROGUE_SIM_EN_G,
         IN_POLARITY_G  => '1',
         OUT_POLARITY_G => '1')
      port map (
         clk    => userRefClk125G,
         rstOut => userRefRst125G);

   userRefClk125 <= userRefClk125G;
   userRefRst125 <= userRefRst125G;

   ---------------------
   -- AXI-Lite Crossbar
   ---------------------
   U_MAIN_XBAR : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => NUM_AXIL_C,
         MASTERS_CONFIG_G   => MAIN_XBAR_CFG_C)
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


   NO_SIM : if (not ROGUE_SIM_EN_G) generate
      PGP_GEN : for i in 2 downto 0 generate

         U_LdmxFebPgp_1 : entity ldmx.LdmxFebPgpLane
            generic map (
               TPD_G            => TPD_G,
               SIMULATION_G     => false,                  -- Set true when runing sim with GTY/PGP
               AXIL_BASE_ADDR_G => MAIN_XBAR_CFG_C(i).baseAddr,
               AXIL_CLK_FREQ_G  => AXIL_CLK_FREQ_G,
               VC_COUNT_G       => 2)
            port map (
               stableClk       => userRefClk125G,          -- [in]
               stableRst       => userRefRst125G,          -- [in]
               gtRefClk185     => gtRefClk185,             -- [in]
               pgpGtTxP        => pgpGtTxP(i),             -- [out]
               pgpGtTxN        => pgpGtTxN(i),             -- [out]
               pgpGtRxP        => pgpGtRxP(i),             -- [in]
               pgpGtRxN        => pgpGtRxN(i),             -- [in]
               pgpTxLink       => pgpTxLink(i),            -- [out]
               pgpRxLink       => pgpRxLink(i),            -- [out]
               pgpRxClkOut     => pgpRxClk(i),             -- [out]
               pgpRxRstOut     => pgpRxRst(i),             -- [out]
               pgpRxOut        => pgpRxOut(i),             -- [out]
               pgpRxMasters    => pgpRxMasters(i),         -- [out]
               pgpRxCtrl       => pgpRxCtrl(i),            -- [in]
               pgpTxClkOut     => pgpTxClk(i),             -- [out]
               pgpTxRstOut     => pgpTxRst(i),             -- [out]
               pgpTxIn         => pgpTxIn(i),              -- [in]
               pgpTxMasters    => pgpTxMasters(i),         -- [in]
               pgpTxSlaves     => pgpTxSlaves(i),          -- [out]
               axilClk         => axilClk,                 -- [in]
               axilRst         => axilRst,                 -- [in]
               axilReadMaster  => locAxilReadMasters(i),   -- [in]
               axilReadSlave   => locAxilReadSlaves(i),    -- [out]
               axilWriteMaster => locAxilWriteMasters(i),  -- [in]
               axilWriteSlave  => locAxilWriteSlaves(i));  -- [out]

      end generate PGP_GEN;

      fcClk185 <= pgpRxClk(SFP_INDEX_C);
      fcRst185 <= pgpRxRst(SFP_INDEX_C);
      fcMsg    <= fcDecode(pgpRxOut(SFP_INDEX_C).fcWord(79 downto 0), pgpRxOut(SFP_INDEX_C).fcValid);
--       daqRxFcWord  <= pgpRxOut(SFP_INDEX_C).fcWord(79 downto 0);
--       daqRxFcValid <= pgpRxOut(SFP_INDEX_C).fcValid;

   end generate NO_SIM;

   GEN_SIM : if (ROGUE_SIM_EN_G) generate

      pgpTxClk(0) <= gtRefClk185;

      PwrUpRst_1 : entity surf.PwrUpRst
         generic map (
            TPD_G          => TPD_G,
            SIM_SPEEDUP_G  => true,
            IN_POLARITY_G  => '1',
            OUT_POLARITY_G => '1')
         port map (
            clk    => pgpTxClk(0),
            rstOut => pgpTxRst(0));

      pgpRxClk(0) <= pgpTxClk(0);
      pgpRxRst(0) <= pgpTxRst(0);

      U_RoguePgp2fcSim_1 : entity surf.RoguePgp2fcSim
         generic map (
            TPD_G      => TPD_G,
            FC_WORDS_G => 5,
            PORT_NUM_G => ROGUE_SIM_PORT_NUM_G,
            NUM_VC_G   => 2)
         port map (
            pgpClk       => pgpTxClk(0),                  -- [in]
            pgpClkRst    => pgpTxRst(0),                  -- [in]
            pgpRxIn      => pgpRxIn(0),                   -- [in]
            pgpRxOut     => pgpRxOut(0),                  -- [out]
            pgpTxIn      => pgpTxIn(0),                   -- [in]
            pgpTxOut     => pgpTxOut(0),                  -- [out]
            pgpTxMasters => pgpTxMasters(0)(1 downto 0),  -- [in]
            pgpTxSlaves  => pgpTxSlaves(0)(1 downto 0),   -- [out]
            pgpRxMasters => pgpRxMasters(0)(1 downto 0),  -- [out]
            pgpRxSlaves  => pgpRxSlaves(0)(1 downto 0));  -- [in]

      DAQ_CLK_GEN : entity surf.ClkRst
         generic map (
            CLK_PERIOD_G      => 5.385 ns,
            CLK_DELAY_G       => 1 ns,
            RST_START_DELAY_G => 0 ns,
            RST_HOLD_TIME_G   => 5 us,
            SYNC_RESET_G      => true)
         port map (
            clkP => fcClk185Tmp,
            rst  => fcRst185Tmp);

      fcClk185 <= fcClk185Tmp;
      fcRst185 <= fcRst185Tmp;

      U_FcEmu_1 : entity ldmx.FcEmu
         generic map (
            TPD_G                => TPD_G,
            AXIL_CLK_IS_FC_CLK_G => false)
         port map (
            fcClk           => fcClk185Tmp,                       -- [in]
            fcRst           => fcRst185Tmp,                       -- [in]
            fcMsg           => fcMsg,                             -- [out]
            bunchClk        => open,                              -- [out]
            bunchStrobe     => open,                              -- [out]
            axilClk         => axilClk,                           -- [in]
            axilRst         => axilRst,                           -- [in]
            axilReadMaster  => locAxilReadMasters(SIM_INDEX_C),   -- [in]
            axilReadSlave   => locAxilReadSlaves(SIM_INDEX_C),    -- [out]
            axilWriteMaster => locAxilWriteMasters(SIM_INDEX_C),  -- [in]
            axilWriteSlave  => locAxilWriteSlaves(SIM_INDEX_C));  -- [out]

--       daqRxFcWord  <= pgpRxOut(0).fcWord(79 downto 0);
--       daqRxFcValid <= pgpRxOut(0).fcValid;


   end generate GEN_SIM;


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
         AXI_STREAM_CONFIG_G => PGP2FC_AXIS_CONFIG_C
         )
      port map (
         -- Streaming Slave (Rx) Interface (sAxisClk domain)
         sAxisClk         => pgpRxClk(SFP_INDEX_C),
         sAxisRst         => pgpRxRst(SFP_INDEX_C),
         sAxisMaster      => pgpRxMasters(SFP_INDEX_C)(0),
         sAxisSlave       => pgpRxSlaves(SFP_INDEX_C)(0),
         sAxisCtrl        => pgpRxCtrl(SFP_INDEX_C)(0),
         -- Streaming Master (Tx) Data Interface (mAxisClk domain)
         mAxisClk         => pgpTxClk(SFP_INDEX_C),
         mAxisRst         => pgpTxRst(SFP_INDEX_C),
         mAxisMaster      => pgpTxMasters(SFP_INDEX_C)(0),
         mAxisSlave       => pgpTxSlaves(SFP_INDEX_C)(0),
         -- AXI Lite Bus (axiLiteClk domain)
         axilClk          => axilClk,
         axilRst          => axilRst,
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
         SLAVE_READY_EN_G       => ROGUE_SIM_EN_G,     -- Check his
         VALID_THOLD_G          => 1,
         VALID_BURST_MODE_G     => false,
         MEMORY_TYPE_G          => "block",
         GEN_SYNC_FIFO_G        => true,
         CASCADE_SIZE_G         => 1,
         CASCADE_PAUSE_SEL_G    => 0,
         FIFO_ADDR_WIDTH_G      => 10,                 --13,
         FIFO_FIXED_THRESH_G    => true,
         FIFO_PAUSE_THRESH_G    => 2**10-8,            --2**13-6200,
         INT_WIDTH_SELECT_G     => "WIDE",
--         INT_DATA_WIDTH_G       => INT_DATA_WIDTH_G,
         LAST_FIFO_ADDR_WIDTH_G => 0,
         SLAVE_AXI_CONFIG_G     => EVENT_SSI_CONFIG_C,
         MASTER_AXI_CONFIG_G    => PGP2FC_AXIS_CONFIG_C)
      port map (
         sAxisClk    => dataClk,                       -- [in]
         sAxisRst    => dataRst,                       -- [in]
         sAxisMaster => dataAxisMaster,                -- [in]
         sAxisSlave  => dataAxisSlave,                 -- [out]
         sAxisCtrl   => dataAxisCtrl,                  -- [out]
         mAxisClk    => pgpTxClk(SFP_INDEX_C),         -- [in]
         mAxisRst    => pgpTxRst(SFP_INDEX_C),         -- [in]
         mAxisMaster => pgpTxMasters(SFP_INDEX_C)(1),  -- [out]
         mAxisSlave  => pgpTxSlaves(SFP_INDEX_C)(1));  -- [in]




end rtl;

-------------------------------------------------------------------------------
-- Title      : Coulter PGP 
-------------------------------------------------------------------------------
-- File       : FetPgp.vhd
-- Author     : Benjamin Reese  <bareese@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2016-06-03
-- Last update: 2023-02-09
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
use surf.Pgp2FcPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;

library ldmx;
use ldmx.HpsPkg.all;

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
   constant SFP_INDEX_C : integer := 0;
   constant SAS_INDEX_C : integer := 1;
   constant QSFP_INDEX_C : integer := 2;


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
   constant MAIN_XBAR_CFG_C : AxiLiteCrossbarMasterConfigArray(2 downto 0) := genAxiLiteConfig(3, AXIL_BASE_ADDR_G, 24, 20);

   signal locAxilReadMasters  : AxiLiteReadMasterArray(2 downto 0);
   signal locAxilReadSlaves   : AxiLiteReadSlaveArray(2 downto 0);
   signal locAxilWriteMasters : AxiLiteWriteMasterArray(2 downto 0);
   signal locAxilWriteSlaves  : AxiLiteWriteSlaveArray(2 downto 0);



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
         DIV     => "001",              -- Divide-by-1
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


   NO_SIM : if (not ROGUE_SIM_EN_G) generate

      ---------------------
      -- AXI-Lite Crossbar
      ---------------------
      U_MAIN_XBAR : entity surf.AxiLiteCrossbar
         generic map (
            TPD_G              => TPD_G,
            NUM_SLAVE_SLOTS_G  => 1,
            NUM_MASTER_SLOTS_G => 3,
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

   end generate NO_SIM;

   daqClk       <= pgpRxClk(SFP_INDEX_C);
   daqRst       <= pgpRxRst(SFP_INDEX_C);
   daqRxFcWord  <= pgpRxOut(SFP_INDEX_C).fcWord(79 downto 0);
   daqRxFcValid <= pgpRxOut(SFP_INDEX_C).fcValid;


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


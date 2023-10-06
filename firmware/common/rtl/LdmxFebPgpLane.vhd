-------------------------------------------------------------------------------
-- Title      : Coulter PGP 
-------------------------------------------------------------------------------
-- File       : FetPgp.vhd
-- Author     : Benjamin Reese  <bareese@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2016-06-03
-- Last update: 2023-09-26
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
use surf.SsiPkg.all;
use surf.SsiCmdMasterPkg.all;

library ldmx;

entity LdmxFebPgpLane is
   generic (
      TPD_G            : time             := 1 ns;
      SIMULATION_G     : boolean          := false;
      AXIL_BASE_ADDR_G : slv(31 downto 0) := (others => '0');
      AXIL_CLK_FREQ_G  : real             := 156.25e6;
      VC_COUNT_G       : integer          := 2);
   port (
      stableClk : in sl;
      stableRst : in sl;

      -- Reference clocks for PGP MGTs
      gtRefClk185  : in sl;
      gtRefClk185G : in sl;

      -- MGT IO
      pgpGtTxP : out sl;
      pgpGtTxN : out sl;
      pgpGtRxP : in  sl;
      pgpGtRxN : in  sl;

      -- Status output for LEDs
      pgpTxLink : out sl;
      pgpRxLink : out sl;

      pgpRxClkOut  : out sl;
      pgpRxRstOut  : out sl;
      pgpRxOut     : out Pgp2fcRxOutType;
      pgpRxMasters : out AxiStreamMasterArray(3 downto 0);
      pgpRxCtrl    : in  AxiStreamCtrlArray(3 downto 0);

      pgpTxClkOut  : out sl;
      pgpTxRstOut  : out sl;
      pgpTxIn      : in  Pgp2fcTxInType;
      pgpTxMasters : in  AxiStreamMasterArray(3 downto 0);
      pgpTxSlaves  : out AxiStreamSlaveArray(3 downto 0);

      -- All AXI-Lite and AXI-Stream interfaces are synchronous with this clock
      axilClk : in sl;                  -- Also Drives PGP stableClk input
      axilRst : in sl;

      -- AXI-Lite slave interface for PGP statuses
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType);
end LdmxFebPgpLane;

architecture rtl of LdmxFebPgpLane is


   -------------------------------------------------------------------------------------------------
   -- AXI-Lite
   -------------------------------------------------------------------------------------------------

   constant AXIL_MASTERS_C : integer := 3;
   constant AXIL_PGP_C     : integer := 0;
   constant AXIL_MISC_C    : integer := 1;
   constant AXIL_GTY_C     : integer := 2;

   constant AXIL_XBAR_CFG_C : AxiLiteCrossbarMasterConfigArray(AXIL_MASTERS_C-1 downto 0) := (
      AXIL_PGP_C      => (
         baseAddr     => AXIL_BASE_ADDR_G,
         addrBits     => 8,
         connectivity => X"0001"),
      AXIL_MISC_C     => (
         baseAddr     => AXIL_BASE_ADDR_G + X"100",
         addrBits     => 8,
         connectivity => X"0001"),
      AXIL_GTY_C      => (
         baseAddr     => AXIL_BASE_ADDR_G + X"10000",
         addrBits     => 16,
         connectivity => X"0001"));

   signal locAxilReadMasters  : AxiLiteReadMasterArray(AXIL_MASTERS_C-1 downto 0);
   signal locAxilReadSlaves   : AxiLiteReadSlaveArray(AXIL_MASTERS_C-1 downto 0);
   signal locAxilWriteMasters : AxiLiteWriteMasterArray(AXIL_MASTERS_C-1 downto 0);
   signal locAxilWriteSlaves  : AxiLiteWriteSlaveArray(AXIL_MASTERS_C-1 downto 0);

   -------------------------------------------------------------------------------------------------
   -- PGP
   -------------------------------------------------------------------------------------------------
   signal pgpTxClkTmp : sl;
   signal pgpTxClk    : sl;
   signal pgpTxRst    : sl;
   signal pgpRxClkTmp : sl;
   signal pgpRxClk    : sl;
   signal pgpRxRst    : sl;
   signal pgpRxIn     : Pgp2fcRxInType := PGP2FC_RX_IN_INIT_C;
   signal pgpRxOutInt : Pgp2fcRxOutType;
   signal pgpTxInInt  : Pgp2fcTxInType := PGP2FC_TX_IN_INIT_C;
   signal pgpTxOut    : Pgp2fcTxOutType;

   signal userTxRst : sl;
   signal userRxRst : sl;

--    signal pgpRxMasters : AxiStreamMasterArray(3 downto 0);
--    signal pgpRxSlaves  : AxiStreamSlaveArray(3 downto 0)  := (others => (others => AXI_STREAM_SLAVE_FORCE_C));
--    signal pgpRxCtrl    : AxiStreamCtrlArray(3 downto 0)   := (others => (others => AXI_STREAM_CTRL_UNUSED_C));
--    signal pgpTxMasters : AxiStreamMasterArray(3 downto 0) := (others => (others => AXI_STREAM_MASTER_INIT_C));
--    signal pgpTxSlaves  : AxiStreamSlaveArray(3 downto 0);


begin

   U_PGP_XBAR : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => AXIL_MASTERS_C,
         MASTERS_CONFIG_G   => AXIL_XBAR_CFG_C)
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilRst,
         sAxiWriteMasters(0) => axilWriteMaster,
         sAxiWriteSlaves(0)  => axilWriteSlave,
         sAxiReadMasters(0)  => axilReadMaster,
         sAxiReadSlaves(0)   => axilReadSlave,
         mAxiWriteMasters    => locAxilWriteMasters,
         mAxiWriteSlaves     => locAxilWriteSlaves,
         mAxiReadMasters     => locAxilReadMasters,
         mAxiReadSlaves      => locAxilReadSlaves);

   -------------------------------
   --       PGP Core            --
   -------------------------------
   U_Pgp2fcGtyUltra_1 : entity surf.Pgp2fcGtyUltra
      generic map (
         TPD_G           => TPD_G,
         SIMULATION_G    => SIMULATION_G,
         FC_WORDS_G      => 5,
         VC_INTERLEAVE_G => 1,
         NUM_VC_EN_G     => 2)
      port map (
         stableClk       => stableClk,                        -- [in]
         stableRst       => stableRst,                        -- [in]
         gtRefClk        => gtRefClk185,                      -- [in]
         gtFabricRefClk  => '0',                              -- [in]
         gtUserRefClk    => gtRefClk185,                      -- [in]
         pgpGtTxP        => pgpGtTxP,                         -- [out]
         pgpGtTxN        => pgpGtTxN,                         -- [out]
         pgpGtRxP        => pgpGtRxP,                         -- [in]
         pgpGtRxN        => pgpGtRxN,                         -- [in]
         pgpTxReset      => pgpTxRst,                         -- [in]
--            pgpTxResetDone   => pgpTxResetDone,    -- [out]
         pgpTxOutClk     => pgpTxClkTmp,                      -- [out]
         pgpTxClk        => pgpTxClk,                         -- [in]
         pgpTxMmcmLocked => '1',                              -- [in]
         pgpRxReset      => pgpRxRst,                         -- [in]
--            pgpRxResetDone   => pgpRxResetDone,    -- [out]
         pgpRxOutClk     => pgpRxClkTmp,                      -- [out]
         pgpRxClk        => pgpRxClk,                         -- [in]
         pgpRxMmcmLocked => '1',                              -- [in]
         pgpRxIn         => pgpRxIn,                          -- [in]
         pgpRxOut        => pgpRxOutInt,                      -- [out]
         pgpTxIn         => pgpTxInInt,                       -- [in]
         pgpTxOut        => pgpTxOut,                         -- [out]
         pgpTxMasters    => pgpTxMasters,                     -- [in]
         pgpTxSlaves     => pgpTxSlaves,                      -- [out]
         pgpRxMasters    => pgpRxMasters,                     -- [out]
--            pgpRxMasterMuxed => pgpRxMasterMuxed,  -- [out]
         pgpRxCtrl       => pgpRxCtrl,                        -- [in]
         axilClk         => axilClk,                          -- [in]
         axilRst         => axilRst,                          -- [in]
         axilReadMaster  => locAxilReadMasters(AXIL_GTY_C),   -- [in]
         axilReadSlave   => locAxilReadSlaves(AXIL_GTY_C),    -- [out]
         axilWriteMaster => locAxilWriteMasters(AXIL_GTY_C),  -- [in]
         axilWriteSlave  => locAxilWriteSlaves(AXIL_GTY_C));  -- [out]

   pgpRxOut <= pgpRxOutInt;

   -------------------------------------------------------------------------------------------------
   -- TX and RX Clock Buffers
   -------------------------------------------------------------------------------------------------
--    U_BUFG_TX : BUFG_GT
--       port map (
--          I       => pgpTxClkTmp,
--          CE      => '1',
--          CEMASK  => '1',
--          CLR     => '0',
--          CLRMASK => '1',
--          DIV     => "000",              -- Divide by 1
--          O       => pgpTxClk);

   pgpTxClk <= pgpTxClkTmp;             -- BUFG_GT moved to inside GT core

   U_PwrUpRst_1 : entity surf.PwrUpRst
      generic map (
         TPD_G         => TPD_G,
         SIM_SPEEDUP_G => SIMULATION_G)
      port map (
         arst   => userTxRst,           -- [in]
         clk    => pgpTxClk,            -- [in]
         rstOut => pgpTxRst);           -- [out]

   pgpTxClkOut <= pgpTxClk;
   pgpTxRstOut <= pgpTxRst;

--    U_BUFG_RX : BUFG_GT
--       port map (
--          I       => pgpRxClkTmp,
--          CE      => '1',
--          CEMASK  => '1',
--          CLR     => '0',
--          CLRMASK => '1',
--          DIV     => "000",              -- Divide by 1
--          O       => pgpRxClk);

   pgpRxClk <= pgpRxClkTmp;             -- BUFG_GT moved inside GT core

   U_PwrUpRst_2 : entity surf.PwrUpRst
      generic map (
         TPD_G         => TPD_G,
         SIM_SPEEDUP_G => SIMULATION_G)
      port map (
         arst   => userRxRst,           -- [in]
         clk    => pgpRxClk,            -- [in]
         rstOut => pgpRxRst);           -- [out]

   pgpRxClkOut <= pgpRxClk;
   pgpRxRstOut <= pgpRxRst;


   --------------
   -- PGP Monitor
   --------------
   U_Pgp2fcAxi_1 : entity surf.Pgp2fcAxi
      generic map (
         TPD_G              => TPD_G,
         COMMON_TX_CLK_G    => false,
         COMMON_RX_CLK_G    => false,
         WRITE_EN_G         => false,
         AXI_CLK_FREQ_G     => AXIL_CLK_FREQ_G,
         FC_WORDS_G         => 5,
         STATUS_CNT_WIDTH_G => 16,
         ERROR_CNT_WIDTH_G  => 16)
      port map (
         pgpTxClk        => pgpTxClk,                         -- [in]
         pgpTxClkRst     => pgpTxRst,                         -- [in]
         pgpTxIn         => pgpTxInInt,                       -- [out]
         pgpTxOut        => pgpTxOut,                         -- [in]
         locTxIn         => pgpTxIn,                          -- [in]
         pgpRxClk        => pgpRxClk,                         -- [in]
         pgpRxClkRst     => pgpRxRst,                         -- [in]
         pgpRxIn         => pgpRxIn,                          -- [out]
         pgpRxOut        => pgpRxOutInt,                      -- [in]
--         locRxIn         => locRxIn,          -- [in]
         axilClk         => axilClk,                          -- [in]
         axilRst         => axilRst,                          -- [in]
         axilReadMaster  => locAxilReadMasters(AXIL_PGP_C),   -- [in]
         axilReadSlave   => locAxilReadSlaves(AXIL_PGP_C),    -- [out]
         axilWriteMaster => locAxilWriteMasters(AXIL_PGP_C),  -- [in]
         axilWriteSlave  => locAxilWriteSlaves(AXIL_PGP_C));  -- [out]

   U_PgpMiscCtrl : entity ldmx.PgpMiscCtrl
      generic map (
         TPD_G => TPD_G)
      port map (
         -- Control/Status  (axilClk domain)
         config          => open,
         txUserRst       => userTxRst,
         rxUserRst       => userRxRst,
         -- AXI Lite interface
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => locAxilReadMasters(AXIL_MISC_C),
         axilReadSlave   => locAxilReadSlaves(AXIL_MISC_C),
         axilWriteMaster => locAxilWriteMasters(AXIL_MISC_C),
         axilWriteSlave  => locAxilWriteSlaves(AXIL_MISC_C));


end rtl;

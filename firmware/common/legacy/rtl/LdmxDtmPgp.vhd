-------------------------------------------------------------------------------
-- Title      : PGP block for LDMX Testbeam DTM
-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
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
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


library surf;
use surf.StdRtlPkg.all;
use surf.Pgp2bPkg.all;
use surf.AxiStreamPkg.all;
use surf.AxiLitePkg.all;
use surf.Gtx7CfgPkg.all;

entity LdmxDtmPgp is

   generic (
      TPD_G            : time             := 1 ns;
      SIMULATION_G     : boolean          := false;
      AXIL_BASE_ADDR_G : slv(31 downto 0) := X"00000000");


   port (
      -- AXI Interface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;

      -- Ref Clock
      locRefClkP : in sl;
      locRefClkM : in sl;

      -- Serial IO
      gtTxP : out sl;
      gtTxN : out sl;
      gtRxP : in  sl;
      gtRxN : in  sl;

      -- refClk
      refClkOut : out sl;

      -- App IO
      l1a        : out sl;
      spill      : out sl;

      busy : in slv(7 downto 0));


end entity LdmxDtmPgp;

architecture rtl of LdmxDtmPgp is

   signal pgpTxClk : sl;
   signal pgpTxRst : sl;
   signal pgpRxClk : sl;
   signal pgpRxRst : sl;

   signal pgpTxIn  : Pgp2bTxInType  := PGP2B_TX_IN_INIT_C;
   signal pgpTxOut : Pgp2bTxOutType := PGP2B_TX_OUT_INIT_C;
   signal locTxIn  : Pgp2bTxInType  := PGP2B_TX_IN_INIT_C;
   signal pgpRxIn  : Pgp2bRxInType  := PGP2B_RX_IN_INIT_C;
   signal pgpRxOut : Pgp2bRxOutType := PGP2B_RX_OUT_INIT_C;
   signal locRxIn  : Pgp2bRxInType  := PGP2B_RX_IN_INIT_C;

   signal locAxilReadMasters  : AxiLiteReadMasterArray(2 downto 0);
   signal locAxilReadSlaves   : AxiLiteReadSlaveArray(2 downto 0);
   signal locAxilWriteMasters : AxiLiteWriteMasterArray(2 downto 0);
   signal locAxilWriteSlaves  : AxiLiteWriteSlaveArray(2 downto 0);

   signal spillTmp : sl;
   signal l1aTmp   : sl;

   signal spillLoc : sl;
   signal l1aLoc   : sl;

   signal spillRst : sl;
   signal l1aRst   : sl;

   signal spillCnt : slv(31 downto 0);
   signal l1aCnt   : slv(31 downto 0);

   signal writeRegister : slv(31 downto 0);

   signal testSpill : sl;
   signal testL1a   : sl;


begin

   U_ClockDivider_1 : entity surf.ClockDivider
      generic map (
         TPD_G         => TPD_G,
         COUNT_WIDTH_G => 16)
      port map (
         clk        => pgpTxClk,         -- [in]
         rst        => pgpTxRst,         -- [in]
         highCount  => X"1000",          -- [in]
         lowCount   => X"1000",          -- [in]
         delayCount => (others => '0'),  -- [in]
         divClk     => open,             -- [out]
         preRise    => testSpill,        -- [out]
         preFall    => open);            -- [out]

   U_ClockDivider_2 : entity surf.ClockDivider
      generic map (
         TPD_G         => TPD_G,
         COUNT_WIDTH_G => 16)
      port map (
         clk        => pgpTxClk,         -- [in]
         rst        => pgpTxRst,         -- [in]
         highCount  => X"0100",          -- [in]
         lowCount   => X"0100",          -- [in]
         delayCount => (others => '0'),  -- [in]
         divClk     => open,             -- [out]
         preRise    => testL1a,          -- [out]
         preFall    => open);            -- [out]

   locTxIn.opCode(0) <= testSpill;
   locTxIn.opCode(1) <= testL1a;
   locTxIn.opCodeEn  <= testSpill or testL1a;


   refClkOut <= pgpTxClk;

   locTxIn.locData <= busy;

   spillTmp <= pgpRxOut.opCodeEn and pgpRxOut.opCode(0);
   l1aTmp   <= pgpRxOut.opCodeEn and pgpRxOut.opCode(1);

   U_RegisterVector_1 : entity surf.RegisterVector
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => 1)
      port map (
         clk      => pgpRxClk,          -- [in]
         rst      => pgpRxRst,          -- [in]
         sig_i(0) => spillTmp,          -- [in]
         reg_o(0) => spillLoc);         -- [out]

   U_RegisterVector_2 : entity surf.RegisterVector
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => 1)
      port map (
         clk      => pgpRxClk,          -- [in]
         rst      => pgpRxRst,          -- [in]
         sig_i(0) => l1aTmp,            -- [in]
         reg_o(0) => l1aLoc);           -- [out]

   l1a   <= l1aLoc;
   spill <= spillLoc;

   U_AxiCrossbar : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => 3,
         DEC_ERROR_RESP_G   => AXI_RESP_OK_C,
         MASTERS_CONFIG_G   => (
            0               => (
               baseAddr     => AXIL_BASE_ADDR_G + x"0000",
               addrBits     => 12,
               connectivity => x"FFFF"),

            1               => (
               baseAddr     => AXIL_BASE_ADDR_G + x"1000",
               addrBits     => 12,
               connectivity => x"FFFF"),
            2               => (
               baseAddr     => AXIL_BASE_ADDR_G + x"2000",
               addrBits     => 12,
               connectivity => x"FFFF")
            )
         ) port map (
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

   U_SynchronizerOneShotCnt_1 : entity surf.SynchronizerOneShotCnt
      generic map (
         TPD_G          => TPD_G,
         CNT_RST_EDGE_G => true,
         CNT_WIDTH_G    => 32)
      port map (
         wrClk      => pgpRxClk,        -- [in]
         wrRst      => pgpRxRst,        -- [in]
         dataIn     => spillLoc,        -- [in]
         rdClk      => axilClk,         -- [in]
         rdRst      => axilRst,         -- [in]
         rollOverEn => '0',             -- [in]
         cntRst     => spillRst,        -- [in]
         dataOut    => open,            -- [out]
         cntOut     => spillCnt);       -- [out]

   U_SynchronizerOneShotCnt_2 : entity surf.SynchronizerOneShotCnt
      generic map (
         TPD_G          => TPD_G,
         CNT_RST_EDGE_G => true,
         CNT_WIDTH_G    => 32)
      port map (
         wrClk      => pgpRxClk,        -- [in]
         wrRst      => pgpRxRst,        -- [in]
         dataIn     => l1aLoc,        -- [in]
         rdClk      => axilClk,         -- [in]
         rdRst      => axilRst,         -- [in]
         rollOverEn => '0',             -- [in]
         cntRst     => l1aRst,          -- [in]
         dataOut    => open,            -- [out]
         cntOut     => l1aCnt);         -- [out]

   U_AxiLiteRegs_1 : entity surf.AxiLiteRegs
      generic map (
         TPD_G           => TPD_G,
         NUM_WRITE_REG_G => 1,
         NUM_READ_REG_G  => 2)
      port map (
         axiClk           => axilClk,                 -- [in]
         axiClkRst        => axilRst,                 -- [in]
         axiReadMaster    => locAxilReadMasters(2),   -- [in]
         axiReadSlave     => locAxilReadSlaves(2),    -- [out]
         axiWriteMaster   => locAxilWriteMasters(2),  -- [in]
         axiWriteSlave    => locAxilWriteSlaves(2),   -- [out]
         writeRegister(0) => writeRegister,           -- [out]
         readRegister(0)  => spillCnt,                -- [in]
         readRegister(1)  => l1aCnt);                 -- [in]

   l1aRst   <= writeRegister(0);
   spillRst <= writeRegister(1);

   U_Pgp2bGtx7FixedLatWrapper_1 : entity surf.Pgp2bGtx7FixedLatWrapper
      generic map (
         TPD_G                 => TPD_G,
         SIM_GTRESET_SPEEDUP_G => ite(SIMULATION_G, "TRUE", "FALSE"),
--         SIM_VERSION_G           => SIM_VERSION_G,
         SIMULATION_G          => SIMULATION_G,
         VC_INTERLEAVE_G       => 0,
         PAYLOAD_CNT_TOP_G     => 7,
         NUM_VC_EN_G           => 1,
         TX_POLARITY_G         => '0',
         RX_POLARITY_G         => '0',
         TX_CM_EN_G            => false,
--          TX_CM_TYPE_G            => TX_CM_TYPE_G,
--          TX_CM_CLKIN_PERIOD_G    => TX_CM_CLKIN_PERIOD_G,
--          TX_CM_DIVCLK_DIVIDE_G   => TX_CM_DIVCLK_DIVIDE_G,
--          TX_CM_CLKFBOUT_MULT_F_G => TX_CM_CLKFBOUT_MULT_F_G,
--          TX_CM_CLKOUT_DIVIDE_F_G => TX_CM_CLKOUT_DIVIDE_F_G,
         RX_CM_EN_G            => true,
         RX_CM_TYPE_G          => "PLL",
         RX_CM_BANDWIDTH_G     => "HIGH",
         RX_CM_CLKIN_PERIOD_G  => 8.000,
         RX_CM_DIVCLK_DIVIDE_G => 1,
         RX_CM_CLKFBOUT_MULT_G => 14,
         RX_CM_CLKOUT_DIVIDE_G => 14,
         PMA_RSV_G             => x"00018480",
         RX_OS_CFG_G           => "0000010000000",
         RXCDR_CFG_G           => x"03000023ff40200020",
         RXDFEXYDEN_G          => '0',
         RX_DFE_KL_CFG2_G      => X"301148AC",
         STABLE_CLK_SRC_G      => "gtClk0Div2",
         TX_REFCLK_SRC_G       => "gtClk0",
         TX_USER_CLK_SRC_G     => "gtClk0Div2",
         TX_OUTCLK_SRC_G       => "PLLREFCLK",
         RX_REFCLK_SRC_G       => "gtClk0",
         CPLL_CFG_G            => getGtx7CPllCfg(250.0e6, 2.5e9),
--         QPLL_CFG_G              => QPLL_CFG_G,
         TX_PLL_G              => "CPLL",
         RX_PLL_G              => "CPLL")
      port map (
--          stableClkIn      => stableClkIn,       -- [in]
--          extRst           => extRst,            -- [in]
--          txPllLock        => txPllLock,         -- [out]
--          rxPllLock        => rxPllLock,         -- [out]
         pgpTxClkOut     => pgpTxClk,                -- [out]
         pgpTxRstOut     => pgpTxRst,                -- [out]
         pgpRxClkOut     => pgpRxClk,                -- [out]
         pgpRxRstOut     => pgpRxRst,                -- [out]
         stableClkOut    => refClkOut,               -- [out]
         pgpRxIn         => pgpRxIn,                 -- [in]
         pgpRxOut        => pgpRxOut,                -- [out]
         pgpTxIn         => pgpTxIn,                 -- [in]
         pgpTxOut        => pgpTxOut,                -- [out]
--          pgpTxMasters     => pgpTxMasters,      -- [in]
--          pgpTxSlaves      => pgpTxSlaves,       -- [out]
--          pgpRxMasters     => pgpRxMasters,      -- [out]
--          pgpRxMasterMuxed => pgpRxMasterMuxed,  -- [out]
--          pgpRxCtrl        => pgpRxCtrl,         -- [in]
--         gtgClk           => gtgClk,            -- [in]
         gtClk0P         => locRefClkP,              -- [in]
         gtClk0N         => locRefClkM,              -- [in]
--          gtClk1P          => gtClk1P,           -- [in]
--          gtClk1N          => gtClk1N,           -- [in]
         gtTxP           => gtTxP,                   -- [out]
         gtTxN           => gtTxN,                   -- [out]
         gtRxP           => gtRxP,                   -- [in]
         gtRxN           => gtRxN,                   -- [in]
--          txPreCursor      => txPreCursor,       -- [in]
--          txPostCursor     => txPostCursor,      -- [in]
--          txDiffCtrl       => txDiffCtrl,        -- [in]
         axilClk         => axilClk,                 -- [in]
         axilRst         => axilRst,                 -- [in]
         axilReadMaster  => locAxilReadMasters(0),   -- [in]
         axilReadSlave   => locAxilReadSlaves(0),    -- [out]
         axilWriteMaster => locAxilWriteMasters(0),  -- [in]
         axilWriteSlave  => locAxilWriteSlaves(0));  -- [out]

   U_Pgp2bAxi_1 : entity surf.Pgp2bAxi
      generic map (
         TPD_G              => TPD_G,
         COMMON_TX_CLK_G    => false,
         COMMON_RX_CLK_G    => false,
         WRITE_EN_G         => true,
         AXI_CLK_FREQ_G     => 125.0e6,              -- check this
         STATUS_CNT_WIDTH_G => 32,
         ERROR_CNT_WIDTH_G  => 16)
      port map (
         pgpTxClk        => pgpTxClk,                -- [in]
         pgpTxClkRst     => pgpTxRst,                -- [in]
         pgpTxIn         => pgpTxIn,                 -- [out]
         pgpTxOut        => pgpTxOut,                -- [in]
         locTxIn         => locTxIn,                 -- [in]
         pgpRxClk        => pgpRxClk,                -- [in]
         pgpRxClkRst     => pgpRxRst,                -- [in]
         pgpRxIn         => pgpRxIn,                 -- [out]
         pgpRxOut        => pgpRxOut,                -- [in]
         locRxIn         => locRxIn,                 -- [in]
         axilClk         => axilClk,                 -- [in]
         axilRst         => axilRst,                 -- [in]
         axilReadMaster  => locAxilReadMasters(1),   -- [in]
         axilReadSlave   => locAxilReadSlaves(1),    -- [out]
         axilWriteMaster => locAxilWriteMasters(1),  -- [in]
         axilWriteSlave  => locAxilWriteSlaves(1));  -- [out]

end architecture rtl;

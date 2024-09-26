-------------------------------------------------------------------------------
-- File       : TrackerPgpFcLane.vhd
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description:
-------------------------------------------------------------------------------
-- This file is part of 'PGP PCIe APP DEV'.
-- It is subject to the license terms in the LICENSE.txt file found in the
-- top-level directory of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of 'PGP PCIe APP DEV', including this file,
-- may be copied, modified, propagated, or distributed except according to
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
use surf.Pgp2fcPkg.all;

-- library axi_pcie_core;
-- use axi_pcie_core.AxiPciePkg.all;

library ldmx_tdaq;

entity LdmxPgpFcLane is
   generic (
      TPD_G            : time                 := 1 ns;
      SIM_SPEEDUP_G    : boolean              := false;
      GT_TYPE_G        : string               := "GTY";  -- Or GTH
      AXIL_CLK_FREQ_G  : real                 := 125.0e6;
      AXIL_BASE_ADDR_G : slv(31 downto 0)     := (others => '0');
      TX_ENABLE_G      : boolean              := true;
      RX_ENABLE_G      : boolean              := true;
      NUM_VC_EN_G      : integer range 0 to 4 := 4;
      RX_CLK_MMCM_G    : boolean              := false);
   port (
      -- PGP Serial Ports
      pgpTxP           : out sl;
      pgpTxN           : out sl;
      pgpRxP           : in  sl;
      pgpRxN           : in  sl;
      pgpRefClk        : in  sl;
      pgpUserRefClk    : in  sl;
      pgpUserStableClk : in  sl;
      -- Rx Interface
      pgpRxRstOut      : out sl;
      pgpRxOutClk      : out sl;
      pgpRxIn          : in  Pgp2fcRxInType                   := PGP2FC_RX_IN_INIT_C;
      pgpRxOut         : out Pgp2fcRxOutType;
      pgpRxMasters     : out AxiStreamMasterArray(3 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
      pgpRxCtrl        : in  AxiStreamCtrlArray(3 downto 0)   := (others => AXI_STREAM_CTRL_UNUSED_C);
      -- Tx Interface
      pgpTxRst         : in  sl                               := '0';
      pgpTxOutClk      : out sl;
      pgpTxUsrClk      : in  sl;
      pgpTxIn          : in  Pgp2fcTxInType                   := PGP2FC_TX_IN_INIT_C;
      pgpTxOut         : out Pgp2fcTxOutType;
      pgpTxMasters     : in  AxiStreamMasterArray(3 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
      pgpTxSlaves      : out AxiStreamSlaveArray(3 downto 0)  := (others => AXI_STREAM_SLAVE_INIT_C);
      -- AXI-Lite Interface (axilClk domain)
      axilClk          : in  sl;
      axilRst          : in  sl;
      axilReadMaster   : in  AxiLiteReadMasterType;
      axilReadSlave    : out AxiLiteReadSlaveType;
      axilWriteMaster  : in  AxiLiteWriteMasterType;
      axilWriteSlave   : out AxiLiteWriteSlaveType);
end LdmxPgpFcLane;

architecture rtl of LdmxPgpFcLane is

   constant NUM_AXIL_MASTERS_C : natural := 4;

   constant GT_INDEX_C     : natural := 0;
   constant PGP2FC_INDEX_C : natural := 1;
   constant TX_MON_INDEX_C : natural := 2;
   constant RX_MON_INDEX_C : natural := 3;

   constant AXIL_XBAR_CFG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXIL_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXIL_MASTERS_C, AXIL_BASE_ADDR_G, 16, 14);

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0) := (others => AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);
   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0)  := (others => AXI_LITE_READ_SLAVE_EMPTY_DECERR_C);

   signal pgpTxInGt  : Pgp2fcTxInType;
   signal pgpTxOutGt : Pgp2fcTxOutType;
   signal pgpRxInGt  : Pgp2fcRxInType;
   signal pgpRxOutGt : Pgp2fcRxOutType;

   signal pgpTxSlavesGt  : AxiStreamSlaveArray(3 downto 0)  := (others => AXI_STREAM_SLAVE_INIT_C);
   signal pgpRxMastersGt : AxiStreamMasterArray(3 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);

   signal pgpTxResetDone    : sl;

   signal pgpRxResetDone    : sl;
   signal pgpRxPmaResetDone : sl;
   signal pgpRxRst          : sl := '0';

   signal pgpRxOutClkGt     : sl;
   signal pgpRxUsrClk       : sl;
   signal pgpRxMmcmLocked   : sl;

   signal pgpUserStableRst  : sl;

   -------------------------------------------------------------------------------------------------
   -- Components
   -------------------------------------------------------------------------------------------------
   component Pgp2fcGtyUltra is
      generic (
         TPD_G               : time                 := 1 ns;
         SIMULATION_G        : boolean              := false;
         -- GT Settings
         SEL_FABRIC_REFCLK_G : boolean              := false;
         -- PGP Settings
         FC_WORDS_G          : integer range 1 to 8 := 1;
         TX_POLARITY_G       : sl                   := '0';
         RX_POLARITY_G       : sl                   := '0';
         AXI_CLK_FREQ_G      : real                 := 125.0e6;
         AXI_BASE_ADDR_G     : slv(31 downto 0)     := (others => '0');
         TX_ENABLE_G         : boolean              := true;
         RX_ENABLE_G         : boolean              := true;
         PAYLOAD_CNT_TOP_G   : integer              := 7;  -- Top bit for payload counter
         VC_INTERLEAVE_G     : integer              := 0;  -- Interleave Frames
         NUM_VC_EN_G         : integer range 1 to 4 := 4);
      port (
         stableClk         : in  sl;
         stableRst         : in  sl;
         gtRefClk          : in  sl;
         gtFabricRefClk    : in  sl;
         gtUserRefClk      : in  sl;
         pgpGtTxP          : out sl;
         pgpGtTxN          : out sl;
         pgpGtRxP          : in  sl;
         pgpGtRxN          : in  sl;
         pgpTxReset        : in  sl;
         pgpTxResetDone    : out sl;
         pgpTxOutClk       : out sl;
         pgpTxClk          : in  sl;
         pgpTxMmcmLocked   : in  sl;
         pgpRxReset        : in  sl;
         pgpRxResetDone    : out sl;
         pgpRxPmaResetDone : out sl;
         pgpRxOutClk       : out sl;
         pgpRxClk          : in  sl;
         pgpRxMmcmLocked   : in  sl;
         pgpRxIn           : in  Pgp2fcRxInType;
         pgpRxOut          : out Pgp2fcRxOutType;
         pgpTxIn           : in  Pgp2fcTxInType;
         pgpTxOut          : out Pgp2fcTxOutType;
         pgpTxMasters      : in  AxiStreamMasterArray(3 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
         pgpTxSlaves       : out AxiStreamSlaveArray(3 downto 0);
         pgpRxMasters      : out AxiStreamMasterArray(3 downto 0);
         pgpRxMasterMuxed  : out AxiStreamMasterType;
         pgpRxCtrl         : in  AxiStreamCtrlArray(3 downto 0);
         axilClk           : in  sl                               := '0';
         axilRst           : in  sl                               := '0';
         axilReadMaster    : in  AxiLiteReadMasterType            := AXI_LITE_READ_MASTER_INIT_C;
         axilReadSlave     : out AxiLiteReadSlaveType;
         axilWriteMaster   : in  AxiLiteWriteMasterType           := AXI_LITE_WRITE_MASTER_INIT_C;
         axilWriteSlave    : out AxiLiteWriteSlaveType);
   end component Pgp2fcGtyUltra;

   component Pgp2fcGthUltra is
      generic (
         TPD_G               : time                 := 1 ns;
         SIMULATION_G        : boolean              := false;
         -- GT Settings
         SEL_FABRIC_REFCLK_G : boolean              := false;
         -- PGP Settings
         FC_WORDS_G          : integer range 1 to 8 := 1;
         TX_POLARITY_G       : sl                   := '0';
         RX_POLARITY_G       : sl                   := '0';
         AXI_CLK_FREQ_G      : real                 := 125.0e6;
         AXI_BASE_ADDR_G     : slv(31 downto 0)     := (others => '0');
         TX_ENABLE_G         : boolean              := true;
         RX_ENABLE_G         : boolean              := true;
         PAYLOAD_CNT_TOP_G   : integer              := 7;  -- Top bit for payload counter
         VC_INTERLEAVE_G     : integer              := 0;  -- Interleave Frames
         NUM_VC_EN_G         : integer range 1 to 4 := 4);
      port (
         stableClk         : in  sl;
         stableRst         : in  sl;
         gtRefClk          : in  sl;
         gtFabricRefClk    : in  sl;
         gtUserRefClk      : in  sl;
         pgpGtTxP          : out sl;
         pgpGtTxN          : out sl;
         pgpGtRxP          : in  sl;
         pgpGtRxN          : in  sl;
         pgpTxReset        : in  sl;
         pgpTxResetDone    : out sl;
         pgpTxOutClk       : out sl;
         pgpTxClk          : in  sl;
         pgpTxMmcmLocked   : in  sl;
         pgpRxReset        : in  sl;
         pgpRxResetDone    : out sl;
         pgpRxPmaResetDone : out sl;
         pgpRxOutClk       : out sl;
         pgpRxClk          : in  sl;
         pgpRxMmcmLocked   : in  sl;
         pgpRxIn           : in  Pgp2fcRxInType;
         pgpRxOut          : out Pgp2fcRxOutType;
         pgpTxIn           : in  Pgp2fcTxInType;
         pgpTxOut          : out Pgp2fcTxOutType;
         pgpTxMasters      : in  AxiStreamMasterArray(3 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
         pgpTxSlaves       : out AxiStreamSlaveArray(3 downto 0);
         pgpRxMasters      : out AxiStreamMasterArray(3 downto 0);
         pgpRxMasterMuxed  : out AxiStreamMasterType;
         pgpRxCtrl         : in  AxiStreamCtrlArray(3 downto 0);
         axilClk           : in  sl                               := '0';
         axilRst           : in  sl                               := '0';
         axilReadMaster    : in  AxiLiteReadMasterType            := AXI_LITE_READ_MASTER_INIT_C;
         axilReadSlave     : out AxiLiteReadSlaveType;
         axilWriteMaster   : in  AxiLiteWriteMasterType           := AXI_LITE_WRITE_MASTER_INIT_C;
         axilWriteSlave    : out AxiLiteWriteSlaveType);
   end component Pgp2fcGthUltra;

begin

   ---------------------
   -- AXI-Lite Crossbar
   ---------------------
   U_XBAR : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => NUM_AXIL_MASTERS_C,
         MASTERS_CONFIG_G   => AXIL_XBAR_CFG_C)
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilRst,
         sAxiWriteMasters(0) => axilWriteMaster,
         sAxiWriteSlaves(0)  => axilWriteSlave,
         sAxiReadMasters(0)  => axilReadMaster,
         sAxiReadSlaves(0)   => axilReadSlave,
         mAxiWriteMasters    => axilWriteMasters,
         mAxiWriteSlaves     => axilWriteSlaves,
         mAxiReadMasters     => axilReadMasters,
         mAxiReadSlaves      => axilReadSlaves);

   -----------
   -- PGP Core
   -----------
   GEN_GTY : if (GT_TYPE_G = "GTY") generate
      U_Pgp : Pgp2fcGtyUltra
         generic map (
            TPD_G           => TPD_G,
            SIMULATION_G    => SIM_SPEEDUP_G,
            AXI_CLK_FREQ_G  => AXIL_CLK_FREQ_G,
            AXI_BASE_ADDR_G => AXIL_BASE_ADDR_G,
            TX_ENABLE_G     => TX_ENABLE_G,
            RX_ENABLE_G     => RX_ENABLE_G,
            FC_WORDS_G      => 5,
            VC_INTERLEAVE_G => 1,
            NUM_VC_EN_G     => ite(NUM_VC_EN_G = 0, 1, NUM_VC_EN_G))
         port map (
            -- GT Clocking
            stableClk         => pgpUserStableClk,              -- [in]
            stableRst         => pgpUserStableRst,              -- [in]
            gtRefClk          => pgpRefClk,                     -- [in]
            gtFabricRefClk    => '0',                           -- [in]
            gtUserRefClk      => pgpUserRefClk,                 -- [in]
            -- Gt Serial IO
            pgpGtTxP          => pgpTxP,                        -- [out]
            pgpGtTxN          => pgpTxN,                        -- [out]
            pgpGtRxP          => pgpRxP,                        -- [in]
            pgpGtRxN          => pgpRxN,                        -- [in]
            -- Tx Clocking
            pgpTxReset        => pgpTxRst,                      -- [in]
            pgpTxResetDone    => pgpTxResetDone,                -- [out]
            pgpTxOutClk       => pgpTxOutClk,                   -- [out]
            pgpTxClk          => pgpTxUsrClk,                   -- [in]
            pgpTxMmcmLocked   => '1',                           -- [in]
            -- Rx clocking
            pgpRxReset        => pgpRxRst,                      -- [in]
            pgpRxResetDone    => pgpRxResetDone,                -- [out]
            pgpRxPmaResetDone => pgpRxPmaResetDone,             -- [out]
            pgpRxOutClk       => pgpRxOutClkGt,                 -- [out]
            pgpRxClk          => pgpRxUsrClk,                   -- [in]
            pgpRxMmcmLocked   => pgpRxMmcmLocked,               -- [in]
            -- Non VC Rx Signals
            pgpRxIn           => pgpRxInGt,                     -- [in]
            pgpRxOut          => pgpRxOutGt,                    -- [out]
            -- Non VC Tx Signals
            pgpTxIn           => pgpTxInGt,                     -- [in]
            pgpTxOut          => pgpTxOutGt,                    -- [out]
            -- Frame Transmit Interface
            pgpTxMasters      => pgpTxMasters,                  -- [in]
            pgpTxSlaves       => pgpTxSlavesGt,                 -- [out]
            -- Frame Receive Interface
            pgpRxMasters      => pgpRxMastersGt,                -- [out]
            pgpRxCtrl         => pgpRxCtrl,                     -- [in]
            -- AXI-Lite Interface
            axilClk           => axilClk,                       -- [in]
            axilRst           => axilRst,                       -- [in]
            axilReadMaster    => axilReadMasters(GT_INDEX_C),   -- [in]
            axilReadSlave     => axilReadSlaves(GT_INDEX_C),    -- [out]
            axilWriteMaster   => axilWriteMasters(GT_INDEX_C),  -- [in]
            axilWriteSlave    => axilWriteSlaves(GT_INDEX_C));  -- [out]
   end generate GEN_GTY;

   GEN_GTH : if (GT_TYPE_G = "GTH") generate
      U_Pgp : Pgp2fcGthUltra
         generic map (
            TPD_G           => TPD_G,
            SIMULATION_G    => SIM_SPEEDUP_G,
            AXI_CLK_FREQ_G  => AXIL_CLK_FREQ_G,
            AXI_BASE_ADDR_G => AXIL_BASE_ADDR_G,
            TX_ENABLE_G     => TX_ENABLE_G,
            RX_ENABLE_G     => RX_ENABLE_G,
            FC_WORDS_G      => 5,
            VC_INTERLEAVE_G => 1,
            NUM_VC_EN_G     => ite(NUM_VC_EN_G = 0, 1, NUM_VC_EN_G))
         port map (
            -- GT Clocking
            stableClk         => pgpUserStableClk,              -- [in]
            stableRst         => pgpUserStableRst,              -- [in]
            gtRefClk          => pgpRefClk,                     -- [in]
            gtFabricRefClk    => '0',                           -- [in]
            gtUserRefClk      => pgpUserRefClk,                 -- [in]
            -- Gt Serial IO
            pgpGtTxP          => pgpTxP,                        -- [out]
            pgpGtTxN          => pgpTxN,                        -- [out]
            pgpGtRxP          => pgpRxP,                        -- [in]
            pgpGtRxN          => pgpRxN,                        -- [in]
            -- Tx Clocking
            pgpTxReset        => pgpTxRst,                      -- [in]
            pgpTxResetDone    => pgpTxResetDone,                -- [out]
            pgpTxOutClk       => pgpTxOutClk,                   -- [out]
            pgpTxClk          => pgpTxUsrClk,                   -- [in]
            pgpTxMmcmLocked   => '1',                           -- [in]
            -- Rx clocking
            pgpRxReset        => pgpRxRst,                      -- [in]
            pgpRxResetDone    => pgpRxResetDone,                -- [out]
            pgpRxPmaResetDone => pgpRxPmaResetDone,             -- [out]
            pgpRxOutClk       => pgpRxOutClkGt,                 -- [out]
            pgpRxClk          => pgpRxUsrClk,                   -- [in]
            pgpRxMmcmLocked   => pgpRxMmcmLocked,               -- [in]
            -- Non VC Rx Signals
            pgpRxIn           => pgpRxInGt,                     -- [in]
            pgpRxOut          => pgpRxOutGt,                    -- [out]
            -- Non VC Tx Signals
            pgpTxIn           => pgpTxInGt,                     -- [in]
            pgpTxOut          => pgpTxOutGt,                    -- [out]
            -- Frame Transmit Interface
            pgpTxMasters      => pgpTxMasters,                  -- [in]
            pgpTxSlaves       => pgpTxSlavesGt,                 -- [out]
            -- Frame Receive Interface
            pgpRxMasters      => pgpRxMastersGt,                -- [out]
            pgpRxCtrl         => pgpRxCtrl,                     -- [in]
            -- AXI-Lite Interface
            axilClk           => axilClk,                       -- [in]
            axilRst           => axilRst,                       -- [in]
            axilReadMaster    => axilReadMasters(GT_INDEX_C),   -- [in]
            axilReadSlave     => axilReadSlaves(GT_INDEX_C),    -- [out]
            axilWriteMaster   => axilWriteMasters(GT_INDEX_C),  -- [in]
            axilWriteSlave    => axilWriteSlaves(GT_INDEX_C));  -- [out]
   end generate GEN_GTH;


   -------------------------------------------------------------------------------------------------
   -- Tie Streaming IO to PGP module
   -------------------------------------------------------------------------------------------------
   pgpTxSlaves  <= pgpTxSlavesGt;
   pgpRxMasters <= pgpRxMastersGt;

   RX_CLK_MMCM_GEN : if (RX_CLK_MMCM_G) generate
      U_ClockManager : entity surf.ClockManagerUltraScale
         generic map(
            TPD_G              => TPD_G,
            TYPE_G             => "MMCM",
            INPUT_BUFG_G       => false,
            FB_BUFG_G          => true,
            RST_IN_POLARITY_G  => '0',
            NUM_CLOCKS_G       => 1,
            -- MMCM attributes
            BANDWIDTH_G        => "OPTIMIZED",
            CLKIN_PERIOD_G     => 5.384,
            DIVCLK_DIVIDE_G    => 1,
            CLKFBOUT_MULT_F_G  => 6.500,
            CLKOUT0_DIVIDE_F_G => 6.500)
         port map(
            clkIn     => pgpRxOutClkGt,
            rstIn     => pgpRxPmaResetDone,
            clkOut(0) => pgpRxUsrClk,
            rstOut    => open,
            locked    => pgpRxMmcmLocked);

   end generate RX_CLK_MMCM_GEN;

   NO_RX_CLK_MMCM_GEN : if (not RX_CLK_MMCM_G) generate
      pgpRxUsrClk     <= pgpRxOutClkGt;
      pgpRxMmcmLocked <= '1';
   end generate NO_RX_CLK_MMCM_GEN;

   -- Output the recovered clock
   pgpRxOutClk <= pgpRxUsrClk;

   --------------
   -- PGP Monitor
   --------------
   U_PgpMon : entity surf.Pgp2fcAxi
      generic map (
         TPD_G              => TPD_G,
         COMMON_TX_CLK_G    => false,
         COMMON_RX_CLK_G    => false,
         WRITE_EN_G         => true,
         AXI_CLK_FREQ_G     => AXIL_CLK_FREQ_G,
         STATUS_CNT_WIDTH_G => 12,
         ERROR_CNT_WIDTH_G  => 18)
      port map (
         -- TX PGP Interface (pgpTxClk)
         pgpTxClk        => pgpTxUsrClk,
         pgpTxClkRst     => pgpTxRst,
         pgpTxIn         => pgpTxInGt,
         pgpTxOut        => pgpTxOutGt,
         locTxIn         => pgpTxIn,
         -- RX PGP Interface (pgpRxClk)
         pgpRxClk        => pgpRxUsrClk,
         pgpRxClkRst     => pgpRxRst,
         pgpRxIn         => pgpRxInGt,
         pgpRxOut        => pgpRxOutGt,
         locRxIn         => pgpRxIn,
         -- AXI-Lite Register Interface (axilClk domain)
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMasters(PGP2FC_INDEX_C),
         axilReadSlave   => axilReadSlaves(PGP2FC_INDEX_C),
         axilWriteMaster => axilWriteMasters(PGP2FC_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(PGP2FC_INDEX_C));

   pgpTxOut <= pgpTxOutGt;
   pgpRxOut <= pgpRxOutGt;

   GEN_MON : if NUM_VC_EN_G > 0 generate

      -----------------------------
      -- Monitor the PGP TX streams
      -----------------------------
      U_AXIS_TX_MON : entity surf.AxiStreamMonAxiL
         generic map(
            TPD_G            => TPD_G,
            COMMON_CLK_G     => false,
            AXIS_CLK_FREQ_G  => 185.71e6,
            AXIS_NUM_SLOTS_G => NUM_VC_EN_G,
            AXIS_CONFIG_G    => PGP2FC_AXIS_CONFIG_C)
         port map(
            -- AXIS Stream Interface
            axisClk          => pgpTxUsrClk,
            axisRst          => pgpTxRst,
            axisMasters      => pgpTxMasters(NUM_VC_EN_G-1 downto 0),
            axisSlaves       => pgpTxSlavesGt(NUM_VC_EN_G-1 downto 0),
            -- AXI lite slave port for register access
            axilClk          => axilClk,
            axilRst          => axilRst,
            sAxilWriteMaster => axilWriteMasters(TX_MON_INDEX_C),
            sAxilWriteSlave  => axilWriteSlaves(TX_MON_INDEX_C),
            sAxilReadMaster  => axilReadMasters(TX_MON_INDEX_C),
            sAxilReadSlave   => axilReadSlaves(TX_MON_INDEX_C));

      -----------------------------
      -- Monitor the PGP RX streams
      -----------------------------
      U_AXIS_RX_MON : entity surf.AxiStreamMonAxiL
         generic map(
            TPD_G            => TPD_G,
            COMMON_CLK_G     => false,
            AXIS_CLK_FREQ_G  => 185.71e6,
            AXIS_NUM_SLOTS_G => NUM_VC_EN_G,
            AXIS_CONFIG_G    => PGP2FC_AXIS_CONFIG_C)
         port map(
            -- AXIS Stream Interface
            axisClk          => pgpRxUsrClk,
            axisRst          => pgpRxRst,
            axisMasters      => pgpRxMastersGt(NUM_VC_EN_G-1 downto 0),
            axisSlaves       => (others => AXI_STREAM_SLAVE_FORCE_C),  -- SLAVE_READY_EN_G=false
            -- AXI lite slave port for register access
            axilClk          => axilClk,
            axilRst          => axilRst,
            sAxilWriteMaster => axilWriteMasters(RX_MON_INDEX_C),
            sAxilWriteSlave  => axilWriteSlaves(RX_MON_INDEX_C),
            sAxilReadMaster  => axilReadMasters(RX_MON_INDEX_C),
            sAxilReadSlave   => axilReadSlaves(RX_MON_INDEX_C));

   end generate GEN_MON;


--    U_Wtd : entity surf.WatchDogRst
--       generic map(
--          TPD_G      => TPD_G,
--          DURATION_G => getTimeRatio(AXI_CLK_FREQ_G, 0.2))  -- 5 s timeout
--       port map (
--          clk    => axilClk,
--          monIn  => pgpRxOut.remLinkReady,
--          rstOut => wdtRst);

--    U_PwrUpRst : entity surf.PwrUpRst
--       generic map (
--          TPD_G         => TPD_G,
--          SIM_SPEEDUP_G => false,
--          DURATION_G    => getTimeRatio(AXI_CLK_FREQ_G, 10.0))  -- 100 ms reset pulse
--       port map (
--          clk    => axilClk,
--          arst   => wdtRst,
--          rstOut => pwrUpRstOut);

--    U_RstSync_Tx : entity surf.RstSync
--       generic map (
--          TPD_G => TPD_G)
--       port map (
--          clk      => pgpTxClk,          -- [in]
--          asyncRst => pgpTxRstAsync,     -- [in]
--          syncRst  => pgpTxRst);         -- [out]

--    U_RstSync_Rx : entity surf.RstSync
--       generic map (
--          TPD_G         => TPD_G,
--          IN_POLARITY_G => '0')
--       port map (
--          clk      => pgpRxUsrClk,       -- [in]
--          asyncRst => pgpRxResetDone,    -- [in]
--          syncRst  => pgpRxRst);         -- [out]

    U_RstSync_StableRst : entity surf.RstSync
       generic map (
          TPD_G => TPD_G)
       port map (
          clk      => pgpUserStableClk,  -- [in]
          asyncRst => axilRst,           -- [in]
          syncRst  => pgpUserStableRst); -- [out]

   pgpRxRstOut <= pgpRxRst;

end rtl;

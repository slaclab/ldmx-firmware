-------------------------------------------------------------------------------
-- Title      : Coulter PGP 
-------------------------------------------------------------------------------
-- File       : FetPgp.vhd
-- Author     : Benjamin Reese  <bareese@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2016-06-03
-- Last update: 2022-11-28
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
      AXIL_CLK_FREQ_G      : real                        := 156.25e6;
      VC_COUNT_G           : integer                     := 2);
   port (
      stableClk : in sl;
      stableRst : in sl;

      -- Reference clocks for PGP MGTs
      gtRefClk185 : in sl;

      -- MGT IO
      pgpGtTxP : out sl;
      pgpGtTxN : out sl;
      pgpGtRxP : in  sl;
      pgpGtRxN : in  sl;

      -- Status output for LEDs
      pgpTxLink : out sl;
      pgpRxLink : out sl;



      -- Control link Opcode and AXI-Stream interface
      daqClk       : out sl;            -- Recovered fixed-latency clock
      daqRst       : out sl;
      daqRxFcWord  : out slv(79 downto 0);
      daqRxFcValid : out sl;

      -- All AXI-Lite and AXI-Stream interfaces are synchronous with this clock
      axilClk : in sl;                  -- Also Drives PGP stableClk input
      axilRst : in sl;

      -- AXI-Lite slave interface for PGP statuses
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType);
end LdmxFebPgp;

architecture rtl of LdmxFebPgp is


   -------------------------------------------------------------------------------------------------
   -- AXI-Lite
   -------------------------------------------------------------------------------------------------

   constant PGP_AXIL_MASTERS_C : integer := 3;
   constant PGP_AXIL_PGP_C     : integer := 0;
   constant PGP_AXIL_MISC_C    : integer := 1;
   constant PGP_AXIL_GTY_C     : integer := 2;

   constant AXIL_XBAR_CFG_C : AxiLiteCrossbarMasterConfigArray(PGP_AXIL_MASTERS_C-1 downto 0) := (
      PGP_AXIL_PGP_C  => (
         baseAddr     => AXIL_BASE_ADDR_G,
         addrBits     => 8,
         connectivity => X"0001");
      PGP_AXIL_MISC_C => (
         baseAddr     => AXIL_BASE_ADDR_G + X"100",
         addrBits     => 8,
         connectivity => X"0001");
      PGP_AXIL_GTY_C  => (
         baseAddr     => AXIL_BASE_ADDR_G + X"10000",
         addrBits     => 16,
         connectivity => X"0001"));

   signal locAxilReadMasters  : AxiLiteReadMasterArray(PGP_AXIL_MASTERS_C-1 downto 0);
   signal locAxilReadSlaves   : AxiLiteReadSlaveArray(PGP_AXIL_MASTERS_C-1 downto 0);
   signal locAxilWriteMasters : AxiLiteWriteMasterArray(PGP_AXIL_MASTERS_C-1 downto 0);
   signal locAxilWriteSlaves  : AxiLiteWriteSlaveArray(PGP_AXIL_MASTERS_C-1 downto 0);

   -------------------------------------------------------------------------------------------------
   -- PGP
   -------------------------------------------------------------------------------------------------
   signal pgpTxClk     : sl;
   signal pgpTxRst     : sl;
   signal pgpRxClk     : sl;
   signal pgpRxRst     : sl;
   signal pgpRxIn      : Pgp2fcRxInType                   := (others => PGP2FC_RX_IN_INIT_C);
   signal pgpRxOut     : Pgp2fcRxOutType;
   signal pgpTxIn      : Pgp2fcTxInType                   := (others => PGP2FC_TX_IN_INIT_C);
   signal pgpTxOut     : Pgp2fcTxOutType;
   signal pgpRxFcWord  : slv(79 downto 0)                 := (others => (others => '0'));
   signal pgpRxFcValid : sl;
   signal pgpTxFcWord  : slv(79 downto 0)                 := (others => (others => '0'));
   signal pgpTxFcValid : sl                               := '0';
   signal pgpRxMasters : AxiStreamMasterArray(3 downto 0);
   signal pgpRxSlaves  : AxiStreamSlaveArray(3 downto 0)  := (others => (others => AXI_STREAM_SLAVE_FORCE_C));
   signal pgpRxCtrl    : AxiStreamCtrlArray(3 downto 0)   := (others => (others => AXI_STREAM_CTRL_UNUSED_C));
   signal pgpTxMasters : AxiStreamMasterArray(3 downto 0) := (others => (others => AXI_STREAM_MASTER_INIT_C));
   signal pgpTxSlaves  : AxiStreamSlaveArray(3 downto 0);


begin

   U_PGP_XBAR : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => AXIL_MASTERS_G,
         MASTERS_CONFIG_G   => AXIL_XBAR_CFG_G)
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilRst,
         sAxiWriteMasters(0) => axilWriteMasters,
         sAxiWriteSlaves(0)  => axilWriteSlaves,
         sAxiReadMasters(0)  => axilReadMasters,
         sAxiReadSlaves(0)   => axilReadSlaves,
         mAxiWriteMasters    => locAxilWriteMasters(i),
         mAxiWriteSlaves     => locAxilWriteSlaves(i),
         mAxiReadMasters     => locAxilReadMasters(i),
         mAxiReadSlaves      => locAxilReadSlaves(i));



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
         stableClk       => stableClk,                            -- [in]
         stableRst       => stableRst,                            -- [in]
         gtRefClk        => gtRefClk185,                          -- [in]
         pgpGtTxP        => pgpGtTxP,                             -- [out]
         pgpGtTxN        => pgpGtTxN,                             -- [out]
         pgpGtRxP        => pgpGtRxP,                             -- [in]
         pgpGtRxN        => pgpGtRxN,                             -- [in]
         pgpTxReset      => pgpTxRst,                             -- [in]
--            pgpTxResetDone   => pgpTxResetDone,    -- [out]
         pgpTxOutClk     => pgpTxOutClk,                          -- [out]
         pgpTxClk        => pgpTxClk,                             -- [in]
         pgpTxMmcmLocked => '1',                                  -- [in]
         pgpRxReset      => pgpRxRst,                             -- [in]
--            pgpRxResetDone   => pgpRxResetDone,    -- [out]
         pgpRxOutClk     => pgpRxOutClk,                          -- [out]
         pgpRxClk        => pgpRxClk,                             -- [in]
         pgpRxMmcmLocked => '1',                                  -- [in]
         pgpRxIn         => pgpRxIn,                              -- [in]
         pgpRxOut        => pgpRxOut,                             -- [out]
         pgpTxIn         => pgpTxIn,                              -- [in]
         pgpTxOut        => pgpTxOut,                             -- [out]
         pgpTxMasters    => pgpTxMasters,                         -- [in]
         pgpTxSlaves     => pgpTxSlaves,                          -- [out]
         pgpRxMasters    => pgpRxMasters,                         -- [out]
--            pgpRxMasterMuxed => pgpRxMasterMuxed,  -- [out]
         pgpRxCtrl       => pgpRxCtrl,                            -- [in]
         axilClk         => axilClk,                              -- [in]
         axilRst         => axilRst,                              -- [in]
         axilReadMaster  => locAxilReadMasters(PGP_AXIL_GTY_C),   -- [in]
         axilReadSlave   => locAxilReadSlaves(PGP_AXIL_GTY_C),    -- [out]
         axilWriteMaster => locAxilWriteMasters(PGP_AXIL_GTY_C),  -- [in]
         axilWriteSlave  => locAxilWriteSlaves(PGP_AXIL_GTY_C));  -- [out]

   U_BUFG_TX : BUFG_GT
      port map (
         I       => pgpTxOutClk,
         CE      => '1',
         CEMASK  => '1',
         CLR     => '0',
         CLRMASK => '1',
         DIV     => "000",              -- Divide by 1
         O       => pgpTxClk);

   U_BUFG_RX : BUFG_GT
      port map (
         I       => pgpRxOutClk,
         CE      => '1',
         CEMASK  => '1',
         CLR     => '0',
         CLRMASK => '1',
         DIV     => "000",              -- Divide by 1
         O       => pgpRxClk);

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
         pgpTxClk        => pgpTxClk,
         pgpTxClkRst     => pgpTxReset,
         pgpTxIn         => pgpTxIn,
         pgpTxOut        => pgpTxOut,
         -- RX PGP Interface (pgpRxClk)
         pgpRxClk        => pgpRxClk,
         pgpRxClkRst     => pgpRxReset,
         pgpRxIn         => pgpRxIn,
         pgpRxOut        => pgpRxOut,
         -- AXI-Lite Register Interface (axilClk domain)
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => locAxilReadMasters(PGP_AXIL_PGP_C),
         axilReadSlave   => locAxilReadSlaves(PGP_AXIL_PGP_C),
         axilWriteMaster => locAxilWriteMasters(PGP_AXIL_PGP_C),
         axilWriteSlave  => locAxilWriteSlaves(PGP_AXIL_PGP_C));

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
         axilReadMaster  => locAxilReadMasters(PGP_AXIL_MISC_C),
         axilReadSlave   => locAxilReadSlaves(PGP_AXIL_MISC_C),
         axilWriteMaster => locAxilWriteMasters(PGP_AXIL_MISC_C),
         axilWriteSlave  => locAxilWriteSlaves(PGP_AXIL_MISC_C));



   pgpRxIn.resetRx  <= '0';
   pgpRxIn.loopback <= "000";

end rtl;

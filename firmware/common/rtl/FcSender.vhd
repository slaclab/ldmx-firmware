-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- Author     : Benjamin Reese  <bareese@slac.stanford.edu>
-------------------------------------------------------------------------------
-- Description: Sends one lane of Fast Control
-------------------------------------------------------------------------------
-- Copyright (c) 2013 SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library UNISIM;
use UNISIM.VCOMPONENTS.all;


library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
use surf.Pgp2FcPkg.all;

library ldmx;
--use ldmx.LdmxPkg.all;
use ldmx.FcPkg.all;


entity FcSender is

   generic (
      TPD_G            : time             := 1 ns;
      SIM_SPEEDUP_G    : boolean          := false;
      AXIL_CLK_FREQ_G  : real             := 125.0e6;
      AXIL_BASE_ADDR_G : slv(31 downto 0) := (others => '0'));
   port (
      -- Reference clock
      lclsTimingRecClkIn : in sl;
      -- PGP FC serial IO
      fcHubTxP            : out sl;
      fcHubTxN            : out sl;
      fcHubRxP            : in  sl;
      fcHubRxN            : in  sl;
      -- Interface to Global Trigger and LCLS Timing
      lclsTimingUserClk   : in  sl;
      lclsTimingUserRst   : in  sl;
      fcTxMsg             : in  FastControlMessageType;
      -- Axil inteface
      axilClk             : in  sl;
      axilRst             : in  sl;
      axilReadMaster      : in  AxiLiteReadMasterType;
      axilReadSlave       : out AxiLiteReadSlaveType;
      axilWriteMaster     : in  AxiLiteWriteMasterType;
      axilWriteSlave      : out AxiLiteWriteSlaveType);

end entity FcSender;

architecture rtl of FcSender is

   -- AXI Lite
   constant NUM_AXIL_MASTERS_C : natural := 3;
   constant PGP_FC_LANE_AXIL_C : natural := 0;
   constant FC_RX_LOGIC_AXIL_C : natural := 1;
   constant FC_EMU_AXIL_C      : natural := 2;

   constant AXIL_XBAR_CFG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXIL_MASTERS_C-1 downto 0) := (
      PGP_FC_LANE_AXIL_C => (
         baseAddr        => AXIL_BASE_ADDR_G + X"0_0000",
         addrBits        => 16,
         connectivity    => X"FFFF"),
      FC_RX_LOGIC_AXIL_C => (
         baseAddr        => AXIL_BASE_ADDR_G + X"1_0000",
         addrBits        => 8,
         connectivity    => X"FFFF"),
      FC_EMU_AXIL_C      => (
         baseAddr        => AXIL_BASE_ADDR_G + X"2_0000",
         addrBits        => 8,
         connectivity    => X"FFFF"));

   signal locAxilWriteMasters : AxiLiteWriteMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal locAxilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0) := (others => AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);
   signal locAxilReadMasters  : AxiLiteReadMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal locAxilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0)  := (others => AXI_LITE_READ_SLAVE_EMPTY_DECERR_C);

   -- Clocks and resets
   signal pgpRefClk          : sl;      -- Refclk after buffering   
   signal pgpUserRefClkOdiv2 : sl;      -- Refclk ODIV2
   signal pgpUserRefClk      : sl;      -- ODIV2+BUFG_GT - Used to clock TX
   signal pgpUserRefRst      : sl;
   signal fcRxClk            : sl;      -- Recovered RX clock for local use
   signal fcRxRst            : sl;

   -- PGP IO
   signal pgpRxIn  : Pgp2fcRxInType  := PGP2FC_RX_IN_INIT_C;
   signal pgpRxOut : Pgp2fcRxOutType := PGP2FC_RX_OUT_INIT_C;
   signal pgpTxIn  : Pgp2fcTxInType  := PGP2FC_TX_IN_INIT_C;
   signal pgpTxOut : Pgp2fcTxOutType := PGP2FC_TX_OUT_INIT_C;

   -- Rx FC Word
   signal fcRxValid : sl;
   signal fcRxWord  : slv(FC_LEN_C-1 downto 0);


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
         mAxiWriteMasters    => locAxilWriteMasters,
         mAxiWriteSlaves     => locAxilWriteSlaves,
         mAxiReadMasters     => locAxilReadMasters,
         mAxiReadSlaves      => locAxilReadSlaves);


   -------------------------------------------------------------------------------------------------
   -- Clock Input and Output Buffers
   -------------------------------------------------------------------------------------------------
   U_mgtRefClk : IBUFDS_GTE4
      generic map (
         REFCLK_EN_TX_PATH  => '0',
         REFCLK_HROW_CK_SEL => "00",    -- 2'b00: ODIV2 = O
         REFCLK_ICNTL_RX    => "00")
      port map (
         I     => fcRefClk185P,
         IB    => fcRefClk185N,
         CEB   => '0',
         ODIV2 => pgpUserRefClkOdiv2,
         O     => pgpRefClk);

   U_mgtUserRefClk : BUFG_GT
      port map (
         I       => pgpUserRefClkOdiv2,
         CE      => '1',
         CEMASK  => '1',
         CLR     => '0',
         CLRMASK => '1',
         DIV     => "000",
         O       => pgpUserRefClk);

   -- Output recovered clock on gt clock pins
   -- Might need generic around this
   U_mgtRecClk : OBUFDS_GTE4
      generic map (
         REFCLK_EN_TX_PATH => '1',
         REFCLK_ICNTL_TX   => "00000")
      port map (
         O   => fcRecClkP,
         OB  => fcRecClkN,
         CEB => '0',
         I   => pgpRxRecClk);           -- using rxRecClk from Channel=0

   -------------------------------------------------------------------------------------------------
   -- Create a reset for pgpUserRefClk
   -------------------------------------------------------------------------------------------------
   RstSync_1 : entity surf.RstSync
      generic map (
         TPD_G           => TPD_G,
         IN_POLARITY_G   => '1',
         OUT_POLARITY_G  => '1',
         RELEASE_DELAY_G => 5)
      port map (
         clk      => pgpUserRefClk,
         asyncRst => '0',
         syncRst  => pgpUserRefRst);


   -------------------------------------------------------------------------------------------------
   -- LDMX FC PGP LANE
   -------------------------------------------------------------------------------------------------
   U_LdmxPgpFcLane_1 : entity ldmx.LdmxPgpFcLane
      generic map (
         TPD_G            => TPD_G,
         SIM_SPEEDUP_G    => SIM_SPEEDUP_G,
         AXIL_CLK_FREQ_G  => AXIL_CLK_FREQ_G,
         AXIL_BASE_ADDR_G => AXIL_XBAR_CFG_C(PGP_FC_LANE_AXIL_C).baseAddr,
         TX_ENABLE_G      => true,
         RX_ENABLE_G      => true,
         NUM_VC_EN_G      => 0,
         RX_CLK_MMCM_G    => false)
      port map (
         pgpTxP          => fcTxP,                                    -- [out]
         pgpTxN          => fcTxN,                                    -- [out]
         pgpRxP          => fcRxP,                                    -- [in]
         pgpRxN          => fcRxN,                                    -- [in]
         pgpRefClk       => pgpRefClk,                                -- [in]
         pgpUserRefClk   => pgpUserRefClk,                            -- [in]
         pgpRxRecClk     => open,                                     -- [out]
         pgpRxRstOut     => fcRxRst185,                               -- [out]
         pgpRxOutClk     => fcRxClk185,                               -- [out]
         pgpRxIn         => pgpRxIn,                                  -- [in]
         pgpRxOut        => pgpRxOut,                                 -- [out]
         pgpRxMasters    => open,                                     -- [out]
         pgpRxCtrl       => (others => AXI_STREAM_CTRL_UNUSED_C),     -- [in]
         pgpTxRst        => fcRst185,                                 -- [in]
         pgpTxOutClk     => open,                                     -- [out]
         pgpTxUsrClk     => fcClk185,                                 -- [in]
         pgpTxIn         => pgpTxIn,                                  -- [in]
         pgpTxOut        => pgpTxOut,                                 -- [out]
         pgpTxMasters    => (others => AXI_STREAM_MASTER_INIT_C),     -- [in]
         pgpTxSlaves     => open,                                     -- [out]
         axilClk         => axilClk,                                  -- [in]
         axilRst         => axilRst,                                  -- [in]
         axilReadMaster  => locAxilReadMasters(PGP_FC_LANE_AXIL_C),   -- [in]
         axilReadSlave   => locAxilReadSlaves(PGP_FC_LANE_AXIL_C),    -- [out]
         axilWriteMaster => locAxilWriteMasters(PGP_FC_LANE_AXIL_C),  -- [in]
         axilWriteSlave  => locAxilWriteSlaves(PGP_FC_LANE_AXIL_C));  -- [out]


   -------------------------------------------------------------------------------------------------
   -- Timing and Fast Control Receiver Logic
   -- Decode Fast Control words and track run state
   -------------------------------------------------------------------------------------------------
   fcRxValid <= pgpRxOut.fcValid;
   fcRxWord  <= pgpRxOut.fcWord(FC_LEN_C-1 downto 0);
   -- Decode Busy and resync


   -- Glue fcMsg to pgpTxIn
   pgpTxIn.fcValid                     <= fcMsg.valid;
   pgpTxIn.fcWord(FC_LEN_C-1 downto 0) <= fcMsg.message;


end architecture rtl;

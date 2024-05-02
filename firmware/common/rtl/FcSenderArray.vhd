-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- Author     : Benjamin Reese  <bareese@slac.stanford.edu>
-------------------------------------------------------------------------------
-- Description: 
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

entity FcSenderArray is

   generic (
      TPD_G             : time                 := 1 ns;
      SIM_SPEEDUP_G     : boolean              := false;
      REFCLKS_G         : integer range 1 to 4 := 2;
      QUADS_G           : integer range 1 to 4 := 4;
      QUAD_REFCLK_MAP_G : IntegerArray         := (0      => 0, 1 => 0, 2 => 1, 3 => 1);  -- Map a refclk for each quad
      AXIL_CLK_FREQ_G   : real                 := 125.0e6;
      AXIL_BASE_ADDR_G  : slv(31 downto 0)     := (others => '0'));
   port (
      -- Reference clock
      fcHubRefClkP    : in  slv(REFCLKS_G-1 downto 0);
      fcHubRefClkN    : in  slv(REFCLKS_G-1 downto 0);
      -- PGP FC serial IO
      fcHubTxP        : out slv(QUADS_G*4-1 downto 0);
      fcHubTxN        : out slv(QUADS_G*4-1 downto 0);
      fcHubRxP        : in  slv(QUADS_G*4-1 downto 0);
      fcHubRxN        : in  slv(QUADS_G*4-1 downto 0);
      -- Interface to Global Trigger and LCLS Timing
      lclsTimingClk   : in  sl;
      lclsTimingRst   : in  sl;
      fcTxMsg         : in  FcMessageType;
      -- Axil inteface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType);

end entity FcSenderArray;

architecture rtl of FcSenderArray is
   -- AXI Lite
   constant NUM_AXIL_MASTERS_C : natural := QUADS_G*4;

   -- 20 Bits for each FC Sender
   constant AXIL_XBAR_CFG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXIL_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXIL_MASTERS_C, AXIL_BASE_ADDR_G, 24, 20);

   signal locAxilWriteMasters : AxiLiteWriteMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal locAxilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0) := (others => AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);
   signal locAxilReadMasters  : AxiLiteReadMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal locAxilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0)  := (others => AXI_LITE_READ_SLAVE_EMPTY_DECERR_C);

--   signal lclsTimingRecClkOdiv2 :    slv(REFCLKS_G-1 downto 0);
   signal fcHubRefClk : slv(REFCLKS_G-1 downto 0);
--   signal lclsTimingRecUserClk  : in slv(REFCLKS_G-1 downto 0);

begin

   -------------------------------------------------------------------------------------------------
   -- Clock Input buffers for each refclk
   -------------------------------------------------------------------------------------------------
   REFCLK_BUFS : for i in REFCLKS_G-1 downto 0 generate
      U_mgtRefClk : IBUFDS_GTE4
         generic map (
            REFCLK_EN_TX_PATH  => '0',
            REFCLK_HROW_CK_SEL => "00",  -- 2'b00: ODIV2 = O
            REFCLK_ICNTL_RX    => "00")
         port map (
            I     => fcHubRefClkP(i),
            IB    => fcHubRefClkN(i),
            CEB   => '0',
            ODIV2 => open,
            O     => fcHubRefClk(i));
   end generate;

   -------------------------------------------------------------------------------------------------
   -- FC Senders
   -------------------------------------------------------------------------------------------------
   GEN_QUADS : for quad in QUADS_G-1 downto 0 generate
      GEN_CHANNELS : for ch in 3 downto 0 generate
         U_FcSender_1 : entity ldmx.FcSender
            generic map (
               TPD_G            => TPD_G,
               SIM_SPEEDUP_G    => SIM_SPEEDUP_G,
               AXIL_CLK_FREQ_G  => AXIL_CLK_FREQ_G,
               AXIL_BASE_ADDR_G => AXIL_XBAR_CFG_C(quad*4+ch).baseAddr)
            port map (
               fcHubRefClk       => fcHubRefClk(QUAD_REFCLK_MAP_G(quad)),  -- [in]
               fcHubTxP          => fcHubTxP(quad*4+ch),                   -- [out]
               fcHubTxN          => fcHubTxN(quad*4+ch),                   -- [out]
               fcHubRxP          => fcHubRxP(quad*4+ch),                   -- [in]
               fcHubRxN          => fcHubRxN(quad*4+ch),                   -- [in]
               lclsTimingUserClk => lclsTimingClk,                         -- [in]
               lclsTimingUserRst => lclsTimingRst,                         -- [in]
               fcTxMsg           => fcTxMsg,                               -- [in]
               axilClk           => axilClk,                               -- [in]
               axilRst           => axilRst,                               -- [in]
               axilReadMaster    => locAxilReadMasters(quad*4+ch),         -- [in]
               axilReadSlave     => locAxilReadSlaves(quad*4+ch),          -- [out]
               axilWriteMaster   => locAxilWriteMasters(quad*4+ch),        -- [in]
               axilWriteSlave    => locAxilWriteSlaves(quad*4+ch));        -- [out]
      end generate GEN_CHANNELS;
   end generate GEN_QUADS;

end architecture rtl;


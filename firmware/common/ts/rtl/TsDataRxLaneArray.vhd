-------------------------------------------------------------------------------
-- Title      : 
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

library UNISIM;
use UNISIM.VCOMPONENTS.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;

library ldmx_tdaq;
use ldmx_tdaq.FcPkg.all;

library ldmx_ts;
use ldmx_ts.TsPkg.all;

entity TsDataRxLaneArray is
   generic (
      TPD_G            : time                  := 1 ns;
      SIMULATION_G     : boolean               := false;
      TS_LANES_G       : integer range 1 to 24 := 2;
      TS_REFCLKS_G     : integer range 1 to 24 := 1;
      TS_REFCLK_MAP_G  : IntegerArray          := (0 => 0, 1 => 0);  -- Map a refclk index to each fiber
      AXIL_CLK_FREQ_G  : real                  := 125.0e6;
      AXIL_BASE_ADDR_G : slv(31 downto 0)      := X"00000000");
   port (
      -- TS RX
      tsRefClk250P : in slv(TS_REFCLKS_G-1 downto 0);
      tsRefClk250N : in slv(TS_REFCLKS_G-1 downto 0);
      tsDataRxP    : in slv(TS_LANES_G-1 downto 0);
      tsDataRxN    : in slv(TS_LANES_G-1 downto 0);

      -- Output
      tsRecClks : out slv(TS_LANES_G-1 downto 0);
      tsRecRsts : out slv(TS_LANES_G-1 downto 0);
      tsRxMsgs  : out TsData6ChMsgArray(TS_LANES_G-1 downto 0);

      -- Input
      tsTxClks : out slv(TS_LANES_G-1 downto 0);  -- TsRefClk250 BUFG
      tsTxRsts : out slv(TS_LANES_G-1 downto 0);
      tsTxMsgs : in  TsData6ChMsgArray(TS_LANES_G-1 downto 0) := (others => TS_DATA_6CH_MSG_INIT_C);

      -- AXI Lite interface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType);
end entity TsDataRxLaneArray;

architecture rtl of TsDataRxLaneArray is

   constant NUM_AXIL_MASTERS_C : natural := 2;

   constant AXIL_XBAR_CFG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXIL_MASTERS_C-1 downto 0) :=
      genAxiLiteConfig(NUM_AXIL_MASTERS_C, AXIL_BASE_ADDR_G, 20, 14);

   signal locAxilWriteMasters : AxiLiteWriteMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal locAxilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0) := (others => AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);
   signal locAxilReadMasters  : AxiLiteReadMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal locAxilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0)  := (others => AXI_LITE_READ_SLAVE_EMPTY_DECERR_C);

   signal tsRefClkOdiv2 : slv(TS_REFCLKS_G-1 downto 0);
   signal tsRefClk250   : slv(TS_REFCLKS_G-1 downto 0);
   signal tsUserClk250  : slv(TS_REFCLKS_G-1 downto 0);
   signal tsUserRst250  : slv(TS_REFCLKS_G-1 downto 0);

begin

   -------------------------------------------------------------------------------------------------
   -- AXIL Crossbar
   -------------------------------------------------------------------------------------------------
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
   -- REFCLK Buffers
   -------------------------------------------------------------------------------------------------
   REFCLK_BUFS : for i in TS_REFCLKS_G-1 downto 0 generate
      U_mgtRefClk : IBUFDS_GTE4
         generic map (
            REFCLK_EN_TX_PATH  => '0',
            REFCLK_HROW_CK_SEL => "00",  -- 2'b00: ODIV2 = O
            REFCLK_ICNTL_RX    => "00")
         port map (
            I     => tsRefClk250P(i),
            IB    => tsRefClk250N(i),
            CEB   => '0',
            ODIV2 => tsRefClkOdiv2(i),
            O     => tsRefClk250(i));

      U_mgtUserRefClk : BUFG_GT
         port map (
            I       => tsRefClkOdiv2(i),
            CE      => '1',
            CEMASK  => '1',
            CLR     => '0',
            CLRMASK => '1',
            DIV     => "000",
            O       => tsUserClk250(i));

      U_RstSync_1 : entity surf.RstSync
         generic map (
            TPD_G => TPD_G)
         port map (
            clk      => tsUserClk250(i),
            asyncRst => '0',
            syncRst  => tsUserRst250(i));

   end generate;

   -------------------------------------------------------------------------------------------------
   -- Generate Lanes
   -------------------------------------------------------------------------------------------------

   GEN_LANES : for i in TS_LANES_G-1 downto 0 generate
      tsTxClks(i) <= tsUserClk250(TS_REFCLK_MAP_G(i));
      tsTxRsts(i) <= tsUserRst250(TS_REFCLK_MAP_G(i));
      U_TsDataRxLane_1 : entity ldmx_ts.TsDataRxLane
         generic map (
            TPD_G            => TPD_G,
            SIMULATION_G     => SIMULATION_G,
            AXIL_CLK_FREQ_G  => AXIL_CLK_FREQ_G,
            AXIL_BASE_ADDR_G => AXIL_XBAR_CFG_C(i).baseAddr)
         port map (
            tsRefClk250     => tsRefClk250(TS_REFCLK_MAP_G(i)),   -- [in]
            tsUserClk250    => tsUserClk250(TS_REFCLK_MAP_G(i)),  -- [in]
            tsDataRxP       => tsDataRxP(i),                      -- [in]
            tsDataRxN       => tsDataRxN(i),                      -- [in]
            tsRecClk        => tsRecClks(i),                      -- [out]
            tsRecRst        => tsRecRsts(i),                      -- [out]
            tsRxMsg         => tsRxMsgs(i),                       -- [out]
            tsTxMsg         => tsTxMsgs(i),                       -- [in]
            axilClk         => axilClk,                           -- [in]
            axilRst         => axilRst,                           -- [in]
            axilReadMaster  => locAxilReadMasters(i),             -- [in]
            axilReadSlave   => locAxilReadSlaves(i),              -- [out]
            axilWriteMaster => locAxilWriteMasters(i),            -- [in]
            axilWriteSlave  => locAxilWriteSlaves(i));            -- [out]
   end generate GEN_LANES;

end rtl;

-------------------------------------------------------------------------------
-- File       : PgpLaneWrapper.vhd
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

library unisim;
use unisim.vcomponents.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;

library axi_pcie_core;
use axi_pcie_core.AxiPciePkg.all;

library ldmx;

entity PgpLaneWrapper is
   generic (
      TPD_G             : time             := 1 ns;
      REFCLK_WIDTH_G    : positive         := 2;
      DMA_AXIS_CONFIG_G : AxiStreamConfigType;
      AXI_BASE_ADDR_G   : slv(31 downto 0) := (others => '0'));
   port (
      -- QSFP[0] Ports
      qsfp0RefClkP    : in  slv(REFCLK_WIDTH_G-1 downto 0);
      qsfp0RefClkN    : in  slv(REFCLK_WIDTH_G-1 downto 0);
      qsfp0RxP        : in  slv(3 downto 0);
      qsfp0RxN        : in  slv(3 downto 0);
      qsfp0TxP        : out slv(3 downto 0);
      qsfp0TxN        : out slv(3 downto 0);
      -- QSFP[1] Ports
      qsfp1RefClkP    : in  slv(REFCLK_WIDTH_G-1 downto 0);
      qsfp1RefClkN    : in  slv(REFCLK_WIDTH_G-1 downto 0);
      qsfp1RxP        : in  slv(3 downto 0);
      qsfp1RxN        : in  slv(3 downto 0);
      qsfp1TxP        : out slv(3 downto 0);
      qsfp1TxN        : out slv(3 downto 0);
      -- DMA Interface (dmaClk domain)
      dmaClk          : in  sl;
      dmaRst          : in  sl;
      dmaBuffGrpPause : in  slv(7 downto 0);
      dmaObMasters    : in  AxiStreamMasterArray(7 downto 0);
      dmaObSlaves     : out AxiStreamSlaveArray(7 downto 0);
      dmaIbMasters    : out AxiStreamMasterArray(7 downto 0);
      dmaIbSlaves     : in  AxiStreamSlaveArray(7 downto 0);
      -- AXI-Lite Interface (axilClk domain)
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType);
end PgpLaneWrapper;

architecture mapping of PgpLaneWrapper is

   constant NUM_AXI_MASTERS_C : natural := 9;

   constant AXI_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXI_MASTERS_C, AXI_BASE_ADDR_G, 20, 16);

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);

   signal pgpRefClk : slv(7 downto 0);
   signal pgpRxP    : slv(7 downto 0);
   signal pgpRxN    : slv(7 downto 0);
   signal pgpTxP    : slv(7 downto 0);
   signal pgpTxN    : slv(7 downto 0);

   signal refClk      : slv((2*REFCLK_WIDTH_G)-1 downto 0);
   signal userRefClk  : slv((2*REFCLK_WIDTH_G)-1 downto 0);
   signal userRefClkG : slv((2*REFCLK_WIDTH_G)-1 downto 0);

begin

   ------------------------
   -- Common PGP Clocking
   ------------------------
   GEN_REFCLK :
   for i in REFCLK_WIDTH_G-1 downto 0 generate

      U_QsfpRef0 : IBUFDS_GTE4
         generic map (
            REFCLK_EN_TX_PATH  => '0',
            REFCLK_HROW_CK_SEL => "00",  -- 2'b00: ODIV2 = O
            REFCLK_ICNTL_RX    => "00")
         port map (
            I     => qsfp0RefClkP(i),
            IB    => qsfp0RefClkN(i),
            CEB   => '0',
            ODIV2 => userRefClk(2*i),
            O     => refClk((2*i)));

      U_QsfpRef1 : IBUFDS_GTE4
         generic map (
            REFCLK_EN_TX_PATH  => '0',
            REFCLK_HROW_CK_SEL => "00",  -- 2'b00: ODIV2 = O
            REFCLK_ICNTL_RX    => "00")
         port map (
            I     => qsfp1RefClkP(i),
            IB    => qsfp1RefClkN(i),
            CEB   => '0',
            ODIV2 => userRefClk((2*i)+1),
            O     => refClk((2*i)+1));
   end generate GEN_REFCLK;

   GEN_USER_REF_BUFG_GT : for i in 3 downto 0 generate
      U_BUFG : BUFG_GT
         port map (
            I       => userRefClk(i),
            CE      => '1',
            CEMASK  => '1',
            CLR     => '0',
            CLRMASK => '1',
            DIV     => "000",           -- Divide-by-1
            O       => userRefClkG(i));

   end generate;


   --------------------------------
   -- Mapping QSFP[1:0] to PGP[7:0]
   -- qsfp*RefClkP(1) is reprogrammable via Si570
   -- Use that one
   --------------------------------
   MAP_QSFP : for i in 3 downto 0 generate
      -- QSFP[0] to PGP[3:0]
      pgpRefClk(i+0) <= refClk(2);
      pgpRxP(i+0)    <= qsfp0RxP(i);
      pgpRxN(i+0)    <= qsfp0RxN(i);
      qsfp0TxP(i)    <= pgpTxP(i+0);
      qsfp0TxN(i)    <= pgpTxN(i+0);
      -- QSFP[1] to PGP[7:4]
      pgpRefClk(i+4) <= refClk(3);
      pgpRxP(i+4)    <= qsfp1RxP(i);
      pgpRxN(i+4)    <= qsfp1RxN(i);
      qsfp1TxP(i)    <= pgpTxP(i+4);
      qsfp1TxN(i)    <= pgpTxN(i+4);
   end generate MAP_QSFP;

   ---------------------
   -- AXI-Lite Crossbar
   ---------------------
   U_XBAR : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => NUM_AXI_MASTERS_C,
         MASTERS_CONFIG_G   => AXI_CONFIG_C)
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

   U_RefclkMon_1 : entity ldmx.RefclkMon
      generic map (
         TPD_G           => TPD_G,
         AXIL_CLK_FREQ_G => 125.0e6)
      port map (
         axilClk         => axilClk,              -- [in]
         axilRst         => axilRst,              -- [in]
         axilReadMaster  => axilReadMasters(8),   -- [in]
         axilReadSlave   => axilReadSlaves(8),    -- [out]
         axilWriteMaster => axilWriteMasters(8),  -- [in]
         axilWriteSlave  => axilWriteSlaves(8),   -- [out]
         qsfpRefClk      => userRefClkG);         -- [in]

   ------------
   -- PGP Lanes
   ------------
   GEN_LANE : for i in 7 downto 0 generate

      U_Lane : entity ldmx.PgpLane
         generic map (
            TPD_G             => TPD_G,
            DMA_AXIS_CONFIG_G => DMA_AXIS_CONFIG_G,
            LANE_G            => i,
            AXI_BASE_ADDR_G   => AXI_CONFIG_C(i).baseAddr)
         port map (
            -- PGP Serial Ports
            pgpRxP          => pgpRxP(i),
            pgpRxN          => pgpRxN(i),
            pgpTxP          => pgpTxP(i),
            pgpTxN          => pgpTxN(i),
            pgpRefClk       => pgpRefClk(i),
            -- DMA Interface (dmaClk domain)
            dmaClk          => dmaClk,
            dmaRst          => dmaRst,
            dmaBuffGrpPause => dmaBuffGrpPause,
            dmaObMaster     => dmaObMasters(i),
            dmaObSlave      => dmaObSlaves(i),
            dmaIbMaster     => dmaIbMasters(i),
            dmaIbSlave      => dmaIbSlaves(i),
            -- AXI-Lite Interface (axilClk domain)
            axilClk         => axilClk,
            axilRst         => axilRst,
            axilReadMaster  => axilReadMasters(i),
            axilReadSlave   => axilReadSlaves(i),
            axilWriteMaster => axilWriteMasters(i),
            axilWriteSlave  => axilWriteSlaves(i));

   end generate GEN_LANE;

end mapping;

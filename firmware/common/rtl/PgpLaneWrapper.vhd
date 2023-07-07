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

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;

library ldmx;

library axi_pcie_core;
use axi_pcie_core.AxiPciePkg.all;

library unisim;
use unisim.vcomponents.all;

entity PgpLaneWrapper is
   generic (
      TPD_G             : time             := 1 ns;
      SIM_SPEEDUP_G     : boolean          := false;
      DMA_AXIS_CONFIG_G : AxiStreamConfigType;
      PGP_QUADS_G       : integer          := 8;
      AXI_CLK_FREQ_G    : real             := 125.0e6;
      AXI_BASE_ADDR_G   : slv(31 downto 0) := (others => '0'));
   port (
      -- QSFP-DD Ports
      qsfpRefClkP     : in  slv(PGP_QUADS_G-1 downto 0);
      qsfpRefClkN     : in  slv(PGP_QUADS_G-1 downto 0);
      qsfpRxP         : in  slv(PGP_QUADS_G*4-1 downto 0);
      qsfpRxN         : in  slv(PGP_QUADS_G*4-1 downto 0);
      qsfpTxP         : out slv(PGP_QUADS_G*4-1 downto 0);
      qsfpTxN         : out slv(PGP_QUADS_G*4-1 downto 0);
      -- DMA Interface (dmaClk domain)
      dmaClk          : in  sl;
      dmaRst          : in  sl;
      dmaBuffGrpPause : in  slv(7 downto 0);
      dmaObMasters    : in  AxiStreamMasterArray(PGP_QUADS_G-1 downto 0);
      dmaObSlaves     : out AxiStreamSlaveArray(PGP_QUADS_G-1 downto 0);
      dmaIbMasters    : out AxiStreamMasterArray(PGP_QUADS_G-1 downto 0);
      dmaIbSlaves     : in  AxiStreamSlaveArray(PGP_QUADS_G-1 downto 0);
      -- AXI-Lite Interface (axilClk domain)
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType);
end PgpLaneWrapper;

architecture mapping of PgpLaneWrapper is

   constant NUM_AXI_MASTERS_C : natural := PGP_QUADS_G*4;

   constant AXI_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXI_MASTERS_C, AXI_BASE_ADDR_G, 21, 16);

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);

   signal qsfpRefClk : slv(PGP_QUADS_G-1 downto 0);


   signal pgpObMasters : AxiStreamMasterArray(PGP_QUADS_G*4-1 downto 0);
   signal pgpObSlaves  : AxiStreamSlaveArray(PGP_QUADS_G*4-1 downto 0);
   signal pgpIbMasters : AxiStreamMasterArray(PGP_QUADS_G*4-1 downto 0);
   signal pgpIbSlaves  : AxiStreamSlaveArray(PGP_QUADS_G*4-1 downto 0);


begin

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

   ------------
   -- PGP Lanes
   ------------
   GEN_QUAD : for quad in PGP_QUADS_G-1 downto 0 generate

      U_QsfpRef : IBUFDS_GTE4
         generic map (
            REFCLK_EN_TX_PATH  => '0',
            REFCLK_HROW_CK_SEL => "00",  -- 2'b00: ODIV2 = O
            REFCLK_ICNTL_RX    => "00")
         port map (
            I     => qsfpRefClkP(quad),
            IB    => qsfpRefClkN(quad),
            CEB   => '0',
            ODIV2 => open,
            O     => qsfpRefClk(quad));


      GEN_LANE : for lane in 3 downto 0 generate
         U_Lane : entity ldmx.PgpLane
            generic map (
               TPD_G             => TPD_G,
               SIM_SPEEDUP_G     => SIM_SPEEDUP_G,
               DMA_AXIS_CONFIG_G => DMA_AXIS_CONFIG_G,
               LANE_G            => quad*4+lane,
               AXI_CLK_FREQ_G    => AXI_CLK_FREQ_G,
               AXI_BASE_ADDR_G   => AXI_CONFIG_C(quad*4+lane).baseAddr)
            port map (
               -- PGP Serial Ports
               pgpRxP          => qsfpRxP(quad*4+lane),
               pgpRxN          => qsfpRxN(quad*4+lane),
               pgpTxP          => qsfpTxP(quad*4+lane),
               pgpTxN          => qsfpTxN(quad*4+lane),
               pgpRefClk       => qsfpRefClk(quad),
               -- DMA Interface (dmaClk domain)
               dmaClk          => dmaClk,
               dmaRst          => dmaRst,
               dmaBuffGrpPause => dmaBuffGrpPause,
               dmaObMaster     => pgpObMasters(quad*4+lane),
               dmaObSlave      => pgpObSlaves(quad*4+lane),
               dmaIbMaster     => pgpIbMasters(quad*4+lane),
               dmaIbSlave      => pgpIbSlaves(quad*4+lane),
               -- AXI-Lite Interface (axilClk domain)
               axilClk         => axilClk,
               axilRst         => axilRst,
               axilReadMaster  => axilReadMasters(quad*4+lane),
               axilReadSlave   => axilReadSlaves(quad*4+lane),
               axilWriteMaster => axilWriteMasters(quad*4+lane),
               axilWriteSlave  => axilWriteSlaves(quad*4+lane));

      end generate GEN_LANE;

      ----------------------------------------------------------------------------------------------
      -- Mux each quad of lanes together
      -- This will make 1 DMA lane per QUAD
      -- All even quads share a TID for buffGrpPause
      -- Likewise for odd numbered quads
      ----------------------------------------------------------------------------------------------
      ----------------------------------------------------------------------------------------------
      -- Should be
      -- Place pgp lane streams into dma streams modulo 8
      ----------------------------------------------------------------------------------------------
      U_Mux : entity surf.AxiStreamMux
         generic map (
            TPD_G          => TPD_G,
            NUM_SLAVES_G   => 4,
            MODE_G         => "ROUTED",
            TDEST_ROUTES_G => (
               0           => "000000--",
               1           => "000100--",
               2           => "001000--",
               3           => "001100--"),
            TID_MODE_G     => "ROUTED",
            TID_ROUTES_G   => (
               0           => "000000--",
               1           => "000001--",
               2           => "000000--",
               3           => "000001--"),
            PIPE_STAGES_G  => 2)
         port map (
            -- Clock and reset
            axisClk      => dmaClk,
            axisRst      => dmaRst,
            -- Slaves
            sAxisMasters => pgpIbMasters(quad*4+3 downto quad*4),
            sAxisSlaves  => pgpIbSlaves(quad*4+3 downto quad*4),
            -- Master
            mAxisMaster  => dmaIbMasters(quad),
            mAxisSlave   => dmaIbSlaves(quad));

      U_AxiStreamDeMux_1 : entity surf.AxiStreamDeMux
         generic map (
            TPD_G          => TPD_G,
            NUM_MASTERS_G  => 4,
            MODE_G         => "ROUTED",
            TDEST_ROUTES_G => (
               0           => "000000--",
               1           => "000100--",
               2           => "001000--",
               3           => "001100--"),
            PIPE_STAGES_G  => 2)
         port map (
            axisClk      => dmaClk,                                -- [in]
            axisRst      => dmaRst,                                -- [in]
            sAxisMaster  => dmaObMasters(quad),                    -- [in]
            sAxisSlave   => dmaObSlaves(quad),                     -- [out]
            mAxisMasters => pgpObMasters(quad*4+3 downto quad*4),  -- [out]
            mAxisSlaves  => pgpObSlaves(quad*4+3 downto quad*4));  -- [in]

   end generate GEN_QUAD;

end mapping;

-------------------------------------------------------------------------------
-- File       : TrackerPgpFcArray.vhd
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description:
-- Creates an array of a generic number of TrackerPgpFcLanes
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

library ldmx_tdaq;
use ldmx_tdaq.FcPkg.all;

library ldmx_tracker;

library unisim;
use unisim.vcomponents.all;

entity TrackerPgpFcArray is
   generic (
      TPD_G             : time                 := 1 ns;
      SIM_SPEEDUP_G     : boolean              := false;
      DMA_AXIS_CONFIG_G : AxiStreamConfigType;
      PGP_QUADS_G       : integer range 1 to 4 := 2;
      AXIL_CLK_FREQ_G   : real                 := 125.0e6;
      AXIL_BASE_ADDR_G  : slv(31 downto 0)     := (others => '0');
      NUM_VC_EN_G       : integer range 0 to 4 := 4);
   port (
      -- QSFP-DD Ports
      pgpFcRefClkP    : in  slv(PGP_QUADS_G-1 downto 0);
      pgpFcRefClkN    : in  slv(PGP_QUADS_G-1 downto 0);
      pgpFcRxP        : in  slv(PGP_QUADS_G*4-1 downto 0);
      pgpFcRxN        : in  slv(PGP_QUADS_G*4-1 downto 0);
      pgpFcTxP        : out slv(PGP_QUADS_G*4-1 downto 0);
      pgpFcTxN        : out slv(PGP_QUADS_G*4-1 downto 0);
      -- Fast Control Interface
      fcClk185        : in  sl;         -- Drives TXUSRCLK
      fcRst185        : in  sl;
      fcBus           : in  FcBusType;
      -- Stable 78.125MHz Clock
      stableClk       : in  sl;
      stableRst       : in  sl;
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
end TrackerPgpFcArray;

architecture mapping of TrackerPgpFcArray is

   constant NUM_AXIL_MASTERS_C : natural := PGP_QUADS_G*4;

   constant AXIL_XBAR_CFG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXIL_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXIL_MASTERS_C, AXIL_BASE_ADDR_G, 20, 16);

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0);

   signal pgpFcRefClk         : slv(PGP_QUADS_G-1 downto 0);
   signal mgtRefClkOdiv2      : slv(PGP_QUADS_G-1 downto 0);
   signal pgpFcUserDiv2RefClk : slv(PGP_QUADS_G-1 downto 0);
   signal pgpFcUserRefClk     : slv(PGP_QUADS_G-1 downto 0);

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


   ------------
   -- PGP Lanes
   ------------
   GEN_QUAD : for quad in PGP_QUADS_G-1 downto 0 generate

      -- One RefClk per quad
      U_mgtRefClk : IBUFDS_GTE4
         generic map (
            REFCLK_EN_TX_PATH  => '0',
            REFCLK_HROW_CK_SEL => "00",  -- 2'b00: ODIV2 = O
            REFCLK_ICNTL_RX    => "00")
         port map (
            I     => pgpFcRefClkP(quad),
            IB    => pgpFcRefClkN(quad),
            CEB   => '0',
            ODIV2 => mgtRefClkOdiv2(quad),
            O     => pgpFcRefClk(quad));

      U_mgtUserRefClk : BUFG_GT
         port map (
            I       => mgtRefClkOdiv2(quad),
            CE      => '1',
            CEMASK  => '1',
            CLR     => '0',
            CLRMASK => '1',
            DIV     => "000",
            O       => pgpFcUserRefClk(quad));

      U_mgtUserDiv2RefClk : BUFG_GT
         port map (
            I       => mgtRefClkOdiv2(quad),
            CE      => '1',
            CEMASK  => '1',
            CLR     => '0',
            CLRMASK => '1',
            DIV     => "001",
            O       => pgpFcUserDiv2RefClk(quad));

      -- 4 Lanes per quad
      GEN_LANE : for lane in 3 downto 0 generate
         U_Lane : entity ldmx_tracker.TrackerPgpFcLane
            generic map (
               TPD_G             => TPD_G,
               SIM_SPEEDUP_G     => SIM_SPEEDUP_G,
               DMA_AXIS_CONFIG_G => DMA_AXIS_CONFIG_G,
               LANE_G            => quad*4+lane,
               AXIL_CLK_FREQ_G   => AXIL_CLK_FREQ_G,
               AXIL_BASE_ADDR_G  => AXIL_XBAR_CFG_C(quad*4+lane).baseAddr,
               NUM_VC_EN_G       => NUM_VC_EN_G)
            port map (
               -- PGP Serial Ports
               pgpRxP            => pgpFcRxP(quad*4+lane),
               pgpRxN            => pgpFcRxN(quad*4+lane),
               pgpTxP            => pgpFcTxP(quad*4+lane),
               pgpTxN            => pgpFcTxN(quad*4+lane),
               pgpRefClk         => pgpFcRefClk(quad),
               pgpUserRefClk     => pgpFcUserRefClk(quad),
               pgpUserDiv2RefClk => pgpFcUserDiv2RefClk(quad),
               pgpUserStableClk  => stableClk,
               pgpUserStableRst  => stableRst,
               -- Fast Control Interface
               fcClk185          => fcClk185,
               fcRst185          => fcRst185,
               fcBus             => fcBus,
               -- DMA Interface (dmaClk domain)
               dmaClk            => dmaClk,
               dmaRst            => dmaRst,
               dmaBuffGrpPause   => dmaBuffGrpPause,
               dmaObMaster       => pgpObMasters(quad*4+lane),
               dmaObSlave        => pgpObSlaves(quad*4+lane),
               dmaIbMaster       => pgpIbMasters(quad*4+lane),
               dmaIbSlave        => pgpIbSlaves(quad*4+lane),
               -- AXI-Lite Interface (axilClk domain)
               axilClk           => axilClk,
               axilRst           => axilRst,
               axilReadMaster    => axilReadMasters(quad*4+lane),
               axilReadSlave     => axilReadSlaves(quad*4+lane),
               axilWriteMaster   => axilWriteMasters(quad*4+lane),
               axilWriteSlave    => axilWriteSlaves(quad*4+lane));

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
            sAxisMasters => pgpIbMasters(quad*4+4-1 downto quad*4),
            sAxisSlaves  => pgpIbSlaves(quad*4+4-1 downto quad*4),
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
            axisClk      => dmaClk,                                  -- [in]
            axisRst      => dmaRst,                                  -- [in]
            sAxisMaster  => dmaObMasters(quad),                      -- [in]
            sAxisSlave   => dmaObSlaves(quad),                       -- [out]
            mAxisMasters => pgpObMasters(quad*4+4-1 downto quad*4),  -- [out]
            mAxisSlaves  => pgpObSlaves(quad*4+4-1 downto quad*4));  -- [in]

   end generate GEN_QUAD;

end mapping;

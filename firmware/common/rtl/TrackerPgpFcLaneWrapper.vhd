-------------------------------------------------------------------------------
-- File       : TrackerPgpFcLaneWrapper.vhd
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
use ldmx.FcPkg.all;

library axi_pcie_core;
use axi_pcie_core.AxiPciePkg.all;

library unisim;
use unisim.vcomponents.all;

entity TrackerPgpFcLaneWrapper is
   generic (
      TPD_G             : time                 := 1 ns;
      SIM_SPEEDUP_G     : boolean              := false;
      DMA_AXIS_CONFIG_G : AxiStreamConfigType;
      PGP_LANES_G       : integer              := 4;
      PGP_QUADS_G       : integer              := 8;
      FC_EMU_QUAD_G     : integer              := 4;
      FC_EMU_LANE_G     : integer              := 0;
      AXI_CLK_FREQ_G    : real                 := 125.0e6;
      AXI_BASE_ADDR_G   : slv(31 downto 0)     := (others => '0');
      TX_ENABLE_G       : boolean              := true;
      RX_ENABLE_G       : boolean              := true;
      DBG_RX_G          : boolean              := true;
      NUM_VC_EN_G       : integer range 0 to 4 := 4);
   port (
      -- QSFP-DD Ports
      qsfpRefClkP     : in  slv(PGP_QUADS_G-1 downto 0);
      qsfpRefClkN     : in  slv(PGP_QUADS_G-1 downto 0);
      qsfpRecClkP     : out slv(PGP_QUADS_G-1 downto 0);
      qsfpRecClkN     : out slv(PGP_QUADS_G-1 downto 0);
      qsfpRxP         : in  slv(PGP_QUADS_G*PGP_LANES_G-1 downto 0);
      qsfpRxN         : in  slv(PGP_QUADS_G*PGP_LANES_G-1 downto 0);
      qsfpTxP         : out slv(PGP_QUADS_G*PGP_LANES_G-1 downto 0);
      qsfpTxN         : out slv(PGP_QUADS_G*PGP_LANES_G-1 downto 0);
      -- DMA Interface (dmaClk domain)
      dmaClk          : in  sl;
      dmaRst          : in  sl;
      dmaBuffGrpPause : in  slv(7 downto 0);
      dmaObMasters    : in  AxiStreamMasterArray(PGP_QUADS_G-1 downto 0);
      dmaObSlaves     : out AxiStreamSlaveArray(PGP_QUADS_G-1 downto 0);
      dmaIbMasters    : out AxiStreamMasterArray(PGP_QUADS_G-1 downto 0);
      dmaIbSlaves     : in  AxiStreamSlaveArray(PGP_QUADS_G-1 downto 0);
      -- Misc
      dbgOut          : out sl;
      -- AXI-Lite Interface (axilClk domain)
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType);
end TrackerPgpFcLaneWrapper;

architecture mapping of TrackerPgpFcLaneWrapper is

   constant MAX_PHYS_LANE_AXI_INDEX_C : natural := (PGP_QUADS_G-1)*PGP_LANES_G + PGP_LANES_G;
   constant FC_EMU_AXI_INDEX_C        : natural := MAX_PHYS_LANE_AXI_INDEX_C + 1;
   constant NUM_AXI_MASTERS_C         : natural := MAX_PHYS_LANE_AXI_INDEX_C +
                                                   FC_EMU_AXI_INDEX_C;

   constant AXI_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXI_MASTERS_C, AXI_BASE_ADDR_G, 21, 16);

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);

   signal mgtRefClk        : slv(PGP_QUADS_G-1   downto 0);
   signal mgtUserRefClk    : slv(PGP_QUADS_G-1   downto 0);
   signal userRefClk       : slv(PGP_QUADS_G-1   downto 0);
   signal pgpRxRecClk      : slv(PGP_QUADS_G*PGP_LANES_G-1 downto 0);

   signal pgpTxOutClk      : slv(PGP_QUADS_G*PGP_LANES_G-1 downto 0);
   signal pgpRxOutClk      : slv(PGP_QUADS_G*PGP_LANES_G-1 downto 0);
   signal pgpTxUsrClk      : slv(PGP_QUADS_G*PGP_LANES_G-1 downto 0);
   signal pgpRxUsrClk      : slv(PGP_QUADS_G*PGP_LANES_G-1 downto 0);

   signal pgpTxRstOut      : slv(PGP_QUADS_G*PGP_LANES_G-1 downto 0);

   signal pgpObMasters     : AxiStreamMasterArray(PGP_QUADS_G*PGP_LANES_G-1 downto 0);
   signal pgpObSlaves      : AxiStreamSlaveArray(PGP_QUADS_G*PGP_LANES_G-1 downto 0);
   signal pgpIbMasters     : AxiStreamMasterArray(PGP_QUADS_G*PGP_LANES_G-1 downto 0);
   signal pgpIbSlaves      : AxiStreamSlaveArray(PGP_QUADS_G*PGP_LANES_G-1 downto 0);

   signal fcBusTx          : FastControlBusArray(PGP_QUADS_G*PGP_LANES_G-1 downto 0)
                           := (others => DEFAULT_FC_BUS_C);
   signal fcBusRx          : FastControlBusArray(PGP_QUADS_G*PGP_LANES_G-1 downto 0)
                           := (others => DEFAULT_FC_BUS_C);
   signal fcEmuMsg         : FastControlMessageType := DEFAULT_FC_MSG_C;
   signal bunchClk         : sl;
   signal bunchStrobe      : sl;

   signal validRx          : sl;
   signal validTx          : sl;

   -- can we use one clock for one emulator transmitting across all physical lanes?
   -- need to opt this. Currently using one quad/lane for the emulator's reference clock;
   constant FC_EMU_PHYSICAL_LANE_C : integer := FC_EMU_QUAD_G*FC_EMU_LANE_G;

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

   ------------------------
   -- MGT Clock Multiplexer
   ------------------------
   U_MgtRefClkMux : entity ldmx.MgtRefClkMux
      generic map (
         TPD_G              => TPD_G,
         PGP_QUADS_G        => PGP_QUADS_G,
         BITTWARE_XUPVV8_G  => true)
      port map (
         -- FPGA I/O
         qsfpRefClkP => qsfpRefClkP,
         qsfpRefClkN => qsfpRefClkN,
         qsfpRecClkP => qsfpRecClkP,
         qsfpRecClkN => qsfpRecClkN,
         -- MGT I/O
         rxRecClk    => pgpRxRecClk,
         mgtRefClk   => mgtRefClk,
         userRefClk  => userRefClk,
         -- RX/TXCLK
         txOutClk    => pgpTxOutClk,
         rxOutClk    => pgpRxOutClk,
         txUsrClk    => pgpTxUsrClk,
         rxUsrClk    => pgpRxUsrClk);

   ------------
   -- PGP Lanes
   ------------
   GEN_QUAD : for quad in PGP_QUADS_G-1 downto 0 generate

      GEN_LANE : for lane in PGP_LANES_G-1 downto 0 generate
         U_Lane : entity ldmx.TrackerPgpFcLane
            generic map (
               TPD_G             => TPD_G,
               SIM_SPEEDUP_G     => SIM_SPEEDUP_G,
               DMA_AXIS_CONFIG_G => DMA_AXIS_CONFIG_G,
               LANE_G            => quad*PGP_LANES_G+lane,
               AXI_CLK_FREQ_G    => AXI_CLK_FREQ_G,
               AXI_BASE_ADDR_G   => AXI_CONFIG_C(quad*PGP_LANES_G+lane).baseAddr,
               TX_ENABLE_G       => TX_ENABLE_G,
               RX_ENABLE_G       => RX_ENABLE_G,
               NUM_VC_EN_G       => NUM_VC_EN_G)
            port map (
               -- PGP Serial Ports
               pgpRxP          => qsfpRxP(quad*PGP_LANES_G+lane),
               pgpRxN          => qsfpRxN(quad*PGP_LANES_G+lane),
               pgpTxP          => qsfpTxP(quad*PGP_LANES_G+lane),
               pgpTxN          => qsfpTxN(quad*PGP_LANES_G+lane),
               -- Fast Control Interface
               fcBusTx         => fcBusTx(quad*PGP_LANES_G+lane),
               fcBusRx         => fcBusRx(quad*PGP_LANES_G+lane),
               -- GT Clocking and Resets
               pgpRefClk       => mgtRefClk(quad),
               pgpUserRefClk   => userRefClk(quad),
               pgpRxRecClk     => pgpRxRecClk(quad*PGP_LANES_G+lane),
               pgpTxOutClk     => pgpTxOutClk(quad*PGP_LANES_G+lane),
               pgpRxOutClk     => pgpRxOutClk(quad*PGP_LANES_G+lane),
               pgpTxUsrClk     => pgpTxUsrClk(quad*PGP_LANES_G+lane),
               pgpRxUsrClk     => pgpRxUsrClk(quad*PGP_LANES_G+lane),
               pgpTxRstOut     => pgpTxRstOut(quad*PGP_LANES_G+lane),
               -- DMA Interface (dmaClk domain)
               dmaClk          => dmaClk,
               dmaRst          => dmaRst,
               dmaBuffGrpPause => dmaBuffGrpPause,
               dmaObMaster     => pgpObMasters(quad*PGP_LANES_G+lane),
               dmaObSlave      => pgpObSlaves(quad*PGP_LANES_G+lane),
               dmaIbMaster     => pgpIbMasters(quad*PGP_LANES_G+lane),
               dmaIbSlave      => pgpIbSlaves(quad*PGP_LANES_G+lane),
               -- AXI-Lite Interface (axilClk domain)
               axilClk         => axilClk,
               axilRst         => axilRst,
               axilReadMaster  => axilReadMasters(quad*PGP_LANES_G+lane),
               axilReadSlave   => axilReadSlaves(quad*PGP_LANES_G+lane),
               axilWriteMaster => axilWriteMasters(quad*PGP_LANES_G+lane),
               axilWriteSlave  => axilWriteSlaves(quad*PGP_LANES_G+lane));

         fcBusTx(quad*PGP_LANES_G+lane).rxLinkStatus <=
         fcBusRx(quad*PGP_LANES_G+lane).rxLinkStatus;

      end generate GEN_LANE;

      ------------------------
      -- Fast-Control Emulator
      ------------------------
      U_Emu : entity ldmx.FcEmu
         port map(
            -- Clock and Reset
            fcClk           => pgpTxUsrClk(FC_EMU_PHYSICAL_LANE_C),
            fcRst           => pgpTxRstOut(FC_EMU_PHYSICAL_LANE_C),
            -- Fast-Control Message Interface
            --fcMsg           => fcBusTx(FC_EMU_PHYSICAL_LANE_C).fcMsg,
            fcMsg           => fcEmuMsg,
            -- Bunch Clock
            bunchClk        => bunchClk,
            bunchStrobe     => bunchStrobe,
            -- AXI-Lite Interface
            axilClk         => axilClk,
            axilRst         => axilRst,
            axilReadMaster  => axilReadMasters(FC_EMU_AXI_INDEX_C),
            axilReadSlave   => axilReadSlaves(FC_EMU_AXI_INDEX_C),
            axilWriteMaster => axilWriteMasters(FC_EMU_AXI_INDEX_C),
            axilWriteSlave  => axilWriteSlaves(FC_EMU_AXI_INDEX_C));

      fcBusTx(FC_EMU_PHYSICAL_LANE_C).fcMsg <= fcEmuMsg;

      dbgOut <= ite(DBG_RX_G,
                    fcBusRx(FC_EMU_PHYSICAL_LANE_C).fcMsg.valid,
                    fcEmuMsg.valid);

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
            NUM_SLAVES_G   => PGP_LANES_G,
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
            sAxisMasters => pgpIbMasters(quad*PGP_LANES_G+PGP_LANES_G-1 downto quad*PGP_LANES_G),
            sAxisSlaves  => pgpIbSlaves(quad*PGP_LANES_G+PGP_LANES_G-1 downto quad*PGP_LANES_G),
            -- Master
            mAxisMaster  => dmaIbMasters(quad),
            mAxisSlave   => dmaIbSlaves(quad));

      U_AxiStreamDeMux_1 : entity surf.AxiStreamDeMux
         generic map (
            TPD_G          => TPD_G,
            NUM_MASTERS_G  => PGP_LANES_G,
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
            mAxisMasters => pgpObMasters(quad*PGP_LANES_G+PGP_LANES_G-1 downto quad*PGP_LANES_G),  -- [out]
            mAxisSlaves  => pgpObSlaves(quad*PGP_LANES_G+PGP_LANES_G-1 downto quad*PGP_LANES_G));  -- [in]

   end generate GEN_QUAD;

end mapping;

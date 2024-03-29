-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: XVC Wrapper
-------------------------------------------------------------------------------
-- This file is part of 'SLAC Firmware Standard Library'.
-- It is subject to the license terms in the LICENSE.txt file found in the
-- top-level directory of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of 'SLAC Firmware Standard Library', including this file,
-- may be copied, modified, propagated, or distributed except according to
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiStreamPkg.all;
use surf.EthMacPkg.all;

library unisim;
use unisim.vcomponents.all;

entity DmaXvcWrapper is
   generic (
      TPD_G          : time    := 1 ns;
      COMMON_CLOCK_G : boolean := false;
      AXIS_CONFIG_G  : AxiStreamConfigType);
   port (
      -- Clock and Reset (xvcClk domain)
      xvcClk       : in  sl;
      xvcRst       : in  sl;
      -- Clock and Reset (pgpClk domain)
      axisClk      : in  sl;
      axisRst      : in  sl;
      -- IB FIFO
      obFifoMaster : in  AxiStreamMasterType;
      obFifoSlave  : out AxiStreamSlaveType;
      -- OB FIFO
      ibFifoSlave  : in  AxiStreamSlaveType;
      ibFifoMaster : out AxiStreamMasterType);
end DmaXvcWrapper;

architecture rtl of DmaXvcWrapper is

   signal ibXvcMaster : AxiStreamMasterType := axiStreamMasterInit(EMAC_AXIS_CONFIG_C);
   signal ibXvcSlave  : AxiStreamSlaveType  := AXI_STREAM_SLAVE_FORCE_C;
   signal obXvcMaster : AxiStreamMasterType := axiStreamMasterInit(EMAC_AXIS_CONFIG_C);
   signal obXvcSlave  : AxiStreamSlaveType  := AXI_STREAM_SLAVE_FORCE_C;

begin

   -----------------------------------------------------------------
   -- Xilinx Virtual Cable (XVC)
   -- https://www.xilinx.com/products/intellectual-property/xvc.html
   -----------------------------------------------------------------
   U_XVC : entity surf.UdpDebugBridgeWrapper
      generic map (
         TPD_G => TPD_G)
      port map (
         -- Clock and Reset
         clk            => xvcClk,
         rst            => xvcRst,
         -- UDP XVC Interface
         obServerMaster => obXvcMaster,
         obServerSlave  => obXvcSlave,
         ibServerMaster => ibXvcMaster,
         ibServerSlave  => ibXvcSlave);

   U_IB_FIFO : entity surf.AxiStreamFifoV2
      generic map (
         -- General Configurations
         TPD_G               => TPD_G,
         -- FIFO configurations
         GEN_SYNC_FIFO_G     => COMMON_CLOCK_G,
         MEMORY_TYPE_G       => "distributed",
         FIFO_ADDR_WIDTH_G   => 5,
         -- AXI Stream Port Configurations
         SLAVE_AXI_CONFIG_G  => AXIS_CONFIG_G,
         MASTER_AXI_CONFIG_G => EMAC_AXIS_CONFIG_C)
      port map (
         -- Slave Port
         sAxisClk    => axisClk,
         sAxisRst    => axisRst,
         sAxisMaster => obFifoMaster,
         sAxisSlave  => obFifoSlave,
         -- Master Port
         mAxisClk    => xvcClk,
         mAxisRst    => xvcRst,
         mAxisMaster => obXvcMaster,
         mAxisSlave  => obXvcSlave);

   U_OB_FIFO : entity surf.AxiStreamFifoV2
      generic map (
         -- General Configurations
         TPD_G               => TPD_G,
         -- FIFO configurations
         GEN_SYNC_FIFO_G     => COMMON_CLOCK_G,
         MEMORY_TYPE_G       => "distributed",
         FIFO_ADDR_WIDTH_G   => 5,
         -- AXI Stream Port Configurations
         SLAVE_AXI_CONFIG_G  => EMAC_AXIS_CONFIG_C,
         MASTER_AXI_CONFIG_G => AXIS_CONFIG_G)
      port map (
         -- Slave Port
         sAxisClk    => xvcClk,
         sAxisRst    => xvcRst,
         sAxisMaster => ibXvcMaster,
         sAxisSlave  => ibXvcSlave,
         -- Master Port
         mAxisClk    => axisClk,
         mAxisRst    => axisRst,
         mAxisMaster => ibFifoMaster,
         mAxisSlave  => ibFifoSlave);


end rtl;

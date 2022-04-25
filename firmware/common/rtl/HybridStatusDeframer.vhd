-------------------------------------------------------------------------------
-- Title      : Hybrid Status Deframer
-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Unpacks a Hybrid Status AXI-Stream Frame to extract data.
-------------------------------------------------------------------------------
-- This file is part of HPS. It is subject to
-- the license terms in the LICENSE.txt file found in the top-level directory
-- of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of HPS, including this file, may be
-- copied, modified, propagated, or distributed except according to the terms
-- contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
use surf.SsiPkg.all;


library hps_daq;
use hps_daq.HpsPkg.all;
use hps_daq.RceConfigPkg.all;

entity HybridStatusDeframer is
   generic (
      TPD_G : time := 1 ns;
      APVS_PER_HYBRID_G : integer := 5);
   port (
      -- Axi-Stream (SSI) extracted frames
      axisClk                    : in  sl;
      axisRst                    : in  sl;
      syncStatus                 : in  slv(APVS_PER_HYBRID_G-1 downto 0);
      hybridStatusDataAxisMaster : in  AxiStreamMasterType;
      hybridStatusDataAxisSlave  : out AxiStreamSlaveType;

      -- Master system clock, 125Mhz
      sysClk     : in  sl;
      sysRst     : in  sl;
      hybridInfo : out HybridInfoType);
end HybridStatusDeframer;

architecture rtl of HybridStatusDeframer is

   type RegType is record
      hybridInfo : HybridInfoType;
   end record RegType;

   constant REG_INIT_C : RegType := (
      hybridInfo => HYBRID_INFO_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal syncStatusSys : slv(APVS_PER_HYBRID_G-1 downto 0);

   signal axisMaster : AxiStreamMasterType;
   signal axisSlave  : AxiStreamSlaveType := AXI_STREAM_SLAVE_FORCE_C;
   signal ssiMaster  : SsiMasterType;

begin

   -------------------------------------------------------------------------------------------------
   -- First move the whole stream to the system clock domain 
   -------------------------------------------------------------------------------------------------
   AxiStreamFifo_1 : entity surf.AxiStreamFifoV2
      generic map (
         TPD_G               => TPD_G,
         SYNTH_MODE_G        => "xpm",
         MEMORY_TYPE_G       => "distributed",
         GEN_SYNC_FIFO_G     => false,
         SLAVE_READY_EN_G    => true,
         FIFO_ADDR_WIDTH_G   => 4,
         SLAVE_AXI_CONFIG_G  => HYBRID_STATUS_SSI_CONFIG_C,
         MASTER_AXI_CONFIG_G => HYBRID_STATUS_SSI_CONFIG_C)
      port map (
         sAxisClk    => axisClk,
         sAxisRst    => axisRst,
         sAxisMaster => hybridStatusDataAxisMaster,
         sAxisSlave  => hybridStatusDataAxisSlave,
         mAxisClk    => sysClk,
         mAxisRst    => sysRst,
         mAxisMaster => axisMaster,
         mAxisSlave  => axisSlave);

   SynchronizerVector_1 : entity surf.SynchronizerVector
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => APVS_PER_HYBRID_G)
      port map (
         clk     => sysClk,
         rst     => sysRst,
         dataIn  => syncStatus,
         dataOut => syncStatusSys);

   ssiMaster <= axis2SsiMaster(HYBRID_STATUS_SSI_CONFIG_C, axisMaster);

   comb : process (r, ssiMaster, syncStatusSys, sysRst) is
      variable v         : RegType;
      variable axiStatus : AxiLiteStatusType;
   begin
      v := r;

      if (ssiMaster.valid = '1' and ssiMaster.sof = '1') then
         v.hybridInfo := toHybridInfo(ssiMaster.data(15 downto 0));
      end if;
      -- Use sync status from pgp status vector instead of from status frame
--      v.hybridInfo.syncStatus := syncStatusSys;  --ssiMaster.data(4 downto 0);

      ----------------------------------------------------------------------------------------------
      -- Resets and outputs
      ----------------------------------------------------------------------------------------------
      if (sysRst = '1') then
         v                       := REG_INIT_C;
         v.hybridInfo            := r.hybridInfo;
         v.hybridInfo.syncStatus := (others => '0');
      end if;

      rin <= v;

      hybridInfo <= r.hybridInfo;

   end process comb;

   seq : process (sysClk) is
   begin
      if (rising_edge(sysClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end rtl;


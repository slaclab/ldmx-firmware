-------------------------------------------------------------------------------
-- Title      : ApvFrameDemux
-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: Demultiplex a stream of APV frames using APV number found
-- in stream header.
-------------------------------------------------------------------------------
-- Copyright (c) 2013 SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


library surf;
use surf.StdRtlPkg.all;
use surf.AxiStreamPkg.all;
use surf.SsiPkg.all;


library ldmx;
use ldmx.HpsPkg.all;

entity ApvFrameDemux is

   generic (
      TPD_G : time := 1 ns;
      NUM_APVS_G : integer range 4 to 6 := 5);
   port (
      axisClk : in sl;
      axisRst : in sl;

      hybridDataAxisMaster : in  AxiStreamMasterType;
      hybridDataAxisSlave  : out AxiStreamSlaveType;

      apvFrameAxisMasters : out AxiStreamMasterArray(NUM_APVS_G-1 downto 0);
      apvFrameAxisSlaves  : in  AxiStreamSlaveArray(NUM_APVS_G-1 downto 0));

end entity ApvFrameDemux;

architecture rtl of ApvFrameDemux is

   signal taggedHybridDataAxisSlave : AxiStreamSlaveType;

   type RegType is record
      taggedHybridDataAxisMaster : AxiStreamMasterType;
      hybridDataAxisSlave        : AxiStreamSlaveType;
   end record RegType;

   constant REG_INIT_C : RegType := (
      taggedHybridDataAxisMaster => AXI_STREAM_MASTER_INIT_C,
      hybridDataAxisSlave        => AXI_STREAM_SLAVE_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

begin

   comb : process (axisRst, hybridDataAxisMaster, r, taggedHybridDataAxisSlave) is
      variable v : RegType;
   begin
      v := r;

      v.hybridDataAxisSlave.tready := '0';

      if (taggedHybridDataAxisSlave.tready = '1') then
         v.taggedHybridDataAxisMaster.tvalid := '0';
      end if;

      if (v.taggedHybridDataAxisMaster.tvalid = '0' and hybridDataAxisMaster.tvalid = '1') then

         -- Pipe the stream through but latch a new tDest on each SOF
         -- tDest taken from bits 15:13 of SOF data
         v.hybridDataAxisSlave.tready       := '1';
         v.taggedHybridDataAxisMaster       := hybridDataAxisMaster;
         v.taggedHybridDataAxisMaster.tDest := r.taggedHybridDataAxisMaster.tDest;

         if (ssiGetUserSof(APV_DATA_SSI_CONFIG_C, hybridDataAxisMaster) = '1') then
            v.taggedHybridDataAxisMaster.tDest(2 downto 0) := hybridDataAxisMaster.tData(15 downto 13);
         end if;

      end if;

      ----------------------------------------------------------------------------------------------
      -- Reset
      ----------------------------------------------------------------------------------------------
      hybridDataAxisSlave <= v.hybridDataAxisSlave;

      if (axisRst = '1') then
         v := REG_INIT_C;
      end if;

      rin <= v;

   end process comb;

   seq : process (axisClk) is
   begin
      if (rising_edge(axisClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

   -- Send tagged data stream into a normal AxiStreamDemux
   AxiStreamDeMux_1 : entity surf.AxiStreamDeMux
      generic map (
         TPD_G         => TPD_G,
         NUM_MASTERS_G => NUM_APVS_G)
      port map (
         axisClk      => axisClk,
         axisRst      => axisRst,
         sAxisMaster  => r.taggedHybridDataAxisMaster,
         sAxisSlave   => taggedHybridDataAxisSlave,
         mAxisMasters => apvFrameAxisMasters,
         mAxisSlaves  => apvFrameAxisSlaves);

end architecture rtl;

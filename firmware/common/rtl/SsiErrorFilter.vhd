-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : SsiErrorFilter.vhd
-- Author     : Ben Reese
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2014-05-02
-- Last update: 2019-11-20
-- Platform   :
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description:   This module is used to filter out SSI frames that end in EOFE
--                Such frames dissapear entirely from the stream.
-- Note: If EN_FRAME_FILTER_G = true, then this module DOES NOT support 
--       interleaving of channels during the middle of a frame transfer.
-------------------------------------------------------------------------------
-- Copyright (c) 2015 SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


library surf;
use surf.StdRtlPkg.all;
use surf.AxiStreamPkg.all;
use surf.SsiPkg.all;

entity SsiErrorFilter is
   generic (
      TPD_G         : time    := 1 ns;
      FRAME_SIZE_G  : integer := 128;
      AXIS_CONFIG_G : AxiStreamConfigType);
   port (
      -- Clock and Reset
      axisClk     : in  sl;
      axisRst     : in  sl;
      -- Slave Port
      sAxisMaster : in  AxiStreamMasterType;
      sAxisSlave  : out AxiStreamSlaveType;
      sAxisCtrl   : out AxiStreamCtrlType;
      -- Master Port
      mAxisMaster : out AxiStreamMasterType;
      mAxisSlave  : in  AxiStreamSlaveType);
end SsiErrorFilter;

architecture rtl of SsiErrorFilter is

   constant FIFO_ADDR_WIDTH_C : integer := log2(FRAME_SIZE_G)*4;

--   type StateType is (
--      IDLE_S,
--      MOVE_S);        

--   type RegType is record
--      mFifoAxisSlave : AxiStreamSlaveType;
--      mAxisMaster    : AxiStreamMasterType;
--      state          : StateType;
--   end record RegType;

--   constant REG_INIT_C : RegType := (
--      mFifoAxisSlave => AXI_STREAM_SLAVE_INIT_C,
--      state          => IDLE_S);

--   signal r   : RegType := REG_INIT_C;
--   signal rin : RegType;

   signal sAxisSlaveLoc   : AxiStreamSlaveType;
   signal mFifoAxisMaster : AxiStreamMasterType;
   signal mFifoAxisSlave  : AxiStreamSlaveType;
   signal eofeWrEn        : sl;
   signal eofeIn          : sl;
   signal eofeRdEn        : sl;
   signal eofeOut         : sl;
   signal eofeValid       : sl;

begin

   sAxisSlave <= sAxisSlaveLoc;

   AxiStreamFifo_1 : entity surf.AxiStreamFifoV2
      generic map (
         TPD_G               => TPD_G,
         SLAVE_READY_EN_G    => true,
         VALID_THOLD_G       => 0,
         MEMORY_TYPE_G       => "block",
         USE_BUILT_IN_G      => false,
         GEN_SYNC_FIFO_G     => true,
         FIFO_ADDR_WIDTH_G   => 9,
         FIFO_FIXED_THRESH_G => true,
         FIFO_PAUSE_THRESH_G => 2**9-128,
         SLAVE_AXI_CONFIG_G  => AXIS_CONFIG_G,
         MASTER_AXI_CONFIG_G => AXIS_CONFIG_G)
      port map (
         sAxisClk    => axisClk,
         sAxisRst    => axisRst,
         sAxisMaster => sAxisMaster,
         sAxisSlave  => sAxisSlaveLoc,
         sAxisCtrl   => sAxisCtrl,
         mAxisClk    => axisClk,
         mAxisRst    => axisRst,
         mAxisMaster => mFifoAxisMaster,
         mAxisSlave  => mFifoAxisSlave);

   Fifo_EOFE : entity surf.Fifo
      generic map (
         TPD_G           => TPD_G,
         GEN_SYNC_FIFO_G => true,
         MEMORY_TYPE_G   => "distributed",
         FWFT_EN_G       => true,
         DATA_WIDTH_G    => 1,
         ADDR_WIDTH_G    => 4)
      port map (
         rst     => axisRst,
         wr_clk  => axisClk,
         wr_en   => eofeWrEn,
         din(0)  => eofeIn,
         rd_clk  => axisClk,
         rd_en   => eofeRdEn,
         dout(0) => eofeOut,
         valid   => eofeValid);


   master : process (eofeOut, eofeValid, mAxisSlave, mFifoAxisMaster, mFifoAxisSlave, sAxisMaster,
                     sAxisSlaveLoc) is
   begin
      eofeWrEn <= sAxisMaster.tValid and sAxisMaster.tLast and sAxisSlaveLoc.tReady;
      eofeIn   <= ssiGetUserEofe(AXIS_CONFIG_G, sAxisMaster);

      mAxisMaster           <= mFifoAxisMaster;
      mAxisMaster.tValid    <= mFifoAxisMaster.tValid and eofeValid and not eofeOut;
      mFifoAxisSlave.tReady <= mAxisSlave.tReady or (eofeValid and eofeOut);

      eofeRdEn <= mFifoAxisMaster.tValid and mFifoAxisMaster.tLast and mFifoAxisSlave.tReady;
   end process master;

--   comb : process (axisRst, r) is
--      variable v : RegType;
--   begin
--      -- Latch the current value
--      v := r;


--      -- Synchronous Reset
--      if axisRst = '1' then
--         v := REG_INIT_C;
--      end if;

--      -- Register the variable for next clock cycle
--      rin <= v;

--      -- Outputs
--   end process comb;

--   seq : process (axisClk) is
--   begin
--      if rising_edge(axisClk) then
--         r <= rin after TPD_G;
--      end if;
--   end process seq;


end rtl;

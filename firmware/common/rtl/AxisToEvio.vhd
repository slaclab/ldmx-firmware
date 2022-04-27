-------------------------------------------------------------------------------
-- Title         : AXIS EVIO Header Generation
-- File          : AxisToEvio.vhd
-- Author        : Ryan Herbst, rherbst@slac.stanford.edu
-- Created       : 12/10/2013
-------------------------------------------------------------------------------
-- Description:
-- Add 64-bit EVIO header to AXIS frame.
-------------------------------------------------------------------------------
-- Copyright (c) 2013 by Ryan Herbst. All rights reserved.
-------------------------------------------------------------------------------
-- Modification history:
-- 12/10/2013: created.
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.STD_LOGIC_ARITH.all;

library UNISIM;
use UNISIM.VCOMPONENTS.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiStreamPkg.all;

library ldmx;
use ldmx.HpsPkg.all;

entity AxisToEvio is
   generic (
      TPD_G             : time                       := 1 ns;
      IB_CASCADE_SIZE_G : integer range 1 to (2**24) := 1
      );
   port (

      -- Clock
      axisClk    : in sl;
      axisClkRst : in sl;

      -- Slave Port, evio header sampled with tLast
      evioHeader  : in  slv(31 downto 0);
      sAxisMaster : in  AxiStreamMasterType;
      sAxisSlave  : out AxiStreamSlaveType;

      -- Master Port
      mAxisMaster : out AxiStreamMasterType;
      mAxisSlave  : in  AxiStreamSlaveType
      );
end AxisToEvio;

architecture STRUCTURE of AxisToEvio is

   type StateType is (IDLE_S, HEAD_S, READ_S, PAUSE_S);

   type RegType is record
      state          : StateType;
      frameCount     : slv(31 downto 0);
      countFifoDin   : slv(63 downto 0);
      countFifoWr    : sl;
      countFifoRd    : sl;
      evioHeaderReg  : slv(31 downto 0);
      sAxisMasterReg : AxiStreamMasterType;
      obAxisMaster   : AxiStreamMasterType;
      ibAxisSlave    : AxiStreamSlaveType;
   end record RegType;

   constant REG_INIT_C : RegType := (
      state          => IDLE_S,
      frameCount     => x"00000004",
      countFifoDin   => (others => '0'),
      countFifoWr    => '0',
      countFifoRd    => '0',
      evioHeaderReg  => (others => '0'),
      sAxisMasterReg => AXI_STREAM_MASTER_INIT_C,
      obAxisMaster   => AXI_STREAM_MASTER_INIT_C,
      ibAxisSlave    => AXI_STREAM_SLAVE_INIT_C
      );

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal sAxisMasterInt : AxiStreamMasterType;
   signal sAxisCtrlInt   : AxiStreamCtrlType;
   signal ibAxisMaster   : AxiStreamMasterType;
   signal ibAxisSlave    : AxiStreamSlaveType;
   signal obAxisCtrl     : AxiStreamCtrlType;
   signal countFifoPFull : sl;
   signal countFifoDout  : slv(63 downto 0);
   signal countFifoValid : sl;
   signal countFifoRd    : sl;
   signal bufferReady    : sl;

begin

   -------------------------------------------------------------------
   -- Input FIFO, Must be large enough to hold complete frame, force keeps to 64-bits
   -------------------------------------------------------------------
   process (sAxisMaster, sAxisCtrlInt, countFifoPFull, bufferReady)
   begin
      bufferReady <= (not sAxisCtrlInt.pause) and (not countFifoPFull);

      sAxisSlave.tReady <= bufferReady;

      sAxisMasterInt        <= sAxisMaster;
      sAxisMasterInt.tKeep  <= (others => '1');
      sAxisMasterInt.tValid <= sAxisMaster.tValid and bufferReady;

   end process;

   U_StageFifo : entity surf.AxiStreamFifo
      generic map (
         TPD_G               => TPD_G,
         PIPE_STAGES_G       => 0,
         SLAVE_READY_EN_G    => false,
         VALID_THOLD_G       => 1,
         MEMORY_TYPE_G       => "block",
         XIL_DEVICE_G        => "7SERIES",
         USE_BUILT_IN_G      => false,
         GEN_SYNC_FIFO_G     => true,
         CASCADE_SIZE_G      => IB_CASCADE_SIZE_G,
         CASCADE_PAUSE_SEL_G => (IB_CASCADE_SIZE_G-1),
         FIFO_ADDR_WIDTH_G   => 9,      -- 512 x 64
         FIFO_FIXED_THRESH_G => true,
         FIFO_PAUSE_THRESH_G => 500,
         SLAVE_AXI_CONFIG_G  => HPS_DMA_DATA_CONFIG_C,
         MASTER_AXI_CONFIG_G => HPS_DMA_DATA_CONFIG_C
         ) port map (
            sAxisClk    => axisClk,
            sAxisRst    => axisClkRst,
            sAxisMaster => sAxisMasterInt,
            sAxisSlave  => open,
            sAxisCtrl   => sAxisCtrlInt,
            mAxisClk    => axisClk,
            mAxisRst    => axisClkRst,
            mAxisMaster => ibAxisMaster,
            mAxisSlave  => ibAxisSlave
            );


   ----------------------------------
   -- Counter FIFO
   ----------------------------------
   U_CountFifo : entity surf.Fifo
      generic map (
         TPD_G           => TPD_G,
         RST_POLARITY_G  => '1',
         RST_ASYNC_G     => false,
         GEN_SYNC_FIFO_G => true,
         MEMORY_TYPE_G   => "block",
         FWFT_EN_G       => true,
         USE_DSP48_G     => "no",
         USE_BUILT_IN_G  => false,
         XIL_DEVICE_G    => "7SERIES",
         SYNC_STAGES_G   => 3,
         PIPE_STAGES_G   => 0,
         DATA_WIDTH_G    => 64,
         ADDR_WIDTH_G    => 9,          -- 512 x 64
         INIT_G          => "0",
         FULL_THRES_G    => 500,
         EMPTY_THRES_G   => 1
         ) port map (
            rst           => axisClkRst,
            wr_clk        => axisClk,
            wr_en         => r.countFifoWr,
            din           => r.countFifoDin,
            wr_data_count => open,
            wr_ack        => open,
            overflow      => open,
            prog_full     => countFifoPFull,
            almost_full   => open,
            full          => open,
            not_full      => open,
            rd_clk        => axisClkRst,
            rd_en         => countFifoRd,
            dout          => countFifoDout,
            rd_data_count => open,
            valid         => countFifoValid,
            underflow     => open,
            prog_empty    => open,
            almost_empty  => open,
            empty         => open
            );


   ----------------------------------
   -- Frame Tracking
   ----------------------------------

   -- Sync
   process (axisClk) is
   begin
      if (rising_edge(axisClk)) then
         r <= rin after TPD_G;
      end if;
   end process;

   -- Async
   process (axisClkRst, r, sAxisMasterInt, evioHeader, countFifoPFull,
            countFifoValid, countFifoDout, obAxisCtrl, ibAxisMaster) is
      variable v         : RegType;
      variable nextCount : slv(31 downto 0);
   begin
      v := r;

      -- Pipeline Input Stream
      v.sAxisMasterReg := sAxisMasterInt;
      v.evioHeaderReg  := evioHeader;

      -- Next count
      nextCount := r.frameCount + 8;

      -- Init
      v.countFifoWr := '0';

      -- FIFO Control
      if r.sAxisMasterReg.tValid = '1' then
         if r.sAxisMasterReg.tLast = '1' then
            v.countFifoWr  := '1';
            v.countFifoDin := r.evioHeaderReg & nextCount;
            v.frameCount   := x"00000004";
         else
            v.frameCount := nextCount;
         end if;
      end if;

      -- Outbound init
      v.countFifoRd  := '0';
      v.ibAxisSlave  := AXI_STREAM_SLAVE_INIT_C;
      v.obAxisMaster := AXI_STREAM_MASTER_INIT_C;

      -- Outbound state machine
      case r.state is

         when IDLE_S =>
            if countFifoValid = '1' and obAxisCtrl.pause = '0' then
               v.state := HEAD_S;
            end if;

         when HEAD_S =>
            v.obAxisMaster.tValid              := '1';
            v.obAxisMaster.tData(31 downto 0)  := "00" & countFifoDout(31 downto 2);  -- Size in # of 32-bits
            v.obAxisMaster.tData(63 downto 32) := countFifoDout(63 downto 32);  -- Header value
            v.countFifoRd                      := '1';
            v.state                            := READ_S;

         when READ_S =>
            v.obAxisMaster       := ibAxisMaster;
            v.ibAxisSlave.tReady := '1';

            if ibAxisMaster.tLast = '1' and ibAxisMaster.tValid = '1' then
               v.state := IDLE_S;
            elsif obAxisCtrl.pause = '1' then
               v.state := PAUSE_S;
            end if;

         when PAUSE_S =>
            if obAxisCtrl.pause = '0' then
               v.state := READ_S;
            end if;

         when others =>
            v.state := IDLE_S;

      end case;

      -- Reset
      if (axisClkRst = '1') then
         v := REG_INIT_C;
      end if;

      -- Next register assignment
      rin <= v;

      -- Outbound
      ibAxisSlave <= v.ibAxisSlave;
      countFifoRd <= v.countFifoRd;

   end process;


   ----------------------------------
   -- Output FIFO
   ----------------------------------
   U_ObFifo : entity surf.AxiStreamFifo
      generic map (
         TPD_G               => TPD_G,
         PIPE_STAGES_G       => 0,
         SLAVE_READY_EN_G    => false,
         VALID_THOLD_G       => 1,
         MEMORY_TYPE_G       => "block",
         XIL_DEVICE_G        => "7SERIES",
         USE_BUILT_IN_G      => false,
         GEN_SYNC_FIFO_G     => true,
         CASCADE_SIZE_G      => 1,
         FIFO_ADDR_WIDTH_G   => 9,      -- 512 x 64
         FIFO_FIXED_THRESH_G => true,
         FIFO_PAUSE_THRESH_G => 500,
         SLAVE_AXI_CONFIG_G  => HPS_DMA_DATA_CONFIG_C,
         MASTER_AXI_CONFIG_G => HPS_DMA_DATA_CONFIG_C
         ) port map (
            sAxisClk    => axisClk,
            sAxisRst    => axisClkRst,
            sAxisMaster => r.obAxisMaster,
            sAxisSlave  => open,
            sAxisCtrl   => obAxisCtrl,
            mAxisClk    => axisClk,
            mAxisRst    => axisClkRst,
            mAxisMaster => mAxisMaster,
            mAxisSlave  => mAxisSlave
            );

end architecture STRUCTURE;


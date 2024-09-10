library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
use surf.EthMacPkg.all;

library ldmx_tdaq;
use ldmx_tdaq.FcPkg.all;
use ldmx_tdaq.DaqPkg.all;

entity DaqEventFormatter is

   generic (
      TPD_G                     : time                  := 1 ns;
      SUBSYSTEM_ID_G            : slv(7 downto 0);
      CONTRIBUTOR_ID_G          : slv(7 downto 0);
      RAW_AXIS_CFG_G            : AxiStreamConfigType;
      EVENT_FIFO_PAUSE_THRESH_G : integer               := 1;
      EVENT_FIFO_ADDR_WIDTH_G   : integer range 4 to 48 := 8;
      EVENT_FIFO_SYNTH_MODE_G   : string                := "inferred";
      EVENT_FIFO_MEMORY_TYPE_G  : string                := "block"
      );

   port (
      -- TS Trig Data and Timing
      fcClk185 : in sl;
      fcRst185 : in sl;
      fcBus    : in FcBusType;

      -- Streaming interface
      axisClk         : in  sl;
      axisRst         : in  sl;
      rawAxisMaster   : in  AxiStreamMasterType;
      rawAxisCtrl     : out AxiStreamCtrlType;
      eventAxisMaster : out AxiStreamMasterType;
      eventAxisSlave  : in  AxiStreamSlaveType);

end entity DaqEventFormatter;

architecture rtl of DaqEventFormatter is

   type StateType is (
      WAIT_ROR_S,
      DO_DATA_S);

   type RegType is record
      state            : StateType;
      rorFifoRdEn      : sl;
      rawFifoAxisSlave : AxiStreamSlaveType;
      eventAxisMaster  : AxiStreamMasterType;
   end record RegType;

   constant REG_INIT_C : RegType := (
      state            => WAIT_ROR_S,
      rorFifoRdEn      => '0',
      rawFifoAxisSlave => AXI_STREAM_SLAVE_INIT_C,
      eventAxisMaster  => axiStreamMasterInit(DAQ_EVENT_AXIS_CONFIG_C));

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal rawFifoAxisMaster : AxiStreamMasterType;
   signal rorFifoTimestamp  : FcTimestampType;
   signal eventAxisCtrl     : AxiStreamCtrlType;

begin

   -------------------------------------------------------------------------------------------------
   -- Reformat stream to standard DAQ data width
   -------------------------------------------------------------------------------------------------
   U_AxiStreamFifoV2_RAW_FIFO : entity surf.AxiStreamFifoV2
      generic map (
         TPD_G               => TPD_G,
         PIPE_STAGES_G       => 0,
         SLAVE_READY_EN_G    => false,
--          VALID_THOLD_G          => VALID_THOLD_G,
--          VALID_BURST_MODE_G     => VALID_BURST_MODE_G,
         GEN_SYNC_FIFO_G     => true,
         FIFO_FIXED_THRESH_G => true,
         FIFO_PAUSE_THRESH_G => 2**5-2,
         FIFO_ADDR_WIDTH_G   => 5,
         SYNTH_MODE_G        => "inferred",
         MEMORY_TYPE_G       => "distributed",
         SLAVE_AXI_CONFIG_G  => RAW_AXIS_CFG_G,
         MASTER_AXI_CONFIG_G => EMAC_AXIS_CONFIG_C)
      port map (
         sAxisClk    => axisClk,                -- [in]
         sAxisRst    => axisRst,                -- [in]
         sAxisMaster => rawAxisMaster,          -- [in]
         sAxisSlave  => open,                   -- [out]
         sAxisCtrl   => rawAxisCtrl,            -- [out]
         mAxisClk    => axisClk,                -- [in]
         mAxisRst    => axisRst,                -- [in]
         mAxisMaster => rawFifoAxisMaster,      -- [out]
         mAxisSlave  => rin.rawFifoAxisSlave);  -- [in]

   U_FcTimestampFifo_1 : entity ldmx_tdaq.FcTimestampFifo
      generic map (
         TPD_G           => TPD_G,
         GEN_SYNC_FIFO_G => false,
         SYNTH_MODE_G    => "inferred",
         MEMORY_TYPE_G   => "distributed",
         ADDR_WIDTH_G    => 5)
      port map (
         rst         => fcRst185,              -- [in]
         wrClk       => fcClk185,              -- [in]
         wrFull      => open,                  -- [out]
         wrTimestamp => fcBus.readoutRequest,  -- [in]
         rdClk       => axisClk,               -- [in]
         rdEn        => r.rorFifoRdEn,         -- [in]
         rdTimestamp => rorFifoTimestamp,      -- [out]
         rdValid     => open);                 -- [out]

   comb : process (axisRst, eventAxisCtrl, r, rawFifoAxisMaster, rorFifoTimestamp) is
      variable v : RegType;
   begin
      v := r;

      v.eventAxisMaster := axiStreamMasterInit(EMAC_AXIS_CONFIG_C);
      v.rorFifoRdEn     := '0';

      case r.state is
         when WAIT_ROR_S =>
            -- Got a ROR, write the header
            if (rorFifoTimestamp.valid = '1' and eventAxisCtrl.pause = '0') then
               v.rorFifoRdEn                         := '1';
               v.eventAxisMaster.tValid              := '1';
               v.eventAxisMaster.tData               := (others => '0');
               v.eventAxisMaster.tData(71 downto 0)  := toSlv(rorFifoTimestamp);
               v.eventAxisMaster.tData(79 downto 72) := CONTRIBUTOR_ID_G;
               v.eventAxisMaster.tData(87 downto 80) := SUBSYSTEM_ID_G;
               v.state                               := DO_DATA_S;
            end if;

         when DO_DATA_S =>
            -- Write Data after header until tLast
            v.rawFifoAxisSlave.tReady := rawFifoAxisMaster.tValid;
            v.eventAxisMaster  := rawFifoAxisMaster;
            if (rawFifoAxisMaster.tValid = '1' and rawFifoAxisMaster.tLast = '1') then
               v.state := WAIT_ROR_S;
            end if;

      end case;

      -- Reset
      if (axisRst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

   end process;

   seq : process (axisClk) is
   begin
      if (rising_edge(axisClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;


   U_AxiStreamFifoV2_EVENT_FIFO : entity surf.AxiStreamFifoV2
      generic map (
         TPD_G               => TPD_G,
         PIPE_STAGES_G       => 0,
         SLAVE_READY_EN_G    => false,
--          VALID_THOLD_G          => VALID_THOLD_G,
--          VALID_BURST_MODE_G     => VALID_BURST_MODE_G,
         GEN_SYNC_FIFO_G     => true,
--         FIFO_FIXED_THRESH_G => true,
--         FIFO_PAUSE_THRESH_G => EVENT_FIFO_PAUSE_THRESH_G,
         FIFO_ADDR_WIDTH_G   => EVENT_FIFO_ADDR_WIDTH_G,
         SYNTH_MODE_G        => EVENT_FIFO_SYNTH_MODE_G,
         MEMORY_TYPE_G       => EVENT_FIFO_MEMORY_TYPE_G,
         SLAVE_AXI_CONFIG_G  => EMAC_AXIS_CONFIG_C,
         MASTER_AXI_CONFIG_G => EMAC_AXIS_CONFIG_C)
      port map (
         sAxisClk    => axisClk,            -- [in]
         sAxisRst    => axisRst,            -- [in]
         sAxisMaster => r.eventAxisMaster,  -- [in]
         sAxisSlave  => open,               -- [out]
         sAxisCtrl   => eventAxisCtrl,      -- [out]
         mAxisClk    => axisClk,            -- [in]
         mAxisRst    => axisRst,            -- [in]
         mAxisMaster => eventAxisMaster,    -- [out]
         mAxisSlave  => eventAxisSlave);    -- [in]
end architecture rtl;

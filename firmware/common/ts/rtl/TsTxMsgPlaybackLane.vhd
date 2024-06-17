-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- This file is part of LDMX. It is subject to
-- the license terms in the LICENSE.txt file found in the top-level directory
-- of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of LDMX, including this file, may be
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

library ldmx_tdaq;
use ldmx_tdaq.FcPkg.all;

library ldmx_ts;
use ldmx_ts.TsPkg.all;


entity TsTxMsgPlaybackLane is

   generic (
      TPD_G            : time             := 1 ns;
      AXIL_BASE_ADDR_G : slv(31 downto 0) := (others => '0'));
   port (
      --------------
      -- Main Output
      --------------
      tsTxClk : in  sl;
      tsTxRst : in  sl;
      tsTxMsg : out TsData6ChMsgType;

      -----------------------------
      -- Fast Control clock and bus
      -----------------------------
      fcClk185 : in sl;
      fcRst185 : in sl;
      fcBus    : in FcBusType;

      -- Axil inteface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType  := AXI_LITE_READ_SLAVE_EMPTY_DECERR_C;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType := AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);

end entity TsTxMsgPlaybackLane;

architecture rtl of TsTxMsgPlaybackLane is

   constant NUM_CHANNELS_C : integer := 6;

   constant NUM_AXIL_MASTERS_C : natural := NUM_CHANNELS_C;

   constant AXIL_XBAR_CFG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXIL_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXIL_MASTERS_C, AXIL_BASE_ADDR_G, 20, 16);

   signal ramAxilWriteMasters : AxiLiteWriteMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal ramAxilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal ramAxilReadMasters  : AxiLiteReadMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal ramAxilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0);

   signal ramDout : slv(95 downto 0);

   signal rdValid : sl;

   type StateType is (
      WAIT_T0_S,
      SEND_DATA_S);

   -- fcClk185 signals
   type RegType is record
      state   : StateType;
      ramAddr : slv(13 downto 0);
      tsMsg   : TsData6ChMsgType;
   end record RegType;

   constant REG_INIT_C : RegType := (
      state   => WAIT_T0_S,
      ramAddr => (others => '0'),
      tsMsg   => TS_DATA_6CH_MSG_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;


begin
   ---------------------
   -- AXI-Lite Crossbar
   ---------------------
--    U_XBAR : entity surf.AxiLiteCrossbar
--       generic map (
--          TPD_G              => TPD_G,
--          NUM_SLAVE_SLOTS_G  => 1,
--          NUM_MASTER_SLOTS_G => NUM_AXIL_MASTERS_C,
--          MASTERS_CONFIG_G   => AXIL_XBAR_CFG_C)
--       port map (
--          axiClk              => axilClk,
--          axiClkRst           => axilRst,
--          sAxiWriteMasters(0) => axilWriteMaster,
--          sAxiWriteSlaves(0)  => axilWriteSlave,
--          sAxiReadMasters(0)  => axilReadMaster,
--          sAxiReadSlaves(0)   => axilReadSlave,
--          mAxiWriteMasters    => ramAxilWriteMasters,
--          mAxiWriteSlaves     => ramAxilWriteSlaves,
--          mAxiReadMasters     => ramAxilReadMasters,
--          mAxiReadSlaves      => ramAxilReadSlaves);

   -------------------------------------------------------------------------------------------------
   -- Make a RAM for each TS channel (6 or 8)
   -------------------------------------------------------------------------------------------------
--   GEN_RAM : for i in NUM_CHANNELS_C-1 downto 0 generate
   U_AxiDualPortRam_1 : entity surf.AxiDualPortRam
      generic map (
         TPD_G            => TPD_G,
         SYNTH_MODE_G     => "inferred",
         MEMORY_TYPE_G    => "ultra",
         READ_LATENCY_G   => 3,
         AXI_WR_EN_G      => true,
         SYS_WR_EN_G      => false,
         SYS_BYTE_WR_EN_G => false,
         COMMON_CLK_G     => false,
         ADDR_WIDTH_G     => 14,
         DATA_WIDTH_G     => 96)
      port map (
         axiClk         => axilClk,          -- [in]
         axiRst         => axilRst,          -- [in]
         axiReadMaster  => axilReadMaster,   -- [in]
         axiReadSlave   => axilReadSlave,    -- [out]
         axiWriteMaster => axilWriteMaster,  -- [in]
         axiWriteSlave  => axilWriteSlave,   -- [out]
         clk            => fcClk185,         -- [in]
         rst            => fcRst185,         -- [in]
         addr           => r.ramAddr,        -- [in]
         dout           => ramDout);         -- [out]
--   end generate GEN_RAM;


   comb : process (fcBus, fcRst185, r, ramDout) is
      variable v : RegType := REG_INIT_C;
   begin
      v := r;

      -- Read RAM entries on FC clock
      -- Format into TS Messages
      -- Place message into a FIFO

      v.tsMsg := TS_DATA_6CH_MSG_INIT_C;
      for i in 5 downto 0 loop
         v.tsMsg := toTsData6ChMsg(ramDout(TS_DATA_6CH_MSG_SIZE_C-1 downto 0));
--          v.tsMsg.adc(i) := ramDout(i)(7 downto 0);
--          v.tsMsg.tdc(i) := ramDout(i)(13 downto 8);
--          v.tsMsg.capId  := (others => '0');  -- ramDout(0)(7 downto 6);
--          v.tsMsg.ce     := '0';              --ramDout(0)(14);
      end loop;

      case r.state is
         when WAIT_T0_S =>
            v.ramAddr := (others => '0');
            if (fcBus.pulseStrobe = '1' and fcBus.stateChanged = '1' and fcBus.runState = RUN_STATE_PRESTART_C and ramDout(95) = '1') then
               v.tsMsg.strobe := '1';
               v.tsMsg.bc0    := '1';
               v.ramAddr      := r.ramAddr + 1;
               v.state        := SEND_DATA_S;
            end if;

         when SEND_DATA_S =>
            if (fcBus.bunchStrobe = '1') then
               v.tsMsg.strobe := '1';
               v.ramAddr      := r.ramAddr + 1;
               if (ramDout(94) = '1') then
                  v.state := WAIT_T0_S;
               end if;
            end if;
      end case;

      if (fcBus.runState = RUN_STATE_RESET_C) then
         v.state := WAIT_T0_S;
      end if;


      -- Reset
      if (fcRst185 = '1') then
         v := REG_INIT_C;
      end if;

      rin <= v;


   end process comb;

   seq : process (fcClk185) is
   begin
      if (rising_edge(fcClk185)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

   -------------------------------------------------------------------------------------------------
   -- Synchronize output messages to TS GT clock
   -------------------------------------------------------------------------------------------------
   U_TsMsgFifo_1 : entity ldmx_ts.TsMsgFifo
      generic map (
         TPD_G           => TPD_G,
         GEN_SYNC_FIFO_G => false,
         SYNTH_MODE_G    => "inferred",
         MEMORY_TYPE_G   => "distributed",
         ADDR_WIDTH_G    => 5)
      port map (
         rst     => fcRst185,           -- [in]
         wrClk   => fcClk185,           -- [in]
         wrEn    => r.tsMsg.strobe,     -- [in]
         wrFull  => open,               -- [out]
         wrMsg   => r.tsMsg,            -- [in]
         rdClk   => tsTxClk,            -- [in]
         rdEn    => rdValid,            -- [in]
         rdMsg   => tsTxMsg,            -- [out]
         rdValid => rdValid);           -- [out]


end rtl;



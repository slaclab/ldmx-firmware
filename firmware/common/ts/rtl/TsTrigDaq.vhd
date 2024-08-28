-------------------------------------------------------------------------------
-- File       : TsTrigDaq.vhd
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
use surf.Pgp2fcPkg.all;
use surf.EthMacPkg.all;
use surf.SsiPkg.all;

library ldmx_tdaq;
use ldmx_tdaq.FcPkg.all;

library ldmx_ts;
use ldmx_ts.TsPkg.all;

entity TsTrigDaq is

   generic (
      TPD_G      : time    := 1 ns;
      TS_LANES_G : integer := 2);

   port (
      -- TS Trig Data and Timing
      fcClk185      : in sl;
      fcRst185      : in sl;
      fcBus         : in FcBusType;
      tsTrigDaqData : in TsS30xlThresholdTriggerDaqType;
--       tsTrigValid      : in sl;
--       tsTrigTimestamp  : in FcTimestampType;
--       tsTrigHits       : in slv(11 downto 0);
--       tsTrigAmplitudes : in slv17Array(11 downto 0);

      -- Streaming interface to ETH
      axisClk          : in  sl;
      axisRst          : in  sl;
      tsTrigAxisMaster : out AxiStreamMasterType;
      tsTrigAxisSlave  : in  AxiStreamSlaveType);

end entity TsTrigDaq;

architecture rtl of TsTrigDaq is

   constant AXIS_CFG_C : AxiStreamConfigType := ssiAxiStreamConfig(dataBytes => 16, tDestBits => 0);

   type StateType is (
      WAIT_ROR_S,
      DO_DATA_A_S,
      DO_DATA_B_S,
      DO_DATA_C_S,
      FIFO_RD_S,
      TAIL_S);

   type RegType is record
      state      : StateType;
      fifoRdEn   : sl;
      axisMaster : AxiStreamMasterType;
   end record RegType;

   constant REG_INIT_C : RegType := (
      state      => WAIT_ROR_S,
      fifoRdEn   => '0',
      axisMaster => axiStreamMasterInit(AXIS_CFG_C));

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;


   signal delayedAmplitudes : Slv17Array(11 downto 0);
   signal fifoAmplitudes    : slv17Array(11 downto 0);
   signal delayedHits       : slv(11 downto 0);
   signal fifoHits          : slv(11 downto 0);

   signal rorTimestampFifoInSlv  : slv(FC_TIMESTAMP_SIZE_C-1 downto 0);
   signal rorTimestampFifoOutSlv : slv(FC_TIMESTAMP_SIZE_C-1 downto 0);
   signal rorTimestampFifoValid  : sl;

   signal aligned  : slv(12 downto 0);
   signal axisCtrl : AxiStreamCtrlType;

begin

   -------------------------------------------------------------------------------------------------
   -- Delay and buffer amplitudes
   -------------------------------------------------------------------------------------------------
   GEN_LANES : for i in 11 downto 0 generate
      -- Buffer and delay incoming data to ROR
      U_RorDaqDelay_Amplitude : entity ldmx_tdaq.RorDaqDataDelay
         generic map (
            TPD_G         => TPD_G,
            DATA_WIDTH_G  => 17,
            MEMORY_TYPE_G => "block")
         port map (
            fcClk185    => fcClk185,                     -- [in]
            fcRst185    => fcRst185,                     -- [in]
            fcBus       => fcBus,                        -- [in]
            timestampIn => tsTrigDaqData.timestamp,      -- [in]
            dataIn      => tsTrigDaqData.amplitudes(i),  -- [in]
            aligned     => aligned(i),                   -- [out]
            dataOut     => delayedAmplitudes(i));        -- [out]


      -- Buffer delayed data in fifos upon each ROR
      -- Will be read out into AXI Stream frame
      ROR_DATA_FIFO_AMPLITUDE : entity surf.Fifo
         generic map (
            TPD_G           => TPD_G,
            GEN_SYNC_FIFO_G => false,
            FWFT_EN_G       => true,
            SYNTH_MODE_G    => "inferred",
            MEMORY_TYPE_G   => "distributed",
            DATA_WIDTH_G    => 17,
            ADDR_WIDTH_G    => 5)
         port map (
            rst    => fcRst185,                     -- [in]
            wr_clk => fcClk185,                     -- [in]
            wr_en  => fcBus.readoutRequest.strobe,  -- [in]
            din    => delayedAmplitudes(i),         -- [in]
            rd_clk => axisClk,                      -- [in]
            rd_en  => r.fifoRdEn,                   -- [in]
            dout   => fifoAmplitudes(i),            -- [out]
            valid  => open);                        -- [out]

   end generate;

   -------------------------------------------------------------------------------------------------
   -- Delay and Buffer hits
   -------------------------------------------------------------------------------------------------
   U_RorDaqDataDelay_Hits : entity ldmx_tdaq.RorDaqDataDelay
      generic map (
         TPD_G         => TPD_G,
         DATA_WIDTH_G  => 12,
         MEMORY_TYPE_G => "block")
      port map (
         fcClk185    => fcClk185,                 -- [in]
         fcRst185    => fcRst185,                 -- [in]
         fcBus       => fcBus,                    -- [in]
         timestampIn => tsTrigDaqData.timestamp,  -- [in]
         dataIn      => tsTrigDaqData.hits,       -- [in]
         aligned     => aligned(12),              -- [out]
         dataOut     => delayedHits);             -- [out]


   -- Buffer delayed data in fifos upon each ROR
   -- Will be read out into AXI Stream frame
   ROR_DATA_FIFO_HITS : entity surf.Fifo
      generic map (
         TPD_G           => TPD_G,
         GEN_SYNC_FIFO_G => false,
         FWFT_EN_G       => true,
         SYNTH_MODE_G    => "inferred",
         MEMORY_TYPE_G   => "distributed",
         DATA_WIDTH_G    => 12,
         ADDR_WIDTH_G    => 5)
      port map (
         rst    => fcRst185,                     -- [in]
         wr_clk => fcClk185,                     -- [in]
         wr_en  => fcBus.readoutRequest.strobe,  -- [in]
         din    => delayedHits,                  -- [in]
         rd_clk => axisClk,                      -- [in]
         rd_en  => r.fifoRdEn,                   -- [in]
         dout   => fifoHits,                     -- [out]
         valid  => open);                        -- [out]


   -- Buffer ROR timestamps
   rorTimestampFifoInSlv <= toSlv( tsTrigDaqData.timestamp);
   ROR_TIMESTAMP_FIFO : entity surf.Fifo
      generic map (
         TPD_G           => TPD_G,
         GEN_SYNC_FIFO_G => false,
         FWFT_EN_G       => true,
         SYNTH_MODE_G    => "inferred",
         MEMORY_TYPE_G   => "distributed",
         DATA_WIDTH_G    => FC_TIMESTAMP_SIZE_C,
         ADDR_WIDTH_G    => 5)
      port map (
         rst    => fcRst185,                     -- [in]
         wr_clk => fcClk185,                     -- [in]
         wr_en  => fcBus.readoutRequest.strobe,  -- [in]
         din    => rorTimestampFifoInSlv,        -- [in]
         rd_clk => axisClk,                      -- [in]
         rd_en  => r.fifoRdEn,                   -- [in]
         dout   => rorTimestampFifoOutSlv,       -- [out]
         valid  => rorTimestampFifoValid);       -- [out]


   comb : process (fifoAmplitudes, fifoHits, r, rorTimestampFifoOutSlv, rorTimestampFifoValid) is
      variable v : RegType;
   begin
      v := r;

      v.axisMaster := axiStreamMasterInit(AXIS_CFG_C);
      v.fifoRdEn   := '0';

      case r.state is
         when WAIT_ROR_S =>
            -- Got a ROR, write the header
            if (rorTimestampFifoValid = '1') then
               v.axisMaster.tValid             := '1';
               v.axisMaster.tData(69 downto 0) := rorTimestampFifoOutSlv;
               v.state                         := DO_DATA_A_S;
            end if;


         when DO_DATA_A_S =>
            v.axisMaster.tValid               := '1';
            v.axisMaster.tData(16 downto 0)   := fifoAmplitudes(0);
            v.axisMaster.tData(48 downto 32)  := fifoAmplitudes(1);
            v.axisMaster.tData(80 downto 64)  := fifoAmplitudes(2);
            v.axisMaster.tData(112 downto 96) := fifoAmplitudes(3);

            v.axisMaster.tData(24)  := fifoHits(0);
            v.axisMaster.tData(56)  := fifoHits(1);
            v.axisMaster.tData(88)  := fifoHits(2);
            v.axisMaster.tData(120) := fifoHits(3);

            v.state := DO_DATA_B_S;

         when DO_DATA_B_S =>
            v.axisMaster.tValid               := '1';
            v.axisMaster.tData(16 downto 0)   := fifoAmplitudes(4);
            v.axisMaster.tData(48 downto 32)  := fifoAmplitudes(5);
            v.axisMaster.tData(80 downto 64)  := fifoAmplitudes(6);
            v.axisMaster.tData(112 downto 96) := fifoAmplitudes(7);

            v.axisMaster.tData(24)  := fifoHits(4);
            v.axisMaster.tData(56)  := fifoHits(5);
            v.axisMaster.tData(88)  := fifoHits(6);
            v.axisMaster.tData(120) := fifoHits(7);

            v.state := DO_DATA_C_S;

         when DO_DATA_C_S =>
            v.axisMaster.tValid               := '1';
            v.axisMaster.tData(16 downto 0)   := fifoAmplitudes(8);
            v.axisMaster.tData(48 downto 32)  := fifoAmplitudes(9);
            v.axisMaster.tData(80 downto 64)  := fifoAmplitudes(10);
            v.axisMaster.tData(112 downto 96) := fifoAmplitudes(11);

            v.axisMaster.tData(24)  := fifoHits(8);
            v.axisMaster.tData(56)  := fifoHits(9);
            v.axisMaster.tData(88)  := fifoHits(10);
            v.axisMaster.tData(120) := fifoHits(11);

            v.state := FIFO_RD_S;

         when FIFO_RD_S =>
            v.fifoRdEn := '1';
            v.state    := TAIL_S;


         when TAIL_S =>
            -- Wait 1 cycle for fifoRdEn to fall back
            v.state := WAIT_ROR_S;

      end case;

      rin <= v;

   end process comb;

   seq : process (axisClk) is
   begin
      if (rising_edge(axisClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

   U_AxiStreamFifoV2_1 : entity surf.AxiStreamFifoV2
      generic map (
         TPD_G               => TPD_G,
         PIPE_STAGES_G       => 0,
         SLAVE_READY_EN_G    => false,
--          VALID_THOLD_G          => VALID_THOLD_G,
--          VALID_BURST_MODE_G     => VALID_BURST_MODE_G,
         GEN_SYNC_FIFO_G     => true,
         FIFO_FIXED_THRESH_G => true,
         FIFO_PAUSE_THRESH_G => 2**7-16,
         FIFO_ADDR_WIDTH_G   => 7,
         SYNTH_MODE_G        => "inferred",
         MEMORY_TYPE_G       => "block",
         SLAVE_AXI_CONFIG_G  => AXIS_CFG_C,
         MASTER_AXI_CONFIG_G => EMAC_AXIS_CONFIG_C)
      port map (
         sAxisClk    => axisClk,           -- [in]
         sAxisRst    => axisRst,           -- [in]
         sAxisMaster => r.axisMaster,      -- [in]
         sAxisSlave  => open,              -- [out]
         sAxisCtrl   => axisCtrl,          -- [out]
         mAxisClk    => axisClk,           -- [in]
         mAxisRst    => axisRst,           -- [in]
         mAxisMaster => tsTrigAxisMaster,  -- [out]
         mAxisSlave  => tsTrigAxisSlave);  -- [in]

end architecture rtl;

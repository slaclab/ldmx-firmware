-------------------------------------------------------------------------------
-- Title      : ADC Readout architecture select
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
use surf.AxiStreamPkg.all;
use surf.Ad9249Pkg.all;

library ldmx;
use ldmx.AdcReadoutPkg.all;

library UNISIM;
use UNISIM.vcomponents.all;

entity AdcReadout is
   generic (
      TPD_G           : time                 := 1 ns;
      SIMULATION_G    : boolean              := false;
      FPGA_ARCH_G     : string               := "artix-us+";
      NUM_CHANNELS_G  : natural range 1 to 8 := 5;
      IODELAY_GROUP_G : string);
   port (
      -- Master system clock, 125Mhz
      axilClk : in sl;
      axilRst : in sl;

      -- Axil Interface
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;

      -- Reset for adc deserializer
      adcClkRst : in sl;

      -- Serial Data from ADC
      adc : in AdcChipOutType;

      -- Deserialized ADC Data
      adcStreamClk : in  sl;
      adcStreams   : out AxiStreamMasterArray(NUM_CHANNELS_G-1 downto 0) :=
      (others => axiStreamMasterInit(ADC_READOUT_AXIS_CFG_C)));

end AdcReadout;

-- Define architecture
architecture rtl of AdcReadout is

   component Ad9249ReadoutGroup2 is
      generic (
         TPD_G           : time;
         SIM_DEVICE_G    : string;
         NUM_CHANNELS_G  : natural;
         SIMULATION_G    : boolean;
         DEFAULT_DELAY_G : slv(8 downto 0) := (others => '0');
         ADC_INVERT_CH_G : slv(7 downto 0):= (others => '0'));
      port (
         axilClk         : in  sl;
         axilRst         : in  sl;
         axilWriteMaster : in  AxiLiteWriteMasterType;
         axilWriteSlave  : out AxiLiteWriteSlaveType                           := AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C;
         axilReadMaster  : in  AxiLiteReadMasterType;
         axilReadSlave   : out AxiLiteReadSlaveType                            := AXI_LITE_READ_SLAVE_EMPTY_DECERR_C;
         adcClkRst       : in  sl;
         adcSerial       : in  Ad9249SerialGroupType;
         adcStreamClk    : in  sl;
         adcStreams      : out AxiStreamMasterArray(NUM_CHANNELS_G-1 downto 0) := (others => axiStreamMasterInit(AD9249_AXIS_CFG_G)));
   end component Ad9249ReadoutGroup2;

begin
   GEN_7SERIES : if (FPGA_ARCH_G = "artix-7") generate
      U_AdcReadout7_1 : entity ldmx.AdcReadout7
         generic map (
            TPD_G           => TPD_G,
            SIMULATION_G    => SIMULATION_G,
            NUM_CHANNELS_G  => NUM_CHANNELS_G,
            IODELAY_GROUP_G => IODELAY_GROUP_G)
         port map (
            axilClk         => axilClk,          -- [in]
            axilRst         => axilRst,          -- [in]
            axilWriteMaster => axilWriteMaster,  -- [in]
            axilWriteSlave  => axilWriteSlave,   -- [out]
            axilReadMaster  => axilReadMaster,   -- [in]
            axilReadSlave   => axilReadSlave,    -- [out]
            adcClkRst       => adcClkRst,        -- [in]
            adc             => adc,              -- [in]
            adcStreamClk    => adcStreamClk,     -- [in]
            adcStreams      => adcStreams);      -- [out]
   end generate GEN_7SERIES;

   GEN_ULTRASCALE_PLUS : if (FPGA_ARCH_G = "artix-us+") generate
      U_Ad9249ReadoutGroup2_1 : Ad9249ReadoutGroup2
         generic map (
            TPD_G          => TPD_G,
            SIM_DEVICE_G   => "ULTRASCALE+",
            NUM_CHANNELS_G => NUM_CHANNELS_G,
            SIMULATION_G   => SIMULATION_G)
--             DEFAULT_DELAY_G => DEFAULT_DELAY_G,
--             ADC_INVERT_CH_G => ADC_INVERT_CH_G)
         port map (
            axilClk         => axilClk,          -- [in]
            axilRst         => axilRst,          -- [in]
            axilWriteMaster => axilWriteMaster,  -- [in]
            axilWriteSlave  => axilWriteSlave,   -- [out]
            axilReadMaster  => axilReadMaster,   -- [in]
            axilReadSlave   => axilReadSlave,    -- [out]
            adcClkRst       => adcClkRst,        -- [in]
            adcSerial.fClkP => adc.fClkP,        -- [in]
            adcSerial.fClkN => adc.fClkP,        -- [in]
            adcSerial.dClkP => adc.dClkP,        -- [in]
            adcSerial.dClkP => adc.dClkP,        -- [in]
            adcSerial.chP   => adc.chP,          -- [in]
            adcSerial.chN   => adc.chN,          -- [in]            
            adcStreamClk    => adcStreamClk,     -- [in]
            adcStreams      => adcStreams);      -- [out]
   end generate GEN_ULTRASCALE_PLUS;

end rtl;

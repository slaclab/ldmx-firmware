-------------------------------------------------------------------------------
-- Title      : Testbench for design "Ads1115AxiBridge"
-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- This file is part of SURF. It is subject to
-- the license terms in the LICENSE.txt file found in the top-level directory
-- of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of SURF, including this file, may be
-- copied, modified, propagated, or distributed except according to the terms
-- contained in the LICENSE.txt file.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;


library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.I2cPkg.all;

library hps_daq; 

----------------------------------------------------------------------------------------------------

entity Ads1115AxiBridgeTb is

end entity Ads1115AxiBridgeTb;

----------------------------------------------------------------------------------------------------

architecture sim of Ads1115AxiBridgeTb is

   -- component generics
   constant TPD_G          : time            := 1 ns;
   constant I2C_DEV_ADDR_C : slv(6 downto 0) := "1001000";
   constant SIMULATION_G   : boolean         := true;

   -- component ports
   signal axiClk         : sl;                                                      -- [in]
   signal axiRst         : sl;                                                      -- [in]
   signal axiReadMaster  : AxiLiteReadMasterType  := AXI_LITE_READ_MASTER_INIT_C;   -- [in]
   signal axiReadSlave   : AxiLiteReadSlaveType   := AXI_LITE_READ_SLAVE_INIT_C;    -- [out]
   signal axiWriteMaster : AxiLiteWriteMasterType := AXI_LITE_WRITE_MASTER_INIT_C;  -- [in]
   signal axiWriteSlave  : AxiLiteWriteSlaveType  := AXI_LITE_WRITE_SLAVE_INIT_C;   -- [out]


   signal i2cRegMasterIn  : I2cRegMasterInType;   -- [out]
   signal i2cRegMasterOut : I2cRegMasterOutType;  -- [in]

   signal hyI2cIn  : i2c_in_type;
   signal hyI2cOut : i2c_out_type;

   signal hyI2cSdaOut : sl;
   signal hyI2cSdaIn  : sl;
   signal hyI2cScl    : sl;

   signal sda : sl;
   signal scl : sl;

begin

   -- component instantiation
   U_Ads1115AxiBridge : entity hps_daq.Ads1115AxiBridge
      generic map (
         TPD_G          => TPD_G,
         I2C_DEV_ADDR_C => I2C_DEV_ADDR_C)
      port map (
         axiClk          => axiClk,            -- [in]
         axiRst          => axiRst,            -- [in]
         axiReadMaster   => axiReadMaster,     -- [in]
         axiReadSlave    => axiReadSlave,      -- [out]
         axiWriteMaster  => axiWriteMaster,    -- [in]
         axiWriteSlave   => axiWriteSlave,     -- [out]
         i2cRegMasterIn  => i2cRegMasterIn,    -- [out]
         i2cRegMasterOut => i2cRegMasterOut);  -- [in]



   -- Finally, the I2cRegMaster
   i2cRegMaster_HybridConfig : entity surf.i2cRegMaster
      generic map (
         TPD_G                => TPD_G,
         OUTPUT_EN_POLARITY_G => 1,
         FILTER_G             => ite(SIMULATION_G, 2, 8),
         PRESCALE_G           => ite(SIMULATION_G, 8, 249))  -- 100 kHz (Simulation faster)
      port map (
         clk    => axiClk,
         srst   => axiRst,
         regIn  => i2cRegMasterIn,
         regOut => i2cRegMasterOut,
         i2ci   => hyI2cIn,
         i2co   => hyI2cOut);

   hyI2cIn.scl <= hyI2cOut.scl when hyI2cOut.scloen = '1' else '1';
   hyI2cIn.sda <= to_x01z(hyI2cSdaIn);
   hyI2cSdaOut <= hyI2cOut.sdaoen;
   hyI2cScl    <= hyI2cOut.scloen;

   scl        <= '0' when hyI2cScl = '1'    else 'H';
   sda        <= '0' when hyI2cSdaOut = '1' else 'H';
   hyI2cSdaIn <= to_x01z(sda);

   U_Ads1115_1 : entity hps_daq.Ads1115
      generic map (
         TPD_G  => TPD_G,
         ADDR_G => '0')
      port map (
         ain(0) => 1.0,                 -- [in]
         ain(1) => 1.1,                 -- [in]
         ain(2) => 1.2,                 -- [in]
         ain(3) => 1.3,                 -- [in]         
         scl    => scl,                 -- [inout]
         sda    => sda);                -- [inout]


   U_ClkRst_1 : entity surf.ClkRst
      generic map (
         CLK_PERIOD_G      => 8 ns,
         CLK_DELAY_G       => 1 ns,
         RST_START_DELAY_G => 0 ns,
         RST_HOLD_TIME_G   => 5 us,
         SYNC_RESET_G      => true)
      port map (
         clkP => axiClk,
         rst  => axiRst);

   main : process is
      variable addr : slv(31 downto 0) := X"00000000";
      variable data : slv(31 downto 0) := X"00000000";
   begin
      wait for 6 us;
      wait until axiClk = '1';

      axiLiteBusSimRead(axiClk, axiReadMaster, axiReadSlave, addr, data, true);
      wait until axiClk = '1';
      addr := X"00000030";
      axiLiteBusSimRead(axiClk, axiReadMaster, axiReadSlave, addr, data, true);
      wait until axiClk = '1';
      wait until axiClk = '1';




   end process main;

end architecture sim;

----------------------------------------------------------------------------------------------------

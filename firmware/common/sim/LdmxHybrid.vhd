-------------------------------------------------------------------------------
-- Title      : LDMX Hybrid Board Model
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
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library surf;
use surf.StdRtlPkg.all;


library ldmx;

entity LdmxHybrid is

   generic (
      TPD_G         : time            := 1 ns);
   port (
      dvdd      : in    real;
      avdd      : in    real;
      v125      : in    real;
      clk       : in    sl;
      trig      : in    sl;
      rstL      : in    sl;
      scl       : inout sl;
      sda       : inout sl;
      analogOut : out   RealArray(0 to 5));

end entity LdmxHybrid;

architecture behavioral of LdmxHybrid is

   signal dvddDiv : real;
   signal avddDiv : real;
   signal v125Div : real;

begin

   APV25_GEN : for i in 0 to 5 generate
      Apv25_Inst : entity ldmx.Apv25
         generic map (
            TPD_G  => TPD_G,
            ADDR_G => ("01" & toSlv(i, 3)))
         port map (
            clk       => clk,
            trig      => trig,
            rstL      => rstL,
            analogOut => analogOut(i),
            sda       => sda,
            scl       => scl);
   end generate APV25_GEN;

   -- Voltage sense dividers
   dvddDiv <= dvdd / 2.0;
   avddDiv <= avdd / 2.0;
   v125Div <= v125 / 1.0;


   Ads1115_1 : entity ldmx.Ads1115
      generic map (
         TPD_G  => TPD_G,
         ADDR_G => '0')
      port map (
         ain(0) => 0.5,                 -- Thermistor
         ain(1) => dvddDiv,
         ain(2) => v125Div,
         ain(3) => avddDiv,
         scl    => scl,
         sda    => sda);

end architecture behavioral;

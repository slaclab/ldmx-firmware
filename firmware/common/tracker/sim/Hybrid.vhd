-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : Hybrid.vhd
-- Author     : Benjamin Reese  <bareese@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2014-01-14
-- Last update: 2024-05-23
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2014 SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library surf;
use surf.StdRtlPkg.all;


library ldmx_tracker;
use ldmx_tracker.LdmxPkg.all;

entity Hybrid is
   
   generic (
      TPD_G         : time := 1 ns;
      HYBRID_TYPE_G : slv(1 downto 0)   := OLD_HYBRID_C);

   port (
      dvdd      : in    real;
      avdd      : in    real;
      v125      : in    real;
      clk       : in    sl;
      trig      : in    sl;
      rstL      : in    sl;
      scl       : inout sl;
      sda       : inout sl;
      analogOut : out   RealArray(0 to 4));

end entity Hybrid;

architecture behavioral of Hybrid is

   signal dvddDiv : real;
   signal avddDiv : real;
   signal v125Div : real;

begin

   APV25_GEN : for i in 0 to 4 generate
      Apv25_Inst : entity ldmx_tracker.Apv25
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

   NEW_HYBRID_GEN : if (HYBRID_TYPE_G = NEW_HYBRID_C) generate
      Ads1115_1 : entity ldmx_tracker.Ads1115
         generic map (
            TPD_G  => TPD_G,
            ADDR_G => '0')
         port map (
            ain(0) => 0.5,              -- Thermistor
            ain(1) => dvddDiv,
            ain(2) => v125Div,
            ain(3) => avddDiv,
            scl    => scl,
            sda    => sda);
   end generate NEW_HYBRID_GEN;

   OLD_HYBRID_GEN : if (HYBRID_TYPE_G = OLD_HYBRID_C) generate
      Ads7924_1 : entity ldmx_tracker.Ads7924
         generic map (
            TPD_G  => TPD_G,
            AVDD_G => 2.5,
            ADDR_G => '0')
         port map (
            ain => (others => 0.5),
            scl => scl,
            sda => sda);
   end generate OLD_HYBRID_GEN;
   
end architecture behavioral;

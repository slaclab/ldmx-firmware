----------------------------------------------------------------------------------
-- Company: FNAL 
-- Engineer: A. Whitbeck
-- 
-- Create Date: 05/30/2024 04:24:42 PM
-- Design Name: 
-- Module Name: SFP_Monitor - Behavioral
-- Project Name: LDMX
-- Target Devices: k26 on custom baseboards
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------



library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_1164.ALL;

library ldmx_ts;
use ldmx_ts.zCCM_Pkg.ALL;

entity SFP_Monitor is
    Port ( 
        sfp_con      : in  SFP_Control ;
        counter      : out STD_LOGIC_VECTOR (23 downto 0); 
        clk          : in STD_LOGIC;
        reset_n      : in STD_LOGIC
         );
end SFP_Monitor;

architecture Behavioral of SFP_Monitor is

component Slow_Control_Monitor
    Port ( 
        d            : in  STD_LOGIC ;
        counter      : out STD_LOGIC_VECTOR (7 downto 0); 
        clk          : in STD_LOGIC;
        reset_n      : in STD_LOGIC
         );
end component;

begin

   RX_LOS : Slow_Control_Monitor 
        Port Map(
                 d => sfp_con.RX_LOS,
                 counter => counter(23 downto 16),
                 clk => clk,
                 reset_n => reset_n
                 );

   TX_FAULT : Slow_Control_Monitor 
        Port Map(
                 d => sfp_con.TX_FAULT,
                 counter => counter(15 downto 8),
                 clk => clk,
                 reset_n => reset_n
                 );

   MOD_ABS : Slow_Control_Monitor 
        Port Map(
                 d => sfp_con.MOD_ABS,
                 counter => counter(7 downto 0),
                 clk => clk,
                 reset_n => reset_n
                 );

end Behavioral;

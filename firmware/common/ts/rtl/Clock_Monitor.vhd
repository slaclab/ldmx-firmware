----------------------------------------------------------------------------------
-- Company: FNAL 
-- Engineer: A. Whitbeck
-- 
-- Create Date: 05/30/2024 04:24:42 PM
-- Design Name: 
-- Module Name: Clock_Monitor - Behavioral
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
use work.zCCM_Pkg.ALL;

entity Clock_Monitor is
    Port ( 
        clk_con      : in  Clock_Control ;
        counter      : out STD_LOGIC_VECTOR (15 downto 0); 
        clk          : in STD_LOGIC;
        reset_n      : in STD_LOGIC
         );
end Clock_Monitor;

architecture Behavioral of Clock_Monitor is

component Slow_Control_Monitor
    Port ( 
        d            : in  STD_LOGIC ;
        counter      : out STD_LOGIC_VECTOR (7 downto 0); 
        clk          : in STD_LOGIC;
        reset_n      : in STD_LOGIC
         );
end component;

begin

   LOS_XAXB : Slow_Control_Monitor 
        Port Map(
                 d => clk_con.LOS_XAXB,
                 counter => counter(15 downto 8),
                 clk => clk,
                 reset_n => reset_n
                 );

   LOL : Slow_Control_Monitor 
        Port Map(
                 d => clk_con.LOL,
                 counter => counter(7 downto 0),
                 clk => clk,
                 reset_n => reset_n
                 );

end Behavioral;

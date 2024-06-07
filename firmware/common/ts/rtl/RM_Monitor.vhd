----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/30/2024 07:54:11 PM
-- Design Name: 
-- Module Name: RM_Monitor - Behavioral
-- Project Name: 
-- Target Devices: 
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

entity RM_Monitor is
    Port ( 
        rm_con      : in  RM_Control ;
        counter      : out STD_LOGIC_VECTOR (7 downto 0); 
        clk          : in STD_LOGIC;
        reset_n      : in STD_LOGIC
         );
end RM_Monitor;

architecture Behavioral of RM_Monitor is

component Slow_Control_Monitor
    Port ( 
        d            : in  STD_LOGIC ;
        counter      : out STD_LOGIC_VECTOR (7 downto 0); 
        clk          : in STD_LOGIC;
        reset_n      : in STD_LOGIC
         );
end component;
    signal rm_reset : STD_LOGIC := '0';
begin

   pgood : Slow_Control_Monitor 
        Port Map(
                 d => rm_con.PGOOD,
                 counter => counter(7 downto 0),
                 clk => clk,
                 reset_n => reset_n
                 );
  
end Behavioral;

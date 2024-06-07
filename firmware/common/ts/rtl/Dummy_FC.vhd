----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06/03/2024 12:48:02 PM
-- Design Name: 
-- Module Name: Dummy_FC - Behavioral
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
use ieee.numeric_std.all;

entity Dummy_FC is
    Port ( clk : in STD_LOGIC;
           reset_n : in STD_LOGIC;
           lcls_clk : out STD_LOGIC;
           fc_command : out STD_LOGIC_VECTOR (31 downto 0);
           command_valid : out STD_LOGIC);
end Dummy_FC;

architecture Behavioral of Dummy_FC is

begin

    lcls_clk <= clk;
   
    process (clk,reset_n)
        variable counter : unsigned (31 downto 0) := (others => '0');
        variable LCLS_Period : unsigned (31 downto 0) := (others => '0');
    begin
        if reset_n = '0' then
            fc_command <= (others => '0');
            command_valid <= '0';
        elsif rising_edge(clk) then
            LCLS_Period := LCLS_Period + 1;
            counter := counter + 1;                       
            command_valid <= '0';
            fc_command <= STD_LOGIC_VECTOR(counter);
            
            if (LCLS_Period = "") then 
                LCLS_Period := (others => '0');
                command_valid <= '1';
            end if;
            
        end if;
                    
    end process;


end Behavioral;

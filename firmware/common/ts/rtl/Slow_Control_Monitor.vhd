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
use work.zCCM_Pkg.ALL;

entity Slow_Control_Monitor is
    Port ( 
        d            : in  STD_LOGIC ;
        counter      : out STD_LOGIC_VECTOR (7 downto 0); 
        clk          : in STD_LOGIC;
        reset_n      : in STD_LOGIC
         );
end Slow_Control_Monitor;

architecture behavioral of Slow_Control_Monitor is
    signal d_synch : STD_LOGIC_VECTOR (3 downto 0 ) := (others => '0');
    signal d_db : STD_LOGIC := '0';
begin

  process (clk, reset_n)
    variable temp_count : unsigned (7 downto 0):= (others => '0');
  begin
    
    if reset_n = '0' then
      temp_count := (others => '0');
    
    elsif rising_edge(clk) then
        d_synch <= d_synch(2 downto 0) & d;
        if d_synch = "1111" then
            d_db <= '1';
            if d_db = '0' then 
                temp_count := temp_count + 1;
            end if;
        elsif d_synch = "0000" then 
            d_db <= '0';
--            if d_db = '1' then 
--                temp_count := temp_count + 1;
--            end if;
        end if;
        
    end if;   
    counter <= STD_LOGIC_VECTOR(temp_count);
  end process;
end behavioral;

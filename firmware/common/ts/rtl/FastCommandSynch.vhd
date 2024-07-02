
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity FastCommandSynch is
    Port ( fast_command : in STD_LOGIC_VECTOR (3 downto 0);
           pulse : out STD_LOGIC;
           fast_command_config : in STD_LOGIC_VECTOR (3 downto 0);
           clk : in STD_LOGIC;
           areset_n : in STD_LOGIC);
end FastCommandSynch;

architecture Behavioral of FastCommandSynch is
signal command_buffer : STD_LOGIC_VECTOR (3 downto 0) := (others => '0');
begin   

process (clk, areset_n)
    begin
        if areset_n = '0' then
           pulse  <= '0';
           command_buffer <= (others => '0');
        elsif rising_edge(clk) then
            if command_buffer = fast_command_config then
                pulse <= '1';
                command_buffer <= (others => '0');
            else
                command_buffer <= fast_command;
                pulse <= '0';                
            end if;
        end if;
    end process;


end Behavioral;

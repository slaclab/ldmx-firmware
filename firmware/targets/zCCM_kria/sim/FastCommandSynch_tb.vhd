library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_FastCommandSynch is
end tb_FastCommandSynch;

architecture Behavioral of tb_FastCommandSynch is
    -- Component Declaration for the Unit Under Test (UUT)
    component FastCommandSynch
        Port ( fast_command : in STD_LOGIC_VECTOR (31 downto 0);
               pulse : out STD_LOGIC;
               fast_command_config : in STD_LOGIC_VECTOR (31 downto 0);
               clk : in STD_LOGIC;
               areset_n : in STD_LOGIC);
    end component;

    -- Signals to connect to the UUT
    signal fast_command : STD_LOGIC_VECTOR (31 downto 0) := (others => '0');
    signal pulse : STD_LOGIC;
    signal fast_command_config : STD_LOGIC_VECTOR (31 downto 0) := (others => '0');
    signal clk : STD_LOGIC := '0';
    signal areset_n : STD_LOGIC := '1';

    -- Clock period definition
    constant clk_period : time := 25 ns;

begin
    -- Instantiate the Unit Under Test (UUT)
    uut: FastCommandSynch Port Map (
        fast_command => fast_command,
        pulse => pulse,
        fast_command_config => fast_command_config,
        clk => clk,
        areset_n => areset_n
    );

    -- Clock process definitions
    clk_process :process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    -- Stimulus process
    stim_proc: process
    begin
        -- Hold reset active (low) for 20 ns
        areset_n <= '0';
        wait for 20 ns;
        areset_n <= '1';
        wait for 10 ns;
        
        -- Apply test vector: fast_command = 32'h00000001, fast_command_config = 32'h00000001
        fast_command <= x"00000001";--"00000000000000000000000000000001";
        fast_command_config <= x"00000002";
        wait for 50 ns;

        -- Apply test vector: fast_command = 32'h00000002, fast_command_config = 32'h00000001
        fast_command <= x"00000002";--"00000000000000000000000000000010";
        wait for 50 ns;

        -- Apply test vector: fast_command = 32'h00000001, fast_command_config = 32'h00000001
        fast_command <= x"00000001";--"00000000000000000000000000000001";
        wait for 50 ns;

        -- Apply test vector: fast_command = 32'hFFFFFFFF, fast_command_config = 32'h00000001
        fast_command <= x"FFFFFFFF";--"11111111111111111111111111111111";
        wait for 50 ns;

        -- Finish the test
        wait;
    end process;

end Behavioral;
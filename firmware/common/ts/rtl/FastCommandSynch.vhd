
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
           areset_n : in STD_LOGIC

           -- AXI-Lite Interface (axilClk domain)
           axilClk           : in    sl;
           axilRst           : in    sl;
           mAxilWriteMaster  : in    AxiLiteWriteMasterType;
           mAxilWriteSlave   : out   AxiLiteWriteSlaveType;
           mAxilReadMaster   : in    AxiLiteReadMasterType;
           mAxilReadSlave    : out   AxiLiteReadSlaveType;
           );

end FastCommandSynch;

architecture Behavioral of FastCommandSynch is

  signal command_buffer : STD_LOGIC_VECTOR (3 downto 0) := (others => '0');

  signal readReg  : slv32Array(0 downto 0) := (others => '0');
  -- (0) count of command seen
  signal writeReg : Slv32Array(2 downto 0) := (others => '0');
  -- (0) command configuration
  -- (1) delay
  -- (2) prescale
  
begin
  
  U_AxiLiteRegs : entity surf.AxiLiteRegs
      generic map (
         TPD_G           => TPD_G,
         NUM_WRITE_REG_G => 1,
         INI_WRITE_REG_G => INI_WRITE_REG_C,
         NUM_READ_REG_G  => 2)
      port map (
         -- AXI-Lite Bus
         axiClk          => axilClk,
         axiClkRst       => axilRst,
         axiReadMaster   => axilReadMasters(AXIL_VERSION_INDEX_C),
         axiReadSlave    => axilReadSlaves(AXIL_VERSION_INDEX_C),
         axiWriteMaster  => axilWriteMasters(AXIL_VERSION_INDEX_C),
         axiWriteSlave   => axilWriteSlaves(AXIL_VERSION_INDEX_C),
         -- User Read/Write registers
         writeRegister   => writeReg,
         readRegister    => readReg);
  
  process (clk, areset_n)
  begin
    if areset_n = '0' then
      pulse  <= '0';
      command_buffer <= (others => '0');
    elsif rising_edge(clk) then
      if command_buffer = writeReg(0)(3 downto 0) then
        pulse <= '1';
        command_buffer <= (others => '0');
      else
        command_buffer <= fast_command;
        pulse <= '0';                
      end if;
    end if;
  end process;

end Behavioral;

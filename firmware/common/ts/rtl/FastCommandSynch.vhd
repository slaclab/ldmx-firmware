
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.Numeric_Std.ALL;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;

entity FastCommandSynch is
  Generic( TPD_G : time := 1 ns);
  Port ( fast_command : in STD_LOGIC_VECTOR (3 downto 0);
           pulse : out STD_LOGIC;
           clk : in STD_LOGIC;
           areset_n : in STD_LOGIC;
           -- AXI-Lite Interface (axilClk domain)
           axilClk           : in    sl;
           axilRst           : in    sl;
           mAxilWriteMaster  : in    AxiLiteWriteMasterType;
           mAxilWriteSlave   : out   AxiLiteWriteSlaveType;
           mAxilReadMaster   : in    AxiLiteReadMasterType;
           mAxilReadSlave    : out   AxiLiteReadSlaveType
           );

end FastCommandSynch;

architecture Behavioral of FastCommandSynch is

  signal command_buffer : STD_LOGIC_VECTOR (3 downto 0) := (others => '0');

  signal readReg  : slv32Array(0 downto 0) := (others => x"0000_0000");
  -- (0) count of command seen
  constant INI_WRITE_REG_C : slv32Array(1 downto 0) := (others => x"0000_0000");
  signal writeReg : Slv32Array(1 downto 0) := (others => x"0000_0000");
  -- (0) command configuration
  -- (1) delay (not implemented)
  -- (2) prescale (not implemented)
  
begin
  
  U_AxiLiteRegs : entity surf.AxiLiteRegs
      generic map (
         TPD_G           => TPD_G,
         NUM_WRITE_REG_G => 2,
         INI_WRITE_REG_G => INI_WRITE_REG_C,
         NUM_READ_REG_G  => 1)
      port map (
         -- AXI-Lite Bus
         axiClk          => axilClk,
         axiClkRst       => axilRst,
         axiReadMaster   => mAxilReadMaster,
         axiReadSlave    => mAxilReadSlave,
         axiWriteMaster  => mAxilWriteMaster,
         axiWriteSlave   => mAxilWriteSlave,
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
        readReg(0) <= std_logic_vector(to_unsigned(to_integer(unsigned(readReg(0)))+1,readReg(0)'length));
      else
        command_buffer <= fast_command;
        pulse <= '0';                
      end if;
    end if;
  end process;

end Behavioral;

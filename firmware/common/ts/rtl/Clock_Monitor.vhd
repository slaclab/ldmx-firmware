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

library ldmx_ts;
use ldmx_ts.zCCM_Pkg.ALL;
library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;

entity Clock_Monitor is
    generic(
    TPD_G : time := 1 ns);
    Port ( 
        clk_con      : in  Clock_Control ;
        clk          : in STD_LOGIC;
        reset_n      : in STD_LOGIC;
        --Axil interface
        axilClk         : in  sl;
        axilRst         : in  sl;
        axilReadMaster  : in  AxiLiteReadMasterType;
        axilReadSlave   : out AxiLiteReadSlaveType;
        axilWriteMaster : in  AxiLiteWriteMasterType;
        axilWriteSlave  : out AxiLiteWriteSlaveType
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

  type RegType is record
    LOS_XAXB       : slv(7 downto 0); -- number of times LOS changes state
    LOL            : slv(7 downto 0); -- number of times LOL changes state
    axilReadSlave  : AxiLiteReadSlaveType;
    axilWriteSlave : AxiLiteWriteSlaveType;
  end record RegType;

  constant REG_INIT_C : RegType := (
    LOS_XAXB       => (others => '0'),
    LOL            => (others => '0'),
    axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
    axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C);

  signal r   : RegType := REG_INIT_C;
  signal rin : RegType;
  signal r_local : RegType := REG_INIT_C;
begin

   LOS_XAXB : Slow_Control_Monitor 
        Port Map(
                 d => clk_con.LOS_XAXB,
                 counter => r_local.LOS_XAXB,
                 clk => clk,
                 reset_n => reset_n
                 );

   LOL : Slow_Control_Monitor 
        Port Map(
                 d => clk_con.LOL,
                 counter => r_local.LOL,
                 clk => clk,
                 reset_n => reset_n
                 );

   comb : process (r_local, r, axilReadMaster, axilWriteMaster) is
     variable v      : RegType;
     variable axilEp : AxiLiteEndpointType;

   begin
     
     v := r;
     v.LOS_XAXB := r_local.LOS_XAXB;
     v.LOL      := r_local.LOL;
     -- AXI Lite registers
     axiSlaveWaitTxn(axilEp, axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave);
     
     axiSlaveRegisterR(axilEp, X"00", 0, v.LOS_XAXB);
     axiSlaveRegisterR(axilEp, X"04", 0, v.LOL);
     
     axiSlaveDefault(axilEp, v.axilWriteSlave, v.axilReadSlave, AXI_RESP_DECERR_C);
          
     axilReadSlave  <= r.axilReadSlave;
     axilWriteSlave <= r.axilWriteSlave;
     rin <= v;

   end process comb;
   
   seq : process (axilClk, axilRst) is

   begin

     if (axilRst = '1') then
       r <= REG_INIT_C after TPD_G;
     elsif (rising_edge(axilClk)) then
       r <= rin after TPD_G;
     end if;

   end process seq;  

end Behavioral;

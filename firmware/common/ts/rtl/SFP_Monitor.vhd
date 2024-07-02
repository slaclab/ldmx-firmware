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
library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;

entity SFP_Monitor is
  generic(
    TPD_G : time := 1 ns);
  Port ( 
        sfp_con      : in  SFP_Control ;
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

  type RegType is record
    RX_LOS         : slv(7 downto 0); -- number of times RX_LOS changes state
    TX_FAULT       : slv(7 downto 0); -- number of times TX_FAULT changes state
    MOD_ABS        : slv(7 downto 0); -- number of times MOD_ABS changes state
    axilReadSlave  : AxiLiteReadSlaveType;
    axilWriteSlave : AxiLiteWriteSlaveType;
  end record RegType;

  constant REG_INIT_C : RegType := (
    RX_LOS         => (others => '0'),
    TX_FAULT       => (others => '0'),
    MOD_ABS        => (others => '0'),
    axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
    axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C);

  signal r   : RegType := REG_INIT_C;
  signal rin : RegType;

begin

   RX_LOS : Slow_Control_Monitor 
        Port Map(
                 d => sfp_con.RX_LOS,
                 counter => r.RX_LOS,
                 clk => clk,
                 reset_n => reset_n
                 );

   TX_FAULT : Slow_Control_Monitor 
        Port Map(
                 d => sfp_con.TX_FAULT,
                 counter => r.TX_FAULT,
                 clk => clk,
                 reset_n => reset_n
                 );

   MOD_ABS : Slow_Control_Monitor 
        Port Map(
                 d => sfp_con.MOD_ABS,
                 counter => R.MOD_ABS,
                 clk => clk,
                 reset_n => reset_n
                 );

   comb : process (r, axilReadMaster, axilWriteMaster) is
     variable v      : RegType;
     variable axilEp : AxiLiteEndpointType;

   begin

     v := r;

     -- AXI Lite registers
     axiSlaveWaitTxn(axilEp, axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave);
     
     axiSlaveRegisterR(axilEp, X"00", 0, v.RX_LOS);
     axiSlaveRegisterR(axilEp, X"04", 0, v.TX_FAULT);
     axiSlaveRegisterR(axilEp, X"08", 0, v.MOD_ABS);
     
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


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package zCCM_Pkg is

    type I2C_Signals is record
        SDA      : STD_LOGIC;    
        SCL      : STD_LOGIC;        
    end record;
    
    constant I2C_Signal_Init_C : I2C_Signals :=(
      SDA => '0',
      SCL => '0'
      );

    -- RM control signals
    
    type RM_Control is record
      PGOOD : STD_LOGIC;
    end record;

    constant RM_Control_Init_C : RM_Control := (
      PGOOD => '0'
      );
    
    type RM_Control_Out is record
        PEN      : STD_LOGIC;
        RESET    : STD_LOGIC;
    end record;

    constant RM_Control_Out_Init_C : RM_Control_Out := (
      PEN => '0',
      RESET => '0'
      );

    -- Clock chip control signals

    type Clock_Control_Out is record 
      RST      : STD_LOGIC;
    end record;

    constant Clock_Control_Out_Init_C : Clock_Control_Out :=(
      RST => '0'
      );
    
    type Clock_Control is record
        INTR     : STD_LOGIC;
        LOS_XAXB : STD_LOGIC;
        LOL      : STD_LOGIC;
    end record;    
    
    constant Clock_Control_Init_C : Clock_Control := (
      INTR=> '0',
      LOS_XAXB=>'0',
      LOL=>'0'
      );

    -- SFP Control Signals

    type SFP_Control_Out is record
      TX_DIS : STD_LOGIC;
    end record;       

    constant SFP_Control_Out_Init_C : SFP_Control_Out := (
      TX_DIS => '0'
      );
    
    type SFP_Control is record
        RX_LOS   : STD_LOGIC;
        TX_FAULT : STD_LOGIC;
        MOD_ABS  : STD_LOGIC;
    end record;

    constant SFP_Control_Init_C : SFP_Control := (
      RX_LOS => '0',
      TX_FAULT => '0',
      MOD_ABS => '0'
      );

    -- SFP data signals
    
    type SFP_Data is record
        MGT_RX_P : STD_LOGIC;
        MGT_RX_N : STD_LOGIC;
    end record;

    constant SFP_Data_Init_C : SFP_Data := (
      MGT_RX_P => '0',
      MGT_RX_N => '0'
      );
    
    type SFP_Data_Out is record
        MGT_TX_P : STD_LOGIC;
        MGT_TX_N : STD_LOGIC;
    end record;

    constant SFP_Data_Out_Init_C : SFP_Data_Out := (
      MGT_TX_P => '0',
      MGT_TX_N => '0'
      );
    
end package zCCM_Pkg;

----------------------------------------------------------------------------------
-- Company: FNAL
-- Engineer: A. Whitbeck
-- 
-- Create Date: 05/30/2024 12:46:12 PM
-- Design Name: 
-- Module Name: top - Behavioral
-- Project Name: LDMX zCCM 
-- Target Devices: k26 on custom zCCM baseboard
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------



Library UNISIM;
use UNISIM.vcomponents.all;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library ldmx_ts;
use ldmx_ts.zCCM_Pkg.ALL;

entity zCCM_kria is
    Port (
          -- clock pins to RMs
          MCLK_BUF_SEL    : out    STD_LOGIC;
          MCLK_REF_P      : in  STD_LOGIC ;
          MCLK_REF_N      : in  STD_LOGIC ;
          MCLK_FROM_SOC_P : out    STD_LOGIC;
          MCLK_FROM_SOC_N : out    STD_LOGIC;
          BCR_FROM_SOC_P  : out    STD_LOGIC;
          BCR_FROM_SOC_N  : out    STD_LOGIC;
          LED_FROM_SOC_P  : out    STD_LOGIC;
          LED_FROM_SOC_N  : out    STD_LOGIC;
          
          -- clock pins to ASICs
          BEAMCLK_P               : out    STD_LOGIC;
          BEAMCLK_N               : out    STD_LOGIC;
          --CLKGEN_MGTCLK_AC_P      : in  STD_LOGIC;  -- for FC RX 
          --CLKGEN_MGTCLK_AC_N      : in  STD_LOGIC;  -- for FC RX
          CLKGEN_CLK0_TO_SOC_AC_P : in  STD_LOGIC;
          CLKGEN_CLK0_TO_SOC_AC_N : in  STD_LOGIC; 
          CLKGEN_CLK1_TO_SOC_AC_P : in  STD_LOGIC;
          CLKGEN_CLK1_TO_SOC_AC_N : in  STD_LOGIC;
          SOC_CLKREF_TO_CLKGEN_P  : out    STD_LOGIC;
          SOC_CLKREF_TO_CLKGEN_N  : out    STD_LOGIC;
          --MGTREFCLK1_AC_P         : in  STD_LOGIC; -- for FC TX
          --MGTREFCLK1_AC_N         : in  STD_LOGIC; -- for FC TX
          SYNTH_TO_SOC_AC_P       : in STD_LOGIC;
          SYNTH_TO_SOC_AC_N       : in STD_LOGIC;

          -- clock ASIC control
          Synth_Control  : in Clock_Control;
          Jitter_Control : in Clock_Control; 

          Synth_Control_out  : out Clock_Control_Out;
          Jitter_Control_out : out Clock_Control_Out; 
          
          Synth_i2c  : inout I2C_Signals;
          Jitter_i2c  : inout I2C_Signals;
          
          -- RM control signals 
          RM0_control    : in RM_Control;          
          RM1_control    : in RM_Control;          
          RM2_control    : in RM_Control;          
          RM3_control    : in RM_Control;          
          RM4_control    : in RM_Control;          
          RM5_control    : in RM_Control;

          RM0_control_out    : out RM_Control_Out;          
          RM1_control_out    : out RM_Control_Out;          
          RM2_control_out    : out RM_Control_Out;          
          RM3_control_out    : out RM_Control_Out;          
          RM4_control_out    : out RM_Control_Out;          
          RM5_control_out    : out RM_Control_Out;
          
          RM0_i2c : inout I2C_Signals;
          RM1_i2c : inout I2C_Signals;
          RM2_i2c : inout I2C_Signals;
          RM3_i2c : inout I2C_Signals;
          RM4_i2c : inout I2C_Signals;
          RM5_i2c : inout I2C_Signals;
          
          -- SFP data and control signals
          SFP0           : in SFP_Data;
          SFP0_control   : in SFP_Control;                             
          SFP1           : in SFP_Data;          
          SFP1_control   : in SFP_Control;                   
          SFP2           : in SFP_Data;          
          SFP2_control   : in SFP_Control;                   
          SFP3           : in SFP_Data;
          SFP3_control   : in SFP_Control;        

          SFP0_out           : out SFP_Data_Out;
          SFP0_control_out   : out SFP_Control_Out;                             
          SFP1_out           : out SFP_Data_Out;          
          SFP1_control_out   : out SFP_Control_Out;                   
          SFP2_out           : out SFP_Data_Out;          
          SFP2_control_out   : out SFP_Control_Out;                   
          SFP3_out           : out SFP_Data_Out;
          SFP3_control_out   : out SFP_Control_Out;        

          SFP0_i2c : inout I2C_Signals;
          SFP1_i2c : inout I2C_Signals;
          SFP2_i2c : inout I2C_Signals;
          SFP3_i2c : inout I2C_Signals;
              
          -- for simulation purposes only
          reset_n        : in STD_LOGIC                                                                
          );
end zCCM_kria;

architecture Behavioral of zCCM_kria is

    -- component definition for block diagram wrapper
    component project_1_wrapper
      port (
        fast_command_config_BCR_tri_o : out STD_LOGIC_VECTOR ( 31 downto 0 );
        fast_command_config_LED_tri_o : out STD_LOGIC_VECTOR ( 31 downto 0 );
        gpio_PLtoPS_rtl : in STD_LOGIC_VECTOR ( 31 downto 0 );
        gpio_PStoPL_rtl : out STD_LOGIC_VECTOR ( 31 downto 0 );
        gpio_rtl_CLK0_tri_i : in STD_LOGIC_VECTOR ( 15 downto 0 );
        gpio_rtl_CLK1_tri_i : in STD_LOGIC_VECTOR ( 15 downto 0 );
        gpio_rtl_RM0_tri_i : in STD_LOGIC_VECTOR ( 23 downto 0 );
        gpio_rtl_RM1_tri_i : in STD_LOGIC_VECTOR ( 23 downto 0 );
        gpio_rtl_SFP0_tri_i : in STD_LOGIC_VECTOR ( 23 downto 0 );
        gpio_rtl_SFP1_tri_i : in STD_LOGIC_VECTOR ( 23 downto 0 );
        gpio_rtl_SFP2_tri_i : in STD_LOGIC_VECTOR ( 23 downto 0 );
        gpio_rtl_SFP3_tri_i : in STD_LOGIC_VECTOR ( 23 downto 0 );
        iic_CLK0_rtl_scl_io : inout STD_LOGIC;
        iic_CLK0_rtl_sda_io : inout STD_LOGIC;
        iic_CLK1_rtl_scl_io : inout STD_LOGIC;
        iic_CLK1_rtl_sda_io : inout STD_LOGIC;
        iic_RM0_rtl_scl_io : inout STD_LOGIC;
        iic_RM0_rtl_sda_io : inout STD_LOGIC;
        iic_RM1_rtl_scl_io : inout STD_LOGIC;
        iic_RM1_rtl_sda_io : inout STD_LOGIC;
        iic_RM2_rtl_scl_io : inout STD_LOGIC;
        iic_RM2_rtl_sda_io : inout STD_LOGIC;
        iic_RM3_rtl_scl_io : inout STD_LOGIC;
        iic_RM3_rtl_sda_io : inout STD_LOGIC;
        iic_RM4_rtl_scl_io : inout STD_LOGIC;
        iic_RM4_rtl_sda_io : inout STD_LOGIC;
        iic_RM5_rtl_scl_io : inout STD_LOGIC;
        iic_RM5_rtl_sda_io : inout STD_LOGIC;
        iic_SFP0_rtl_scl_io : inout STD_LOGIC;
        iic_SFP0_rtl_sda_io : inout STD_LOGIC;
        iic_SFP1_rtl_scl_io : inout STD_LOGIC;
        iic_SFP1_rtl_sda_io : inout STD_LOGIC;
        iic_SFP2_rtl_scl_io : inout STD_LOGIC;
        iic_SFP2_rtl_sda_io : inout STD_LOGIC;
        iic_SFP3_rtl_scl_io : inout STD_LOGIC;
        iic_SFP3_rtl_sda_io : inout STD_LOGIC
        
      );
    end component;

    -- component definition for monitoring SFP bits
    component SFP_Monitor
        Port ( 
            sfp_con      : in  SFP_Control ;
            counter      : out STD_LOGIC_VECTOR (23 downto 0); 
            clk          : in STD_LOGIC;
            reset_n      : in STD_LOGIC
             );
    end component;

    -- component definition for monitoring Clock bits
    component Clock_Monitor is
        Port ( 
            clk_con      : in  Clock_Control ;
            counter      : out STD_LOGIC_VECTOR (15 downto 0); 
            clk          : in STD_LOGIC;
            reset_n      : in STD_LOGIC
             );
    end component;

    -- component definition for monitoring RM PGOOD
    component RM_Monitor is
        Port ( 
            rm_con      : in  RM_Control ;
            counter      : out STD_LOGIC_VECTOR (7 downto 0); 
            clk          : in STD_LOGIC;
            reset_n      : in STD_LOGIC
             );
    end component;

    -- component definition for a dummy FC block
    component Dummy_FC
        Port ( clk : in STD_LOGIC;
               reset_n : in STD_LOGIC;
               lcls_clk : out STD_LOGIC;
               fc_command : out STD_LOGIC_VECTOR (31 downto 0);
               command_valid : out STD_LOGIC);
    end component;

    -- component definition for fastcommandsynch; used to generate LED and BCR pulses

    component FastCommandSynch
        Port ( fast_command : in STD_LOGIC_VECTOR (31 downto 0);
               pulse : out STD_LOGIC;
               fast_command_config : in STD_LOGIC_VECTOR (31 downto 0);
               clk : in STD_LOGIC;
               areset_n : in STD_LOGIC);
    end component;
    
    -- top level signal definitions
    
    signal MCLK : STD_LOGIC := '0';
    signal pulse_BCR_rtl : STD_LOGIC := '0';
    signal pulse_LED_rtl : STD_LOGIC := '0';
    signal fast_command_config_BCR_tri_o : STD_LOGIC_VECTOR ( 31 downto 0 );
    signal fast_command_config_LED_tri_o : STD_LOGIC_VECTOR ( 31 downto 0 );
    signal fast_commands_rtl : STD_LOGIC_VECTOR (31 downto 0) := (others => '0');
    signal fast_commands_valid : STD_LOGIC := '0';
    signal gpio_PLtoPS_rtl : STD_LOGIC_VECTOR (31 downto 0) := (others => '0');
    signal gpio_PStoPL_rtl : STD_LOGIC_VECTOR (31 downto 0) := (others => '0');
    signal gpio_rtl_CLK0 : STD_LOGIC_VECTOR (15 downto 0) := (others => '0');
    signal gpio_rtl_CLK1 : STD_LOGIC_VECTOR (15 downto 0) := (others => '0');
    signal gpio_rtl_RM0 : STD_LOGIC_VECTOR (23 downto 0) := (others => '0');
    signal gpio_rtl_RM1 : STD_LOGIC_VECTOR (23 downto 0) := (others => '0');
    signal gpio_rtl_SFP0 : STD_LOGIC_VECTOR (23 downto 0) := (others => '0');
    signal gpio_rtl_SFP1 : STD_LOGIC_VECTOR (23 downto 0) := (others => '0');
    signal gpio_rtl_SFP2 : STD_LOGIC_VECTOR (23 downto 0) := (others => '0');
    signal gpio_rtl_SFP3  : STD_LOGIC_VECTOR (23 downto 0) := (others => '0');
    signal dummy_clock_output : STD_LOGIC := '0';    
    
begin
    
    
    synch_led :  FastCommandSynch
        Port Map ( 
           fast_command => fast_commands_rtl,
           pulse => pulse_LED_rtl,
           fast_command_config => x"0000000A",
           clk => SYNTH_TO_SOC_AC_P,
           areset_n => reset_n
           );
    
    synch_bcr :  FastCommandSynch
        Port Map ( 
           fast_command => fast_commands_rtl,
           pulse => pulse_BCR_rtl,
           fast_command_config => x"000000AA",
           clk => SYNTH_TO_SOC_AC_P,
           areset_n => reset_n
           );

    
    -- - - - - - - - - - - - - - - - - - - - - -
    -- all differential outputs
    -- - - - - - - - - - - - - - - - - - - - - -
    
    -- differential output buffer for LED to clock fanout
    LED_OBUFDS : OBUFDS
    port map (
      O  => LED_FROM_SOC_P,   -- 1-bit output: Diff_p output (connect directly to top-level port)
      OB => LED_FROM_SOC_N,   -- 1-bit output: Diff_n output (connect directly to top-level port)
      I  => pulse_LED_rtl     -- 1-bit input: Buffer input
    );
    
    -- differential output buffer for BCR to clock fanout
    BCR_OBUFDS : OBUFDS
    port map (
      O  => BCR_FROM_SOC_P,   -- 1-bit output: Diff_p output (connect directly to top-level port)
      OB => BCR_FROM_SOC_N,   -- 1-bit output: Diff_n output (connect directly to top-level port)
      I  => pulse_BCR_rtl     -- 1-bit input: Buffer input
    );
    
    -- differential output buffer for MCLK_FROM_SOC to clock fanout
    -- expected to be 37.142 MHz
    MCLK_FROM_SOC_OBUFDS : OBUFDS
    port map (
      O  => MCLK_FROM_SOC_P,   -- 1-bit output: Diff_p output (connect directly to top-level port)
      OB => MCLK_FROM_SOC_N,   -- 1-bit output: Diff_n output (connect directly to top-level port)
      I  => MCLK     -- 1-bit input: Buffer input
    );
    
    -- differential output buffer for BEAMCLK to ???
    -- expectd to be 37.142 MHz
    BEAMCLK_OBUFDS : OBUFDS
    port map (
      O  => BEAMCLK_P,   -- 1-bit output: Diff_p output (connect directly to top-level port)
      OB => BEAMCLK_N,   -- 1-bit output: Diff_n output (connect directly to top-level port)
      I  => MCLK     -- 1-bit input: Buffer input
    );
    
    -- differential output buffer for SOC_CLKREF_TO_CLKGEN to ???
    -- expected to be 37.142 MHz
    SOC_CLKREF_TO_CLKGEN_OBUFDS : OBUFDS
    port map (
      O  => SOC_CLKREF_TO_CLKGEN_P,   -- 1-bit output: Diff_p output (connect directly to top-level port)
      OB => SOC_CLKREF_TO_CLKGEN_N,   -- 1-bit output: Diff_n output (connect directly to top-level port)
      I  => MCLK     -- 1-bit input: Buffer input
    );
    
    
    -- - - - - - - - - - - - - - - - - - - - - -
    --component for FC
    -- - - - - - - - - - - - - - - - - - - - - -    
    Dummy_FC_comp : Dummy_FC
        Port Map(
               clk => SYNTH_TO_SOC_AC_P,
               reset_n => reset_n,
               lcls_clk => MCLK,
               fc_command => fast_commands_rtl, 
               command_valid => fast_commands_valid 
                );

    -- - - - - - - - - - - - - - - - - - - - - -
    -- components for managing state changes on SPFs
    -- - - - - - - - - - - - - - - - - - - - - -
    
    SFP0_mon : SFP_Monitor
        Port Map(
                sfp_con => SFP0_control,
                counter => gpio_rtl_SFP0,
                clk     => CLKGEN_CLK1_TO_SOC_AC_P,
                reset_n => reset_n
                );
    SFP1_mon : SFP_Monitor
        Port Map(
                sfp_con => SFP1_control,
                counter => gpio_rtl_SFP1,
                clk     => CLKGEN_CLK1_TO_SOC_AC_P,
                reset_n => reset_n
                );
    SFP2_mon : SFP_Monitor
        Port Map(
                sfp_con => SFP2_control,
                counter => gpio_rtl_SFP2,
                clk     => CLKGEN_CLK1_TO_SOC_AC_P,
                reset_n => reset_n
                );
    SFP3_mon : SFP_Monitor
        Port Map(
                sfp_con => SFP3_control,
                counter => gpio_rtl_SFP3,
                clk     => CLKGEN_CLK1_TO_SOC_AC_P,
                reset_n => reset_n
                );             

    -- - - - - - - - - - - - - - - - - - - - - -
    -- components for managing state changes on Clock chips
    -- - - - - - - - - - - - - - - - - - - - - -
    synth_mon : Clock_Monitor
        Port Map(
                clk_con => Synth_Control,
                counter => gpio_rtl_CLK0,
                clk     => CLKGEN_CLK1_TO_SOC_AC_P,
                reset_n => reset_n
                );    

    jitter_mon : Clock_Monitor
        Port Map(
                clk_con => Jitter_Control,
                counter => gpio_rtl_CLK1,
                clk     => CLKGEN_CLK1_TO_SOC_AC_P,
                reset_n => reset_n
                );
    -- - - - - - - - - - - - - - - - - - - - - -
    -- components for managing state changes on RMs
    -- - - - - - - - - - - - - - - - - - - - - -

    rm0_mon : RM_Monitor
        Port Map(
            rm_con => RM0_control,
            counter=> gpio_rtl_RM0(7 downto 0),
            clk    => CLKGEN_CLK1_TO_SOC_AC_P,
            reset_n=> reset_n
            );
            
    rm1_mon : RM_Monitor
        Port Map(
            rm_con => RM1_control,
            counter=> gpio_rtl_RM0(15 downto 8),
            clk    => CLKGEN_CLK1_TO_SOC_AC_P,
            reset_n=> reset_n
            );

    rm2_mon : RM_Monitor
        Port Map(
            rm_con => RM2_control,
            counter=> gpio_rtl_RM0(23 downto 16),
            clk    => CLKGEN_CLK1_TO_SOC_AC_P,
            reset_n=> reset_n
        );

    rm3_mon : RM_Monitor
        Port Map(
            rm_con => RM3_control,
            counter=> gpio_rtl_RM1(7 downto 0),
            clk    => CLKGEN_CLK1_TO_SOC_AC_P,
            reset_n=> reset_n
            );
            
    rm4_mon : RM_Monitor
        Port Map(
            rm_con => RM4_control,
            counter=> gpio_rtl_RM1(15 downto 8),
            clk    => CLKGEN_CLK1_TO_SOC_AC_P,
            reset_n=> reset_n
            );

    rm5_mon : RM_Monitor
        Port Map(
            rm_con => RM5_control,
            counter=> gpio_rtl_RM1(23 downto 16),
            clk    => CLKGEN_CLK1_TO_SOC_AC_P,
            reset_n=> reset_n
        );

    -- - - - - - - - - - - - - - - - - - - - - -
    -- Wrapper for block diagram, which contains
    -- zynqmp and axi peripheral blocks such as 
    -- gpio and i2c interfaces
    -- - - - - - - - - - - - - - - - - - - - - -
    
    BD : project_1_wrapper 
        Port Map(
                fast_command_config_BCR_tri_o => fast_command_config_BCR_tri_o,
                fast_command_config_LED_tri_o => fast_command_config_LED_tri_o,
                gpio_PLtoPS_rtl     => gpio_PLtoPS_rtl, 
                gpio_PStoPL_rtl     => gpio_PStoPL_rtl,
                gpio_rtl_CLK0_tri_i => gpio_rtl_CLK0,
                gpio_rtl_CLK1_tri_i => gpio_rtl_CLK1,
                gpio_rtl_RM0_tri_i  => gpio_rtl_RM0,
                gpio_rtl_RM1_tri_i  => gpio_rtl_RM1,
                gpio_rtl_SFP0_tri_i => gpio_rtl_SFP0,
                gpio_rtl_SFP1_tri_i => gpio_rtl_SFP1,
                gpio_rtl_SFP2_tri_i => gpio_rtl_SFP2,
                gpio_rtl_SFP3_tri_i => gpio_rtl_SFP3,
                iic_CLK0_rtl_scl_io => Synth_i2c.SCL,
                iic_CLK0_rtl_sda_io => Synth_i2c.SDA,
                iic_CLK1_rtl_scl_io => Jitter_i2c.SCL,
                iic_CLK1_rtl_sda_io => Jitter_i2c.SDA,
                iic_RM0_rtl_scl_io  => RM0_i2c.SCL,
                iic_RM0_rtl_sda_io  => RM0_i2c.SDA,
                iic_RM1_rtl_scl_io  => RM1_i2c.SCL,
                iic_RM1_rtl_sda_io  => RM1_i2c.SDA,
                iic_RM2_rtl_scl_io  => RM2_i2c.SCL,
                iic_RM2_rtl_sda_io  => RM2_i2c.SDA,
                iic_RM3_rtl_scl_io  => RM3_i2c.SCL,
                iic_RM3_rtl_sda_io  => RM3_i2c.SDA,
                iic_RM4_rtl_scl_io  => RM4_i2c.SCL,
                iic_RM4_rtl_sda_io  => RM4_i2c.SDA,
                iic_RM5_rtl_scl_io  => RM5_i2c.SCL,
                iic_RM5_rtl_sda_io  => RM5_i2c.SDA,
                iic_SFP0_rtl_scl_io => SFP0_i2c.SCL,
                iic_SFP0_rtl_sda_io => SFP0_i2c.SDA,
                iic_SFP1_rtl_scl_io => SFP1_i2c.SCL,
                iic_SFP1_rtl_sda_io => SFP1_i2c.SDA,
                iic_SFP2_rtl_scl_io => SFP2_i2c.SCL,
                iic_SFP2_rtl_sda_io => SFP2_i2c.SDA,
                iic_SFP3_rtl_scl_io => SFP3_i2c.SCL,
                iic_SFP3_rtl_sda_io => SFP3_i2c.SDA
                );
    
    MCLK_BUF_SEL <= '1';    
    
    RM0_control_out.PEN    <=  gpio_PStoPL_rtl(0);
    RM0_control_out.RESET  <=  gpio_PStoPL_rtl(1);
    RM1_control_out.PEN    <=  gpio_PStoPL_rtl(2);
    RM1_control_out.RESET  <=  gpio_PStoPL_rtl(3);
    RM2_control_out.PEN    <=  gpio_PStoPL_rtl(4);
    RM2_control_out.RESET  <=  gpio_PStoPL_rtl(5);
    RM3_control_out.PEN    <=  gpio_PStoPL_rtl(6);
    RM3_control_out.RESET  <=  gpio_PStoPL_rtl(7);
    RM4_control_out.PEN    <=  gpio_PStoPL_rtl(8);
    RM4_control_out.RESET  <=  gpio_PStoPL_rtl(9);
    RM5_control_out.PEN    <=  gpio_PStoPL_rtl(10);
    RM5_control_out.RESET  <=  gpio_PStoPL_rtl(11);
        
    Synth_Control_out.RST <=  gpio_PStoPL_rtl(12);
    
    Jitter_Control_out.RST <=  gpio_PStoPL_rtl(13);
    
    SFP0_control_out.TX_DIS   <= gpio_PStoPL_rtl(14);

    SFP1_control_out.TX_DIS   <= gpio_PStoPL_rtl(15);

    SFP2_control_out.TX_DIS   <= gpio_PStoPL_rtl(16);

    SFP3_control_out.TX_DIS   <= gpio_PStoPL_rtl(17);
        
end Behavioral;


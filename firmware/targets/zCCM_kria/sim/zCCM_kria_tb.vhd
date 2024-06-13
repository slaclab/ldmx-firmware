library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.zCCM_Pkg.ALL;

entity zCCM_kria_tb is
end zCCM_kria_tb;

architecture Behavioral of zCCM_kria_tb is

    -- Component declaration for the unit under test (UUT)
    component zCCM_kria
        Port (
            MCLK_BUF_SEL : out STD_LOGIC;
            MCLK_REF_P : inout STD_LOGIC;
            MCLK_REF_N : inout STD_LOGIC;
            MCLK_FROM_SOC_P : out STD_LOGIC;
            MCLK_FROM_SOC_N : out STD_LOGIC;
            BCR_FROM_SOC_P : out STD_LOGIC;
            BCR_FROM_SOC_N : out STD_LOGIC;
            LED_FROM_SOC_P : out STD_LOGIC;
            LED_FROM_SOC_N : out STD_LOGIC;
            BEAMCLK_P : out STD_LOGIC;
            BEAMCLK_N : out STD_LOGIC;
            CLKGEN_CLK0_TO_SOC_AC_P : inout STD_LOGIC;
            CLKGEN_CLK0_TO_SOC_AC_N : inout STD_LOGIC;
            CLKGEN_CLK1_TO_SOC_AC_P : inout STD_LOGIC;
            CLKGEN_CLK1_TO_SOC_AC_N : inout STD_LOGIC;
            SOC_CLKREF_TO_CLKGEN_P : out STD_LOGIC;
            SOC_CLKREF_TO_CLKGEN_N : out STD_LOGIC;
            SYNTH_TO_SOC_AC_P : inout STD_LOGIC;
            SYNTH_TO_SOC_AC_N : inout STD_LOGIC;
            Synth_Control  : in Clock_Control;
            Jitter_Control : in Clock_Control; 
            Synth_Control_out  : out Clock_Control_Out;
            Jitter_Control_out : out Clock_Control_Out;          
            Synth_i2c  : inout I2C_Signals;
            Jitter_i2c  : inout I2C_Signals;
            
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
                        
            reset_n : in STD_LOGIC
        );
    end component;

    -- Signal declarations
    signal MCLK_BUF_SEL : STD_LOGIC;
    signal MCLK_REF_P : STD_LOGIC := '0';
    signal MCLK_REF_N : STD_LOGIC := '1';
    signal MCLK_FROM_SOC_P : STD_LOGIC;
    signal MCLK_FROM_SOC_N : STD_LOGIC;
    signal BCR_FROM_SOC_P : STD_LOGIC;
    signal BCR_FROM_SOC_N : STD_LOGIC;
    signal LED_FROM_SOC_P : STD_LOGIC;
    signal LED_FROM_SOC_N : STD_LOGIC;
    signal BEAMCLK_P : STD_LOGIC;
    signal BEAMCLK_N : STD_LOGIC;
    signal CLKGEN_CLK0_TO_SOC_AC_P : STD_LOGIC := '0';
    signal CLKGEN_CLK0_TO_SOC_AC_N : STD_LOGIC := '1';
    signal CLKGEN_CLK1_TO_SOC_AC_P : STD_LOGIC := '0';
    signal CLKGEN_CLK1_TO_SOC_AC_N : STD_LOGIC := '1';
    signal SOC_CLKREF_TO_CLKGEN_P : STD_LOGIC ;
    signal SOC_CLKREF_TO_CLKGEN_N : STD_LOGIC;
    signal SYNTH_TO_SOC_AC_P : STD_LOGIC := '0';
    signal SYNTH_TO_SOC_AC_N : STD_LOGIC := '1';

    signal        Synth_Control  : Clock_Control := Clock_Control_Init_C;
    signal        Jitter_Control :  Clock_Control:= Clock_Control_Init_C; 
    signal        Synth_Control_out  :  Clock_Control_Out:= Clock_Control_Out_Init_C;
    signal        Jitter_Control_out :  Clock_Control_Out:= Clock_Control_Out_Init_C;          
    signal        Synth_i2c  :  I2C_Signals := I2C_Signal_Init_C;
    signal        Jitter_i2c  :  I2C_Signals := I2C_Signal_Init_C;
            
     signal       RM0_control    :  RM_Control := RM_Control_Init_C;          
     signal       RM1_control    :  RM_Control := RM_Control_Init_C;          
     signal       RM2_control    :  RM_Control := RM_Control_Init_C;          
     signal       RM3_control    :  RM_Control := RM_Control_Init_C;          
     signal       RM4_control    :  RM_Control := RM_Control_Init_C;          
     signal       RM5_control    :  RM_Control := RM_Control_Init_C;

     signal       RM0_control_out    :  RM_Control_Out := RM_Control_Out_Init_C;          
     signal       RM1_control_out    :  RM_Control_Out := RM_Control_Out_Init_C;
     signal       RM2_control_out    :  RM_Control_Out := RM_Control_Out_Init_C;          
     signal       RM3_control_out    :  RM_Control_Out := RM_Control_Out_Init_C;          
     signal       RM4_control_out    :  RM_Control_Out := RM_Control_Out_Init_C;          
     signal       RM5_control_out    :  RM_Control_Out := RM_Control_Out_Init_C;
          
     signal       RM0_i2c :  I2C_Signals:= I2C_Signal_Init_C;
     signal       RM1_i2c :  I2C_Signals:= I2C_Signal_Init_C;
     signal       RM2_i2c :  I2C_Signals:= I2C_Signal_Init_C;
     signal       RM3_i2c :  I2C_Signals:= I2C_Signal_Init_C;
     signal       RM4_i2c :  I2C_Signals:= I2C_Signal_Init_C;
     signal       RM5_i2c :  I2C_Signals:= I2C_Signal_Init_C;
            
     signal       SFP0           :  SFP_Data := SFP_Data_Init_C;
     signal       SFP0_control   :  SFP_Control := SFP_Control_Init_C;                             
     signal       SFP1           :  SFP_Data := SFP_Data_Init_C;          
     signal       SFP1_control   :  SFP_Control := SFP_Control_Init_C;                   
     signal       SFP2           :  SFP_Data := SFP_Data_Init_C;          
     signal       SFP2_control   :  SFP_Control := SFP_Control_Init_C;                   
     signal       SFP3           :  SFP_Data := SFP_Data_Init_C;
     signal       SFP3_control   :  SFP_Control := SFP_Control_Init_C;        

     signal       SFP0_out           :  SFP_Data_Out := SFP_Data_Out_Init_C;
     signal       SFP0_control_out   :  SFP_Control_Out := SFP_Control_Out_Init_C;                             
     signal       SFP1_out           :  SFP_Data_Out := SFP_Data_Out_Init_C;          
     signal       SFP1_control_out   :  SFP_Control_Out := SFP_Control_Out_Init_C;                   
     signal       SFP2_out           :  SFP_Data_Out := SFP_Data_Out_Init_C;          
     signal       SFP2_control_out   :  SFP_Control_Out := SFP_Control_Out_Init_C;                   
     signal       SFP3_out           :  SFP_Data_Out := SFP_Data_Out_Init_C;
     signal       SFP3_control_out   :  SFP_Control_Out := SFP_Control_Out_Init_C;        

     signal       SFP0_i2c :  I2C_Signals:= I2C_Signal_Init_C;
     signal       SFP1_i2c :  I2C_Signals:= I2C_Signal_Init_C;
     signal       SFP2_i2c :  I2C_Signals:= I2C_Signal_Init_C;
      signal      SFP3_i2c :  I2C_Signals:= I2C_Signal_Init_C;
      
    signal reset_n : STD_LOGIC := '1';

begin

    -- Instantiate the Unit Under Test (UUT)
    uut: zCCM_kria
        Port map (
            MCLK_BUF_SEL => MCLK_BUF_SEL,
            MCLK_REF_P => MCLK_REF_P,
            MCLK_REF_N => MCLK_REF_N,
            MCLK_FROM_SOC_P => MCLK_FROM_SOC_P,
            MCLK_FROM_SOC_N => MCLK_FROM_SOC_N,
            BCR_FROM_SOC_P => BCR_FROM_SOC_P,
            BCR_FROM_SOC_N => BCR_FROM_SOC_N,
            LED_FROM_SOC_P => LED_FROM_SOC_P,
            LED_FROM_SOC_N => LED_FROM_SOC_N,
            BEAMCLK_P => BEAMCLK_P,
            BEAMCLK_N => BEAMCLK_N,
            CLKGEN_CLK0_TO_SOC_AC_P => CLKGEN_CLK0_TO_SOC_AC_P,
            CLKGEN_CLK0_TO_SOC_AC_N => CLKGEN_CLK0_TO_SOC_AC_N,
            CLKGEN_CLK1_TO_SOC_AC_P => CLKGEN_CLK1_TO_SOC_AC_P,
            CLKGEN_CLK1_TO_SOC_AC_N => CLKGEN_CLK1_TO_SOC_AC_N,
            SOC_CLKREF_TO_CLKGEN_P => SOC_CLKREF_TO_CLKGEN_P,
            SOC_CLKREF_TO_CLKGEN_N => SOC_CLKREF_TO_CLKGEN_N,
            SYNTH_TO_SOC_AC_P => SYNTH_TO_SOC_AC_P,
            SYNTH_TO_SOC_AC_N => SYNTH_TO_SOC_AC_N,
            Synth_Control  => Synth_Control,
            Jitter_Control => Jitter_Control,
            Synth_Control_out => Synth_Control_out,
            Jitter_Control_out => Jitter_Control_out,           
            Synth_i2c => Synth_i2c,
            Jitter_i2c => Jitter_i2c,
            
            RM0_control => RM0_control,          
            RM1_control => RM1_control,             
            RM2_control => RM2_control,             
            RM3_control => RM3_control,             
            RM4_control => RM4_control,             
            RM5_control => RM5_control,   

            RM0_control_out => RM0_control_out,          
            RM1_control_out => RM1_control_out,          
            RM2_control_out => RM2_control_out,          
            RM3_control_out => RM3_control_out,          
            RM4_control_out => RM4_control_out,          
            RM5_control_out => RM5_control_out,
          
            RM0_i2c => RM0_i2c,  
            RM1_i2c => RM1_i2c, 
            RM2_i2c => RM2_i2c,
            RM3_i2c => RM3_i2c,
            RM4_i2c => RM4_i2c,
            RM5_i2c => RM5_i2c,
            
            SFP0        =>SFP0        ,    
            SFP0_control=>SFP0_control,                               
            SFP1        =>SFP1        ,        
            SFP1_control=>SFP1_control,                   
            SFP2        =>SFP2        ,      
            SFP2_control=>SFP2_control,                 
            SFP3        =>SFP3        ,
            SFP3_control=>SFP3_control,       

            SFP0_out        =>SFP0_out        ,
            SFP0_control_out=>SFP0_control_out,                             
            SFP1_out        =>SFP1_out        ,       
            SFP1_control_out=>SFP1_control_out,                   
            SFP2_out        =>SFP2_out        ,       
            SFP2_control_out=>SFP2_control_out,                   
            SFP3_out        =>SFP3_out        , 
            SFP3_control_out=>SFP3_control_out,        

            SFP0_i2c =>SFP0_i2c, 
            SFP1_i2c =>SFP1_i2c, 
            SFP2_i2c =>SFP2_i2c, 
            SFP3_i2c =>SFP3_i2c, 
            
            reset_n => reset_n
        );

    SYNTH_TO_SOC_AC_N <= not SYNTH_TO_SOC_AC_P;
    MCLK_REF_N <= not MCLK_REF_P;
    CLKGEN_CLK0_TO_SOC_AC_N <= not CLKGEN_CLK0_TO_SOC_AC_P;
    CLKGEN_CLK1_TO_SOC_AC_N <= not CLKGEN_CLK1_TO_SOC_AC_P;
    
    
    
    
    
    -- toggle SFP0 signals
    SFP0_control_stim : process
        variable temp : STD_LOGIC_VECTOR(2 downto 0) := "001";
    begin
        if temp = "100" then 
            temp := "001";
        else 
            temp := temp(1 downto 0) & '0';
        end if;
        SFP0_control.RX_LOS <= temp(0);
        SFP0_control.TX_FAULT <= temp(1);
        SFP0_control.MOD_ABS <= temp(2);
        wait for 50 ns;  
    end process;  
    
    -- toggle SFP1 signals
    SFP1_control_stim : process
        variable temp : STD_LOGIC_VECTOR(2 downto 0) := "001";
    begin
        if temp = "100" then 
            temp := "001";
        else 
            temp := temp(1 downto 0) & '0';
        end if;
        SFP1_control.RX_LOS <= temp(0);
        SFP1_control.TX_FAULT <= temp(1);
        SFP1_control.MOD_ABS <= temp(2);
        wait for 50 ns;  
    end process;  
    
    -- toggle SFP2 signals
    SFP2_control_stim : process
        variable temp : STD_LOGIC_VECTOR(2 downto 0) := "001";
    begin
        if temp = "100" then 
            temp := "001";
        else 
            temp := temp(1 downto 0) & '0';
        end if;
        SFP2_control.RX_LOS <= temp(0);
        SFP2_control.TX_FAULT <= temp(1);
        SFP2_control.MOD_ABS <= temp(2);
        wait for 50 ns;  
    end process;  
    
    -- toggle SFP3 signals
    SFP3_control_stim : process
        variable temp : STD_LOGIC_VECTOR(2 downto 0) := "001";
    begin
        if temp = "100" then 
            temp := "001";
        else 
            temp := temp(1 downto 0) & '0';
        end if;
        SFP3_control.RX_LOS <= temp(0);
        SFP3_control.TX_FAULT <= temp(1);
        SFP3_control.MOD_ABS <= temp(2);
        wait for 50 ns;  
    end process;  
    
    -- toggle RM0 signals
    RM0_control_stim : process
    begin
        RM0_control.PGOOD <= '1';
        wait for 50 ns;  
        RM0_control.PGOOD <= '0';
        wait for 50 ns;          
    end process;  

    -- toggle RM1 signals
    RM1_control_stim : process
    begin
        RM1_control.PGOOD <= '1';
        wait for 50 ns;  
        RM1_control.PGOOD <= '0';
        wait for 50 ns;          
    end process;  

    -- toggle RM2 signals
    RM2_control_stim : process
    begin
        RM2_control.PGOOD <= '1';
        wait for 50 ns;  
        RM2_control.PGOOD <= '0';
        wait for 50 ns;          
    end process;  

    -- toggle RM3 signals
    RM3_control_stim : process
    begin
        RM3_control.PGOOD <= '1';
        wait for 50 ns;  
        RM3_control.PGOOD <= '0';
        wait for 50 ns;          
    end process;  

    -- toggle RM4 signals
    RM4_control_stim : process
    begin
        RM4_control.PGOOD <= '1';
        wait for 50 ns;  
        RM4_control.PGOOD <= '0';
        wait for 50 ns;          
    end process;  

    -- toggle RM5 signals
    RM5_control_stim : process
    begin
        RM5_control.PGOOD <= '1';
        wait for 50 ns;  
        RM5_control.PGOOD <= '0';
        wait for 50 ns;          
    end process;  

    -- toggle jitter cleaner signals
    jitter_control_stim : process
        variable temp : STD_LOGIC_VECTOR(1 downto 0) := "01";
    begin
        if temp = "10" then 
            temp := "01";
        else 
            temp := temp(0) & '0';
        end if;
        Jitter_Control.LOS_XAXB <= temp(0);
        Jitter_Control.LOL <= temp(1);
        wait for 50 ns;          
    end process;  

    -- toggle synth cleaner signals
    synth_control_stim : process
        variable temp : STD_LOGIC_VECTOR(1 downto 0) := "01";
    begin
        if temp = "10" then 
            temp := "01";
        else 
            temp := temp(0) & '0';
        end if;
        Synth_Control.LOS_XAXB <= temp(0);
        Synth_Control.LOL <= temp(1);
        wait for 50 ns;          
    end process;  
    
    -- clock
    clock : process 
    begin
        SYNTH_TO_SOC_AC_P <= not SYNTH_TO_SOC_AC_P;
        MCLK_REF_P <= not MCLK_REF_P;
        wait for 18 ns;

    end process;
    
    clock100 : process 
    begin
        CLKGEN_CLK0_TO_SOC_AC_P <= not CLKGEN_CLK0_TO_SOC_AC_P;
        CLKGEN_CLK1_TO_SOC_AC_P <= not CLKGEN_CLK1_TO_SOC_AC_P;
        wait for 5 ns;
    end process;
    
    
    -- Stimulus process
    stim_proc: process
    begin            
   
--        SFP0_control <= SFP_Control_Init_C;
--        SFP1_control <= SFP_Control_Init_C;
--        SFP2_control <= SFP_Control_Init_C;
--        SFP3_control <= SFP_Control_Init_C;

--        SFP0 <= SFP_Data_Init_C;
--        SFP2 <= SFP_Data_Init_C;
--        SFP3 <= SFP_Data_Init_C;

--        RM1_control <= RM_Control_Init_C;
--        RM2_control <= RM_Control_Init_C;
--        RM3_control <= RM_Control_Init_C;
--        RM0_control <= RM_Control_Init_C;

        --Jitter_Control <= Clock_Control_Init_C;
        --Synth_Control <= Clock_Control_Init_C;
        
        -- Initialize Inputs               
        reset_n <= '1';
        wait for 10 ns; 
        reset_n <= '0';
        wait for 50 ns;
        reset_n <= '1';

        -- Wait 100 ns for global reset to finish
        wait for 200 ns;

        -- Add stimulus here
        wait for 100 ns;

        -- Further stimulus can be added here as needed
        wait;
    end process;

end Behavioral;

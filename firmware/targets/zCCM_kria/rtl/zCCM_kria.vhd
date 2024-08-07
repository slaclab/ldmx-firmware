----------------------------------------------------------------------------------
-- Company: FNAL
-- Author: A. Whitbeck
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

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
use surf.Pgp2FcPkg.all;
use surf.I2cPkg.all;

library ldmx_tdaq;
use ldmx_tdaq.FcPkg.all;

library axi_soc_ultra_plus_core;
use axi_soc_ultra_plus_core.AxiSocUltraPlusPkg.all;

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
          CLKGEN_MGTCLK_AC_P      : in  STD_LOGIC;  -- for FC RX 
          CLKGEN_MGTCLK_AC_N      : in  STD_LOGIC;  -- for FC RX
          CLKGEN_CLK0_TO_SOC_AC_P : in  STD_LOGIC;
          CLKGEN_CLK0_TO_SOC_AC_N : in  STD_LOGIC; 
          CLKGEN_CLK1_TO_SOC_AC_P : in  STD_LOGIC;
          CLKGEN_CLK1_TO_SOC_AC_N : in  STD_LOGIC;
          SOC_CLKREF_TO_CLKGEN_P  : out    STD_LOGIC;
          SOC_CLKREF_TO_CLKGEN_N  : out    STD_LOGIC;
          MGTREFCLK1_AC_P         : in  STD_LOGIC; -- for FC TX
          MGTREFCLK1_AC_N         : in  STD_LOGIC; -- for FC TX
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
          );
end zCCM_kria;

architecture Behavioral of zCCM_kria is

   signal dmaClk       : sl;
   signal dmaRst       : sl;
   signal dmaObMasters : AxiStreamMasterArray(0 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal dmaObSlaves  : AxiStreamSlaveArray(0 downto 0)  := (others => AXI_STREAM_SLAVE_FORCE_C);
   signal dmaIbMasters : AxiStreamMasterArray(0 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal dmaIbSlaves  : AxiStreamSlaveArray(0 downto 0)  := (others => AXI_STREAM_SLAVE_FORCE_C);

   signal axilClk           : sl;
   signal axilRst           : sl;
   signal mAxilReadMasters  : AxiLiteReadMasterArray(0 downto 0);
   signal mAxilReadSlaves   : AxiLiteReadSlaveArray(0 downto 0)  := (others => AXI_LITE_READ_SLAVE_EMPTY_DECERR_C);
   signal mAxilWriteMasters : AxiLiteWriteMasterArray(0 downto 0);
   signal mAxilWriteSlaves  : AxiLiteWriteSlaveArray(0 downto 0) := (others => AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);

   signal vPin : sl;
   signal vNin: sl;
   
begin

    U_Core : entity axi_soc_ultra_plus_core.AxiSocUltraPlusCore
      generic map (
         TPD_G             => TPD_G,
         BUILD_INFO_G      => BUILD_INFO_G,
         EXT_AXIL_MASTER_G => false,
         DMA_SIZE_G        => 1)
      port map (
         ------------------------
         --  Top Level Interfaces
         ------------------------
         -- DSP Clock and Reset Monitoring
         dspClk         => '0',
         dspRst         => '0',
         -- AUX Clock and Reset
         auxClk         => axilClk,     -- 100 MHz
         auxRst         => axilRst,
         -- DMA Interfaces  (dmaClk domain)
         dmaClk         => dmaClk,      -- 250 MHz
         dmaRst         => dmaRst,
         dmaObMasters   => dmaObMasters,
         dmaObSlaves    => dmaObSlaves,
         dmaIbMasters   => dmaIbMasters,
         dmaIbSlaves    => dmaIbSlaves,
         -- Application AXI-Lite Interfaces [0x80000000:0xFFFFFFFF] (appClk domain)
         appClk         => axilClk,
         appRst         => axilRst,
         appReadMaster  => mAxilReadMasters(0),
         appReadSlave   => mAxilReadSlaves(0),
         appWriteMaster => mAxilWriteMasters(0),
         appWriteSlave  => mAxilWriteSlaves(0),
         -- PMU Ports
         fanEnableL     => fanEnableL,
         -- SYSMON Ports
         vPIn           => vPIn,
         vNIn           => vNIn);

   --------------
   -- Application
   --------------
   U_App : entity ldmx_ts.zccmApplication
      generic map (
         TPD_G            => TPD_G,
         AXIL_CLK_FREQ_G  => 100.0E+6, -- 100MHz
         AXIL_BASE_ADDR_G => APP_ADDR_OFFSET_C)
      port map (
        -- i2c
        RM0_i2c           => RM0_i2c,
        RM1_i2c           => RM1_i2c,
        RM2_i2c           => RM2_i2c,
        RM3_i2c           => RM3_i2c,
        Synth_i2c         => Synth_i2c,
        Jitter_i2c        => Jitter_i2c,
        SFP0_i2c          => SFP0_i2c,
        SFP1_i2c          => SFP1_i2c,
        SFP2_i2c          => SFP2_i2c,
        SFP3_i2c          => SFP3_i2c,
        -- control signals
        RM0_control       => RM0_control,
        RM1_control       => RM1_control,
        RM2_control       => RM2_control,
        RM3_control       => RM3_control,
        RM4_control       => RM4_control,
        RM5_control       => RM5_control,
        
        RM0_control_out   => RM0_control_out,
        RM1_control_out   => RM1_control_out,
        RM2_control_out   => RM2_control_out,
        RM3_control_out   => RM3_control_out,
        RM4_control_out   => RM4_control_out,
        RM5_control_out   => RM5_control_out,

        SFP0_control       => SFP0_control,
        SFP1_control       => SFP1_control,
        SFP2_control       => SFP2_control,
        SFP3_control       => SFP3_control,

        SFP0_control_out   => SFP0_control_out,
        SFP1_control_out   => SFP1_control_out,
        SFP2_control_out   => SFP2_control_out,
        SFP3_control_out   => SFP3_control_out,

        Synth_control      => Synth_Control,
        Jitter_control     => Jitter_control,
        
        Synth_control_out  => Synth_Control_out,
        Jitter_control_out => Jitter_Control_out,

        -- Clocks
        appClk            => axiClk,
        appRes            => axiRes,
        MCLK              => MCLK,
        MGTREFCLK0_P      => CLKGEN_MGTCLK_AC_P,
        MGTREFCLK0_N      => CLKGEN_MGTCLK_AC_N,        
        MGTREFCLK1_P      => MGTREFCLK1_AC_P,
        MGTREFCLK1_N      => MGTREFCLK1_AC_N,

        -- Fast control signals
        pulse_BCR_rtl     => pulse_BCR_rtl
        pulse_LED_rtl     => pulse_LED_rtl,

        -- SFP signals
        SFP_TX_P          => SFP0_out.MGT_TX_P,
        SFP_TX_N          => SFP0_out.MGT_TX_N,
        SFP_RX_P          => SFP0_out.MGT_RX_P,
        SFP_RX_N          => SFP0_out.MGT_RX_N,

        -- AXI-Lite Interface (axilClk domain)
        axilClk           => axilClk,
        axilRst           => axilRst,
        mAxilWriteMasters => mAxilWriteMasters,
        mAxilWriteSlaves  => mAxilWriteSlaves,
        mAxilReadMasters  => mAxilReadMasters,
        mAxilReadSlaves   => mAxilReadSlaves);

    
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

    MCLK_BUF_SEL <= '1';
    
end Behavioral;


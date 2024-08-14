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

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
use surf.Pgp2FcPkg.all;
use surf.I2cPkg.all;

library axi_soc_ultra_plus_core;
use axi_soc_ultra_plus_core.AxiSocUltraPlusPkg.all;

library ldmx_tdaq;
use ldmx_tdaq.FcPkg.all;

library ldmx_ts;
use ldmx_ts.zCCM_Pkg.ALL;


entity zCCM_kria is
   generic (
      TPD_G : time := 0.5 ns;
      SIMULATION_G : boolean := false;
      BUILD_INFO_G : BuildInfoType);
    Port (
          -- clock pins to RMs
          MCLK_BUF_SEL    : out    sl;
          MCLK_REF_P      : in     sl;
          MCLK_REF_N      : in     sl;
          MCLK_FROM_SOC_P : out    sl;
          MCLK_FROM_SOC_N : out    sl;
          BCR_FROM_SOC_P  : out    sl;
          BCR_FROM_SOC_N  : out    sl;
          LED_FROM_SOC_P  : out    sl;
          LED_FROM_SOC_N  : out    sl;
          
          -- clock pins to ASICs
          BEAMCLK_P               : out sl;
          BEAMCLK_N               : out sl;
          CLKGEN_MGTCLK_AC_P      : in  sl;  -- for FC RX 
          CLKGEN_MGTCLK_AC_N      : in  sl;  -- for FC RX
          CLKGEN_CLK0_TO_SOC_AC_P : in  sl;
          CLKGEN_CLK0_TO_SOC_AC_N : in  sl; 
          SOC_CLKREF_TO_CLKGEN_P  : out sl;
          SOC_CLKREF_TO_CLKGEN_N  : out sl;
          MGTREFCLK1_AC_P         : in  sl; -- for FC TX
          MGTREFCLK1_AC_N         : in  sl; -- for FC TX
          SYNTH_TO_SOC_AC_P       : in  sl;
          SYNTH_TO_SOC_AC_N       : in  sl;

          -- clock ASIC control
          Synth_Control_INTR      : in  sl;
          Synth_Control_LOS_XAXB  : in  sl;
          Synth_Control_LOL       : in  sl;
          Synth_Control_RST       : out sl;
          Jitter_Control_INTR     : in  sl;
          Jitter_Control_LOS_XAXB : in  sl;
          Jitter_Control_LOL      : in  sl;
          Jitter_Control_RST      : out sl;
          
          Synth_i2c_SCL  : inout sl;
          Synth_i2c_SDA  : inout sl;   
          Jitter_i2c_SCL  : inout sl;
          Jitter_i2c_SDA  : inout sl;  

          -- RM control signals 
          RM_control_PGOOD    : in  slv(5 downto 0);
          RM_control_PEN      : out slv(5 downto 0);
          RM_control_RESET    : out slv(5 downto 0);       
        
          RM_i2c_SDA : inout slv(5 downto 0);
          RM_i2c_SCL : inout slv(5 downto 0);
          
          -- SFP data and control signals
          SFP_MGT_RX_P         : in  slv(3 downto 0);
          SFP_MGT_RX_N         : in  slv(3 downto 0);   
          SFP_MGT_TX_P         : out slv(3 downto 0);
          SFP_MGT_TX_N         : out slv(3 downto 0);   
          SFP_control_RX_LOS   : in  slv(3 downto 0);
          SFP_control_TX_FAULT : in  slv(3 downto 0);
          SFP_control_MOD_ABS  : in  slv(3 downto 0);
          SFP_control_TX_DIS   : out slv(3 downto 0);

          SFP_i2c_SCL : inout slv(3 downto 0);
          SFP_i2c_SDA : inout slv(3 downto 0)

          -- PMU Ports
          --fanEnableL : out   sl;
          -- SYSMON Ports
          --vPIn       : in    sl;
          --vNIn       : in    sl
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

   signal pulse_BCR_rtl : sl := '0' ;
   signal pulse_LED_rtl : sl := '0' ;
   signal MCLK          : sl := '0' ;
   signal MCLK37 : sl;

   signal fanEnableL : sl := '0';
   signal vPIn : sl := '0';
   signal vNIn : sl := '0';
   
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
         SIMULATION_G => SIMULATION_G,
         AXIL_CLK_FREQ_G  => 100.0E+6, -- half the LCLS frequency
         AXIL_BASE_ADDR_G => APP_ADDR_OFFSET_C)
      port map (
        -- i2c
        RM0_i2c.SCL           => RM_i2c_SCL(0),
        RM0_i2c.SDA           => RM_i2c_SDA(0),       
        RM1_i2c.SCL           => RM_i2c_SCL(1),
        RM1_i2c.SDA           => RM_i2c_SDA(1),
        RM2_i2c.SCL           => RM_i2c_SCL(2),
        RM2_i2c.SDA           => RM_i2c_SDA(2),
        RM3_i2c.SCL           => RM_i2c_SCL(3),
        RM3_i2c.SDA           => RM_i2c_SDA(3),
        Synth_i2c.SCL         => Synth_i2c_SCL,
        Synth_i2c.SDA         => Synth_i2c_SDA, 
        Jitter_i2c.SCL        => Jitter_i2c_SCL,
        Jitter_i2C.SDA        => Jitter_i2c_SDA,
        SFP0_i2c.SCL          => SFP_i2c_SCL(0),
        SFP0_i2c.SDA          => SFP_i2c_SDA(0),
        SFP1_i2c.SCL          => SFP_i2c_SCL(1),
        SFP1_i2c.SDA          => SFP_i2c_SDA(1),
        SFP2_i2c.SCL          => SFP_i2c_SCL(2),
        SFP2_i2c.SDA          => SFP_i2c_SDA(2),
        SFP3_i2c.SCL          => SFP_i2c_SCL(3),
        SFP3_i2c.SDA          => SFP_i2c_SDA(3),
        -- control signals
        RM0_control.PGOOD     => RM_control_PGOOD(0),
        RM1_control.PGOOD     => RM_control_PGOOD(1),
        RM2_control.PGOOD     => RM_control_PGOOD(2),
        RM3_control.PGOOD     => RM_control_PGOOD(3),
        RM4_control.PGOOD     => RM_control_PGOOD(4),
        RM5_control.PGOOD     => RM_control_PGOOD(5),
        
        RM0_control_out.PEN   => RM_control_PEN(0),
        RM0_control_out.RESET => RM_control_RESET(0),
        RM1_control_out.PEN   => RM_control_PEN(1),
        RM1_control_out.RESET => RM_control_RESET(1),
        RM2_control_out.PEN   => RM_control_PEN(2),
        RM2_control_out.RESET => RM_control_RESET(2),
        RM3_control_out.PEN   => RM_control_PEN(3),
        RM3_control_out.RESET => RM_control_RESET(3),
        RM4_control_out.PEN   => RM_control_PEN(4),
        RM4_control_out.RESET => RM_control_RESET(4),
        RM5_control_out.PEN   => RM_control_PEN(5),
        RM5_control_out.RESET => RM_control_RESET(5),

        SFP0_control.RX_LOS   => SFP_control_RX_LOS(0),
        SFP0_control.TX_FAULT   => SFP_control_TX_FAULT(0),
        SFP0_control.MOD_ABS   => SFP_control_MOD_ABS(0),
        SFP1_control.RX_LOS   => SFP_control_RX_LOS(1),
        SFP1_control.TX_FAULT   => SFP_control_TX_FAULT(1),
        SFP1_control.MOD_ABS   => SFP_control_MOD_ABS(1),
        SFP2_control.RX_LOS   => SFP_control_RX_LOS(2),
        SFP2_control.TX_FAULT   => SFP_control_TX_FAULT(2),
        SFP2_control.MOD_ABS   => SFP_control_MOD_ABS(2),
        SFP3_control.RX_LOS   => SFP_control_RX_LOS(3),
        SFP3_control.TX_FAULT   => SFP_control_TX_FAULT(3),
        SFP3_control.MOD_ABS   => SFP_control_MOD_ABS(3),

        SFP0_control_out.TX_DIS=> SFP_control_TX_DIS(0),
        SFP1_control_out.TX_DIS=> SFP_control_TX_DIS(1),
        SFP2_control_out.TX_DIS=> SFP_control_TX_DIS(2),
        SFP3_control_out.TX_DIS=> SFP_control_TX_DIS(3),

        Synth_control.INTR      => Synth_Control_INTR,
        Synth_control.LOS_XAXB  => Synth_Control_LOS_XAXB,
        Synth_control.LOL       => Synth_Control_LOL,

        Jitter_control.INTR      => Jitter_Control_INTR,
        Jitter_control.LOS_XAXB  => Jitter_Control_LOS_XAXB,
        Jitter_control.LOL       => Jitter_Control_LOL,

        Synth_control_out.RST   => Synth_Control_RST,           
        Jitter_control_out.RST   => Jitter_Control_RST,           

        -- Clocks
        appClk            => axilClk,
        appRes            => axilRst,
        MCLK37              => MCLK37,
        MGTREFCLK0_P      => CLKGEN_MGTCLK_AC_P,
        MGTREFCLK0_N      => CLKGEN_MGTCLK_AC_N,        
        MGTREFCLK1_P      => MGTREFCLK1_AC_P,
        MGTREFCLK1_N      => MGTREFCLK1_AC_N,

        -- Fast control signals
        pulse_BCR_rtl     => pulse_BCR_rtl,
        pulse_LED_rtl     => pulse_LED_rtl,

        -- SFP signals
        fcRxP    => SFP_MGT_RX_P(0),
        fcRxN    => SFP_MGT_RX_N(0),
        fcTxP    => SFP_MGT_TX_P(0),
        fcTxN    => SFP_MGT_TX_N(0),

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
    U_ClkOutBufDiff_1: entity surf.ClkOutBufDiff
       generic map (
          TPD_G          => TPD_G,
          XIL_DEVICE_G   => "ULTRASCALE_PLUS",
          RST_POLARITY_G => '1',
          INVERT_G       => true)
       port map (
          clkIn   => MCLK37,             -- [in]
          clkOutP => MCLK_FROM_SOC_P,           -- [out]
          clkOutN => MCLK_FROM_SOC_N);          -- [out]
    
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


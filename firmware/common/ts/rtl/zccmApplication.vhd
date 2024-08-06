----------------------------------------------------------------------------------
-- Company: FNAL
-- Author: A. Whitbeck
-- 
-- Create Date: 08/6/2024 
-- Design Name: 
-- Module Name: SoC PL application
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
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiStreamPkg.all;
use surf.AxiLitePkg.all;

use surf.I2cPkg.all;

library axi_soc_ultra_plus_core;
use axi_soc_ultra_plus_core.AxiSocUltraPlusPkg.all;

library ldmx_ts;

entity Application is
   generic (
      TPD_G            : time := 1 ns;
      SIMULATION_G      : boolean              := false;
      AXIL_CLK_FREQ_G   : real                 := 125.0e6;
      AXIL_BASE_ADDR_G : slv(31 downto 0));
   port (
        -- i2c
        RM0_i2c      : inout I2C_Signals;
        RM1_i2c      : inout I2C_Signals;
        RM2_i2c      : inout I2C_Signals;
        RM3_i2c      : inout I2C_Signals;
        Synth_i2c    : inout I2C_Signals;
        Jitter_i2c   : inout I2C_Signals;
        SFP0_i2c     : inout I2C_Signals;
        SFP1_i2c     : inout I2C_Signals;
        SFP2_i2c     : inout I2C_Signals;
        SFP3_i2c     : inout I2C_Signals;
        -- control signals
        RM0_control  : in RM_Control;
        RM1_control  : in RM_Control;
        RM2_control  : in RM_Control;
        RM3_control  : in RM_Control;
        RM4_control  : in RM_Control;
        RM5_control  : in RM_Control;
        
        RM0_control_out : out RM_Control_Out;
        RM1_control_out : out RM_Control_Out;
        RM2_control_out : out RM_Control_Out;
        RM3_control_out : out RM_Control_Out;
        RM4_control_out : out RM_Control_Out;
        RM5_control_out : out RM_Control_Out;

        SFP0_control    : in SFP_Control;
        SFP1_control    : in SFP_Control;
        SFP2_control    : in SFP_Control;
        SFP3_control    : in SFP_Control;

        SFP0_control_out : out SFP_Control_Out;
        SFP1_control_out : out SFP_Control_Out;
        SFP2_control_out : out SFP_Control_Out;
        SFP3_control_out : out SFP_Control_Out;

        Synth_control    : in Clock_Control;
        Jitter_control   : in Clock_Control;
        
        Synth_control_out  : in Clock_Control_Out;
        Jitter_control_out : in Clock_Control_Out;

        -- Clocks
        appClk            : in sl;
        appRes            : in sl;
        MCLK              : out sl;
        MGTREFCLK0        : in sl;
        MGTREFCLK1        : in sl;
      -- AXI-Lite Interface (axilClk domain)
      axilClk           : in    sl;
      axilRst           : in    sl;
      mAxilWriteMasters : in    AxiLiteWriteMasterArray(0 downto 0);
      mAxilWriteSlaves  : out   AxiLiteWriteSlaveArray(0 downto 0);
      mAxilReadMasters  : in    AxiLiteReadMasterArray(0 downto 0);
      mAxilReadSlaves   : out   AxiLiteReadSlaveArray(0 downto 0));
end Application;


architecture mapping of Application is

   constant DMA_SIZE_C           : positive := 1;
   constant AXIL_CLK_FREQ_C      : real     := 1.0/AXIL_CLK_FREQ_G;  

      constant AXIL_VERSION_INDEX_C    : natural  := 25;
   
   constant AXIL_RM0_I2C_INDEX_C    : natural  := 1;
   constant AXIL_RM1_I2C_INDEX_C    : natural  := 2;
   constant AXIL_RM2_I2C_INDEX_C    : natural  := 3;
   constant AXIL_RM3_I2C_INDEX_C    : natural  := 4;
   constant AXIL_RM4_I2C_INDEX_C    : natural  := 5;
   constant AXIL_RM5_I2C_INDEX_C    : natural  := 6;

   constant AXIL_SYNTH_I2C_INDEX_C  : natural  := 7; 
   constant AXIL_JITTER_I2C_INDEX_C : natural  := 8;    
   
   constant AXIL_TOP_REG_INDEX_C    : natural  := 9;

   constant AXIL_SFP0_REG_INDEX_C   : natural  := 10;
   constant AXIL_SFP1_REG_INDEX_C   : natural  := 11;
   constant AXIL_SFP2_REG_INDEX_C   : natural  := 12;
   constant AXIL_SFP3_REG_INDEX_C   : natural  := 13;

   constant AXIL_SYNTH_REG_INDEX_C  : natural  := 14;
   constant AXIL_JITTER_REG_INDEX_C : natural  := 15;

   constant AXIL_RM0_REG_INDEX_C    : natural  := 16;
   constant AXIL_RM1_REG_INDEX_C    : natural  := 17;
   constant AXIL_RM2_REG_INDEX_C    : natural  := 18;
   constant AXIL_RM3_REG_INDEX_C    : natural  := 19;
   constant AXIL_RM4_REG_INDEX_C    : natural  := 20;
   constant AXIL_RM5_REG_INDEX_C    : natural  := 21;

   constant AXIL_FCREC_REG_INDEX_C  : natural  := 22;
   constand AXIL_GTH_REG_INDEX_C    : natural  := 23
   constant AXIL_OUTPUT_REG_INDEX_C : natural  := 24;                

   --constant AXIL_SFP0_I2C_INDEX_C    : natural  := 25;
   --constant AXIL_SFP1_I2C_INDEX_C    : natural  := 26;
   --constant AXIL_SFP2_I2C_INDEX_C    : natural  := 27;
   --constant AXIL_SFP3_I2C_INDEX_C    : natural  := 28;        
   
   constant MAIN_XBAR_CFG_C : AxiLiteCrossbarMasterConfigArray(MAIN_XBAR_MASTERS_C-1 downto 0) := (
     AXIL_VERSION_INDEX_C             => (
       baseAddr                       => AXIL_BASE_ADDR_G + X"0000",
       addrBits                       => 16,
       connectivity                   => X"0001"), 

     AXIL_RM0_I2C_INDEX_C            => (    -- RM0 I2C Interface
         baseAddr                     => AXIL_BASE_ADDR_G + X"4_0500",
         addrBits                     => 8,
         connectivity                 => X"0001")
     AXIL_RM1_I2C_INDEX_C            => (    -- RM1 I2C Interface
         baseAddr                     => AXIL_BASE_ADDR_G + X"4_1000",
         addrBits                     => 8,
         connectivity                 => X"0001")
     AXIL_RM2_I2C_INDEX_C            => (    -- RM2 I2C Interface
         baseAddr                     => AXIL_BASE_ADDR_G + X"4_1500",
         addrBits                     => 8,
         connectivity                 => X"0001")
     AXIL_RM3_I2C_INDEX_C            => (    -- RM3 I2C Interface
         baseAddr                     => AXIL_BASE_ADDR_G + X"4_2000",
         addrBits                     => 8,
         connectivity                 => X"0001")
     AXIL_RM4_I2C_INDEX_C            => (    -- RM4 I2C Interface
         baseAddr                     => AXIL_BASE_ADDR_G + X"4_2500",
         addrBits                     => 8,
         connectivity                 => X"0001")
     AXIL_RM5_I2C_INDEX_C            => (    -- RM5 I2C Interface
         baseAddr                     => AXIL_BASE_ADDR_G + X"4_3000",
         addrBits                     => 8,
         connectivity                 => X"0001")

     AXIL_SYNTH_I2C_INDEX_C            => (    -- SYNTH I2C Interface
         baseAddr                     => AXIL_BASE_ADDR_G + X"4_3500",
         addrBits                     => 8,
         connectivity                 => X"0001")
     AXIL_JITTER_I2C_INDEX_C            => (    -- JITTER I2C Interface
         baseAddr                     => AXIL_BASE_ADDR_G + X"4_4000",
         addrBits                     => 8,
         connectivity                 => X"0001")

     AXIL_SFP0_REG_INDEX_C            => (    -- SFP0 control Register Interface
         baseAddr                     => AXIL_BASE_ADDR_G + X"4_4500",
         addrBits                     => 8,
         connectivity                 => X"0001")
     AXIL_SFP1_REG_INDEX_C            => (    -- SFP1 control Register Interface
         baseAddr                     => AXIL_BASE_ADDR_G + X"4_5000",
         addrBits                     => 8,
         connectivity                 => X"0001")
     AXIL_SFP2_REG_INDEX_C            => (    -- SFP2 control Register Interface
         baseAddr                     => AXIL_BASE_ADDR_G + X"4_5500",
         addrBits                     => 8,
         connectivity                 => X"0001")
     AXIL_SFP3_REG_INDEX_C            => (    -- SFP3 control Register Interface
         baseAddr                     => AXIL_BASE_ADDR_G + X"4_6000",
         addrBits                     => 8,
         connectivity                 => X"0001")
     AXIL_SYNTH_REG_INDEX_C            => (    -- SYNTH Register Interface
         baseAddr                     => AXIL_BASE_ADDR_G + X"4_6500",
         addrBits                     => 8,
         connectivity                 => X"0001")
     AXIL_JITTER_REG_INDEX_C          => (    -- Jitter Register Interface
         baseAddr                     => AXIL_BASE_ADDR_G + X"4_7000",
         addrBits                     => 8,
         connectivity                 => X"0001")
     AXIL_RM0_REG_INDEX_C          => (    -- RM0 control Register Interface
         baseAddr                     => AXIL_BASE_ADDR_G + X"4_7500",
         addrBits                     => 8,
         connectivity                 => X"0001")
     AXIL_RM1_REG_INDEX_C          => (    -- RM1 control Register Interface
         baseAddr                     => AXIL_BASE_ADDR_G + X"4_8000",
         addrBits                     => 8,
         connectivity                 => X"0001")
     AXIL_RM2_REG_INDEX_C          => (    -- RM2 control Register Interface
         baseAddr                     => AXIL_BASE_ADDR_G + X"4_8500",
         addrBits                     => 8,
         connectivity                 => X"0001")
     AXIL_RM3_REG_INDEX_C          => (    -- RM3 control Register Interface
         baseAddr                     => AXIL_BASE_ADDR_G + X"4_9000",
         addrBits                     => 8,
         connectivity                 => X"0001")
     AXIL_RM4_REG_INDEX_C          => (    -- RM4 control Register Interface
         baseAddr                     => AXIL_BASE_ADDR_G + X"4_9500",
         addrBits                     => 8,
         connectivity                 => X"0001")     
     AXIL_RM5_REG_INDEX_C          => (    -- RM5 control Register Interface
         baseAddr                     => AXIL_BASE_ADDR_G + X"5_0000",
         addrBits                     => 8,
         connectivity                 => X"0001")
     AXIL_FCREC_REG_INDEX_C          => (    -- FC Receiver Register Interface
         baseAddr                     => AXIL_BASE_ADDR_G + X"5_0500",
         addrBits                     => 8,
         connectivity                 => X"0001")
     AXIL_GTH_REG_INDEX_C          => (    -- GTH Register Interface
         baseAddr                     => AXIL_BASE_ADDR_G + X"5_1500",
         addrBits                     => 8,
         connectivity                 => X"0001")
     AXIL_OUTPUT_REG_INDEX_C          => (    -- Output Register Interface
         baseAddr                     => AXIL_BASE_ADDR_G + X"5_2000",
         addrBits                     => 8,
         connectivity                 => X"0001")
     );

      constant I2C_SCL_FREQ_C  : real := ite(SIMULATION_G, 2.0e6, 100.0E+3);
   constant I2C_MIN_PULSE_C : real := ite(SIMULATION_G, 50.0e-9, 100.0E-9);
   
   signal dmaClk       : sl;
   signal dmaRst       : sl;
   signal dmaObMasters : AxiStreamMasterArray(DMA_SIZE_C-1 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal dmaObSlaves  : AxiStreamSlaveArray(DMA_SIZE_C-1 downto 0)  := (others => AXI_STREAM_SLAVE_FORCE_C);
   signal dmaIbMasters : AxiStreamMasterArray(DMA_SIZE_C-1 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal dmaIbSlaves  : AxiStreamSlaveArray(DMA_SIZE_C-1 downto 0)  := (others => AXI_STREAM_SLAVE_FORCE_C);

   signal axilClk         : sl;
   signal axilRst         : sl;
   signal axilReadMaster  : AxiLiteReadMasterType;
   signal axilReadSlave   : AxiLiteReadSlaveType  := AXI_LITE_READ_SLAVE_EMPTY_DECERR_C;
   signal axilWriteMaster : AxiLiteWriteMasterType;
   signal axilWriteSlave  : AxiLiteWriteSlaveType := AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C;

   signal mainAxilWriteMasters : AxiLiteWriteMasterArray(MAIN_XBAR_MASTERS_C-1 downto 0) := (others => AXI_LITE_WRITE_MASTER_INIT_C);
   signal mainAxilWriteSlaves  : AxiLiteWriteSlaveArray(MAIN_XBAR_MASTERS_C-1 downto 0)  := (others => AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);
   signal mainAxilReadMasters  : AxiLiteReadMasterArray(MAIN_XBAR_MASTERS_C-1 downto 0)  := (others => AXI_LITE_READ_MASTER_INIT_C);
   signal mainAxilReadSlaves   : AxiLiteReadSlaveArray(MAIN_XBAR_MASTERS_C-1 downto 0)   := (others => AXI_LITE_READ_SLAVE_EMPTY_DECERR_C);

   type RegType is record
     RM_PEN      : slv(5 downto 0);       -- power enable for each RM pair 
     RM_RESET    : slv(5 downto 0);       -- reset for each RM pair
     Synth_RST   : sl;                    -- reset for generator chip
     Jitter_RST  : sl;                    -- reset for jitter cleaning clock chip
     SFP_TX_DIS  : slv(3 downto 0);       -- SFP Transmit disable for each module
     BCR_Command : slv(3 downto 0);       -- command BCR is synchronized to
     LED_Command : slv(3 downto 0);       -- command LED is synchronized to
     scratch     : slv(31 downto 0);      -- scratch register
     axilReadSlave  : AxiLiteReadSlaveType;
     axilWriteSlave : AxiLiteWriteSlaveType;
   end record RegType;

   constant REG_INIT_C : RegType := (
     RM_PEN      => (others => '0'),
     RM_RESET    => (others => '0'),
     Synth_RST   => '0';
     Jitter_RST  => '0';
     SFP_TX_DIS  => (others => '0'),
     BCR_Command => (others => '0'),
     LED_Command => (others => '0'),
     scratch     => (others => '0'),
     axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
     axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C);
   
   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal pulse_LED_rtl : sl := '0';
   signal pusle_BCR_rtl : sl := '0';
   signal reset : sl := '0';
   signal MCLK185  : sl := '0';
   signal reset185 : sl := '0';
   signal fcBus: ldmx_tdaq.FcBusType := FC_BUS_INIT_C;
   
   signal RM_i2c_scl : slv(5 downto 0) := (
     0 => RM0_i2c.SCL,
     1 => RM1_i2c.SCL,
     2 => RM2_i2c.SCL,
     3 => RM3_i2c.SCL,
     4 => RM4_i2c.SCL,
     5 => RM5_i2c.SCL);
   
   signal RM_i2c_sda : slv(5 downto 0) := (
     0 => RM0_i2c.SDA,
     1 => RM1_i2c.SDA,
     2 => RM2_i2c.SDA,
     3 => RM3_i2c.SDA,
     4 => RM4_i2c.SDA,
     5 => RM5_i2c.SDA);

    -- component definition for monitoring SFP bits
    -- component SFP_Monitor
    --     Port ( 
    --         sfp_con      : in  SFP_Control ;
    --         counter      : out STD_LOGIC_VECTOR (23 downto 0); 
    --         clk          : in STD_LOGIC;
    --         reset_n      : in STD_LOGIC;
    --         --Axil interface
    --         axilClk         : in  sl;
    --         axilRst         : in  sl;
    --         axilReadMaster  : in  AxiLiteReadMasterType;
    --         axilReadSlave   : out AxiLiteReadSlaveType;
    --         axilWriteMaster : in  AxiLiteWriteMasterType;
    --         axilWriteSlave  : out AxiLiteWriteSlaveType
    --          );
    -- end component;

    -- component definition for monitoring Clock bits
    -- component Clock_Monitor
    --     Port ( 
    --         clk_con      : in  Clock_Control ;
    --         counter      : out STD_LOGIC_VECTOR (15 downto 0); 
    --         clk          : in STD_LOGIC;
    --         reset_n      : in STD_LOGIC;
    --         --Axil interface
    --         axilClk         : in  sl;
    --         axilRst         : in  sl;
    --         axilReadMaster  : in  AxiLiteReadMasterType;
    --         axilReadSlave   : out AxiLiteReadSlaveType;
    --         axilWriteMaster : in  AxiLiteWriteMasterType;
    --         axilWriteSlave  : out AxiLiteWriteSlaveType
    --          );
    -- end component;

    -- component definition for monitoring RM PGOOD
    -- component RM_Monitor 
    --     Port ( 
    --         rm_con      : in  RM_Control ;
    --         counter      : out STD_LOGIC_VECTOR (7 downto 0); 
    --         clk          : in STD_LOGIC;
    --         reset_n      : in STD_LOGIC;
    --         --Axil interface
    --         axilClk         : in  sl;
    --         axilRst         : in  sl;
    --         axilReadMaster  : in  AxiLiteReadMasterType;
    --         axilReadSlave   : out AxiLiteReadSlaveType;
    --         axilWriteMaster : in  AxiLiteWriteMasterType;
    --         axilWriteSlave  : out AxiLiteWriteSlaveType
    --          );
    -- end component;

    -- component definition for fastcommandsynch; used to generate LED and BCR pulses

    -- component FastCommandSynch
    --     Port ( fast_command : in STD_LOGIC_VECTOR (3 downto 0);
    --            pulse : out STD_LOGIC;
    --            fast_command_config : in STD_LOGIC_VECTOR (3 downto 0);
    --            clk : in STD_LOGIC;
    --            areset_n : in STD_LOGIC);
    -- end component;
    
    -- top level signal definitions
    
    signal dummy_clock_output : STD_LOGIC := '0';    

begin

  synch_led :  ldmx_ts.FastCommandSynch
    Port Map ( 
      fast_command => fcBus.fcMsg.msgType,
      pulse => pulse_LED_rtl,
      fast_command_config => r.LED_Command,
      clk => SYNTH_TO_SOC_AC_P,
      areset_n => not reset
      );
  
  synch_bcr :  ldmx_ts.FastCommandSynch
    Port Map ( 
      fast_command => fcBus.fcMsg.msgType,
      pulse => pulse_BCR_rtl,
      fast_command_config => BCR_Command,
      clk => SYNTH_TO_SOC_AC_P,
      areset_n => not reset
      );

  -- - - - - - - - - - - - - - - - - - - - - -
  -- components for managing state changes on SPFs
  -- - - - - - - - - - - - - - - - - - - - - -
  
  SFP0_mon : ldmx_ts.SFP_Monitor
    generic map(
      TPD_G          => TPD_G)
    Port Map(
      sfp_con => SFP0_control,
      clk     => CLKGEN_CLK1_TO_SOC_AC_P,
      reset_n => not reset,
      -- Axil interface
      axilClk        => axilClk,
      axilRst        => axilRst,
      axilReadMaster  => mainAxilReadMasters(AXIL_SFP0_REG_INDEX_C),   -- [in]
      axilReadSlave   => mainAxilReadSlaves(AXIL_SFP0_REG_INDEX_C),    -- [out]
      axilWriteMaster => mainAxilWriteMasters(AXIL_SFP0_REG_INDEX_C),  -- [in]
      axilWriteSlave  => mainAxilWriteSlaves(AXIL_SFP0_REG_INDEX_C)    -- [out
      );
  SFP1_mon : ldmx_ts.SFP_Monitor
    generic map(
      TPD_G          => TPD_G)
    Port Map(
      sfp_con => SFP1_control,
      clk     => CLKGEN_CLK1_TO_SOC_AC_P,
      reset_n => not reset,
      -- Axil interface
      axilClk        => axilClk,
      axilRst        => axilRst,
      axilReadMaster  => mainAxilReadMasters(AXIL_SFP1_REG_INDEX_C),   -- [in]
      axilReadSlave   => mainAxilReadSlaves(AXIL_SFP1_REG_INDEX_C),    -- [out]
      axilWriteMaster => mainAxilWriteMasters(AXIL_SFP1_REG_INDEX_C),  -- [in]
      axilWriteSlave  => mainAxilWriteSlaves(AXIL_SFP1_REG_INDEX_C)    -- [out
      );
  SFP2_mon : ldmx_ts.SFP_Monitor
    generic map(
      TPD_G          => TPD_G)
    Port Map(
      sfp_con => SFP2_control,
      clk     => CLKGEN_CLK1_TO_SOC_AC_P,
      reset_n => not reset,
      -- Axil interface
      axilClk        => axilClk,
      axilRst        => axilRst,
      axilReadMaster  => mainAxilReadMasters(AXIL_SFP2_REG_INDEX_C),   -- [in]
      axilReadSlave   => mainAxilReadSlaves(AXIL_SFP2_REG_INDEX_C),    -- [out]
      axilWriteMaster => mainAxilWriteMasters(AXIL_SFP2_REG_INDEX_C),  -- [in]
      axilWriteSlave  => mainAxilWriteSlaves(AXIL_SFP2_REG_INDEX_C)    -- [out
      );
  SFP3_mon : ldmx_ts.SFP_Monitor
    generic map(
      TPD_G          => TPD_G)
    Port Map(
      sfp_con => SFP3_control,
      clk     => CLKGEN_CLK1_TO_SOC_AC_P,
      reset_n => not reset,
      -- Axil interface
      axilClk        => axilClk,
      axilRst        => axilRst,
      axilReadMaster  => mainAxilReadMasters(AXIL_SFP3_REG_INDEX_C),   -- [in]
      axilReadSlave   => mainAxilReadSlaves(AXIL_SFP3_REG_INDEX_C),    -- [out]
      axilWriteMaster => mainAxilWriteMasters(AXIL_SFP3_REG_INDEX_C),  -- [in]
      axilWriteSlave  => mainAxilWriteSlaves(AXIL_SFP3_REG_INDEX_C)    -- [out
      );             

  -- - - - - - - - - - - - - - - - - - - - - -
  -- components for managing state changes on Clock chips
  -- - - - - - - - - - - - - - - - - - - - - -
  synth_mon : ldmx_ts.Clock_Monitor
    generic map(
      TPD_G          => TPD_G)
    Port Map(
      clk_con => Synth_Control,
      clk     => CLKGEN_CLK1_TO_SOC_AC_P,
      reset_n => not reset,
      -- Axil interface
      axilClk        =>  axilClk,
      axilRst        =>  axilRst,
      axilReadMaster  => mainAxilReadMasters(AXIL_SYNTH_REG_INDEX_C),   -- [in]
      axilReadSlave   => mainAxilReadSlaves(AXIL_SYNTH_REG_INDEX_C),    -- [out]
      axilWriteMaster => mainAxilWriteMasters(AXIL_SYNTH_REG_INDEX_C),  -- [in]
      axilWriteSlave  => mainAxilWriteSlaves(AXIL_SYNTH_REG_INDEX_C)    -- [out]
      );    

  jitter_mon : ldmx_ts.Clock_Monitor
    generic map(
      TPD_G          => TPD_G)
    Port Map(
      clk_con => Jitter_Control,
      clk     => CLKGEN_CLK1_TO_SOC_AC_P,
      reset_n => not reset,
      -- Axil interface
      axilClk        => axilClk,
      axilRst        => axilRst,
      axilReadMaster  => mainAxilReadMasters(AXIL_JITTER_REG_INDEX_C),   -- [in]
      axilReadSlave   => mainAxilReadSlaves(AXIL_JITTER_REG_INDEX_C),    -- [out]
      axilWriteMaster => mainAxilWriteMasters(AXIL_JITTER_REG_INDEX_C),  -- [in]
      axilWriteSlave  => mainAxilWriteSlaves(AXIL_JITTER_REG_INDEX_C)    -- [out
      );
  -- - - - - - - - - - - - - - - - - - - - - -
  -- components for managing state changes on RMs
  -- - - - - - - - - - - - - - - - - - - - - -

  rm0_mon : ldmx_ts.RM_Monitor
    generic map(
      TPD_G          => TPD_G)
    Port Map(
      rm_con => RM0_control,
      clk    => CLKGEN_CLK1_TO_SOC_AC_P,
      reset_n=> not reset,
      -- Axil interface
      axilClk        => axilClk,
      axilRst        => axilRst,
      axilReadMaster  => mainAxilReadMasters(AXIL_RM0_REG_INDEX_C),   -- [in]
      axilReadSlave   => mainAxilReadSlaves(AXIL_RM0_REG_INDEX_C),    -- [out]
      axilWriteMaster => mainAxilWriteMasters(AXIL_RM0_REG_INDEX_C),  -- [in]
      axilWriteSlave  => mainAxilWriteSlaves(AXIL_RM0_REG_INDEX_C)    -- [out
      );
  
  rm1_mon : ldmx_ts.RM_Monitor
    generic map(
      TPD_G          => TPD_G)
    Port Map(
      rm_con => RM1_control,
      clk    => CLKGEN_CLK1_TO_SOC_AC_P,
      reset_n=> not reset,
      -- Axil interface
      axilClk        => axilClk,
      axilRst        => axilRst,
      axilReadMaster  => mainAxilReadMasters(AXIL_RM1_REG_INDEX_C),   -- [in]
      axilReadSlave   => mainAxilReadSlaves(AXIL_RM1_REG_INDEX_C),    -- [out]
      axilWriteMaster => mainAxilWriteMasters(AXIL_RM1_REG_INDEX_C),  -- [in]
      axilWriteSlave  => mainAxilWriteSlaves(AXIL_RM1_REG_INDEX_C)    -- [out
      );

  rm2_mon : ldmx_ts.RM_Monitor
    generic map(
      TPD_G          => TPD_G)
    Port Map(
      rm_con => RM2_control,
      clk    => CLKGEN_CLK1_TO_SOC_AC_P,
      reset_n=> not reset,
      -- Axil interface
      axilClk        => axilClk,
      axilRst        => axilRst,
      axilReadMaster  => mainAxilReadMasters(AXIL_RM2_REG_INDEX_C),   -- [in]
      axilReadSlave   => mainAxilReadSlaves(AXIL_RM2_REG_INDEX_C),    -- [out]
      axilWriteMaster => mainAxilWriteMasters(AXIL_RM2_REG_INDEX_C),  -- [in]
      axilWriteSlave  => mainAxilWriteSlaves(AXIL_RM2_REG_INDEX_C)    -- [out
      );

  rm3_mon : ldmx_ts.RM_Monitor
    generic map(
      TPD_G          => TPD_G)
    Port Map(
      rm_con => RM3_control,
      clk    => CLKGEN_CLK1_TO_SOC_AC_P,
      reset_n=> not reset,
      -- Axil interface
      axilClk        => axilClk,
      axilRst        => axilRst,
      axilReadMaster  => mainAxilReadMasters(AXIL_RM3_REG_INDEX_C),   -- [in]
      axilReadSlave   => mainAxilReadSlaves(AXIL_RM3_REG_INDEX_C),    -- [out]
      axilWriteMaster => mainAxilWriteMasters(AXIL_RM3_REG_INDEX_C),  -- [in]
      axilWriteSlave  => mainAxilWriteSlaves(AXIL_RM3_REG_INDEX_C)    -- [out
      );
  
  rm4_mon : ldmx_ts.RM_Monitor
    generic map(
      TPD_G          => TPD_G)
    Port Map(
      rm_con => RM4_control,
      clk    => CLKGEN_CLK1_TO_SOC_AC_P,
      reset_n=> not reset,
      -- Axil interface
      axilClk        => axilClk,
      axilRst        => axilRst,
      axilReadMaster  => mainAxilReadMasters(AXIL_RM4_REG_INDEX_C),   -- [in]
      axilReadSlave   => mainAxilReadSlaves(AXIL_RM4_REG_INDEX_C),    -- [out]
      axilWriteMaster => mainAxilWriteMasters(AXIL_RM4_REG_INDEX_C),  -- [in]
      axilWriteSlave  => mainAxilWriteSlaves(AXIL_RM4_REG_INDEX_C)    -- [out
      );

  rm5_mon : ldmx_ts.RM_Monitor 
    generic map(
      TPD_G          => TPD_G)
    Port Map(
      rm_con => RM5_control,
      counter=> gpio_rtl_RM1(23 downto 16),
      clk    => CLKGEN_CLK1_TO_SOC_AC_P,
      reset_n=> not reset,
      -- Axil interface
      axilClk        => axilClk,
      axilRst        => axilRst,
      axilReadMaster  => mainAxilReadMasters(AXIL_RM4_REG_INDEX_C),   -- [in]
      axilReadSlave   => mainAxilReadSlaves(AXIL_RM4_REG_INDEX_C),    -- [out]
      axilWriteMaster => mainAxilWriteMasters(AXIL_RM4_REG_INDEX_C),  -- [in]
      axilWriteSlave  => mainAxilWriteSlaves(AXIL_RM4_REG_INDEX_C)    -- [out
      );

  -------------------------------------------------------------------------------------------------
  -- Main Axi Crossbar
  -------------------------------------------------------------------------------------------------
  HpsAxiCrossbar : entity surf.AxiLiteCrossbar
    generic map (
      TPD_G              => TPD_G,
      NUM_SLAVE_SLOTS_G  => 1,
      NUM_MASTER_SLOTS_G => MAIN_XBAR_MASTERS_C,
      MASTERS_CONFIG_G   => MAIN_XBAR_CFG_C)
    port map (
      axiClk              => axilClk,
      axiClkRst           => axilRst,
      sAxiWriteMasters(0) => axilWriteMaster,
      sAxiWriteSlaves(0)  => axilWriteSlave,
      sAxiReadMasters(0)  => axilReadMaster,
      sAxiReadSlaves(0)   => axilReadSlave,
      mAxiWriteMasters    => mainAxilWriteMasters,
      mAxiWriteSlaves     => mainAxilWriteSlaves,
      mAxiReadMasters     => mainAxilReadMasters,
      mAxiReadSlaves      => mainAxilReadSlaves);

  -------------------------------------------------------------------------------------------------
  -- synthesizer clock chip I2C
  -------------------------------------------------------------------------------------------------
  constant SYNTH_DEVICE_MAP_C : I2cAxiLiteDevArray(0 downto 0) := (
    0              => MakeI2cAxiLiteDevType(
      i2cAddress  => "1101000",  -- si5344
      dataSize    => 8,
      addrSize    => 8,
      endianness  => '0'));

  U_AxiI2cRegMaster_Synth : entity surf.AxiI2cRegMaster
    generic map (
      TPD_G             => TPD_G,
      AXIL_PROXY_G      => false,
      DEVICE_MAP_G      => SYNTH_DEVICE_MAP_C,
      I2C_SCL_FREQ_G    => I2C_SCL_FREQ_C,
      I2C_MIN_PULSE_G   => I2C_MIN_PULSE_C,
      AXI_CLK_FREQ_G    => AXIL_CLK_FREQ_G)
    port map (
      -- AXIL signals
      axiClk         => axilClk,                                     -- [in]
      axiRst         => axilRst,                                     -- [in]
      axiReadMaster  => mainAxilReadMasters(AXIL_SYNTH_I2C_INDEX_C),   -- [in]
      axiReadSlave   => mainAxilReadSlaves(AXIL_SYNTH_I2C_INDEX_C),    -- [out]
      axiWriteMaster => mainAxilWriteMasters(AXIL_SYNTH_I2C_INDEX_C),  -- [in]
      axiWriteSlave  => mainAxilWriteSlaves(AXIL_SYNTH_I2C_INDEX_C),   -- [out]
      -- externals (these are buffered internal to AxiI2cRegMaster)
      scl            => Synth_i2c.SCL,                                     -- [inout]
      sda            => Synth_i2c.SDA);                                    -- [inout]

  
  -------------------------------------------------------------------------------------------------
  -- synthesizer clock chip I2C
  -------------------------------------------------------------------------------------------------
  constant JITTER_DEVICE_MAP_C : I2cAxiLiteDevArray(0 downto 0) := (
    0              => MakeI2cAxiLiteDevType(
      i2cAddress  => "1101001",  -- si5344
      dataSize    => 8,
      addrSize    => 8,
      endianness  => '0'));

  U_AxiI2cRegMaster_Jitter : entity surf.AxiI2cRegMaster
    generic map (
      TPD_G             => TPD_G,
      AXIL_PROXY_G      => false,
      DEVICE_MAP_G      => JITTER_DEVICE_MAP_C,
      I2C_SCL_FREQ_G    => I2C_SCL_FREQ_C,
      I2C_MIN_PULSE_G   => I2C_MIN_PULSE_C,
      AXI_CLK_FREQ_G    => AXIL_CLK_FREQ_G)
    port map (
      -- AXIL signals
      axiClk         => axilClk,                                     -- [in]
      axiRst         => axilRst,                                     -- [in]
      axiReadMaster  => mainAxilReadMasters(AXIL_JITTER_I2C_INDEX_C),   -- [in]
      axiReadSlave   => mainAxilReadSlaves(AXIL_JITTER_I2C_INDEX_C),    -- [out]
      axiWriteMaster => mainAxilWriteMasters(AXIL_JITTER_I2C_INDEX_C),  -- [in]
      axiWriteSlave  => mainAxilWriteSlaves(AXIL_JITTER_I2C_INDEX_C),   -- [out]
      -- externals (these are buffered internal to AxiI2cRegMaster)
      scl            => Jitter_i2c.SCL,                                     -- [inout]
      sda            => Jitter_i2c.SDA);                                    -- [inout]

  -------------------------------------------------------------------------------------------------
  -- Backplane/RM I2C device-register address mapping
  -- TODO:
  -- -this should be put into wrapper so that device configuration can be
  --  standardized across all of the backplanes
  -- -add RM slave
  -- -add peripheral devices on the RM
  -------------------------------------------------------------------------------------------------
  constant RM_DEVICE_MAP_C : I2cAxiLiteDevArray(2 downto 0) := (
    0              => MakeI2cAxiLiteDevType(                    -- GPIO (1000)
      i2cAddress  => "1000001",
      dataSize    => 8,
      addrSize    => 8,
      endianness  => '0'),
    1              => MakeI2cAxiLiteDevType(                    -- EEPROM(1400)
      i2cAddress  => "1010000",
      dataSize    => 8,
      addrSize    => 16,
      endianness  => '0',
      repeatStart => '1'),
    2              => MakeI2cAxiLiteDevType(                    -- UART-bridge(1800)
      i2cAddress  => "1001101",
      dataSize    => 8, 
      addrSize    => 8,
      endianness  => '1',
      repeatStart => '0') );


  GEN_VEC : for i in 5 downto 0 generate
    U_AxiI2cRegMaster_RM : entity surf.AxiI2cRegMaster
      generic map (
        TPD_G             => TPD_G,
        AXIL_PROXY_G      => false,
        DEVICE_MAP_G      => RM_DEVICE_MAP_C,
        I2C_SCL_FREQ_G    => I2C_SCL_FREQ_C,
        I2C_MIN_PULSE_G   => I2C_MIN_PULSE_C,
        AXI_CLK_FREQ_G    => AXIL_CLK_FREQ_G)
      port map (
        -- AXIL signals
        axiClk         => axilClk,                                     -- [in]
        axiRst         => axilRst,                                     -- [in]
        axiReadMaster  => mainAxilReadMasters(AXIL_RM0_I2C_INDEX_C+i),   -- [in]
        axiReadSlave   => mainAxilReadSlaves(AXIL_RM0_I2C_INDEX_C+i),    -- [out]
        axiWriteMaster => mainAxilWriteMasters(AXIL_RM0_I2C_INDEX_C+i),  -- [in]
        axiWriteSlave  => mainAxilWriteSlaves(AXIL_RM0_I2C_INDEX_C+i),   -- [out]
        -- externals (these are buffered internal to AxiI2cRegMaster)
        scl            => RM_i2c_scl(i),                                     -- [inout]
        sda            => RM_i2c_sda(i));                                    -- [inout]

    -- - - - - - - - - - - - - - - - - - - - - -
    -- FC Receiver block...
    -- TODO:
    --  - add GTH Wrapper and connect to FC Rec.
    -- - - - - - - - - - - - - - - - - - - - - -

    fcrec_1 : FcReceiver         
      port map(
        -- Reference clock
        fcRefClk185P =>  CLKGEN_MGTCLK_AC_P,
        fcRefClk185N =>  CLKGEN_MGTCLK_AC_N,
        -- Output Recovered Clock
        fcRecClkP    =>  BEAMCLK_P,
        fcRecClkN    =>  BEAMCLK_N,
        -- PGP serial IO
        fcTxP        => SFP0_out.MGT_TX_P,
        fcTxN        => SFP0_out.MGT_TX_N,
        fcRxP        => SFP0.MGT_RX_P,
        fcRxN        => SFP0.MGT_RX_N,
        -- RX FC and PGP interface
        fcClk185     => MCLK185,
        fcRst185     => reset185,
        fcBus        => fcBus,
        fcBunchClk37 => MCLK
        fcBunchRst37 => reset,
        -- Axil inteface
        axilClk         => axilClk,                                     -- [in] 
        axilRst         => axilRst,                                     -- [in] 
        axilReadMaster  => mainAxilReadMasters(AXIL_FCREC_REG_INDEX_C),   -- [in] 
        axilReadSlave   => mainAxilReadSlaves(AXIL_FCREC_REG_INDEX_C),    -- [out]
        axilWriteMaster => mainAxilWriteMasters(AXIL_FCREC_REG_INDEX_C),  -- [in] 
        axilWriteSlave  => mainAxilWriteSlaves(AXIL_FCREC_REG_INDEX_C)    -- [out]
        );
    
    comb : process (r, axilReadMaster, axilWriteMaster) is
      variable v      : RegType;
      variable axilEp : AxiLiteEndpointType;

    begin

      v := r;

      -- AXI Lite registers
      axiSlaveWaitTxn(axilEp, mainAxilWriteMaster(AXIL_OUTPUT_REG_INDEX_C), mainAxilReadMaster(AXIL_OUTPUT_REG_INDEX_C), v.axilWriteSlave, v.axilReadSlave);
      
      axiSlaveRegister(axilEp, X"00", 0, v.RM_PEN);
      axiSlaveRegister(axilEp, X"04", 0, v.RM_RESET);
      axiSlaveRegister(axilEp, X"08", 0, v.Synth_RST);
      axiSlaveRegister(axilEp, X"0C", 0, v.Jitter_RST);
      axiSlaveRegister(axilEp, X"10", 0, v.SFP_TIX_DIS);
      axiSlaveRegister(axilEp, X"14", 0, v.BCR_Command);    
      axiSlaveRegister(axilEp, X"18", 0, v.LED_Command); 

      axiSlaveDefault(axilEp, v.axilWriteSlave, v.axilReadSlave, AXI_RESP_DECERR_C);
      
      mainAxilReadSlave(AXIL_OUTPUT_REG_INDEX_C)  <= r.axilReadSlave;
      mainAxilWriteSlave(AXIL_OUTPUT_REG_INDEX_C) <= r.axilWriteSlave;
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
    
    MCLK_BUF_SEL <= '1';    
    
    RM0_control_out.PEN     <= r.RM_PEN(0); 
    RM0_control_out.RESET   <= r.RM_RESET(0); 
    RM1_control_out.PEN     <= r.RM_PEN(0); 
    RM1_control_out.RESET   <= r.RM_RESET(0); 
    RM2_control_out.PEN     <= r.RM_PEN(0);  
    RM2_control_out.RESET   <= r.RM_RESET(0); 
    RM3_control_out.PEN     <= r.RM_PEN(0);   
    RM3_control_out.RESET   <= r.RM_RESET(0); 
    RM4_control_out.PEN     <= r.RM_PEN(0);   
    RM4_control_out.RESET   <= r.RM_RESET(0);   
    RM5_control_out.PEN     <= r.RM_PEN(0);   
    RM5_control_out.RESET   <= r.RM_RESET(0);   
    
    Synth_Control_out.RST   <= r.Synth_RST; 
    Jitter_Control_out.RST  <= r.Jitter_RST;
    
    SFP0_control_out.TX_DIS <= r.SFP_TX_DIS(0);
    SFP1_control_out.TX_DIS <= r.SFP_TX_DIS(1);
    SFP2_control_out.TX_DIS <= r.SFP_TX_DIS(2);
    SFP3_control_out.TX_DIS <= r.SFP_TX_DIS(3);

end mapping
   

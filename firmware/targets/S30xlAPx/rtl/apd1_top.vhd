library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;


library UNISIM;
use UNISIM.vcomponents.all;


library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;


use surf.i2cPkg.all;


library apx_fs;
use apx_fs.PrjSpecPkg.all;
use apx_fs.tcdsPkg.all;
use apx_fs.MgtPkg.all;
use apx_fs.ApxChPkg.all;
use apx_fs.apd1ChassisPkg.all;


entity apd1_top is
  generic (
    I2C_C2C_PHY_ADDR_G : integer range 0 to 1023 := I2C_C2C_PHY_ADDR_C;
    AURORA_LANES       : integer                 := 2;
    TPD_G              : time                    := 1 ns;
    BUILD_INFO_G       : BuildInfoType;
    XIL_DEVICE_G       : string                  := "ULTRASCALE";
    ILA_ALGO_IO_DBG_G  : boolean                 := true
    );
  port (
    clk_300_clk_n : in std_logic;
    clk_300_clk_p : in std_logic;

    clk_125_osc_in_p : in std_logic;
    clk_125_osc_in_n : in std_logic;

    clk_125_osc_out0_p : out std_logic;
    clk_125_osc_out0_n : out std_logic;

    clk_125_osc_out1_p : out std_logic;
    clk_125_osc_out1_n : out std_logic;

    dplink_p2p_ecc_p : out std_logic := '0';
    dplink_p2n_ecc_n : out std_logic := '1';

    I2C_C2C_scl_io : inout std_logic;
    I2C_C2C_sda_io : inout std_logic;

    mgtRefClk0P : in slv(0 to REFCLK_CNT_C-1);
    mgtRefClk0N : in slv(0 to REFCLK_CNT_C-1);

    mgtRefClk1P : in slv(0 to REFCLK_CNT_C-1);
    mgtRefClk1N : in slv(0 to REFCLK_CNT_C-1);


    -- Mgt Rx/Tx pins
    MgtRxN : in  slv(0 to MGT_CNT_C-1) := (others => '0');
    MgtRxP : in  slv(0 to MGT_CNT_C-1) := (others => '0');
    MgtTxN : out slv(0 to MGT_CNT_C-1);
    MgtTxP : out slv(0 to MGT_CNT_C-1);


    gt_c2c_rx_rxn : in  slv (0 to AURORA_LANES-1);
    gt_c2c_rx_rxp : in  slv (0 to AURORA_LANES-1);
    gt_c2c_tx_txn : out slv (0 to AURORA_LANES-1);
    gt_c2c_tx_txp : out slv (0 to AURORA_LANES-1);

    tcdsRefclk_n : in std_logic;
    tcdsRefclk_p : in std_logic;

    refclk_c2c_clk_n : in std_logic;
    refclk_c2c_clk_p : in std_logic
    );
end apd1_top;

architecture rtl of apd1_top is


  signal clk_10  : sl;
  signal clk_40  : sl;
  signal clk_50  : sl;
  signal clk_80  : sl;
  signal clk_100 : sl;

  signal axi_lite_clk    : std_logic;
  signal axi_lite_resetn : std_logic_vector (0 to 0);
  signal axi_lite_reset  : std_logic;

  constant AXI_CLK_FREQUENCY_G : real := 50.00E+6;

  constant NUM_AXI_MASTERS_C : natural := 4;

  constant APX_INFO_INDEX_C        : natural := 0;
  constant TCDS_INDEX_C            : natural := 1;
  constant APX_SECTOR_CTRL_INDEX_C : natural := 2;
  constant ALGO_CTRL_INDEX_C       : natural := 3;


  constant AXI_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := (
    APX_INFO_INDEX_C        => (
      baseAddr              => APX_INFO_BASE_ADDR_C,
      addrBits              => 18,
      connectivity          => x"FFFF"),
    TCDS_INDEX_C            => (
      baseAddr              => TCDS_CTRL_BASE_ADDR_C,
      addrBits              => 16,
      connectivity          => x"FFFF"),
    ALGO_CTRL_INDEX_C       => (
      baseAddr              => ALGO_CTRL_BASE_ADDR_C,
      addrBits              => 16,
      connectivity          => x"FFFF"),
    APX_SECTOR_CTRL_INDEX_C => (
      baseAddr              => APX_SECTOR_CTRL_BASE_ADDR_C,
      addrBits              => 23,
      connectivity          => x"FFFF")

    );

  signal mAxilWriteMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
  signal mAxilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0) := (others => AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);
  signal mAxilReadMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
  signal mAxilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0)  := (others => AXI_LITE_READ_SLAVE_EMPTY_DECERR_C);

  signal mAxilWriteMaster : AxiLiteWriteMasterType;
  signal mAxilWriteSlave  : AxiLiteWriteSlaveType;
  signal mAxilReadMaster  : AxiLiteReadMasterType;
  signal mAxilReadSlave   : AxiLiteReadSlaveType;


  signal secAxiRst : slv(SECTOR_CNT_C-1 downto 0);

  signal secAxiWriteMasters : AxiLiteWriteMasterArray(SECTOR_CNT_C-1 downto 0) := (others => AXI_LITE_WRITE_MASTER_INIT_C);
  signal secAxiWriteSlaves  : AxiLiteWriteSlaveArray(SECTOR_CNT_C-1 downto 0)  := (others => AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);
  signal secAxiReadMasters  : AxiLiteReadMasterArray(SECTOR_CNT_C-1 downto 0)  := (others => AXI_LITE_READ_MASTER_INIT_C);
  signal secAxiReadSlaves   : AxiLiteReadSlaveArray(SECTOR_CNT_C-1 downto 0)   := (others => AXI_LITE_READ_SLAVE_EMPTY_DECERR_C);


  constant APX_SECTOR_OFFSETS_C : Slv32Array(0 to 5) := (SECTOR_0_BASE_ADDR_C,
                                                         SECTOR_1_BASE_ADDR_C,
                                                         SECTOR_2_BASE_ADDR_C,
                                                         SECTOR_3_BASE_ADDR_C,
                                                         SECTOR_4_BASE_ADDR_C,
                                                         SECTOR_5_BASE_ADDR_C);

  -- COMMON 
  -- AXI Chip to Chip
  signal axic2cgtQpllClk        : sl;
  signal axic2cgtQpllLock       : sl;
  signal axic2cgtQpllRefClk     : sl;
  signal axic2cgtQpllRefClkLost : sl;
  signal axic2cCommonQpllRst    : sl;
  signal axic2cRefClk           : sl;
  signal axic2cSyncClk          : sl;
  signal axic2cUserClk          : sl;
  signal gtPllLock, ngtPllLock  : sl;
  signal txUsrClk               : sl;
  signal syncCE, syncClr        : sl;
  signal bufGTClr               : sl;
  signal mmcmNotLocked          : sl;


  signal MgtRefClk0, MgtRefClk0Bufg : sl               := '0';
  signal MgtRefClk1, MgtRefClk1Bufg : sl               := '0';
  signal MgtRefClk                  : slv (1 downto 0) := (others => '0');
  signal gtQPllClk                  : slv (1 downto 0) := (others => '0');
  signal gtQpllLock                 : slv (1 downto 0) := (others => '0');
  signal gtQpllRefClk               : slv (1 downto 0) := (others => '0');
  signal gtQpllRefClkLost           : slv (1 downto 0) := (others => '0');
  signal gtQpllReset                : slv (1 downto 0) := (others => '0');
  signal gtQpllRefClkBufgDiv2       : slv (1 downto 0) := (others => '0');


  --LpGBT 
  signal TcdsQpll0ClkIn      : sl;
  signal TcdsQpll0RefClkIn   : sl;
  signal TcdsQpll1ClkIn      : sl;
  signal TcdsQpll1RefClkIn   : sl;
  signal TcdsgtQpll0LockIn   : sl;
  signal TcdsgtQpll0ResetOut : sl;

  signal clk_125, clk_125_bufg : std_logic;



  signal tcdsCmds    : tTcdsCmds;
  signal tcdsCmdsArr : tTcdsCmdsArr(0 to SECTOR_CNT_C-1);

  constant L1T_IN_STREAM_CNT_C  : integer := 100;
  constant L1T_OUT_STREAM_CNT_C : integer := 100;


  signal axiStreamAlgoIn  : AxiStreamMasterArray(0 to L1T_IN_STREAM_CNT_C -1);
  signal axiStreamAlgoOut : AxiStreamMasterArray(0 to L1T_OUT_STREAM_CNT_C -1);

  signal algoClk   : sl;
  signal algoRst   : sl;
  signal algoStart : sl;
  signal algoDone  : sl;
  signal algoIdle  : sl;
  signal algoReady : sl;


  signal fsClk40   : sl;
  signal fsClkMain : sl;
  signal fsClkDiv2 : sl;

  signal reg0 : slv(31 downto 0);
  signal reg1 : slv(31 downto 0);
  
  COMPONENT ila_algo_io_dbg

PORT (
	clk : IN STD_LOGIC;



	probe0 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
	probe1 : IN STD_LOGIC_VECTOR(4 DOWNTO 0); 
	probe2 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
	probe3 : IN STD_LOGIC_VECTOR(4 DOWNTO 0); 
	probe4 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
	probe5 : IN STD_LOGIC_VECTOR(4 DOWNTO 0); 
	probe6 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
	probe7 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
	probe8 : IN STD_LOGIC_VECTOR(0 DOWNTO 0)
);
END COMPONENT  ;



begin

  U_ibufds_125 : IBUFDS
    port map (
      O  => clk_125,
      I  => clk_125_osc_in_p,
      IB => clk_125_osc_in_n
      );


  BUFG_inst : BUFG
    port map (
      O => clk_125_bufg,
      I => clk_125
      );


  U_obufds_125_0 : OBUFDS
    port map (
      O  => clk_125_osc_out0_p,
      OB => clk_125_osc_out0_n,
      I  => clk_125_bufg
      );

  U_obufds_125_1 : OBUFDS
    port map (
      O  => clk_125_osc_out1_p,
      OB => clk_125_osc_out1_n,
      I  => clk_125_bufg
      );

  U_obufds_dplink_ecc : OBUFDS
    port map (
      O  => dplink_p2p_ecc_p,
      OB => dplink_p2n_ecc_n,
      I  => gtQpllRefClkBufgDiv2(1)
      );


  U_axiInfra : entity apx_fs.axiInfra
    generic map(
      I2C_C2C_PHY_ADDR_G => I2C_C2C_PHY_ADDR_G
      )
    port map(
      clk10            => clk_10,
      clk100           => clk_100,
      clk40            => clk_40,
      clk50            => clk_50,
      clk80            => clk_80,
      refclk_c2c_clk_n => refclk_c2c_clk_n,
      refclk_c2c_clk_p => refclk_c2c_clk_p,
      clk_osc_in_n     => clk_300_clk_n,
      clk_osc_in_p     => clk_300_clk_p,
      gt_c2c_rx_rxn    => gt_c2c_rx_rxn,
      gt_c2c_rx_rxp    => gt_c2c_rx_rxp,
      gt_c2c_tx_txn    => gt_c2c_tx_txn,
      gt_c2c_tx_txp    => gt_c2c_tx_txp,

      I2C_C2C_scl_io => I2C_C2C_scl_io,
      I2C_C2C_sda_io => I2C_C2C_sda_io,

      refClkIn             => axic2cRefClk,
      syncClkIn            => axic2cSyncClk,
      userClkIn            => axic2cUserClk,
      bufGtClrOut          => bufGTClr,
      txUsrClk             => txUsrClk,
      gtQpllClkIn          => axic2cgtQpllClk,
      gtQplllockIn         => axic2cgtQpllLock,
      gtQpllRefClkIn       => axic2cgtQpllRefClk,
      gtQpllRefClkLostIn   => axic2cgtQpllRefClkLost,
      gtCommonQpllResetOut => axic2cCommonQpllRst,
      mmcmNotLocked        => mmcmNotLocked,

      mAxilClk         => axi_lite_clk,
      mAxilRst         => axi_lite_reset,
      mAxilWriteMaster => mAxilWriteMaster,
      mAxilWriteSlave  => mAxilWriteSlave,
      mAxilReadMaster  => mAxilReadMaster,
      mAxilReadSlave   => mAxilReadSlave
      );

  U_QpllServiceBank : entity apx_fs.QpllServiceBank

    port map (
      axi_lite_clk => axi_lite_clk,

      txUsrClk => txUsrClk,
      bufGTClr => bufGTClr,

      axic2cRefClk  => axic2cRefClk,
      axic2cSyncClk => axic2cSyncClk,
      axic2cUserClk => axic2cUserClk,
      mmcmNotLocked => mmcmNotLocked,

      gtQpllReset          => gtQpllReset,
      gtQPllClk            => gtQPllClk,
      gtQpllRefClk         => gtQpllRefClk,
      gtQpllLock           => gtQpllLock,
      gtQpllRefClkLost     => gtQpllRefClkLost,
      gtQpllRefClkBufgDiv2 => gtQpllRefClkBufgDiv2,

      tcdsRefclk_n     => tcdsRefclk_n,
      tcdsRefclk_p     => tcdsRefclk_p,
      refclk_c2c_clk_n => refclk_c2c_clk_n,
      refclk_c2c_clk_p => refclk_c2c_clk_p
      );

  axic2cgtQpllClk        <= gtQpllClk(1);
  axic2cgtQpllLock       <= gtQpllLock(1);
  axic2cgtQpllRefClk     <= gtQpllRefClk(1);
  axic2cgtQpllRefClkLost <= gtQpllRefClkLost(1);

  gtQpllReset(1) <= axic2cCommonQpllRst;
  gtQpllReset(0) <= TcdsgtQpll0ResetOut;

  TcdsQpll0ClkIn    <= gtQpllClk(0);
  TcdsQpll0RefClkIn <= gtQpllRefClk(0);
  TcdsQpll1ClkIn    <= '0';
  TcdsQpll1RefClkIn <= '0';
  TcdsgtQpll0LockIn <= gtQpllLock(0);

  -----------------------------
  --  APxTCDS2 
  ---------------------------         
  U_ApxTcds2 : entity apx_fs.ApxTcds2
    generic map (
      FS_TO_LHC_CLK_FACTOR_G => FS_TO_LHC_CLK_FACTOR_C
      )
    port map(
      -- AXI-Lite Bus
      axiReadMaster  => mAxilReadMasters(TCDS_INDEX_C),
      axiReadSlave   => mAxilReadSlaves(TCDS_INDEX_C),
      axiWriteMaster => mAxilWriteMasters(TCDS_INDEX_C),
      axiWriteSlave  => mAxilWriteSlaves(TCDS_INDEX_C),
      axiClk         => axi_lite_clk,
      axiRst         => axi_lite_reset,

      APxTcds2MgtRefClk_p => tcdsRefclk_p,
      APxTcds2MgtRefClk_n => tcdsRefclk_n,
      fsClk40             => fsClk40,
      fsClkMain           => fsClkMain,
      fsClkDiv2           => fsClkDiv2,

      oscClk40 => clk_40,

      tcdsCmds => tcdsCmds,

      Qpll0ClkIn      => TcdsQpll0ClkIn,
      Qpll0RefClkIn   => TcdsQpll0RefClkIn,
      Qpll1ClkIn      => TcdsQpll1ClkIn,
      Qpll1RefClkIn   => TcdsQpll1RefClkIn,
      gtQpll0LockIn   => TcdsgtQpll0LockIn,
      gtQpll0ResetOut => TcdsgtQpll0ResetOut
      );


  U_XBAR : entity surf.AxiLiteCrossbar
    generic map (
      TPD_G              => TPD_G,
      NUM_SLAVE_SLOTS_G  => 1,
      NUM_MASTER_SLOTS_G => NUM_AXI_MASTERS_C,
      MASTERS_CONFIG_G   => AXI_CONFIG_C)
    port map (
      sAxiWriteMasters(0) => mAxilWriteMaster,
      sAxiWriteSlaves(0)  => mAxilWriteSlave,
      sAxiReadMasters(0)  => mAxilReadMaster,
      sAxiReadSlaves(0)   => mAxilReadSlave,
      mAxiWriteMasters    => mAxilWriteMasters,
      mAxiWriteSlaves     => mAxilWriteSlaves,
      mAxiReadMasters     => mAxilReadMasters,
      mAxiReadSlaves      => mAxilReadSlaves,
      axiClk              => axi_lite_clk,
      axiClkRst           => axi_lite_reset);

  U_APxInfo : entity apx_fs.apxInfo
    generic map(
      AXI_CLK_FREQ_G          => AXI_CLK_FREQUENCY_G,
      INCLUDE_VERSION_CORE    => true,
      INCLUDE_APX_FS_INFO_ROM => true,
      INCLUDE_ALGO_INFO_ROM   => false,
      BUILD_INFO_G            => BUILD_INFO_G,
      XIL_DEVICE_G            => "ULTRASCALE",
      AXIL_BASE_ADDR_G        => APX_INFO_BASE_ADDR_C
      )
    port map(
      SysmonClk => clk_10,

      -- AXI-Lite Bus
      axiReadMaster  => mAxilReadMasters(APX_INFO_INDEX_C),
      axiReadSlave   => mAxilReadSlaves(APX_INFO_INDEX_C),
      axiWriteMaster => mAxilWriteMasters(APX_INFO_INDEX_C),
      axiWriteSlave  => mAxilWriteSlaves(APX_INFO_INDEX_C),
      axiClk         => axi_lite_clk,
      axiRst         => axi_lite_reset);

  U_apxFsTcdsCmdChassisWrapper : entity apx_fs.apxFsTcdsCmdChassisWrapper
    generic map(
      SECTOR_CNT_G   => SECTOR_CNT_C,
      CHASSIS_TYPE_G => CHASSIS_TYPE_C
      )
    port map(
      tcdsClk40   => fsClk40,
      tcdsCmds    => tcdsCmds,
      tcdsCmdsArr => tcdsCmdsArr
      );


  U_ApxSectorChassisWrapper : entity apx_fs.ApxFsSectorChassisWrapper
    generic map(
      SECTOR_CNT_G   => SECTOR_CNT_C,
      CHASSIS_TYPE_G => CHASSIS_TYPE_C
      )
    port map(

      axiClk   => axi_lite_clk,
      axiRstIn => axi_lite_reset,

      sAxiReadMaster  => mAxilReadMasters(APX_SECTOR_CTRL_INDEX_C),
      sAxiReadSlave   => mAxilReadSlaves(APX_SECTOR_CTRL_INDEX_C),
      sAxiWriteMaster => mAxilWriteMasters(APX_SECTOR_CTRL_INDEX_C),
      sAxiWriteSlave  => mAxilWriteSlaves(APX_SECTOR_CTRL_INDEX_C),

      axiRstOut        => secAxiRst,
      mAxiWriteMasters => secAxiWriteMasters,
      mAxiWriteSlaves  => secAxiWriteSlaves,
      mAxiReadMasters  => secAxiReadMasters,
      mAxiReadSlaves   => secAxiReadSlaves
      );

  gen_sector : for i in 0 to SECTOR_CNT_C - 1 generate
    gen_sector_enabled : if SECTOR_ENABLED_C (i) = true generate
      U_apxSector : entity apx_fs.apxSector
        generic map(

          AXI_CLK_FREQ_G => AXI_CLK_FREQUENCY_G,

          REFCLK_CFG_G => REFCLK_CFG_C,
          QPLL_CFG_G   => QPLL_CFG_C,
          APX_CH_CFG_G => APX_CH_CFG_C,

          REFCLK_PAIR_IDX_BTM_G => sectorMinIdx(i, REFCLK_CFG_C),
          REFCLK_PAIR_IDX_TOP_G => sectorMaxIdx(i, REFCLK_CFG_C),

          QPLL_IDX_BTM_G => sectorMinIdx(i, QPLL_CFG_C),
          QPLL_IDX_TOP_G => sectorMaxIdx(i, QPLL_CFG_C),

          APX_CH_IDX_BTM_G => sectorMinIdx(i, APX_CH_CFG_C),
          APX_CH_IDX_TOP_G => sectorMaxIdx(i, APX_CH_CFG_C),

          AXIL_BASE_ADDR_G => APX_SECTOR_OFFSETS_C(i)

          )
        port map(

          axiReadMaster  => secAxiReadMasters(i),
          axiReadSlave   => secAxiReadSlaves(i),
          axiWriteMaster => secAxiWriteMasters(i),
          axiWriteSlave  => secAxiWriteSlaves(i),
          axiClk         => axi_lite_clk,
          axiRst         => secAxiRst(i),

          axiStreamClk => fsClkMain,
          axiStreamIn  => axiStreamAlgoOut(sectorMinIdx(i, APX_CH_CFG_C) to sectorMaxIdx(i, APX_CH_CFG_C)),
          axiStreamOut => axiStreamAlgoIn(sectorMinIdx(i, APX_CH_CFG_C) to sectorMaxIdx(i, APX_CH_CFG_C)),

          LHCClk   => fsClk40,
          tcdsCmds => tcdsCmdsArr(i),

          MgtRxN => MgtRxN(sectorMinIdx(i, APX_CH_CFG_C) to sectorMaxIdx(i, APX_CH_CFG_C)),
          MgtRxP => MgtRxP(sectorMinIdx(i, APX_CH_CFG_C) to sectorMaxIdx(i, APX_CH_CFG_C)),
          MgtTxN => MgtTxN(sectorMinIdx(i, APX_CH_CFG_C) to sectorMaxIdx(i, APX_CH_CFG_C)),
          MgtTxP => MgtTxP(sectorMinIdx(i, APX_CH_CFG_C) to sectorMaxIdx(i, APX_CH_CFG_C)),

          mgtRefClk0N => mgtRefClk0N(sectorMinIdx(i, REFCLK_CFG_C) to sectorMaxIdx(i, REFCLK_CFG_C)),
          mgtRefClk0P => mgtRefClk0P(sectorMinIdx(i, REFCLK_CFG_C) to sectorMaxIdx(i, REFCLK_CFG_C)),
          mgtRefClk1N => mgtRefClk1N(sectorMinIdx(i, REFCLK_CFG_C) to sectorMaxIdx(i, REFCLK_CFG_C)),
          mgtRefClk1P => mgtRefClk1P(sectorMinIdx(i, REFCLK_CFG_C) to sectorMaxIdx(i, REFCLK_CFG_C))

          );
    end generate;
  end generate;

  algoClk <= fsClkMain;

  U_algoCtrl : entity apx_fs.algoCtrlv2
    generic map (
      TPD_G => TPD_G)
    port map(
      algoClk   => algoClk,
      algoRst   => algoRst,
      algoStart => algoStart,
      algoDone  => algoDone,
      algoIdle  => algoIdle,
      algoReady => algoReady,

      tcdsCmds => tcdsCmds,

      -- AXI-Lite Bus
      axiReadMaster  => mAxilReadMasters(ALGO_CTRL_INDEX_C),
      axiReadSlave   => mAxilReadSlaves(ALGO_CTRL_INDEX_C),
      axiWriteMaster => mAxilWriteMasters(ALGO_CTRL_INDEX_C),
      axiWriteSlave  => mAxilWriteSlaves(ALGO_CTRL_INDEX_C),
      axiClk         => axi_lite_clk,
      axiClkRst      => axi_lite_reset);

  U_algoTopWrapper : entity work.algoTopWrapper
    generic map(
      APX_CH_CFG_G     => APX_CH_CFG_C,
      N_INPUT_STREAMS  => L1T_IN_STREAM_CNT_C,
      N_OUTPUT_STREAMS => L1T_OUT_STREAM_CNT_C
      )
    port map(
      -- Algo Control/Status Signals
      algoClk   => algoClk,
      algoRst   => algoRst,
      algoStart => algoStart,
      algoDone  => algoDone,
      algoIdle  => algoIdle,
      algoReady => algoReady,

      clkLHC     => fsClk40,
      bc0_clkLHC => tcdsCmds.bc0,

      -- AXI-Stream In/Out Ports
      axiStreamIn  => axiStreamAlgoIn,
      axiStreamOut => axiStreamAlgoOut
      );
      
gen_ila : if ILA_ALGO_IO_DBG_G = true generate
    U_ila_algo_io_dbg : ila_algo_io_dbg
    PORT MAP (
        clk => algoClk,
    
        probe0 => axiStreamAlgoIn(0).tData(31 downto 0), 
        probe1 => axiStreamAlgoIn(0).tUser(4 downto 0),
        probe2 => axiStreamAlgoIn(1).tData(31 downto 0), 
        probe3 => axiStreamAlgoIn(1).tUser(4 downto 0),
        probe4 => axiStreamAlgoOut(0).tData(31 downto 0), 
        probe5 => axiStreamAlgoOut(0).tUser(4 downto 0),
        probe6(0) => algoStart, 
        probe7(0) => algoRst,
        probe8(0) => tcdsCmds.bc0
    );
end generate;

end architecture;

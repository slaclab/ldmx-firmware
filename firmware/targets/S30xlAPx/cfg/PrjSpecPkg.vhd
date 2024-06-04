library IEEE;
use IEEE.STD_LOGIC_1164.all;

library surf;
use surf.StdRtlPkg.all;

library apx_fs;
use apx_fs.MgtPkg.all;
use apx_fs.ApxChPkg.all;

use apx_fs.apd1ChassisPkg.all;

package PrjSpecPkg is

  constant PRJ_SPEC_PKG_FORMAT_VER_C : integer := 1;

  -- chassis type
  constant CHASSIS_TYPE_C : string := "APd1";
  constant PROJECT_SPEED_GRADE_C : integer := 1;

 constant FABRIC_ID_BOARD_C : string := "APd1";
 constant FABRIC_ID_NUMBER_C : integer := 0;

  --clk 40 source
  constant CLK_40_SOURCE_LOCAL_C   : integer := 1;
  constant CLK_40_SOURCE_TCDS_C    : integer := 2;
  constant CLK_40_SOURCE_DYNAMIC_C : integer := 3;


  -- user constants
  -- Must begin with "USER_" and must be parsable as a string or number.
  constant USER_STRING_C : string           := "Project description. abcdef 123 !!@#$";  -- up to 64 character long, parser will throw an error if longer
  constant USER_NUM1_C   : slv(31 downto 0) := x"00000000";
  constant USER_NUM2_C   : slv(31 downto 0) := x"11111111";
  constant USER_NUM3_C   : slv(31 downto 0) := x"ABCD1234";
  constant USER_NUM4_C   : slv(31 downto 0) := x"87654321";

  constant PRJ_VER_MAJOR_C    : integer := 0;
  constant PRJ_VER_MINOR_C    : integer := 1;
  constant PRJ_VER_REVISION_C : integer := 0;

  -- firmware shell algo clock to LHC BC clock multiplier
  constant FS_TO_LHC_CLK_FACTOR_C : natural range 1 to 12 := 9;
  constant SHELL_ALGO_FREQ_HZ_C : natural range 1 to 1000000 := 360720000;

  constant SECTOR_ENABLED_C : BooleanArray(0 to SECTOR_CNT_C-1) := (
    0 => true,
    1 => true,
    2 => true,
    3 => true,
    4 => true,
    5 => true  
    );


  -- tRefClkCfgArr declaration in apx-fs/mgt/rtl/MgtPkg.vhd
  constant REFCLK_CFG_C : tRefClkCfgArr(0 to REFCLK_CNT_C-1) := (
    0  => (enabled => "11", sector => 0, refclk0_freq => "515.625MHz", refclk1_freq => "515.625MHz"),
    1  => (enabled => "11", sector => 0, refclk0_freq => "515.625MHz", refclk1_freq => "515.625MHz"),
    2  => (enabled => "11", sector => 1, refclk0_freq => "515.625MHz", refclk1_freq => "515.625MHz"),
    3  => (enabled => "00", sector => 1, refclk0_freq => "515.625MHz", refclk1_freq => "515.625MHz"),
    4  => (enabled => "11", sector => 1, refclk0_freq => "515.625MHz", refclk1_freq => "515.625MHz"),
    5  => (enabled => "11", sector => 2, refclk0_freq => "515.625MHz", refclk1_freq => "515.625MHz"),
    6  => (enabled => "11", sector => 2, refclk0_freq => "515.625MHz", refclk1_freq => "515.625MHz"),
    7  => (enabled => "11", sector => 2, refclk0_freq => "515.625MHz", refclk1_freq => "515.625MHz"),
    8  => (enabled => "11", sector => 3, refclk0_freq => "515.625MHz", refclk1_freq => "515.625MHz"),
    9  => (enabled => "11", sector => 3, refclk0_freq => "515.625MHz", refclk1_freq => "515.625MHz"),
    10 => (enabled => "11", sector => 4, refclk0_freq => "515.625MHz", refclk1_freq => "515.625MHz"),
    11 => (enabled => "11", sector => 4, refclk0_freq => "515.625MHz", refclk1_freq => "515.625MHz"),
    12 => (enabled => "11", sector => 4, refclk0_freq => "515.625MHz", refclk1_freq => "515.625MHz"),
    13 => (enabled => "11", sector => 5, refclk0_freq => "515.625MHz", refclk1_freq => "515.625MHz"),
    14 => (enabled => "11", sector => 5, refclk0_freq => "515.625MHz", refclk1_freq => "515.625MHz"),
    15 => (enabled => "11", sector => 5, refclk0_freq => "515.625MHz", refclk1_freq => "515.625MHz")

    );

  -- tQpllCfgArr declaration in apx-fs/mgt/rtl/MgtPkg.vhd
  constant QPLL_CFG_C : tQpllCfgArr(0 to QPLL_CNT_C-1) := (
    0  => (enabled => "1", sector => 0, qpllCore => gty_qpll_25g, refclk0 => 0, refclk1 => 0),
    1  => (enabled => "1", sector => 0, qpllCore => gty_qpll_25g, refclk0 => 0, refclk1 => 0),
    2  => (enabled => "1", sector => 0, qpllCore => gty_qpll_25g, refclk0 => 1, refclk1 => 1),
    3  => (enabled => "1", sector => 1, qpllCore => gty_qpll_25g, refclk0 => 2, refclk1 => 2),
    4  => (enabled => "1", sector => 1, qpllCore => gty_qpll_25g, refclk0 => 2, refclk1 => 2),
    5  => (enabled => "1", sector => 1, qpllCore => gty_qpll_25g, refclk0 => 4, refclk1 => 4),
    6  => (enabled => "1", sector => 1, qpllCore => gty_qpll_25g, refclk0 => 4, refclk1 => 4),
    7  => (enabled => "1", sector => 2, qpllCore => gty_qpll_25g, refclk0 => 5, refclk1 => 5),
    8  => (enabled => "1", sector => 2, qpllCore => gty_qpll_25g, refclk0 => 5, refclk1 => 5),
    9  => (enabled => "1", sector => 2, qpllCore => gty_qpll_25g, refclk0 => 6, refclk1 => 6),
    10 => (enabled => "1", sector => 2, qpllCore => gty_qpll_25g, refclk0 => 7, refclk1 => 7),
    11 => (enabled => "1", sector => 2, qpllCore => gty_qpll_25g, refclk0 => 7, refclk1 => 7),
    12 => (enabled => "1", sector => 3, qpllCore => gty_qpll_25g, refclk0 => 8, refclk1 => 8),
    13 => (enabled => "1", sector => 3, qpllCore => gty_qpll_25g, refclk0 => 8, refclk1 => 8),
    14 => (enabled => "1", sector => 3, qpllCore => gty_qpll_25g, refclk0 => 9, refclk1 => 9),
    15 => (enabled => "1", sector => 4, qpllCore => gty_qpll_25g, refclk0 => 10, refclk1 => 10),
    16 => (enabled => "1", sector => 4, qpllCore => gty_qpll_25g, refclk0 => 10, refclk1 => 10),
    17 => (enabled => "1", sector => 4, qpllCore => gty_qpll_25g, refclk0 => 11, refclk1 => 11),
    18 => (enabled => "1", sector => 4, qpllCore => gty_qpll_25g, refclk0 => 12, refclk1 => 12),
    19 => (enabled => "1", sector => 4, qpllCore => gty_qpll_25g, refclk0 => 12, refclk1 => 12),
    20 => (enabled => "1", sector => 5, qpllCore => gty_qpll_25g, refclk0 => 13, refclk1 => 13),
    21 => (enabled => "1", sector => 5, qpllCore => gty_qpll_25g, refclk0 => 13, refclk1 => 13),
    22 => (enabled => "1", sector => 5, qpllCore => gty_qpll_25g, refclk0 => 14, refclk1 => 14),
    23 => (enabled => "1", sector => 5, qpllCore => gty_qpll_25g, refclk0 => 15, refclk1 => 15),
    24 => (enabled => "1", sector => 5, qpllCore => gty_qpll_25g, refclk0 => 15, refclk1 => 15)

    );

  constant MGT_SYM_25G_6467 : tMgtCfg := (mgtCore => gty4_25g_sym, mgtCoreType => "gty4", rxLineRate => "25.78125Gbps", rxEncoding => "64b67b", txLineRate => "25.78125Gbps", txEncoding => "64b67b");

  --constant PROTO_CSP_TM_18_CR_9_FL_162_TV_0 : tCSPProtoCfg := (ProtocolType  => CSP, CSPTMInterval => 18, CSPClkRatio => 9, CSPFrameLength => 162, CSPThrottleVector => "000000000", lpGBTParam1 => 0, lpGBTParam2 => '0', lpGBTParam3 => "0000");

--TM2, 360 AXI Clock, 18-word packets (PL=18, PI=18), no throttle
 constant CSP_PL18_PI18 : tCSPProtoCfg := (ProtocolType => CSP, CSPFrameInterval => 18, CSPFrameLength => 18, CSPThrottleVector => "000000000", lpGBTParam1 => 0, lpGBTParam2 => '0', lpGBTParam3 => "0000");

  -- tApxChCfgArr declaration in apx-fs/apxSector/rtl/apxChPkg.vhd
  -- channel configurations for APx Validation Tests
  -- NOTE:  enable order, L->R, is  "TxBuf TxProt MGT RxProt RxBuf"   1=enabled, 0=disabled
  constant APX_CH_CFG_C : tApxChCfgArr(0 to MGT_CNT_C-1) := (
    0 => (enabled => "11111", sector => 0, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    1 => (enabled => "11111", sector => 0, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    2 => (enabled => "11111", sector => 0, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    3 => (enabled => "11111", sector => 0, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),

    4 => (enabled => "11111", sector => 0, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    5 => (enabled => "11111", sector => 0, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    6 => (enabled => "11111", sector => 0, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    7 => (enabled => "11111", sector => 0, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),

    8  => (enabled => "11111", sector => 0, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    9  => (enabled => "11111", sector => 0, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    10 => (enabled => "11111", sector => 0, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    11 => (enabled => "11111", sector => 0, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),

    12 => (enabled => "11111", sector => 1, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    13 => (enabled => "11111", sector => 1, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    14 => (enabled => "11111", sector => 1, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    15 => (enabled => "11111", sector => 1, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),

    16 => (enabled => "11111", sector => 1, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    17 => (enabled => "11111", sector => 1, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    18 => (enabled => "11111", sector => 1, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    19 => (enabled => "11111", sector => 1, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),

    20 => (enabled => "11111", sector => 1, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    21 => (enabled => "11111", sector => 1, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    22 => (enabled => "11111", sector => 1, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    23 => (enabled => "11111", sector => 1, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),

    24 => (enabled => "11111", sector => 1, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    25 => (enabled => "11111", sector => 1, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    26 => (enabled => "11111", sector => 1, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    27 => (enabled => "11111", sector => 1, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),

    28 => (enabled => "11111", sector => 2, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    29 => (enabled => "11111", sector => 2, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    30 => (enabled => "11111", sector => 2, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    31 => (enabled => "11111", sector => 2, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),

    32 => (enabled => "11111", sector => 2, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    33 => (enabled => "11111", sector => 2, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    34 => (enabled => "11111", sector => 2, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    35 => (enabled => "11111", sector => 2, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),

    36 => (enabled => "11111", sector => 2, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    37 => (enabled => "11111", sector => 2, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    38 => (enabled => "11111", sector => 2, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    39 => (enabled => "11111", sector => 2, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),

    40 => (enabled => "11111", sector => 2, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    41 => (enabled => "11111", sector => 2, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    42 => (enabled => "11111", sector => 2, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    43 => (enabled => "11111", sector => 2, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),

    --no links below this line have any enables
    44 => (enabled => "11111", sector => 2, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    45 => (enabled => "11111", sector => 2, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    46 => (enabled => "11111", sector => 2, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    47 => (enabled => "11111", sector => 2, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),

    48 => (enabled => "11111", sector => 3, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    49 => (enabled => "11111", sector => 3, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    50 => (enabled => "11111", sector => 3, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    51 => (enabled => "11111", sector => 3, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    52 => (enabled => "11111", sector => 3, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    53 => (enabled => "11111", sector => 3, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    54 => (enabled => "11111", sector => 3, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    55 => (enabled => "11111", sector => 3, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    56 => (enabled => "11111", sector => 3, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    57 => (enabled => "11111", sector => 3, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    58 => (enabled => "11111", sector => 3, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    59 => (enabled => "11111", sector => 3, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),

    60 => (enabled => "11111", sector => 4, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    61 => (enabled => "11111", sector => 4, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    62 => (enabled => "11111", sector => 4, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    63 => (enabled => "11111", sector => 4, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    64 => (enabled => "11111", sector => 4, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    65 => (enabled => "11111", sector => 4, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    66 => (enabled => "11111", sector => 4, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    67 => (enabled => "11111", sector => 4, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    68 => (enabled => "11111", sector => 4, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    69 => (enabled => "11111", sector => 4, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    70 => (enabled => "11111", sector => 4, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    71 => (enabled => "11111", sector => 4, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    72 => (enabled => "11111", sector => 4, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    73 => (enabled => "11111", sector => 4, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    74 => (enabled => "11111", sector => 4, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    75 => (enabled => "11111", sector => 4, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    76 => (enabled => "11111", sector => 4, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    77 => (enabled => "11111", sector => 4, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    78 => (enabled => "11111", sector => 4, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    79 => (enabled => "11111", sector => 4, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),

    80 => (enabled => "11111", sector => 5, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    81 => (enabled => "11111", sector => 5, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    82 => (enabled => "11111", sector => 5, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    83 => (enabled => "11111", sector => 5, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    84 => (enabled => "11111", sector => 5, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    85 => (enabled => "11111", sector => 5, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    86 => (enabled => "11111", sector => 5, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    87 => (enabled => "11111", sector => 5, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    88 => (enabled => "11111", sector => 5, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    89 => (enabled => "11111", sector => 5, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    90 => (enabled => "11111", sector => 5, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    91 => (enabled => "11111", sector => 5, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    92 => (enabled => "11111", sector => 5, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    93 => (enabled => "11111", sector => 5, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    94 => (enabled => "11111", sector => 5, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    95 => (enabled => "11111", sector => 5, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    96 => (enabled => "11111", sector => 5, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    97 => (enabled => "11111", sector => 5, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    98 => (enabled => "11111", sector => 5, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18),
    99 => (enabled => "11111", sector => 5, MgtCfg => MGT_SYM_25G_6467, TxProtocolCfg => CSP_PL18_PI18, RxProtocolCfg => CSP_PL18_PI18)

    );

end package PrjSpecPkg;


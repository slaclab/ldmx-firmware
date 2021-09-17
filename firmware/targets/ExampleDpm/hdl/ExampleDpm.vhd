-------------------------------------------------------------------------------
-- ExampleDpm.vhd
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;

library UNISIM;
use UNISIM.VCOMPONENTS.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
use surf.ClockManager7Pkg.all;


library rce_gen3_fw_lib;
use rce_gen3_fw_lib.RceG3Pkg.all;

library hps_daq;
use hps_daq.HpsPkg.all;
use hps_daq.HpsTiPkg.all;

entity ExampleDpm is
   generic (
      TPD_G              : time                        := 1 ns;
      BUILD_INFO_G       : BuildInfoType               := BUILD_INFO_DEFAULT_SLV_C;
      SIMULATION_G       : boolean                     := false;
      SIM_MEM_PORT_NUM_G : natural range 1024 to 49151 := 2000;
      SIM_DMA_PORT_NUM_G : natural range 1024 to 49151 := 3000;
      SIM_PGP_PORT_NUM_G : natural range 1024 to 49151 := 4000;
      HS_LINK_COUNT_G    : natural range 1 to 12       := 4;
      THRESHOLD_EN_G     : boolean                     := true;
      PACK_APV_DATA_G    : boolean                     := true;
      DATA_PGP_CFG_G     : DataPgpCfgType              := DATA_2500_S;
      DIST_CLK_PLL_G     : boolean                     := true);
   port (

      -- Debug
      led : out slv(1 downto 0);

      -- I2C
      i2cSda : inout sl := 'H';
      i2cScl : inout sl := 'H';

      -- Ethernet
      ethRxP     : in  slv(3 downto 0) := (others => '0');
      ethRxM     : in  slv(3 downto 0) := (others => '0');
      ethTxP     : out slv(3 downto 0) := (others => '0');
      ethTxM     : out slv(3 downto 0) := (others => '0');
      ethRefClkP : in  sl              := '0';
      ethRefClkM : in  sl              := '0';

      -- RTM High Speed
      dpmToRtmHsP : out slv(HS_LINK_COUNT_G-1 downto 0);
      dpmToRtmHsM : out slv(HS_LINK_COUNT_G-1 downto 0);
      rtmToDpmHsP : in  slv(HS_LINK_COUNT_G-1 downto 0);
      rtmToDpmHsM : in  slv(HS_LINK_COUNT_G-1 downto 0);

      -- Reference Clocks
      locRefClkP : in sl;
      locRefClkM : in sl;
      dtmRefClkP : in sl;
      dtmRefClkM : in sl;

      -- DTM Signals
      dtmClkP : in  slv(1 downto 0);
      dtmClkM : in  slv(1 downto 0);
      dtmFbP  : out sl;
      dtmFbM  : out sl;

      -- Clock Select
      clkSelA : out slv(1 downto 0);
      clkSelB : out slv(1 downto 0)
      );
end ExampleDpm;

architecture STRUCTURE of ExampleDpm is

   -------------------------------------------------------------------------------------------------
   -- System clocks
   -------------------------------------------------------------------------------------------------
   signal sysClk125    : sl;
   signal sysClk125Rst : sl;
   signal sysClk200    : sl;
   signal sysClk200Rst : sl;

   -------------------------------------------------------------------------------------------------
   -- AXI-Lite config
   -------------------------------------------------------------------------------------------------
   constant AXIL_MASTER_SLOTS_C  : natural := 2;
   constant AXIL_TIMING_INDEX_C  : integer := 0;
   constant AXIL_LDMX_INDEX_C    : integer := 1;

   constant AXIL_MASTERS_CONFIG_C : AxiLiteCrossbarMasterConfigArray := (
      -- Channel 0 = 0xA0000000 - 0xA000FFFF : DPM Timing Source
      0               => (
         baseAddr     => x"A0000000",
         addrBits     => 16,
         connectivity => x"FFFF"),

      -- Channel 1 = 0xA0100000 - 0xA01FFFFF : LDMX Address space
      1               => (
         baseAddr     => X"A0100000",
         addrBits     => 20,
         connectivity => X"FFFF"));

   -- AXI-Lite
   signal axilClk             : sl;
   signal axilRst             : sl;
   signal dpmAxilReadMaster   : AxiLiteReadMasterType;
   signal dpmAxilReadSlave    : AxiLiteReadSlaveType;
   signal dpmAxilWriteMaster  : AxiLiteWriteMasterType;
   signal dpmAxilWriteSlave   : AxiLiteWriteSlaveType;
   signal locAxilReadMasters  : AxiLiteReadMasterArray(AXIL_MASTER_SLOTS_C-1 downto 0);
   signal locAxilReadSlaves   : AxiLiteReadSlaveArray(AXIL_MASTER_SLOTS_C-1 downto 0);
   signal locAxilWriteMasters : AxiLiteWriteMasterArray(AXIL_MASTER_SLOTS_C-1 downto 0);
   signal locAxilWriteSlaves  : AxiLiteWriteSlaveArray(AXIL_MASTER_SLOTS_C-1 downto 0);

   -- DMA
   signal dmaClk      : sl;
   signal dmaRst      : sl;
   signal dmaObMaster : AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
   signal dmaObSlave  : AxiStreamSlaveType  := AXI_STREAM_SLAVE_FORCE_C;
   signal dmaIbMaster : AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
   signal dmaIbSlave  : AxiStreamSlaveType  := AXI_STREAM_SLAVE_FORCE_C;

   -- Distributed clociing
   signal dtmRefClk     : sl;
   signal dtmRefClkG    : sl;
   signal distClk       : sl;
   signal distClkLocked : sl;
   signal distClkRst    : sl;

   -- Timing sink
   signal rxData   : Slv10Array(1 downto 0);
   signal rxDataEn : slv(1 downto 0);
   signal txData   : slv(9 downto 0);
   signal txDataEn : sl;
   signal txReady  : sl;

begin

   --------------------------------------------------
   -- Core
   --------------------------------------------------
   U_DpmCore_1 : entity rce_gen3_fw_lib.DpmCore
      generic map (
         TPD_G              => TPD_G,
         BUILD_INFO_G       => BUILD_INFO_G,
         ETH_TYPE_G         => "1000BASE-KX",
         RCE_DMA_MODE_G     => RCE_DMA_AXISV2_C)
      port map (
         i2cSda             => i2cSda,               -- [inout]
         i2cScl             => i2cScl,               -- [inout]
         ethRxP             => ethRxP,               -- [in]
         ethRxM             => ethRxM,               -- [in]
         ethTxP             => ethTxP,               -- [out]
         ethTxM             => ethTxM,               -- [out]
         ethRefClkP         => ethRefClkP,           -- [in]
         ethRefClkM         => ethRefClkM,           -- [in]
         clkSelA            => clkSelA,              -- [out]
         clkSelB            => clkSelB,              -- [out]
         sysClk125          => sysClk125,            -- [out]
         sysClk125Rst       => sysClk125Rst,         -- [out]
         sysClk200          => sysClk200,            -- [out]
         sysClk200Rst       => sysClk200Rst,         -- [out]
         axiClk             => axilClk,              -- [out]
         axiClkRst          => axilRst,              -- [out]
         extAxilReadMaster  => dpmAxilReadMaster,    -- [out]
         extAxilReadSlave   => dpmAxilReadSlave,     -- [in]
         extAxilWriteMaster => dpmAxilWriteMaster,   -- [out]
         extAxilWriteSlave  => dpmAxilWriteSlave,    -- [in]
         dmaClk             => dmaClk,               -- [in]
         dmaClkRst          => dmaRst,               -- [in]
         dmaState           => open,                 -- [out]
         dmaObMaster        => dmaObMasters,         -- [out]
         dmaObSlave         => dmaObSlaves,          -- [in]
         dmaIbMaster        => dmaIbMasters,         -- [in]
         dmaIbSlave         => dmaIbSlaves,          -- [out]

   -------------------------------------
   -- AXI Lite Crossbar
   -- Base: 0xA0000000 - 0xAFFFFFFF
   -------------------------------------
   U_AxiCrossbar : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => AXIL_MASTER_SLOTS_C,
         DEC_ERROR_RESP_G   => AXI_RESP_OK_C,
         MASTERS_CONFIG_G   => AXIL_MASTERS_CONFIG_C)
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilRst,
         sAxiWriteMasters(0) => dpmAxilWriteMaster,
         sAxiWriteSlaves(0)  => dpmAxilWriteSlave,
         sAxiReadMasters(0)  => dpmAxilReadMaster,
         sAxiReadSlaves(0)   => dpmAxilReadSlave,
         mAxiWriteMasters    => locAxilWriteMasters,
         mAxiWriteSlaves     => locAxilWriteSlaves,
         mAxiReadMasters     => locAxilReadMasters,
         mAxiReadSlaves      => locAxilReadSlaves
         );

   --------------------------------------------------
   -- DTM Clocking
   --------------------------------------------------

   -- DTM Ref Clk
   U_DtmRefClk : IBUFDS_GTE2
      port map(
         O     => dtmRefClk,
         ODIV2 => open,
         I     => dtmRefClkP,
         IB    => dtmRefClkM,
         CEB   => '0'
         );

   -- DTM Clock
   U_DtmBufg : BUFG
      port map (
         I => dtmRefClk,
         O => dtmRefClkG
         );

   GenDistClkPll : if (DIST_CLK_PLL_G) generate
      ClockManager7_1 : entity surf.ClockManager7
         generic map (
            TPD_G            => TPD_G,
            TYPE_G           => "PLL",
            INPUT_BUFG_G     => false,
            FB_BUFG_G        => true,
            NUM_CLOCKS_G     => 1,
            BANDWIDTH_G      => "HIGH",
            CLKIN_PERIOD_G   => 8.0,
            DIVCLK_DIVIDE_G  => 1,
            CLKFBOUT_MULT_G  => 14,
            CLKOUT0_DIVIDE_G => 14)
         port map (
            clkIn     => dtmRefClkG,
            rstIn     => axilRst,
            clkOut(0) => distClk,
            locked    => distClkLocked);
   end generate;

   NoGenDistClkPll : if (not DIST_CLK_PLL_G) generate
      distClk       <= dtmRefClkG;
      distClkLocked <= '1';
   end generate;

   U_DpmTimingSinkV2 : entity rce_gen3_fw_lib.DpmTimingSinkV2
      generic map (
         TPD_G => TPD_G)
      port map (
         axiClk         => axilClk,
         axiClkRst      => axilRst,
         axiReadMaster  => locAxilReadMasters(AXIL_TIMING_INDEX_C),
         axiReadSlave   => locAxilReadSlaves(AXIL_TIMING_INDEX_C),
         axiWriteMaster => locAxilWriteMasters(AXIL_TIMING_INDEX_C),
         axiWriteSlave  => locAxilWriteSlaves(AXIL_TIMING_INDEX_C),
         sysClk200      => sysClk200,
         sysClk200Rst   => sysClk200Rst,
         dtmClkP        => dtmClkP,
         dtmClkM        => dtmClkM,
         dtmFbP         => dtmFbP,
         dtmFbM         => dtmFbM,
         distClk        => distClk,
         distClkLocked  => distClkLocked,
         distClkRst     => distClkRst,
         rxData         => rxData,
         rxDataEn       => rxDataEn,
         txData         => txData,
         txDataEn       => txDataEn,
         txReady        => txReady);

   --------------------------------------------------
   -- LDMX Core
   --------------------------------------------------

   U_LdmxDpmWrapper: entity ldmx.LdmxDpmWrapper
      generic map (
         TPD_G => TPD_G,
         HS_LINK_COUNT_G => HS_LINK_COUNT_G)
      port map (
         sysClk125       => sysClk125,
         sysClk125Rst    => sysClk125Rst,
         sysClk200       => sysClk200,
         sysClk200Rst    => sysClk200Rst,
         locRefClkP      => locRefClkP,
         locRefClkM      => locRefClkM,
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => locAxilReadMaster(1),
         axilReadSlave   => locAxilReadSlave(1),
         axilWriteMaster => locAxilWriteMaster(1),
         axilWriteSlave  => locAxilWriteSlave(1),
         dmaClk          => dmaClk,
         dmaRst          => dmaRst,
         dmaObMaster     => dmaObMaster,
         dmaObSlave      => dmaObSlave,
         dmaIbMaster     => dmaIbMaster,
         dmaIbSlave      => dmaIbSlave,
         dpmToRtmHsP     => dpmToRtmHsP,
         dpmToRtmHsM     => dpmToRtmHsM,
         rtmToDpmHsP     => rtmToDpmHsP,
         rtmToDpmHsM     => rtmToDpmHsM,
         rxData          => rxData,
         rxDataEn        => rxDataEn,
         txData          => txData,
         txDataEn        => txDataEn,
         txReady         => txReady
      );

   --------------------------------------------------
   -- Unused Top Level Signals
   --------------------------------------------------
   led <= (others => '1');

end architecture STRUCTURE;

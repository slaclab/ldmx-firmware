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

library ldmx;

entity ExampleDpm is
   generic (
      TPD_G              : time                     := 1 ns;
      BUILD_INFO_G       : BuildInfoType            := BUILD_INFO_DEFAULT_SLV_C;
      SIM_MEM_PORT_NUM_G : natural range 0 to 65535 := 20000;
      SIMULATION_G       : boolean                  := false;
      HS_LINK_COUNT_G    : natural range 1 to 12    := 2);
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
      dpmToRtmHsP : out slv(HS_LINK_COUNT_G-1 downto 0) := (others => '0');
      dpmToRtmHsM : out slv(HS_LINK_COUNT_G-1 downto 0) := (others => '0');
      rtmToDpmHsP : in  slv(HS_LINK_COUNT_G-1 downto 0) := (others => '0');
      rtmToDpmHsM : in  slv(HS_LINK_COUNT_G-1 downto 0) := (others => '0');

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
   constant AXIL_MASTER_SLOTS_C : natural := 2;
   constant AXIL_TIMING_INDEX_C : integer := 0;
   constant AXIL_LDMX_INDEX_C   : integer := 1;

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
   signal dmaClk      : slv(2 downto 0);
   signal dmaRst      : slv(2 downto 0);
   signal dmaObMaster : AxiStreamMasterArray(2 downto 0);
   signal dmaObSlave  : AxiStreamSlaveArray(2 downto 0);
   signal dmaIbMaster : AxiStreamMasterArray(2 downto 0);
   signal dmaIbSlave  : AxiStreamSlaveArray(2 downto 0);

   -- Distributed clociing
   signal dtmRefClk     : sl;
   signal dtmRefClkG    : sl;
   signal distClk       : sl;
   signal distClkRst    : sl;
   signal distClkLocked : sl;
   signal distDivClk    : sl;
   signal distDivClkRst : sl;

   -- Timing sink
   signal rxData   : slv(9 downto 0);
   signal rxDataEn : sl;
   signal txData   : slv(9 downto 0);
   signal txDataEn : sl;
   signal txReady  : sl;

begin

   --------------------------------------------------
   -- Core
   --------------------------------------------------
   U_DpmCore : entity rce_gen3_fw_lib.DpmCore
      generic map (
         TPD_G              => TPD_G,
         BUILD_INFO_G       => BUILD_INFO_G,
         SIMULATION_G       => SIMULATION_G,
         SIM_MEM_PORT_NUM_G => SIM_MEM_PORT_NUM_G,
         ETH_TYPE_G         => "ZYNQ-GEM",
         RCE_DMA_MODE_G     => RCE_DMA_AXISV2_C)
      port map (
         i2cSda             => i2cSda,              -- [inout]
         i2cScl             => i2cScl,              -- [inout]
         ethRxP             => ethRxP,              -- [in]
         ethRxM             => ethRxM,              -- [in]
         ethTxP             => ethTxP,              -- [out]
         ethTxM             => ethTxM,              -- [out]
         ethRefClkP         => ethRefClkP,          -- [in]
         ethRefClkM         => ethRefClkM,          -- [in]
         clkSelA            => clkSelA,             -- [out]
         clkSelB            => clkSelB,             -- [out]
         sysClk125          => sysClk125,           -- [out]
         sysClk125Rst       => sysClk125Rst,        -- [out]
         sysClk200          => sysClk200,           -- [out]
         sysClk200Rst       => sysClk200Rst,        -- [out]
         axiClk             => axilClk,             -- [out]
         axiClkRst          => axilRst,             -- [out]
         extAxilReadMaster  => dpmAxilReadMaster,   -- [out]
         extAxilReadSlave   => dpmAxilReadSlave,    -- [in]
         extAxilWriteMaster => dpmAxilWriteMaster,  -- [out]
         extAxilWriteSlave  => dpmAxilWriteSlave,   -- [in]
         dmaClk             => dmaClk,              -- [in]
         dmaClkRst          => dmaRst,              -- [in]
         dmaState           => open,                -- [out]
         dmaObMaster        => dmaObMaster,         -- [out]
         dmaObSlave         => dmaObSlave,          -- [in]
         dmaIbMaster        => dmaIbMaster,         -- [in]
         dmaIbSlave         => dmaIbSlave);         -- [out]

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

   ClockManager7_1 : entity surf.ClockManager7
      generic map (
         TPD_G            => TPD_G,
         TYPE_G           => "PLL",
         INPUT_BUFG_G     => false,
         FB_BUFG_G        => true,
         NUM_CLOCKS_G     => 1,
         BANDWIDTH_G      => "HIGH",
         CLKIN_PERIOD_G   => 5.37,      -- 186Mhz
         DIVCLK_DIVIDE_G  => 1,
         CLKFBOUT_MULT_G  => 5,         -- 930Mhz
         CLKOUT0_DIVIDE_G => 5)
      port map (
         clkIn     => dtmRefClkG,
         rstIn     => '0',
         clkOut(0) => distClk,
         rstOut(0) => distClkRst,
         locked    => distClkLocked);

   U_LdmxDpmTimingSink : entity ldmx.LdmxDpmTimingSink
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
         distClkRst     => distClkRst,
         distDivClk     => distDivClk,
         distDivClkRst  => distDivClkRst,
         distClkLocked  => distClkLocked,
         rxData         => rxData,
         rxDataEn       => rxDataEn,
         txData         => txData,
         txDataEn       => txDataEn,
         txReady        => txReady);

   --------------------------------------------------
   -- LDMX Core
   --------------------------------------------------

   U_LdmxDpmWrapper : entity ldmx.LdmxDpmWrapper
      generic map (
         TPD_G           => TPD_G,
         HS_LINK_COUNT_G => HS_LINK_COUNT_G)
      port map (
         sysClk125       => sysClk125,
         sysClk125Rst    => sysClk125Rst,
         sysClk200       => sysClk200,
         sysClk200Rst    => sysClk200Rst,
         locRefClkP      => locRefClkP,
         locRefClkM      => locRefClkM,
         dtmRefClkG      => dtmRefClkG,
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => locAxilReadMasters(1),
         axilReadSlave   => locAxilReadSlaves(1),
         axilWriteMaster => locAxilWriteMasters(1),
         axilWriteSlave  => locAxilWriteSlaves(1),
         dmaClk          => dmaClk(0),
         dmaRst          => dmaRst(0),
         dmaObMaster     => dmaObMaster(0),
         dmaObSlave      => dmaObSlave(0),
         dmaIbMaster     => dmaIbMaster(0),
         dmaIbSlave      => dmaIbSlave(0),
         dpmToRtmHsP     => dpmToRtmHsP,
         dpmToRtmHsM     => dpmToRtmHsM,
         rtmToDpmHsP     => rtmToDpmHsP,
         rtmToDpmHsM     => rtmToDpmHsM,
         distClk      => distClk,
         distDivClk      => distDivClk,
         distDivClkRst   => distDivClkRst,
         rxData          => rxData,
         rxDataEn        => rxDataEn,
         txData          => txData,
         txDataEn        => txDataEn,
         txReady         => txReady
         );

   dmaClk(2 downto 1)      <= (others => sysClk200);
   dmaRst(2 downto 1)      <= (others => sysClk200Rst);
   dmaObSlave(2 downto 1)  <= (others => AXI_STREAM_SLAVE_INIT_C);
   dmaIbMaster(2 downto 1) <= (others => AXI_STREAM_MASTER_INIT_C);

   --------------------------------------------------
   -- Unused Top Level Signals
   --------------------------------------------------
   led <= (others => '1');

end architecture STRUCTURE;

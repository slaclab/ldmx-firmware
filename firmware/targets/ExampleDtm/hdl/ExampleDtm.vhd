-------------------------------------------------------------------------------
-- ExampleDtm.vhd
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.STD_LOGIC_ARITH.all;

library UNISIM;
use UNISIM.VCOMPONENTS.all;


library rce_gen3_fw_lib;
use rce_gen3_fw_lib.RceG3Pkg.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;

library ldmx;

entity ExampleDtm is
   generic (
      TPD_G              : time                     := 1 ns;
      BUILD_INFO_G       : BuildInfoType            := BUILD_INFO_DEFAULT_SLV_C;
      SIM_MEM_PORT_NUM_G : natural range 0 to 65535 := 10000;
      SIMULATION_G       : boolean                  := false);
   port (

      -- Debug
      led : out slv(1 downto 0);

      -- I2C
      i2cSda : inout sl;
      i2cScl : inout sl;

      -- PCI Exress
      pciRefClkP : in  sl := '0';
      pciRefClkM : in  sl := '0';
      pciRxP     : in  sl := '0';
      pciRxM     : in  sl := '0';
      pciTxP     : out sl;
      pciTxM     : out sl;
      pciResetL  : out sl;

      -- COB Ethernet
      ethRxP : in  sl := '0';
      ethRxM : in  sl := '0';
      ethTxP : out sl;
      ethTxM : out sl;

      -- Reference Clock
      locRefClkP : in sl;
      locRefClkM : in sl;

      -- Clock Select
      clkSelA : out sl;
      clkSelB : out sl;

      -- Base Ethernet
      ethRxCtrl  : in    slv(1 downto 0) := "00";
      ethRxClk   : in    slv(1 downto 0) := "00";
      ethRxDataA : in    Slv(1 downto 0) := "00";
      ethRxDataB : in    Slv(1 downto 0) := "00";
      ethRxDataC : in    Slv(1 downto 0) := "00";
      ethRxDataD : in    Slv(1 downto 0) := "00";
      ethTxCtrl  : out   slv(1 downto 0) := "00";
      ethTxClk   : out   slv(1 downto 0) := "00";
      ethTxDataA : out   Slv(1 downto 0) := "00";
      ethTxDataB : out   Slv(1 downto 0) := "00";
      ethTxDataC : out   Slv(1 downto 0) := "00";
      ethTxDataD : out   Slv(1 downto 0) := "00";
      ethMdc     : out   Slv(1 downto 0) := "00";
      ethMio     : inout Slv(1 downto 0) := "HH";
      ethResetL  : out   Slv(1 downto 0) := "00";

      -- RTM High Speed
      dtmToRtmHsP : out sl := '0';
      dtmToRtmHsM : out sl := '0';
      rtmToDtmHsP : in  sl := '0';
      rtmToDtmHsM : in  sl := '0';

      -- RTM Low Speed
      dtmToRtmLsP : inout slv(5 downto 0) := (others => 'L');
      dtmToRtmLsM : inout slv(5 downto 0) := (others => 'H');

      -- DPM Signals
      dpmClkP : out slv(2 downto 0);
      dpmClkM : out slv(2 downto 0);
      dpmFbP  : in  slv(7 downto 0);
      dpmFbM  : in  slv(7 downto 0);

      -- Backplane Clocks
      bpClkIn  : in  slv(5 downto 0) := (others => '0');
      bpClkOut : out slv(5 downto 0) := (others => '0');

      -- Spare Signals
      plSpareP : inout slv(4 downto 0) := (others => '0');
      plSpareM : inout slv(4 downto 0) := (others => '0');

      -- IPMI
      dtmToIpmiP : out slv(1 downto 0);
      dtmToIpmiM : out slv(1 downto 0)

      );
end ExampleDtm;

architecture STRUCTURE of ExampleDtm is

   -- Local Signals
   signal axiClk             : sl;
   signal axiClkRst          : sl;
   signal sysClk125          : sl;
   signal sysClk125Rst       : sl;
   signal sysClk200          : sl;
   signal sysClk200Rst       : sl;
   signal extAxilReadMaster  : AxiLiteReadMasterType;
   signal extAxilReadSlave   : AxiLiteReadSlaveType;
   signal extAxilWriteMaster : AxiLiteWriteMasterType;
   signal extAxilWriteSlave  : AxiLiteWriteSlaveType;
   signal dmaClk             : slv(2 downto 0);
   signal dmaClkRst          : slv(2 downto 0);
   signal dmaState           : RceDmaStateArray(2 downto 0);
   signal dmaObMaster        : AxiStreamMasterArray(2 downto 0);
   signal dmaObSlave         : AxiStreamSlaveArray(2 downto 0);
   signal dmaIbMaster        : AxiStreamMasterArray(2 downto 0);
   signal dmaIbSlave         : AxiStreamSlaveArray(2 downto 0);
   signal locAxilReadMaster  : AxiLiteReadMasterArray(1 downto 0);
   signal locAxilReadSlave   : AxiLiteReadSlaveArray(1 downto 0);
   signal locAxilWriteMaster : AxiLiteWriteMasterArray(1 downto 0);
   signal locAxilWriteSlave  : AxiLiteWriteSlaveArray(1 downto 0);
   signal txData             : slv(9 downto 0);
   signal txDataEn           : sl;
   signal txReady            : sl;
   signal rxData             : Slv10Array(7 downto 0);
   signal rxDataEn           : slv(7 downto 0);
   signal distClk            : sl;
   signal distClkRst         : sl;
   signal distDivClk         : sl;
   signal distDivClkRst      : sl;

begin

   --------------------------------------------------
   -- Core
   --------------------------------------------------
   U_DtmCore : entity rce_gen3_fw_lib.DtmCore
      generic map (
         TPD_G              => TPD_G,
         BUILD_INFO_G       => BUILD_INFO_G,
         SIMULATION_G       => SIMULATION_G,
         SIM_MEM_PORT_NUM_G => SIM_MEM_PORT_NUM_G,
         RCE_DMA_MODE_G     => RCE_DMA_AXISV2_C)
      port map (
         i2cSda             => i2cSda,
         i2cScl             => i2cScl,
         pciRefClkP         => pciRefClkP,
         pciRefClkM         => pciRefClkM,
         pciRxP             => pciRxP,
         pciRxM             => pciRxM,
         pciTxP             => pciTxP,
         pciTxM             => pciTxM,
         pciResetL          => pciResetL,
         ethRxP             => ethRxP,
         ethRxM             => ethRxM,
         ethTxP             => ethTxP,
         ethTxM             => ethTxM,
         clkSelA            => clkSelA,
         clkSelB            => clkSelB,
         ethRxCtrl          => ethRxCtrl,
         ethRxClk           => ethRxClk,
         ethRxDataA         => ethRxDataA,
         ethRxDataB         => ethRxDataB,
         ethRxDataC         => ethRxDataC,
         ethRxDataD         => ethRxDataD,
         ethTxCtrl          => ethTxCtrl,
         ethTxClk           => ethTxClk,
         ethTxDataA         => ethTxDataA,
         ethTxDataB         => ethTxDataB,
         ethTxDataC         => ethTxDataC,
         ethTxDataD         => ethTxDataD,
         ethMdc             => ethMdc,
         ethMio             => ethMio,
         ethResetL          => ethResetL,
         dtmToIpmiP         => dtmToIpmiP,
         dtmToIpmiM         => dtmToIpmiM,
         sysClk125          => sysClk125,
         sysClk125Rst       => sysClk125Rst,
         sysClk200          => sysClk200,
         sysClk200Rst       => sysClk200Rst,
         axiClk             => axiClk,
         axiClkRst          => axiClkRst,
         extAxilReadMaster  => extAxilReadMaster,
         extAxilReadSlave   => extAxilReadSlave,
         extAxilWriteMaster => extAxilWriteMaster,
         extAxilWriteSlave  => extAxilWriteSlave,
         dmaClk             => dmaClk,
         dmaClkRst          => dmaClkRst,
         dmaState           => dmaState,
         dmaObMaster        => dmaObMaster,
         dmaObSlave         => dmaObSlave,
         dmaIbMaster        => dmaIbMaster,
         dmaIbSlave         => dmaIbSlave,
         userInterrupt      => (others => '0'));


   -------------------------------------
   -- AXI Lite Crossbar
   -- Base: 0xA0000000 - 0xAFFFFFFF
   -------------------------------------
   U_AxiCrossbar : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => 2,
         DEC_ERROR_RESP_G   => AXI_RESP_OK_C,
         MASTERS_CONFIG_G   => (

            -- Channel 0 = 0xA0000000 - 0xA000FFFF : DTM Timing
            0               => (
               baseAddr     => x"A0000000",
               addrBits     => 16,
               connectivity => x"FFFF"),

            -- Channel 1 = 0xA0001000 - 0xA001FFFF : DTM Trigger
            1               => (
               baseAddr     => x"A0010000",
               addrBits     => 16,
               connectivity => x"FFFF")
            )
         ) port map (
            axiClk              => axiClk,
            axiClkRst           => axiClkRst,
            sAxiWriteMasters(0) => extAxilWriteMaster,
            sAxiWriteSlaves(0)  => extAxilWriteSlave,
            sAxiReadMasters(0)  => extAxilReadMaster,
            sAxiReadSlaves(0)   => extAxilReadSlave,
            mAxiWriteMasters    => locAxilWriteMaster,
            mAxiWriteSlaves     => locAxilWriteSlave,
            mAxiReadMasters     => locAxilReadMaster,
            mAxiReadSlaves      => locAxilReadSlave
            );


   --------------------------------------------------
   -- PPI Loopback
   --------------------------------------------------
   dmaClk(2 downto 0)      <= (others => sysClk200);
   dmaClkRst(2 downto 0)   <= (others => sysClk200Rst);
   dmaIbMaster(2 downto 0) <= dmaObMaster(2 downto 0);
   dmaObSlave(2 downto 1)  <= dmaIbSlave(2 downto 1);
   dmaObSlave(0)           <= AXI_STREAM_SLAVE_FORCE_C;

   --------------------------------------------------
   -- Timing
   --------------------------------------------------
   U_LdmxDtmTimingSource : entity ldmx.LdmxDtmTimingSource
      generic map (
         TPD_G => TPD_G
         )
      port map (
         axiClk         => axiClk,
         axiClkRst      => axiClkRst,
         axiReadMaster  => locAxilReadMaster(0),
         axiReadSlave   => locAxilReadSlave(0),
         axiWriteMaster => locAxilWriteMaster(0),
         axiWriteSlave  => locAxilWriteSlave(0),
         sysClk200      => sysClk200,
         sysClk200Rst   => sysClk200Rst,
         distClk        => distClk,
         distClkRst     => distClkRst,
         distDivClk     => distDivClk,
         distDivClkRst  => distDivClkRst,
         txData         => txData,
         txDataEn       => txDataEn,
         txReady        => txReady,
         rxData         => rxData,
         rxDataEn       => rxDataEn,
         dpmClkP        => dpmClkP,
         dpmClkM        => dpmClkM,
         dpmFbP         => dpmFbP,
         dpmFbM         => dpmFbM
         );


   --------------------------------------------------
   -- Trigger
   --------------------------------------------------
   U_LdmxDtmWrapper : entity ldmx.LdmxDtmWrapper
      generic map (
         TPD_G            => TPD_G,
         SIMULATION_G     => SIMULATION_G,
         AXIL_BASE_ADDR_G => x"A0010000"
         )
      port map (
         axilClk         => axiClk,
         axilClkRst      => axiClkRst,
         axilReadMaster  => locAxilReadMaster(1),
         axilReadSlave   => locAxilReadSlave(1),
         axilWriteMaster => locAxilWriteMaster(1),
         axilWriteSlave  => locAxilWriteSlave(1),
         sysClk200       => sysClk200,
         sysClk200Rst    => sysClk200Rst,
         sysClk125       => sysClk125,
         sysClk125Rst    => sysClk125Rst,
         locRefClkP      => locRefClkP,
         locRefClkM      => locRefClkM,
         dtmToRtmLsP     => dtmToRtmLsP,
         dtmToRtmLsM     => dtmToRtmLsM,
         plSpareP        => plSpareP,
         plSpareM        => plSpareM,
         distClk         => distClk,
         distClkRst      => distClkRst,
         distDivClk      => distDivClk,
         distDivClkRst   => distDivClkRst,
         txData          => txData,
         txDataEn        => txDataEn,
         txReady         => txReady,
         rxData          => rxData,
         rxDataEn        => rxDataEn,
         gtTxP           => dtmToRtmHsP,
         gtTxN           => dtmToRtmHsM,
         gtRxP           => rtmToDtmHsP,
         gtRxN           => rtmToDtmHsM
         );


   --------------------------------------------------
   -- Top Level Signals
   --------------------------------------------------

   -- Backplane Clocks
   --bpClkIn      : in    slv(5 downto 0);
   --bpClkOut     : out   slv(5 downto 0);
   bpClkOut <= (others => '0');
   led      <= (others => '1');

end architecture STRUCTURE;


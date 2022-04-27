-------------------------------------------------------------------------------
-- Title         : PGP Lane Array For Control DPM
-- File          : HpsCtrlPgpArray.vhd
-- Author        : Ryan Herbst, rherbst@slac.stanford.edu
-- Created       : 05/21/2014
-------------------------------------------------------------------------------
-- Description:
-- Array of 10 PGP Lanes
-------------------------------------------------------------------------------
-- Copyright (c) 2013 by Ryan Herbst. All rights reserved.
-------------------------------------------------------------------------------
-- Modification history:
-- 05/21/2014: created.
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

library UNISIM;
use UNISIM.VCOMPONENTS.all;


library surf;
use surf.StdRtlPkg.all;
use surf.Pgp2bPkg.all;
use surf.AxiStreamPkg.all;
use surf.AxiLitePkg.all;
use surf.Gtx7CfgPkg.all;

library ldmx; 

entity HpsCtrlPgpArray is
   generic (
      TPD_G               : time                        := 1 ns;
      SIMULATION_G        : boolean                     := false;
      SIM_PGP_PORT_NUM_G  : natural range 1024 to 49151 := 4000;
      AXIL_BASE_ADDRESS_G : slv(31 downto 0)            := x"00000000";
      NUM_LINKS_G         : integer range 1 to 12       := 1;
      TX_PLL_G            : string                      := "QPLL";
      RX_PLL_G            : string                      := "CPLL";
      RX_FIXED_LAT_G      : boolean                     := true;
      RX_REFCLK_G         : string                      := "LOC"  -- "LOC" or "DTM"
      );
   port (

      -- Clocks
      sysClk200 : in sl;

      dtmRefClk  : in sl;
      dtmRefClkG : in sl;
      locRefClk  : in sl;
      locRefClkG : in sl;

      -- AXI Stream Clock
      pgpAxisClk : in sl;
      pgpAxisRst : in sl;

      -- AXI-Stream Control PGP Streams
      ctrlRxMasters : out AxiStreamMasterType;
      ctrlRxSlaves  : in  AxiStreamSlaveType;
      ctrlTxMasters : in  AxiStreamMasterType;
      ctrlTxSlaves  : out AxiStreamSlaveType;

      -- AXI-Lite Bus
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;

      -- System Transmit Clock And Code
      distClk      : in sl;
      distClkRst   : in sl;
      distTxData   : in slv(9 downto 0);
      distTxDataEn : in sl;

      -- RTM High Speed
      dpmToRtmHsP : out slv(NUM_LINKS_G-1 downto 0);
      dpmToRtmHsM : out slv(NUM_LINKS_G-1 downto 0);
      rtmToDpmHsP : in  slv(NUM_LINKS_G-1 downto 0);
      rtmToDpmHsM : in  slv(NUM_LINKS_G-1 downto 0)

      );
end HpsCtrlPgpArray;

architecture STRUCTURE of HpsCtrlPgpArray is

   signal cPllRefClk     : sl;
   signal qPllRefClk     : sl;
   signal qPllOutClk     : slv((NUM_LINKS_G-1)/4 downto 0);
   signal qPllOutRefClk  : slv((NUM_LINKS_G-1)/4 downto 0);
   signal qPllLock       : slv((NUM_LINKS_G-1)/4 downto 0);
   signal qPllLockDetClk : slv((NUM_LINKS_G-1)/4 downto 0);
   signal qPllRefClkLost : slv((NUM_LINKS_G-1)/4 downto 0);
   signal qPllPowerDown  : slv((NUM_LINKS_G-1)/4 downto 0);
   signal qPllReset      : slv(NUM_LINKS_G-1 downto 0);
   signal rxRefClkG      : sl;

   -- Local Signals
   signal pgpAxilReadMaster  : AxiLiteReadMasterArray(NUM_LINKS_G-1 downto 0);
   signal pgpAxilReadSlave   : AxiLiteReadSlaveArray(NUM_LINKS_G-1 downto 0);
   signal pgpAxilWriteMaster : AxiLiteWriteMasterArray(NUM_LINKS_G-1 downto 0);
   signal pgpAxilWriteSlave  : AxiLiteWriteSlaveArray(NUM_LINKS_G-1 downto 0);

   signal ictrlRxMasters : AxiStreamMasterArray(NUM_LINKS_G-1 downto 0);
   signal ictrlRxSlaves  : AxiStreamSlaveArray(NUM_LINKS_G-1 downto 0);
   signal ictrlTxMasters : AxiStreamMasterArray(NUM_LINKS_G-1 downto 0);
   signal ictrlTxSlaves  : AxiStreamSlaveArray(NUM_LINKS_G-1 downto 0);

   signal pgpRxRst        : sl;
   signal ipgpTxClk       : sl;
   signal pgpTxClk        : sl;
   signal pgpTxRst        : sl;
   signal pgpFbClk        : sl;
   signal pgpFbClkG       : sl;
   signal pgpTxMmcmLocked : sl;

   constant MASTERS_CONFIG_C : AxiLiteCrossbarMasterConfigArray :=
      genAxiLiteConfig (NUM_LINKS_G, AXIL_BASE_ADDRESS_G, 20, 16);

   constant QPLL_REFCLK_FREQ_C : real := ite(TX_PLL_G = "QPLL", 125.0E6,
                                             ite(RX_PLL_G = "QPLL" and RX_REFCLK_G = "LOC", 250.0E6,
                                                 ite(RX_PLL_G = "QPLL" and RX_REFCLK_G = "DTM", 125.0E6,
                                                     125.0E6)));  -- Default

   constant QPLL_CFG_C : Gtx7QPllCfgType := getGtx7QPllCfg(QPLL_REFCLK_FREQ_C, 2.5E9);

begin

   assert (RX_REFCLK_G = "LOC" or RX_REFCLK_G = "DTM")
      report "HpsCtrlPgpArray: RX_REFCLK_G must be LOC or RTM" severity failure;

   ----------------------------------
   -- Muiplexers and crossbar
   ----------------------------------

   -- AXI-Lite Crossbar
   U_AxiCrossbar : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => NUM_LINKS_G,
         MASTERS_CONFIG_G   => MASTERS_CONFIG_C)
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilRst,
         sAxiWriteMasters(0) => axilWriteMaster,
         sAxiWriteSlaves(0)  => axilWriteSlave,
         sAxiReadMasters(0)  => axilReadMaster,
         sAxiReadSlaves(0)   => axilReadSlave,
         mAxiWriteMasters    => pgpAxilWriteMaster,
         mAxiWriteSlaves     => pgpAxilWriteSlave,
         mAxiReadMasters     => pgpAxilReadMaster,
         mAxiReadSlaves      => pgpAxilReadSlave
         );



   -- Control stream MUX
   U_CntrlMux : entity surf.AxiStreamMux
      generic map (
         TPD_G         => TPD_G,
         NUM_SLAVES_G  => NUM_LINKS_G,
         PIPE_STAGES_G => 1,
         TDEST_LOW_G   => 4)
      port map (
         axisClk      => pgpAxisClk,
         axisRst      => pgpAxisRst,
         sAxisMasters => ictrlRxMasters,
         sAxisSlaves  => ictrlRxSlaves,
         mAxisMaster  => ctrlRxMasters,
         mAxisSlave   => ctrlRxSlaves);

   -- Control Stream De-Mux
   U_CntrlDeMux : entity surf.AxiStreamDeMux
      generic map (
         TPD_G         => TPD_G,
         NUM_MASTERS_G => NUM_LINKS_G,
         TDEST_HIGH_G  => 7,
         TDEST_LOW_G   => 4)
      port map (
         axisClk      => pgpAxisClk,
         axisRst      => pgpAxisRst,
         sAxisMaster  => ctrlTxMasters,
         sAxisSlave   => ctrlTxSlaves,
         mAxisMasters => ictrlTxMasters,
         mAxisSlaves  => ictrlTxSlaves);

   TxPwrUpRst_1 : entity surf.PwrUpRst
      generic map (
         TPD_G          => TPD_G,
         SIM_SPEEDUP_G  => SIMULATION_G,
         IN_POLARITY_G  => '1',
         OUT_POLARITY_G => '1',
         DURATION_G     => 125000000)
      port map (
         arst   => distClkRst,
         clk    => distClk,
         rstOut => pgpTxRst);

   RxPwrUpRst_1 : entity surf.PwrUpRst
      generic map (
         TPD_G          => TPD_G,
         SIM_SPEEDUP_G => SIMULATION_G,
         IN_POLARITY_G  => '1',
         OUT_POLARITY_G => '1',
         DURATION_G     => 250000000)
      port map (
         arst   => distClkRst,
         clk    => distClk,
         rstOut => pgpRxRst);


   qPllRefClk <= dtmRefClk when TX_PLL_G = "QPLL" else
                 locRefClk when RX_PLL_G = "QPLL" and RX_REFCLK_G = "LOC" else
                 dtmRefClk when RX_PLL_G = "QPLL" and RX_REFCLK_G = "DTM" else
                 '0';

   cPllRefClk <= dtmRefClk when TX_PLL_G = "CPLL" else
                 locRefClk when RX_PLL_G = "CPLL" and RX_REFCLK_G = "LOC" else
                 dtmRefClk when RX_PLL_G = "CPLL" and RX_REFCLK_G = "DTM" else
                 '0';

   rxRefClkG <= dtmRefClkG when RX_REFCLK_G = "DTM" else
                locRefClkG when RX_REFCLK_G = "LOC" else
                '0';

   --------------------------------------------------
   -- PGP Lanes
   --------------------------------------------------
   U_QPllGen : for i in 0 to (NUM_LINKS_G-1)/4 generate
      Gtx7QuadPll_1 : entity surf.Gtx7QuadPll
         generic map (
            SIM_RESET_SPEEDUP_G => "TRUE",
            SIM_VERSION_G       => "4.0",
            QPLL_REFCLK_SEL_G   => "001",
            QPLL_FBDIV_G        => QPLL_CFG_C.QPLL_FBDIV_G,
            QPLL_FBDIV_RATIO_G  => QPLL_CFG_C.QPLL_FBDIV_RATIO_G,
            QPLL_REFCLK_DIV_G   => QPLL_CFG_C.QPLL_REFCLK_DIV_G)
         port map (
            qPllRefClk     => qPllRefClk,
            qPllOutClk     => qPllOutClk(i),
            qPllOutRefClk  => qPllOutRefClk(i),
            qPllLock       => qPllLock(i),
            qPllLockDetClk => sysClk200,
            qPllRefClkLost => qPllRefClkLost(i),
            qPllPowerDown  => '0',
            qPllReset      => qPllReset(i/4));
   end generate U_QPllGen;

   -- 10 Units
   -- Might have more then 1 data VC
   -- If so, combine onto signle dataDma stream
   U_PgpGen : for i in 0 to NUM_LINKS_G-1 generate
      U_PgpLane : entity ldmx.HpsCtrlPgpLane
         generic map (
            TPD_G               => TPD_G,
            SIMULATION_G        => SIMULATION_G,
            SIM_PGP_PORT_NUM_G  => SIM_PGP_PORT_NUM_G + (i*10),
            AXIL_BASE_ADDRESS_G => MASTERS_CONFIG_C(i).baseAddr,
            TX_PLL_G            => TX_PLL_G,
            RX_PLL_G            => RX_PLL_G,
            RX_FIXED_LAT_G      => RX_FIXED_LAT_G,
            QPLL_CFG_G          => QPLL_CFG_C)
         port map (
            pgpRxRst        => pgpRxRst,
            pgpTxClk        => distClk,
            pgpTxRst        => pgpTxRst,
            pgpTxData       => distTxData,
            pgpTxDataEn     => distTxDataEn,
            pgpAxisClk      => pgpAxisClk,
            pgpAxisRst      => pgpAxisRst,
            pgpRxMasters    => ictrlRxMasters(i),
            pgpRxSlaves     => ictrlRxSlaves(i),
            pgpTxMasters    => ictrlTxMasters(i),
            pgpTxSlaves     => ictrlTxSlaves(i),
            axilClk         => axilClk,
            axilRst         => axilRst,
            axilReadMaster  => pgpAxilReadMaster(i),
            axilReadSlave   => pgpAxilReadSlave(i),
            axilWriteMaster => pgpAxilWriteMaster(i),
            axilWriteSlave  => pgpAxilWriteSlave(i),
            sysClk200       => sysClk200,
            cPllRefClk      => cPllRefClk,
            qPllOutRefClk   => qPllOutRefClk(i/4),
            qPllOutClk      => qPllOutClk(i/4),
            qPllLock        => qPllLock(i/4),
            qPllRefClkLost  => qPllRefClkLost(i/4),
            qPllReset       => qPllReset(i),
            rxRefClkG       => rxRefClkG,
            pgpTxMmcmLocked => '1',
            dpmToRtmHsP     => dpmToRtmHsP(i),
            dpmToRtmHsM     => dpmToRtmHsM(i),
            rtmToDpmHsP     => rtmToDpmHsP(i),
            rtmToDpmHsM     => rtmToDpmHsM(i)
            );

   end generate;

end architecture STRUCTURE;


-------------------------------------------------------------------------------
-- Title         : PGP Lane Array For Control DPM
-- File          : HpsDataPgpArray.vhd
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
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.STD_LOGIC_ARITH.all;

library UNISIM;
use UNISIM.VCOMPONENTS.all;


library surf;
use surf.StdRtlPkg.all;
use surf.Pgp2bPkg.all;
use surf.AxiStreamPkg.all;
use surf.AxiLitePkg.all;

library ldmx; 

entity HpsDataPgpArray is
   generic (
      TPD_G                : time                        := 1 ns;
      SIMULATION_G         : boolean                     := false;
      SIM_PGP_PORT_NUM_G   : natural range 1024 to 49151 := 4000;
      HYBRIDS_G            : natural range 1 to 12       := 4;
      AXIL_BASE_ADDRESS_G  : slv(31 downto 0)            := x"00000000";
      DATA_PGP_LINE_RATE_G : real                        := 3.125E9);
   port (
      -- AXI Stream
      pgpClk               : in  sl;
      pgpClkRst            : in  sl;
      dataClk              : in  sl;
      dataClkRst           : in  sl;
      pgpRxAxisQuadMasters : out AxiStreamQuadMasterArray(HYBRIDS_G-1 downto 0);
      pgpRxAxisQuadSlaves  : in  AxiStreamQuadSlaveArray(HYBRIDS_G-1 downto 0);
      pgpRxStatuses        : out slv8Array(HYBRIDS_G-1 downto 0);

      -- AXI Bus
      axilClk         : in  sl;
      axilClkRst      : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;

      -- RTM High Speed
      pgpRefClk   : in  sl;
      dpmToRtmHsP : out slv(HYBRIDS_G-1 downto 0);
      dpmToRtmHsM : out slv(HYBRIDS_G-1 downto 0);
      rtmToDpmHsP : in  slv(HYBRIDS_G-1 downto 0);
      rtmToDpmHsM : in  slv(HYBRIDS_G-1 downto 0)

      );
end HpsDataPgpArray;

architecture STRUCTURE of HpsDataPgpArray is

   -- Local Signals
   signal pgpAxilReadMaster  : AxiLiteReadMasterArray(HYBRIDS_G-1 downto 0);
   signal pgpAxilReadSlave   : AxiLiteReadSlaveArray(HYBRIDS_G-1 downto 0);
   signal pgpAxilWriteMaster : AxiLiteWriteMasterArray(HYBRIDS_G-1 downto 0);
   signal pgpAxilWriteSlave  : AxiLiteWriteSlaveArray(HYBRIDS_G-1 downto 0);

   constant MASTERS_CONFIG_C : AxiLiteCrossbarMasterConfigArray :=
      genAxiLiteConfig (HYBRIDS_G, AXIL_BASE_ADDRESS_G, 20, 16);

begin

   ----------------------------------
   -- Muiplexers and crossbar
   ----------------------------------

   -- AXI-Lite Crossbar
   U_AxiCrossbar : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => HYBRIDS_G,
         MASTERS_CONFIG_G   => MASTERS_CONFIG_C)
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilClkRst,
         sAxiWriteMasters(0) => axilWriteMaster,
         sAxiWriteSlaves(0)  => axilWriteSlave,
         sAxiReadMasters(0)  => axilReadMaster,
         sAxiReadSlaves(0)   => axilReadSlave,
         mAxiWriteMasters    => pgpAxilWriteMaster,
         mAxiWriteSlaves     => pgpAxilWriteSlave,
         mAxiReadMasters     => pgpAxilReadMaster,
         mAxiReadSlaves      => pgpAxilReadSlave
         );


   --------------------------------------------------
   -- PGP Lanes
   --------------------------------------------------

   -- 3 Units
   U_PgpGen : for i in HYBRIDS_G-1 downto 0 generate
      U_PgpLane : entity ldmx.HpsDataPgpLane
         generic map (
            TPD_G                => TPD_G,
            SIMULATION_G         => SIMULATION_G,
            SIM_PGP_PORT_NUM_G   => SIM_PGP_PORT_NUM_G + (i*10),
            AXIL_BASE_ADDRESS_G  => MASTERS_CONFIG_C(i).baseAddr,
            DATA_PGP_LINE_RATE_G => DATA_PGP_LINE_RATE_G)
         port map (
            pgpClk           => pgpClk,
            pgpClkRst        => pgpClkRst,
            dataClk          => dataClk,
            dataClkRst       => dataClkRst,
            pgpRxAxisMasters => pgpRxAxisQuadMasters(i)(1 downto 0),
            pgpRxAxisSlaves  => pgpRxAxisQuadSlaves(i)(1 downto 0),
            pgpRxStatus      => pgpRxStatuses(i),
            axilClk          => axilClk,
            axilClkRst       => axilClkRst,
            axilReadMaster   => pgpAxilReadMaster(i),
            axilReadSlave    => pgpAxilReadSlave(i),
            axilWriteMaster  => pgpAxilWriteMaster(i),
            axilWriteSlave   => pgpAxilWriteSlave(i),
            pgpRefClk        => pgpRefClk,
            dpmToRtmHsP      => dpmToRtmHsP(i),
            dpmToRtmHsM      => dpmToRtmHsM(i),
            rtmToDpmHsP      => rtmToDpmHsP(i),
            rtmToDpmHsM      => rtmToDpmHsM(i));
   end generate;

end architecture STRUCTURE;


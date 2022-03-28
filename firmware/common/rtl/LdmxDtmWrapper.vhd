-------------------------------------------------------------------------------
-- Title         : JLAB TI Wrapper
-- File          : LdmxDtmWrapper.vhd
-- Author        : Ryan Herbst, rherbst@slac.stanford.edu
-- Created       : 07/16/2014
-------------------------------------------------------------------------------
-- Description:
-- Trigger / Timing Distribution
-------------------------------------------------------------------------------
-- Copyright (c) 2014 by Ryan Herbst. All rights reserved.
-------------------------------------------------------------------------------
-- Modification history:
-- 07/16/2014: created.
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_arith.all;
use IEEE.STD_LOGIC_unsigned.all;

library UNISIM;
use UNISIM.VCOMPONENTS.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;

library rce_gen3_fw_lib;
use rce_gen3_fw_lib.RceG3Pkg.all;

library ldmx;

entity LdmxDtmWrapper is
   generic (
      TPD_G            : time             := 1 ns;
      SIMULATION_G     : boolean          := false;
      AXIL_BASE_ADDR_G : slv(31 downto 0) := X"00000000");
   port (

      -- AXI Interface
      axilClk         : in  sl;
      axilClkRst      : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;

      -- System Clocks
      sysClk200    : in sl;
      sysClk200Rst : in sl;
      sysClk125    : in sl;
      sysClk125Rst : in sl;

      -- Ref Clock
      locRefClkP : in sl;
      locRefClkM : in sl;

      -- TS Signals
      dtmToRtmLsP : inout slv(5 downto 0);
      dtmToRtmLsM : inout slv(5 downto 0);

      -- Spare Signals
      plSpareP : inout slv(4 downto 0);
      plSpareM : inout slv(4 downto 0);

      -- Timing Codes
      distClk       : out sl;
      distClkRst    : out sl;
      distDivClk    : out sl;
      distDivClkRst : out sl;
      txData        : out slv(9 downto 0);
      txDataEn      : out sl;
      txReady       : in  sl;
      rxData        : in  Slv10Array(7 downto 0);
      rxDataEn      : in  slv(7 downto 0);

      -- Serial IO
      gtTxP : out sl;
      gtTxN : out sl;
      gtRxP : in  sl;
      gtRxN : in  sl
      );

begin
end LdmxDtmWrapper;

architecture STRUCTURE of LdmxDtmWrapper is


   signal busyOut        : sl;
   signal busyOutReg     : sl;
   signal busySync       : sl;
   signal dpmFbEn        : slv(7 downto 0);
   signal dpmBusy        : slv(7 downto 0);
   signal triggerIn      : sl;
   signal triggerRise    : sl;
   signal triggerArm     : sl;
   signal spillIn        : sl;
   signal spillRise      : sl;
   signal spillArm       : sl;
   signal locRefClk      : sl;
   signal locRefClkG     : sl;
   signal locFbClk       : sl;
   signal idistClk       : sl;
   signal idistClkRst    : sl;
   signal idistDivClk    : sl;
   signal idistDivClkRst : sl;

begin

   -- Unused
   plSpareP <= (others => 'Z');
   plSpareM <= (others => 'Z');

   DTM_RTM2 : OBUFDS
      port map (
         I  => '0',
         O  => dtmToRtmLsP(2),
         OB => dtmToRtmLsM(2));

   DTM_RTM3 : OBUFDS
      port map (
         I  => '0',
         O  => dtmToRtmLsP(3),
         OB => dtmToRtmLsM(3));

   DTM_RTM4 : OBUFDS
      port map (
         I  => '0',
         O  => dtmToRtmLsP(4),
         OB => dtmToRtmLsM(4));

   DTM_RTM5 : OBUFDS
      port map (
         I  => '0',
         O  => dtmToRtmLsP(5),
         OB => dtmToRtmLsM(5));

   -------------------------------------------------------------------------------------------------
   -- PGP block
   -------------------------------------------------------------------------------------------------
   U_LdmxDtmPgp_1 : entity ldmx.LdmxDtmPgp
      generic map (
         TPD_G            => TPD_G,
         SIMULATION_G     => SIMULATION_G,
         AXIL_BASE_ADDR_G => AXIL_BASE_ADDR_G)
      port map (
         axilClk         => axilClk,          -- [in]
         axilRst         => axilClkRst,       -- [in]
         axilReadMaster  => axilReadMaster,   -- [in]
         axilReadSlave   => axilReadSlave,    -- [out]
         axilWriteMaster => axilWriteMaster,  -- [in]
         axilWriteSlave  => axilWriteSlave,   -- [out]
         locRefClkP      => locRefClkP,       -- [in]
         locRefClkM      => locRefClkM,       -- [in]
         gtTxP           => gtTxP,            -- [out]
         gtTxN           => gtTxN,            -- [out]
         gtRxP           => gtRxP,            -- [in]
         gtRxN           => gtRxN,            -- [in]
         refClkOut       => locRefClkG,       -- [out]
         l1a             => triggerIn,        -- [out]
         spill           => spillIn,          -- [out]
         busy            => busySync);        -- [in]

   -----------------------------------
   -- Clock Generation
   -----------------------------------
   distClk       <= idistClk;
   distClkRst    <= idistClkRst;
   distDivClk    <= idistDivClk;
   distDivClkRst <= idistDivClkRst;

   -- Local Ref Clk
--    U_LocRefClk : IBUFDS_GTE2
--       port map(
--          O     => locRefClk,
--          ODIV2 => open,
--          I     => locRefClkP,
--          IB    => locRefClkM,
--          CEB   => '0'
--          );

--    -- Buffer for ref clk
--    U_RefBug : BUFG
--       port map (
--          I => locRefClk,
--          O => locRefClkG
--          );

--    -- PLL

--    U_MMCM_IDELAY : entity surf.ClockManager7
--       generic map(
--          TPD_G              => TPD_G,
--          TYPE_G             => "MMCM",
--          INPUT_BUFG_G       => false,
--          FB_BUFG_G          => true,    -- Without this, will never lock in simulation
--          RST_IN_POLARITY_G  => '1',
--          NUM_CLOCKS_G       => 1,
--          -- MMCM attributes
--          BANDWIDTH_G        => "OPTIMIZED",
--          CLKIN_PERIOD_G     => 8.0,     -- 125 MHz
--          DIVCLK_DIVIDE_G    => 1,       -- 125 MHz
--          CLKFBOUT_MULT_F_G  => 8.0,     -- 1.0GHz =  125 MHz x 8
--          CLKOUT0_DIVIDE_F_G => 5.0)     --  = 200 MHz = 1.0GHz/5
--       port map(
--          clkIn     => locRefClkG,
--          rstIn     => '0',
--          clkOut(0) => iDistClk,
-- --         clkOut(1) => idelayClk,
-- --         rstOut(0) => timingRst125,
--          rstOut(0) => iDistClkRst,
--          locked    => open);



   U_PLL : entity surf.ClockManager7
      generic map (
         TPD_G              => TPD_G,
--         SIMULATION_G       => true,
         FB_BUFG_G          => true,
         INPUT_BUFG_G       => false,
         TYPE_G             => "MMCM",
         NUM_CLOCKS_G       => 2,
         RST_IN_POLARITY_G  => '1',
         BANDWIDTH_G        => "OPTIMIZED",
         CLKIN_PERIOD_G     => 8.0,
         DIVCLK_DIVIDE_G    => 3,
         CLKFBOUT_MULT_F_G  => 31.25,   -- 930Mhz
         CLKOUT0_DIVIDE_F_G => 7.0,     -- 186Mhz
         CLKOUT1_DIVIDE_G   => 35       -- 37.2Mhz
         )
      port map (
         clkIn     => sysClk125,
         rstIn     => '0',
         clkOut(0) => idistClk,
         clkOut(1) => idistDivClk,
         rstOut(0) => idistClkRst,
         rstOut(1) => idistDivClkRst);

   -----------------------------------
   -- Trigger Signal Processing
   -----------------------------------

   U_SynchronizerOneShot_1 : entity surf.SynchronizerOneShot
      generic map (
         TPD_G => TPD_G)
      port map (
         clk     => iDistClk,        -- [in]
         rst     => iDistClkRst,     -- [in]
         dataIn  => triggerIn,       -- [in]
         dataOut => triggerRise);    -- [out]

   U_SynchronizerOneShot_2 : entity surf.SynchronizerOneShot
      generic map (
         TPD_G => TPD_G)
      port map (
         clk     => iDistClk,        -- [in]
         rst     => iDistClkRst,     -- [in]
         dataIn  => spillIn,         -- [in]
         dataOut => spillRise)       -- [out]


   process (idistClk)
   begin
      if rising_edge(idistClk) then
         if idistClkRst = '1' then
            triggerArm <= '0'             after TPD_G;
            spillArm   <= '0'             after TPD_G;
            txData     <= (others => '0') after TPD_G;
            txDataEn   <= '0'             after TPD_G;
         else
            if triggerRise = '1' then
               triggerArm <= '1' after TPD_G;
            elsif txReady = '1' then
               triggerArm <= '0' after TPD_G;
            end if;

            if spillRise = '1' then
               spillArm <= '1' after TPD_G;
            elsif txReady = '1' then
               spillArm <= '0' after TPD_G;
            end if;

            txDataEn  <= spillArm or triggerArm after TPD_G;
            txData(0) <= triggerArm             after TPD_G;
            txData(1) <= spillArm               after TPD_G;

         end if;
      end if;
   end process;

--   dtmToRtmLsM(1) <= triggerReg(2);

-----------------------------------
-- Busy processing
-----------------------------------
   dpmFbEn <= "00000001";

   U_FbGen : for i in 0 to 7 generate
      process (idistClk)
      begin
         if rising_edge(idistClk) then
            if idistClkRst = '1' then
               dpmBusy(i) <= '0' after TPD_G;
            elsif rxDataEn(i) = '1' then
               dpmBusy(i) <= rxData(i)(0) after TPD_G;
            end if;
         end if;
      end process;
   end generate;

   process (idistClk)
   begin
      if rising_edge(idistClk) then
         if idistClkRst = '1' then
            busyOut    <= '0' after TPD_G;
            busyOutReg <= '0' after TPD_G;
         else

            if (dpmBusy and dpmFbEn) = 0 then
               busyOut <= '0' after TPD_G;
            else
               busyOut <= '1' after TPD_G;
            end if;

            busyOutReg <= busyOut after TPD_G;
         --busyOutReg <= not busyOutReg after TPD_G;
         end if;
      end if;
   end process;

   U_Synchronizer_1 : entity surf.Synchronizer
      generic map (
         TPD_G => TPD_G)
      port map (
         clk     => locRefClkG,         -- [in]
         rst     => '0',                -- [in]
         dataIn  => busyOutReg,         -- [in]
         dataOut => busySync);          -- [out]

--   dtmToRtmLsP(1) <= busyOutReg;

end architecture STRUCTURE;


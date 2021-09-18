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
      TPD_G     : time    := 1 ns
      );
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
      distClk    : out sl;
      distClkRst : out sl;
      txData     : out Slv10Array(1 downto 0);
      txDataEn   : out slv(1 downto 0);
      txReady    : in  slv(1 downto 0);
      rxData     : in  Slv10Array(7 downto 0);
      rxDataEn   : in  slv(7 downto 0);

      -- Serial IO
      gtTxP : out sl;
      gtTxN : out sl;
      gtRxP : in  sl;
      gtRxN : in  sl
      );

begin
end LdmxDtmWrapper;

architecture STRUCTURE of LdmxDtmWrapper is

   component LdmxDtmWrapper is
      port (

         -- System Clocks
         sysClk125    : in sl;
         sysClk125Rst : in sl;
         sysClk200    : in sl;
         sysClk200Rst : in sl;

         -- Ref Clock
         locRefClkP : in sl;
         locRefClkM : in sl;

         -- AXI-Lite Interface
         axilClk                 : in  sl;
         axilRst                 : in  sl;
         axilReadMaster_araddr   : in  slv(31 downto 0);
         axilReadMaster_arprot   : in  slv(2 downto 0);
         axilReadMaster_arvalid  : in  sl;
         axilReadMaster_rready   : in  sl;
         axilReadSlave_arready   : out sl;
         axilReadSlave_rdata     : out slv(31 downto 0);
         axilReadSlave_rresp     : out slv(1 downto 0);
         axilReadSlave_rvalid    : out sl;
         axilWriteMaster_awaddr  : in  slv(31 downto 0);
         axilWriteMaster_awprot  : in  slv(2 downto 0);
         axilWriteMaster_awvalid : in  sl;
         axilWriteMaster_wdata   : in  slv(31 downto 0);
         axilWriteMaster_wstrb   : in  slv(3 downto 0);
         axilWriteMaster_wvalid  : in  sl;
         axilWriteMaster_bready  : in  sl;
         axilWriteSlave_awready  : out sl;
         axilWriteSlave_wready   : out sl;
         axilWriteSlave_bresp    : out slv(1 downto 0);
         axilWriteSlave_bvalid   : out sl;

         -- TS Signals
         dtmToRtmLsP : inout slv(5 downto 0);
         dtmToRtmLsM : inout slv(5 downto 0);

         -- Timing Codes
         distClk    : out sl;
         distClkRst : out sl;
         txDataA    : out slv(9 downto 0);
         txDataAEn  : out sl;
         txDataB    : out Slv(9 downto 0);
         txDataBEn  : out sl;
         txReady    : in  slv(1 downto 0);
         rxDataA    : in  slv(9 downto 0);
         rxDataAEn  : in  sl;
         rxDataB    : in  slv(9 downto 0);
         rxDataBEn  : in  sl;
         rxDataC    : in  slv(9 downto 0);
         rxDataCEn  : in  sl;
         rxDataD    : in  slv(9 downto 0);
         rxDataDEn  : in  sl;
         rxDataE    : in  slv(9 downto 0);
         rxDataEEn  : in  sl;
         rxDataF    : in  slv(9 downto 0);
         rxDataFEn  : in  sl;
         rxDataG    : in  slv(9 downto 0);
         rxDataGEn  : in  sl;
         rxDataH    : in  slv(9 downto 0);
         rxDataHEn  : in  sl;

         -- Serial IO
         gtTxP : out sl;
         gtTxN : out sl;
         gtRxP : in  sl;
         gtRxN : in  sl
         );

   end component;

begin

   -- Unused
   plSpareP <= (others=>'Z');
   plSpareM <= (others=>'Z');

   U_LdmxDtm: LdmxDtm
      port map (
         sysClk125                => sysClk125,
         sysClk125Rst             => sysClk125Rst,
         sysClk200                => sysClk200,
         sysClk200Rst             => sysClk200Rst,
         locRefClkP               => locRefClkP,
         locRefClkM               => locRefClkM,
         axilClk                  => axilClk,
         axilRst                  => axilClkRst,
         axilReadMaster_araddr    => axilReadMaster.araddr,
         axilReadMaster_arprot    => axilReadMaster.arprot,
         axilReadMaster_arvalid   => axilReadMaster.arvalid,
         axilReadMaster_rready    => axilReadMaster.rready,
         axilReadSlave_arready    => axilReadSlave.arready,
         axilReadSlave_rdata      => axilReadSlave.rdata,
         axilReadSlave_rresp      => axilReadSlave.rresp,
         axilReadSlave_rvalid     => axilReadSlave.rvalid,
         axilWriteMaster_awaddr   => axilWriteMaster.awaddr,
         axilWriteMaster_awprot   => axilWriteMaster.awprot,
         axilWriteMaster_awvalid  => axilWriteMaster.awvalid,
         axilWriteMaster_wdata    => axilWriteMaster.wdata,
         axilWriteMaster_wstrb    => axilWriteMaster.wstrb,
         axilWriteMaster_wvalid   => axilWriteMaster.wvalid,
         axilWriteMaster_bready   => axilWriteMaster.bready,
         axilWriteSlave_awready   => axilWriteSlave.awready,
         axilWriteSlave_wready    => axilWriteSlave.wready,
         axilWriteSlave_bresp     => axilWriteSlave.bresp,
         axilWriteSlave_bvalid    => axilWriteSlave.bvalid,
         dtmToRtmLsP              => dtmToRtmLsP,
         dtmToRtmLsM              => dtmToRtmLsM,
         distClk                  => distClk,
         distClkRst               => distClkRst,
         txDataA                  => txData(0),
         txDataAEn                => txDataEn(0),
         txDataB                  => txData(1),
         txDataBEn                => txDataEn(1),
         txReadyA                 => txReady(0),
         txReadyB                 => txReady(1),
         rxDataA                  => rxData(0),
         rxDataAEn                => rxDataEn(0),
         rxDataB                  => rxData(1),
         rxDataBEn                => rxDataEn(1),
         rxDataC                  => rxData(2),
         rxDataCEn                => rxDataEn(2),
         rxDataD                  => rxData(3),
         rxDataDEn                => rxDataEn(3),
         rxDataE                  => rxData(4),
         rxDataEEn                => rxDataEn(4),
         rxDataF                  => rxData(5),
         rxDataFEn                => rxDataEn(5),
         rxDataG                  => rxData(6),
         rxDataGEn                => rxDataEn(6),
         rxDataH                  => rxData(7),
         rxDataHEn                => rxDataEn(7),
         gtTxP                    => gtTxP,
         gtTxN                    => gtTxN,
         gtRxP                    => gtRxP,
         gtRxN                    => gtRxN);

end architecture STRUCTURE;


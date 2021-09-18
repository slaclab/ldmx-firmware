-------------------------------------------------------------------------------
-- Title      : LDMX DPM Wrapper Core
-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-- Platform   :
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Wrapper for LdmxDpmCore and user ethernet blocks
-------------------------------------------------------------------------------
-- This file is part of HPS. It is subject to
-- the license terms in the LICENSE.txt file found in the top-level directory
-- of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of HPS, including this file, may be
-- copied, modified, propagated, or distributed except according to the terms
-- contained in the LICENSE.txt file.
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;


library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
use surf.EthMacPkg.all;


library rce_gen3_fw_lib;
use rce_gen3_fw_lib.RceG3Pkg.all;

entity LdmxDpmWrapper is
   generic (
      TPD_G           : time := 1 ns;
      HS_LINK_COUNT_G : natural range 1 to 12 := 4);
   port (
      -- Clocks and Resets
      sysClk125    : in sl;
      sysClk125Rst : in sl;
      sysClk200    : in sl;
      sysClk200Rst : in sl;

      -- External reference clock
      locRefClkP : in sl;
      locRefClkM : in sl;

      -- AXI-Lite Interface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;

      -- DMA Interface (1 Stream on DMA0) -- 64 bits wide (RCEG3_AXIS_DMA_CONFIG_C)
      dmaClk      : out sl;
      dmaRst      : out sl;
      dmaObMaster : in  AxiStreamMasterType;
      dmaObSlave  : out AxiStreamSlaveType;
      dmaIbMaster : out AxiStreamMasterType;
      dmaIbSlave  : in  AxiStreamSlaveType;

      -- High Speed Interface
      dpmToRtmHsP : out slv(HS_LINK_COUNT_G-1 downto 0);
      dpmToRtmHsM : out slv(HS_LINK_COUNT_G-1 downto 0);
      rtmToDpmHsP : in  slv(HS_LINK_COUNT_G-1 downto 0);
      rtmToDpmHsM : in  slv(HS_LINK_COUNT_G-1 downto 0);

      -- COB Timing Interface
      rxData   : in  Slv10Array(1 downto 0);
      rxDataEn : in  slv(1 downto 0);
      txData   : out slv(9 downto 0);
      txDataEn : out sl;
      txReady  : in  sl
   );

end LdmxDpmWrapper;

architecture rtl of LdmxDpmWrapper is

   component LdmxDpm is
      port (
         -- Clocks and Resets
         sysClk125    : in sl;
         sysClk125Rst : in sl;
         sysClk200    : in sl;
         sysClk200Rst : in sl;

         -- External reference clock
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

         -- DMA Interface (1 Stream on DMA0) -- 64 bits wide (RCEG3_AXIS_DMA_CONFIG_C)
         dmaClk             : out sl;
         dmaRst             : out sl;
         dmaObMaster_tValid : in  sl;
         dmaObMaster_tData  : in  slv(63 downto 0);
         dmaObMaster_tStrb  : in  slv(7 downto 0);
         dmaObMaster_tKeep  : in  slv(7 downto 0);
         dmaObMaster_tLast  : in  sl;
         dmaObMaster_tDest  : in  slv(7 downto 0);
         dmaObMaster_tId    : in  slv(7 downto 0);
         dmaObMaster_tUser  : in  slv(63 downto 0);
         dmaObSlave_tReady  : out sl;
         dmaIbMaster_tValid : out sl;
         dmaIbMaster_tData  : out slv(63 downto 0);
         dmaIbMaster_tStrb  : out slv(7 downto 0);
         dmaIbMaster_tKeep  : out slv(7 downto 0);
         dmaIbMaster_tLast  : out sl;
         dmaIbMaster_tDest  : out slv(7 downto 0);
         dmaIbMaster_tId    : out slv(7 downto 0);
         dmaIbMaster_tUser  : out slv(63 downto 0);
         dmaIbSlave_tReady  : in  sl;

         -- High Speed Interface
         dpmToRtmHsP : out slv(HS_LINK_COUNT_G-1 downto 0);
         dpmToRtmHsM : out slv(HS_LINK_COUNT_G-1 downto 0);
         rtmToDpmHsP : in  slv(HS_LINK_COUNT_G-1 downto 0);
         rtmToDpmHsM : in  slv(HS_LINK_COUNT_G-1 downto 0);

         -- COB Timing Interface
         rxDataA   : in  slv(9 downto 0);
         rxDataAEn : in  sl;
         rxDataB   : in  slv(9 downto 0);
         rxDataBEn : in  sl;
         txData    : out slv(9 downto 0);
         txDataEn  : out sl;
         txReady   : in  sl);
   end component;

begin

   U_LdmxDpm: LdmxDpm
      port map (
         sysClk125                => sysClk125,
         sysClk125Rst             => sysClk125Rst,
         sysClk200                => sysClk200,
         sysClk200Rst             => sysClk200Rst,
         locRefClkP               => locRefClkP,
         locRefClkM               => locRefClkM,
         axilClk                  => axilClk,
         axilRst                  => axilRst,
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
         dmaClk                   => dmaClk,
         dmaRst                   => dmaRst,
         dmaObMaster_tValid       => dmaObMaster.tValid,
         dmaObMaster_tData        => dmaObMaster.tData(63 downto 0),
         dmaObMaster_tStrb        => dmaObMaster.tStrb(7 downto 0),
         dmaObMaster_tKeep        => dmaObMaster.tKeep(7 downto 0),
         dmaObMaster_tLast        => dmaObMaster.tLast,
         dmaObMaster_tDest        => dmaObMaster.tDest(7 downto 0),
         dmaObMaster_tId          => dmaObMaster.tId(7 downto 0),
         dmaObMaster_tUser        => dmaObMaster.tUser(63 downto 0),
         dmaObSlave_tReady        => dmaObSlave.tReady,
         dmaIbMaster_tValid       => dmaIbMaster.tValid,
         dmaIbMaster_tData        => dmaIbMaster.tData(63 downto 0),
         dmaIbMaster_tStrb        => dmaIbMaster.tStrb(7 downto 0),
         dmaIbMaster_tKeep        => dmaIbMaster.tKeep(7 downto 0),
         dmaIbMaster_tLast        => dmaIbMaster.tLast,
         dmaIbMaster_tDest        => dmaIbMaster.tDest(7 downto 0),
         dmaIbMaster_tId          => dmaIbMaster.tId(7 downto 0),
         dmaIbMaster_tUser        => dmaIbMaster.tUser(63 downto 0),
         dmaIbSlave_tReady        => dmaIbSlave.tReady,
         dpmToRtmHsP              => dpmToRtmHsP,
         dpmToRtmHsM              => dpmToRtmHsM,
         rtmToDpmHsP              => rtmToDpmHsP,
         rtmToDpmHsM              => rtmToDpmHsM,
         rxDataA                  => rxData(0),
         rxDataAEn                => rxDataEn(0),
         rxDataB                  => rxData(1),
         rxDataBEn                => rxDataEn(1),
         txData                   => txData,
         txDataEn                 => txDataEn,
         txReady                  => txReady);

   -- Undriven Signals
   dmaIbMaster.tData(511 downto 64) <= (others=>'0');
   dmaIbMaster.tStrb(63 downto 8)   <= (others=>'0');
   dmaIbMaster.tKeep(63 downto 8)   <= (others=>'0');
   dmaIbMaster.tUser(511 downto 64) <= (others=>'0');

end architecture rtl;

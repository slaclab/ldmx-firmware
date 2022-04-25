-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : PgpFrontEnd.vhd
-- Author     : Benjamin Reese  <bareese@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2013-08-06
-- Last update: 2019-11-20
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2013 SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
use surf.SsiPkg.all;
use surf.SsiCmdMasterPkg.all;
use surf.Pgp2bPkg.all;


library hps_daq;
use hps_daq.HpsPkg.all;

--entity PgpFrontEndTest is

--   generic (
--      TPD_G                 : time    := 1 ns;
--      SIM_GTRESET_SPEEDUP_G : string  := "FALSE";
--      SIM_VERSION_G         : string  := "1.0";
--      SIMULATION_G          : boolean := false
--      );

--   port (
--      -- Reference clocks for PGP MGTs
--      gtRefClk125 : in sl;
--      gtRefClk250 : in sl;

--      sysGtTxP : out sl;
--      sysGtTxN : out sl;
--      sysGtRxP : in  sl;
--      sysGtRxN : in  sl;

--      dataGtTxP : out slv(3 downto 0);
--      dataGtTxN : out slv(3 downto 0);
--      dataGtRxP : in  slv(3 downto 0);
--      dataGtRxN : in  slv(3 downto 0);

--      daqClk    : in sl;
--      daqClkRst : in sl;

--      pgpClk    : in sl;
--      pgpClkRst : in sl;

--      pgpClk250    : in sl;
--      pgpClk250Rst : in sl;

--      axiClk : in sl;
--      axiRst : in sl;

--      rxLink : out sl;
--      txLink : out sl;

--      dataTxLink : out slv(3 downto 0);

--      -- Command interface for software triggers
--      cmdMaster : out SsiCmdMasterType;

--      -- Axi Master Interface - Registers
--      regAxiReadMaster  : out AxiLiteReadMasterType;
--      regAxiReadSlave   : in  AxiLiteReadSlaveType;
--      regAxiWriteMaster : out AxiLiteWriteMasterType;
--      regAxiWriteSlave  : in  AxiLiteWriteSlaveType;

--      -- Event Data Stream
--      eventAxisMaster : in  AxiStreamMasterType;
--      eventAxisSlave  : out AxiStreamSlaveType;
--      eventAxisCtrl   : out AxiStreamCtrlType;

--      -- Power Status stream
--      pmAxisMaster : in  AxiStreamMasterType;
--      pmAxisSlave  : out AxiStreamSlaveType;
--      pmAxisCtrl   : out AxiStreamCtrlType);

--end entity PgpFrontEndTest;

architecture sim of PgpFrontEndTest is

   -- Sys PGP Signals
   signal sysPgpRxIn          : Pgp2bRxInType;
   signal sysPgpRxOut         : Pgp2bRxOutType;
   signal sysPgpTxIn          : Pgp2bTxInType;
   signal sysPgpTxOut         : Pgp2bTxOutType;
   signal sysPgpTxAxisMasters : AxiStreamMasterArray(3 downto 0);
   signal sysPgpTxAxisSlaves  : AxiStreamSlaveArray(3 downto 0);
   signal sysPgpRxAxisMasters : AxiStreamMasterArray(3 downto 0);
   signal sysPgpRxAxisCtrl    : AxiStreamCtrlArray(3 downto 0);

   signal dataPgpTxReset : slv(3 downto 0);
   signal dataPgpRxIn    : Pgp2bRxInArray(3 downto 0);
   signal dataPgpRxOut   : Pgp2bRxOutArray(3 downto 0);
   signal dataPgpTxIn    : Pgp2bTxInArray(3 downto 0);
   signal dataPgpTxOut   : Pgp2bTxOutArray(3 downto 0);

   type AxiStreamMasterQuadArray is array (natural range <>) of AxiStreamMasterArray(3 downto 0);
   type AxiStreamSlaveQuadArray is array (natural range <>) of AxiStreamSlaveArray(3 downto 0);
   signal prbsTxAxisMasters : AxiStreamMasterQuadArray(3 downto 0);
   signal prbsTxAxisSlaves  : AxiStreamSlaveQuadArray(3 downto 0);

   signal mPgpAxiWriteMasters : AxiLiteWriteMasterArray(4 downto 0);
   signal mPgpAxiWriteSlaves  : AxiLiteWriteSlaveArray(4 downto 0);
   signal mPgpAxiReadMasters  : AxiLiteReadMasterArray(4 downto 0);
   signal mPgpAxiReadSlaves   : AxiLiteReadSlaveArray(4 downto 0);

   signal trigger : sl;
   signal busy    : sl;

begin

   -------------------------------------------------------------------------------------------------
   -- Fixed Latency Pgp Link delivers clock and resets
   -- Hooked up to RegSlave
   -------------------------------------------------------------------------------------------------

   rxLink <= sysPgpRxOut.linkReady;
   txLink <= sysPgpTxOut.linkReady;
--   sysPgpRxIn.flush   <= '0';
--   sysPgpRxIn.resetRx <= '0';

--   sysPgpTxIn.flush        <= '0';
--   sysPgpTxIn.locLinkReady <= sysPgpRxOut.linkReady;
--   sysPgpTxIn.locData      <= (others => '0');
--   sysPgpTxIn.opCodeEn     <= '0';
--   sysPgpTxIn.opCode       <= (others => '0');


   GEN_AXIS_LANE : for i in 3 downto 0 generate
      U_RogueStreamSimWrap_PGP_VC : entity work.RogueStreamSimWrap
         generic map (
            TPD_G         => TPD_G,
            DEST_ID_G     => i,
            AXIS_CONFIG_G => SSI_PGP2B_CONFIG_C)
         port map (
            clk         => pgpClk,              -- [in]
            rst         => pgpRst,              -- [in]
            sAxisClk    => pgpClk,              -- [in]
            sAxisRst    => pgpRst,              -- [in]
            sAxisMaster => sysPgpTxMasters(i),  -- [in]
            sAxisSlave  => sysPgpTxSlaves(i),   -- [out]
            mAxisClk    => pgpClk,              -- [in]
            mAxisRst    => pgpClk,              -- [in]
            mAxisMaster => sysPgpRxMasters(i),  -- [out]
            mAxisSlave  => sysPgpRxSlaves(i));  -- [in]
   end generate GEN_AXIS_LANE;

   U_RogueStreamSimWrap_OPCODE : entity work.RogueStreamSimWrap
      generic map (
         TPD_G         => TPD_G,
         DEST_ID_G     => 4,
         AXIS_CONFIG_G => SSI_PGP2B_CONFIG_C)
      port map (
         clk         => pgpClk,                    -- [in]
         rst         => pgpRst,                    -- [in]
         sAxisClk    => pgpClk,                    -- [in]
         sAxisRst    => pgpRst,                    -- [in]
         sAxisMaster => AXI_STREAM_MASTER_INIT_C,  -- [in]
         sAxisSlave  => open,                      -- [out]
         mAxisClk    => pgpClk,                    -- [in]
         mAxisRst    => pgpRst,                    -- [in]
         mAxisMaster => open,                      -- [out]
         mAxisSlave  => AXI_STREAM_SLAVE_FORCE_C,  -- [in]
         opCode      => sysPgpRxOut.opCode,        -- [out]
         opCodeEn    => sysPgpRxOut.opCodeEn,      -- [out]
         remData     => sysPgpRxOut.remLinkData);  -- [out]

   sysPgpRxOut.phyRxReady   <= '1';
   sysPgpRxOut.linkReady    <= '1';
   sysPgpRxOut.linkPolarity <= (others => '0');
   sysPgpRxOut.frameRx      <= '0';
   sysPgpRxOut.frameRxErr   <= '0';
   sysPgpRxOut.linkDown     <= '0';
   sysPgpRxOut.linkError    <= '0';
   sysPgpRxOut.remLinkReady <= '1';
   sysPgpRxOut.remOverflow  <= (others => '0');
   sysPgpRxOut.remPause     <= (others => '0');

   sysPgpTxOut.locOverflow <= (others => '0');
   sysPgpTxOut.locPause    <= (others => '0');
   sysPgpTxOut.phyTxReady  <= '1';
   sysPgpTxOut.linkReady   <= '1';
   sysPgpTxOut.frameTx     <= '0';
   sysPgpTxOut.frameTxErr  <= '0';



--    PgpSimModel_1 : entity surf.PgpSimModel
--       generic map (
--          TPD_G      => TPD_G,
--          LANE_CNT_G => 1)
--       port map (
--          pgpTxClk         => pgpClk,
--          pgpTxClkRst      => pgpClkRst,
--          pgpTxIn          => sysPgpTxIn,
--          pgpTxOut         => sysPgpTxOut,
--          pgpTxMasters     => sysPgpTxAxisMasters,
--          pgpTxSlaves      => sysPgpTxAxisSlaves,
--          pgpRxClk         => pgpClk,
--          pgpRxClkRst      => pgpClkRst,
--          pgpRxIn          => sysPgpRxIn,
--          pgpRxOut         => sysPgpRxOut,
--          pgpRxMasters     => sysPgpRxAxisMasters,
--          pgpRxMasterMuxed => open,
--          pgpRxCtrl        => sysPgpRxAxisCtrl);


   -------------------------------------------------------------------------------------------------
   -- AXI Master For Register access
   -------------------------------------------------------------------------------------------------
   SsiAxiLiteMaster_1 : entity surf.SsiAxiLiteMaster
      generic map (
         TPD_G               => TPD_G,
         MEMORY_TYPE_G       => "block",
         GEN_SYNC_FIFO_G     => false,
         USE_BUILT_IN_G      => false,
         FIFO_ADDR_WIDTH_G   => 9,
         FIFO_PAUSE_THRESH_G => 2**8,
         AXI_STREAM_CONFIG_G => SSI_PGP2B_CONFIG_C)
      port map (
         sAxisClk            => pgpClk,
         sAxisRst            => pgpClkRst,
         sAxisMaster         => sysPgpRxAxisMasters(0),
         sAxisSlave          => open,
         sAxisCtrl           => sysPgpRxAxisCtrl(0),
         mAxisClk            => pgpClk,
         mAxisRst            => pgpClkRst,
         mAxisMaster         => sysPgpTxAxisMasters(0),
         mAxisSlave          => sysPgpTxAxisSlaves(0),
         axiLiteClk          => axiClk,
         axiLiteRst          => axiRst,
         mAxiLiteWriteMaster => regAxiWriteMaster,
         mAxiLiteWriteSlave  => regAxiWriteSlave,
         mAxiLiteReadMaster  => regAxiReadMaster,
         mAxiLiteReadSlave   => regAxiReadSlave);

   -------------------------------------------------------------------------------------------------
   -- CMD Slave for software triggers
   -------------------------------------------------------------------------------------------------
   SsiCmdMaster_1 : entity surf.SsiCmdMaster
      generic map (
         TPD_G               => TPD_G,
         MEMORY_TYPE_G       => "distributed",
         GEN_SYNC_FIFO_G     => false,
         USE_BUILT_IN_G      => false,
         FIFO_ADDR_WIDTH_G   => 6,
         FIFO_PAUSE_THRESH_G => 2**5,
         AXI_STREAM_CONFIG_G => SSI_PGP2B_CONFIG_C)
      port map (
         axisClk     => pgpClk,
         axisRst     => pgpClkRst,
         sAxisMaster => sysPgpRxAxisMasters(1),
         sAxisSlave  => open,
         sAxisCtrl   => sysPgpRxAxisCtrl(1),
         cmdClk      => daqClk,
         cmdRst      => daqClkRst,
         cmdMaster   => cmdMaster);

   TriggerFilter_1 : entity hps_daq.TriggerFilter
      generic map (
         TPD_G             => TPD_G,
         CLK_PERIOD_G      => 8.0E-9,
         TRIGGER_TIME_G    => 21.0E-6,
         MAX_OUTSTANDING_G => 5)
      port map (
         clk     => daqClk,
         rst     => daqClkRst,
         trigger => trigger,
         busy    => busy);

--   process is
--   begin

--      cmdMaster.opCode <= (others => '0');
--      cmdMaster.valid  <= '0';
--      trigger          <= '0';
--      wait for 250 us;

--      wait for 20 us;
--      while (true) loop
--         wait for 2 us;
--         wait until daqClk = '1';
--         cmdMaster.opCode <= X"5A";
--         cmdMaster.valid  <= not busy;
--         trigger          <= not busy;
--         wait until daqClk = '1';
--         cmdMaster.valid  <= '0';
--         trigger          <= '0';
--         wait until daqClk = '1';
--      end loop;
--   end process;

   -------------------------------------------------------------------------------------------------
   -- Event Data Upstream buffer
   -------------------------------------------------------------------------------------------------
   AxiStreamFifo_EventBuff : entity surf.AxiStreamFifo
      generic map (
         TPD_G               => TPD_G,
         PIPE_STAGES_G       => 1,
         SLAVE_READY_EN_G    => true,
         MEMORY_TYPE_G       => "block",
         GEN_SYNC_FIFO_G     => false,
         FIFO_ADDR_WIDTH_G   => 12,
         FIFO_PAUSE_THRESH_G => 2**12-8,
         SLAVE_AXI_CONFIG_G  => EVENT_SSI_CONFIG_C,
         MASTER_AXI_CONFIG_G => SSI_PGP2B_CONFIG_C)
      port map (
         sAxisClk    => axiClk,
         sAxisRst    => axiRst,
         sAxisMaster => eventAxisMaster,
         sAxisSlave  => eventAxisSlave,
         sAxisCtrl   => eventAxisCtrl,
         mAxisClk    => pgpClk,
         mAxisRst    => pgpClkRst,
         mAxisMaster => sysPgpTxAxisMasters(1),
         mAxisSlave  => sysPgpTxAxisSlaves(1));

   -- RX channel 2 is unused
   sysPgpTxAxisMasters(2) <= AXI_STREAM_MASTER_INIT_C;
   sysPgpRxAxisCtrl(2)    <= AXI_STREAM_CTRL_UNUSED_C;

   -------------------------------------------------------------------------------------------------
   -- No other channels used
   -------------------------------------------------------------------------------------------------
   sysPgpRxAxisCtrl(3)    <= AXI_STREAM_CTRL_UNUSED_C;
   sysPgpTxAxisMasters(3) <= AXI_STREAM_MASTER_INIT_C;

   -------------------------------------------------------------------------------------------------
   -- Upstream data channels
   -------------------------------------------------------------------------------------------------

--   -------------------------------------------------------------------------------------------------
--   -- 4 PGP links at 5 Gbps
--   -- Each attached to a VC UsBuff
--   -------------------------------------------------------------------------------------------------
   sPgpAxiReadSlave  <= AXI_LITE_READ_SLAVE_INIT_C;
   sPgpAxiWriteSlave <= AXI_LITE_WRITE_SLAVE_INIT_C;
--   DATA_CHANNEL_GEN : for i in 0 to 3 generate
--     SsiPrbsTx_1 : entity surf.SsiPrbsTx
--         generic map (
--            TPD_G                      => TPD_G,
--            MEMORY_TYPE_G                  => "block",
--            GEN_SYNC_FIFO_G            => false,
--            FIFO_ADDR_WIDTH_G          => 9,
--            FIFO_PAUSE_THRESH_G        => 2**8,
--            MASTER_AXI_STREAM_CONFIG_G => SSI_PGP2B_CONFIG_C,
--            MASTER_AXI_PIPE_STAGES_G   => 1)
--         port map (
--            mAxisClk     => pgpClk250,
--            mAxisRst     => pgpClk250Rst,
--            mAxisSlave   => prbsTxAxisSlaves(i)(0),
--            mAxisMaster  => prbsTxAxisMasters(i)(0),
--            locClk       => axiClk, -- pgpClk250,
--            locRst       => axiRst, -- pgpClk250Rst,
--            trig         => '1',
--            packetLength => X"000FFFFF",
--            busy         => open,
--            tDest        => X"00",
--            tId          => X"00");

--      prbsTxAxisMasters(i)(3 downto 1) <= (others => AXI_STREAM_MASTER_INIT_C);

--   end generate;

--   -------------------------------------------------------------------------------------------------
--   -- Allow monitoring of PGP module statuses via axi-lite
--   -------------------------------------------------------------------------------------------------
--   Pgp2bAxiAxiCrossbar : entity surf.AxiLiteCrossbar
--      generic map (
--         TPD_G              => TPD_G,
--         NUM_SLAVE_SLOTS_G  => 1,
--         NUM_MASTER_SLOTS_G => 5,
--         MASTERS_CONFIG_G   => (
--            0               => (        -- Control link
--               baseAddr     => AXI_BASE_ADDR_G + X"000",
--               addrBits     => 8,
--               connectivity => X"0001"),
--            1               => (
--               baseAddr     => AXI_BASE_ADDR_G + X"100",
--               addrBits     => 8,
--               connectivity => X"0001"),
--            2               => (
--               baseAddr     => AXI_BASE_ADDR_G + X"200",
--               addrBits     => 8,
--               connectivity => X"0001"),
--            3               => (
--               baseAddr     => AXI_BASE_ADDR_G + X"300",
--               addrBits     => 8,
--               connectivity => X"0001"),
--            4               => (
--               baseAddr     => AXI_BASE_ADDR_G + X"400",
--               addrBits     => 8,
--               connectivity => X"0001")))
--      port map (
--         axiClk              => axiClk,
--         axiClkRst           => axiRst,
--         sAxiWriteMasters(0) => sPgpAxiWriteMaster,
--         sAxiWriteSlaves(0)  => sPgpAxiWriteSlave,
--         sAxiReadMasters(0)  => sPgpAxiReadMaster,
--         sAxiReadSlaves(0)   => sPgpAxiReadSlave,
--         mAxiWriteMasters    => mPgpAxiWriteMasters,
--         mAxiWriteSlaves     => mPgpAxiWriteSlaves,
--         mAxiReadMasters     => mPgpAxiReadMasters,
--         mAxiReadSlaves      => mPgpAxiReadSlaves);

--   CntlPgp2bAxi : entity surf.Pgp2bAxi
--      generic map (
--         TPD_G              => TPD_G,
--         COMMON_TX_CLK_G    => false,
--         COMMON_RX_CLK_G    => false,
--         WRITE_EN_G         => false,
--         AXI_CLK_FREQ_G     => 125.0E+6,
--         STATUS_CNT_WIDTH_G => 32,
--         ERROR_CNT_WIDTH_G  => 4)
--      port map (
--         pgpTxClk        => pgpClk,
--         pgpTxClkRst     => pgpClkRst,
--         pgpTxIn         => sysPgpTxIn,
--         pgpTxOut        => sysPgpTxOut,
----         locTxIn         => ,
--         pgpRxClk        => pgpClk,
--         pgpRxClkRst     => pgpClkRst,
--         pgpRxIn         => sysPgpRxIn,
--         pgpRxOut        => sysPgpRxOut,
----         locRxIn         => ,
--         statusWord      => open,
--         statusSend      => open,
--         axilClk         => axiClk,
--         axilRst         => axiRst,
--         axilReadMaster  => mPgpAxiReadMasters(0),
--         axilReadSlave   => mPgpAxiReadSlaves(0),
--         axilWriteMaster => mPgpAxiWriteMasters(0),
--         axilWriteSlave  => mPgpAxiWriteSlaves(0));

--   DataPgp2bAxiGen : for i in 3 downto 0 generate
--      DataPgp2bAxi : entity surf.Pgp2bAxi
--         generic map (
--            TPD_G              => TPD_G,
--            COMMON_TX_CLK_G    => false,
--            COMMON_RX_CLK_G    => false,
--            WRITE_EN_G         => false,
--            AXI_CLK_FREQ_G     => 125.0E+6,
--            STATUS_CNT_WIDTH_G => 32,
--            ERROR_CNT_WIDTH_G  => 4)
--         port map (
--            pgpTxClk        => pgpClk250,
--            pgpTxClkRst     => pgpClk250Rst,
--            pgpTxIn         => dataPgpTxIn(i),
--            pgpTxOut        => dataPgpTxOut(i),
----         locTxIn         => ,
--            pgpRxClk        => pgpClk250,
--            pgpRxClkRst     => pgpClk250Rst,
--            pgpRxIn         => dataPgpRxIn(i),
--            pgpRxOut        => dataPgpRxOut(i),
----         locRxIn         => ,
--            statusWord      => open,
--            statusSend      => open,
--            axilClk         => axiClk,
--            axilRst         => axiRst,
--            axilReadMaster  => mPgpAxiReadMasters(i+1),
--            axilReadSlave   => mPgpAxiReadSlaves(i+1),
--            axilWriteMaster => mPgpAxiWriteMasters(i+1),
--            axilWriteSlave  => mPgpAxiWriteSlaves(i+1));
--   end generate DataPgp2bAxiGen;

end architecture sim;

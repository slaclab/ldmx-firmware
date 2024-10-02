-------------------------------------------------------------------------------
-- Title      : Trigger Scintillator Data Rx
-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- This file is part of LDMX. It is subject to
-- the license terms in the LICENSE.txt file found in the top-level directory
-- of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of LDMX, including this file, may be
-- copied, modified, propagated, or distributed except according to the terms
-- contained in the LICENSE.txt file.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;

library ldmx_ts;
use ldmx_ts.TsPkg.all;

entity TsDataRxLane is
   generic (
      TPD_G            : time             := 1 ns;
      SIMULATION_G     : boolean          := false;
      AXIL_CLK_FREQ_G  : real             := 125.0e6;
      AXIL_BASE_ADDR_G : slv(31 downto 0) := X"00000000");
   port (
      -- TS Interface
      tsRefClk250  : in  sl;
      tsUserClk250 : in  sl;
      tsUserRst250 : in  sl;
      tsUserClk125 : in  sl;
      tsUserRst125 : in  sl;
      tsDataRxP    : in  sl;
      tsDataRxN    : in  sl;
      tsDataTxP    : out sl;
      tsDataTxN    : out sl;

      tsRecClk : out sl;
      tsRecRst : out sl;
      tsRxMsg  : out TsData6ChMsgType;

      -- Synchronous to tsUserClk250
      tsTxMsg : in TsData6ChMsgType := TS_DATA_6CH_MSG_INIT_C;

      -- AXI Lite interface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType);
end entity TsDataRxLane;

architecture rtl of TsDataRxLane is

   constant NUM_AXIL_C   : natural := 3;
   constant AXIL_GTY_C   : natural := 0;
   constant AXIL_TS_RX_C : natural := 1;
   constant AXIL_TS_TX_C : natural := 2;

   constant AXIL_XBAR_CFG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXIL_C-1 downto 0) := (
      AXIL_GTY_C      => (
         baseAddr     => AXIL_BASE_ADDR_G + X"0000",
         addrBits     => 13,
         connectivity => X"FFFF"),
      AXIL_TS_RX_C    => (
         baseAddr     => AXIL_BASE_ADDR_G + X"2000",
         addrBits     => 8,
         connectivity => X"FFFF"),
      AXIL_TS_TX_C    => (
         baseAddr     => AXIL_BASE_ADDR_G + X"2100",
         addrBits     => 8,
         connectivity => X"FFFF"));


   signal locAxilWriteMasters : AxiLiteWriteMasterArray(NUM_AXIL_C-1 downto 0);
   signal locAxilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXIL_C-1 downto 0) := (others => AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);
   signal locAxilReadMasters  : AxiLiteReadMasterArray(NUM_AXIL_C-1 downto 0);
   signal locAxilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXIL_C-1 downto 0)  := (others => AXI_LITE_READ_SLAVE_EMPTY_DECERR_C);

   signal tsRecClkGt         : sl;
   signal tsRecClkMmcm       : sl;
   signal tsRecClkMmcmLocked : sl;
   signal tsRecClkRst        : sl;

   signal tsRxPhyInit      : sl;
   signal tsRxPhyInitSync  : sl;
   signal tsRxPhyResetDone : sl;
   signal tsRxData         : slv(15 downto 0);
   signal tsRxDataK        : slv(1 downto 0);
   signal tsRxDispErr      : slv(1 downto 0);
   signal tsRxDecErr       : slv(1 downto 0);

   signal tsTxPhyInit      : sl;
   signal tsTxPhyResetDone : sl;
   signal tsTxData         : slv(15 downto 0);
   signal tsTxDataK        : slv(1 downto 0);

   signal loopback     : slv(2 downto 0) := "000";
   signal resetRxPwrUp : sl;
   signal rxReset      : sl;

begin

   -------------------------------------------------------------------------------------------------
   -- AXIL Crossbar
   -------------------------------------------------------------------------------------------------
   U_XBAR : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => NUM_AXIL_C,
         MASTERS_CONFIG_G   => AXIL_XBAR_CFG_C)
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilRst,
         sAxiWriteMasters(0) => axilWriteMaster,
         sAxiWriteSlaves(0)  => axilWriteSlave,
         sAxiReadMasters(0)  => axilReadMaster,
         sAxiReadSlaves(0)   => axilReadSlave,
         mAxiWriteMasters    => locAxilWriteMasters,
         mAxiWriteSlaves     => locAxilWriteSlaves,
         mAxiReadMasters     => locAxilReadMasters,
         mAxiReadSlaves      => locAxilReadSlaves);

   -------------------------------------------------------------------------------------------------
   -- Various Reset synchronization
   -------------------------------------------------------------------------------------------------
   -- Sync phy init to stableClk (axilClk)
--    U_RstSync_1 : entity surf.SynchronizerOneShot
--       generic map (
--          TPD_G         => TPD_G,
--          PULSE_WIDTH_G => ite(SIMULATION_G, 12500, 125000000))  -- 100us in sim; 1s in silicon
--       port map (
--          clk     => axilClk,                                    -- [in]
--          dataIn  => tsRxPhyInit,                                -- [in]
--          dataOut => tsRxPhyInitSync);                           -- [out]

   U_RstSync_1 : entity surf.RstSync
      generic map (
         TPD_G => TPD_G)
      port map (
         clk      => axilClk,
         asyncRst => tsRxPhyInit,
         syncRst  => tsRxPhyInitSync);


   -------------------------------------------------------------------------------------------------
   -- TS Data GTY
   -------------------------------------------------------------------------------------------------
   U_TsGtyIpCoreWrapper_1 : entity ldmx_ts.TsGtyIpCoreWrapper
      generic map (
         TPD_G             => TPD_G,
         SIMULATION_G      => SIMULATION_G,
         USE_ALIGN_CHECK_G => true,
         AXIL_CLK_FREQ_G   => AXIL_CLK_FREQ_G,
         AXIL_BASE_ADDR_G  => AXIL_XBAR_CFG_C(AXIL_GTY_C).baseAddr)
      port map (
         stableClk       => tsUserClk125,                     -- [in]
         stableRst       => tsUserRst125,                     -- [in]
         gtRefClk        => tsRefClk250,                      -- [in]
         gtUserRefClk    => tsUserClk250,                     -- [in]
         gtRxP           => tsDataRxP,                        -- [in]
         gtRxN           => tsDataRxN,                        -- [in]
         gtTxP           => tsDataTxP,                        -- [out]
         gtTxN           => tsDataTxN,                        -- [out]
         rxReset         => rxReset,                          -- [in]
         rxUsrClkActive  => tsRecClkMmcmLocked,               -- [in]
         rxResetDone     => tsRxPhyResetDone,                 -- [out]
         rxUsrClk        => tsRecClkMmcm,                     -- [in]
         rxData          => tsRxData,                         -- [out]
         rxDataK         => tsRxDataK,                        -- [out]
         rxDispErr       => tsRxDispErr,                      -- [out]
         rxDecErr        => tsRxDecErr,                       -- [out]
         rxPolarity      => '0',                              -- [in]
         rxOutClk        => tsRecClkGt,                       -- [out]
         txReset         => tsTxPhyInit,                      -- [in]
         txResetDone     => tsTxPhyResetDone,                 -- [out]
         txData          => tsTxData,                         -- [in]
         txDataK         => tsTxDataK,                        -- [in]
         loopback        => loopback,                         -- [in]
         axilClk         => axilClk,                          -- [in]
         axilRst         => axilRst,                          -- [in]
         axilReadMaster  => locAxilReadMasters(AXIL_GTY_C),   -- [in]
         axilReadSlave   => locAxilReadSlaves(AXIL_GTY_C),    -- [out]
         axilWriteMaster => locAxilWriteMasters(AXIL_GTY_C),  -- [in]
         axilWriteSlave  => locAxilWriteSlaves(AXIL_GTY_C));  -- [out]

   -- Don't need MMCM
   tsRecClkMmcm       <= tsRecClkGt;
   tsRecClkMmcmLocked <= '1';

   RstSync_1 : entity surf.RstSync
      generic map (
         TPD_G           => TPD_G,
         IN_POLARITY_G   => '0',
         OUT_POLARITY_G  => '1',
         RELEASE_DELAY_G => 5)
      port map (
         clk      => tsRecClkMmcm,
         asyncRst => tsRecClkMmcmLocked,
         syncRst  => tsRecClkRst);

   tsRecClk <= tsRecClkMmcm;
   tsRecRst <= tsRecClkRst;

   U_RstSync_2 : entity surf.PwrUpRst
      generic map (
         TPD_G      => TPD_G,
         DURATION_G => 12500)           -- 100us in sim; 1s in silicon
      port map (
         arst   => '0',                 -- [in]
         clk    => axilClk,             -- [in]
         rstOut => resetRxPwrUp);       -- [out]


   rxReset <= tsRxPhyInitSync or resetRxPwrUp;

   -------------------------------------------------------------------------------------------------
   -- TS Message Decoder
   -- Decodes 8b10b stream into TS messages
   -------------------------------------------------------------------------------------------------
   U_TsRxLogic_1 : entity ldmx_ts.TsRxLogic
      generic map (
         TPD_G => TPD_G)
      port map (
         tsClk250         => tsRecClkMmcm,                       -- [in]
         tsRst250         => tsRecClkRst,                        -- [in]
         tsRxPhyInit      => tsRxPhyInit,                        -- [out]
         tsRxPhyResetDone => tsRxPhyResetDone,                   -- [in]
         tsRxPhyLoopback  => loopback,                           -- [out]         
         tsRxData         => tsRxData,                           -- [in]
         tsRxDataK        => tsRxDataK,                          -- [in]
         tsRxDispErr      => tsRxDispErr,                        -- [in]
         tsRxDecErr       => tsRxDecErr,                         -- [in]
         tsRxMsg          => tsRxMsg,                            -- [out]
         axilClk          => axilClk,                            -- [in]
         axilRst          => axilRst,                            -- [in]
         axilReadMaster   => locAxilReadMasters(AXIL_TS_RX_C),   -- [in]
         axilReadSlave    => locAxilReadSlaves(AXIL_TS_RX_C),    -- [out]
         axilWriteMaster  => locAxilWriteMasters(AXIL_TS_RX_C),  -- [in]
         axilWriteSlave   => locAxilWriteSlaves(AXIL_TS_RX_C));  -- [out]

   -------------------------------------------------------------------------------------------------
   -- TS Message Encoder
   -------------------------------------------------------------------------------------------------
   U_TsTxLogic_1 : entity ldmx_ts.TsTxLogic
      generic map (
         TPD_G => TPD_G)
      port map (
         tsClk250         => tsUserClk250,                       -- [in]
         tsRst250         => '0',                                -- [in] Add this back
         tsTxPhyInit      => tsTxPhyInit,                        -- [out]
         tsTxPhyResetDone => tsTxPhyResetDone,                   -- [in]
         tsTxMsg          => tsTxMsg,                            -- [in]
         tsTxData         => tsTxData,                           -- [out]
         tsTxDataK        => tsTxDataK,                          -- [out]
         axilClk          => axilClk,                            -- [in]
         axilRst          => axilRst,                            -- [in]
         axilReadMaster   => locAxilReadMasters(AXIL_TS_TX_C),   -- [in]
         axilReadSlave    => locAxilReadSlaves(AXIL_TS_TX_C),    -- [out]
         axilWriteMaster  => locAxilWriteMasters(AXIL_TS_TX_C),  -- [in]
         axilWriteSlave   => locAxilWriteSlaves(AXIL_TS_TX_C));  -- [out]

end architecture rtl;

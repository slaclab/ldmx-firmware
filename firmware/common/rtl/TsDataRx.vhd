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

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;

library ldmx;
use ldmx.FcPkg.all;
use ldmx.TsPkg.all;

entity TsDataRx is
   generic (
      TPD_G            : time             := 1 ns;
      AXIL_CLK_FREQ_G  : real             := 125.0e6;
      AXIL_BASE_ADDR_G : slv(31 downto 0) := X"00000000");
   port (
      -- TS Interface
      tsRefClkP : in sl;
      tsRefClkN : in sl;
      tsRxP     : in sl;
      tsRxN     : in sl;

      -- Fast Control Interface
      fcClk185 : in sl;
      fcRst185 : in sl;
      fcBus    : in FastControlBusType;

      -- TS data synchronized to fcClk
      -- and corresponding fcMsg
      fcTsRxMsg : out TsData6ChMsgType;
      fcMsgTime : out FcTimestampType;

      -- AXI Lite interface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType);


end entity TsDataRx;

architecture rtl of TsDataRx is

   -- AXI Lite
   constant NUM_AXIL_MASTERS_C   : natural := 3;
   constant AXIL_GTY_C           : natural := 0;
   constant AXIL_TS_RX_LOGIC_C   : natural := 1;
   constant AXIL_TS_RX_ALIGNER_C : natural := 2;

   constant AXIL_XBAR_CFG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXIL_MASTERS_C-1 downto 0) := (
      AXIL_GTY_C           => (
         baseAddr          => AXIL_BASE_ADDR_G + X"0_0000",
         addrBits          => 16,
         connectivity      => X"FFFF"),
      AXIL_TS_RX_LOGIC_C   => (
         baseAddr          => AXIL_BASE_ADDR_G + X"1_0000",
         addrBits          => 8,
         connectivity      => X"FFFF"),
      AXIL_TS_RX_ALIGNER_C => (
         baseAddr          => AXIL_BASE_ADDR_G + X"1_0100",
         addrBits          => 8,
         connectivity      => X"FFFF"));

   signal locAxilWriteMasters : AxiLiteWriteMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal locAxilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0) := (others => AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);
   signal locAxilReadMasters  : AxiLiteReadMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal locAxilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0)  := (others => AXI_LITE_READ_SLAVE_EMPTY_DECERR_C);

   signal tsPhyInit      : sl;
   signal tsPhyInitSync  : sl;
   signal tsRefClkOdiv2  : sl;
   signal tsRefClk       : sl;
   signal tsUserRefClk   : sl;
   signal tsPhyResetDone : sl;
   signal tsRxData       : slv(15 downto 0);
   signal tsRxDataK      : slv(1 downto 0);
   signal tsRxMsg        : TsData6ChMsgType;


begin

   -------------------------------------------------------------------------------------------------
   -- AXIL Crossbar
   -------------------------------------------------------------------------------------------------
   U_XBAR : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => NUM_AXIL_MASTERS_C,
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
   U_RstSync_1 : entity surf.SynchronizerOneShot
      generic map (
         TPD_G         => TPD_G,
         PULSE_WIDTH_G => ite(SIMULATION_G, 12500, 125000000))  -- 100us in sim; 1s in silicon
      port map (
         clk     => axilClk,                                    -- [in]
         dataIn  => tsPhyInit,                                  -- [in]
         dataOut => tsPhyInitSync);                             -- [out]

   -------------------------------------------------------------------------------------------------
   -- REFCLK Buffer
   -------------------------------------------------------------------------------------------------
   REFCLK_BUFS : for i in FC_HUB_REFCLKS_G-1 downto 0 generate
      U_mgtRefClk : IBUFDS_GTE4
         generic map (
            REFCLK_EN_TX_PATH  => '0',
            REFCLK_HROW_CK_SEL => "00",  -- 2'b00: ODIV2 = O
            REFCLK_ICNTL_RX    => "00")
         port map (
            I     => tsRefClkP,
            IB    => tsRefClkN,
            CEB   => '0',
            ODIV2 => tsRefClkOdiv2,
            O     => tsRefClk);

      U_mgtUserRefClk : BUFG_GT
         port map (
            I       => tsRefClkOdiv2,
            CE      => '1',
            CEMASK  => '1',
            CLR     => '0',
            CLRMASK => '1',
            DIV     => "000",
            O       => tsUserRefClk);
   end generate;

   -------------------------------------------------------------------------------------------------
   -- TS Data GTY
   -------------------------------------------------------------------------------------------------
   U_TsGtyIpCoreWrapper_1 : entity ldmx.TsGtyIpCoreWrapper
      generic map (
         TPD_G               => TPD_G,
         SEL_FABRIC_REFCLK_G => false,
         USE_ALIGN_CHECK_G   => true,
         AXIL_CLK_FREQ_G     => AXIL_CLK_FREQ_G,
         AXIL_BASE_ADDR_G    => AXIL_BASE_ADDR_G)
      port map (
         stableClk       => axilClk,                          -- [in]
         stableRst       => axilRst,                          -- [in]
         gtRefClk        => tsRefClk,                         -- [in]
         gtFabricRefClk  => '0',                              -- [in]
         gtUserRefClk    => tsUserRefClk,                     -- [in]
         gtRxP           => tsRxP,                            -- [in]
         gtRxN           => tsRxN,                            -- [in]
         gtTxP           => tsTxP,                            -- [out]
         gtTxN           => tsTxN,                            -- [out]
         rxReset         => tsPhyInitSync,                    -- [in]
         rxUsrClkActive  => tsRecClkMmcmLocked,               -- [in]
         rxResetDone     => tsPhyResetDone,                   -- [out]
         rxUsrClk        => tsRecClkMmcm,                     -- [in]
         rxData          => tsRxData,                         -- [out]
         rxDataK         => tsRxDataK,                        -- [out]
         rxDispErr       => tsRxDispErr,                      -- [out]
         rxDecErr        => tsRxDecErr,                       -- [out]
         rxPolarity      => '0',                              -- [in]
         rxOutClk        => tsRecClk,                         -- [out]
         txReset         => '1',                              -- [in]
         txUsrClk        => tsUserRefClk,                     -- [in]
         txUsrClkActive  => '1',                              -- [in]
         txResetDone     => open,                             -- [out]
         txData          => (others => '0'),                  -- [in]
         txDataK         => (others => '0'),                  -- [in]
         txPolarity      => '0',                              -- [in]
         txOutClk        => open,                             -- [out]
         loopback        => (others => '0'),                  -- [in]
         axilClk         => axilClk,                          -- [in]
         axilRst         => axilRst,                          -- [in]
         axilReadMaster  => locAxilReadMasters(AXIL_GTY_C),   -- [in]
         axilReadSlave   => locAxilReadSlaves(AXIL_GTY_C),    -- [out]
         axilWriteMaster => locAxilWriteMasters(AXIL_GTY_C),  -- [in]
         axilWriteSlave  => locAxilWriteSlaves(AXIL_GTY_C));  -- [out]

   -- For now don't use MMCM
   tsRecClkMmcm       <= tsRecClk;
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

   -------------------------------------------------------------------------------------------------
   -- TS Message Decoder
   -- Decodes 8b10b stream into TS messages
   -------------------------------------------------------------------------------------------------
   U_TsRxLogic_1 : entity ldmx.TsRxLogic
      generic map (
         TPD_G => TPD_G)
      port map (
         tsClk250        => tsRecClkMmcm,                             -- [in]
         tsRst250        => tsRecClkRst,                              -- [in]
         tsPhyInit       => tsPhyInit,                                -- [out]
         tsPhyResetDone  => tsPhyResetDone,                           -- [in]
         tsRxData        => tsRxData,                                 -- [in]
         tsRxDataK       => tsRxDataK,                                -- [in]
         tsRxMsg         => tsRxMsg,                                  -- [out]
         axilClk         => axilClk,                                  -- [in]
         axilRst         => axilRst,                                  -- [in]
         axilReadMaster  => locAxilReadMasters(AXIL_TS_RX_LOGIC_C),   -- [in]
         axilReadSlave   => locAxilReadSlaves(AXIL_TS_RX_LOGIC_C),    -- [out]
         axilWriteMaster => locAxilWriteMasters(AXIL_TS_RX_LOGIC_C),  -- [in]
         axilWriteSlave  => locAxilWriteSlaves(AXIL_TS_RX_LOGIC_C));  -- [out]

   -------------------------------------------------------------------------------------------------
   -- TS Message Aligner
   -- Aligns messages with Fast Control
   -------------------------------------------------------------------------------------------------
   U_TsRxMsgAligner_1 : entity ldmx.TsRxMsgAligner
      generic map (
         TPD_G => TPD_G)
      port map (
         tsClk250        => tsRecClkMmcm,                               -- [in]
         tsRst250        => tsRecClkRst,                                -- [in]
         tsRxMsg         => tsRxMsg,                                    -- [in]
         fcClk185        => fcClk185,                                   -- [in]
         fcRst185        => fcRst185,                                   -- [in]
         fcBus           => fcBus,                                      -- [in]
         fcTsRxMsg       => fcTsRxMsg,
         fcMsgTime       => fcMsgTime,
         axilClk         => axilClk,                                    -- [in]
         axilRst         => axilRst,                                    -- [in]
         axilReadMaster  => locAxilReadMasters(AXIL_TS_RX_ALIGNER_C),   -- [in]
         axilReadSlave   => locAxilReadSlaves(AXIL_TS_RX_ALIGNER_C),    -- [out]
         axilWriteMaster => locAxilWriteMasters(AXIL_TS_RX_ALIGNER_C),  -- [in]
         axilWriteSlave  => locAxilWriteSlaves(AXIL_TS_RX_ALIGNER_C));  -- [out]
end architecture rtl;

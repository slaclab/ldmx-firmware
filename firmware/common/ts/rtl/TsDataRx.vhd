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
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;

library ldmx_tdaq;
use ldmx_tdaq.FcPkg.all;

library ldmx_ts;
use ldmx_ts.TsPkg.all;

entity TsDataRx is
   generic (
      TPD_G            : time             := 1 ns;
      SIMULATION_G     : boolean          := false;
      TS_LANES_G       : integer          := 2;
      TS_REFCLKS_G     : integer          := 1;
      TS_REFCLK_MAP_G  : IntegerArray     := (0 => 0, 1 => 0);  -- Map a refclk index to each fiber
      AXIL_CLK_FREQ_G  : real             := 125.0e6;
      AXIL_BASE_ADDR_G : slv(31 downto 0) := X"00000000");
   port (
      -- TS Interface
      tsRefClk250P : in slv(TS_REFCLKS_G-1 downto 0);
      tsRefClk250N : in slv(TS_REFCLKS_G-1 downto 0);
      tsDataRxP    : in slv(TS_LANES_G-1 downto 0);
      tsDataRxN    : in slv(TS_LANES_G-1 downto 0);
      tsDataTxP    : out slv(TS_LANES_G-1 downto 0);
      tsDataTxN    : out slv(TS_LANES_G-1 downto 0);

      -- Fast Control Interface
      fcClk185 : in sl;
      fcRst185 : in sl;
      fcBus    : in FcBusType;

      -- TS data synchronized to fcClk
      -- and corresponding fcMsg
      fcTsRxMsgs : out TsData6ChMsgArray(TS_LANES_G-1 downto 0);
      fcMsgTime  : out FcTimestampType;

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
   constant NUM_AXIL_MASTERS_C      : natural := 3;
   constant AXIL_TS_RX_LANE_ARRAY_C : natural := 0;
   constant AXIL_TS_RX_ALIGNER_C    : natural := 1;
   constant AXIL_TS_TX_PLAYBACK_C   : natural := 2;

   constant AXIL_XBAR_CFG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXIL_MASTERS_C-1 downto 0) := (
      AXIL_TS_RX_LANE_ARRAY_C => (
         baseAddr             => AXIL_BASE_ADDR_G + X"00_0000",
         addrBits             => 20,
         connectivity         => X"FFFF"),
      AXIL_TS_RX_ALIGNER_C    => (
         baseAddr             => AXIL_BASE_ADDR_G + X"10_0000",
         addrBits             => 8,
         connectivity         => X"FFFF"),
      AXIL_TS_TX_PLAYBACK_C   => (
         baseAddr             => AXIL_BASE_ADDR_G + X"1000_0000",
         addrBits             => 28,
         connectivity         => X"FFFF"));



   signal locAxilWriteMasters : AxiLiteWriteMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal locAxilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0) := (others => AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);
   signal locAxilReadMasters  : AxiLiteReadMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal locAxilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0)  := (others => AXI_LITE_READ_SLAVE_EMPTY_DECERR_C);

   -- Local signals
   signal tsRecClks : slv(TS_LANES_G-1 downto 0);
   signal tsRecRsts : slv(TS_LANES_G-1 downto 0);
   signal tsRxMsgs  : TsData6ChMsgArray(TS_LANES_G-1 downto 0);

   signal tsTxClks : slv(TS_LANES_G-1 downto 0);
   signal tsTxRsts : slv(TS_LANES_G-1 downto 0);
   signal tsTxMsgs : TsData6ChMsgArray(TS_LANES_G-1 downto 0);



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
   -- TS Lanes
   -------------------------------------------------------------------------------------------------
   U_TsDataRxLaneArray_1 : entity ldmx_ts.TsDataRxLaneArray
      generic map (
         TPD_G            => TPD_G,
         SIMULATION_G     => SIMULATION_G,
         TS_LANES_G       => TS_LANES_G,
         TS_REFCLKS_G     => TS_REFCLKS_G,
         TS_REFCLK_MAP_G  => TS_REFCLK_MAP_G,
         AXIL_CLK_FREQ_G  => AXIL_CLK_FREQ_G,
         AXIL_BASE_ADDR_G => AXIL_XBAR_CFG_C(AXIL_TS_RX_LANE_ARRAY_C).baseAddr)
      port map (
         tsRefClk250P    => tsRefClk250P,                                  -- [in]
         tsRefClk250N    => tsRefClk250N,                                  -- [in]
         tsDataRxP       => tsDataRxP,                                     -- [in]
         tsDataRxN       => tsDataRxN,                                     -- [in]
         tsDataTxP       => tsDataTxP,                                     -- [out]
         tsDataTxN       => tsDataTxN,                                     -- [out]
         tsRecClks       => tsRecClks,                                     -- [out]
         tsRecRsts       => tsRecRsts,                                     -- [out]
         tsRxMsgs        => tsRxMsgs,                                      -- [out]
         tsTxClks        => tsTxClks,                                      -- [out]
         tsTxRsts        => tsTxRsts,                                      -- [out]
         tsTxMsgs        => tsTxMsgs,                                      -- [in]
         axilClk         => axilClk,                                       -- [in]
         axilRst         => axilRst,                                       -- [in]
         axilReadMaster  => locAxilReadMasters(AXIL_TS_RX_LANE_ARRAY_C),   -- [in]
         axilReadSlave   => locAxilReadSlaves(AXIL_TS_RX_LANE_ARRAY_C),    -- [out]
         axilWriteMaster => locAxilWriteMasters(AXIL_TS_RX_LANE_ARRAY_C),  -- [in]
         axilWriteSlave  => locAxilWriteSlaves(AXIL_TS_RX_LANE_ARRAY_C));  -- [out]

   -------------------------------------------------------------------------------------------------
   -- TS Message Playback
   -------------------------------------------------------------------------------------------------
   U_TsTxMsgPlayback_1 : entity ldmx_ts.TsTxMsgPlayback
      generic map (
         TPD_G            => TPD_G,
         TS_LANES_G       => TS_LANES_G,
         AXIL_BASE_ADDR_G => AXIL_XBAR_CFG_C(AXIL_TS_TX_PLAYBACK_C).baseAddr)
      port map (
         tsTxClks        => tsTxClks,                                    -- [in]
         tsTxRsts        => tsTxRsts,                                    -- [in]
         tsTxMsgs        => tsTxMsgs,                                    -- [out]
         fcClk185        => fcClk185,                                    -- [in]
         fcRst185        => fcRst185,                                    -- [in]
         fcBus           => fcBus,                                       -- [in]
         axilClk         => axilClk,                                     -- [in]
         axilRst         => axilRst,                                     -- [in]
         axilReadMaster  => locAxilReadMasters(AXIL_TS_TX_PLAYBACK_C),   -- [in]
         axilReadSlave   => locAxilReadSlaves(AXIL_TS_TX_PLAYBACK_C),    -- [out]
         axilWriteMaster => locAxilWriteMasters(AXIL_TS_TX_PLAYBACK_C),  -- [in]
         axilWriteSlave  => locAxilWriteSlaves(AXIL_TS_TX_PLAYBACK_C));  -- [out]

   -------------------------------------------------------------------------------------------------
   -- TS Message Aligner
   -- Aligns messages with Fast Control
   -------------------------------------------------------------------------------------------------
   U_TsRxMsgAligner_1 : entity ldmx_ts.TsRxMsgAligner
      generic map (
         TPD_G      => TPD_G,
         TS_LANES_G => TS_LANES_G)
      port map (
         tsRecClks       => tsRecClks,                                  -- [in]
         tsRecRsts       => tsRecRsts,                                  -- [in]
         tsRxMsgs        => tsRxMsgs,                                   -- [in]
         fcClk185        => fcClk185,                                   -- [in]
         fcRst185        => fcRst185,                                   -- [in]
         fcBus           => fcBus,                                      -- [in]
         fcTsRxMsgs      => fcTsRxMsgs,                                 -- [out]
         fcMsgTime       => fcMsgTime,                                  -- [out]
         axilClk         => axilClk,                                    -- [in]
         axilRst         => axilRst,                                    -- [in]
         axilReadMaster  => locAxilReadMasters(AXIL_TS_RX_ALIGNER_C),   -- [in]
         axilReadSlave   => locAxilReadSlaves(AXIL_TS_RX_ALIGNER_C),    -- [out]
         axilWriteMaster => locAxilWriteMasters(AXIL_TS_RX_ALIGNER_C),  -- [in]
         axilWriteSlave  => locAxilWriteSlaves(AXIL_TS_RX_ALIGNER_C));  -- [out]

end architecture rtl;

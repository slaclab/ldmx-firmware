-------------------------------------------------------------------------------
-- Title      : 
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

library ldmx_tdaq;
use ldmx_tdaq.FcPkg.all;

library ldmx_ts;
use ldmx_ts.TsPkg.all;

entity TsTxMsgPlayback is

   generic (
      TPD_G            : time             := 1 ns;
      TS_LANES_G       : integer          := 2;
      AXIL_BASE_ADDR_G : slv(31 downto 0) := (others => '0'));
   port (
      --------------
      -- Main Output
      --------------
      tsTxClks : in  slv(TS_LANES_G-1 downto 0);
      tsTxRsts : in  slv(TS_LANES_G-1 downto 0);
      tsTxMsgs : out TsData6ChMsgArray(TS_LANES_G-1 downto 0);

      -----------------------------
      -- Fast Control clock and bus
      -----------------------------
      fcClk185 : in sl;
      fcRst185 : in sl;
      fcBus    : in FcBusType;

      -- Axil inteface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType  := AXI_LITE_READ_SLAVE_EMPTY_DECERR_C;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType := AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);

end entity TsTxMsgPlayback;

architecture rtl of TsTxMsgPlayback is

   constant NUM_AXIL_MASTERS_C : natural := TS_LANES_G;

   constant AXIL_XBAR_CFG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXIL_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXIL_MASTERS_C, AXIL_BASE_ADDR_G, 28, 20);

   signal locAxilWriteMasters : AxiLiteWriteMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal locAxilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal locAxilReadMasters  : AxiLiteReadMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal locAxilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0);

begin

   ---------------------
   -- AXI-Lite Crossbar
   ---------------------
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

   GEN_LANES : for i in TS_LANES_G-1 downto 0 generate
      U_TsTxMsgPlaybackLane_1 : entity ldmx_ts.TsTxMsgPlaybackLane
         generic map (
            TPD_G            => TPD_G,
            AXIL_BASE_ADDR_G => AXIL_XBAR_CFG_C(i).baseAddr)
         port map (
            tsTxClk         => tsTxClks(i),             -- [in]
            tsTxRst         => tsTxRsts(i),             -- [in]
            tsTxMsg         => tsTxMsgs(i),             -- [out]
            fcClk185        => fcClk185,                -- [in]
            fcRst185        => fcRst185,                -- [in]
            fcBus           => fcBus,                   -- [in]
            axilClk         => axilClk,                 -- [in]
            axilRst         => axilRst,                 -- [in]
            axilReadMaster  => locAxilReadMasters(i),   -- [in]
            axilReadSlave   => locAxilReadSlaves(i),    -- [out]
            axilWriteMaster => locAxilWriteMasters(i),  -- [in]
            axilWriteSlave  => locAxilWriteSlaves(i));  -- [out]
   end generate GEN_LANES;

end rtl;



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
use ldmx.FcPkg.all;

library ldmx_ts;
use ldmx.TsPkg.all;


entity TsTxMsgPlaybackLane is

   generic (
      TPD_G : time := 1 ns);
   port (
      --------------
      -- Main Output
      --------------
      tsTxClk : in  sl;
      tsTxRst : in  sl;
      tsTxMsg : out TsData6ChMsgType;

      -----------------------------
      -- Fast Control clock and bus
      -----------------------------
      fcClk185 : in sl;
      fcRst185 : in sl;
      fcBus    : in FastControlBusType;

      -- Axil inteface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType  := AXI_LITE_READ_SLAVE_EMPTY_DECERR_C;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType := AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);

end entity TsTxMsgPlaybackLane;

architecture rtl of TsTxMsgPlaybackLane is

   constant NUM_CHANNELS_C : integer := 6;


   type StateType is (
      WAIT_CLOCK_ALIGN_S,
      WAIT_BC0_S,
      ALIGNED_S);

   -- fcClk185 signals
   type RegType is record
      state : StateType;
   end record RegType;

   constant REG_INIT_C : RegType := (
      state => WAIT_CLOCK_ALIGN_S);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;


begin

   -------------------------------------------------------------------------------------------------
   -- Make a RAM for each TS channel (6 or 8)
   -------------------------------------------------------------------------------------------------
   GEN_RAM : for i in NUM_CHANNELS_C-1 downto 0 generate
      U_AxiDualPortRam_1 : entity surf.AxiDualPortRam
         generic map (
            TPD_G            => TPD_G,
            SYNTH_MODE_G     => "inferred",
            MEMORY_TYPE_G    => "block",
            READ_LATENCY_G   => 3,
            AXI_WR_EN_G      => true,
            SYS_WR_EN_G      => false,
            SYS_BYTE_WR_EN_G => false,
            COMMON_CLK_G     => false,
            ADDR_WIDTH_G     => 14,
            DATA_WIDTH_G     => 16)
         port map (
            axiClk         => axilClk,                 -- [in]
            axiRst         => axilRst,                 -- [in]
            axiReadMaster  => ramAxilReadMasters(i),   -- [in]
            axiReadSlave   => ramAxilReadSlaves(i),    -- [out]
            axiWriteMaster => ramAxilWriteMasters(i),  -- [in]
            axiWriteSlave  => ramAxilWriteSlaves(i),   -- [out]
            clk            => fcClk185,                -- [in]
            rst            => fcRst185,                -- [in]
            addr           => r.ramAddr,               -- [in]
            dout           => ramDout(i));             -- [out]
   end generate GEN_RAM;

   comb : process (fcRst185, r) is
      variable v : RegType := REG_INIT_C;
   begin
      v := r;

      -- Read RAM entries on FC clock
      -- Format into TS Messages
      -- Place message into a FIFO


      -- Reset
      if (fcRst185 = '1') then
         v := REG_INIT_C;
      end if;

      -- Outputs
      fcTsRxMsgs <= r.fcTsRxMsgs;
      fcMsgTime  <= r.fcMsgTime;

      rin <= v;


   end process comb;

   seq : process (fcClk185) is
   begin
      if (rising_edge(fcClk185)) then
         r <= rin after TPD_G;
      end if;
   end process seq;


end rtl;



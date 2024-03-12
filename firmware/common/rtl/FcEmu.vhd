-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: Fast Control Message Emulator
--
-------------------------------------------------------------------------------
-- This file is part of 'LDMX'.
-- It is subject to the license terms in the LICENSE.txt file found in the
-- top-level directory of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of 'LDMX', including this file,
-- may be copied, modified, propagated, or distributed except according to
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiStreamPkg.all;
use surf.AxiLitePkg.all;

library ldmx;
use ldmx.FcPkg.all;

entity FcEmu is
   generic (
      TPD_G                : time    := 1 ns;
      AXIL_CLK_IS_FC_CLK_G : boolean := false;
      TIMING_MSG_PERIOD_G  : natural := 2400;  -- should fit in 32 bits
      BUNCH_CNT_PERIOD_G   : natural := 5);   -- should fit in 6 bits
   port (
      -- Clock and Reset
      fcClk           : in  sl;
      fcRst           : in  sl;
      -- Fast-Control Message Interface
      fcMsg           : out FastControlMessageType;
      -- Bunch Clock
      bunchClk        : out sl;
      bunchStrobe     : out sl;
      -- AXI-Lite Interface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType);
end FcEmu;

architecture rtl of FcEmu is

   type RegType is record
      enableTimingMsg    : sl;
      enableRoR          : sl;
      usrRoR             : sl;
      timingMsgReq       : sl;
      bunchCntStrb       : sl;
      bunchClk           : sl;
      fcMsg              : FastControlMessageType;
      pulseIDinit        : slv(63 downto 0);
      fcRunStateSet      : slv(4 downto 0);
      bunchCntPeriodCnt  : slv(5 downto 0);
      bunchCntPeriodSet  : slv(5 downto 0);
      bunchCntPeriod     : slv(5 downto 0);
      timingMsgPeriodCnt : slv(31 downto 0);
      timingMsgPeriodSet : slv(31 downto 0);
      timingMsgPeriod    : slv(31 downto 0);
      rOrPeriodCnt       : slv(31 downto 0);
      rOrPeriod          : slv(31 downto 0);
      axilReadSlave      : AxiLiteReadSlaveType;
      axilWriteSlave     : AxiLiteWriteSlaveType;
   end record RegType;

   constant REG_INIT_C : RegType := (
      enableTimingMsg    => '1',
      enableRoR          => '1',
      usrRoR             => '0',
      timingMsgReq       => '0',
      bunchCntStrb       => '0',
      bunchClk           => '0',
      fcMsg              => DEFAULT_FC_MSG_C,
      pulseIDinit        => (others => '0'),
      fcRunStateSet      => (others => '0'),
      bunchCntPeriodCnt  => (others => '0'),
      bunchCntPeriodSet  => toSlv(BUNCH_CNT_PERIOD_G, 6),
      bunchCntPeriod     => toSlv(BUNCH_CNT_PERIOD_G, 6),
      timingMsgPeriodCnt => (others => '0'),
      timingMsgPeriodSet => toSlv(TIMING_MSG_PERIOD_G, 32),
      timingMsgPeriod    => toSlv(TIMING_MSG_PERIOD_G, 32),
      rOrPeriodCnt       => (others => '0'),
      rOrPeriod          => toSlv(100, 32),
      axilReadSlave      => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave     => AXI_LITE_WRITE_SLAVE_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal syncAxilReadMaster  : AxiLiteReadMasterType;
   signal syncAxilReadSlave   : AxiLiteReadSlaveType;
   signal syncAxilWriteMaster : AxiLiteWriteMasterType;
   signal syncAxilWriteSlave  : AxiLiteWriteSlaveType;

begin

   U_AxiLiteAsync_1 : entity surf.AxiLiteAsync
      generic map (
         TPD_G         => TPD_G,
         COMMON_CLK_G  => AXIL_CLK_IS_FC_CLK_G,
         PIPE_STAGES_G => 0)
      port map (
         sAxiClk         => axilClk,              -- [in]
         sAxiClkRst      => axilRst,              -- [in]
         sAxiReadMaster  => axilReadMaster,       -- [in]
         sAxiReadSlave   => axilReadSlave,        -- [out]
         sAxiWriteMaster => axilWriteMaster,      -- [in]
         sAxiWriteSlave  => axilWriteSlave,       -- [out]
         mAxiClk         => fcClk,                -- [in]
         mAxiClkRst      => fcRst,                -- [in]
         mAxiReadMaster  => syncAxilReadMaster,   -- [out]
         mAxiReadSlave   => syncAxilReadSlave,    -- [in]
         mAxiWriteMaster => syncAxilWriteMaster,  -- [out]
         mAxiWriteSlave  => syncAxilWriteSlave);  -- [in]

   comb : process (fcRst, axilRst, r, syncAxilReadMaster, syncAxilWriteMaster) is
      variable v      : RegType;
      variable axilEp : AxiLiteEndPointType;
   begin
      -- Latch the current value
      v := r;

      -- Pulsed
      v.usrRoR       := '0';

      ----------------------------------------------------------------------
      --                AXI-Lite Register Logic
      ----------------------------------------------------------------------

      -- Determine the transaction type
      axiSlaveWaitTxn(axilEp, syncAxilWriteMaster, syncAxilReadMaster, v.axilWriteSlave, v.axilReadSlave);

      -- Map the read registers
      axiSlaveRegister (axilEp, x"000", 0, v.enableTimingMsg);     -- If high, Timing Msg Period cnt
                                                                   -- rolls and msgs are being sent
      axiSlaveRegister (axilEp, x"004", 0, v.enableRoR);           -- If high, RoR Period Counter
                                                                   -- increments every 5 cycles,
                                                                   -- and RoRs are being sent
      axiSlaveRegister (axilEp, x"008", 0, v.usrRoR);              -- Sends a single RoR for every
                                                                   -- low-to-high transition
      axiSlaveRegister (axilEp, x"00C", 0, v.pulseIDinit);         -- Set pulseID initial value
      axiSlaveRegister (axilEp, x"014", 0, v.timingMsgPeriodSet);  -- Timing Message period
      axiSlaveRegister (axilEp, x"018", 0, v.bunchCntPeriodSet);   -- Bunch Cnt period
      axiSlaveRegister (axilEp, x"01C", 0, v.fcRunStateSet);       -- Next FC run state set value
      axiSlaveRegister (axilEp, x"020", 0, v.rOrPeriod);           -- Read-Out-Req period
                                                                   -- (units of 5*timing clk period)


      -- Closeout the transaction
      axiSlaveDefault(axilEp, v.axilWriteSlave, v.axilReadSlave, AXI_RESP_DECERR_C);

      -- pulseID Period Counter Control
      -- bunchCnt Period Counter Control
      -- pulseID increments when the timingMsgPeriodCnt hits its limit
      -- and coincides with a request for a timing message;
      -- bunchCnt increments when the bunchCntPeriodCnt hits its limit;
      v.bunchCntStrb := '0';
      v.timingMsgReq := '0';
      v.fcMsg.valid  := '0';


      if (r.enableTimingMsg = '0') then
         -- reset case
         v.bunchClk           := '0';
         v.bunchCntPeriodCnt  := (others => '0');
         v.timingMsgPeriodCnt := (others => '0');
         v.fcMsg.bunchCnt     := (others => '0');
         v.fcMsg.pulseID      := r.pulseIDinit;

         -- When messages are disabled, set right away
         v.timingMsgPeriod := r.timingMsgPeriodSet;
         v.bunchCntPeriod  := r.bunchCntPeriodSet;
      else
         v.timingMsgPeriodCnt := r.timingMsgPeriodCnt + 1;
         v.bunchCntPeriodCnt  := r.bunchCntPeriodCnt + 1;

         -- timing message request and pulseID control
         if (r.timingMsgPeriodCnt = r.timingMsgPeriod-1) then
            v.timingMsgPeriodCnt := (others => '0');
            v.fcMsg.pulseID      := r.fcMsg.pulseID + 1;
            v.timingMsgReq       := '1';

            -- Load new periods set by software before starting next msg period
            v.timingMsgPeriod := r.timingMsgPeriodSet;
            v.bunchCntPeriod  := r.bunchCntPeriodSet;

         end if;

         -- the bunch Count strobe eventually triggers an RoR, and increments the bunch Counter
         if (r.bunchCntPeriodCnt = r.bunchCntPeriod-2) then
            -- strobe me just before the rollover so that the RoR
            -- gets the appropriate bunchCnt value
            v.bunchCntStrb := '1';
         elsif (r.bunchCntPeriodCnt = r.bunchCntPeriod-1) then
            v.bunchCntPeriodCnt := (others => '0');
         end if;

         -- bunch Count control. resets to zero foreach timing message request
         if (r.timingMsgReq = '1') then
            v.fcMsg.bunchCnt := (others => '0');
         elsif (v.bunchCntStrb = '1') then
            v.fcMsg.bunchCnt := r.fcMsg.bunchCnt + 1;
         end if;

         -- bunchClk control. bunchClk rising-edge has to coincide with bunchCnt incr
         -- bunchClk cannot be 50% duty-cycle because bunchCnt period is odd
         if (r.bunchCntStrb = '1') then
            v.bunchClk := '1';
         elsif (r.bunchCntPeriodCnt = ('0' & r.bunchCntPeriod(5 downto 1))) then
            -- cut the last bit -> div-by-2
            v.bunchClk := '0';
         end if;

      end if;

      -- main sub-process that controls the TX of the FC message
      -- controls FC message type, run state, and the message valid strobe
      if (r.usrRoR = '1') then
         -- immediate RoR
         -- if RoRs are not enabled, FC message bunchCnt will get the init value
         v.fcMsg.msgType := MSG_TYPE_ROR_C;
         v.fcMsg.message := FcEncode(r.fcMsg);
         v.fcMsg.valid   := '1';
      elsif (r.bunchCntStrb = '1' and r.enableRoR = '1') then
         -- periodic RoR. Have to check the RoR Period counter first
         v.rOrPeriodCnt := r.rOrPeriodCnt + 1;
         if (r.rOrPeriodCnt = r.rOrPeriod) then
            -- TX RoR
            v.rOrPeriodCnt  := (others => '0');
            v.fcMsg.msgType := MSG_TYPE_ROR_C;
            v.fcMsg.message := FcEncode(r.fcMsg);
            v.fcMsg.valid   := '1';
         end if;
      elsif (r.timingMsgReq = '1') then
         -- simple Timing Message
         v.fcMsg.stateChanged := toSl(v.fcMsg.runState /= r.fcRunStateSet);
         v.fcMsg.runState     := r.fcRunStateSet;
         v.fcMsg.msgType      := MSG_TYPE_TIMING_C;
         v.fcMsg.message      := FcEncode(r.fcMsg);
         v.fcMsg.valid        := '1';
      end if;

      -- General Outputs
      fcMsg              <= r.fcMsg;
      bunchClk           <= r.bunchClk;
      bunchStrobe        <= r.bunchCntStrb;
      -- AXI Outputs
      syncAxilWriteSlave <= r.axilWriteSlave;
      syncAxilReadSlave  <= r.axilReadSlave;

      ----------------------------------------------------------------------

      -- Reset
      if (fcRst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

   end process comb;

   seq : process (fcClk) is
   begin
      if (rising_edge(fcClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end rtl;

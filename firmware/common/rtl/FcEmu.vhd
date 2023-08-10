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

library work;
use work.FcPkg.all;

entity FcEmu is
   generic (
      TPD_G                      : time    := 1 ns;
      RST_ASYNC_G                : boolean := false;
      SIMULATION_G               : boolean := false;
      TIMING_MSG_PERIOD_G        : natural := 200; -- should fit in 32 bits
      BUNCH_CNT_PERIOD_G         : natural := 5;   -- should fit in 6 bits
      OVERRIDE_PERIOD_DEFAULTS_G : boolean := false);
   port (
      -- Clock and Reset
      axilClk         : in  sl;
      axilRst         : in  sl;
      -- Bunch Clock
      bunchClk        : out sl;
      -- Fast-Control Message Interface
      fcValid         : out sl;
      fcMsg           : out FastControlMessageType;
      -- AXI-Lite Interface
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
      fcValid            : sl;
      timingMsgReq       : sl;
      bunchCntStrb       : sl;
      bunchClk           : sl;
      fcMsg              : FastControlMessageType;
      pulseIDinit        : slv(63 downto 0);
      fcRunStateSet      : slv(5 downto 0);
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
      enableTimingMsg    => '0',
      enableRoR          => '0',
      usrRoR             => '0',
      fcValid            => '0',
      timingMsgReq       => '0',
      bunchCntStrb       => '0',
      bunchClk           => '0',
      fcMsg              => DEFAULT_FC_MSG_C,
      pulseIDinit        => (others => '0'),
      fcRunStateSet      => (others => '0'),
      bunchCntPeriodCnt  => (others => '0'),
      bunchCntPeriodSet  => slv(conv_unsigned(5, 6)),
      bunchCntPeriod     => slv(conv_unsigned(5, 6)),
      timingMsgPeriodCnt => (others => '0'),
      timingMsgPeriodSet => slv(conv_unsigned(200, 32)),
      timingMsgPeriod    => slv(conv_unsigned(200, 32)),
      rOrPeriodCnt       => (others => '0'),
      rOrPeriod          => slv(conv_unsigned(100, 32)),
      axilReadSlave      => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave     => AXI_LITE_WRITE_SLAVE_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

begin

   comb : process (axilReadMaster, axilRst, axilWriteMaster, r) is
      variable v      : RegType;
      variable axilEp : AxiLiteEndPointType;
   begin
      -- Latch the current value
      v := r;

      -- Reset the strobe
      v.usrRoR := '0';

      ----------------------------------------------------------------------
      --                AXI-Lite Register Logic
      ----------------------------------------------------------------------

      -- Determine the transaction type
      axiSlaveWaitTxn(axilEp, axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave);

      -- Map the read registers
      axiSlaveRegister (axilEp, x"000", 0, v.enableTimingMsg);    -- If high, Timing Msg Period cnt
                                                                  -- rolls and msgs are being sent
      axiSlaveRegister (axilEp, x"004", 0, v.enableRoR);          -- If high, RoR Period Counter
                                                                  -- increments every 5 cycles,
                                                                  -- and RoRs are being sent
      axiSlaveRegister (axilEp, x"008", 0, v.usrRoR);             -- Sends a single RoR for every
                                                                  -- low-to-high transition
      axiSlaveRegister (axilEp, x"00C", 0, v.pulseIDinit);        -- Set pulseID initial value
      axiSlaveRegister (axilEp, x"014", 0, v.timingMsgPeriodSet); -- Timing Message period
      axiSlaveRegister (axilEp, x"018", 0, v.bunchCntPeriodSet);  -- Bunch Cnt period
      axiSlaveRegister (axilEp, x"01C", 0, v.fcRunStateSet);      -- Next FC run state set value
      axiSlaveRegister (axilEp, x"020", 0, v.rOrPeriod);          -- Read-Out-Req period
                                                                  -- (units of 5*timing clk period)


      -- Closeout the transaction
      axiSlaveDefault(axilEp, v.axilWriteSlave, v.axilReadSlave, AXI_RESP_DECERR_C);


      -- to override or not to override
      v.timingMsgPeriod := ite(OVERRIDE_PERIOD_DEFAULTS_G, r.timingMsgPeriodSet,
                               slv(conv_unsigned(TIMING_MSG_PERIOD_G, 32)));
      v.bunchCntPeriod  := ite(OVERRIDE_PERIOD_DEFAULTS_G, r.bunchCntPeriodSet,
                               slv(conv_unsigned(BUNCH_CNT_PERIOD_G, 6)));

      -- pulseID Period Counter Control
      -- bunchCnt Period Counter Control
      -- pulseID increments when the timingMsgPeriodCnt hits its limit
      -- and coincides with a request for a timing message;
      -- bunchCnt increments when the bunchCntPeriodCnt hits its limit;
      v.bunchCntStrb := '0';
      v.timingMsgReq := '0';
      v.fcValid      := '0';

      if (r.enableTimingMsg = '0') then
         -- reset case
         v.bunchClk           := '0';
         v.bunchCntPeriodCnt  := (others => '0');
         v.timingMsgPeriodCnt := (others => '0');
         v.fcMsg.bunchCnt     := (others => '0');
         v.fcMsg.pulseID      := r.pulseIDinit;
      else
         v.timingMsgPeriodCnt := r.timingMsgPeriodCnt + 1;
         v.bunchCntPeriodCnt  := r.bunchCntPeriodCnt + 1;

         -- timing message request and pulseID control
         if (r.timingMsgPeriodCnt = r.timingMsgPeriod-1) then
            v.timingMsgPeriodCnt := (others => '0');
            v.fcMsg.pulseID      := r.fcMsg.pulseID + 1;
            v.timingMsgReq       := '1';
         end if;

         -- the bunch Count strobe eventually triggers an RoR, and increments the bunch Counter
         if (r.bunchCntPeriodCnt = r.bunchCntPeriod-2) then
            -- strobe me just before the rollover so that the RoR
            -- gets the appropriate bunchCnt value
            v.bunchCntStrb      := '1';
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
      if (v.fcMsg.runState /= r.fcRunStateSet) then
         -- note that any state change takes precedence and gets TX'd right away
         v.fcMsg.runState := r.fcRunStateSet;
         v.fcMsg.msgType  := MSG_TYPE_TIMING_C;
         v.fcMsg.message  := FcEncode(r.fcMsg);
         v.fcValid        := '1';
      elsif (r.usrRoR = '1') then
         -- immediate RoR
         -- if RoRs are not enabled, FC message bunchCnt will get the init value
         v.fcMsg.msgType  := MSG_TYPE_ROR_C;
         v.fcMsg.message  := FcEncode(r.fcMsg);
         v.fcValid        := '1';
      elsif (r.bunchCntStrb = '1' and r.enableRoR = '1') then
         -- periodic RoR. Have to check the RoR Period counter first
         v.rOrPeriodCnt := r.rOrPeriodCnt + 1;
         if (r.rOrPeriodCnt = r.rOrPeriod) then
            -- TX RoR
            v.rOrPeriodCnt  := (others => '0');
            v.fcMsg.msgType := MSG_TYPE_ROR_C;
            v.fcMsg.message := FcEncode(r.fcMsg);
            v.fcValid       := '1';
         end if;
      elsif (r.timingMsgReq = '1') then
         -- simple Timing Message
         v.fcMsg.msgType  := MSG_TYPE_TIMING_C;
         v.fcMsg.message  := FcEncode(r.fcMsg);
         v.fcValid        := '1';
      end if;

      -- General Outputs
      fcValid        <= r.fcValid;
      fcMsg          <= r.fcMsg;
      bunchClk       <= r.bunchClk;
      -- AXI Outputs
      axilWriteSlave <= r.axilWriteSlave;
      axilReadSlave  <= r.axilReadSlave;

      ----------------------------------------------------------------------

      -- Reset
      if (RST_ASYNC_G = false and axilRst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

   end process comb;

   seq : process (axilClk, axilRst) is
   begin
      if (RST_ASYNC_G and axilRst = '1') then
         r <= REG_INIT_C after TPD_G;
      elsif (rising_edge(axilClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end rtl;

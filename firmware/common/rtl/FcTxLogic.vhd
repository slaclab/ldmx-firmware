-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- Author     : Benjamin Reese  <bareese@slac.stanford.edu>
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2013 SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library UNISIM;
use UNISIM.VCOMPONENTS.all;


library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
--use surf.Pgp2FcPkg.all;

library lcls_timing_core;
use lcls_timing_core.TimingPkg.all;

library ldmx;
use ldmx.FcPkg.all;

entity FcTxLogic is

   generic (
      TPD_G : time := 1 ns);

   port (
      lclsTimingClk    : in  sl;
      lclsTimingRst    : in  sl;
      lclsTimingBus    : in  TimingBusType;
      globalTriggerRor : in  FcTimestampType;
      fcMsg            : out FastControlMessageType;

      -- Axil inteface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType);

end entity FcTxLogic;

architecture rtl of FcTxLogic is

   type RegType is record
      runState       : slv(4 downto 0);
      stateChanged   : sl;
      fcMsg          : FastControlMessageType;
      axilReadSlave  : AxiLiteReadSlaveType;
      axilWriteSlave : AxiLiteWriteSlaveType;
   end record;

   constant REG_INIT_C : RegType := (
      runState       => RUN_STATE_RESET_C,
      stateChanged   => '1',
      fcMsg          => FC_MSG_INIT_C,
      axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C);

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
         COMMON_CLK_G  => false,
         PIPE_STAGES_G => 0)
      port map (
         sAxiClk         => axilClk,              -- [in]
         sAxiClkRst      => axilRst,              -- [in]
         sAxiReadMaster  => axilReadMaster,       -- [in]
         sAxiReadSlave   => axilReadSlave,        -- [out]
         sAxiWriteMaster => axilWriteMaster,      -- [in]
         sAxiWriteSlave  => axilWriteSlave,       -- [out]
         mAxiClk         => lclsTimingClk,        -- [in]
         mAxiClkRst      => lclsTimingRst,        -- [in]
         mAxiReadMaster  => syncAxilReadMaster,   -- [out]
         mAxiReadSlave   => syncAxilReadSlave,    -- [in]
         mAxiWriteMaster => syncAxilWriteMaster,  -- [out]
         mAxiWriteSlave  => syncAxilWriteSlave);  -- [in]

   comb : process (globalTriggerRor, lclsTimingBus, r, syncAxilReadMaster, syncAxilWriteMaster) is
      variable v      : RegType;
      variable axilEp : AxiLiteEndpointType;
   begin

      v := r;

      v.fcMsg.valid := '0';

      -- Currently Timing Messages take priority
      -- Not sure if this is correct
      if (lclsTimingBus.strobe = '1' and lclsTimingBus.valid = '1') then
         v.fcMsg.valid        := '1';
         v.fcMsg.msgType      := MSG_TYPE_TIMING_C;
         v.fcMsg.pulseId      := lclsTimingBus.message.pulseId;
         v.fcMsg.runState     := r.runState;
         v.fcMsg.stateChanged := r.stateChanged;
         v.stateChanged       := '0';
         v.fcMsg.message      := FcEncode(v.fcMsg);

      elsif (globalTriggerRor.valid = '1') then
         v.fcMsg.valid      := '1';
         v.fcMsg.pulseId    := globalTriggerRor.pulseId;
         v.fcMsg.bunchCount := globalTriggerRor.bunchCount;
         v.fcMsg.message    := FcEncode(v.fcMsg);
      end if;

      ----------------------------------------------------------------------------------------------
      -- AXI Lite
      ----------------------------------------------------------------------------------------------
      axiSlaveWaitTxn(axilEp, syncAxilWriteMaster, syncAxilReadMaster, v.axilWriteSlave, v.axilReadSlave);

      axiSlaveRegister(axilEp, X"00", 0, v.runState);
      if (v.runState /= r.runState) then
         v.stateChanged := '1';
      end if;

      axiSlaveDefault(axilEp, v.axilWriteSlave, v.axilReadSlave, AXI_RESP_DECERR_C);

      syncAxilReadSlave  <= r.axilReadSlave;
      syncAxilWriteSlave <= r.axilWriteSlave;

      fcMsg <= r.fcMsg;
      rin   <= v;

   end process;


   -- Have to use async reset since recovered clock can drop out
   seq : process (lclsTimingClk, lclsTimingRst) is
   begin
      if (lclsTimingRst = '1') then
         r <= REG_INIT_C after TPD_G;
      elsif (rising_edge(lclsTimingClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end architecture rtl;

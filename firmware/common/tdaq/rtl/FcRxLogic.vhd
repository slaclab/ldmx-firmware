-------------------------------------------------------------------------------
-- Title      :
-------------------------------------------------------------------------------
-- File       : FcRxLogic.vhd
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

library ldmx_tdaq;
use ldmx_tdaq.FcPkg.all;

entity FcRxLogic is

   generic (
      TPD_G                : time    := 1 ns;
      AXIL_CLK_IS_FC_CLK_G : boolean := false);
   port (
      fcClk185     : in  sl;
      fcRst185     : in  sl;
      fcValid      : in  sl;
      fcWord       : in  slv(FC_LEN_C-1 downto 0);
      fcBus        : out FcBusType;
      fcBunchClk37 : out sl;
      fcBunchRst37 : out sl;

      -- Axil inteface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType);

end entity FcRxLogic;

architecture rtl of FcRxLogic is

   constant SUB_COUNT_MAX_C      : integer := 4;
   constant BUNCH_CLK_FALL_C     : integer := 1;
   constant BUNCH_CLK_RISE_C     : integer := 4;
   constant BUNCH_CLK_PRE_RISE_C : integer := 3;

   type RegType is record
      runTime        : slv(63 downto 0);
      clkCounter     : slv(7 downto 0);
      rorLatch       : sl;
      fcClkLost      : sl;
      fcBunchClk37   : sl;
      rorCount       : slv(31 downto 0);
      bunchClkAxiRst : sl;
      fcClk37Rst     : sl;
      fcBus          : FcBusType;
      axilReadSlave  : AxiLiteReadSlaveType;
      axilWriteSlave : AxiLiteWriteSlaveType;
   end record RegType;

   -- Timing comes up already enabled so that ADC can be read before sync is established
   constant REG_INIT_C : RegType := (
      runTime        => (others => '0'),
      clkCounter     => (others => '0'),
      rorLatch       => '0',
      fcClkLost      => '1',
      fcBunchClk37   => '0',
      rorCount       => (others => '0'),
      bunchClkAxiRst => '0',
      fcClk37Rst     => '1',
      fcBus          => FC_BUS_INIT_C,
      axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C);


   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal fcBunchClk37G : sl;

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
         mAxiClk         => fcClk185,             -- [in]
         mAxiClkRst      => fcRst185,             -- [in]
         mAxiReadMaster  => syncAxilReadMaster,   -- [out]
         mAxiReadSlave   => syncAxilReadSlave,    -- [in]
         mAxiWriteMaster => syncAxilWriteMaster,  -- [out]
         mAxiWriteSlave  => syncAxilWriteSlave);  -- [in]


   comb : process (fcValid, fcWord, r, syncAxilReadMaster, syncAxilWriteMaster) is
      variable v      : RegType;
      variable axilEp : AxiLiteEndpointType;
      variable fcMsg  : FcMessageType;
   begin
      v := r;

      -- Pulsed signals
      v.fcClkLost                   := '0';
      v.fcBus.pulseStrobe           := '0';
      v.fcBus.bunchStrobe           := '0';
      v.fcBus.bunchStrobePre        := '0';
      v.fcBus.stateChanged          := '0';
      v.fcBus.readoutRequest.strobe := '0';
      v.fcBus.bc0                   := '0';

      -- Count cycles from start of run
      v.runTime := r.runTime + 1;

      -- Counter for bunch count
      v.fcBus.subCount := r.fcBus.subCount + 1;
      if (r.fcBus.subCount = SUB_COUNT_MAX_C) then
         v.fcBus.subCount := (others => '0');
      end if;

      -- Assert ror and soft rst (reset101) only on falling edge of fcClk37
      -- to allow enough setup time for shfited hybrid clocks to see it.
      if (r.fcBus.subCount = BUNCH_CLK_FALL_C) then
         v.fcBunchClk37               := '0';
         v.fcBus.readoutRequest.valid := r.rorLatch;

         v.rorLatch := '0';
      end if;

      if (r.fcBus.subCount = BUNCH_CLK_RISE_C) then
         v.fcBunchClk37      := '1';
         v.fcBus.bunchStrobe := '1';
         v.fcBus.bunchCount  := r.fcBus.bunchCount + 1;
      end if;

      if (r.fcBus.subCount = BUNCH_CLK_PRE_RISE_C) then
         v.fcBus.bunchStrobePre        := '1';
         v.fcBus.readoutRequest.strobe := r.fcBus.readoutRequest.valid;
      end if;

      -- Decode incomming fast control messages from PGPFC
      fcMsg               := toFcMessage(fcWord, fcValid);
      v.fcBus.fcMsg.valid := fcValid;

      -- Process FC Messages
      if (fcMsg.valid = '1') then

         -- Save the message
         v.fcBus.fcMsg := fcMsg;

         case fcMsg.msgType is

            -- Process timing messages
            when MSG_TYPE_TIMING_C =>
               -- Output fields
               v.fcBus.pulseStrobe  := '1';
               v.fcBus.pulseId      := fcMsg.pulseId;
               v.fcBus.bunchCount   := fcMsg.bunchCount;  -- Should always be 0
               v.fcBus.runState     := fcMsg.runState;
               v.fcBus.stateChanged := fcMsg.stateChanged;
               v.fcBus.subCount     := (others => '0');

               -- State specific actions
               if (fcMsg.stateChanged = '1') then
                  case fcMsg.runState is
                     when RUN_STATE_RESET_C =>
                        -- Reset counters and FIFOs
                        v.rorCount              := (others => '0');
                        v.fcBus.bunchClkAligned := '0';
                     when RUN_STATE_IDLE_C =>
                        -- Algin Bunch clock
                        v.fcBunchClk37          := '0';
                        v.fcClkLost             := '1';  -- Creats a bunchClkRst
                        v.fcBus.bunchClkAligned := '1';
                     when RUN_STATE_BC0_C =>
                        v.fcBus.bc0 := '1';
                     when RUN_STATE_RUNNING_C =>
                        -- Reset runtime timestamp counter
                        -- Might do this in an earlier state
                        v.fcBus.runTime := (others => '0');
                     when others => null;
                  end case;

               end if;

            -- Process readout requests
            when MSG_TYPE_ROR_C =>
               if (r.fcBus.runState = RUN_STATE_BC0_C or r.fcBus.runState = RUN_STATE_RUNNING_C) then
                  -- Place on output bus
                  v.fcBus.readoutRequest.bunchCount := fcMsg.bunchCount;
                  v.fcBus.readoutRequest.pulseId    := fcMsg.pulseId;
                  v.rorLatch                        := '1';
                  v.rorCount                        := r.rorCount + 1;
               end if;
            when others => null;
         end case;
      end if;


      -- AXI Lite registers
      axiSlaveWaitTxn(axilEp, syncAxilWriteMaster, syncAxilReadMaster, v.axilWriteSlave, v.axilReadSlave);

      axiSlaveRegisterR(axilEp, X"00", 0, r.fcBus.bunchClkAligned);
      axiSlaveRegisterR(axilEp, X"04", 0, r.rorCount);
      axiSlaveRegisterR(axilEp, X"10", 0, r.fcBus.fcMsg.message);
      axiSlaveRegister(axilEp, X"24", 0, v.bunchClkAxiRst);  -- Allows software reprogramming of CM
      -- Add trigger enable register to replace feb config equivalent?

      axiSlaveDefault(axilEp, v.axilWriteSlave, v.axilReadSlave, AXI_RESP_DECERR_C);

      v.fcClk37Rst := r.bunchClkAxiRst or r.fcClkLost;

      fcBus <= r.fcBus;

      syncAxilReadSlave  <= r.axilReadSlave;
      syncAxilWriteSlave <= r.axilWriteSlave;

      rin <= v;


   end process comb;

   -- Have to use async reset since recovered clk125 can drop out
   seq : process (fcClk185, fcRst185) is
   begin
      if (fcRst185 = '1') then
         r <= REG_INIT_C after TPD_G;
      elsif (rising_edge(fcClk185)) then
         r <= rin after TPD_G;
      end if;
   end process seq;


   -- Drive divided clock onto a BUFG
   BUFG_CLK41_RAW : BUFG
      port map (
         I => r.fcBunchClk37,
         O => fcBunchClk37G);

   fcBunchClk37 <= fcBunchClk37G;

   -- Provide a reset signal for downstream MMCMs
   RstSync_fcClk37Rst : entity surf.RstSync
      generic map (
         TPD_G           => TPD_G,
         IN_POLARITY_G   => '1',
         OUT_POLARITY_G  => '1',
         RELEASE_DELAY_G => 5)
      port map (
         clk      => fcBunchClk37G,
         asyncRst => r.fcClk37Rst,
         syncRst  => fcBunchRst37);



end architecture rtl;

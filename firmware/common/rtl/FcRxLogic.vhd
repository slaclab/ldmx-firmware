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


library ldmx;
use ldmx.LdmxPkg.all;
use ldmx.FcPkg.all;

entity FcRxLogic is

   generic (
      TPD_G : time := 1 ns);
   port (
      fcClk185     : in  sl;
      fcRst185     : in  sl;
      fcValid      : in  sl;
      fcWord       : in  slv(FC_LEN_C-1 downto 0);
      fcBunchClk37 : out sl;
      fcBunchRst37 : out sl;
      fcBus        : out FastControlBusType;

      -- Axil inteface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType);

end entity FcRxLogic;

architecture rtl of FcRxLogic is

   constant CLK_DIV_FALL_CNT_C : integer := 4;
   constant CLK_DIV_RISE_CNT_C : integer := 2;

   type RegType is record
      divCounter     : slv(2 downto 0);
      runTime        : slv(63 downto 0);
      rorLatch       : sl;
      fcClkLost      : sl;
      fcBunchClk37   : sl;
      rorCount       : slv(15 downto 0);
      fcClkAxilRst   : sl;
      fcClk37Rst     : sl;
      fcBus          : FastControlBusType;
      axilReadSlave  : AxiLiteReadSlaveType;
      axilWriteSlave : AxiLiteWriteSlaveType;
   end record RegType;

   -- Timing comes up already enabled so that ADC can be read before sync is established
   constant REG_INIT_C : RegType := (
      divCounter     => (others => '0'),
      runTime        => (others => '0'),
      rorLatch       => '0',
      fcClkLost      => '1',
      fcBunchClk37   => '0',
      rorCount       => (others => '0'),
      fcClkAxilRst   => '0',
      fcClk37Rst     => '0',
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
         COMMON_CLK_G  => false,
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
      variable fcMsg  : FastControlMessageType;
   begin
      v := r;

      -- Pulsed signals
      v.fcClkLost                  := '0';
      v.fcBus.pulseStrobe          := '0';
      v.fcBus.readoutRequest.valid := '0';

      -- Counters
      v.divCounter := r.divCounter + 1;
      v.runTime    := r.runTime + 1;

      -- Assert ror and soft rst (reset101) only on falling edge of fcClk37
      -- to allow enough setup time for shfited hybrid clocks to see it.
      if (r.divCounter = CLK_DIV_FALL_CNT_C) then
         v.divCounter                 := (others => '0');
         v.fcBunchClk37               := '0';
         v.fcBus.readoutRequest.valid := r.rorLatch;
         v.rorLatch                   := '0';
      end if;

      if (r.divCounter = CLK_DIV_RISE_CNT_C) then
         v.fcBunchClk37 := '1';
      end if;

      -- Decode incomming fast control messages from PGPFC
      fcMsg := FcDecode(fcWord, fcValid);

      -- Process FC Messages
      if (fcMsg.valid = '1') then

         -- Save the message
         v.fcBus.fcMsg := fcMsg;

         case fcMsg.msgType is

            -- Process timing messages
            when MSG_TYPE_TIMING_C =>
               -- Align bunch clock every time?


               -- Output fields
               v.fcBus.pulseStrobe  := '1';
               v.fcBus.pulseId      := fcMsg.pulseId;
               v.fcBus.bunchCount   := fcMsg.bunchCount;
               v.fcBus.runState     := fcMsg.runState;
               v.fcBus.stateChanged := fcMsg.stateChanged;

               -- State specific actions
               if (fcMsg.stateChanged = '1') then
                  case fcMsg.runState is
                     when RUN_STATE_RESET_C =>
                        -- Reset counters and FIFOs
                        v.rorCount              := (others => '0');
                        v.fcBus.bunchClkAligned := '0';
                     when RUN_STATE_CLOCK_ALIGN_C =>
                        -- Algin Bunch clock
                        v.divCounter      := (others => '0');
                        v.fcBunchClk37    := '0';
                        v.fcClkLost       := '1';  -- Creats a bunchClkRst                        
                        v.fcBus.bunchClkAligned := '1';
                     when RUN_STATE_RUNNING_C =>
                        -- Reset runtime timestamp counter
                        -- Might do this in an earlier state
                        v.fcBus.runTime := (others => '0');
                     when others => null;
                  end case;

               end if;

            -- Process readout requests
            when MSG_TYPE_ROR_C =>
               if (r.fcBus.runState = RUN_STATE_RUNNING_C) then
                  -- Place on output bus
                  v.fcBus.readoutRequest.valid      := '1';
                  v.fcBus.readoutRequest.bunchCount := fcMsg.bunchCount;
                  v.fcBus.readoutRequest.pulseId    := fcMsg.pulseId;

                  v.rorLatch := '1';
                  v.rorCount := r.rorCount + 1;
               end if;
            when others => null;
         end case;

      end if;



      -- AXI Lite registers
      axiSlaveWaitTxn(axilEp, syncAxilWriteMaster, syncAxilReadMaster, v.axilWriteSlave, v.axilReadSlave);

      axiSlaveRegisterR(axilEp, X"00", 0, r.fcBus.bunchClkAligned);
      axiSlaveRegisterR(axilEp, X"04", 0, r.rorCount);
      axiSlaveRegisterR(axilEp, X"10", 0, r.fcBus.fcMsg.message);
      axiSlaveRegister(axilEp, X"24", 0, v.fcClkAxilRst);  -- Allows software reprogramming of CM
      -- Add trigger enable register to replace feb config equivalent?

      axiSlaveDefault(axilEp, v.axilWriteSlave, v.axilReadSlave, AXI_RESP_DECERR_C);

      v.fcClk37Rst := r.fcClkAxilRst or r.fcClkLost;

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
         O => fcBunchClk37);

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

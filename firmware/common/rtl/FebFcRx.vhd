-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : FebFcRx.vhd
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

entity FebFcRx is

   generic (
      TPD_G     : time    := 1 ns;
      HYBRIDS_G : integer := 4);
   port (
      fcClk185 : in sl;
      fcRst185 : in sl;
      fcMsg    : in FastControlMessageType;

      fcClk37    : out sl;
      fcClk37Rst : out sl;
      fcRoR      : out sl;
      fcReset101 : out slv(HYBRIDS_G-1 downto 0);

      -- Axil inteface
      axilClk          : in  sl;
      axilRst          : in  sl;
      axilRoR          : out sl;
--      rorFifoValid     : out sl;
      rorFifoMsg       : out FastControlMessageType;
      rorFifoTimestamp : out slv(63 downto 0);
      rorFifoRdEn      : in  sl;

      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType);

end entity FebFcRx;

architecture rtl of FebFcRx is

   constant CLK_DIV_FALL_CNT_C : integer := 4;
   constant CLK_DIV_RISE_CNT_C : integer := 2;

   type RegType is record
      divCounter      : slv(2 downto 0);
      runTime         : slv(63 downto 0);
      rorLatch        : sl;
      fcClkLost       : sl;
      fcClk37         : sl;
      fcRor           : sl;
      fcAligned       : sl;
      fifoRst         : sl;
      fifoWrEn        : sl;
      lastTimingMsg   : FastControlMessageType;
      fcReset101      : slv(HYBRIDS_G-1 downto 0);
      fcReset101Latch : slv(HYBRIDS_G-1 downto 0);
      rorCount        : slv(15 downto 0);
      alignCount      : slv(15 downto 0);
      fcReset101Count : slv(15 downto 0);
      fcClkAxilRst    : sl;
      fcClk37Rst      : sl;
      axilReadSlave   : AxiLiteReadSlaveType;
      axilWriteSlave  : AxiLiteWriteSlaveType;

   end record RegType;

   -- Timing comes up already enabled so that ADC can be read before sync is established
   constant REG_INIT_C : RegType := (
      divCounter      => (others => '0'),
      runTime         => (others => '0'),
      rorLatch        => '0',
      fcClkLost       => '1',
      fcClk37         => '0',
      fcRor           => '0',
      fcAligned       => '0',
      fifoRst         => '0',
      fifoWrEn        => '0',
      lastTimingMsg   => DEFAULT_FC_MSG_C,
      fcReset101      => (others => '0'),
      fcReset101Latch => (others => '0'),
      rorCount        => (others => '0'),
      alignCount      => (others => '0'),
      fcReset101Count => (others => '0'),
      fcClkAxilRst    => '0',
      fcClk37Rst      => '0',
      axilReadSlave   => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave  => AXI_LITE_WRITE_SLAVE_INIT_C);


   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal fcClk37Int : sl;

   signal syncAxilReadMaster  : AxiLiteReadMasterType;
   signal syncAxilReadSlave   : AxiLiteReadSlaveType;
   signal syncAxilWriteMaster : AxiLiteWriteMasterType;
   signal syncAxilWriteSlave  : AxiLiteWriteSlaveType;

   signal rorFifoMsgRaw : slv(79 downto 0);
   signal rorFifoValid  : sl;


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

   comb : process (fcMsg, r, syncAxilReadMaster, syncAxilWriteMaster) is
      variable v      : RegType;
      variable axilEp : AxiLiteEndpointType;
   begin
      v := r;

      -- Pulsed signals
      v.fcClkLost := '0';
      --v.fifoRst   := '0';
      v.fifoWrEn  := '0';

      -- Counters
      v.divCounter := r.divCounter + 1;
      v.runTime    := r.runTime + 1;

      -- Assert ror and soft rst (reset101) only on falling edge of fcClk37
      -- to allow enough setup time for shfited hybrid clocks to see it.
      if (r.divCounter = CLK_DIV_FALL_CNT_C) then
         v.divCounter      := (others => '0');
         v.fcClk37         := '0';
         v.fcRor           := r.rorLatch;
         v.fcReset101      := r.fcReset101Latch;
         v.rorLatch        := '0';
         v.fcReset101Latch := (others => '0');
      end if;

      if (r.divCounter = CLK_DIV_RISE_CNT_C) then
         v.fcClk37 := '1';
      end if;


      -- Process FC Messages
      if (fcMsg.valid = '1') then
         case fcMsg.msgType is
            when MSG_TYPE_TIMING_C =>
               -- Align bunch clock every time?

               -- Save the message
               v.lastTimingMsg := fcMsg;

               -- If the state has just changed, do things
               if (fcMsg.stateChanged = '1') then
                  case fcMsg.runState is
                     when RUN_STATE_RESET_C =>
                        -- Reset counters and FIFOs
                        v.rorCount  := (others => '0');
                        v.fifoRst   := '1';
                        v.fcAligned := '0';
                     when RUN_STATE_CLOCK_ALIGN_C =>
                        -- Algin Bunch clock
                        v.fifoRst    := '0';
                        v.divCounter := (others => '0');
                        v.fcClk37    := '0';
                        v.fcAligned  := '1';
                        v.alignCount := r.alignCount + 1;
                        v.fcClkLost  := '1';
                     when RUN_STATE_PRESTART_C =>
                        -- Issue Reset 101 to APVs
                        v.fcReset101Latch := (others => '1');
                        v.fcReset101Count := r.fcReset101Count + 1;
                     when RUN_STATE_RUNNING_C =>
                        -- Reset runtime timestamp counter
                        v.runTime := (others => '0');
                     when others => null;
                  end case;

               end if;


            when MSG_TYPE_ROR_C =>
               if (r.lastTimingMsg.runState = RUN_STATE_RUNNING_C) then
                  v.rorLatch := '1';
                  v.rorCount := r.rorCount + 1;
                  v.fifoWrEn := '1';
               end if;
            when others => null;
         end case;

      end if;



      -- AXI Lite registers
      axiSlaveWaitTxn(axilEp, syncAxilWriteMaster, syncAxilReadMaster, v.axilWriteSlave, v.axilReadSlave);

      axiSlaveRegisterR(axilEp, X"00", 0, r.fcAligned);
      axiSlaveRegisterR(axilEp, X"04", 0, r.rorCount);
      axiSlaveRegisterR(axilEp, X"08", 0, r.alignCount);
      axiSlaveRegisterR(axilEp, X"0C", 0, r.fcReset101Count);
      axiSlaveRegisterR(axilEp, X"10", 0, r.lastTimingMsg.message);
      axiSlaveRegister(axilEp, X"20", 0, v.fifoRst);
      axiSlaveRegister(axilEp, X"24", 0, v.fcClkAxilRst);  -- Allows software reprogramming of CM
      -- Add trigger enable register to replace feb config equivalent?

      axiSlaveDefault(axilEp, v.axilWriteSlave, v.axilReadSlave, AXI_RESP_DECERR_C);

      v.fcClk37Rst := r.fcClkAxilRst or r.fcClkLost;

      rin <= v;

      fcRor              <= r.fcRor;
      fcReset101         <= r.fcReset101;
      syncAxilReadSlave  <= r.axilReadSlave;
      syncAxilWriteSlave <= r.axilWriteSlave;

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
         I => r.fcClk37,
         O => fcClk37Int);

   fcClk37 <= fcClk37Int;

   -- Provide a reset signal for downstream MMCMs
   RstSync_fcClk37Rst : entity surf.RstSync
      generic map (
         TPD_G           => TPD_G,
         IN_POLARITY_G   => '1',
         OUT_POLARITY_G  => '1',
         RELEASE_DELAY_G => 5)
      port map (
         clk      => fcClk37Int,
         asyncRst => r.fcClk37Rst,
         syncRst  => fcClk37Rst);

   -- Pulse trigger for 1 axilClk cycle in response to each trigger code
   ROR_SYNC_FIFO : entity surf.SynchronizerFifo
      generic map (
         TPD_G         => TPD_G,
         MEMORY_TYPE_G => "distributed",
         DATA_WIDTH_G  => 1,
         ADDR_WIDTH_G  => 4)
      port map (
         rst    => r.fifoRst,
         wr_clk => fcClk185,
         wr_en  => r.fifoWrEn,
         din(0) => '0',
         rd_clk => axilClk,
         valid  => axilRor);

   -- Log the timestamp of each trigger
   ROR_TIMESTAMP_FIFO : entity surf.Fifo
      generic map (
         TPD_G           => TPD_G,
         GEN_SYNC_FIFO_G => false,
         MEMORY_TYPE_G   => "distributed",
         FWFT_EN_G       => true,
         DATA_WIDTH_G    => 64,
         ADDR_WIDTH_G    => 6)
      port map (
         rst           => r.fifoRst,
         wr_clk        => fcClk185,
         wr_en         => r.fifoWrEn,
         wr_data_count => open,
         din           => r.runtime,
         rd_clk        => axilClk,
         rd_en         => rorFifoRdEn,
         dout          => rorFifoTimestamp,
         valid         => open);

   -- Log FC message for each ROR
   ROR_FC_MSG_FIFO : entity surf.Fifo
      generic map (
         TPD_G           => TPD_G,
         GEN_SYNC_FIFO_G => false,
         MEMORY_TYPE_G   => "distributed",
         FWFT_EN_G       => true,
         DATA_WIDTH_G    => 80,
         ADDR_WIDTH_G    => 6)
      port map (
         rst           => r.fifoRst,
         wr_clk        => fcClk185,
         wr_en         => r.fifoWrEn,
         wr_data_count => open,
         din           => fcMsg.message,
         rd_clk        => axilClk,
         rd_en         => rorFifoRdEn,
         dout          => rorFifoMsgRaw,
         valid         => rorFifoValid);

   rorFifoMsg <= fcDecode(rorFifoMsgRaw, rorFifoValid);




end architecture rtl;

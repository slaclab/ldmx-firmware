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

library ldmx_tdaq;
use ldmx_tdaq.FcPkg.all;

library ldmx_tracker;
use ldmx_tracker.LdmxPkg.all;

entity FebFcRx is

   generic (
      TPD_G     : time    := 1 ns;
      HYBRIDS_G : integer := 4);
   port (
      fcClk185   : in  sl;
      fcRst185   : in  sl;
      fcBus      : in  FcBusType;
      fcReset101 : out slv(HYBRIDS_G-1 downto 0);

      -- Axil inteface
      axilClk              : in  sl;
      axilRst              : in  sl;
      axilRorStrobe        : out sl;
      axilRorFifoTimestamp : out FcTimestampType;
      axilRorFifoRdEn      : in  sl;
      axilReadMaster       : in  AxiLiteReadMasterType;
      axilReadSlave        : out AxiLiteReadSlaveType;
      axilWriteMaster      : in  AxiLiteWriteMasterType;
      axilWriteSlave       : out AxiLiteWriteSlaveType);

end entity FebFcRx;

architecture rtl of FebFcRx is

   type RegType is record
      fifoRst         : sl;
      fcReset101      : slv(HYBRIDS_G-1 downto 0);
      fcReset101Latch : slv(HYBRIDS_G-1 downto 0);
      fcReset101Count : slv(15 downto 0);
      fcClkAxilRst    : sl;
      axilReadSlave   : AxiLiteReadSlaveType;
      axilWriteSlave  : AxiLiteWriteSlaveType;
   end record RegType;

   -- Timing comes up already enabled so that ADC can be read before sync is established
   constant REG_INIT_C : RegType := (
      fifoRst         => '0',
      fcReset101      => (others => '0'),
      fcReset101Latch => (others => '0'),
      fcReset101Count => (others => '0'),
      fcClkAxilRst    => '0',
      axilReadSlave   => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave  => AXI_LITE_WRITE_SLAVE_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal syncAxilReadMaster  : AxiLiteReadMasterType;
   signal syncAxilReadSlave   : AxiLiteReadSlaveType;
   signal syncAxilWriteMaster : AxiLiteWriteMasterType;
   signal syncAxilWriteSlave  : AxiLiteWriteSlaveType;

   signal axilRorLoc : sl;

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

   comb : process (fcBus, r, syncAxilReadMaster, syncAxilWriteMaster) is
      variable v      : RegType;
      variable axilEp : AxiLiteEndpointType;
   begin
      v := r;

      -- Assert ror and soft rst (reset101) only on falling edge of fcClk37
      -- to allow enough setup time for shfited hybrid clocks to see it.
      if (fcBus.subCount = 1) then
         v.fcReset101      := r.fcReset101Latch;
         v.fcReset101Latch := (others => '0');
      end if;

      -- Process FC Messages
      if (fcBus.pulseStrobe = '1' and fcBus.stateChanged = '1') then
         case fcBus.runState is
            when RUN_STATE_RESET_C =>
               -- Reset counters and FIFOs
               v.fifoRst := '1';
            when RUN_STATE_BC0_C =>
               -- Algin Bunch clock
               v.fifoRst := '0';
            when RUN_STATE_PRESTART_C =>
               -- Issue Reset 101 to APVs
               v.fcReset101Latch := (others => '1');
               v.fcReset101Count := r.fcReset101Count + 1;
            when others =>
               null;
         end case;
      end if;


      -- AXI Lite registers
      axiSlaveWaitTxn(axilEp, syncAxilWriteMaster, syncAxilReadMaster, v.axilWriteSlave, v.axilReadSlave);

      axiSlaveRegisterR(axilEp, X"0C", 0, r.fcReset101Count);
      axiSlaveRegister(axilEp, X"20", 0, v.fifoRst);
      axiSlaveRegister(axilEp, X"24", 0, v.fcClkAxilRst);  -- Allows software reprogramming of CM
      -- Add trigger enable register to replace feb config equivalent?

      axiSlaveDefault(axilEp, v.axilWriteSlave, v.axilReadSlave, AXI_RESP_DECERR_C);

      rin <= v;

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
         wr_en  => fcBus.readoutRequest.valid,
         din(0) => '0',
         rd_clk => axilClk,
         valid  => axilRorLoc,
         rd_en  => axilRorLoc);

   axilRorStrobe <= axilRorLoc;

   -- Log FC message for each ROR
   U_ReadoutRequestFifo_1 : entity ldmx_tdaq.ReadoutRequestFifo
      generic map (
         TPD_G => TPD_G)
      port map (
         rst          => r.fifoRst,             -- [in]         
         fcClk185     => fcClk185,              -- [in]
         fcBus        => fcBus,                 -- [in]
         sysClk       => axilClk,               -- [in]
         sysRst       => axilRst,               -- [in]
         rorTimestamp => axilRorFifoTimestamp,  -- [out]
         rdEn         => axilRorFifoRdEn);      -- [in]



end architecture rtl;

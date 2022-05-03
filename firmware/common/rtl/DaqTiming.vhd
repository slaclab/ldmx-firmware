-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : DaqTiming.vhd
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
use ldmx.HpsPkg.all;

entity DaqTiming is

   generic (
      TPD_G         : time    := 1 ns;
      DAQ_CLK_DIV_G : integer := 3;
      HYBRIDS_G     : integer := 4);
   port (
      daqClk       : in  sl;
      daqRst       : in  sl;
      daqFcWord    : in  slv(7 downto 0);
      daqFcValid   : in  sl;
      daqClkDiv    : out sl;
      daqClkDivRst : out sl;
      daqTrigger   : out sl;
      hySoftRst    : out slv(HYBRIDS_G-1 downto 0);

      -- Axi inteface
      axiClk         : in  sl;
      axiRst         : in  sl;
      axiReadMaster  : in  AxiLiteReadMasterType;
      axiReadSlave   : out AxiLiteReadSlaveType;
      axiWriteMaster : in  AxiLiteWriteMasterType;
      axiWriteSlave  : out AxiLiteWriteSlaveType);

end entity DaqTiming;

architecture rtl of DaqTiming is


   type RegType is record
      counter        : integer range 0 to DAQ_CLK_DIV_G-1;
      triggerLatch   : sl;
      daqClkLost     : sl;
      daqClkDiv      : sl;
      daqTrigger     : sl;
      daqAligned     : sl;
      hySoftRst      : slv(HYBRIDS_G-1 downto 0);
      hySoftRstLatch : slv(HYBRIDS_G-1 downto 0);
      triggerCount   : slv(15 downto 0);
      alignCount     : slv(15 downto 0);
      hySoftRstCount : slv(15 downto 0);
   end record RegType;

   -- Timing comes up already enabled so that ADC can be read before sync is established
   constant REG_INIT_C : RegType := (
      counter        => 0,
      triggerLatch   => '0',
      daqClkLost     => '1',
      daqClkDiv      => '0',
      daqTrigger     => '0',
      daqAligned     => '0',
      hySoftRst      => (others => '0'),
      hySoftRstLatch => (others => '0'),
      triggerCount   => (others => '0'),
      alignCount     => (others => '0'),
      hySoftRstCount => (others => '0'));

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal daqClkDivInt : sl;

   -------------------------------------------------------------------------------------------------
   -- AXI signals
   -------------------------------------------------------------------------------------------------
   type AxiRegType is record
      axiReadSlave  : AxiLiteReadSlaveType;
      axiWriteSlave : AxiLiteWriteSlaveType;
   end record AxiRegType;

   constant AXI_REG_INIT_C : AxiRegType := (
      axiReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axiWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C);

   signal axiR   : AxiRegType := AXI_REG_INIT_C;
   signal axiRin : AxiRegType;


   signal daqAlignedAxi     : sl;
   signal triggerCountAxi   : slv(15 downto 0);
   signal alignCountAxi     : slv(15 downto 0);
   signal hySoftRstCountAxi : slv(15 downto 0);



begin

   comb : process (daqFcValid, daqFcWord, r) is
      variable v : RegType;
   begin
      v := r;

      v.daqClkLost := '0';
      v.counter    := r.counter + 1;
      v.daqClkDiv  := '1';

      -- Assert trigger only on falling edge of daqClkDiv
      -- to allow enough setup time for shfited hybrid clocks to see it.
      if (r.counter = DAQ_CLK_DIV_G-1 or (daqFcValid = '1' and daqFcWord = DAQ_CLK_ALIGN_CODE_C)) then
         v.counter        := 0;
         v.daqClkDiv      := '0';
         v.daqTrigger     := r.triggerLatch;
         v.hySoftRst      := r.hySoftRstLatch;
         v.triggerLatch   := '0';
         v.hySoftRstLatch := (others => '0');
      end if;

      -- Terrible hack
      if (r.counter = 3 and DAQ_CLK_DIV_G = 5) then
         v.daqClkDiv := '0';
      end if;

      if (daqFcValid = '1' and daqFcWord = DAQ_CLK_ALIGN_CODE_C) then
         v.daqAligned := '1';
         v.alignCount := r.alignCount + 1;
         v.daqClkLost := '1';
      end if;

      -- Trigger Opcode
      if (daqFcValid = '1' and daqFcWord = DAQ_TRIGGER_CODE_C) then
         v.triggerLatch := '1';
         v.triggerCount := r.triggerCount + 1;
      end if;


      if (daqFcValid = '1' and daqFcWord = DAQ_APV_RESET101_C) then
         v.hySoftRstLatch := (others => '1');
         v.hySoftRstCount := r.hySoftRstCount + 1;
      end if;


      rin <= v;

      daqTrigger <= r.daqTrigger;
      hySoftRst  <= r.hySoftRst;



   end process comb;

   -- Have to use async reset since recovered clk125 can drop out
   seq : process (daqClk, daqRst) is
   begin
      if (daqRst = '1') then
         r <= REG_INIT_C after TPD_G;
      elsif (rising_edge(daqClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;


   -- Drive divided clock onto a BUFG
   BUFG_CLK41_RAW : BUFG
      port map (
         I => r.daqClkDiv,
         O => daqClkDivInt);

   daqClkDiv <= daqClkDivInt;

   -- Provide a reset signal for downstream MMCMs
   RstSync_daqClkDivRst : entity surf.RstSync
      generic map (
         TPD_G           => TPD_G,
         IN_POLARITY_G   => '1',
         OUT_POLARITY_G  => '1',
         RELEASE_DELAY_G => 5)
      port map (
         clk      => daqClkDivInt,
         asyncRst => r.daqClkLost,
         syncRst  => daqClkDivRst);

   -------------------------------------------------------------------------------------------------
   -- AXI logic
   -------------------------------------------------------------------------------------------------
   -- First synchronize counters to axi clk
   SynchronizerFifo_1 : entity surf.SynchronizerFifo
      generic map (
         TPD_G         => TPD_G,
         COMMON_CLK_G  => false,
         MEMORY_TYPE_G => "distributed",
         DATA_WIDTH_G  => (3*16 + 1),
         ADDR_WIDTH_G  => 4)
      port map (
         rst                => axiRst,
         wr_clk             => daqClk,
         din(15 downto 0)   => r.triggerCount,
         din(31 downto 16)  => r.alignCount,
         din(47 downto 32)  => r.hySoftRstCount,
         din(48)            => r.daqAligned,
         rd_clk             => axiClk,
         dout(15 downto 0)  => triggerCountAxi,
         dout(31 downto 16) => alignCountAxi,
         dout(47 downto 32) => hySoftRstCountAxi,
         dout(48)           => daqAlignedAxi);

   axiComb : process (alignCountAxi, axiR, axiReadMaster, axiRst, axiWriteMaster, daqAlignedAxi,
                      hySoftRstCountAxi, triggerCountAxi) is
      variable v         : AxiRegType;
      variable axiStatus : AxiLiteStatusType;
   begin
      v := axiR;

      axiSlaveWaitTxn(axiWriteMaster, axiReadMaster, v.axiWriteSlave, v.axiReadSlave, axiStatus);
      if (axiStatus.readEnable = '1') then
         -- Decode address and assign read data
         v.axiReadSlave.rdata := (others => '0');
         case axiReadMaster.araddr(7 downto 0) is
            when X"00" =>
               v.axiReadSlave.rdata(0) := daqAlignedAxi;
            when X"04" =>
               v.axiReadSlave.rdata(15 downto 0) := triggerCountAxi;
            when X"08" =>
               v.axiReadSlave.rdata(15 downto 0) := alignCountAxi;
            when x"0C" =>
               v.axiReadSlave.rdata(15 downto 0) := hySoftRstCountAxi;
            when others => null;
         end case;
         axiSlaveReadResponse(v.axiReadSlave);
      end if;

      if (axiRst = '1') then
         v := AXI_REG_INIT_C;
      end if;

      axiRin <= v;

      axiReadSlave  <= axiR.axiReadSlave;
      axiWriteSlave <= axiR.axiWriteSlave;

   end process axiComb;

   axiSeq : process (axiClk) is
   begin
      if (rising_edge(axiClk)) then
         axiR <= axiRin after TPD_G;
      end if;
   end process axiSeq;

end architecture rtl;

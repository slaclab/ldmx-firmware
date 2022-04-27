-------------------------------------------------------------------------------
-- Title         : ADC Readout Control
-- Project       : Heavy Photon Tracker
-------------------------------------------------------------------------------
-- File          : AdcReadout7.vhd
-- Author        : Ben Reese <bareese@slac.stanford.edu>
-- Created       : 2013
-------------------------------------------------------------------------------
-- Description:
-- ADC Readout Controller
-- Receives ADC Data from an AD9592 chip.
-- Designed specifically for Xilinx 7 series FPGAs
-------------------------------------------------------------------------------
-- Copyright (c) 2013 by SLAC. All rights reserved.
-------------------------------------------------------------------------------
-- Modification history:
-- 12/08/2011: created.
-- 02/2013: Updated for Xilinx 7 series FPGA IO resources
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;

library ldmx;
use ldmx.AdcReadoutPkg.all;

library UNISIM;
use UNISIM.vcomponents.all;

entity AdcReadout7 is
   generic (
      TPD_G           : time                 := 1 ns;
      SIMULATION_G    : boolean              := false;
      NUM_CHANNELS_G  : natural range 1 to 8 := 5;
      IODELAY_GROUP_G : string);
   port (
      -- Master system clock, 125Mhz
      axiClk : in sl;
      axiRst : in sl;

      -- Axi Interface
      axiWriteMaster : in  AxiLiteWriteMasterType;
      axiWriteSlave  : out AxiLiteWriteSlaveType;
      axiReadMaster  : in  AxiLiteReadMasterType;
      axiReadSlave   : out AxiLiteReadSlaveType;

      -- Reset for adc deserializer
      adcClkRst : in sl;

      -- Serial Data from ADC
      adc : in AdcChipOutType;

      -- Deserialized ADC Data
      readout : out AdcReadoutType);
end AdcReadout7;

-- Define architecture
architecture rtl of AdcReadout7 is

   -------------------------------------------------------------------------------------------------
   -- AXI Registers
   -------------------------------------------------------------------------------------------------
   type AxiRegType is record
      axiWriteSlave : AxiLiteWriteSlaveType;
      axiReadSlave  : AxiLiteReadSlaveType;

      -- Deserializer configuration registers
      dataDelay     : slv5Array(4 downto 0);
      dataDelaySet  : slv(4 downto 0);
      frameDelay    : slv(4 downto 0);
      frameDelaySet : sl;
      readout       : AdcReadoutArray(1 downto 0);
   end record;

   constant AXI_REG_INIT_C : AxiRegType := (
      axiWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C,
      axiReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      dataDelay     => (others => "00101"),  -- Default delay of 10 taps
      dataDelaySet  => (others => '1'),
      frameDelay    => "00101",
      frameDelaySet => '1',
      readout       => (others => ADC_READOUT_INIT_C));

   signal lockedSync      : sl;
   signal lockedFallCount : slv(15 downto 0);

   signal axiR   : AxiRegType := AXI_REG_INIT_C;
   signal axiRin : AxiRegType;

   -------------------------------------------------------------------------------------------------
   -- ADC Readout Clocked Registers
   -------------------------------------------------------------------------------------------------
   type AdcRegType is record
      slip       : sl;
      count      : slv(ite(SIMULATION_G, 4, 8) downto 0);
      locked     : sl;
      fifoWrData : Slv16Array(NUM_CHANNELS_G-1 downto 0);
      fifoWrEn   : sl;
   end record;

   constant ADC_REG_INIT_C : AdcRegType := (
      slip       => '0',
      count      => (others => '0'),
      locked     => '0',
      fifoWrData => (others => (others => '0')),
      fifoWrEn   => '0');

   signal adcR   : AdcRegType := ADC_REG_INIT_C;
   signal adcRin : AdcRegType;


   -- Local Signals
   signal tmpAdcClk      : sl;
   signal adcBitClkIo    : sl;
   signal adcBitClkIoInv : sl;
   signal adcBitClkR     : sl;
   signal adcBitRst      : sl;

   signal adcFramePad   : sl;
   signal adcFrame      : slv(13 downto 0);
   signal adcDataPad    : slv(NUM_CHANNELS_G-1 downto 0);
   signal adcData       : Slv14Array(NUM_CHANNELS_G-1 downto 0);
   signal fifoDataValid : slv(1 downto 0);
   signal fifoDataEmpty : slv(1 downto 0);
   signal fifoDataOut   : slv(NUM_CHANNELS_G*16-1 downto 0);
   signal fifoDataIn    : slv(NUM_CHANNELS_G*16-1 downto 0);

   signal dummy      : slv(63 downto 0);
   signal readoutInt : AdcReadoutType;

begin
   -------------------------------------------------------------------------------------------------
   -- Synchronize adcR.locked across to axi clock domain and count falling edges on it
   -------------------------------------------------------------------------------------------------

   SynchronizerOneShotCnt_1 : entity surf.SynchronizerOneShotCnt
      generic map (
         TPD_G          => TPD_G,
         IN_POLARITY_G  => '0',
         OUT_POLARITY_G => '0',
         CNT_RST_EDGE_G => true,
         CNT_WIDTH_G    => 16)
      port map (
         dataIn     => adcR.locked,
         rollOverEn => '0',
         cntRst     => axiRst,
         dataOut    => open,
         cntOut     => lockedFallCount,
         wrClk      => adcBitClkR,
         wrRst      => adcBitRst,
         rdClk      => axiClk,
         rdRst      => axiRst);

   Synchronizer_1 : entity surf.Synchronizer
      generic map (
         TPD_G    => TPD_G,
         STAGES_G => 2)
      port map (
         clk     => axiClk,
         rst     => axiRst,
         dataIn  => adcR.locked,
         dataOut => lockedSync);

   -------------------------------------------------------------------------------------------------
   -- AXI Interface
   -------------------------------------------------------------------------------------------------
   axiComb : process (axiR, axiReadMaster, axiRst, axiWriteMaster, lockedFallCount, lockedSync,
                      readoutInt) is
      variable v         : AxiRegType;
      variable axiStatus : AxiLiteStatusType;
      variable axiResp   : slv(1 downto 0);
   begin
      v := axiR;

      v.dataDelaySet  := (others => '0');
      v.frameDelaySet := '0';

      if (readoutInt.valid = '1') then
         v.readout(0) := readoutInt;
         v.readout(1) := axiR.readout(0);
      end if;

      axiSlaveWaitTxn(axiWriteMaster, axiReadMaster, v.axiWriteSlave, v.axiReadSlave, axiStatus);

      if (axiStatus.writeEnable = '1') then
         -- Decode address and perform write
         case (axiWriteMaster.awaddr(7 downto 0)) is
            when X"00" =>
               v.dataDelay(0)    := axiWriteMaster.wdata(4 downto 0);
               v.dataDelaySet(0) := '1';
            when X"04" =>
               v.dataDelay(1)    := axiWriteMaster.wdata(4 downto 0);
               v.dataDelaySet(1) := '1';
            when X"08" =>
               v.dataDelay(2)    := axiWriteMaster.wdata(4 downto 0);
               v.dataDelaySet(2) := '1';
            when X"0C" =>
               v.dataDelay(3)    := axiWriteMaster.wdata(4 downto 0);
               v.dataDelaySet(3) := '1';
            when X"10" =>
               v.dataDelay(4)    := axiWriteMaster.wdata(4 downto 0);
               v.dataDelaySet(4) := '1';
            when X"20" =>
               v.frameDelay    := axiWriteMaster.wdata(4 downto 0);
               v.frameDelaySet := '1';
            when others => null;
         end case;

         -- Send Axi response
         axiSlaveWriteResponse(v.axiWriteSlave);
      end if;

      if (axiStatus.readEnable = '1') then
         -- Decode address and assign read data
         v.axiReadSlave.rdata := (others => '0');
         case (axiReadMaster.araddr(7 downto 0)) is
            when X"00" =>
               v.axiReadSlave.rdata(4 downto 0) := axiR.dataDelay(0);
            when X"04" =>
               v.axiReadSlave.rdata(4 downto 0) := axiR.dataDelay(1);
            when X"08" =>
               v.axiReadSlave.rdata(4 downto 0) := axiR.dataDelay(2);
            when X"0C" =>
               v.axiReadSlave.rdata(4 downto 0) := axiR.dataDelay(3);
            when X"10" =>
               v.axiReadSlave.rdata(4 downto 0) := axiR.dataDelay(4);
            when X"20" =>
               v.axiReadSlave.rdata(4 downto 0) := axiR.frameDelay;
            when X"30" =>
               v.axiReadSlave.rdata(16)          := lockedSync;
               v.axiReadSlave.rdata(15 downto 0) := lockedFallCount;

            -- Debug registers. Output the last 2 words received
            when X"80" =>
               v.axiReadSlave.rdata(15 downto 0)  := axiR.readout(0).data(0);
               v.axiReadSlave.rdata(31 downto 16) := axiR.readout(1).data(0);
            when X"84" =>
               v.axiReadSlave.rdata(15 downto 0)  := axiR.readout(0).data(1);
               v.axiReadSlave.rdata(31 downto 16) := axiR.readout(1).data(1);
            when X"88" =>
               v.axiReadSlave.rdata(15 downto 0)  := axiR.readout(0).data(2);
               v.axiReadSlave.rdata(31 downto 16) := axiR.readout(1).data(2);
            when X"8C" =>
               v.axiReadSlave.rdata(15 downto 0)  := axiR.readout(0).data(3);
               v.axiReadSlave.rdata(31 downto 16) := axiR.readout(1).data(3);
            when X"90" =>
               v.axiReadSlave.rdata(15 downto 0)  := axiR.readout(0).data(4);
               v.axiReadSlave.rdata(31 downto 16) := axiR.readout(1).data(4);
            when X"94" =>
               v.axiReadSlave.rdata(15 downto 0)  := axiR.readout(0).data(5);
               v.axiReadSlave.rdata(31 downto 16) := axiR.readout(1).data(5);
            when X"98" =>
               v.axiReadSlave.rdata(15 downto 0)  := axiR.readout(0).data(6);
               v.axiReadSlave.rdata(31 downto 16) := axiR.readout(1).data(6);
            when X"9C" =>
               v.axiReadSlave.rdata(15 downto 0)  := axiR.readout(0).data(7);
               v.axiReadSlave.rdata(31 downto 16) := axiR.readout(1).data(7);
            when others =>
               null;
         end case;

         -- Send Axi Response
         axiSlaveReadResponse(v.axiReadSlave);
      end if;

      if (axiRst = '1') then
         v := AXI_REG_INIT_C;
      end if;

      axiRin        <= v;
      axiWriteSlave <= axiR.axiWriteSlave;
      axiReadSlave  <= axiR.axiReadSlave;

   end process;

   axiSeq : process (axiClk) is
   begin
      if (rising_edge(axiClk)) then
         axiR <= axiRin after TPD_G;
      end if;
   end process axiSeq;



   -------------------------------------------------------------------------------------------------
   -- Create Clocks
   -------------------------------------------------------------------------------------------------

   AdcClk_I_Ibufds : IBUFDS
      generic map (
         DIFF_TERM  => true,
         IOSTANDARD => "LVDS_25")
      port map (
         I  => adc.dClkP,
         IB => adc.dClkN,
         O  => tmpAdcClk);

   -- IO Clock
   U_BUFIO : BUFIO
      port map (
         I => tmpAdcClk,
         O => adcBitClkIo);

   adcBitClkIoInv <= not adcBitClkIo;

   -- Regional clock
   U_AdcBitClkR : BUFR
      generic map (
         SIM_DEVICE  => "7SERIES",
         BUFR_DIVIDE => "7")
      port map (
         I   => tmpAdcClk,
         O   => adcBitClkR,
         CE  => '1',
         CLR => '0');

   -- Regional clock reset
   ADC_BITCLK_RST_SYNC : entity surf.RstSync
      generic map (
         TPD_G           => TPD_G,
         RELEASE_DELAY_G => 5)
      port map (
         clk      => adcBitClkR,
         asyncRst => adcClkRst,
         syncRst  => adcBitRst);


   -------------------------------------------------------------------------------------------------
   -- Deserializers
   -------------------------------------------------------------------------------------------------

   -- Frame signal input
   U_FrameIn : IBUFDS
      generic map (
         DIFF_TERM => true)
      port map (
         I  => adc.fClkP,
         IB => adc.fClkN,
         O  => adcFramePad);

   U_FRAME_DESERIALIZER : entity ldmx.AdcDeserializer
      generic map (
         TPD_G           => TPD_G,
         IODELAY_GROUP_G => IODELAY_GROUP_G)
      port map (
         clkIo    => adcBitClkIo,
         clkIoInv => adcBitClkIoInv,
         clkR     => adcBitClkR,
         rst      => adcBitRst,
         slip     => adcR.slip,
         sysClk   => axiClk,
         delay    => axiR.frameDelay,
         set      => axiR.frameDelaySet,
         iData    => adcFramePad,
         oData    => adcFrame);

   --------------------------------
   -- Data Input, 8 channels
   --------------------------------
   GenData : for i in NUM_CHANNELS_G-1 downto 0 generate

      -- Frame signal input
      U_DataIn : IBUFDS
         generic map (
            DIFF_TERM => true)
         port map (
            I  => adc.chP(i),
            IB => adc.chN(i),
            O  => adcDataPad(i));

      U_DATA_DESERIALIZER : entity ldmx.AdcDeserializer
         generic map (
            TPD_G           => TPD_G,
            IODELAY_GROUP_G => IODELAY_GROUP_G)
         port map (
            clkIo    => adcBitClkIo,
            clkIoInv => adcBitClkIoInv,
            clkR     => adcBitClkR,
            rst      => adcBitRst,
            slip     => adcR.slip,
            sysClk   => axiClk,
            delay    => axiR.dataDelay(i),
            set      => axiR.dataDelaySet(i),
            iData    => adcDataPad(i),
            oData    => adcData(i));
   end generate;

   -------------------------------------------------------------------------------------------------
   -- ADC Bit Clocked Logic
   -------------------------------------------------------------------------------------------------
   adcComb : process (adcR, adcData, adcFrame) is
      variable v : AdcRegType;
   begin
      v := adcR;

      ----------------------------------------------------------------------------------------------
      -- Slip bits until correct alignment seen
      ----------------------------------------------------------------------------------------------
      v.slip := '0';

      if (adcR.count = 0) then
         if (adcFrame = "11111110000000") then
            v.locked := '1';
         else
            v.locked := '0';
            v.slip   := '1';
            v.count  := adcR.count + 1;
         end if;
      end if;

      if (adcR.count /= 0) then
         v.count := adcR.count + 1;
      end if;

      ----------------------------------------------------------------------------------------------
      -- Look for Frame rising edges and write data to fifos
      ----------------------------------------------------------------------------------------------
      v.fifoWrEn := '1';                -- Always write data
      for i in NUM_CHANNELS_G-1 downto 0 loop
         if (adcR.locked = '1' and adcFrame = "11111110000000") then
            -- Locked, output adc data
            v.fifoWrData(i) := "00" & adcData(i);
         else
            -- Not locked
            v.fifoWrData(i) := "10" & "00000000000000";
         end if;
      end loop;

      adcRin <= v;

   end process adcComb;

   adcSeq : process (adcBitClkR, adcBitRst) is
   begin
      if (adcBitRst = '1') then
         adcR <= ADC_REG_INIT_C after TPD_G;
      elsif (rising_edge(adcBitClkR)) then
         adcR <= adcRin after TPD_G;
      end if;
   end process adcSeq;

   readoutInt.valid <= fifoDataValid(0);
   readout_glue : for i in NUM_CHANNELS_G-1 downto 0 generate
      fifoDataIn(i*16+15 downto i*16) <= adcR.fifoWrData(i);
      readoutInt.data(i)              <= fifoDataOut(i*16+15 downto i*16);
   end generate;

   readout <= readoutInt;
--   fifoDataValid <= not fifoDataEmpty;

--   IN_FIFO_0 : IN_FIFO
--      generic map (
--         ALMOST_EMPTY_VALUE => 1,                   -- Almost empty offset (1-2)
--         ALMOST_FULL_VALUE  => 1,                   -- Almost full offset (1-2)
--         ARRAY_MODE         => "ARRAY_MODE_4_X_4",  -- ARRAY_MODE_4_X_8, ARRAY_MODE_4_X_4
--         SYNCHRONOUS_MODE   => "FALSE"              -- Clock synchronous (FALSE)
--         )
--      port map (
--         -- FIFO Status Flags: 1-bit (each) output: Flags and other FIFO status outputs
--         ALMOSTEMPTY    => open,                    -- 1-bit output: Almost empty
--         ALMOSTFULL     => open,                    -- 1-bit output: Almost full
--         EMPTY          => fifoDataEmpty(0),        -- 1-bit output: Empty
--         FULL           => open,                    -- 1-bit output: Full
--         -- Q0-Q9: 8-bit (each) output: FIFO Outputs
--         Q0(3 downto 0) => fifoDataOut(3 downto 0),
--         Q0(7 downto 4) => dummy(3 downto 0),
--         Q1(3 downto 0) => fifoDataOut(7 downto 4),
--         Q1(7 downto 4) => dummy(7 downto 4),
--         Q2(3 downto 0) => fifoDataOut(11 downto 8),
--         Q2(7 downto 4) => dummy(11 downto 8),
--         Q3(3 downto 0) => fifoDataOut(15 downto 12),
--         Q3(7 downto 4) => dummy(15 downto 12),
--         Q4(3 downto 0) => fifoDataOut(19 downto 16),
--         Q4(7 downto 4) => dummy(19 downto 16),
--         Q5(3 downto 0) => fifoDataOut(23 downto 20),
--         Q5(7 downto 4) => fifoDataOut(43 downto 40),
--         Q6(3 downto 0) => fifoDataOut(27 downto 24),
--         Q6(7 downto 4) => fifoDataOut(47 downto 44),
--         Q7(3 downto 0) => fifoDataOut(31 downto 28),
--         Q7(7 downto 4) => dummy(23 downto 20),
--         Q8(3 downto 0) => fifoDataOut(35 downto 32),
--         Q8(7 downto 4) => dummy(27 downto 24),
--         Q9(3 downto 0) => fifoDataOut(39 downto 36),
--         Q9(7 downto 4) => dummy(31 downto 28),

--         -- D0-D9: 4-bit (each) input: FIFO inputs
--         D0             => fifoDataIn(3 downto 0),
--         D1             => fifoDataIn(7 downto 4),
--         D2             => fifoDataIn(11 downto 8),
--         D3             => fifoDataIn(15 downto 12),
--         D4             => fifoDataIn(19 downto 16),
--         D5(3 downto 0) => fifoDataIn(23 downto 20),
--         D5(7 downto 4) => fifoDataIn(43 downto 40),
--         D6(3 downto 0) => fifoDataIn(27 downto 24),
--         D6(7 downto 4) => fifoDataIn(47 downto 44),
--         D7             => fifoDataIn(31 downto 28),
--         D8             => fifoDataIn(35 downto 32),
--         D9             => fifoDataIn(39 downto 36),
--         -- FIFO Control Signals: 1-bit (each) input: Clocks, Resets and Enables
--         RDCLK          => axiClk,            -- 1-bit input: Read clock
--         RDEN           => fifoDataValid(0),  -- 1-bit input: Read enable
--         RESET          => adcBitRst,         -- 1-bit input: Reset
--         WRCLK          => adcBitClkR,        -- 1-bit input: Write clock
--         WREN           => adcR.fifoWrEn      -- 1-bit input: Write enable
--         );

--   IN_FIFO_1 : IN_FIFO
--      generic map (
--         ALMOST_EMPTY_VALUE => 1,                   -- Almost empty offset (1-2)
--         ALMOST_FULL_VALUE  => 1,                   -- Almost full offset (1-2)
--         ARRAY_MODE         => "ARRAY_MODE_4_X_4",  -- ARRAY_MODE_4_X_8, ARRAY_MODE_4_X_4
--         SYNCHRONOUS_MODE   => "FALSE"              -- Clock synchronous (FALSE)
--         )
--      port map (
--         -- FIFO Status Flags: 1-bit (each) output: Flags and other FIFO status outputs
--         ALMOSTEMPTY    => open,                    -- 1-bit output: Almost empty
--         ALMOSTFULL     => open,                    -- 1-bit output: Almost full
--         EMPTY          => fifoDataEmpty(1),        -- 1-bit output: Empty
--         FULL           => open,                    -- 1-bit output: Full
--         -- Q0-Q9: 8-bit (each) output: FIFO Outputs
--         Q0(3 downto 0) => fifoDataOut(51 downto 48),
--         Q0(7 downto 4) => dummy(35 downto 32),
--         Q1(3 downto 0) => fifoDataOut(55 downto 52),
--         Q1(7 downto 4) => dummy(39 downto 36),
--         Q2(3 downto 0) => fifoDataOut(59 downto 56),
--         Q2(7 downto 4) => dummy(43 downto 40),
--         Q3(3 downto 0) => fifoDataOut(63 downto 60),
--         Q3(7 downto 4) => dummy(47 downto 44),
--         Q4(3 downto 0) => fifoDataOut(67 downto 64),
--         Q4(7 downto 4) => dummy(51 downto 48),
--         Q5(3 downto 0) => fifoDataOut(71 downto 68),
--         Q5(7 downto 4) => dummy(55 downto 52),
--         Q6(3 downto 0) => fifoDataOut(75 downto 72),
--         Q6(7 downto 4) => dummy(59 downto 56),
--         Q7(3 downto 0) => fifoDataOut(79 downto 76),
--         Q7(7 downto 4) => dummy(63 downto 60),
--         Q8             => open,
--         Q9             => open,

--         -- D0-D9: 4-bit (each) input: FIFO inputs
--         D0             => fifoDataIn(51 downto 48),
--         D1             => fifoDataIn(55 downto 52),
--         D2             => fifoDataIn(59 downto 56),
--         D3             => fifoDataIn(63 downto 60),
--         D4             => fifoDataIn(67 downto 64),
--         D5(3 downto 0) => fifoDataIn(71 downto 68),
--         D5(7 downto 4) => (others => '0'),
--         D6(3 downto 0) => fifoDataIn(75 downto 72),
--         D6(7 downto 4) => (others => '0'),
--         D7             => fifoDataIn(79 downto 76),
--         D8             => (others => '0'),
--         D9             => (others => '0'),
--         -- FIFO Control Signals: 1-bit (each) input: Clocks, Resets and Enables
--         RDCLK          => axiClk,            -- 1-bit input: Read clock
--         RDEN           => fifoDataValid(1),  -- 1-bit input: Read enable
--         RESET          => adcBitRst,         -- 1-bit input: Reset
--         WRCLK          => adcBitClkR,        -- 1-bit input: Write clock
--         WREN           => adcR.fifoWrEn      -- 1-bit input: Write enable
--         );

   U_DataFifo : entity surf.SynchronizerFifo
      generic map (
         TPD_G         => TPD_G,
         MEMORY_TYPE_G => "distributed",
         DATA_WIDTH_G  => 80,
         ADDR_WIDTH_G  => 4,
         INIT_G        => "0")
      port map (
         rst    => adcBitRst,
         wr_clk => adcBitClkR,
         wr_en  => adcR.fifoWrEn,
         din    => fifoDataIn,
         rd_clk => axiClk,
         rd_en  => fifoDataValid(0),
         valid  => fifoDataValid(0),
         dout   => fifoDataOut);

end rtl;


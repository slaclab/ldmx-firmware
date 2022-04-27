-------------------------------------------------------------------------------
-- Title      : ClockPhaseShifter
-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2013 SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------




library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library surf;
use surf.StdRtlPkg.all;

library hps_daq;
use hps_daq.MmcmPhaseShiftPkg.all;
use surf.AxiLitePkg.all;

library unisim;
use unisim.vcomponents.all;

entity ClockPhaseShifter is
   generic (
      TPD_G           : time                 := 1 ns;
      NUM_OUTCLOCKS_G : integer range 1 to 6 := 4;
      CLKIN_PERIOD_G  : real                 := 24.0;
      DIVCLK_DIVIDE_G : integer              := 1;
      CLKFBOUT_MULT_G : integer              := 24,
      CLKOUT_DIVIDE_G : integer              := 24);
   port (
      axiClk : in sl;
      axiRst : in sl;

      axiReadMaster  : in  AxiLiteReadMasterType;
      axiReadSlave   : out AxiLiteReadSlaveType;
      axiWriteMaster : in  AxiLiteWriteMasterType;
      axiWriteSlave  : out AxiLiteWriteSlaveType;

      refClk    : in  sl;
      refClkRst : in  sl;               -- Figure out what to do with this
      clkOut    : out slv(NUM_OUTCLOCKS_G-1 downto 0);
      outputEn  : in  slv(NUM_OUTCLOCKS_G-1 downto 0) := (others => '1');
      rstOut    : out slv(NUM_OUTCLOCKS_G-1 downto 0)
      );
end ClockPhaseShifter;

architecture rtl of ClockPhaseShifter is

   signal drpClk       : sl;
   signal drpIn        : MmcmDrpInType;
   signal drpOut       : MmcmDrpOutType;
   signal shiftCtrlOut : MmcmPhaseShiftCtrlOutType;


   type RegType is record
      configReq   : sl;
      shiftCtrlIn : MmcmPhaseShiftCtrlInType;

      axiReadSlave  : AxiLiteReadSlaveType;
      axiWriteSlave : AxiLiteWriteSlaveType;
   end record RegType;

   constant REG_INIT_C : RegType := (
      configReq     => '0',
      shiftCtrlIn   => MMCM_PHASE_SHIFT_CTRL_IN_INIT_C,
      axiReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axiWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal mmcmRst       : sl;
   signal refClkRstFall : sl;
   signal clkOutInt     : slv(3 downto 0);


begin

   -- Synchronize refClkRst to axiClk
   SynchronizerEdge_1 : entity surf.SynchronizerEdge
      generic map (
         TPD_G          => TPD_G,
         RST_POLARITY_G => '1',
         RST_ASYNC_G    => false)
      port map (
         clk         => axiClk,
         rst         => axiRst,
         dataIn      => refClkRst,
         fallingEdge => refClkRstFall);

   -- Main process
   comb : process (axiRst, axiReadMaster, axiWriteMaster, r, refClkRstFall, shiftCtrlOut) is
      variable v         : RegType;
      variable axiStatus : AxiLiteStatusType;
   begin
      v := r;

      v.shiftCtrlIn.setConfig := '0';   -- Only pulsed when written to

      axiSlaveWaitTxn(axiWriteMaster, axiReadMaster, v.axiWriteSlave, v.axiReadSlave, axiStatus);

      if (axiStatus.writeEnable = '1') then
         -- Decode address and perform write
         case (axiWriteMaster.awaddr(7 downto 0)) is
            when X"00" =>
               v.shiftCtrlIn.shift0 := axiWriteMaster.wdata(8 downto 0);
            when X"04" =>
               v.shiftCtrlIn.shift1 := axiWriteMaster.wdata(8 downto 0);
            when X"08" =>
               v.shiftCtrlIn.shift2 := axiWriteMaster.wdata(8 downto 0);
            when X"0C" =>
               v.shiftCtrlIn.shift3 := axiWriteMaster.wdata(8 downto 0);
            when X"10" =>
               v.configReq := axiWriteMaster.wdata(0);
--            v.shiftCtrlIn.setConfig := axiWriteMaster.wdata(0);
            when others =>
               null;
         end case;

         -- Send Axi response
         axiSlaveWriteResponse(v.axiWriteSlave);
      end if;

      if (axiStatus.readEnable = '1') then
         -- Decode address and assign read data
         case (axiReadMaster.araddr(7 downto 0)) is
            when X"00" =>
               v.axiReadSlave.rdata(8 downto 0) := r.shiftCtrlIn.shift0;
            when X"04" =>
               v.axiReadSlave.rdata(8 downto 0) := r.shiftCtrlIn.shift1;
            when X"08" =>
               v.axiReadSlave.rdata(8 downto 0) := r.shiftCtrlIn.shift2;
            when X"0C" =>
               v.axiReadSlave.rdata(8 downto 0) := r.shiftCtrlIn.shift3;
            when X"10" =>
               v.axiReadSlave.rdata(1) := shiftCtrlOut.configDone;
            when others => null;
         end case;

         -- Send Axi Response
         axiSlaveReadResponse(v.axiReadSlave);
      end if;

      -- Upon falling edge of refClkRst, trigger setConfig req
      if (refClkRstFall = '1') then
         v.configReq := '1';
      end if;

      if (r.configReq = '1' and shiftCtrlOut.configDone = '1') then
         v.shiftCtrlIn.setConfig := '1';
         v.configReq             := '0';
      end if;

      ----------------------------------------------------------------------------------------------
      -- Reset
      ----------------------------------------------------------------------------------------------
      if (axiRst = '1') then
         v := REG_INIT_C;
      end if;

      rin <= v;

      axiReadSlave  <= r.axiReadSlave;
      axiWriteSlave <= r.axiWriteSlave;

   end process comb;

   seq : process (axiClk) is
   begin
      if (rising_edge(axiClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;


   MMCM_PHASE_SHIFT_CTR : entity hps_daq.MmcmPhaseShiftCtrl
      generic map (
         TPD_G => TPD_G)
      port map (
         clk     => axiClk,
         sRst    => axiRst,
         drpClk  => drpClk,
         drpIn   => drpIn,
         drpOut  => drpOut,
         userIn  => r.shiftCtrlIn,
         userOut => shiftCtrlOut);

   -- MMCM rst port is async. Hopefully has internal rst synchronizer
   mmcmRst <= refClkRst or drpIn.rst;


   -- MMCM Created by coregen
   CLOCK_SHIFTER_MMCM : entity hps_daq.PhaseShiftMmcm
      port map (
         TPD_G           => TPD_G,
         NUM_OUTCLOCKS_G => NUM_OUTCLOCKS_G,
         CLKIN_PERIOD_G  => CLKIN_PERIOD_G,
         DIVCLK_DIVIDE_G => DIVCLK_DIVIDE_G,
         CLKFBOUT_MULT_G => CLKFBOUT_MULT_G
         CLKOUT_DIVIDE_G => CLKOUT_DIVIDE_G)
      port map(
         clk41    => refClk,
         -- Output clocks
         clkOut   => clkOutInt,
         outputEn => outputEn,
         -- Ports for dynamic reconfiguration
         daddr    => drpIn.daddr,
         dclk     => drpClk,
         den      => drpIn.den,
         din      => drpIn.di,
         dout     => drpOut.do,
         drdy     => drpOut.drdy,
         dwe      => drpIn.dwe,
         -- Other control and status signals
         locked   => drpOut.locked,
         rst      => mmcmRst);          --drpIn.rst);

   RST_GEN : for i in 3 downto 0 generate
      RstSync_1 : entity surf.RstSync
         generic map (
            TPD_G           => TPD_G,
            IN_POLARITY_G   => '0',
            OUT_POLARITY_G  => '1',
            RELEASE_DELAY_G => 3)
         port map (
            clk      => clkOutInt(i),
            asyncRst => drpOut.locked,
            syncRst  => rstOut(i));
   end generate RST_GEN;

   clkOut <= clkOutInt;


end architecture rtl;

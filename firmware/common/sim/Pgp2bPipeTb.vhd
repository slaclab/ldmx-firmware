-------------------------------------------------------------------------------
-- Title      : Testbench for design "Pgp2bPipe"
-------------------------------------------------------------------------------
-- File       : Pgp2bPipeTb.vhd
-- Author     : Benjamin Reese  <bareese@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-04-21
-- Last update: 2019-11-20
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2015 SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
use surf.Pgp2bPkg.all;

library hps_daq;

----------------------------------------------------------------------------------------------------

entity Pgp2bPipeTb is

end entity Pgp2bPipeTb;

----------------------------------------------------------------------------------------------------

architecture tb of Pgp2bPipeTb is

   -- component generics
   constant TPD_G                      : time                 := 1 ns;
   constant MEMORY_TYPE_G              : string               := "block";
   constant TX_FIFO_SYNC_G             : BooleanArray(0 to 3) := (others => true);
   constant TX_FIFO_ADDR_WIDTHS_G      : IntegerArray(0 to 3) := (others => 9);
   constant TX_FIFO_PAUSE_THRESHOLDS_G : IntegerArray(0 to 3) := (others => 1);
   constant RX_FIFO_SYNC_G             : BooleanArray(0 to 3) := (others => true);
   constant RX_FIFO_ADDR_WIDTHS_G      : IntegerArray(0 to 3) := (others => 9);
   constant RX_FIFO_PAUSE_THRESHOLDS_G : IntegerArray(0 to 3) := (others => 1);
   constant VC_INTERLEAVE_G            : integer              := 1;
   constant PAYLOAD_CNT_TOP_G          : integer              := 7;
   constant NUM_VC_EN_G                : integer range 1 to 4 := 4;

   -- component ports
   signal pgpClk        : sl;
   signal pgpClkRst     : sl;
   signal txAxisClks    : slv(3 downto 0);
   signal txAxisRsts    : slv(3 downto 0);
   signal pgpTxIn       : Pgp2bTxInType                    := PGP2B_TX_IN_INIT_C;
   signal txAxisMasters : AxiStreamMasterArray(3 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal txAxisSlaves  : AxiStreamSlaveArray(3 downto 0);
   signal txAxisCtrl    : AxiStreamCtrlArray(3 downto 0);
   signal rxAxisClks    : slv(3 downto 0);
   signal rxAxisRsts    : slv(3 downto 0);
   signal pgpRxOut      : Pgp2bRxOutType;
   signal rxAxisMasters : AxiStreamMasterArray(3 downto 0);
   signal rxAxisSlaves  : AxiStreamSlaveArray(3 downto 0)  := (others => AXI_STREAM_SLAVE_FORCE_C);
   signal rxAxisCtrl    : AxiStreamCtrlArray(3 downto 0)   := (others => AXI_STREAM_CTRL_INIT_C);
   signal trig          : sl                               := '0';

begin

   ClkRst_1 : entity surf.ClkRst
      generic map (
         CLK_PERIOD_G      => 8 ns,
         RST_START_DELAY_G => 0 ns)
      port map (
         clkP => pgpClk,
         rst  => pgpClkRst);

   clks : for i in 3 downto 0 generate
      txAxisClks(i) <= pgpClk;
      txAxisRsts(i) <= pgpClkRst;
      rxAxisClks(i) <= pgpClk;
      rxAxisRsts(i) <= pgpClkRst;
   end generate clks;

   -- component instantiation
   DUT : entity hps_daq.Pgp2bPipe
      generic map (
         TPD_G                      => TPD_G,
         MEMORY_TYPE_G              => MEMORY_TYPE_G,
         TX_FIFO_SYNC_G             => TX_FIFO_SYNC_G,
         TX_FIFO_ADDR_WIDTHS_G      => TX_FIFO_ADDR_WIDTHS_G,
         TX_FIFO_PAUSE_THRESHOLDS_G => TX_FIFO_PAUSE_THRESHOLDS_G,
         RX_FIFO_SYNC_G             => RX_FIFO_SYNC_G,
         RX_FIFO_ADDR_WIDTHS_G      => RX_FIFO_ADDR_WIDTHS_G,
         RX_FIFO_PAUSE_THRESHOLDS_G => RX_FIFO_PAUSE_THRESHOLDS_G,
         VC_INTERLEAVE_G            => VC_INTERLEAVE_G,
         PAYLOAD_CNT_TOP_G          => PAYLOAD_CNT_TOP_G,
         NUM_VC_EN_G                => NUM_VC_EN_G)
      port map (
         pgpClk        => pgpClk,
         pgpClkRst     => pgpClkRst,
         txAxisClks    => txAxisClks,
         txAxisRsts    => txAxisRsts,
         pgpTxIn       => pgpTxIn,
         txAxisMasters => txAxisMasters,
         txAxisSlaves  => txAxisSlaves,
         txAxisCtrl    => txAxisCtrl,
         rxAxisClks    => rxAxisClks,
         rxAxisRsts    => rxAxisRsts,
         pgpRxOut      => pgpRxOut,
         rxAxisMasters => rxAxisMasters,
         rxAxisSlaves  => rxAxisSlaves,
         rxAxisCtrl    => rxAxisCtrl);

   SsiPrbsTx_1 : entity surf.SsiPrbsTx
      generic map (
         TPD_G                      => TPD_G,
         GEN_SYNC_FIFO_G            => true,
         MASTER_AXI_STREAM_CONFIG_G => SSI_PGP2B_CONFIG_C)
      port map (
         mAxisClk     => pgpClk,
         mAxisRst     => pgpClkRst,
         mAxisMaster  => txAxisMasters(0),
         mAxisSlave   => txAxisSlaves(0),
         locClk       => pgpClk,
         locRst       => pgpClkRst,
         trig         => trig,
         packetLength => toSlv(4, 32),
         forceEofe    => '0',
         busy         => open);

   dataStream : process is
   begin
      if (pgpRxOut.linkReady = '0') then
         wait until pgpRxOut.linkReady = '1';
         wait for 10 us;
      else
         wait for 50 ns;
         wait until pgpClk = '1';
         trig <= '0';
         wait until pgpClk = '1';
--         trig <= '0';
         wait until pgpClk = '1';
      end if;

   end process dataStream;

   -- waveform generation
   WaveGen_Proc : process
      variable w : time := 20 us;
   begin
      -- insert signal assignments here
      if (pgpRxOut.linkReady = '0') then
         wait until pgpRxOut.linkReady = '1';
         wait for 10 us;
      else

         wait until pgpClk = '1';

         wait for 100 ns;

         wait until pgpClk = '1';

         pgpTxIn.opCode   <= "01011010";
         pgpTxIn.opCodeEn <= '1';

         wait until pgpClk = '1';

         pgpTxIn.opCode   <= "00000000";
         pgpTxIn.opCodeEn <= '0';

         wait until pgpClk = '1';

      end if;

--      w := w - 1 us;
--      if (w = 1 us) then
--         w := 20 us;
--      end if;
   end process WaveGen_Proc;



end architecture tb;

----------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : Pgp2bPipe.vhd
-- Author     : Benjamin Reese  <bareese@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2013-09-26
-- Last update: 2019-11-20
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Takes 8 80-bit (5x16) adc frames and reformats them into
--              7 80 bit (5x14) frames.
-------------------------------------------------------------------------------
-- Copyright (c) 2013 SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


library surf;
use surf.StdRtlPkg.all;
use surf.AxiStreamPkg.all;
use surf.Pgp2bPkg.all;

entity Pgp2bPipe is

   generic (
      TPD_G                      : time                 := 1 ns;
      MEMORY_TYPE_G              : string               := "block";
      TX_FIFO_SYNC_G             : BooleanArray(0 to 3) := (others => false);
      TX_FIFO_ADDR_WIDTHS_G      : IntegerArray(0 to 3) := (others => 9);
      TX_FIFO_PAUSE_THRESHOLDS_G : IntegerArray(0 to 3) := (others => 1);
      RX_FIFO_SYNC_G             : BooleanArray(0 to 3) := (others => false);
      RX_FIFO_ADDR_WIDTHS_G      : IntegerArray(0 to 3) := (others => 9);
      RX_FIFO_PAUSE_THRESHOLDS_G : IntegerArray(0 to 3) := (others => 1);
      VC_INTERLEAVE_G            : integer              := 1;
      PAYLOAD_CNT_TOP_G          : integer              := 7;
      NUM_VC_EN_G                : integer range 1 to 4 := 4);

   port (
      pgpClk    : in sl;
      pgpClkRst : in sl;

      txAxisClks    : in  slv(3 downto 0);
      txAxisRsts    : in  slv(3 downto 0);
      pgpTxIn       : in  Pgp2bTxInType := PGP2B_TX_IN_INIT_C;
      txAxisMasters : in  AxiStreamMasterArray(3 downto 0);
      txAxisSlaves  : out AxiStreamSlaveArray(3 downto 0);
      txAxisCtrl    : out AxiStreamCtrlArray(3 downto 0);

      rxAxisClks    : in  slv(3 downto 0);
      rxAxisRsts    : in  slv(3 downto 0);
      pgpRxOut      : out Pgp2bRxOutType;
      rxAxisMasters : out AxiStreamMasterArray(3 downto 0);
      rxAxisSlaves  : in  AxiStreamSlaveArray(3 downto 0);
      rxAxisCtrl    : in  AxiStreamCtrlArray(3 downto 0));
end entity Pgp2bPipe;

architecture rtl of Pgp2bPipe is

   signal pgpTxAxisMasters : AxiStreamMasterArray(3 downto 0);
   signal pgpTxAxisSlaves  : AxiStreamSlaveArray(3 downto 0);

   signal pgpRxAxisMasters : AxiStreamMasterArray(3 downto 0);
   signal pgpRxAxisCtrl    : AxiStreamCtrlArray(3 downto 0);

   signal phyTxOut : Pgp2bTxPhyLaneOutType;
   signal phyRxIn  : Pgp2bRxPhyLaneInType;

begin

   GEN_FIFOS : for i in NUM_VC_EN_G-1 downto 0 generate
      AxiStreamFifo_TX : entity surf.AxiStreamFifo
         generic map (
            TPD_G               => TPD_G,
            MEMORY_TYPE_G       => MEMORY_TYPE_G,
            GEN_SYNC_FIFO_G     => TX_FIFO_SYNC_G(i),
            FIFO_ADDR_WIDTH_G   => TX_FIFO_ADDR_WIDTHS_G(i),  -- Double check. 
            FIFO_FIXED_THRESH_G => true,
            FIFO_PAUSE_THRESH_G => TX_FIFO_PAUSE_THRESHOLDS_G(i),
            SLAVE_AXI_CONFIG_G  => SSI_PGP2B_CONFIG_C,
            MASTER_AXI_CONFIG_G => SSI_PGP2B_CONFIG_C)
         port map (
            sAxisClk    => txAxisClks(i),
            sAxisRst    => txAxisRsts(i),
            sAxisMaster => txAxisMasters(i),
            sAxisSlave  => txAxisSlaves(i),
            sAxisCtrl   => txAxisCtrl(i),
            mAxisClk    => pgpClk,
            mAxisRst    => pgpClkRst,
            mAxisMaster => pgpTxAxisMasters(i),
            mAxisSlave  => pgpTxAxisSlaves(i));

      AxiStreamFifo_RX : entity surf.AxiStreamFifo
         generic map (
            TPD_G               => TPD_G,
            MEMORY_TYPE_G       => MEMORY_TYPE_G,
            GEN_SYNC_FIFO_G     => RX_FIFO_SYNC_G(i),
            FIFO_ADDR_WIDTH_G   => RX_FIFO_ADDR_WIDTHS_G(i),  -- Double check. 
            FIFO_FIXED_THRESH_G => true,
            FIFO_PAUSE_THRESH_G => RX_FIFO_PAUSE_THRESHOLDS_G(i),
            SLAVE_AXI_CONFIG_G  => SSI_PGP2B_CONFIG_C,
            MASTER_AXI_CONFIG_G => SSI_PGP2B_CONFIG_C)
         port map (
            sAxisClk    => pgpClk,
            sAxisRst    => pgpClkRst,
            sAxisMaster => pgpRxAxisMasters(i),
            sAxisSlave  => open,
            sAxisCtrl   => pgpRxAxisCtrl(i),
            mAxisClk    => rxAxisClks(i),
            mAxisRst    => rxAxisRsts(i),
            mAxisMaster => rxAxisMasters(i),
            mAxisSlave  => rxAxisSlaves(i));

   end generate GEN_FIFOS;

   phyRxIn.data    <= phyTxOut.data;
   phyRxIn.dataK   <= phyTxOut.dataK;
   phyRxIn.dispErr <= (others => '0');
   phyRxIn.decErr  <= (others => '0');

--   pgpTxIn.locData <= txStatus;
--   rxStatus        <= pgpRxOut.remLinkData;
   Pgp2bLane_1 : entity surf.Pgp2bLane
      generic map (
         TPD_G             => TPD_G,
         LANE_CNT_G        => 1,
         VC_INTERLEAVE_G   => VC_INTERLEAVE_G,
         PAYLOAD_CNT_TOP_G => PAYLOAD_CNT_TOP_G,
         NUM_VC_EN_G       => NUM_VC_EN_G,
         TX_ENABLE_G       => true,
         RX_ENABLE_G       => true)
      port map (
         pgpTxClk         => pgpClk,
         pgpTxClkRst      => pgpClkRst,
         pgpTxIn          => pgpTxIn,
         pgpTxMasters     => pgpTxAxisMasters,
         pgpTxSlaves      => pgpTxAxisSlaves,
         phyTxLanesOut(0) => phyTxOut,
         phyTxReady       => '1',
         pgpRxClk         => pgpClk,
         pgpRxClkRst      => pgpClkRst,
         pgpRxOut         => pgpRxOut,
         pgpRxMasters     => pgpRxAxisMasters,
         pgpRxCtrl        => pgpRxAxisCtrl,
         phyRxLanesIn(0)  => phyRxIn,
         phyRxReady       => '1',
         phyRxInit        => open);



end architecture rtl;

-------------------------------------------------------------------------------
-- Title      : MGT RefClk (0/1) Multiplexer
-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: MGT RefClk (0/1) Multiplexer. Needed to route recovered clocks
--              from links outside of the fabric; also needed to drive RX/TX
--              user clocks between quads
-------------------------------------------------------------------------------
-- This file is part of 'SLAC Firmware Standard Library'.
-- It is subject to the license terms in the LICENSE.txt file found in the
-- top-level directory of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of 'SLAC Firmware Standard Library', including this file,
-- may be copied, modified, propagated, or distributed except according to
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library surf;
use surf.StdRtlPkg.all;

library unisim;
use unisim.vcomponents.all;

entity MgtRefClkMux is
   generic (
      TPD_G              : time    := 1 ns;
      PGP_QUADS_G        : integer := 1;
      PGP_LANES_G        : integer := 4;
      BITTWARE_XUPVV8_G  : boolean := false;
      TRACKER_FRONTEND_G : boolean := false;
      APX_G              : boolean := false);
   port (
      -- FPGA I/O
      qsfpRefClkP : in  slv(PGP_QUADS_G-1 downto 0);
      qsfpRefClkN : in  slv(PGP_QUADS_G-1 downto 0);
      qsfpRecClkP : out slv(PGP_QUADS_G-1 downto 0);
      qsfpRecClkN : out slv(PGP_QUADS_G-1 downto 0);
      -- MGT I/O
      rxRecClk    : in  slv(PGP_QUADS_G*PGP_LANES_G-1 downto 0);
      mgtRefClk   : out slv(PGP_QUADS_G-1 downto 0);
      userRefClk  : out slv(PGP_QUADS_G-1 downto 0);
      -- RX/TXCLK
      pgpTxOutClk : in  slv(PGP_QUADS_G*PGP_LANES_G-1 downto 0);
      pgpRxOutClk : in  slv(PGP_QUADS_G*PGP_LANES_G-1 downto 0);
      pgpTxClk    : out slv(PGP_QUADS_G*PGP_LANES_G-1 downto 0);
      pgpRxClk    : out slv(PGP_QUADS_G*PGP_LANES_G-1 downto 0));
end entity MgtRefClkMux;

architecture mapping of MgtRefClkMux is

   signal mgtUserRefClk : slv(PGP_QUADS_G-1 downto 0) := (others => '0');

begin

   GEN_BITTWARE : if BITTWARE_XUPVV8_G generate

      GEN_QUADS_MGTREFCLK : for quad in PGP_QUADS_G-1 downto 0 generate

         U_mgtRefClk : IBUFDS_GTE4
            generic map (
               REFCLK_EN_TX_PATH  => '0',
               REFCLK_HROW_CK_SEL => "00",  -- 2'b00: ODIV2 = O
               REFCLK_ICNTL_RX    => "00")
            port map (
               I     => qsfpRefClkP(quad),
               IB    => qsfpRefClkN(quad),
               CEB   => '0',
               ODIV2 => mgtUserRefClk(quad),
               O     => mgtRefClk(quad));

         U_mgtUserRefClk : BUFG_GT
            port map (
               I       => mgtUserRefClk(quad),
               CE      => '1',
               CEMASK  => '1',
               CLR     => '0',
               CLRMASK => '1',
               DIV     => "000",
               O       => userRefClk(quad));

         U_mgtRecClk : OBUFDS_GTE4
            generic map (
               REFCLK_EN_TX_PATH => '1',
               REFCLK_ICNTL_TX => "00000")
            port map (
               O   => qsfpRecClkP(quad),
               OB  => qsfpRecClkN(quad),
               CEB => '0',
               I   => rxRecClk(quad*PGP_LANES_G+0)); -- using rxRecClk from Channel=0

      end generate GEN_QUADS_MGTREFCLK;

      ---------------------------
      -- RXOUTCLK/TXOUTCLK Muxing
      ---------------------------
      -- Every GT uses their own rxoutclk as their rxusrclk;
      pgpRxClk <= pgpRxOutClk;

      -- The GTs that recover the timing stream provide an rxoutclk;
      -- (These GTs are in quad=0 and quad=2 for the BittWare)
      -- that rxoutclk is looped back to their own rxusrclk; (already done above)
      -- that rxoutclk also drives the FEB-GT txusrclk ports though
      -- (i.e. the FEB-GT txoutclk is not really used)

      GEN_QUAD0_TXUSRCLK : if PGP_QUADS_G > 0 generate
         -- quad=0 (120) clocks itself
         pgpTxClk(3 downto 0) <= pgpTxOutClk(3 downto 0);
      end generate GEN_QUAD0_TXUSRCLK;

      GEN_QUAD1_TXUSRCLK : if PGP_QUADS_G > 1 generate
         -- quad=1 (121) is clocked by 120/lane=0
         -- (120/lane=0 also provides the recClk to the external jitter cleaner)
         pgpTxClk(7 downto 4) <= (others => pgpRxOutClk(0));
      end generate GEN_QUAD1_TXUSRCLK;

      GEN_QUAD2_TXUSRCLK : if PGP_QUADS_G > 2 generate
         -- quad=2 (122) clocks itself
         pgpTxClk(11 downto 8) <= pgpTxOutClk(11 downto 8);
      end generate GEN_QUAD2_TXUSRCLK;

      GEN_QUAD3_TXUSRCLK : if PGP_QUADS_G > 3 generate
         -- quad=3 (123) is clocked by 122/lane=0
         -- (122/lane=0 also provides the recClk to the external jitter cleaner)
         pgpTxClk(15 downto 12) <= (others => pgpRxOutClk(8));
      end generate GEN_QUAD3_TXUSRCLK;

      GEN_QUAD4_TXUSRCLK : if PGP_QUADS_G > 4 generate
         -- quad=4 (124) is clocked by 120/lane=0
         -- (120/lane=0 also provides the recClk to the external jitter cleaner)
         pgpTxClk(19 downto 16) <= (others => pgpRxOutClk(0));
      end generate GEN_QUAD4_TXUSRCLK;

      GEN_QUAD5_TXUSRCLK : if PGP_QUADS_G > 5 generate
         -- quad=5 (125) is clocked by 120/lane=0
         -- (120/lane=0 also provides the recClk to the external jitter cleaner)
         pgpTxClk(23 downto 20) <= (others => pgpRxOutClk(0));
      end generate GEN_QUAD5_TXUSRCLK;

      GEN_QUAD6_TXUSRCLK : if PGP_QUADS_G > 6 generate
         -- quad=6 (127) is clocked by 122/lane=0
         -- (122/lane=0 also provides the recClk to the external jitter cleaner)
         pgpTxClk(27 downto 24) <= (others => pgpRxOutClk(8));
      end generate GEN_QUAD6_TXUSRCLK;

      GEN_QUAD7_TXUSRCLK : if PGP_QUADS_G > 7 generate
         -- quad=7 (131) is clocked by 122/lane=0
         -- (122/lane=0 also provides the recClk to the external jitter cleaner)
         pgpTxClk(31 downto 28) <= (others => pgpRxOutClk(8));
      end generate GEN_QUAD7_TXUSRCLK;


   end generate GEN_BITTWARE;

   --GEN_TRACKER_FRONTEND : if GEN_TRACKER_FRONTEND_G generate
      -- https://www.dumpaday.com/wp-content/uploads/2013/01/soon-bird-and-cat.jpg
   --end generate GEN_TRACKER_FRONTEND;

   --GEN_APX : if APX_G generate
      -- https://www.dumpaday.com/wp-content/uploads/2013/01/soon-bird-and-cat.jpg
   --end generate GEN_APX;

end architecture mapping;

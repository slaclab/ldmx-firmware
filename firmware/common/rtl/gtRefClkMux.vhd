-------------------------------------------------------------------------------
-- Title      : MGT RefClk (0/1) Multiplexer
-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: MGT RefClk (0/1) Multiplexer
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

entity gtRefClkMux is
   generic (
      TPD_G              : time    := 1 ns;
      QUAD_G             : integer := 0;
      BITTWARE_XUPVV8_G  : boolean := false;
      TRACKER_FRONTEND_G : boolean := false;
      APX_G              : boolean := false);
   port (
      -- FPGA I/O
      qsfpRefClkP : in  sl;
      qsfpRefClkN : in  sl;
      qsfpRecClkP : out sl;
      qsfpRecClkN : out sl;
      -- MGT I/O
      rxRecClk    : in  sl;
      mgtRefClk   : out sl;
      userRefClk  : out sl);

end entity gtRefClkMux;

architecture mapping of gtRefClkMux is

   signal mgtUserRefClk : sl := '0';

begin

   GEN_BITTWARE : if BITTWARE_XUPVV8_G generate

      U_mgtRefClk : IBUFDS_GTE4
         generic map (
            REFCLK_EN_TX_PATH  => '0',
            REFCLK_HROW_CK_SEL => "00",  -- 2'b00: ODIV2 = O
            REFCLK_ICNTL_RX    => "00")
         port map (
            I     => qsfpRefClkP,
            IB    => qsfpRefClkN,
            CEB   => '0',
            ODIV2 => mgtUserRefClk,
            O     => mgtRefClk);

      U_mgtUserRefClk : BUFG_GT
         port map (
            I       => mgtUserRefClk,
            CE      => '1',
            CEMASK  => '1',
            CLR     => '0',
            CLRMASK => '1',
            DIV     => "000",
            O       => userRefClk);

      U_mgtRecClk : OBUFDS_GTE4
         generic map (
            REFCLK_EN_TX_PATH => '1',
            REFCLK_ICNTL_TX => "00000")
         port map (
            O   => qsfpRecClkP,
            OB  => qsfpRecClkN,
            CEB => '0',
            I   => rxRecClk);

   end generate GEN_BITTWARE;

   --GEN_TRACKER_FRONTEND : if GEN_TRACKER_FRONTEND_G generate
      -- https://www.dumpaday.com/wp-content/uploads/2013/01/soon-bird-and-cat.jpg
   --end generate GEN_TRACKER_FRONTEND;

   --GEN_APX : if APX_G generate
      -- https://www.dumpaday.com/wp-content/uploads/2013/01/soon-bird-and-cat.jpg
   --end generate GEN_APX;

end architecture mapping;

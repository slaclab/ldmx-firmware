-------------------------------------------------------------------------------
-- Title      : ReadoutRequest FIFO
-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Attaches a timestamp to each incomming trigger
-------------------------------------------------------------------------------
-- This file is part of HPS. It is subject to
-- the license terms in the LICENSE.txt file found in the top-level directory
-- of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of HPS, including this file, may be
-- copied, modified, propagated, or distributed except according to the terms
-- contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


library surf;
use surf.StdRtlPkg.all;

library ldmx;
use ldmx.FcPkg.all;

entity ReadoutRequestFifo is

   generic (
      TPD_G : time := 1 ns);

   port (
      rst : in sl;

      fcClk185 : in sl;
      fcBus    : in FastControlBusType;

      sysClk       : in  sl;
      sysRst       : in  sl;
      rorTimestamp : out FcTimestampType;
      rdEn         : in  sl);

end entity ReadoutRequestFifo;

architecture rtl of ReadoutRequestFifo is

   signal fifoDin   : slv(FC_TIMESTAMP_SIZE_C-1 downto 0);
   signal fifoDout  : slv(FC_TIMESTAMP_SIZE_C-1 downto 0);
   signal fifoValid : sl;

begin

   fifoDin <= toSlv(fcBus.readoutRequest);

   ROR_FC_MSG_FIFO : entity surf.Fifo
      generic map (
         TPD_G           => TPD_G,
         GEN_SYNC_FIFO_G => false,
         MEMORY_TYPE_G   => "distributed",
         FWFT_EN_G       => true,
         DATA_WIDTH_G    => FC_TIMESTAMP_SIZE_C,
         ADDR_WIDTH_G    => 6)
      port map (
         rst           => rst,
         wr_clk        => fcClk185,
         wr_en         => fcBus.readoutRequest.valid,
         wr_data_count => open,
         din           => fifoDin,
         rd_clk        => sysClk,
         rd_en         => rdEn,
         dout          => fifoDout,
         valid         => fifoValid);

   rorTimestamp <= toFcTimestamp(fifoDout, fifoValid);


end architecture rtl;

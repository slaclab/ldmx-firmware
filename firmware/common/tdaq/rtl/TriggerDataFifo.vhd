-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- This file is part of LDMX. It is subject to
-- the license terms in the LICENSE.txt file found in the top-level directory
-- of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of LDMX, including this file, may be
-- copied, modified, propagated, or distributed except according to the terms
-- contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library surf;
use surf.StdRtlPkg.all;

library ldmx_tdaq;
use ldmx_tdaq.TriggerPkg.all;

entity TriggerDataFifo is

   generic (
      TPD_G           : time                  := 1 ns;
      GEN_SYNC_FIFO_G : boolean               := false;
      SYNTH_MODE_G    : string                := "inferred";
      MEMORY_TYPE_G   : string                := "block";
      ADDR_WIDTH_G    : integer range 4 to 48 := 4
      );

   port (
      rst : in sl;

      wrClk  : in  sl;
      wrEn   : in  sl;
      wrFull : out sl;
      wrData : in  TriggerDataType;

      rdClk   : in  sl;
      rdEn    : in  sl;
      rdData  : out TriggerDataType;
      rdValid : out sl);

end entity TriggerDataFifo;

architecture rtl of TriggerDataFifo is

   signal fifoDin   : slv(TRIGGER_WORD_SIZE_C-1 downto 0);
   signal fifoDout  : slv(TRIGGER_WORD_SIZE_C-1 downto 0);
   signal fifoValid : sl;

begin

   -- Convert to SLV for FIFO
   fifoDin <= toSlv(wrMsg);

   U_Fifo_1 : entity surf.Fifo
      generic map (
         TPD_G           => TPD_G,
         FWFT_EN_G       => true,
         GEN_SYNC_FIFO_G => GEN_SYNC_FIFO_G,
         SYNTH_MODE_G    => SYNTH_MODE_G,
         MEMORY_TYPE_G   => MEMORY_TYPE_G,
         PIPE_STAGES_G   => 0,
         DATA_WIDTH_G    => FC_TIMESTAMP_SIZE_C,
         ADDR_WIDTH_G    => ADDR_WIDTH_G)
      port map (
         rst           => rst,          -- [in]
         wr_clk        => wrClk,        -- [in]
         wr_en         => wrEn,         -- [in]
         din           => fifoDin,      -- [in]
         wr_data_count => open,         -- [out]
         full          => wrFull,       -- [out]
         rd_clk        => rdClk,        -- [in]
         rd_en         => rdEn,         -- [in]
         dout          => fifoDout,     -- [out]
         rd_data_count => open,         -- [out]
         valid         => fifoValid);   -- [out]

   rdValid <= fifoValid;
   rdData  <= toTriggerData(fifoDout, fifoValid);

end architecture rtl;

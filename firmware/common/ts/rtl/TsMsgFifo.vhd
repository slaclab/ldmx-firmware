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
use ldmx_tdaq.FcPkg.all;

library ldmx_ts;
use ldmx_ts.TsPkg.all;


entity TsMsgFifo is

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
      wrMsg  : in  TsData6ChMsgType;

      rdClk   : in  sl;
      rdEn    : in  sl;
      rdMsg   : out TsData6ChMsgType;
      rdValid : out sl);

end entity TsMsgFifo;

architecture rtl of TsMsgFifo is

   signal fifoDin   : slv(TS_DATA_6CH_MSG_SIZE_C-1 downto 0);
   signal fifoDout  : slv(TS_DATA_6CH_MSG_SIZE_C-1 downto 0);
   signal fifoValid : sl;

begin

   -- Convert to SLV for FIFO
   fifoDin <= toSlv(wrMsg);

   U_Fifo_1 : entity surf.Fifo
      generic map (
         TPD_G           => TPD_G,
         GEN_SYNC_FIFO_G => GEN_SYNC_FIFO_G,
         SYNTH_MODE_G    => SYNTH_MODE_G,
         MEMORY_TYPE_G   => MEMORY_TYPE_G,
         PIPE_STAGES_G   => 0,
         DATA_WIDTH_G    => TS_DATA_6CH_MSG_SIZE_C,
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
   rdMsg   <= toTsData6ChMsg(fifoDout, fifoValid);

end architecture rtl;

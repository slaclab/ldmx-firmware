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
use surf.AxiLitePkg.all;

library ldmx;
use ldmx.TsPkg.all;
use ldmx.FcPkg.all;

entity TsTxMsgPlayback is

   generic (
      TPD_G      : time    := 1 ns;
      TS_LANES_G : integer := 2);
   port (
      --------------
      -- Main Output
      --------------
      tsTxClks : in slv(TS_LANES_G-1 downto 0);
      tsTxRsts : in slv(TS_LANES_G-1 downto 0);
      tsTxMsgs  : out TsData6ChMsgArray(TS_LANES_G-1 downto 0);

      -----------------------------
      -- Fast Control clock and bus
      -----------------------------
      fcClk185 : in sl;
      fcRst185 : in sl;
      fcBus    : in FastControlBusType;

      -- Axil inteface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType  := AXI_LITE_READ_SLAVE_EMPTY_DECERR_C;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType := AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);

end entity TsTxMsgPlayback;

architecture rtl of TsTxMsgPlayback is


   type StateType is (
      WAIT_CLOCK_ALIGN_S,
      WAIT_BC0_S,
      ALIGNED_S);

   -- fcClk185 signals
   type RegType is record
      state               : StateType;
   end record RegType;

   constant REG_INIT_C : RegType := (
      state               => WAIT_CLOCK_ALIGN_S,
);
   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;


begin



   comb : process (fcBus, fcRst185, r, timestampFifoRdData, tsMsgFifoMsgs) is
      variable v : RegType := REG_INIT_C;
   begin
      v := r;


      -- Reset
      if (fcRst185 = '1') then
         v := REG_INIT_C;
      end if;

      -- Outputs
      fcTsRxMsgs <= r.fcTsRxMsgs;
      fcMsgTime  <= r.fcMsgTime;

      rin <= v;


   end process comb;

   seq : process (fcClk185) is
   begin
      if (rising_edge(fcClk185)) then
         r <= rin after TPD_G;
      end if;
   end process seq;


end rtl;



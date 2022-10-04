-------------------------------------------------------------------------------
-- File       : RefclkMon.vhd
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: RefclkMon File
-------------------------------------------------------------------------------
-- This file is part of 'PGP PCIe APP DEV'.
-- It is subject to the license terms in the LICENSE.txt file found in the
-- top-level directory of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of 'PGP PCIe APP DEV', including this file,
-- may be copied, modified, propagated, or distributed except according to
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;

library unisim;
use unisim.vcomponents.all;

entity RefclkMon is
   generic (
      TPD_G           : time := 1 ns;
      AXIL_CLK_FREQ_G : real := 156.25E+6);  -- units of Hz
   port (
      -- AXI-Lite Interface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType  := AXI_LITE_READ_MASTER_INIT_C;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType := AXI_LITE_WRITE_MASTER_INIT_C;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      ---------------------
      --  Application Ports
      ---------------------
      -- QSFP[0] Ports
      qsfpRefClk    : in  slv(3 downto 0));
end RefclkMon;

architecture mapping of RefclkMon is

   type RegType is record
      axilReadSlave  : AxiLiteReadSlaveType;
      axilWriteSlave : AxiLiteWriteSlaveType;
   end record;
   constant REG_INIT_C : RegType := (
      axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal refClkBufg  : slv(3 downto 0);
   signal refClkFreq  : Slv32Array(3 downto 0);

--   attribute CLOCK_DEDICATED_ROUTE : string;
--   attribute CLOCK_DEDICATED_ROUTE of qsfpRefClk is "FALSE";

begin

   GEN_VEC : for i in 3 downto 0 generate

      U_BUFG : BUFG_GT
         port map (
            I       => qsfpRefClk(i),
            CE      => '1',
            CEMASK  => '1',
            CLR     => '0',
            CLRMASK => '1',
            DIV     => "000",           -- Divide-by-1
            O       => refClkBufg(i));

      U_appClkFreq : entity surf.SyncClockFreq
         generic map (
            TPD_G          => TPD_G,
            REF_CLK_FREQ_G => AXIL_CLK_FREQ_G,
            REFRESH_RATE_G => 1.0,
            CNT_WIDTH_G    => 32)
         port map (
            -- Frequency Measurement (locClk domain)
            freqOut => refClkFreq(i),
            -- Clocks
            clkIn   => refClkBufg(i),
            locClk  => axilClk,
            refClk  => axilClk);

   end generate;

   comb : process (axilReadMaster, axilRst, axilWriteMaster, r, refClkFreq) is
      variable v      : RegType;
      variable axilEp : AxiLiteEndPointType;
   begin
      -- Latch the current value
      v := r;

      -- Determine the transaction type
      axiSlaveWaitTxn(axilEp, axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave);

      -- Map the read registers
      axiSlaveRegisterR(axilEp, x"0", 0, refClkFreq(0));
      axiSlaveRegisterR(axilEp, x"4", 0, refClkFreq(1));
      axiSlaveRegisterR(axilEp, x"8", 0, refClkFreq(3));
      axiSlaveRegisterR(axilEp, x"C", 0, refClkFreq(2));

      -- Closeout the transaction
      axiSlaveDefault(axilEp, v.axilWriteSlave, v.axilReadSlave, AXI_RESP_DECERR_C);

      -- Outputs
      axilWriteSlave <= r.axilWriteSlave;
      axilReadSlave  <= r.axilReadSlave;

      -- Reset
      if (axilRst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

   end process comb;

   seq : process (axilClk) is
   begin
      if rising_edge(axilClk) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end mapping;

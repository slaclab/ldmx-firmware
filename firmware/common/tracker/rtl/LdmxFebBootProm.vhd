-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- This file is part of 'Example Project Firmware'.
-- It is subject to the license terms in the LICENSE.txt file found in the
-- top-level directory of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of 'Example Project Firmware', including this file,
-- may be copied, modified, propagated, or distributed except according to
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;

library unisim;
use unisim.vcomponents.all;

entity LdmxFebBootProm is
   generic (
      TPD_G           : time := 1 ns;
      AXIL_CLK_FREQ_G : real := 125.0e6;
      SPI_CLK_FREQ_G  : real := 10.0e6);
   port (
      -- AXI-Lite Interface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType);
end LdmxFebBootProm;

architecture rtl of LdmxFebBootProm is

   signal bootCsL  : sl;
   signal bootSck  : sl;
   signal bootMosi : sl;
   signal bootMiso : sl;

   signal di : slv(3 downto 0);
   signal do : slv(3 downto 0);

begin

   U_BootProm : entity surf.AxiMicronN25QCore
      generic map (
         TPD_G          => TPD_G,
         AXI_CLK_FREQ_G => AXIL_CLK_FREQ_G,  -- units of Hz
         SPI_CLK_FREQ_G => SPI_CLK_FREQ_G)   -- units of Hz
      port map (
         -- FLASH Memory Ports
         csL            => bootCsL,
         sck            => bootSck,
         mosi           => bootMosi,
         miso           => bootMiso,
         -- AXI-Lite Register Interface
         axiReadMaster  => axilReadMaster,
         axiReadSlave   => axilReadSlave,
         axiWriteMaster => axilWriteMaster,
         axiWriteSlave  => axilWriteSlave,
         -- Clocks and Resets
         axiClk         => axilClk,
         axiRst         => axilRst);

   U_STARTUPE3 : STARTUPE3
      generic map (
         PROG_USR      => "FALSE",  -- Activate program event security feature. Requires encrypted bitstreams.
         SIM_CCLK_FREQ => 0.0)          -- Set the Configuration Clock Frequency(ns) for simulation
      port map (
         CFGCLK    => open,             -- 1-bit output: Configuration main clock output
         CFGMCLK   => open,  -- 1-bit output: Configuration internal oscillator clock output
         DI        => di,               -- 4-bit output: Allow receiving on the D[3:0] input pins
         EOS       => open,  -- 1-bit output: Active high output signal indicating the End Of Startup.
         PREQ      => open,             -- 1-bit output: PROGRAM request to fabric output
         DO        => do,               -- 4-bit input: Allows control of the D[3:0] pin outputs
         DTS       => "1110",           -- 4-bit input: Allows tristate of the D[3:0] pins
         FCSBO     => bootCsL,          -- 1-bit input: Contols the FCS_B pin for flash access
         FCSBTS    => '0',              -- 1-bit input: Tristate the FCS_B pin
         GSR       => '0',  -- 1-bit input: Global Set/Reset input (GSR cannot be used for the port name)
         GTS       => '0',  -- 1-bit input: Global 3-state input (GTS cannot be used for the port name)
         KEYCLEARB => '0',  -- 1-bit input: Clear AES Decrypter Key input from Battery-Backed RAM (BBRAM)
         PACK      => '0',              -- 1-bit input: PROGRAM acknowledge input
         USRCCLKO  => bootSck,          -- 1-bit input: User CCLK input
         USRCCLKTS => '0',              -- 1-bit input: User CCLK 3-state enable input
         USRDONEO  => '1',              -- 1-bit input: User DONE pin output control
         USRDONETS => '0');             -- 1-bit input: User DONE 3-state enable output

   do       <= "111" & bootMosi;
   bootMiso <= di(1);

end rtl;

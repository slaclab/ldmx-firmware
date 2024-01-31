-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : Version.vhd
-- Author     : Benjamin Reese  <bareese@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2013-09-29
-- Last update: 2016-02-23
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2013 SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;

package Version is

  constant FPGA_VERSION_C : std_logic_vector(31 downto 0) := x"E312501C";  -- MAKE_VERSION
  constant BUILD_STAMP_C : string := "Feb: Vivado v2015.3 (x86_64) Built Tue Feb 23 16:47:36 PST 2016 by bareese";

end Version;

-- E312501C - 02/23/2016 - Adjusted reset threshold to 25C
-- E312501B - 02/23/2016 - Adjusted temperature threshold to 80C
-- E312501A - 02/23/2016 - Fix SemWrapper FEB Number bug.
-- E3125019 - 09/22/2015 - Fix Sem AXI-LITE access (hopefully for real this time)
-- E3125018 - 09/22/2015 - Fix Sem AXI-LITE access
-- E3125017 - 09/22/2015 - Test build
-- E3125016 - 06/16/2015 - Added SEM core.
-- E3125015 - 06/05/2015 - Build with updated libraries.
-- E3125014 - 06/03/2015 - Fifo stream type change
-- E3125013 - 05/29/2015 - Add pgp loopback on VC3
-- E3125012 - 05/29/2015 - Fix AxiMicronP30Core generics for PGP stream interface
-- E3125011 - 04/24/2015 - Just use counter for rxRecClkStable.
-- E3125010 - 04/22/2015 - Added ApvFrameExtractor frameCount register

-------------------------------------------------------------------------------
-- Revision History:
-- 4 - Hooked up rx opcodes, loopback on tx as well
-- 7 - 2.5 Gbps tweaks
-- 8 - Feedback rx clock on tx (first attempt)
-- 9 - Removed rxClk MMCM
-- A - back to local tx clk
-- B - back to rx-tx clk, no MMCM
-- C - MMCM (PLL) on tx
-- D - Send rec clk out and back
-- E - minor cleanup
-- F - Use gtRef125 for tx
-- 10 - Added Prbs modules
-- 11 - i2c tweak
-- 12 - pgp tweak
-- 13 - move data back to vc 0, prbs vc 1
-- 14 - Fix possible adc enable bug
-- 15 - Larger PGP error counters
-- 16 - Removed unexpected align code guard logic in DaqTiming.vhd
-- 17 - Added PROM programming module
-- 18 - (Hopefully) auto set ADC IO delays to 5 on reset
-- 19 - AdcDeframer now tracks missed frames.
-- 1A - Small tweak in AdcFramer
-- C00000000 - Changed data tx rate to 2.5 Gbps
-- C00000001 - tweaked Prom programming logic
-- 1B - 125 MHz osc for 5 gig links (broken)
-- 1C - 4.0 Gig links (125 MHz base)
-- 1D - 4.0 Gig links (250 MHz base)
-- 1E - 4.0 Gig links, 250 Mhz base, packed frames
-- 1F - 3.125 gig links. 250 Mhz base, packed frames
-- 20 - 4.0 Gig links, 250 Mhz base, packed frames, feb power NOT on by default
-- 21 - Added counters for daq commands
-- 22 - Added counters for all opcodes
-- 23 - Bug fix, opcodes now echoed back
-- 24 - Output every ADC sample and not every other.
-- D0000000 - First build of new firmware. 3.125 Gbps data links.
-- E0000000 - 2.5 Gbps data links
-- E4000000 - 4.0 Gbps data links
-- E5000000 - 5.0 Gbps data links
-- E2500000 - 2.5 Gbps data links again.
-- E3125000 - 3.125 Gbps data links
-- E3125001 - Fix L4-6 APV ordering.
-- E3125002 - Use clk250 for ctrlQPllLockDetClk, adjust reset hold times.
-- E2500001 - Rebuild at 2.5G to see if ctrl links work
-- E3125002 - Adjust clk250 reset hold time
-- E3125003 - Adjusted reset hold times again.
-- E3125004 - Don't use builtin fifos in SsiAxiLiteMaster
-- E3125005 - Hold dataClk reset longer
-- E3125006 - LEDs on by default (works)
-- E3125007 - LEDs off by default (broken)
-- E3125008 - LEDs on by default again (works)
-- E3125009 - Vivado 2014.4, leds off by default (locks after some time)
-- E312500A - ctrl link uses dataClk for stableClock (still broken, never locks)
-- E312500B - No rxRecClk Mmcm (broken)
-- D0000001 - Just for shits and giggles (broken)
-- D0000002 - LED's on by default. (broken)
-- D0000003 - Put rxRecClk MMCM back (broken)
-- D0000004 - Set STABLE_CLOCK_PERIOD lower for longer waits in rst state machine (broken)
-- D0000004 - Use axiClk for stableClk again (overwrote last one on accident, still broken)
-- D0000005 - Hold axiClk in reset for 100 cycles instead of 32 (works!)
-- D0000006 - Turn leds off by default (Still works)
-- E312500C - Changed version string back (broken)
-- D0000006 - Accidentaly overwrote with no other changes, now broken.
-- D0000007 - Remove recClkMonitor (Works!)
-- D0000008 - Use SyncClkFreq module instead of Gtp7RecClkMonitor
-- E312500D - Just change the version number to try to break it
-- E312500E - Shortened default status frame interval, brought REF_CLK_FREQ_G generic out of Gtp7Core
-- E312500F - PROM stream programming. Cleaned up old files in HeavyPDaq module.

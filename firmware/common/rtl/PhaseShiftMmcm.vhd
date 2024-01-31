-- file: PhaseShiftMmcm_clk_wiz.vhd
-- 
-- (c) Copyright 2008 - 2013 Xilinx, Inc. All rights reserved.
-- 
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
-- 
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
-- 
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
-- 
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
-- 
------------------------------------------------------------------------------
-- User entered comments
------------------------------------------------------------------------------
-- None
--
------------------------------------------------------------------------------
--  Output     Output      Phase    Duty Cycle   Pk-to-Pk     Phase
--   Clock     Freq (MHz)  (degrees)    (%)     Jitter (ps)  Error (ps)
------------------------------------------------------------------------------
-- CLK_OUT1____41.667______0.000______50.0______229.120____188.345
-- CLK_OUT2____41.667______0.000______50.0______229.120____188.345
-- CLK_OUT3____41.667______0.000______50.0______229.120____188.345
-- CLK_OUT4____41.667______0.000______50.0______229.120____188.345
--
------------------------------------------------------------------------------
-- Input Clock   Freq (MHz)    Input Jitter (UI)
------------------------------------------------------------------------------
-- __primary__________41.667____________0.010

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library unisim;
use unisim.vcomponents.all;


library surf;
use surf.StdRtlPkg.all;

entity PhaseShiftMmcm is
   generic (
      TPD_G           : time                 := 1 ns;
      NUM_OUTCLOCKS_G : integer range 1 to 6 := 4;
      CLKIN_PERIOD_G  : real                 := 24.0;
      DIVCLK_DIVIDE_G : integer              := 1;
      CLKFBOUT_MULT_G : integer              := 24;
      CLKOUT_DIVIDE_G : integer              := 24);
   port (                               -- Clock in ports
      clkIn    : in  sl;
      -- Clock out ports
      clkOut   : out slv(NUM_OUTCLOCKS_G-1 downto 0);
      outputEn : in  slv(NUM_OUTCLOCKS_G-1 downto 0) := (others => '1');

      -- Dynamic reconfiguration ports
      daddr : in  slv(6 downto 0);
      dclk  : in  sl;
      den   : in  sl;
      din   : in  slv(15 downto 0);
      dout  : out slv(15 downto 0);
      dwe   : in  sl;
      drdy  : out sl;
      -- Status and control signals

      rst    : in  sl;
      locked : out sl);
end PhaseShiftMmcm;

architecture rtl of PhaseShiftMmcm is

   signal clkFbOut  : sl;
   signal clkFbBufg : sl;

   signal clkOutMmcm : slv(5 downto 0);

begin


   -- Clocking PRIMITIVE
   --------------------------------------
   -- Instantiation of the MMCM PRIMITIVE
   --    * Unused inputs are tied off
   --    * Unused outputs are labeled unused
   mmcm_adv_inst : MMCME2_ADV
      generic map
      (BANDWIDTH            => "OPTIMIZED",
       CLKOUT4_CASCADE      => false,
       COMPENSATION         => "ZHOLD",
       STARTUP_WAIT         => false,
       DIVCLK_DIVIDE        => DIVCLK_DIVIDE_G,
       CLKFBOUT_MULT_F      => real(CLKFBOUT_MULT_G),
       CLKFBOUT_PHASE       => 0.000,
       CLKFBOUT_USE_FINE_PS => false,
       CLKOUT0_DIVIDE_F     => real(CLKOUT_DIVIDE_G),
       CLKOUT0_PHASE        => 0.000,
       CLKOUT0_DUTY_CYCLE   => 0.500,
       CLKOUT0_USE_FINE_PS  => false,
       CLKOUT1_DIVIDE       => CLKOUT_DIVIDE_G,
       CLKOUT1_PHASE        => 0.000,
       CLKOUT1_DUTY_CYCLE   => 0.500,
       CLKOUT1_USE_FINE_PS  => false,
       CLKOUT2_DIVIDE       => CLKOUT_DIVIDE_G,
       CLKOUT2_PHASE        => 0.000,
       CLKOUT2_DUTY_CYCLE   => 0.500,
       CLKOUT2_USE_FINE_PS  => false,
       CLKOUT3_DIVIDE       => CLKOUT_DIVIDE_G,
       CLKOUT3_PHASE        => 0.000,
       CLKOUT3_DUTY_CYCLE   => 0.500,
       CLKOUT3_USE_FINE_PS  => false,
       CLKOUT4_DIVIDE       => CLKOUT_DIVIDE_G,
       CLKOUT4_PHASE        => 0.000,
       CLKOUT4_DUTY_CYCLE   => 0.500,
       CLKOUT4_USE_FINE_PS  => false,
       CLKOUT5_DIVIDE       => CLKOUT_DIVIDE_G,
       CLKOUT5_PHASE        => 0.000,
       CLKOUT5_DUTY_CYCLE   => 0.500,
       CLKOUT5_USE_FINE_PS  => false,
       CLKIN1_PERIOD        => CLKIN_PERIOD_G,
       REF_JITTER1          => 0.010)
      port map
      -- Output clocks
      (
         CLKFBOUT     => clkFbOut,
         CLKFBOUTB    => open,
         CLKOUT0      => clkOutMmcm(0),
         CLKOUT0B     => open,
         CLKOUT1      => clkOutMmcm(1),
         CLKOUT1B     => open,
         CLKOUT2      => clkOutMmcm(2),
         CLKOUT2B     => open,
         CLKOUT3      => clkOutMmcm(3),
         CLKOUT3B     => open,
         CLKOUT4      => clkOutMmcm(4),
         CLKOUT5      => clkOutMmcm(5),
         CLKOUT6      => open,
         -- Input clock control
         CLKFBIN      => clkFbBufg,
         CLKIN1       => clkIn,
         CLKIN2       => '0',
         -- Tied to always select the primary input clock
         CLKINSEL     => '1',
         -- Ports for dynamic reconfiguration
         DADDR        => daddr,
         DCLK         => dclk,
         DEN          => den,
         DI           => din,
         DO           => dout,
         DRDY         => drdy,
         DWE          => dwe,
         -- Ports for dynamic phase shift
         PSCLK        => '0',
         PSEN         => '0',
         PSINCDEC     => '0',
         PSDONE       => open,
         -- Other control and status signals
         LOCKED       => locked,
         CLKINSTOPPED => open,
         CLKFBSTOPPED => open,
         PWRDWN       => '0',
         RST          => rst);

   -- Output buffering
   -------------------------------------

   clkf_buf : BUFG
      port map
      (I => clkFbOut,
       O => clkFbBufg);

   BUFG_GEN : for i in NUM_OUTCLOCKS_G-1 downto 0 generate
      clkout1_buf : BUFGCE
         port map
         (O  => clkOut(i),
          CE => outputEn(i),
          I  => clkOutMmcm(i));
   end generate BUFG_GEN;

end rtl;

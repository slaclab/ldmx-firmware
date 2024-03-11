-------------------------------------------------------------------------------
-- Title      : Testbench for design "BittWareXupVv8Pgp2fc"
-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Multi-FPGA testbench to emulate independent-clock topologies
--              (probably won't work in multiple-lane implementations)
-------------------------------------------------------------------------------
-- This file is part of pgp-pcie-apps. It is subject to
-- the license terms in the LICENSE.txt file found in the top-level directory
-- of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of pgp-pcie-apps, including this file, may be
-- copied, modified, propagated, or distributed except according to the terms
-- contained in the LICENSE.txt file.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiStreamPkg.all;
use surf.SsiPkg.all;

library ruckus;
use ruckus.BuildInfoPkg.all;

----------------------------------------------------------------------------------------------------

entity BittWareXupVv8Pgp2fcMultiFpgaTb is

end entity BittWareXupVv8Pgp2fcMultiFpgaTb;

----------------------------------------------------------------------------------------------------

architecture sim of BittWareXupVv8Pgp2fcMultiFpgaTb is

   -- component generics
   constant TPD_G                : time                        := 0.2 ns;
   constant SIM_SPEEDUP_G        : boolean                     := true;
   constant ROGUE_SIM_EN_G       : boolean                     := true;
   constant DMA_BURST_BYTES_G    : integer range 256 to 4096   := 4096;
   constant DMA_BYTE_WIDTH_G     : integer range 8 to 64       := 8;
   constant PGP_QUADS_G          : integer                     := 1;
   constant PGP_FPGAS_G          : integer                     := 2;
   constant BUILD_INFO_G         : BuildInfoType               := BUILD_INFO_C;

   type PciLaneArray    is array (natural range PGP_FPGAS_G*4-1 downto 0) of slv(15 downto 0);
   type QsfpLaneArray   is array (natural range PGP_FPGAS_G*4-1 downto 0) of slv(PGP_QUADS_G*4-1 downto 0);
   type QsfpRefClkArray is array (natural range PGP_FPGAS_G-1 downto 0) of slv(PGP_QUADS_G-1 downto 0);

   type RoguePortArray is array (natural range PGP_FPGAS_G-1 downto 0) of natural range 1024 to 49151;

   constant ROGUE_SIM_PORT_NUM_G : RoguePortArray := (12000, 11000);

   type DbgRxArray is array (natural range PGP_FPGAS_G-1 downto 0) of boolean;

   -- FPGA 0 -> TX
   -- FPGA 1 -> RX
   constant DBG_RX_G : DbgRxArray := (true, false);

   -- component ports
   signal qsfpLane       : QsfpLaneArray   := (others => (others => '0'));
   signal qsfpRefClkP    : QsfpRefClkArray := (others => (others => '0')); -- [in]
   signal qsfpRefClkN    : QsfpRefClkArray := (others => (others => '0')); -- [in]
   signal qsfpRecClkP    : QsfpRefClkArray := (others => (others => '0')); -- [in]
   signal qsfpRecClkN    : QsfpRefClkArray := (others => (others => '0')); -- [in]
   signal fpgaI2cMasterL : slv(PGP_FPGAS_G-1 downto 0) := (others => '0'); -- [out]
   signal userClkP       : sl := '0';  -- [in]
   signal userClkN       : sl := '0';  -- [in]
   signal pciRstL        : sl := '1';  -- [in]
   signal pciRefClkP     : sl := '0';  -- [in]
   signal pciRefClkN     : sl := '0';  -- [in]
   signal extPps         : slv(PGP_FPGAS_G-1 downto 0) := (others => '0');
   signal pciLane        : PciLaneArray := (others => (others => '0'));

   function toTimeOffset (BASE, OFFSET : real) return time is
   begin
      return (BASE + OFFSET) * 1.0 ns;
   end function;

begin

GEN_FPGA : for fpga in 0 to PGP_FPGAS_G-1 generate
   -- component instantiation
   U_BittWareXupVv8Pgp2fc : entity work.BittWareXupVv8Pgp2fc
      generic map (
         TPD_G                => TPD_G,
         SIM_SPEEDUP_G        => SIM_SPEEDUP_G,
         ROGUE_SIM_EN_G       => ROGUE_SIM_EN_G,
         ROGUE_SIM_PORT_NUM_G => ROGUE_SIM_PORT_NUM_G(fpga),
         DMA_BURST_BYTES_G    => DMA_BURST_BYTES_G,
         DMA_BYTE_WIDTH_G     => DMA_BYTE_WIDTH_G,
         PGP_QUADS_G          => PGP_QUADS_G,
         FC_EMU_QUAD_G        => 0, -- only using quad=0 for tb
         FC_EMU_LANE_G        => 0,
         DBG_RX_G             => DBG_RX_G(fpga),
         BUILD_INFO_G         => BUILD_INFO_G)
      port map (
         qsfpRefClkP    => qsfpRefClkP(fpga),    -- [in]
         qsfpRefClkN    => qsfpRefClkN(fpga),    -- [in]
         qsfpRecClkP    => qsfpRecClkP(fpga),    -- [in]
         qsfpRecClkN    => qsfpRecClkN(fpga),    -- [in]
         qsfpRxP        => qsfpLane(0+4*fpga),   -- [in]
         qsfpRxN        => qsfpLane(1+4*fpga),   -- [in]
         qsfpTxP        => qsfpLane(2+4*fpga),   -- [out]
         qsfpTxN        => qsfpLane(3+4*fpga),   -- [out]
         fpgaI2cMasterL => fpgaI2cMasterL(fpga), -- [out]
         userClkP       => userClkP,             -- [in]
         userClkN       => userClkN,             -- [in]
         extPps         => extPps(fpga),         -- [out]
         pciRstL        => pciRstL,              -- [in]
         pciRefClkP     => pciRefClkP,           -- [in]
         pciRefClkN     => pciRefClkN,           -- [in]
         pciRxP         => pciLane(0+4*fpga),    -- [in]
         pciRxN         => pciLane(1+4*fpga),    -- [in]
         pciTxP         => pciLane(2+4*fpga),    -- [out]
         pciTxN         => pciLane(3+4*fpga));   -- [out]

   U_ClkRst_REFCLK : entity surf.ClkRst
      generic map (
         CLK_PERIOD_G      => toTimeOffset(5.3846 , 0.016*fpga),
         CLK_DELAY_G       => 1 ns,
         RST_START_DELAY_G => 0 ns,
         RST_HOLD_TIME_G   => 5 us,
         SYNC_RESET_G      => true)
      port map (
         clkP => qsfpRefClkP(fpga)(PGP_QUADS_G-1),
         clkN => qsfpRefClkN(fpga)(PGP_QUADS_G-1));

end generate GEN_FPGA;

   U_ClkRst_USERCLK : entity surf.ClkRst
      generic map (
         CLK_PERIOD_G      => 10.0 ns, -- 100.0 MHz = 10.0 ns
         CLK_DELAY_G       => 1 ns,
         RST_START_DELAY_G => 0 ns,
         RST_HOLD_TIME_G   => 5 us,
         SYNC_RESET_G      => true)
      port map (
         clkP => userClkP,
         clkN => userClkN);

   pciRefClkP  <= userClkP;
   pciRefClkN  <= userClkN;

   qsfpLane(0) <= qsfpLane(6);
   qsfpLane(1) <= qsfpLane(7);
   qsfpLane(5) <= qsfpLane(3);
   qsfpLane(4) <= qsfpLane(2);

   pciLane(0)  <= pciLane(6);
   pciLane(1)  <= pciLane(7);
   pciLane(5)  <= pciLane(3);
   pciLane(4)  <= pciLane(2);


end architecture sim;

----------------------------------------------------------------------------------------------------

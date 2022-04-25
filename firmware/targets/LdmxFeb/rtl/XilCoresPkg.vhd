-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : XilCoresPkg.vhd
-- Author     : Benjamin Reese  <bareese@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2014-01-08
-- Last update: 2015-06-16
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2014 SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;


library surf;
use surf.StdRtlPkg.all;

package XilCoresPkg is

   component AxiXadcCore is
      port (
         s_axi_aclk    : in  std_logic;
         s_axi_aresetn : in  std_logic;
         s_axi_awaddr  : in  std_logic_vector(10 downto 0);
         s_axi_awvalid : in  std_logic;
         s_axi_awready : out std_logic;
         s_axi_wdata   : in  std_logic_vector(31 downto 0);
         s_axi_wstrb   : in  std_logic_vector(3 downto 0);
         s_axi_wvalid  : in  std_logic;
         s_axi_wready  : out std_logic;
         s_axi_bresp   : out std_logic_vector(1 downto 0);
         s_axi_bvalid  : out std_logic;
         s_axi_bready  : in  std_logic;
         s_axi_araddr  : in  std_logic_vector(10 downto 0);
         s_axi_arvalid : in  std_logic;
         s_axi_arready : out std_logic;
         s_axi_rdata   : out std_logic_vector(31 downto 0);
         s_axi_rresp   : out std_logic_vector(1 downto 0);
         s_axi_rvalid  : out std_logic;
         s_axi_rready  : in  std_logic;
         ip2intc_irpt  : out std_logic;
         vauxp0        : in  std_logic;
         vauxn0        : in  std_logic;
         vauxp1        : in  std_logic;
         vauxn1        : in  std_logic;
         vauxp2        : in  std_logic;
         vauxn2        : in  std_logic;
         vauxp3        : in  std_logic;
         vauxn3        : in  std_logic;
         vauxp4        : in  std_logic;
         vauxn4        : in  std_logic;
         vauxp5        : in  std_logic;
         vauxn5        : in  std_logic;
         vauxp6        : in  std_logic;
         vauxn6        : in  std_logic;
         vauxp7        : in  std_logic;
         vauxn7        : in  std_logic;
         vauxp8        : in  std_logic;
         vauxn8        : in  std_logic;
         vauxp9        : in  std_logic;
         vauxn9        : in  std_logic;
         vauxp10       : in  std_logic;
         vauxn10       : in  std_logic;
         vauxp11       : in  std_logic;
         vauxn11       : in  std_logic;
         vauxp12       : in  std_logic;
         vauxn12       : in  std_logic;
         vauxp13       : in  std_logic;
         vauxn13       : in  std_logic;
         vauxp14       : in  std_logic;
         vauxn14       : in  std_logic;
         vauxp15       : in  std_logic;
         vauxn15       : in  std_logic;
         busy_out      : out std_logic;
         channel_out   : out std_logic_vector (4 downto 0);
         eoc_out       : out std_logic;
         eos_out       : out std_logic;
         alarm_out     : out std_logic;
         vp_in         : in  std_logic;
         vn_in         : in  std_logic);
   end component AxiXadcCore;

 
end package XilCoresPkg;

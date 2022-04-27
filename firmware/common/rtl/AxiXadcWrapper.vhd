-------------------------------------------------------------------------------
-- Title      : AxiXadcWrapper
-------------------------------------------------------------------------------
-- File       : AxiXadcWrapper.vhd
-- Author     : Benjamin Reese  <bareese@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2014-03-24
-- Last update: 2022-04-27
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Wrapper around XADC IP Core using AXI record types
-------------------------------------------------------------------------------
-- Copyright (c) 2014 SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;

library ldmx;
use ldmx.XilCoresPkg.all;

entity AxiXadcWrapper is
   
   generic (
      TPD_G : time := 1 ns);

   port (
      axiClk : in sl;
      axiRst : in sl;

      axiReadMaster  : in  AxiLiteReadMasterType;
      axiReadSlave   : out AxiLiteReadSlaveType;
      axiWriteMaster : in  AxiLiteWriteMasterType;
      axiWriteSlave  : out AxiLiteWriteSlaveType;

      vPIn : in sl;
      vNIn : in sl;
      vAuxP : in slv(15 downto 0);
      vAuxN : in slv(15 downto 0)
      );

end entity AxiXadcWrapper;

architecture rtl of AxiXadcWrapper is

   signal axiRstL : sl;

begin

   axiRstL <= not axiRst;
   AxiXadcCore_1 : AxiXadcCore
      port map (
         s_axi_aclk    => axiClk,
         s_axi_aresetn => axiRstL,
         s_axi_awaddr  => axiWriteMaster.awaddr(10 downto 0),
         s_axi_awvalid => axiWriteMaster.awvalid,
         s_axi_awready => axiWriteSlave.awready,
         s_axi_wdata   => axiWriteMaster.wdata,
         s_axi_wstrb   => axiWriteMaster.wstrb,
         s_axi_wvalid  => axiWriteMaster.wvalid,
         s_axi_wready  => axiWriteSlave.wready,
         s_axi_bresp   => axiWriteSlave.bresp,
         s_axi_bvalid  => axiWriteSlave.bvalid,
         s_axi_bready  => axiWriteMaster.bready,
         s_axi_araddr  => axiReadMaster.araddr(10 downto 0),
         s_axi_arvalid => axiReadMaster.arvalid,
         s_axi_arready => axiReadSlave.arready,
         s_axi_rdata   => axiReadSlave.rdata,
         s_axi_rresp   => axiReadSlave.rresp,
         s_axi_rvalid  => axiReadSlave.rvalid,
         s_axi_rready  => axiReadMaster.rready,
         ip2intc_irpt  => open,
         vauxp0        => vAuxP(0),
         vauxn0        => vAuxN(0),
         vauxp1        => vAuxP(1),
         vauxn1        => vAuxN(1),
         vauxp2        => vAuxP(2),
         vauxn2        => vAuxN(2),
         vauxp3        => vAuxP(3),
         vauxn3        => vAuxN(3),
         vauxp4        => vAuxP(4),
         vauxn4        => vAuxN(4),
         vauxp5        => vAuxP(5),
         vauxn5        => vAuxN(5),
         vauxp6        => vAuxP(6),
         vauxn6        => vAuxN(6),
         vauxp7        => vAuxP(7),
         vauxn7        => vAuxN(7),
         vauxp8        => vAuxP(8),
         vauxn8        => vAuxN(8),
         vauxp9        => vAuxP(9),
         vauxn9        => vAuxN(9),
         vauxp10       => vAuxP(10),
         vauxn10       => vAuxN(10),
         vauxp11       => vAuxP(11),
         vauxn11       => vAuxN(11),
         vauxp12       => vAuxP(12),
         vauxn12       => vAuxN(12),
         vauxp13       => vAuxP(13),
         vauxn13       => vAuxN(13),
         vauxp14       => vAuxP(14),
         vauxn14       => vAuxN(14),
         vauxp15       => vAuxP(15),
         vauxn15       => vAuxN(15),
         busy_out      => open,
         channel_out   => open,
         eoc_out       => open,
         eos_out       => open,
         alarm_out     => open,
         vp_in         => vpIn,
         vn_in         => vNIn);

end architecture rtl;

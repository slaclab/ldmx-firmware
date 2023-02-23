-------------------------------------------------------------------------------
-- Title      : LDMX FEB SYSMON Wrapper
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


entity LdmxFebSysmonWrapper is

   generic (
      TPD_G : time := 1 ns);
   port (
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      vauxp           : in  slv(1 downto 0);
      vauxn           : in  slv(1 downto 0));

end entity LdmxFebSysmonWrapper;

architecture rtl of LdmxFebSysmonWrapper is

   signal axilRstL : sl;

   component LdmxFebSysmon
      port (
         s_axi_aclk             : in  sl;
         s_axi_aresetn          : in  sl;
         s_axi_awaddr           : in  slv(12 downto 0);
         s_axi_awvalid          : in  sl;
         s_axi_awready          : out sl;
         s_axi_wdata            : in  slv(31 downto 0);
         s_axi_wstrb            : in  slv(3 downto 0);
         s_axi_wvalid           : in  sl;
         s_axi_wready           : out sl;
         s_axi_bresp            : out slv(1 downto 0);
         s_axi_bvalid           : out sl;
         s_axi_bready           : in  sl;
         s_axi_araddr           : in  slv(12 downto 0);
         s_axi_arvalid          : in  sl;
         s_axi_arready          : out sl;
         s_axi_rdata            : out slv(31 downto 0);
         s_axi_rresp            : out slv(1 downto 0);
         s_axi_rvalid           : out sl;
         s_axi_rready           : in  sl;
         vauxp0                 : in  sl;
         vauxn0                 : in  sl;
         vauxp1                 : in  sl;
         vauxn1                 : in  sl;
         ip2intc_irpt           : out sl;
         user_temp_alarm_out    : out sl;
         vccint_alarm_out       : out sl;
         vccaux_alarm_out       : out sl;
         user_supply0_alarm_out : out sl;
         user_supply1_alarm_out : out sl;
         user_supply2_alarm_out : out sl;
         user_supply3_alarm_out : out sl;
         ot_out                 : out sl;
         channel_out            : out slv(5 downto 0);
         eoc_out                : out sl;
         alarm_out              : out sl;
         eos_out                : out sl;
         busy_out               : out sl
         );
   end component;

begin

   axilRstL <= not axilRst;

   U_LdmxFebSysmon_1 : LdmxFebSysmon
      port map (
         s_axi_aclk             => axilClk,                              -- [in]
         s_axi_aresetn          => axilRstL,                             -- [in]
         s_axi_awaddr           => axilWriteMaster.awaddr(12 downto 0),  -- [in]
         s_axi_awvalid          => axilWriteMaster.awvalid,              -- [in]
         s_axi_awready          => axilWriteSlave.awready,               -- [out]
         s_axi_wdata            => axilWriteMaster.wdata,                -- [in]
         s_axi_wstrb            => axilWriteMaster.wstrb,                -- [in]
         s_axi_wvalid           => axilWriteMaster.wvalid,               -- [in]
         s_axi_wready           => axilWriteSlave.wready,                -- [out]
         s_axi_bresp            => axilWriteSlave.bresp,                 -- [out]
         s_axi_bvalid           => axilWriteSlave.bvalid,                -- [out]
         s_axi_bready           => axilWriteMaster.bready,               -- [in]
         s_axi_araddr           => axilReadMaster.araddr(12 downto 0),   -- [in]
         s_axi_arvalid          => axilReadMaster.arvalid,               -- [in]
         s_axi_arready          => axilReadSlave.arready,                -- [out]
         s_axi_rdata            => axilReadSlave.rdata,                  -- [out]
         s_axi_rresp            => axilReadSlave.rresp,                  -- [out]
         s_axi_rvalid           => axilReadSlave.rvalid,                 -- [out]
         s_axi_rready           => axilReadMaster.rready,                -- [in]
         vauxp0                 => vauxp(0),                             -- [in]
         vauxn0                 => vauxn(0),                             -- [in]
         vauxp1                 => vauxp(1),                             -- [in]
         vauxn1                 => vauxn(1),                             -- [in]
         ip2intc_irpt           => open,                                 -- [out]
         user_temp_alarm_out    => open,                                 -- [out]
         vccint_alarm_out       => open,                                 -- [out]
         vccaux_alarm_out       => open,                                 -- [out]
         user_supply0_alarm_out => open,                                 -- [out]
         user_supply1_alarm_out => open,                                 -- [out]
         user_supply2_alarm_out => open,                                 -- [out]
         user_supply3_alarm_out => open,                                 -- [out]
         ot_out                 => open,                                 -- [out]
         channel_out            => open,                                 -- [out]
         eoc_out                => open,                                 -- [out]
         alarm_out              => open,                                 -- [out]
         eos_out                => open,                                 -- [out]
         busy_out               => open);                                -- [out]

end rtl;

-------------------------------------------------------------------------------
-- Title      : ADC Deframer
-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- This file is part of HPS. It is subject to
-- the license terms in the LICENSE.txt file found in the top-level directory
-- of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of HPS, including this file, may be
-- copied, modified, propagated, or distributed except according to the terms
-- contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


library surf;
use surf.StdRtlPkg.all;
use surf.AxiStreamPkg.all;
use surf.SsiPkg.all;


library hps_daq;
use hps_daq.HpsPkg.all;
use hps_daq.AdcReadoutPkg.all;
use hps_daq.FebConfigPkg.all;

entity AdcDeframer is
   
   generic (
      TPD_G : time := 1 ns);

   port (
      sysClk : in sl;
      sysRst : in sl;

      -- Incomming Data from ADCs
      febDataAxisMaster : in  AxiStreamMasterType;
      febDataAxisSlave  : out AxiStreamSlaveType;
      febDataAxisCtrl   : out AxiStreamCtrlType;

      adcReadout   : out AdcReadoutType;
      febHybrid    : out slv(1 downto 0);
      febConfig    : out FebConfigType;
      lastFrameNum : out slv(13 downto 0);
      missedFrames : out slv(15 downto 0));

end entity AdcDeframer;

architecture rtl of AdcDeframer is

   type RegType is record
      febDataSsiSlave : SsiSlaveType;
      adcReadout      : AdcReadoutType;
      febHybrid       : slv(1 downto 0);
      febConfig       : FebConfigType;
      lastFrameNum    : slv(13 downto 0);
      missedFrames    : slv(15 downto 0);
   end record RegType;

   constant REG_INIT_C : RegType := (
      febDataSsiSlave => axis2SsiSlave(ADC_DATA_SSI_CONFIG_C, AXI_STREAM_SLAVE_FORCE_C, AXI_STREAM_CTRL_UNUSED_C),
      adcReadout      => ADC_READOUT_INIT_C,
      febHybrid       => (others => '0'),
      febConfig       => FEB_CONFIG_INIT_C,
      lastFrameNum    => (others => '0'),
      missedFrames    => (others => '0'));

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal febDataSsiMaster : SsiMasterType;
   
begin

   febDataSsiMaster <= axis2SsiMaster(ADC_DATA_SSI_CONFIG_C, febDataAxisMaster);

   comb : process (febDataSsiMaster, r, sysRst) is
      variable v : RegType;
   begin
      v := r;

      v.febDataSsiSlave.ready    := '1';
      v.febDataSsiSlave.pause    := '0';
      v.febDataSsiSlave.overflow := '0';

      v.adcReadout.valid := '0';

      if (febDataSsiMaster.valid = '1' and r.febDataSsiSlave.ready = '1') then
         v.febDataSsiSlave.ready := '0';
         if (febDataSsiMaster.sof = '1') then
            -- Extract header data
            v.febConfig := toFebConfig(febDataSsiMaster.data(63 downto 0));
            v.febHybrid := febDataSsiMaster.data(79 downto 78);
            if (febDataSsiMaster.data(77 downto 64) /= (r.lastFrameNum+1)) then
               v.missedFrames := r.missedFrames + 1;
            end if;
            v.lastFrameNum := febDataSsiMaster.data(77 downto 64);
         else
            v.adcReadout.valid := '1';
            for i in 4 downto 0 loop
               v.adcReadout.data(i) := febDataSsiMaster.data(i*16+15 downto i*16);
            end loop;
         end if;

      end if;

      if (sysRst = '1') then
         v := REG_INIT_C;
      end if;

      rin              <= v;
      febDataAxisSlave <= ssi2AxisSlave(r.febDataSsiSlave);
      febDataAxisCtrl  <= ssi2AxisCtrl(r.febDataSsiSlave);
      adcReadout       <= r.adcReadout;
      febHybrid        <= r.febHybrid;
      febConfig        <= r.febConfig;
      lastFrameNum     <= r.lastFrameNum;
      missedFrames     <= r.missedFrames;
      
   end process comb;

   seq : process (sysClk) is
   begin
      if (rising_edge(sysClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end architecture rtl;

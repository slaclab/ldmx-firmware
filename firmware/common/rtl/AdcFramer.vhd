-------------------------------------------------------------------------------
-- Title      : AdcFramer
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


library ldmx;
use ldmx.HpsPkg.all;
use ldmx.AdcReadoutPkg.all;
use ldmx.FebConfigPkg.all;

entity AdcFramer is

   generic (
      TPD_G        : time                 := 1 ns;
      HYBRID_NUM_G : natural range 0 to 3 := 0);
   port (
      sysClk125 : in sl;
      sysRst125 : in sl;

      adcReadout : in AdcReadoutType;
      febConfig  : in FebConfigType;

      hybridAdcDataAxisMaster : out AxiStreamMasterType;
      hybridAdcDataAxisSlave  : in  AxiStreamSlaveType;
      hybridAdcDataAxisCtrl   : in  AxiStreamCtrlType);

end entity AdcFramer;

architecture rtl of AdcFramer is

   type StateType is (HEADER_S, DATA_S, WAIT_DRAIN_S);

   type RegType is record
      hybridAdcDataSsiMaster : SsiMasterType;
      state                  : StateType;
      count                  : slv(27 downto 0);
      frameNum               : slv(7 downto 0);
      fifoRdEn               : sl;
   end record RegType;

   constant REG_INIT_C : RegType := (
      hybridAdcDataSsiMaster => ssiMasterInit(ADC_DATA_SSI_CONFIG_C),
      state                  => HEADER_S,
      count                  => (others => '0'),
      frameNum               => (others => '0'),
      fifoRdEn               => '0');

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal hybridAdcDataSsiSlave : SsiSlaveType;

   signal fifoWrData   : slv(79 downto 0);
   signal fifoOverflow : sl;
   signal fifoFull     : sl;
   signal fifoRdData   : slv(79 downto 0);
   signal fifoValid    : sl;
   signal fifoRdEn     : sl;

begin

   hybridAdcDataSsiSlave <= axis2ssiSlave(ADC_DATA_SSI_CONFIG_C, hybridAdcDataAxisSlave, hybridAdcDataAxisCtrl);

   flatten : for i in 4 downto 0 generate
      fifoWrData(i*16+15 downto i*16) <= adcReadout.data(i);
   end generate;

   -- Small fifo to buffer while header is inserted into stream
   Fifo_1 : entity surf.Fifo
      generic map (
         TPD_G           => TPD_G,
         GEN_SYNC_FIFO_G => true,
         MEMORY_TYPE_G   => "distributed",
         FWFT_EN_G       => true,
         DATA_WIDTH_G    => 80,
         ADDR_WIDTH_G    => 4)
      port map (
         rst      => sysRst125,
         wr_clk   => sysClk125,
         wr_en    => adcReadout.valid,
         din      => fifoWrData,
         overflow => fifoOverflow,
         full     => fifoFull,
         rd_clk   => sysClk125,
         rd_en    => fifoRdEn,
         dout     => fifoRdData,
         valid    => fifoValid);

   comb : process (febConfig, fifoRdData, fifoValid, hybridAdcDataSsiSlave, r, sysRst125) is
      variable v          : RegType;
      variable hybridInfo : HybridInfoType;

   begin
      v := r;

      hybridInfo.febAddress := febConfig.febAddress;
      hybridInfo.hybridNum  := toSlv(HYBRID_NUM_G, 2);
      hybridInfo.hybridType := febConfig.hybridType;
      hybridInfo.syncStatus := (others => '0');


      v.hybridAdcDataSsiMaster.sof   := '0';
      v.hybridAdcDataSsiMaster.eof   := '0';
      v.hybridAdcDataSsiMaster.eofe  := '0';
      v.hybridAdcDataSsiMaster.valid := '0';
      v.hybridAdcDataSsiMaster.keep  := X"03FF";
      v.hybridAdcDataSsiMaster.data  := (others => '0');
      v.fifoRdEn                     := fifoValid;

      case r.state is
         when HEADER_S =>
            v.count := (others => '0');

            if (fifoValid = '1' and hybridAdcDataSsiSlave.ready = '1' and
                febConfig.hyAdcDataStreamEn(HYBRID_NUM_G) /= 0) then

               v.hybridAdcDataSsiMaster.data(31 downto 24) := r.frameNum;
               v.hybridAdcDataSsiMaster.data(20 downto 16) := febConfig.hyAdcDataStreamEn(HYBRID_NUM_G);
               v.hybridAdcDataSsiMaster.data(15 downto 0)  := toSlv(hybridInfo);
               v.hybridAdcDataSsiMaster.keep               := X"000F";
               v.hybridAdcDataSsiMaster.sof                := '1';
               v.hybridAdcDataSsiMaster.valid              := '1';
               v.fifoRdEn                                  := '0';  -- Pause reading for 1 cycle while header inserted

               v.frameNum := r.frameNum + 1;
               v.state    := DATA_S;

            end if;

         when DATA_S =>
            if (fifoValid = '1') then
               v.hybridAdcDataSsiMaster.data(79 downto 0) := fifoRdData;
               v.hybridAdcDataSsiMaster.valid             := '1';
               v.count                                    := r.count + 1;

               if (r.count = febConfig.frameSize) then
                  v.count                      := (others => '0');
                  v.hybridAdcDataSsiMaster.eof := '1';
                  v.state                      := HEADER_S;
               end if;

            end if;

            -- Terminate frame early if ready drops
            if (hybridAdcDataSsiSlave.ready = '0') then
               v.hybridAdcDataSsiMaster.eof := '1';
               v.state                      := WAIT_DRAIN_S;
            end if;

         when WAIT_DRAIN_S =>
            -- Hold last txn until ready rises, then drop valid
            v.hybridAdcDataSsiMaster := r.hybridAdcDataSsiMaster;
            if (hybridAdcDataSsiSlave.ready = '1') then
               v.hybridAdcDataSsiMaster.valid := '0';
            end if;

            -- Pause goes low when buffer is fully drained. Can then start new frame.
            if (hybridAdcDataSsiSlave.pause = '0') then
               v.state := HEADER_S;
            end if;

         when others => null;
      end case;

--      if (r.count = 0) then
--         if (fifoValid = '1' and hybridAdcDataSsiSlave.pause = '0' and and hybridAdcDataSsiSlave.ready = '1' and
--             febConfig.hyAdcDataStreamEn(HYBRID_NUM_G) /= 0) then

--            v.hybridAdcDataSsiMaster.data(31 downto 24) := r.frameNum;
--            v.hybridAdcDataSsiMaster.data(20 downto 16) := febConfig.hyAdcDataStreamEn(HYBRID_NUM_G);
--            v.hybridAdcDataSsiMaster.data(15 downto 0)  := toSlv(hybridInfo);
--            v.hybridAdcDataSsiMaster.keep               := X"000F";
--            v.hybridAdcDataSsiMaster.sof                := '1';
--            v.hybridAdcDataSsiMaster.valid              := '1';

--            v.frameNum := r.frameNum + 1;
--         elsif (hybridAdcDataSsiSlave.pause = '1') then
--            v.fifoRdEn := '1';          -- burn data between frames
--         end if;
--      elsif (fifoValid = '1' and r.fifoRdEn = '0') then
--         if (febConfig.hybridType = OLD_HYBRID_C) then
--            v.hybridAdcDataSsiMaster.data(79 downto 0) := fifoRdData;
--         else
--            -- Channels are all out of order on new hybrids, reorder them here
--            v.hybridAdcDataSsiMaster.data(15 downto 0)  := fifoRdData(63 downto 48);  --3
--            v.hybridAdcDataSsiMaster.data(31 downto 16) := fifoRdData(79 downto 64);  --4
--            v.hybridAdcDataSsiMaster.data(47 downto 32) := fifoRdData(15 downto 0);   --0
--            v.hybridAdcDataSsiMaster.data(63 downto 48) := fifoRdData(31 downto 16);  --1
--            v.hybridAdcDataSsiMaster.data(79 downto 64) := fifoRdData(47 downto 32);  --2
--         end if;

--         v.hybridAdcDataSsiMaster.valid := '1';  --r.burn;
--         for i in 9 downto 0 loop
--            v.hybridAdcDataSsiMaster.keep(i) := febConfig.hyAdcDataStreamEn(HYBRID_NUM_G)(i/2);
--         end loop;
----            v.burn                   := not r.burn;
--         v.fifoRdEn := '1';
--      end if;


--      if (febConfig.hyAdcDataStreamEn(HYBRID_NUM_G) = 0) then
--         -- Burn all fifo data when stream output is disabled
--         v.fifoRdEn := '1';
--      end if;

--      if (v.hybridAdcDataSsiMaster.valid = '1') then
--         v.count := r.count + 1;
--         if (r.count = febConfig.frameSize) then
--            v.count                      := (others => '0');
--            v.hybridAdcDataSsiMaster.eof := '1';
--         end if;

--         -- EOFE if pause ever asserted
--         if (hybridAdcDataSsiSlave.ready = '0') then
--            v.count                      := (others => '0');
--            v.hybridAdcDataSsiMaster.eof := '1';
--         end if;
--      end if;

      ----------------------------------------------------------------------------------------------
      -- Reset
      ----------------------------------------------------------------------------------------------
      if (sysRst125 = '1') then
         v                             := REG_INIT_C;
         v.hybridAdcDataSsiMaster.keep := X"03FF";
      end if;

      rin <= v;

      ----------------------------------------------------------------------------------------------
      -- Outputs
      ----------------------------------------------------------------------------------------------
      hybridAdcDataAxisMaster <= ssi2AxisMaster(ADC_DATA_SSI_CONFIG_C, r.hybridAdcDataSsiMaster);
      fifoRdEn                <= v.fifoRdEn;

   end process comb;

   seq : process (sysClk125) is
   begin
      if (rising_edge(sysClk125)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end architecture rtl;

-------------------------------------------------------------------------------
-- Title         : TI Data Transmit
-- File          : TiDataSend.vhd
-- Author        : Ryan Herbst, rherbst@slac.stanford.edu
-- Created       : 07/16/2014
-------------------------------------------------------------------------------
-- Description:
-- TI Data Transmission
-------------------------------------------------------------------------------
-- Copyright (c) 2014 by Ryan Herbst. All rights reserved.
-------------------------------------------------------------------------------
-- Modification history:
-- 07/16/2014: created.
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_arith.all;
use IEEE.STD_LOGIC_unsigned.all;

library UNISIM;
use UNISIM.VCOMPONENTS.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiStreamPkg.all;

library rce_gen3_fw_lib;
use rce_gen3_fw_lib.RceG3Pkg.all;

library hps_daq;
use hps_daq.HpsTiPkg.all;
use hps_daq.HpsPkg.all;

entity TiDataSend is
   generic (
      TPD_G : time := 1 ns
      );
   port (

      -- Event Data
      tiDistClk    : in sl;
      tiDistClkRst : in sl;
      daqDataEn    : in sl;
      daqData      : in slv(71 downto 0);
      blockLevel   : in slv(7 downto 0);
      syncEvent    : in sl;

      -- Output Stream
      txData   : out slv(9 downto 0);
      txDataEn : out sl;
      txReady  : in  sl;

      -- Status
      readPause     : out sl;
      readDone      : out sl;
      trigTxDone    : out sl;
      syncSentCount : out slv(15 downto 0)
      );
end TiDataSend;

architecture STRUCTURE of TiDataSend is

   signal sIbMaster        : AxiStreamMasterType;
   signal sIbCtrl          : AxiStreamCtrlType;
   signal mIbMaster        : AxiStreamMasterType;
   signal mIbSlave         : AxiStreamSlaveType;
   signal regDataEn        : sl;
   signal regData          : slv(71 downto 0);
   signal periodCnt        : slv(7 downto 0);
   signal blkSend          : sl;
   signal head             : sl;
   signal word             : sl;
   signal syncHold         : sl;
   signal syncSentCountInt : slv(15 downto 0);

begin

   syncSentCount <= syncSentCountInt;

--   SynchronizerEdge_1 : entity surf.SynchronizerOneShot
--      generic map (
--         TPD_G => TPD_G)
--      port map (
--         clk     => tiDistClk,
--         rst     => tiDistClkRst,
--         dataIn  => syncEvent,
--         dataOut => syncEventEdge);

   process (tiDistClk)
   begin
      if (rising_edge(tiDistClk)) then
         if tiDistClkRst = '1' then
            sIbMaster        <= AXI_STREAM_MASTER_INIT_C after TPD_G;
            readDone         <= '0'                      after TPD_G;
            regDataEn        <= '0'                      after TPD_G;
            regData          <= (others => '0')          after TPD_G;
            periodCnt        <= (others => '0')          after TPD_G;
            blkSend          <= '0'                      after TPD_G;
            word             <= '0'                      after TPD_G;
            head             <= '0'                      after TPD_G;
            syncHold         <= '0'                      after TPD_G;
            syncSentCountInt <= (others => '0')          after TPD_G;
         else

            periodCnt <= periodCnt + 1 after TPD_G;
            if periodCnt = 255 then
               blkSend <= '1' after TPD_G;
            else
               blkSend <= '0' after TPD_G;
            end if;

            -- Register data
            regDataEn <= daqDataEn after TPD_G;
            regData   <= daqData   after TPD_G;

            -- Init
            sIbMaster.tValid              <= regDataEn             after TPD_G;
            sIbMaster.tLast               <= '0'                   after TPD_G;
            sIbMaster.tKeep(7 downto 0)   <= x"FF"                 after TPD_G;
            sIbMaster.tData(31 downto 0)  <= regData(31 downto 0)  after TPD_G;
            sIbMaster.tData(63 downto 32) <= regData(67 downto 36) after TPD_G;

            if syncEvent = '1' then
               syncHold <= '1' after TPD_G;
            end if;

            -- Overwrite special SVT sync bit
            if head = '1' and word = '0' then
               sIbMaster.tData(15) <= syncHold or syncEvent after TPD_G;
               if (regDataEn = '1') then
                  if (syncHold = '1' or syncEvent = '1') then
                     syncSentCountInt <= syncSentCountInt + 1 after TPD_G;
                  end if;
                  syncHold <= '0' after TPD_G;
               end if;
            end if;
            -- Header / word tracking
            if regDataEn = '1' then
               if regData(35 downto 34) = "10" or regData(71 downto 70) = "10" then
                  head <= '0' after TPD_G;
                  word <= '0' after TPD_G;
               else
                  head <= '1' after TPD_G;
                  if head = '1' then
                     word <= not word after TPD_G;
                  end if;
               end if;
            end if;

            -- Last field in bits 31:0 or bits 63:32
            if regData(35 downto 34) = "10" or regData(71 downto 70) = "10" then
               sIbMaster.tLast <= '1' after TPD_G;
            end if;

            -- Assert done
            readDone   <= sIbMaster.tValid and sIbMaster.tLast             after TPD_G;
            trigTxDone <= mIbMaster.tValid and mIbMaster.tLast and txReady after TPD_G;

         end if;
      end if;
   end process;


   -- Trigger Data Fifo
   U_TrigFifo : entity surf.AxiStreamFifo
      generic map (
         TPD_G               => TPD_G,
         PIPE_STAGES_G       => 0,
         SLAVE_READY_EN_G    => false,
         VALID_THOLD_G       => 1,
         MEMORY_TYPE_G       => "block",
         XIL_DEVICE_G        => "7SERIES",
         USE_BUILT_IN_G      => false,
         GEN_SYNC_FIFO_G     => true,
         CASCADE_SIZE_G      => 1,
         FIFO_ADDR_WIDTH_G   => 9,      -- 512 x 64
         FIFO_FIXED_THRESH_G => true,
         FIFO_PAUSE_THRESH_G => 300,
         SLAVE_AXI_CONFIG_G  => HPS_DMA_DATA_CONFIG_C,
         MASTER_AXI_CONFIG_G => TRG_8B_DATA_CONFIG_C
         ) port map (
            sAxisClk    => tiDistClk,
            sAxisRst    => tiDistClkRst,
            sAxisMaster => sIbMaster,
            sAxisSlave  => open,
            sAxisCtrl   => sIbCtrl,
            mAxisClk    => tiDistClk,
            mAxisRst    => tiDistClkRst,
            mAxisMaster => mIbMaster,
            mAxisSlave  => mIbSlave
            );

   readPause <= sIbCtrl.pause;

   -- Mux between trigger data and block level updates
   txData(9)          <= '1'                          when blkSend = '0' else '0';
   txData(8)          <= mIbMaster.tLast              when blkSend = '0' else '0';
   txData(7 downto 0) <= mIbMaster.tData(7 downto 0)  when blkSend = '0' else blockLevel;
   txDataEn           <= mIbMaster.tValid and txReady when blkSend = '0' else txReady;
   mIbSlave.tReady    <= txReady                      when blkSend = '0' else '0';

end architecture STRUCTURE;


library ieee;
use work.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library unisim;
use unisim.vcomponents.all;


library surf;
use surf.StdRtlPkg.all;

library rce_gen3_fw_lib;
use rce_gen3_fw_lib.RceG3Pkg.all;

library hps_daq;
use hps_daq.HpsPkg.all;
use surf.AxiStreamPkg.all;
use surf.AxiLitePkg.all;

entity evio_tb is end evio_tb;

-- Define architecture
architecture evio_tb of evio_tb is

   signal dbgClk      : sl;
   signal dbgClkRst   : sl;
   signal axisClk     : sl;
   signal axisClkRst  : sl;
   signal dbgCount    : slv(11 downto 0);
   signal testSend    : sl;
   signal outMaster   : AxiStreamMasterType;
   signal outSlave    : AxiStreamSlaveType;
   signal emuMaster   : AxiStreamMasterType;
   signal emuSlave    : AxiStreamSlaveType;
   signal emulateSize : slv(31 downto 0);

begin

   process
   begin
      axisClk <= '0';
      wait for 2.5 ns;
      axisClk <= '1';
      wait for 2.5 ns;
   end process;

   process
   begin
      axisClkRst <= '1';
      wait for 1000 ns;
      axisClkRst <= '0';
      wait;
   end process;

   process
   begin
      dbgClk <= '0';
      wait for 4 ns;
      dbgClk <= '1';
      wait for 4 ns;
   end process;

   process
   begin
      dbgClkRst <= '1';
      wait for 1000 ns;
      dbgClkRst <= '0';
      wait;
   end process;

   process (dbgClk)
   begin
      if rising_edge(dbgClk) then
         if dbgClkRst = '1' then
            testSend <= '0';
         else
            if dbgCount = 300 then
               testSend <= '1';
            else
               testSend <= '0';
            end if;
         end if;
      end if;
   end process;

   process (dbgClk)
   begin
      if rising_edge(dbgClk) then
         if dbgClkRst = '1' then
            dbgCount <= (others => '0');
         else
            dbgCount <= dbgCount + 1;
         end if;
      end if;
   end process;

   U_SsiPrbsTx : entity surf.SsiPrbsTx
      generic map (
         TPD_G                      => 1 ns,
         MEMORY_TYPE_G              => "block",
         XIL_DEVICE_G               => "7SERIES",
         USE_BUILT_IN_G             => false,
         GEN_SYNC_FIFO_G            => false,
         FIFO_ADDR_WIDTH_G          => 14,
         FIFO_PAUSE_THRESH_G        => 255,
         MASTER_AXI_STREAM_CONFIG_G => HPS_DMA_DATA_CONFIG_C,
         MASTER_AXI_PIPE_STAGES_G   => 0)
      port map (
         mAxisClk     => axisClk,
         mAxisRst     => axisClkRst,
         mAxisSlave   => emuSlave,
         mAxisMaster  => emuMaster,
         locClk       => dbgClk,
         locRst       => dbgClkRst,
         trig         => testSend,
         packetLength => emulateSize,
         busy         => open,
         tDest        => X"00",
         tId          => X"00");

   -- Compute PRBS size, (emulate * 4) + 1
   emulateSize(31 downto 14) <= (others => '0');
   emulateSize(13 downto 2)  <= x"A00";
   emulateSize(1 downto 0)   <= "01";

   U_Evio : entity hps_daq.AxisToEvio
      generic map (
         TPD_G             => 1 ns,
         IB_CASCADE_SIZE_G => 12)
      port map (
         axisClk     => axisClk,
         axisClkRst  => axisClkRst,
         evioHeader  => (others => '0'),
         sAxisMaster => emuMaster,
         sAxisSlave  => emuSlave,
         mAxisMaster => outMaster,
         mAxisSlave  => outSlave);

   outSlave <= AXI_STREAM_SLAVE_FORCE_C;

end evio_tb;


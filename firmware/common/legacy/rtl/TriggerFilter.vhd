-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : TriggerFilter.vhd
-- Author     : Benjamin Reese  <bareese@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2013-03-01
-- Last update: 2023-08-10
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------
-- Copyright (c) 2015 SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
use surf.SsiPkg.all;


library ldmx;
use ldmx.LdmxPkg.all;
use ldmx.DataPathPkg.all;
use ldmx.RceConfigPkg.all;

entity TriggerFilter is

   generic (
      TPD_G             : time    := 1 ns;
      CLK_PERIOD_G      : real    := 4.0E-9;
      TRIGGER_TIME_G    : real    := 21.00E-6;
      MAX_OUTSTANDING_G : integer := 5);
   port (
      -- Master system clock, 125Mhz
      clk : in sl;
      rst : in sl;

      -- Trigger
      trigger             : in  sl;
      triggersOutstanding : out slv(3 downto 0);

      busy : out sl
      );

end entity TriggerFilter;

architecture rtl of TriggerFilter is

   constant EXPIRE_COUNT_C : integer := integer(TRIGGER_TIME_G / CLK_PERIOD_G);
   constant COUNTER_SIZE_C : integer := bitSize(EXPIRE_COUNT_C);

   type RegType is record
      counter  : slv(COUNTER_SIZE_C-1 downto 0);
      fifoRdEn : sl;
   end record RegType;

   constant REG_INIT_C : RegType := (
      counter  => (others => '0'),
      fifoRdEn => '0');

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal fifoRdData : slv(COUNTER_SIZE_C-1 downto 0);
   signal fifoEmpty  : sl;

begin

--   SynchronizerEdge_1 : entity surf.SynchronizerEdge
--      generic map (
--         TPD_G          => TPD_G,
--         RST_POLARITY_G => RST_POLARITY_G,
--         OUT_POLARITY_G => OUT_POLARITY_G,
--         RST_ASYNC_G    => RST_ASYNC_G,
--         BYPASS_SYNC_G  => BYPASS_SYNC_G,
--         STAGES_G       => STAGES_G,
--         INIT_G         => INIT_G)
--      port map (
--         clk        => clk,
--         rst        => rst,
--         dataIn     => trigger,
--         risingEdge => triggerRise);

   -- Queue up incomming triggers
   -- Could just increment and decrement a counter but this might be cleaner
   TRIGGER_FIFO : entity surf.Fifo
      generic map (
         TPD_G           => TPD_G,
         GEN_SYNC_FIFO_G => true,
         MEMORY_TYPE_G   => "distributed",
         FWFT_EN_G       => false,
         DATA_WIDTH_G    => 1,
         ADDR_WIDTH_G    => maximum(4, bitSize(MAX_OUTSTANDING_G)),
         FULL_THRES_G    => MAX_OUTSTANDING_G-1)
      port map (
         rst           => rst,
         wr_clk        => clk,
         wr_en         => trigger,
         din           => "1",
         rd_clk        => clk,
         rd_en         => r.fifoRdEn,
         rd_data_count => triggersOutstanding,
         dout          => open,
         empty         => fifoEmpty,
         prog_full     => busy);


   comb : process (fifoEmpty, r, rst) is
      variable v : RegType;
   begin
      v := r;

      v.fifoRdEn := '0';

      if (fifoEmpty = '0' and r.fifoRdEn = '0') then
         v.counter := r.counter + 1;
      end if;

      if (r.counter = EXPIRE_COUNT_C) then
         v.fifoRdEn := '1';
         v.counter  := (others => '0');
      end if;


      ----------------------------------------------------------------------------------------------
      -- Reset 
      ----------------------------------------------------------------------------------------------
      if (rst = '1') then
         v := REG_INIT_C;
      end if;

      ----------------------------------------------------------------------------------------------
      -- Outputs
      ----------------------------------------------------------------------------------------------
      rin <= v;

   end process comb;



   sync : process (clk) is
   begin
      if (rising_edge(clk)) then
         r <= rin after TPD_G;
      end if;
   end process sync;


end architecture rtl;

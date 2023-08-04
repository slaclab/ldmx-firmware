-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2013 SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;


library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;

library ldmx;
use ldmx.HpsFebHwPkg.all;

entity HpsFebPGoodMon is
   generic (
      TPD_G : time := 1 ns);
   port (
      axilClk : in sl;
      axilRst : in sl;

      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;

      ledEn     : out sl;
      powerGood : in  PowerGoodType);

end HpsFebPGoodMon;

architecture rtl of HpsFebPGoodMon is

   type RegType is record
      axilReadSlave   : AxiLiteReadSlaveType;
      axilWriteSlave  : AxiLiteWriteSlaveType;
      ledEn           : sl;
      powerGoodCntRst : sl;
   end record RegType;

   constant REG_INIT_C : RegType := (
      axilReadSlave   => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave  => AXI_LITE_WRITE_SLAVE_INIT_C,
      ledEn           => '0',
      powerGoodCntRst => '0');

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   -------------------------------------------------------------------------------------------------
   -- Power good
   -------------------------------------------------------------------------------------------------
   constant POWER_GOOD_SLV_LENGTH_C : integer := 17;

   function toSlv (powerGood : PowerGoodType) return slv
   is
      variable ret : slv(POWER_GOOD_SLV_LENGTH_C-1 downto 0) := (others => '0');
   begin
      ret(0) := powerGood.a22;
      ret(1) := powerGood.a18;
      ret(2) := powerGood.a16;
      ret(3) := powerGood.a29A;
      ret(4) := powerGood.a29D;

      ret(5) := powerGood.hybrid(0).v125;
      ret(6) := powerGood.hybrid(0).dvdd;
      ret(7) := powerGood.hybrid(0).avdd;

      ret(8)  := powerGood.hybrid(1).v125;
      ret(9)  := powerGood.hybrid(1).dvdd;
      ret(10) := powerGood.hybrid(1).avdd;

      ret(11) := powerGood.hybrid(2).v125;
      ret(12) := powerGood.hybrid(2).dvdd;
      ret(13) := powerGood.hybrid(2).avdd;

      ret(14) := powerGood.hybrid(3).v125;
      ret(15) := powerGood.hybrid(3).dvdd;
      ret(16) := powerGood.hybrid(3).avdd;
      return ret;
   end function toSlv;


   constant POWER_GOOD_CNT_WIDTH_C : integer := 16;
   signal powerGoodSyncSlv         : slv(POWER_GOOD_SLV_LENGTH_C-1 downto 0);
   signal powerGoodFallCnt         : SlVectorArray(POWER_GOOD_SLV_LENGTH_C-1 downto 0, POWER_GOOD_CNT_WIDTH_C-1 downto 0);


begin


   SyncStatusVector_1 : entity surf.SyncStatusVector
      generic map (
         TPD_G          => TPD_G,
         COMMON_CLK_G   => true,
         IN_POLARITY_G  => "0",
         OUT_POLARITY_G => '1',
         SYNTH_CNT_G    => "1",
         CNT_RST_EDGE_G => false,
         CNT_WIDTH_G    => POWER_GOOD_CNT_WIDTH_C,
         WIDTH_G        => POWER_GOOD_SLV_LENGTH_C)
      port map (
         statusIn     => toSlv(powerGood),
         statusOut    => powerGoodSyncSlv,
         cntRstIn     => r.powerGoodCntRst,
         rollOverEnIn => (others => '0'),
         cntOut       => powerGoodFallCnt,
         wrClk        => axilClk,
         wrRst        => axilRst,
         rdClk        => axilClk,
         rdRst        => axilRst);

   comb : process (axilReadMaster, axilRst, axilWriteMaster, powerGoodFallCnt, powerGoodSyncSlv, r) is
      variable v       : RegType;
      variable axilEp  : AxiLiteEndpointType;
      variable addrInt : integer;
   begin
      v := r;

      -- Turn on hybrid hard reset when no power to hybrid
      -- Only allow it high for one cycle when there is power
      v.powerGoodCntRst     := '0';

      axiSlaveWaitTxn(axilEp, axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave);

      axiSlaveRegister(axilEp, X"00", 0, v.ledEn);
      axiSlaveRegister(axilEp, X"fC", 31, v.powerGoodCntRst);

      for i in 0 to POWER_GOOD_SLV_LENGTH_C-1 loop
         axiSlaveRegisterR(axilEp, X"80"+toSlv(i*4, 8), 31, powerGoodSyncSlv(i));
         axiSlaveRegisterR(axilEp, X"80"+toSlv(i*4, 8), 0, muxSlVectorArray(powerGoodFallCnt, i));
      end loop;

      axiSlaveDefault(axilEp, v.axilWriteSlave, v.axilReadSlave, AXI_RESP_DECERR_C);

      ----------------------------------------------------------------------------------------------
      -- Reset
      ----------------------------------------------------------------------------------------------
      if (axilRst = '1') then
         v := REG_INIT_C;
      end if;

      rin <= v;

      axilReadSlave  <= r.axilReadSlave;
      axilWriteSlave <= r.axilWriteSlave;
      ledEn          <= r.ledEn;

   end process comb;

   seq : process (axilClk) is
   begin
      if (rising_edge(axilClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end architecture rtl;

-------------------------------------------------------------------------------
-- Title      : 
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

library UNISIM;
use UNISIM.VCOMPONENTS.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;

library ldmx_ts;
use ldmx_ts.TsPkg.all;

entity TsRxLogic is

   generic (
      TPD_G : time := 1 ns);
   port (
      tsClk250         : in  sl;
      tsRst250         : in  sl;
      tsRxPhyInit      : out sl := '0';
      tsRxPhyResetDone : in  sl;
      tsRxPhyLoopback  : out slv(2 downto 0);
      tsRxData         : in  slv(15 downto 0);
      tsRxDataK        : in  slv(1 downto 0);
      tsRxMsg          : out TsData6ChMsgType;

      -- Axil inteface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType  := AXI_LITE_READ_SLAVE_EMPTY_DECERR_C;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType := AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);

end entity TsRxLogic;

architecture rtl of TsRxLogic is

   constant K28_5_C : slv(7 downto 0) := "10111100";  -- K28.5, 0xBC

   type StateType is (
      WAIT_COMMA_S,
      WORD_1_S,
      WORD_2_S,
      WORD_3_S,
      WORD_4_S,
      WORD_5_S);

   type RegType is record
      state   : StateType;
      tsRxMsg : TsData6ChMsgType;
   end record RegType;

   constant REG_INIT_C : RegType := (
      state   => WAIT_COMMA_S,
      tsRxMsg => TS_DATA_6CH_MSG_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal writeRegister : slv32Array(0 downto 0);

begin

   comb : process (r, tsRst250, tsRxData, tsRxDataK) is
      variable v : RegType := REG_INIT_C;
   begin
      v := r;

      v.tsRxMsg.strobe := '0';

      case r.state is
         when WAIT_COMMA_S =>
            if (tsRxDataK(0) = '1' and tsRxData(7 downto 0) = K28_5_C) then
               v.tsRxMsg.bc0                := tsRxData(8);
               v.tsRxMsg.ce                 := tsRxData(9);
               v.tsRxMsg.capId              := tsRxData(11 downto 10);
               v.tsRxMsg.tdc(0)(3 downto 0) := tsRxData(15 downto 12);
               v.state                      := WORD_1_S;
            end if;
         when WORD_1_S =>
            v.tsRxMsg.adc(0) := tsRxData(7 downto 0);
            v.tsRxMsg.adc(1) := tsRxData(15 downto 8);
            v.state          := WORD_2_S;
         when WORD_2_S =>
            v.tsRxMsg.adc(2) := tsRxData(7 downto 0);
            v.tsRxMsg.adc(3) := tsRxData(15 downto 8);
            v.state          := WORD_3_S;
         when WORD_3_S =>
            v.tsRxMsg.adc(4) := tsRxData(7 downto 0);
            v.tsRxMsg.adc(5) := tsRxData(15 downto 8);
            v.state          := WORD_4_S;
         when WORD_4_S =>
            v.tsRxMsg.tdc(0)(5 downto 4) := tsRxData(1 downto 0);
            v.tsRxMsg.tdc(1)(5 downto 0) := tsRxData(7 downto 2);
            v.tsRxMsg.tdc(2)(5 downto 0) := tsRxData(13 downto 8);
            v.tsRxMsg.tdc(3)(1 downto 0) := tsRxData(15 downto 14);
            v.state                      := WORD_5_S;
         when WORD_5_S =>
            v.tsRxMsg.tdc(3)(5 downto 2) := tsRxData(3 downto 0);
            v.tsRxMsg.tdc(4)(3 downto 0) := tsRxData(7 downto 4);
            v.tsRxMsg.tdc(4)(5 downto 4) := tsRxData(9 downto 8);
            v.tsRxMsg.tdc(5)(5 downto 0) := tsRxData(15 downto 10);
            v.tsRxMsg.strobe             := '1';
            v.state                      := WAIT_COMMA_S;
      end case;

      -- Reset
      if (tsRst250 = '1') then
         v := REG_INIT_C;
      end if;

      -- Outputs
      tsRxMsg <= r.tsRxMsg;

      rin <= v;


   end process comb;

   seq : process (tsClk250) is
   begin
      if (rising_edge(tsClk250)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

   U_AxiLiteRegs_1 : entity surf.AxiLiteRegs
      generic map (
         TPD_G           => TPD_G,
         NUM_WRITE_REG_G => 1,
         NUM_READ_REG_G  => 1)
      port map (
         axiClk         => axilClk,          -- [in]
         axiClkRst      => axilRst,           -- [in]
         axiReadMaster  => axilReadMaster,   -- [in]
         axiReadSlave   => axilReadSlave,    -- [out]
         axiWriteMaster => axilWriteMaster,  -- [in]
         axiWriteSlave  => axilWriteSlave,   -- [out]
         writeRegister  => writeRegister);    -- [out]

      U_SynchronizerVector_1 : entity surf.SynchronizerVector
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => 3)
      port map (
         clk     => tsClk250,                      -- [in]
         rst     => tsRst250,                      -- [in]
         dataIn  => writeRegister(0)(2 downto 0),  -- [in]
         dataOut => tsRxPhyLoopback);              -- [out]


end rtl;



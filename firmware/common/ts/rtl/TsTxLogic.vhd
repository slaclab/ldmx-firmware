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

entity TsTxLogic is

   generic (
      TPD_G : time := 1 ns);
   port (
      tsClk250         : in  sl;
      tsRst250         : in  sl;
      tsTxPhyInit      : out sl                    := '0';
      tsTxPhyResetDone : in  sl;
      tsTxMsg          : in  TsData6ChMsgType;
      tsTxData         : out slv(15 downto 0);
      tsTxDataK        : out slv(1 downto 0);
      -- Axil inteface
      axilClk          : in  sl;
      axilRst          : in  sl;
      axilReadMaster   : in  AxiLiteReadMasterType;
      axilReadSlave    : out AxiLiteReadSlaveType  := AXI_LITE_READ_SLAVE_EMPTY_DECERR_C;
      axilWriteMaster  : in  AxiLiteWriteMasterType;
      axilWriteSlave   : out AxiLiteWriteSlaveType := AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);

end entity TsTxLogic;

architecture rtl of TsTxLogic is

   constant K28_1_C : slv(7 downto 0) := "00111100";
   constant K28_5_C : slv(7 downto 0) := "10111100";  -- K28.5, 0xBC
   constant K28_2_C : slv(7 downto 0) := "01011100";  -- K28.2, 0x5C
   constant K29_7_C : slv(7 downto 0) := "11111101";  -- K29.7, 0xFD

   type StateType is (
      INIT_0_S,      
      INIT_1_S,
      WAIT_RESET_DONE_S,
      IDLE_S,
      WORD_1_S,
      WORD_2_S,
      WORD_3_S,
      WORD_4_S,
      WORD_5_S);

   type RegType is record
      state       : StateType;
      tsTxPhyInit : sl;
      idleSeq     : sl;
      tsTxData    : slv(15 downto 0);
      tsTxDataK   : slv(1 downto 0);
   end record RegType;

   constant REG_INIT_C : RegType := (
      state       => INIT_0_S,
      tsTxPhyInit => '0',
      idleSeq     => '0',
      tsTxData    => (others => '0'),
      tsTxDataK   => (others => '0'));

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

begin

--    U_PwrUpRst_1 : entity surf.PwrUpRst
--       generic map (
--          TPD_G      => TPD_G,
--          DURATION_G => 1000)
--       port map (
--          arst   => r.tsTxPhyInit,       -- [in]
--          clk    => tsClk250,            -- [in]
--          rstOut => tsTxPhyInit);        -- [out]

   tsTxPhyInit <= r.tsTxPhyInit;

   comb : process (r, tsRst250, tsTxMsg, tsTxPhyResetDone) is
      variable v : RegType := REG_INIT_C;
   begin
      v := r;

      v.tsTxPhyInit := '0';

      case r.state is
         when INIT_0_S =>
            v.state := INIT_1_S;
         when INIT_1_S =>
            -- Init the phy
            v.tsTxPhyInit := '1';
            v.state       := WAIT_RESET_DONE_S;
         when WAIT_RESET_DONE_S =>
            if (tsTxPhyResetDone = '1') then
               v.state := IDLE_S;
            end if;
         when IDLE_S =>
            v.idleSeq   := not r.idleSeq;
            v.tsTxDataK := "11";
            if (r.idleSeq = '0') then
               v.tsTxData := K28_2_C & K29_7_C;
            else
               v.tsTxData := K28_2_C & K28_2_C;
            end if;

            if (tsTxMsg.strobe = '1') then
               v.tsTxDataK              := "01";
               v.tsTxData(7 downto 0)   := K28_5_C;
               v.tsTxData(8)            := tsTxMsg.bc0;
               v.tsTxData(9)            := tsTxMsg.ce;
               v.tsTxData(11 downto 10) := tsTxMsg.capId;
               v.tsTxData(15 downto 12) := tsTxMsg.tdc(0)(3 downto 0);
               v.state                  := WORD_1_S;
            end if;
         when WORD_1_S =>
            v.tsTxDataK             := "00";
            v.tsTxData(7 downto 0)  := tsTxMsg.adc(0);
            v.tsTxData(15 downto 8) := tsTxMsg.adc(1);
            v.state                 := WORD_2_S;
         when WORD_2_S =>
            v.tsTxDataK             := "00";
            v.tsTxData(7 downto 0)  := tsTxMsg.adc(2);
            v.tsTxData(15 downto 8) := tsTxMsg.adc(3);
            v.state                 := WORD_3_S;
         when WORD_3_S =>
            v.tsTxDataK             := "00";
            v.tsTxData(7 downto 0)  := tsTxMsg.adc(4);
            v.tsTxData(15 downto 8) := tsTxMsg.adc(5);
            v.state                 := WORD_4_S;
         when WORD_4_S =>
            v.tsTxDataK              := "00";
            v.tsTxData(1 downto 0)   := tsTxMsg.tdc(0)(5 downto 4);
            v.tsTxData(7 downto 2)   := tsTxMsg.tdc(1)(5 downto 0);
            v.tsTxData(13 downto 8)  := tsTxMsg.tdc(2)(5 downto 0);
            v.tsTxData(15 downto 14) := tsTxMsg.tdc(3)(1 downto 0);
            v.state                  := WORD_5_S;
         when WORD_5_S =>
            v.tsTxDataK              := "00";
            v.tsTxData(3 downto 0)   := tsTxMsg.tdc(3)(5 downto 2);
            v.tsTxData(7 downto 4)   := tsTxMsg.tdc(4)(3 downto 0);
            v.tsTxData(9 downto 8)   := tsTxMsg.tdc(4)(5 downto 4);
            v.tsTxData(15 downto 10) := tsTxMsg.tdc(5)(5 downto 0);
            v.state                  := IDLE_S;
      end case;

      -- Reset
      if (tsRst250 = '1') then
         v := REG_INIT_C;
      end if;

      -- Outputs
      tsTxData  <= r.tsTxData;
      tsTxDataK <= r.tsTxDataK;

      rin <= v;


   end process comb;

   seq : process (tsClk250) is
   begin
      if (rising_edge(tsClk250)) then
         r <= rin after TPD_G;
      end if;
   end process seq;


end rtl;



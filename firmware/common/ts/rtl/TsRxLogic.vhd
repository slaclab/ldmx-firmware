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
      tsRxDispErr      : in  slv(1 downto 0);
      tsRxDecErr       : in  slv(1 downto 0);
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
      INIT_S,
      WAIT_RESETDONE_LOW_S,
      WAIT_RESETDONE_HIGH_S,
      WAIT_COMMA_S,
      WORD_1_S,
      WORD_2_S,
      WORD_3_S,
      WORD_4_S,
      WORD_5_S);

   type RegType is record
      state           : StateType;
      rxFrameCount    : slv(63 downto 0);
      rxErrorCount    : slv(31 downto 0);
      countReset      : sl;
      tsRxPhyInit     : sl;
      tsRxPhyLoopback : slv(2 downto 0);
      tsRxMsg         : TsData6ChMsgType;
      axilReadSlave   : AxiLiteReadSlaveType;
      axilWriteSlave  : AxiLiteWriteSlaveType;
   end record RegType;

   constant REG_INIT_C : RegType := (
      state           => WAIT_COMMA_S,
      rxFrameCount    => (others => '0'),
      rxErrorCount    => (others => '0'),
      countReset      => '0',
      tsRxPhyInit     => '0',
      tsRxPhyLoopback => "010",
      tsRxMsg         => TS_DATA_6CH_MSG_INIT_C,
      axilReadSlave   => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave   => AXI_LITE_WRITE_SLAVE_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal syncAxilReadMaster  : AxiLiteReadMasterType;
   signal syncAxilReadSlave   : AxiLiteReadSlaveType;
   signal syncAxilWriteMaster : AxiLiteWriteMasterType;
   signal syncAxilWriteSlave  : AxiLiteWriteSlaveType;

   signal resetDoneRise : sl;

begin

   U_AxiLiteAsync_1 : entity surf.AxiLiteAsync
      generic map (
         TPD_G            => TPD_G)
      port map (
         sAxiClk         => axilClk,              -- [in]
         sAxiClkRst      => axilRst,              -- [in]
         sAxiReadMaster  => axilReadMaster,       -- [in]
         sAxiReadSlave   => axilReadSlave,        -- [out]
         sAxiWriteMaster => axilWriteMaster,      -- [in]
         sAxiWriteSlave  => axilWriteSlave,       -- [out]
         mAxiClk         => tsClk250,             -- [in]
         mAxiClkRst      => tsRst250,             -- [in]
         mAxiReadMaster  => syncAxilReadMaster,   -- [out]
         mAxiReadSlave   => syncAxilReadSlave,    -- [in]
         mAxiWriteMaster => syncAxilWriteMaster,  -- [out]
         mAxiWriteSlave  => syncAxilWriteSlave);  -- [in]

   U_SynchronizerEdge_1 : entity surf.SynchronizerEdge
      generic map (
         TPD_G => TPD_G)
      port map (
         clk         => tsClk250,          -- [in]
         rst         => tsRst250,          -- [in]
         dataIn      => tsRxPhyResetDone,  -- [in]
         dataOut     => open,              -- [out]
         risingEdge  => resetDoneRise,     -- [out]
         fallingEdge => open);             -- [out]


   comb : process (r, syncAxilReadMaster, syncAxilWriteMaster, tsRst250, tsRxData, tsRxDataK,
                   tsRxDecErr, tsRxDispErr, tsRxPhyResetDone) is
      variable v : RegType := REG_INIT_C;
      variable axilEp : AxiLiteEndpointType;
   begin
      v := r;

      v.tsRxMsg.strobe := '0';
      v.tsRxPhyInit    := '0';

      -- Count error with saturating counter
      if (tsRxPhyResetDone = '1' and (tsRxDecErr /= "00" or tsRxDispErr /= "00")) then
         v.rxErrorCount := r.rxErrorCount + 1;
      end if;
      if (r.rxErrorCount = X"FFFFFFFF") then
         v.rxErrorCount := r.rxErrorCount;
      end if;

      case r.state is
         when INIT_S =>
            v.tsRxPhyInit := '1';
            v.state       := WAIT_RESETDONE_LOW_S;
         when WAIT_RESETDONE_LOW_S =>
            if (tsRxPhyResetDone = '0') then
               v.state := WAIT_RESETDONE_HIGH_S;
            end if;
         when WAIT_RESETDONE_HIGH_S =>
            if (tsRxPhyResetDone = '1') then
               v.state := WAIT_COMMA_S;
            end if;

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
            v.rxFrameCount               := r.rxFrameCount + 1;
            v.state                      := WAIT_COMMA_S;
      end case;

      

      if (r.state = WAIT_COMMA_S and (tsRxDispErr /= "00" or tsRxDecErr /= "00")) then
         v.state := INIT_S;
      end if;

      ----------------------------------------------------------------------------------------------
      -- AXI Lite
      ----------------------------------------------------------------------------------------------
      v.countReset := '0';
      if (r.countReset = '1') then
         v.rxFrameCount := (others => '0');
         v.rxErrorCount := (others => '0');
      end if;

      axiSlaveWaitTxn(axilEp, syncAxilWriteMaster, syncAxilReadMaster, v.axilWriteSlave, v.axilReadSlave);

      axiSlaveRegisterR(axilEp, X"00", 0, tsRxPhyResetDone);
      axiSlaveRegister(axilEp, X"00", 1, v.countReset);
      axiSlaveRegister(axilEp, X"04", 0, v.tsRxPhyLoopback);
      axiSlaveRegisterR(axilEp, X"08", 0, r.rxFrameCount);
      axiSlaveRegisterR(axilEp, X"10", 0, r.rxErrorCount);

      axiSlaveDefault(axilEp, v.axilWriteSlave, v.axilReadSlave, AXI_RESP_DECERR_C);

      -- Reset
      if (tsRst250 = '1') then
         v := REG_INIT_C;
         v.rxFrameCount := r.rxFrameCount;
         v.rxErrorCount := r.rxErrorCount;
      end if;

      -- Outputs
      tsRxMsg            <= r.tsRxMsg;
      tsRxPhyInit        <= r.tsRxPhyInit;
      tsRxPhyLoopback    <= r.tsRxPhyLoopback;
      syncAxilReadSlave  <= r.axilReadSlave;
      syncAxilWriteSlave <= r.axilWriteSlave;

      rin <= v;


   end process comb;

   seq : process (tsClk250) is
   begin
      if (rising_edge(tsClk250)) then
         r <= rin after TPD_G;
      end if;
   end process seq;



end rtl;



-------------------------------------------------------------------------------
-- Title         : Clock/Trigger Sink Module For DPM, Version 2
-- File          : LdmxDpmTimingSink.vhd
-------------------------------------------------------------------------------
-- Description:
-- Clock & Trigger sink module for COB
-------------------------------------------------------------------------------
-- This file is part of 'SLAC RCE Timing Core'.
-- It is subject to the license terms in the LICENSE.txt file found in the
-- top-level directory of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of 'SLAC RCE Timing Core', including this file,
-- may be copied, modified, propagated, or distributed except according to
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

library UNISIM;
use UNISIM.VCOMPONENTS.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;

library rce_gen3_fw_lib;

entity LdmxDpmTimingSink is
   generic (
      TPD_G           : time   := 1 ns;
      IODELAY_GROUP_G : string := "DtmTimingGrp"
      );
   port (

      -- Local Bus
      axiClk         : in  sl;
      axiClkRst      : in  sl;
      axiReadMaster  : in  AxiLiteReadMasterType;
      axiReadSlave   : out AxiLiteReadSlaveType;
      axiWriteMaster : in  AxiLiteWriteMasterType;
      axiWriteSlave  : out AxiLiteWriteSlaveType;

      -- Reference Clock
      sysClk200    : in sl;
      sysClk200Rst : in sl;

      -- Timing bus, Ref Clock Receiver Is External
      dtmClkP : in  slv(1 downto 0);
      dtmClkM : in  slv(1 downto 0);
      dtmFbP  : out sl;
      dtmFbM  : out sl;

      -- Clock and reset
      distDivClk    : out sl;
      distDivClkRst : out sl;
      distClkLocked : in  sl;

      -- Received Data, synchronous to distDivClk
      rxData   : out slv(9 downto 0);
      rxDataEn : out sl;

      -- Transmit data, synchronous to distDivClk
      txData   : in  slv(9 downto 0);
      txDataEn : in  sl;
      txReady  : out sl
      );
end LdmxDpmTimingSink;

architecture STRUCTURE of LdmxDpmTimingSink is

   -- Local Signals
   signal intRxData      : slv(9 downto 0);
   signal intRxDataEn    : sl;
   signal statusIdleCnt  : Slv16Array(1 downto 0);
   signal statusErrorCnt : Slv16Array(1 downto 0);
   signal rxDataCnt      : slv(31 downto 0);
   signal rxDataCntSync  : Slv32Array(1 downto 0);
   signal intTxData      : slv(9 downto 0);
   signal intTxDataEn    : sl;
   signal txDataCnt      : slv(31 downto 0);
   signal txDataCntSync  : slv(31 downto 0);
   signal dtmFb          : sl;
   signal dtmClk         : sl;
   signal intReset       : sl;
   signal intRxEcho      : sl;
   signal countReset     : sl;
   signal idistDivClk    : sl;
   signal idistDivClkRst : sl;

   type RegType is record
      cfgReset      : sl;
      countReset    : sl;
      cfgSet        : slv(1 downto 0);
      cfgDelay      : Slv5Array(4 downto 0);
      axiReadSlave  : AxiLiteReadSlaveType;
      axiWriteSlave : AxiLiteWriteSlaveType;
   end record RegType;

   constant REG_INIT_C : RegType := (
      cfgReset      => '0',
      countReset    => '0',
      cfgSet        => (others => '0'),
      cfgDelay      => (others => (others => '0')),
      axiReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axiWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C
      );

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   attribute IODELAY_GROUP                        : string;
   attribute IODELAY_GROUP of U_DpmTimingDlyCntrl : label is IODELAY_GROUP_G;

begin

   -- Clock and reset out
   rxData     <= intRxData;
   rxDataEn   <= intRxDataEn;

   ----------------------------------------
   -- Delay Control
   ----------------------------------------
   U_DpmTimingDlyCntrl : IDELAYCTRL
      port map (
         RDY    => open,                -- 1-bit output: Ready output
         REFCLK => sysClk200,           -- 1-bit input: Reference clock input
         RST    => sysClk200Rst         -- 1-bit input: Active high reset input
         );


   ----------------------------------------
   -- Incoming global clock
   ----------------------------------------
   U_DivClk : IBUFGDS
      generic map (DIFF_TERM => true)
      port map (
         I  => dtmClkP(0),
         IB => dtmClkM(0),
         O  => idistDivClk
         );

   intReset <= (not distClkLocked) or r.cfgReset;

   -- Reset gen
   U_RstGen : entity surf.RstSync
      generic map (
         TPD_G           => TPD_G,
         IN_POLARITY_G   => '1',
         OUT_POLARITY_G  => '1',
         RELEASE_DELAY_G => 16
         )
      port map (
         clk      => idistDivClk,
         asyncRst => intReset,
         syncRst  => idistDivClkRst
         );

   distDivClk    <= idistDivClk;
   distDivClkRst <= idistDivClkRst;

   ----------------------------------------
   -- Incoming Data Stream
   ----------------------------------------
   -- DTM Clock
   U_DtmClk : IBUFDS
      generic map (DIFF_TERM => true)
      port map (
         I  => dtmClkP(1),
         IB => dtmClkM(1),
         O  => dtmClk);

   -- Input processor
   U_CobDataSink : entity rce_gen3_fw_lib.CobDataSink10b
      generic map (
         TPD_G           => TPD_G,
         IODELAY_GROUP_G => IODELAY_GROUP_G
         ) port map (
            serialData     => dtmClk,
            distClk        => idistDivClk,
            distClkRst     => idistDivClkRst,
            rxData         => intRxData,
            rxDataEn       => intRxDataEn,
            configClk      => axiClk,
            configClkRst   => axiClkRst,
            configSet      => r.cfgSet(0),
            configDelay    => r.cfgDelay(0),
            statusIdleCnt  => statusIdleCnt(0),
            statusErrorCnt => statusErrorCnt(0));

   statusIdleCnt(1)  <= (others=>'0');
   statusErrorCnt(1) <= (others=>'0');

   process (idistDivClk)
   begin
      if rising_edge(idistDivClk) then
         if idistDivClkRst = '1' or countReset = '1' then
            rxDataCnt <= (others => '0') after TPD_G;
         elsif intRxDataEn = '1' then
            rxDataCnt <= rxDataCnt + 1 after TPD_G;
         end if;
      end if;
   end process;

   -- Rx data count sync
   U_RxDataCntSync : entity surf.SynchronizerFifo
      generic map (
         TPD_G         => TPD_G,
         DATA_WIDTH_G  => 32
         ) port map (
            rst    => axiClkRst,
            wr_clk => idistDivClk,
            wr_en  => '1',
            din    => rxDataCnt,
            rd_clk => axiClk,
            rd_en  => '1',
            valid  => open,
            dout   => rxDataCntSync(0)
            );

   rxDataCntSync(1) <= (others=>'0');

   ----------------------------------------
   -- Feedback Output
   ----------------------------------------

   -- Determine Echo
   intRxEcho <= '1' when intRxDataEn = '1' and intRxData(9 downto 8) = "01" else '0';

   -- Mux TX Data
   intTxDataEn <= txDataEn or intRxEcho;
   intTxData   <= txData when txDataEn = '1' else
                  intRxData when intRxEcho = '1' else
                  (others => '0');

   -- Module
   U_CobDataSource : entity rce_gen3_fw_lib.CobDataSource10b
      generic map (
         TPD_G => TPD_G
         ) port map (
            distClk    => idistDivClk,
            distClkRst => idistDivClkRst,
            txData     => intTxData,
            txDataEn   => intTxDataEn,
            txReady    => txReady,
            serialData => dtmFb
            );

   -- DTM Feedback
   U_DtmFb : OBUFDS
      port map (
         O  => dtmFbP,
         OB => dtmFbM,
         I  => dtmFb
         );

   process (idistDivClk)
   begin
      if rising_edge(idistDivClk) then
         if idistDivClkRst = '1' or countReset = '1' then
            txDataCnt <= (others => '0') after TPD_G;
         elsif intTxDataEn = '1' then
            txDataCnt <= txDataCnt + 1 after TPD_G;
         end if;
      end if;
   end process;

   -- Tx data count sync
   U_TxDataCntSync : entity surf.SynchronizerFifo
      generic map (
         TPD_G         => TPD_G,
         DATA_WIDTH_G  => 32
         ) port map (
            rst    => axiClkRst,
            wr_clk => idistDivClk,
            wr_en  => '1',
            din    => txDataCnt,
            rd_clk => axiClk,
            rd_en  => '1',
            valid  => open,
            dout   => txDataCntSync
            );


   ----------------------------------------
   -- Local Registers
   ----------------------------------------

   -- Sync
   process (axiClk) is
   begin
      if (rising_edge(axiClk)) then
         r <= rin after TPD_G;
      end if;
   end process;

   -- Async
   process (axiClkRst, axiReadMaster, axiWriteMaster, r, statusErrorCnt, statusIdleCnt, rxDataCntSync, txDataCntSync) is
      variable v         : RegType;
      variable axiStatus : AxiLiteStatusType;
   begin
      v := r;

      v.cfgReset   := '0';
      v.cfgSet     := "00";
      v.countReset := '0';

      axiSlaveWaitTxn(axiWriteMaster, axiReadMaster, v.axiWriteSlave, v.axiReadSlave, axiStatus);

      -- Write
      if (axiStatus.writeEnable = '1') then

         -- Master Reset, 0x000
         if axiWriteMaster.awaddr(11 downto 0) = x"000" then
            v.cfgReset := axiWriteMaster.wdata(0);

            -- OC Fifo Write Enable, 0x004 (legacy)

         -- OC 0 Delay configuration, 0x008
         elsif axiWriteMaster.awaddr(11 downto 0) = x"008" then
            v.cfgSet(0)   := '1';
            v.cfgDelay(0) := axiWriteMaster.wdata(4 downto 0);

            -- Receive status, 0x00C

            -- OC FIFO read, one per FIFO, 0x010 (legacy)

            -- Clock Count, 0x014 (legacy)

         -- OC 1 Delay configuration, 0x018
         elsif axiWriteMaster.awaddr(11 downto 0) = x"018" then
            v.cfgSet(1)   := '1';
            v.cfgDelay(1) := axiWriteMaster.wdata(4 downto 0);

            -- Receive status, 0x01C

         -- Counter Reset 0x020
         elsif axiWriteMaster.awaddr(11 downto 0) = x"020" then
            v.countReset := axiWriteMaster.wdata(0);

            -- Rx Count A, 0x024

            -- Rx Count B, 0x028

         end if;

         -- Send Axi response
         axiSlaveWriteResponse(v.axiWriteSlave);

      end if;

      -- Read
      if (axiStatus.readEnable = '1') then
         v.axiReadSlave.rdata := (others => '0');

         -- Master Reset, 0x000

         -- OC Fifo Write Enable, 0x004 (legacy)

         -- OC 0 Delay configuration, 0x008
         if axiReadMaster.araddr(11 downto 0) = x"008" then
            v.axiReadSlave.rdata(4 downto 0) := r.cfgDelay(0);

         -- Receive status, 0x00C
         elsif axiReadMaster.araddr(11 downto 0) = x"00C" then
            v.axiReadSlave.rdata(31 downto 16) := statusErrorCnt(0);
            v.axiReadSlave.rdata(15 downto 0)  := statusIdleCnt(0);

            -- OC FIFO read, one per FIFO, 0x010 (legacy)

            -- Clock Count, 0x014 (legacy)

         -- OC 1 Delay configuration, 0x018
         elsif axiReadMaster.araddr(11 downto 0) = x"018" then
            v.axiReadSlave.rdata(4 downto 0) := r.cfgDelay(1);

         -- Receive status, 0x01C
         elsif axiReadMaster.araddr(11 downto 0) = x"01C" then
            v.axiReadSlave.rdata(31 downto 16) := statusErrorCnt(1);
            v.axiReadSlave.rdata(15 downto 0)  := statusIdleCnt(1);

            -- Clock Reset, 0x020

         -- Rx Count A, 0x024
         elsif axiReadMaster.araddr(11 downto 0) = x"024" then
            v.axiReadSlave.rdata := rxDataCntSync(0);

         -- Rx Count B, 0x028
         elsif axiReadMaster.araddr(11 downto 0) = x"028" then
            v.axiReadSlave.rdata := rxDataCntSync(1);

                                        -- Tx Count, 0x02C
         elsif axiReadMaster.araddr(11 downto 0) = x"02C" then
            v.axiReadSlave.rdata := txDataCntSync;

         end if;

         -- Send Axi Response
         axiSlaveReadResponse(v.axiReadSlave);

      end if;

      -- Reset
      if (axiClkRst = '1') then
         v := REG_INIT_C;
      end if;

      -- Next register assignment
      rin <= v;

      -- Outputs
      axiReadSlave  <= r.axiReadSlave;
      axiWriteSlave <= r.axiWriteSlave;

   end process;

   -- Count Reset gen
   U_CountRstGen : entity surf.RstSync
      generic map (
         TPD_G           => TPD_G,
         IN_POLARITY_G   => '1',
         OUT_POLARITY_G  => '1',
         RELEASE_DELAY_G => 16
         )
      port map (
         clk      => idistDivClk,
         asyncRst => r.countReset,
         syncRst  => countReset
         );

end architecture STRUCTURE;


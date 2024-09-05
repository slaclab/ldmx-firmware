-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: Fast Control Message Emulator
--
-------------------------------------------------------------------------------
-- This file is part of 'LDMX'.
-- It is subject to the license terms in the LICENSE.txt file found in the
-- top-level directory of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of 'LDMX', including this file,
-- may be copied, modified, propagated, or distributed except according to
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiStreamPkg.all;
use surf.AxiLitePkg.all;

library lcls_timing_core;
use lcls_timing_core.TimingPkg.all;

library ldmx_tdaq;
use ldmx_tdaq.FcPkg.all;
use ldmx_tdaq.TriggerPkg.all;



entity SyntheticTrigger is
   generic (
      TPD_G                : time    := 1 ns;
      AXIL_CLK_IS_FC_CLK_G : boolean := false);
   port (
      -- Clock and Reset
      fcClk         : in  sl;
      fcRst         : in  sl;
      fcBus         : in  FcBusType;
      lclsTimingBus : in  TimingBusType;
      triggerData   : out TriggerDataType;

      -- AXI-Lite Interface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType);
end SyntheticTrigger;

architecture rtl of SyntheticTrigger is

   type RegType is record
      usrRoR         : sl;
      enableRor      : sl;
      rOrPeriodCount : slv(31 downto 0);
      rOrPeriod      : slv(31 downto 0);
      triggerData    : TriggerDataType;
      axilReadSlave  : AxiLiteReadSlaveType;
      axilWriteSlave : AxiLiteWriteSlaveType;
   end record RegType;

   constant REG_INIT_C : RegType := (
      usrRoR         => '0',
      enableRor      => '0',
      rOrPeriodCount => (others => '0'),
      rOrPeriod      => toSlv(100, 32),
      triggerData    => TRIGGER_DATA_INIT_C,
      axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal syncAxilReadMaster  : AxiLiteReadMasterType;
   signal syncAxilReadSlave   : AxiLiteReadSlaveType;
   signal syncAxilWriteMaster : AxiLiteWriteMasterType;
   signal syncAxilWriteSlave  : AxiLiteWriteSlaveType;

begin

   U_AxiLiteAsync_1 : entity surf.AxiLiteAsync
      generic map (
         TPD_G         => TPD_G,
         COMMON_CLK_G  => AXIL_CLK_IS_FC_CLK_G,
         PIPE_STAGES_G => 0)
      port map (
         sAxiClk         => axilClk,              -- [in]
         sAxiClkRst      => axilRst,              -- [in]
         sAxiReadMaster  => axilReadMaster,       -- [in]
         sAxiReadSlave   => axilReadSlave,        -- [out]
         sAxiWriteMaster => axilWriteMaster,      -- [in]
         sAxiWriteSlave  => axilWriteSlave,       -- [out]
         mAxiClk         => fcClk,                -- [in]
         mAxiClkRst      => fcRst,                -- [in]
         mAxiReadMaster  => syncAxilReadMaster,   -- [out]
         mAxiReadSlave   => syncAxilReadSlave,    -- [in]
         mAxiWriteMaster => syncAxilWriteMaster,  -- [out]
         mAxiWriteSlave  => syncAxilWriteSlave);  -- [in]

   comb : process (fcBus, fcRst, r, syncAxilReadMaster, syncAxilWriteMaster) is
      variable v      : RegType;
      variable axilEp : AxiLiteEndPointType;
   begin
      -- Latch the current value
      v := r;

      ----------------------------------------------------------------------
      --                AXI-Lite Register Logic
      ----------------------------------------------------------------------

      -- Determine the transaction type
      axiSlaveWaitTxn(axilEp, syncAxilWriteMaster, syncAxilReadMaster, v.axilWriteSlave, v.axilReadSlave);

      axiSlaveRegister (axilEp, x"00", 0, v.usrRoR);
      axiSlaveRegister (axilEp, x"04", 0, v.enableRoR);
      axiSlaveRegister (axilEp, x"08", 0, v.rOrPeriod);


      -- Closeout the transaction
      axiSlaveDefault(axilEp, v.axilWriteSlave, v.axilReadSlave, AXI_RESP_DECERR_C);


      v.triggerData := TRIGGER_DATA_INIT_C;

      if (fcBus.bc0 = '1') then
         v.triggerData.valid := '1';
         v.triggerData.bc0   := '1';
      end if;

      if (fcBus.bunchStrobe = '1') then
         v.triggerData.valid := '1';

         if (r.usrRoR = '1') then
            v.triggerData.data(0) := '1';
            v.usrRoR              := '0';
         end if;

         if (r.enableRoR = '1') then
            -- periodic RoR. Have to check the RoR Period counter first
            v.rOrPeriodCount := r.rOrPeriodCount + 1;
            if (r.rOrPeriodCount = r.rOrPeriod) then
               -- TX RoR
               v.rOrPeriodCount      := (others => '0');
               v.triggerData.data(0) := '1';
            end if;
         end if;
      end if;


      -- General Outputs
      triggerData        <= r.triggerData;
      -- AXI Outputs
      syncAxilWriteSlave <= r.axilWriteSlave;
      syncAxilReadSlave  <= r.axilReadSlave;

      ----------------------------------------------------------------------

      -- Reset
      if (fcRst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

   end process comb;

   seq : process (fcClk) is
   begin
      if (rising_edge(fcClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end rtl;

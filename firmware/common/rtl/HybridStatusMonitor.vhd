-------------------------------------------------------------------------------
-- Title         : APV25 Sync Pulse Detect
-- Project       : Heavy Photon Tracker
-------------------------------------------------------------------------------
-- File          : HybridStatusFramer.vhd
-- Author        : Ryan Herbst, rherbst@slac.stanford.edu
-- Created       : 12/08/2011
-------------------------------------------------------------------------------
-- Description:
-- Detects the sync pulse from APV25
-------------------------------------------------------------------------------
-- Copyright (c) 2011 by SLAC. All rights reserved.
-------------------------------------------------------------------------------
-- Modification history:
-- 12/08/2011: created.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
use surf.SsiPkg.all;


library ldmx;
use ldmx.HpsPkg.all;
use ldmx.FebConfigPkg.all;

entity HybridStatusMonitor is
   generic (
      TPD_G             : time                 := 1 ns;
      HYBRID_NUM_G      : integer range 0 to 8 := 0;
      APVS_PER_HYBRID_G : integer              := 5);
   port (
      -- Master system clock, 125Mhz
      sysClk : in sl;
      sysRst : in sl;

      -- Config
      febConfig : in FebConfigType;

      -- Apv sync statuses
      syncDetected  : in  slv(APVS_PER_HYBRID_G-1 downto 0);
      syncBase      : in  Slv16Array(APVS_PER_HYBRID_G-1 downto 0);
      syncPeak      : in  Slv16Array(APVS_PER_HYBRID_G-1 downto 0);
      frameCount    : in  Slv32Array(APVS_PER_HYBRID_G-1 downto 0);
      pulseStream   : in  slv64Array(APVS_PER_HYBRID_G-1 downto 0);
      minSamples    : in  Slv16Array(APVS_PER_HYBRID_G-1 downto 0);
      maxSamples    : in  Slv16Array(APVS_PER_HYBRID_G-1 downto 0);
      lostSyncCount : in  slv32Array(APVS_PER_HYBRID_G-1 downto 0);
      countReset    : out sl;

      -- Axi-Lite interface for configuration and status
      axiReadMaster  : in  AxiLiteReadMasterType;
      axiReadSlave   : out AxiLiteReadSlaveType;
      axiWriteMaster : in  AxiLiteWriteMasterType;
      axiWriteSlave  : out AxiLiteWriteSlaveType

      -- Axi-Stream (SSI) extracted frames
--       dataClk                : in  sl;
--       dataClkRst             : in  sl;
--       syncStatus             : out slv(7 downto 0) := (others => '0');
--       hybridStatusAxisMaster : out AxiStreamMasterType;
--       hybridStatusAxisSlave  : in  AxiStreamSlaveType;
--       hybridStatusAxisCtrl   : in  AxiStreamCtrlType

      );
end HybridStatusMonitor;

architecture rtl of HybridStatusMonitor is

   type RegType is record
      count         : slv(31 downto 0);
      pulseStream   : slv64array(APVS_PER_HYBRID_G-1 downto 0);
      countReset    : sl;
      hybridInfo    : HybridInfoType;
      axiReadSlave  : AxiLiteReadSlaveType;
      axiWriteSlave : AxiLiteWriteSlaveType;
   end record RegType;

   constant REG_INIT_C : RegType := (
      count         => (others => '0'),
      pulseStream   => (others => (others => '0')),
      countReset    => '0',
      hybridInfo    => HYBRID_INFO_INIT_C,
      axiReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axiWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;


begin

   comb : process (axiReadMaster, axiWriteMaster, febConfig, frameCount, lostSyncCount, maxSamples,
                   minSamples, pulseStream, r, syncBase, syncDetected, syncPeak, sysRst) is
      variable v          : RegType;
      variable axilEp     : AxiLiteEndpointType;
      variable hybridInfo : HybridInfoType;
      variable freeze     : sl;
      variable index      : IntegerArray(0 to 5);
   begin
      v := r;

      -- Translate apv index accoring to hybridType
      if (febConfig.hybridType(HYBRID_NUM_G) = NEW_HYBRID_C) then
         index(2) := 0;
         index(3) := 1;
         index(4) := 2;
         index(0) := 3;
         index(1) := 4;
         index(5) := 5;
      else
         index(0) := 0;
         index(1) := 1;
         index(2) := 2;
         index(3) := 3;
         index(4) := 4;
         index(5) := 5;
      end if;

      v.hybridInfo.febAddress := febConfig.febAddress;
      v.hybridInfo.hybridNum  := toSlv(HYBRID_NUM_G, 3);
      v.hybridInfo.hybridType := febConfig.hybridType(HYBRID_NUM_G);
      for i in APVS_PER_HYBRID_G-1 downto 0 loop
         v.hybridInfo.syncStatus(i) := syncDetected(i);
      end loop;


      ----------------------------------------------------------------------------------------------
      -- Axi Lite Interface
      ----------------------------------------------------------------------------------------------
      axiSlaveWaitTxn(axilEp, axiWriteMaster, axiReadMaster, v.axiWriteSlave, v.axiReadSlave);

      for i in APVS_PER_HYBRID_G-1 downto 0 loop
         axiSlaveRegisterR(axilEp, X"00", i, r.hybridInfo.syncStatus(i));
      end loop;

      for i in APVS_PER_HYBRID_G-1 downto 0 loop
         axiSlaveRegisterR(axilEp, X"10"+toSlv(i*4, 8), 0, syncBase(index(i)));
         axiSlaveRegisterR(axilEp, X"10"+toSlv(i*4, 8), 16, syncPeak(index(i)));
      end loop;

      for i in APVS_PER_HYBRID_G-1 downto 0 loop
         axiSlaveRegisterR(axilEp, X"30"+toSlv(i*4, 8), 0, frameCount(index(i)));
      end loop;

      freeze := '0';
      axiRdDetect(axilEp, X"50", freeze);
      if (freeze = '1') then
         v.pulseStream := pulseStream;
      end if;

      for i in APVS_PER_HYBRID_G-1 downto 0 loop
         axiSlaveRegisterR(axilEp, X"60"+toSlv(i*8, 8), 0, r.pulseStream(index(i)));
      end loop;

      for i in APVS_PER_HYBRID_G-1 downto 0 loop
         axiSlaveRegisterR(axilEp, X"90"+toSlv(i*4, 8), 0, lostSyncCount(index(i)));
      end loop;

      for i in APVS_PER_HYBRID_G-1 downto 0 loop
         axiSlaveRegisterR(axilEp, X"B0"+toSlv(i*4, 8), 0, minSamples(index(i)));
         axiSlaveRegisterR(axilEp, X"B0"+toSlv(i*4, 8), 16, maxSamples(index(i)));
      end loop;

      v.countReset := '0';
      axiSlaveRegister(axilEp, X"D0", 0, v.countReset);

      axiSlaveDefault(axilEp, v.axiWriteSlave, v.axiReadSlave, AXI_RESP_DECERR_C);

      ----------------------------------------------------------------------------------------------
      -- Resets and outputs
      ----------------------------------------------------------------------------------------------
      if (sysRst = '1') then
         v := REG_INIT_C;
      end if;

      rin <= v;

      axiReadSlave  <= r.axiReadSlave;
      axiWriteSlave <= r.axiWriteSlave;
      countReset    <= r.countReset;

   end process comb;

   seq : process (sysClk) is
   begin
      if (rising_edge(sysClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;


end rtl;


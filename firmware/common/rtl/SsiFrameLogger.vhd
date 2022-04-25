-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : SsiFrameLogger.vhd
-- Author     : 
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2014-05-02
-- Last update: 2019-11-20
-- Platform   : Vivado 2013.3
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------
-- Copyright (c) 2014 SLAC National Accelerator Laboratory
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

entity SsiFrameLogger is
   generic (
      -- General Configurations
      TPD_G            : time                    := 1 ns;
      MEMORY_TYPE_G    : string                  := "block";
      RAM_ADDR_WIDTH_G : integer range 1 to 2*24 := 10;
      -- AXI Stream Port Configurations
      AXIS_CONFIG_G    : AxiStreamConfigType);
   port (
      -- Axi Lite interface for readoutout
      axilClk        : in  sl;
      axilRst        : in  sl;
      axiReadMaster  : in  AxiLiteReadMasterType  := AXI_LITE_READ_MASTER_INIT_C;
      axiReadSlave   : out AxiLiteReadSlaveType;
      axiWriteMaster : in  AxiLiteWriteMasterType := AXI_LITE_WRITE_MASTER_INIT_C;
      axiWriteSlave  : out AxiLiteWriteSlaveType;

      -- AxisStream interface to log
      axisClk     : in sl;
      axisRst     : in sl;
      sAxisMaster : in AxiStreamMasterType;
      sAxisSlave  : in AxiStreamSlaveType;
      sAxisCtrl   : in AxiStreamCtrlType);
end SsiFrameLogger;

architecture rtl of SsiFrameLogger is

   -------------------------------------------------------------------------------------------------
   -- Stream clock domain signals
   -------------------------------------------------------------------------------------------------
   type AxisRegType is record
      ramWrAddr  : slv(RAM_ADDR_WIDTH_G-1 downto 0);
      ramWrData  : slv(31 downto 0);
      ramWrEn    : sl;
      frameCount : slv(31 downto 0);
   end record;

   constant AXIS_REG_INIT_C : AxisRegType := (
      ramWrAddr  => (others => '0'),
      ramWrData  => (others => '0'),
      ramWrEn    => '0',
      frameCount => (others => '0'));

   signal axisR   : AxisRegType := AXIS_REG_INIT_C;
   signal axisRin : AxisRegType;

   signal axisLogEn : sl;
   signal ssiMaster : SsiMasterType;
   signal ssiSlave  : SsiSlaveType;

   -------------------------------------------------------------------------------------------------
   -- AXI-Lite clock domain signals
   -------------------------------------------------------------------------------------------------
   type AxilRegType is record
      logEn     : sl;
      ramRdAddr : slv(RAM_ADDR_WIDTH_G-1 downto 0);

      axiReadSlave  : AxiLiteReadSlaveType;
      axiWriteSlave : AxiLiteWriteSlaveType;
   end record;

   constant AXIL_REG_INIT_C : AxilRegType := (
      logEn     => '1',
      ramRdAddr => (others => '0'),

      axiReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axiWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C);

   signal axilR   : AxilRegType := AXIL_REG_INIT_C;
   signal axilRin : AxilRegType;

   signal axilRamRdData  : slv(31 downto 0);
   signal axilRamWrAddr  : slv(RAM_ADDR_WIDTH_G-1 downto 0);
   signal axilFrameCount : slv(31 downto 0);

begin

   -------------------------------------------------------------------------------------------------
   -- Instantiate the ram
   -------------------------------------------------------------------------------------------------
   DualPortRam_1 : entity surf.DualPortRam
      generic map (
         TPD_G         => TPD_G,
         MEMORY_TYPE_G => "block",
         REG_EN_G      => false,
         MODE_G        => "read-first",
         DATA_WIDTH_G  => 32,
         ADDR_WIDTH_G  => RAM_ADDR_WIDTH_G)
      port map (
         clka  => axisClk,
         wea   => axisR.ramWrEn,
         rsta  => axisRst,
         addra => axisR.ramWrAddr,
         dina  => axisR.ramWrData,
         douta => open,
         clkb  => axilClk,
         rstb  => axilRst,
         addrb => axilR.ramRdAddr,
         doutb => axilRamRdData);

   -------------------------------------------------------------------------------------------------
   -- Convert AXI-Stream records to SSI
   -------------------------------------------------------------------------------------------------
   ssiMaster <= axis2SsiMaster(AXIS_CONFIG_G, sAxisMaster);
   ssiSlave  <= axis2SsiSlave(AXIS_CONFIG_G, sAxisSlave, sAxisCtrl);

   -------------------------------------------------------------------------------------------------
   -- Synchronize logEn to axisClk
   -------------------------------------------------------------------------------------------------
   Synchronizer_logEn : entity surf.Synchronizer
      generic map (
         TPD_G => TPD_G)
      port map (
         clk     => axisClk,
         rst     => axisRst,
         dataIn  => axilR.logEn,
         dataOut => axisLogEn);

   -------------------------------------------------------------------------------------------------
   -- Main AXI-Stream process
   -------------------------------------------------------------------------------------------------
   axisComb : process (axisLogEn, axisR, axisRst, ssiMaster, ssiSlave) is
      variable v : AxisRegType;
   begin
      -- Latch the current value
      v := axisR;

      v.ramWrEn := '0';
      if (ssiMaster.valid = '1' and ssiSlave.ready = '1' and axisLogEn = '1') then

         if (ssiMaster.sof = '1') then
            v.ramWrAddr               := axisR.ramWrAddr + 1;
            v.ramWrEn                 := '1';
            v.ramWrData               := (others => '0');  -- reset the data
            v.ramWrData(31)           := '1';              -- SOF bit
            v.ramWrData(28 downto 16) := toSlv(1, 13);     -- Reset txn count
            v.ramWrData(15 downto 0)  := ssiMaster.data(15 downto 0);
            v.frameCount              := axisR.frameCount + 1;
         elsif (ssiMaster.eof = '1') then
            v.ramWrEn                 := '1';
            v.ramWrData(30)           := '1';
            v.ramWrData(29)           := ssiMaster.eofe;
            v.ramWrData(28 downto 16) := axisR.ramWrData(28 downto 16) + 1;
         else
            v.ramWrData(28 downto 16) := axisR.ramWrData(28 downto 16) + 1;
         end if;
      end if;


      -- Synchronous Reset
      if (axisRst = '1') then
         v := AXIS_REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      axisRin <= v;

      -- Outputs

   end process;

   axisSeq : process (axisClk) is
   begin
      if rising_edge(axisClk) then
         axisR <= axisRin after TPD_G;
      end if;
   end process;

   -------------------------------------------------------------------------------------------------
   -- Synchronize write address across to axilite clock
   -------------------------------------------------------------------------------------------------
   SynchronizerFifo_1 : entity surf.SynchronizerFifo
      generic map (
         TPD_G        => TPD_G,
         DATA_WIDTH_G => RAM_ADDR_WIDTH_G)
      port map (
         rst    => axilRst,
         wr_clk => axisClk,
         din    => axisR.ramWrAddr,
         rd_clk => axilClk,
         dout   => axilRamWrAddr);

   SynchronizerFifo_2 : entity surf.SynchronizerFifo
      generic map (
         TPD_G        => TPD_G,
         DATA_WIDTH_G => 32)
      port map (
         rst    => axilRst,
         wr_clk => axisClk,
         din    => axisR.frameCount,
         rd_clk => axilClk,
         dout   => axilFrameCount);

   axiComb : process (axiReadMaster, axiWriteMaster, axilFrameCount, axilR, axilRamRdData,
                      axilRamWrAddr, axilRst) is
      variable v         : AxilRegType;
      variable axiStatus : AxiLiteStatusType;

      -- Wrapper procedures to make calls cleaner.
      procedure axiSlaveRegisterW (addr : in slv; offset : in integer; reg : inout slv) is
      begin
         axiSlaveRegister(axiWriteMaster, axiReadMaster, v.axiWriteSlave, v.axiReadSlave, axiStatus, addr, offset, reg);
      end procedure;

      procedure axiSlaveRegisterR (addr : in slv; offset : in integer; reg : in slv) is
      begin
         axiSlaveRegister(axiReadMaster, v.axiReadSlave, axiStatus, addr, offset, reg);
      end procedure;

      procedure axiSlaveRegisterW (addr : in slv; offset : in integer; reg : inout sl) is
      begin
         axiSlaveRegister(axiWriteMaster, axiReadMaster, v.axiWriteSlave, v.axiReadSlave, axiStatus, addr, offset, reg);
      end procedure;

      procedure axiSlaveRegisterR (addr : in slv; offset : in integer; reg : in sl) is
      begin
         axiSlaveRegister(axiReadMaster, v.axiReadSlave, axiStatus, addr, offset, reg);
      end procedure;

      procedure axiSlaveDefault (
         axiResp : in slv(1 downto 0)) is
      begin
         axiSlaveDefault(axiWriteMaster, axiReadMaster, v.axiWriteSlave, v.axiReadSlave, axiStatus, axiResp);
      end procedure;
   begin
      -- Latch the current value
      v := axilR;

      axiSlaveWaitTxn(axiWriteMaster, axiReadMaster, v.axiWriteSlave, v.axiReadSlave, axiStatus);

      axiSlaveRegisterW(X"00", 0, v.logEn);
      axiSlaveRegisterR(X"08", 0, axilRamRdData);
      axiSlaveRegisterR(X"0C", 0, axilFrameCount);
      axiSlaveDefault(AXI_RESP_OK_C);

      if (axiStatus.writeEnable = '1' and axiWriteMaster.awaddr(7 downto 0) = X"04") then
         v.ramRdAddr := axilRamWrAddr;
      end if;

      if (axiStatus.readEnable = '1' and axiReadMaster.araddr(7 downto 0) = X"08") then
         v.ramRdAddr := axilR.ramRdAddr - 1;
      end if;

      -- Synchronous Reset
      if (axilRst = '1') then
         v := AXIL_REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      axilRin <= v;

      -- Outputs
      axiReadSlave  <= axilR.axiReadSlave;
      axiWriteSlave <= axilR.axiWriteSlave;

   end process;

   axiSeq : process (axilClk) is
   begin
      if rising_edge(axilClk) then
         axilR <= axilRin after TPD_G;
      end if;
   end process;
end rtl;

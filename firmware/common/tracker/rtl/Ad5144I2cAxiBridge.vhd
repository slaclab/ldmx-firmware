-------------------------------------------------------------------------------
-- Title      : Ad5144SpiAxiBridge
-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: An abstraction layer and AXI-SPI bridge for comminication with
-- an AD5144 digital potentiometer.
-------------------------------------------------------------------------------
-- This file is part of HPS. It is subject to
-- the license terms in the LICENSE.txt file found in the top-level directory
-- of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of HPS, including this file, may be
-- copied, modified, propagated, or distributed except according to the terms
-- contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;


library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.I2cPkg.all;

entity Ad5144I2cAxiBridge is

   generic (
      TPD_G      : time            := 1 ns;
      I2C_ADDR_G : slv(6 downto 0) := "0100000");
   port (
      axiClk : in sl;
      axiRst : in sl;

      axiReadMaster  : in  AxiLiteReadMasterType;
      axiReadSlave   : out AxiLiteReadSlaveType;
      axiWriteMaster : in  AxiLiteWriteMasterType;
      axiWriteSlave  : out AxiLiteWriteSlaveType;

      i2cRegMasterIn  : out I2cRegMasterInType;
      i2cRegMasterOut : in  I2cRegMasterOutType);

end entity Ad5144I2cAxiBridge;

architecture rtl of Ad5144I2cAxiBridge is

   constant I2C_CONFIG_C : I2cAxiLiteDevType := MakeI2cAxiLiteDevType(
      i2cAddress  => I2C_ADDR_G,
      dataSize    => 8,
      addrSize    => 8,
      endianness  => '1',
      repeatStart => '1');

   constant CMD_NOP_C        : slv(3 downto 0) := "0000";
   constant CMD_WR_RDAC_C    : slv(3 downto 0) := "0001";
   constant CMD_WR_INP_C     : slv(3 downto 0) := "0010";
   constant CMD_RDBACK_C     : slv(3 downto 0) := "0011";
   constant CMD_LRDAC_C      : slv(3 downto 0) := "0110";
   constant CMD_CPY_C        : slv(3 downto 0) := "0111";
   constant CMD_WR_EEPROM_C  : slv(3 downto 0) := "1000";
   constant CMD_SOFT_RESET_C : slv(3 downto 0) := "1011";
   constant CMD_WR_CTRLREG_C : slv(3 downto 0) := "1101";

   constant RDBACK_SRC_INP_C     : slv(1 downto 0) := "00";
   constant RDBACK_SRC_EEPROM_C  : slv(1 downto 0) := "01";
   constant RDBACK_SRC_CTRLREG_C : slv(1 downto 0) := "10";
   constant RDBACK_SRC_RDAC_C    : slv(1 downto 0) := "11";

   type RegType is record
      axiWriteSlave : AxiLiteWriteSlaveType;
      axiReadSlave  : AxiLiteReadSlaveType;
      regIn         : I2cRegMasterInType;
   end record RegType;

   constant REG_INIT_C : RegType := (
      axiWriteSlave  => AXI_LITE_WRITE_SLAVE_INIT_C,
      axiReadSlave   => AXI_LITE_READ_SLAVE_INIT_C,
      regIn          => (
         i2cAddr     => I2C_CONFIG_C.i2cAddress,
         tenbit      => '0',
         regAddr     => (others => '0'),
         regWrData   => (others => '0'),
         regOp       => '0',
         regAddrSkip => '0',
         regAddrSize => "00",
         regDataSize => "00",
         regReq      => '0',
         busReq      => '0',
         endianness  => '1',
         repeatStart => '1',
         wrDataOnRd  => '1'));


   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

begin

   comb : process (axiReadMaster, axiRst, axiWriteMaster, i2cRegMasterOut, r) is
      variable v         : RegType;
      variable axiStatus : AxiLiteStatusType;
      variable axiResp   : slv(1 downto 0);      
   begin
      v := r;

      axiSlaveWaitTxn(axiWriteMaster, axiReadMaster, v.axiWriteSlave, v.axiReadSlave, axiStatus);

      if (axiStatus.writeEnable = '1') then
         v.regIn.regReq := '1';
         v.regIn.regOp  := '1';

         -- Decode Register, POT number is bits 3:2
         case (axiWriteMaster.awaddr(6 downto 4)) is

            when "000" =>               -- RDAC ACCESS
               v.regIn.regAddr(7 downto 4)   := CMD_WR_RDAC_C;
               v.regIn.regAddr(3 downto 0)   := "00" & axiWriteMaster.awaddr(3 downto 2);
               v.regIn.regWrData(7 downto 0) := axiWriteMaster.wdata(7 downto 0);

            when "001" =>               -- EEPROM Access
               v.regIn.regAddr(7 downto 4)   := CMD_WR_EEPROM_C;
               v.regIn.regAddr(3 downto 0)   := "00" & axiWriteMaster.awaddr(3 downto 2);
               v.regIn.regWrData(7 downto 0) := axiWriteMaster.wdata(7 downto 0);

            when "010" =>               -- INPUT Access
               v.regIn.regAddr(7 downto 4)   := CMD_WR_INP_C;
               v.regIn.regAddr(3 downto 0)   := "00" & axiWriteMaster.awaddr(3 downto 2);
               v.regIn.regWrData(7 downto 0) := axiWriteMaster.wdata(7 downto 0);

            when "011" =>               -- Copy Access
               v.regIn.regAddr(7 downto 4) := CMD_CPY_C;
               v.regIn.regAddr(3 downto 0) := "00" & axiWriteMaster.awaddr(3 downto 2);
               v.regIn.regWrData(0)        := axiWriteMaster.wdata(0);  -- 0 = RDAC->EEPROM, 1 = EEPROM->RDAC

            when "100" =>               -- LRDAC Access
               v.regIn.regAddr(7 downto 4) := CMD_LRDAC_C;
               v.regIn.regAddr(3 downto 0) := axiWriteMaster.wdata(3 downto 0);

            when "101" =>               -- CTRLREG
               v.regIn.regAddr(7 downto 4)   := CMD_WR_CTRLREG_C;
               v.regIn.regWrData(3 downto 0) := axiWriteMaster.wdata(3 downto 0);

            when "110" =>               -- Software reset
               v.regIn.regAddr(7 downto 4) := CMD_SOFT_RESET_C;

            when others =>
               v.regIn.regAddr(7 downto 4) := CMD_NOP_C;
         end case;

      -- READ
      elsif (axiStatus.readEnable = '1') then
         v.regIn.regReq := '1';
         v.regIn.regOp  := '0';

         v.regIn.regAddr(7 downto 4)   := CMD_RDBACK_C;
         v.regIn.regAddr(3 downto 0)   := "00" & axiReadMaster.araddr(3 downto 2);
         v.regIn.regWrData(7 downto 0) := (others => '0');

         case (axiReadMaster.araddr(6 downto 4)) is
            when "000" =>               -- RDAC ACCESS
               v.regIn.regWrData(1 downto 0) := "11";
            when "001" =>               -- EEPROM ACCESS
               v.regIn.regWrData(1 downto 0) := "01";
            when "010" =>               -- INPUT ACCESS
               v.regIn.regWrData(1 downto 0) := "00";
            when "101" =>               -- CTRLREG
               v.regIn.regWrData(1 downto 0) := "10";
            when others =>
               -- Could just return zero right away if reading unreadable register
               -- But this makes the state machine a bit simpler
               v.regIn.regAddr(7 downto 4)   := CMD_NOP_C;
               v.regIn.regWrData(7 downto 0) := (others => '0');
         end case;
      end if;

      if (i2cRegMasterOut.regAck = '1' and r.regIn.regReq = '1') then
         v.regIn.regReq := '0';
         axiResp        := ite(i2cRegMasterOut.regFail = '1', AXI_RESP_SLVERR_C, AXI_RESP_OK_C);
         if (r.regIn.regOp = '1') then
            axiSlaveWriteResponse(v.axiWriteSlave, axiResp);
         else
            v.axiReadSlave.rdata := i2cRegMasterOut.regRdData;
            if (i2cRegMasterOut.regFail = '1') then
               v.axiReadSlave.rdata := X"000000" & i2cRegMasterOut.regFailCode;
            end if;
            axiSlaveReadResponse(v.axiReadSlave, axiResp);
         end if;
      end if;


      if (axiRst = '1') then
         v := REG_INIT_C;
      end if;

      rin <= v;

      i2cRegMasterIn <= r.regIn;

      axiWriteSlave <= r.axiWriteSlave;
      axiReadSlave  <= r.axiReadSlave;

   end process comb;

   seq : process (axiClk) is
   begin
      if (rising_edge(axiClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;


end architecture rtl;

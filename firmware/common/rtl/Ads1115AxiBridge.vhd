-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : Ads1115AxiBridge.vhd
-- Author     : Benjamin Reese  <bareese@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Maps the I2C registers of the ADS1115 ADC chip onto the AXI bus
-- Technically, the chip only has 4 registers, which are mapped into the AXI
-- space as follows:
-- Conversion - 0x00,
-- Config     - 0x04,
-- Lo_thresh  - 0x08
-- Hi_thresh  - 0x0C
--
-- The various constituents of the Config register are also separately mapped,
-- so that they can be changed individually without first having to manually
-- querry the other contents of the register. These are mapped as follows:
-- MUX[2:0]      - 0x10
-- PGA[2:0]      - 0x14
-- MODE          - 0x18
-- DR[2:0]       - 0x1C
-- COMP_MODE     - 0x20
-- COMP_POL      - 0x24
-- COMP_LAT      - 0x28
-- COMP_QUE[1:0] - 0x2C
--
-- Finally, four registers are mapped that, when read, cause a specific mux
-- value to be written, a conversion performed, and the conversion result
-- returned. These only work when running in low power mode.
-- AIN0 - 0x30 - temp
-- AIN1 - 0x34 - dvdd
-- AIN2 - 0x38 - v1_25v
-- AIN3 - 0x3C - avdd
--
-- AXI INFO
-- Address bits - 8
-------------------------------------------------------------------------------
-- Copyright (c) 2013 SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.I2cPkg.all;

entity Ads1115AxiBridge is

   generic (
      TPD_G : time := 1 ns;

      I2C_DEV_ADDR_C : slv(6 downto 0) := "1001000");

   port (
      axiClk : in sl;
      axiRst : in sl;

      axiReadMaster  : in  AxiLiteReadMasterType;
      axiReadSlave   : out AxiLiteReadSlaveType;
      axiWriteMaster : in  AxiLiteWriteMasterType;
      axiWriteSlave  : out AxiLiteWriteSlaveType;

      i2cRegMasterIn  : out I2cRegMasterInType;
      i2cRegMasterOut : in  I2cRegMasterOutType);

end entity Ads1115AxiBridge;

architecture rtl of Ads1115AxiBridge is

   type StateType is (WAIT_AXI_TXN_S, WRITE_I2C_CONFIG_REG_S, WRITE_I2C_REG_S, READ_I2C_WAIT_S, READ_I2C_REG_S);

   type RegType is record
      state    : StateType;
      os       : sl;
      mux      : slv(2 downto 0);
      pga      : slv(2 downto 0);
      mode     : sl;
      dr       : slv(2 downto 0);
      compMode : sl;
      compPol  : sl;
      compLat  : sl;
      compQue  : slv(1 downto 0);

      axiReadSlave   : AxiLiteReadSlaveType;
      axiWriteSlave  : AxiLiteWriteSlaveType;
      i2cRegMasterIn : I2cRegMasterInType;
   end record RegType;

   constant REG_INIT_C : RegType := (
      state          => WAIT_AXI_TXN_S,
      os             => '0',
      mux            => (others => '0'),
      pga            => (others => '0'),
      mode           => '0',
      dr             => (others => '0'),
      compMode       => '0',
      compPol        => '0',
      compLat        => '0',
      compQue        => (others => '0'),
      axiReadSlave   => AXI_LITE_READ_SLAVE_INIT_C,
      axiWriteSlave  => AXI_LITE_WRITE_SLAVE_INIT_C,
      i2cRegMasterIn => I2C_REG_MASTER_IN_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

begin

   -------------------------------------------------------------------------------------------------
   -- Main Comb Process
   -------------------------------------------------------------------------------------------------
   comb : process (axiRst, axiReadMaster, axiWriteMaster, i2cRegMasterOut, r) is
      variable v         : RegType;
      variable axiStatus : AxiLiteStatusType;
      variable axiResp   : slv(1 downto 0);
   begin
      v := r;

      -- These never change, will optimize to constants
      v.i2cRegMasterIn.i2cAddr     := "000" & I2C_DEV_ADDR_C;
      v.i2cRegMasterIn.tenbit      := '0';
      v.i2cRegMasterIn.regAddrSize := "00";
      v.i2cRegMasterIn.regDataSize := "01";
      v.i2cRegMasterIn.endianness  := '1';  -- Big endian

      axiSlaveWaitTxn(axiWriteMaster, axiReadMaster, v.axiWriteSlave, v.axiReadSlave, axiStatus);

      case (r.state) is
         when WAIT_AXI_TXN_S =>

            if (axiStatus.writeEnable = '1') then

               -- Normal register write, pass through to I2C
               case (axiWriteMaster.awaddr(7 downto 4)) is
                  when X"0" =>          -- Direct chip register access
                     v.i2cRegMasterIn.regAddr                := (others => '0');
                     v.i2cRegMasterIn.regAddr(1 downto 0)    := axiWriteMaster.awaddr(3 downto 2);
                     v.i2cRegMasterIn.regWrData              := (others => '0');
                     v.i2cRegMasterIn.regWrData(15 downto 0) := axiWriteMaster.wdata(15 downto 0);

                     if (axiWriteMaster.awaddr(3 downto 0) = X"4") then
                        -- If writing to config register, save the constituent values locally
                        v.os       := '0';
                        v.mux      := axiWriteMaster.wdata(14 downto 12);
                        v.pga      := axiWriteMaster.wdata(11 downto 9);
                        v.mode     := axiWriteMaster.wdata(8);
                        v.dr       := axiWriteMaster.wdata(7 downto 5);
                        v.compMode := axiWriteMaster.wdata(4);
                        v.compPol  := axiWriteMaster.wdata(3);
                        v.compLat  := axiWriteMaster.wdata(2);
                        v.compQue  := axiWriteMaster.wdata(1 downto 0);
                     end if;
                     v.state := WRITE_I2C_REG_S;

                  -- Simplified Config Registers
                  -- Decode config constituent, then write to the I2C Config reg
                  when X"1" =>
                     v.os := '0';
                     case (axiWriteMaster.awaddr(3 downto 0)) is
                        when X"0" =>
                           v.mux := axiWriteMaster.wdata(2 downto 0);
                        when X"4" =>
                           v.pga := axiWriteMaster.wdata(2 downto 0);
                        when X"8" =>
                           v.mode := axiWriteMaster.wdata(0);
                        when X"C" =>
                           v.dr := axiWriteMaster.wdata(2 downto 0);
                        when others => null;
                     end case;
                     v.state := WRITE_I2C_CONFIG_REG_S;
                  when X"2" =>
                     case (axiWriteMaster.awaddr(3 downto 0)) is
                        when X"0" =>
                           v.compMode := axiWriteMaster.wdata(0);
                        when X"4" =>
                           v.compPol := axiWriteMaster.wdata(0);
                        when X"8" =>
                           v.compLat := axiWriteMaster.wdata(0);
                        when X"C" =>
                           v.compQue := axiWriteMaster.wdata(1 downto 0);
                        when others => null;
                     end case;
                     v.state := WRITE_I2C_CONFIG_REG_S;

                  when others =>
                     axiSlaveWriteResponse(v.axiWriteSlave);

               end case;

            elsif (axiStatus.readEnable = '1') then

               -- Normal Register Read
               case (axiReadMaster.araddr(7 downto 4)) is
                  when X"0" =>

                     v.i2cRegMasterIn.regAddr             := (others => '0');
                     v.i2cRegMasterIn.regAddr(1 downto 0) := axiReadMaster.araddr(3 downto 2);
                     v.os                                 := '0';
                     v.state                              := READ_I2C_WAIT_S;

                  -- Config constituent register read
                  when X"1" =>
                     v.axiReadSlave.rdata := (others => '0');
                     case (axiReadMaster.araddr(3 downto 0)) is
                        when X"0" =>
                           v.axiReadSlave.rdata(2 downto 0) := r.mux;
                        when X"4" =>
                           v.axiReadSlave.rdata(2 downto 0) := r.pga;
                        when X"8" =>
                           v.axiReadSlave.rdata(0) := r.mode;
                        when X"C" =>
                           v.axiReadSlave.rdata(2 downto 0) := r.dr;
                        when others => null;
                     end case;
                     axiSlaveReadResponse(v.axiReadSlave);
                  when X"2" =>
                     v.axiReadSlave.rdata := (others => '0');
                     case (axiReadMaster.araddr(3 downto 0)) is
                        when X"0" =>
                           v.axiReadSlave.rdata(0) := r.compMode;
                        when X"4" =>
                           v.axiReadSlave.rdata(0) := r.compPol;
                        when X"8" =>
                           v.axiReadSlave.rdata(0) := r.compLat;
                        when X"C" =>
                           v.axiReadSlave.rdata(1 downto 0) := r.compQue;
                        when others => null;
                     end case;
                     axiSlaveReadResponse(v.axiReadSlave);

                  -- Special mapped conversion registers
                  when X"3" =>
                     v.mode  := '1';    -- Must be on single shot mode or will hang bus
                     v.mux   := '1' & axiReadMaster.araddr(3 downto 2);
                     v.os    := '1';
                     v.state := WRITE_I2C_CONFIG_REG_S;

                  when others =>
                     v.axiReadSlave.rdata := (others => '0');
                     axiSlaveReadResponse(v.axiReadSlave);

               end case;
            end if;

         when WRITE_I2C_CONFIG_REG_S =>
            v.i2cRegMasterIn.regAddr                 := X"00000001";  -- Config Register
            v.i2cRegMasterIn.regWrData(15)           := r.os;
            v.i2cRegMasterIn.regWrData(14 downto 12) := r.mux;
            v.i2cRegMasterIn.regWrData(11 downto 9)  := r.pga;
            v.i2cRegMasterIn.regWrData(8)            := r.mode;
            v.i2cRegMasterIn.regWrData(7 downto 5)   := r.dr;
            v.i2cRegMasterIn.regWrData(4)            := r.compMode;
            v.i2cRegMasterIn.regWrData(3)            := r.compPol;
            v.i2cRegMasterIn.regWrData(2)            := r.compLat;
            v.i2cRegMasterIn.regWrData(1 downto 0)   := r.compQue;

            v.state := WRITE_I2C_REG_S;

         when WRITE_I2C_REG_S =>
            -- Address and data should be set up before reaching this state
            v.i2cRegMasterIn.regOp  := '1';  -- Write
            v.i2cRegMasterIn.regReq := '1';

            if (i2cRegMasterOut.regAck = '1') then
               v.i2cRegMasterIn.regReq := '0';
               axiResp                 := ite(i2cRegMasterOut.regFail = '1', AXI_RESP_SLVERR_C, AXI_RESP_OK_C);

               if (i2cRegMasterOut.regFail = '1') then
                  -- If write failed end the AXI Txn
                  v.state := WAIT_AXI_TXN_S;
                  v.os    := '0';
                  if (r.os = '0') then
                     axiSlaveWriteResponse(v.axiWriteSlave, axiResp);
                  else
                     -- os bit indicates an axi read of special reg was being attempted
                     axiSlaveReadResponse(v.axiReadSlave, axiResp);
                  end if;
               elsif (r.os = '0') then
                  -- Normal write case, end the txn
                  axiSlaveWriteResponse(v.axiWriteSlave, axiResp);
                  v.state := WAIT_AXI_TXN_S;
               else
                  -- Special read case
                  v.i2cRegMasterIn.regAddr := X"00000001";
                  v.state                  := READ_I2C_WAIT_S;
               end if;
            end if;

         when READ_I2C_WAIT_S =>
            -- Wait until previous txn (if any) is done before starting another read
            if (i2cRegMasterOut.regAck = '0' and r.i2cRegMasterIn.regReq = '0') then
               v.state := READ_I2C_REG_S;
            end if;

         when READ_I2C_REG_S =>
            -- Address should be set up before reaching this state
            -- Assert Read
            v.i2cRegMasterIn.regOp  := '0';  -- Read
            v.i2cRegMasterIn.regReq := '1';

            -- Wait for resp
            if (i2cRegMasterOut.regAck = '1') then
               v.i2cRegMasterIn.regReq := '0';
               axiResp                 := ite(i2cRegMasterOut.regFail = '1', AXI_RESP_SLVERR_C, AXI_RESP_OK_C);

               if (i2cRegMasterOut.regFail = '1' or r.os = '0') then
                  v.axiReadSlave.rdata := i2cRegMasterOut.regRdData;
                  axiSlaveReadResponse(v.axiReadSlave, axiResp);
                  v.state              := WAIT_AXI_TXN_S;
                  v.os                 := '0';
               else
                  -- Performing special read, poll until OS bit is high, then read conversion reg
                  v.state := READ_I2C_WAIT_S;
                  if (i2cRegMasterOut.regRdData(15) = '1') then
                     v.os                     := '0';
                     v.i2cRegMasterIn.regAddr := X"00000000";
                  end if;
               end if;
            end if;


      end case;

      ----------------------------------------------------------------------------------------------
      -- Reset
      ----------------------------------------------------------------------------------------------
      if (axiRst = '1') then
         v := REG_INIT_C;
      end if;

      rin <= v;

      axiReadSlave   <= r.axiReadSlave;
      axiWriteSlave  <= r.axiWriteSlave;
      i2cRegMasterIn <= r.i2cRegMasterIn;

   end process comb;

-------------------------------------------------------------------------------------------------
-- Sequential Process
-------------------------------------------------------------------------------------------------
   seq : process (axiClk) is
   begin
      if (rising_edge(axiClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end architecture rtl;

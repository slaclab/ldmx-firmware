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

entity Ad5144SpiAxiBridge is
   
   generic (
      TPD_G             : time                  := 1 ns;
      NUM_CHIPS_G       : positive range 1 to 8 := 4;
      AXI_CLK_PERIOD_G  : real                  := 8.0E-9;
      SPI_SCLK_PERIOD_G : real                  := 1.0E-6);

   port (
      axiClk : in sl;
      axiRst : in sl;

      axiReadMaster  : in  AxiLiteReadMasterType;
      axiReadSlave   : out AxiLiteReadSlaveType;
      axiWriteMaster : in  AxiLiteWriteMasterType;
      axiWriteSlave  : out AxiLiteWriteSlaveType;

      spiCsL  : out slv(NUM_CHIPS_G-1 downto 0);
      spiSclk : out sl;
      spiSdi  : out sl;
      spiSdo  : in  sl);

end entity Ad5144SpiAxiBridge;

architecture rtl of Ad5144SpiAxiBridge is

   constant DATA_SIZE_C : natural := 16;


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

   type StateType is (WAIT_AXI_TXN_S, WRITE_SPI_S, READ_SPI_S);

   type RegType is record
      axiWriteSlave : AxiLiteWriteSlaveType;
      axiReadSlave  : AxiLiteReadSlaveType;
      state         : StateType;
      hold          : sl;
      wrTxn         : sl;
      wrEn          : sl;
      chipSel       : slv(log2(NUM_CHIPS_G)-1 downto 0);
      wrData        : slv(15 downto 0);
   end record RegType;

   constant REG_INIT_C : RegType := (
      axiWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C,
      axiReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      state         => WAIT_AXI_TXN_S,
      hold          => '0',
      wrTxn         => '0',
      wrEn          => '0',
      chipSel       => (others => '0'),
      wrData        => (others => '0'));

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal rdEn   : sl;
   signal rdData : slv(15 downto 0);

begin

   comb : process (axiRst, axiReadMaster, axiWriteMaster, r, rdData, rdEn) is
      variable v         : RegType;
      variable axiStatus : AxiLiteStatusType;
   begin
      v := r;

      v.wrEn := '0';

      axiSlaveWaitTxn(axiWriteMaster, axiReadMaster, v.axiWriteSlave, v.axiReadSlave, axiStatus);

      case (r.state) is
         when WAIT_AXI_TXN_S =>
            v.hold := '0';
            if (axiStatus.writeEnable = '1') then
               -- Select chip by upper address bits
               v.chipSel := axiWriteMaster.awaddr(log2(NUM_CHIPS_G)-1+10 downto 10);
               v.wrTxn   := '1';
               v.wrEn    := '1';
               v.wrData  := (others => '0');
               v.state   := WRITE_SPI_S;

               -- Decode Register, POT number is bits 1:0
               case (axiWriteMaster.awaddr(6 downto 4)) is
                  
                  when "000" =>         -- RDAC ACCESS
                     v.wrData(15 downto 12) := CMD_WR_RDAC_C;
                     v.wrData(11 downto 8)  := "00" & axiWriteMaster.awaddr(3 downto 2);
                     v.wrData(7 downto 0)   := axiWriteMaster.wdata(7 downto 0);

                  when "001" =>         -- EEPROM Access
                     v.wrData(15 downto 12) := CMD_WR_EEPROM_C;
                     v.wrData(11 downto 8)  := "00" & axiWriteMaster.awaddr(3 downto 2);
                     v.wrData(7 downto 0)   := axiWriteMaster.wdata(7 downto 0);

                  when "010" =>         -- INPUT Access
                     v.wrData(15 downto 12) := CMD_WR_INP_C;
                     v.wrData(11 downto 8)  := "00" & axiWriteMaster.awaddr(3 downto 2);
                     v.wrData(7 downto 0)   := axiWriteMaster.wdata(7 downto 0);

                  when "011" =>         -- Copy Access
                     v.wrData(15 downto 12) := CMD_CPY_C;
                     v.wrData(11 downto 8)  := "00" & axiWriteMaster.awaddr(3 downto 2);
                     v.wrData(0)            := axiWriteMaster.wdata(0);  -- 0 = RDAC->EEPROM, 1 = EEPROM->RDAC

                  when "100" =>         -- LRDAC Access
                     v.wrData(15 downto 12) := CMD_LRDAC_C;
                     v.wrData(11 downto 8)  := axiWriteMaster.wdata(3 downto 0);

                  when "101" =>         -- CTRLREG
                     v.wrData(15 downto 12) := CMD_WR_CTRLREG_C;
                     v.wrData(3 downto 0)   := axiWriteMaster.wdata(3 downto 0);

                  when "110" =>         -- Software reset
                     v.wrData(15 downto 12) := CMD_SOFT_RESET_C;

                  when others =>
                     v.wrData(15 downto 12) := CMD_NOP_C;
               end case;

            -- READ
            elsif (axiStatus.readEnable = '1') then
               v.chipSel := axiReadMaster.araddr(log2(NUM_CHIPS_G)-1+10 downto 10);
               v.wrTxn   := '0';
               v.wrEn    := '1';
               v.state   := WRITE_SPI_S;

               v.wrData(15 downto 12) := CMD_RDBACK_C;
               v.wrData(11 downto 8)  := "00" & axiReadMaster.araddr(3 downto 2);
               v.wrData(7 downto 0)   := (others => '0');

               case (axiReadMaster.araddr(6 downto 4)) is
                  when "000" =>         -- RDAC ACCESS
                     v.wrData(1 downto 0) := "11";
                  when "001" =>         -- EEPROM ACCESS
                     v.wrData(1 downto 0) := "01";
                  when "010" =>         -- INPUT ACCESS
                     v.wrData(1 downto 0) := "00";
                  when "101" =>         -- CTRLREG
                     v.wrData(1 downto 0) := "10";
                  when others =>
                     -- Could just return zero right away if reading unreadable register
                     -- But this makes the state machine a bit simpler
                     v.wrData(15 downto 12) := CMD_NOP_C;
                     v.wrData(11 downto 0)  := (others => '0');
               end case;
            end if;

         when WRITE_SPI_S =>
            v.hold := '1';
            if (r.hold = '1' and rdEn = '1') then
               v.hold := '0';
               if (r.wrTxn = '1') then
                  axiSlaveWriteResponse(v.axiWriteSlave);
                  v.state := WAIT_AXI_TXN_S;
               else
                  -- Do a NOP write to read back the result
                  v.wrData(15 downto 12) := CMD_NOP_C;
                  v.wrEn                 := '1';
                  v.state                := READ_SPI_S;
               end if;
            end if;

         when READ_SPI_S =>
            v.hold := '1';
            if (r.hold = '1' and rdEn = '1') then
               v.axiReadSlave.rdata(7 downto 0) := rdData(7 downto 0);
               axiSlaveReadResponse(v.axiReadSlave);
               v.state                          := WAIT_AXI_TXN_S;
            end if;

      end case;

      if (axiRst = '1') then
         v := REG_INIT_C;
      end if;

      rin <= v;

      axiWriteSlave <= r.axiWriteSlave;
      axiReadSlave  <= r.axiReadSlave;
      
   end process comb;

   seq : process (axiClk) is
   begin
      if (rising_edge(axiClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

   SpiMaster_1 : entity surf.SpiMaster
      generic map (
         TPD_G             => TPD_G,
         NUM_CHIPS_G       => NUM_CHIPS_G,
         DATA_SIZE_G       => 16,
         CPHA_G            => '0',      -- Sample on leading edge
         CPOL_G            => '1',      -- Sample on falling edge
         CLK_PERIOD_G      => AXI_CLK_PERIOD_G,
         SPI_SCLK_PERIOD_G => SPI_SCLK_PERIOD_G)
      port map (
         clk     => axiClk,
         sRst    => axiRst,
         chipSel => r.chipSel,
         wrEn    => r.wrEn,
         wrData  => r.wrData,
         rdEn    => rdEn,
         rdData  => rdData,
         spiCsL  => spiCsL,
         spiSclk => spiSclk,
         spiSdi  => spiSdi,
         spiSdo  => spiSdo);

end architecture rtl;

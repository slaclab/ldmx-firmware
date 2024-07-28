-- ==============================================================
-- Vitis HLS - High-Level Synthesis from C, C++ and OpenCL v2022.2 (64-bit)
-- Version: 2022.2
-- Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
-- ==============================================================
library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;

entity ts_s30xl_pileupst_trigger_hw_nbins_s_ROM_AUTO_1R is 
    generic(
             DataWidth     : integer := 7; 
             AddressWidth     : integer := 3; 
             AddressRange    : integer := 5
    ); 
    port (
 
          address0        : in std_logic_vector(AddressWidth-1 downto 0); 
          ce0             : in std_logic; 
          q0              : out std_logic_vector(DataWidth-1 downto 0);
 
          address1        : in std_logic_vector(AddressWidth-1 downto 0); 
          ce1             : in std_logic; 
          q1              : out std_logic_vector(DataWidth-1 downto 0);
 
          address2        : in std_logic_vector(AddressWidth-1 downto 0); 
          ce2             : in std_logic; 
          q2              : out std_logic_vector(DataWidth-1 downto 0);
 
          address3        : in std_logic_vector(AddressWidth-1 downto 0); 
          ce3             : in std_logic; 
          q3              : out std_logic_vector(DataWidth-1 downto 0);
 
          address4        : in std_logic_vector(AddressWidth-1 downto 0); 
          ce4             : in std_logic; 
          q4              : out std_logic_vector(DataWidth-1 downto 0);
 
          address5        : in std_logic_vector(AddressWidth-1 downto 0); 
          ce5             : in std_logic; 
          q5              : out std_logic_vector(DataWidth-1 downto 0);
 
          address6        : in std_logic_vector(AddressWidth-1 downto 0); 
          ce6             : in std_logic; 
          q6              : out std_logic_vector(DataWidth-1 downto 0);
 
          address7        : in std_logic_vector(AddressWidth-1 downto 0); 
          ce7             : in std_logic; 
          q7              : out std_logic_vector(DataWidth-1 downto 0);
 
          address8        : in std_logic_vector(AddressWidth-1 downto 0); 
          ce8             : in std_logic; 
          q8              : out std_logic_vector(DataWidth-1 downto 0);
 
          address9        : in std_logic_vector(AddressWidth-1 downto 0); 
          ce9             : in std_logic; 
          q9              : out std_logic_vector(DataWidth-1 downto 0);
 
          address10        : in std_logic_vector(AddressWidth-1 downto 0); 
          ce10             : in std_logic; 
          q10              : out std_logic_vector(DataWidth-1 downto 0);
 
          address11        : in std_logic_vector(AddressWidth-1 downto 0); 
          ce11             : in std_logic; 
          q11              : out std_logic_vector(DataWidth-1 downto 0);
 
          address12        : in std_logic_vector(AddressWidth-1 downto 0); 
          ce12             : in std_logic; 
          q12              : out std_logic_vector(DataWidth-1 downto 0);
 
          address13        : in std_logic_vector(AddressWidth-1 downto 0); 
          ce13             : in std_logic; 
          q13              : out std_logic_vector(DataWidth-1 downto 0);
 
          address14        : in std_logic_vector(AddressWidth-1 downto 0); 
          ce14             : in std_logic; 
          q14              : out std_logic_vector(DataWidth-1 downto 0);
 
          address15        : in std_logic_vector(AddressWidth-1 downto 0); 
          ce15             : in std_logic; 
          q15              : out std_logic_vector(DataWidth-1 downto 0);
 
          address16        : in std_logic_vector(AddressWidth-1 downto 0); 
          ce16             : in std_logic; 
          q16              : out std_logic_vector(DataWidth-1 downto 0);
 
          address17        : in std_logic_vector(AddressWidth-1 downto 0); 
          ce17             : in std_logic; 
          q17              : out std_logic_vector(DataWidth-1 downto 0);
 
          address18        : in std_logic_vector(AddressWidth-1 downto 0); 
          ce18             : in std_logic; 
          q18              : out std_logic_vector(DataWidth-1 downto 0);
 
          address19        : in std_logic_vector(AddressWidth-1 downto 0); 
          ce19             : in std_logic; 
          q19              : out std_logic_vector(DataWidth-1 downto 0);
 
          address20        : in std_logic_vector(AddressWidth-1 downto 0); 
          ce20             : in std_logic; 
          q20              : out std_logic_vector(DataWidth-1 downto 0);
 
          address21        : in std_logic_vector(AddressWidth-1 downto 0); 
          ce21             : in std_logic; 
          q21              : out std_logic_vector(DataWidth-1 downto 0);
 
          address22        : in std_logic_vector(AddressWidth-1 downto 0); 
          ce22             : in std_logic; 
          q22              : out std_logic_vector(DataWidth-1 downto 0);
 
          address23        : in std_logic_vector(AddressWidth-1 downto 0); 
          ce23             : in std_logic; 
          q23              : out std_logic_vector(DataWidth-1 downto 0);

          reset               : in std_logic;
          clk                 : in std_logic
    ); 
end entity; 


architecture rtl of ts_s30xl_pileupst_trigger_hw_nbins_s_ROM_AUTO_1R is 
 
signal address0_tmp : std_logic_vector(AddressWidth-1 downto 0);  
signal address1_tmp : std_logic_vector(AddressWidth-1 downto 0);  
signal address2_tmp : std_logic_vector(AddressWidth-1 downto 0);  
signal address3_tmp : std_logic_vector(AddressWidth-1 downto 0);  
signal address4_tmp : std_logic_vector(AddressWidth-1 downto 0);  
signal address5_tmp : std_logic_vector(AddressWidth-1 downto 0);  
signal address6_tmp : std_logic_vector(AddressWidth-1 downto 0);  
signal address7_tmp : std_logic_vector(AddressWidth-1 downto 0);  
signal address8_tmp : std_logic_vector(AddressWidth-1 downto 0);  
signal address9_tmp : std_logic_vector(AddressWidth-1 downto 0);  
signal address10_tmp : std_logic_vector(AddressWidth-1 downto 0);  
signal address11_tmp : std_logic_vector(AddressWidth-1 downto 0);  
signal address12_tmp : std_logic_vector(AddressWidth-1 downto 0);  
signal address13_tmp : std_logic_vector(AddressWidth-1 downto 0);  
signal address14_tmp : std_logic_vector(AddressWidth-1 downto 0);  
signal address15_tmp : std_logic_vector(AddressWidth-1 downto 0);  
signal address16_tmp : std_logic_vector(AddressWidth-1 downto 0);  
signal address17_tmp : std_logic_vector(AddressWidth-1 downto 0);  
signal address18_tmp : std_logic_vector(AddressWidth-1 downto 0);  
signal address19_tmp : std_logic_vector(AddressWidth-1 downto 0);  
signal address20_tmp : std_logic_vector(AddressWidth-1 downto 0);  
signal address21_tmp : std_logic_vector(AddressWidth-1 downto 0);  
signal address22_tmp : std_logic_vector(AddressWidth-1 downto 0);  
signal address23_tmp : std_logic_vector(AddressWidth-1 downto 0); 

type mem_array is array (0 to AddressRange-1) of std_logic_vector (DataWidth-1 downto 0); 

signal mem0 : mem_array := (
    0 => "0000000", 1 => "0010000", 2 => "0100100", 3 => "0111001", 
    4 => "1000000");

signal mem1 : mem_array := (
    0 => "0000000", 1 => "0010000", 2 => "0100100", 3 => "0111001", 
    4 => "1000000");

signal mem2 : mem_array := (
    0 => "0000000", 1 => "0010000", 2 => "0100100", 3 => "0111001", 
    4 => "1000000");

signal mem3 : mem_array := (
    0 => "0000000", 1 => "0010000", 2 => "0100100", 3 => "0111001", 
    4 => "1000000");

signal mem4 : mem_array := (
    0 => "0000000", 1 => "0010000", 2 => "0100100", 3 => "0111001", 
    4 => "1000000");

signal mem5 : mem_array := (
    0 => "0000000", 1 => "0010000", 2 => "0100100", 3 => "0111001", 
    4 => "1000000");

signal mem6 : mem_array := (
    0 => "0000000", 1 => "0010000", 2 => "0100100", 3 => "0111001", 
    4 => "1000000");

signal mem7 : mem_array := (
    0 => "0000000", 1 => "0010000", 2 => "0100100", 3 => "0111001", 
    4 => "1000000");

signal mem8 : mem_array := (
    0 => "0000000", 1 => "0010000", 2 => "0100100", 3 => "0111001", 
    4 => "1000000");

signal mem9 : mem_array := (
    0 => "0000000", 1 => "0010000", 2 => "0100100", 3 => "0111001", 
    4 => "1000000");

signal mem10 : mem_array := (
    0 => "0000000", 1 => "0010000", 2 => "0100100", 3 => "0111001", 
    4 => "1000000");

signal mem11 : mem_array := (
    0 => "0000000", 1 => "0010000", 2 => "0100100", 3 => "0111001", 
    4 => "1000000");



begin 

 
memory_access_guard_0: process (address0) 
begin
      address0_tmp <= address0;
--synthesis translate_off
      if (CONV_INTEGER(address0) > AddressRange-1) then
           address0_tmp <= (others => '0');
      else 
           address0_tmp <= address0;
      end if;
--synthesis translate_on
end process;
 
memory_access_guard_1: process (address1) 
begin
      address1_tmp <= address1;
--synthesis translate_off
      if (CONV_INTEGER(address1) > AddressRange-1) then
           address1_tmp <= (others => '0');
      else 
           address1_tmp <= address1;
      end if;
--synthesis translate_on
end process;
 
memory_access_guard_2: process (address2) 
begin
      address2_tmp <= address2;
--synthesis translate_off
      if (CONV_INTEGER(address2) > AddressRange-1) then
           address2_tmp <= (others => '0');
      else 
           address2_tmp <= address2;
      end if;
--synthesis translate_on
end process;
 
memory_access_guard_3: process (address3) 
begin
      address3_tmp <= address3;
--synthesis translate_off
      if (CONV_INTEGER(address3) > AddressRange-1) then
           address3_tmp <= (others => '0');
      else 
           address3_tmp <= address3;
      end if;
--synthesis translate_on
end process;
 
memory_access_guard_4: process (address4) 
begin
      address4_tmp <= address4;
--synthesis translate_off
      if (CONV_INTEGER(address4) > AddressRange-1) then
           address4_tmp <= (others => '0');
      else 
           address4_tmp <= address4;
      end if;
--synthesis translate_on
end process;
 
memory_access_guard_5: process (address5) 
begin
      address5_tmp <= address5;
--synthesis translate_off
      if (CONV_INTEGER(address5) > AddressRange-1) then
           address5_tmp <= (others => '0');
      else 
           address5_tmp <= address5;
      end if;
--synthesis translate_on
end process;
 
memory_access_guard_6: process (address6) 
begin
      address6_tmp <= address6;
--synthesis translate_off
      if (CONV_INTEGER(address6) > AddressRange-1) then
           address6_tmp <= (others => '0');
      else 
           address6_tmp <= address6;
      end if;
--synthesis translate_on
end process;
 
memory_access_guard_7: process (address7) 
begin
      address7_tmp <= address7;
--synthesis translate_off
      if (CONV_INTEGER(address7) > AddressRange-1) then
           address7_tmp <= (others => '0');
      else 
           address7_tmp <= address7;
      end if;
--synthesis translate_on
end process;
 
memory_access_guard_8: process (address8) 
begin
      address8_tmp <= address8;
--synthesis translate_off
      if (CONV_INTEGER(address8) > AddressRange-1) then
           address8_tmp <= (others => '0');
      else 
           address8_tmp <= address8;
      end if;
--synthesis translate_on
end process;
 
memory_access_guard_9: process (address9) 
begin
      address9_tmp <= address9;
--synthesis translate_off
      if (CONV_INTEGER(address9) > AddressRange-1) then
           address9_tmp <= (others => '0');
      else 
           address9_tmp <= address9;
      end if;
--synthesis translate_on
end process;
 
memory_access_guard_10: process (address10) 
begin
      address10_tmp <= address10;
--synthesis translate_off
      if (CONV_INTEGER(address10) > AddressRange-1) then
           address10_tmp <= (others => '0');
      else 
           address10_tmp <= address10;
      end if;
--synthesis translate_on
end process;
 
memory_access_guard_11: process (address11) 
begin
      address11_tmp <= address11;
--synthesis translate_off
      if (CONV_INTEGER(address11) > AddressRange-1) then
           address11_tmp <= (others => '0');
      else 
           address11_tmp <= address11;
      end if;
--synthesis translate_on
end process;
 
memory_access_guard_12: process (address12) 
begin
      address12_tmp <= address12;
--synthesis translate_off
      if (CONV_INTEGER(address12) > AddressRange-1) then
           address12_tmp <= (others => '0');
      else 
           address12_tmp <= address12;
      end if;
--synthesis translate_on
end process;
 
memory_access_guard_13: process (address13) 
begin
      address13_tmp <= address13;
--synthesis translate_off
      if (CONV_INTEGER(address13) > AddressRange-1) then
           address13_tmp <= (others => '0');
      else 
           address13_tmp <= address13;
      end if;
--synthesis translate_on
end process;
 
memory_access_guard_14: process (address14) 
begin
      address14_tmp <= address14;
--synthesis translate_off
      if (CONV_INTEGER(address14) > AddressRange-1) then
           address14_tmp <= (others => '0');
      else 
           address14_tmp <= address14;
      end if;
--synthesis translate_on
end process;
 
memory_access_guard_15: process (address15) 
begin
      address15_tmp <= address15;
--synthesis translate_off
      if (CONV_INTEGER(address15) > AddressRange-1) then
           address15_tmp <= (others => '0');
      else 
           address15_tmp <= address15;
      end if;
--synthesis translate_on
end process;
 
memory_access_guard_16: process (address16) 
begin
      address16_tmp <= address16;
--synthesis translate_off
      if (CONV_INTEGER(address16) > AddressRange-1) then
           address16_tmp <= (others => '0');
      else 
           address16_tmp <= address16;
      end if;
--synthesis translate_on
end process;
 
memory_access_guard_17: process (address17) 
begin
      address17_tmp <= address17;
--synthesis translate_off
      if (CONV_INTEGER(address17) > AddressRange-1) then
           address17_tmp <= (others => '0');
      else 
           address17_tmp <= address17;
      end if;
--synthesis translate_on
end process;
 
memory_access_guard_18: process (address18) 
begin
      address18_tmp <= address18;
--synthesis translate_off
      if (CONV_INTEGER(address18) > AddressRange-1) then
           address18_tmp <= (others => '0');
      else 
           address18_tmp <= address18;
      end if;
--synthesis translate_on
end process;
 
memory_access_guard_19: process (address19) 
begin
      address19_tmp <= address19;
--synthesis translate_off
      if (CONV_INTEGER(address19) > AddressRange-1) then
           address19_tmp <= (others => '0');
      else 
           address19_tmp <= address19;
      end if;
--synthesis translate_on
end process;
 
memory_access_guard_20: process (address20) 
begin
      address20_tmp <= address20;
--synthesis translate_off
      if (CONV_INTEGER(address20) > AddressRange-1) then
           address20_tmp <= (others => '0');
      else 
           address20_tmp <= address20;
      end if;
--synthesis translate_on
end process;
 
memory_access_guard_21: process (address21) 
begin
      address21_tmp <= address21;
--synthesis translate_off
      if (CONV_INTEGER(address21) > AddressRange-1) then
           address21_tmp <= (others => '0');
      else 
           address21_tmp <= address21;
      end if;
--synthesis translate_on
end process;
 
memory_access_guard_22: process (address22) 
begin
      address22_tmp <= address22;
--synthesis translate_off
      if (CONV_INTEGER(address22) > AddressRange-1) then
           address22_tmp <= (others => '0');
      else 
           address22_tmp <= address22;
      end if;
--synthesis translate_on
end process;
 
memory_access_guard_23: process (address23) 
begin
      address23_tmp <= address23;
--synthesis translate_off
      if (CONV_INTEGER(address23) > AddressRange-1) then
           address23_tmp <= (others => '0');
      else 
           address23_tmp <= address23;
      end if;
--synthesis translate_on
end process;

p_rom_access: process (clk)  
begin 
    if (clk'event and clk = '1') then
 
        if (ce0 = '1') then  
            q0 <= mem0(CONV_INTEGER(address0_tmp)); 
        end if;
 
        if (ce1 = '1') then  
            q1 <= mem0(CONV_INTEGER(address1_tmp)); 
        end if;
 
        if (ce2 = '1') then  
            q2 <= mem1(CONV_INTEGER(address2_tmp)); 
        end if;
 
        if (ce3 = '1') then  
            q3 <= mem1(CONV_INTEGER(address3_tmp)); 
        end if;
 
        if (ce4 = '1') then  
            q4 <= mem2(CONV_INTEGER(address4_tmp)); 
        end if;
 
        if (ce5 = '1') then  
            q5 <= mem2(CONV_INTEGER(address5_tmp)); 
        end if;
 
        if (ce6 = '1') then  
            q6 <= mem3(CONV_INTEGER(address6_tmp)); 
        end if;
 
        if (ce7 = '1') then  
            q7 <= mem3(CONV_INTEGER(address7_tmp)); 
        end if;
 
        if (ce8 = '1') then  
            q8 <= mem4(CONV_INTEGER(address8_tmp)); 
        end if;
 
        if (ce9 = '1') then  
            q9 <= mem4(CONV_INTEGER(address9_tmp)); 
        end if;
 
        if (ce10 = '1') then  
            q10 <= mem5(CONV_INTEGER(address10_tmp)); 
        end if;
 
        if (ce11 = '1') then  
            q11 <= mem5(CONV_INTEGER(address11_tmp)); 
        end if;
 
        if (ce12 = '1') then  
            q12 <= mem6(CONV_INTEGER(address12_tmp)); 
        end if;
 
        if (ce13 = '1') then  
            q13 <= mem6(CONV_INTEGER(address13_tmp)); 
        end if;
 
        if (ce14 = '1') then  
            q14 <= mem7(CONV_INTEGER(address14_tmp)); 
        end if;
 
        if (ce15 = '1') then  
            q15 <= mem7(CONV_INTEGER(address15_tmp)); 
        end if;
 
        if (ce16 = '1') then  
            q16 <= mem8(CONV_INTEGER(address16_tmp)); 
        end if;
 
        if (ce17 = '1') then  
            q17 <= mem8(CONV_INTEGER(address17_tmp)); 
        end if;
 
        if (ce18 = '1') then  
            q18 <= mem9(CONV_INTEGER(address18_tmp)); 
        end if;
 
        if (ce19 = '1') then  
            q19 <= mem9(CONV_INTEGER(address19_tmp)); 
        end if;
 
        if (ce20 = '1') then  
            q20 <= mem10(CONV_INTEGER(address20_tmp)); 
        end if;
 
        if (ce21 = '1') then  
            q21 <= mem10(CONV_INTEGER(address21_tmp)); 
        end if;
 
        if (ce22 = '1') then  
            q22 <= mem11(CONV_INTEGER(address22_tmp)); 
        end if;
 
        if (ce23 = '1') then  
            q23 <= mem11(CONV_INTEGER(address23_tmp)); 
        end if;

end if;
end process;

end rtl;


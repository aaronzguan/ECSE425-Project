--********************************************************************
-- ECSE 425, Group 6
-- Runze ZHANG(260760723)
-- Date: March 14, 2017

-- Description: stage of ID and the buffer between ID and EX
-- analysis the oprand part and return the relative value in register
-- also save the value return from state WB to register 

-- build a register with size 32 and 32bits each block 

-- March 15, 2017
-- add zero-extend immediate for andi and ori 

--********************************************************************
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ID is
        GENERIC(
              register_size: integer:=32
              );
	PORT( 
              clk: in  std_logic;
              hazard_detect: in std_logic;   -- stall the instruction when hazard_detect is 1 
              instruction_addr: in  std_logic_vector(31 downto 0);
              IR_in: in  std_logic_vector(31 downto 0);
              writeback_register_address: in  std_Logic_vector(5 downto 0);
              writeback_register_content: in  std_logic_vector(31 downto 0);
              instruction_addr_out: out std_logic_vector(31 downto 0);
              rs:  out std_logic_vector(31 downto 0);
              rt:  out  std_logic_vector(31 downto 0);  
              rd_addr: out std_logic_vector(4 downto 0);
              rt_addr: out std_logic_vector(4 downto 0);
              signExtImm: out  std_logic_vector(31 downto 0);
              opcode_out: out  std_logic_vector(5 downto 0)
             
	);
end entity;

architecture behaviour of ID is
          TYPE registerarray is ARRAY(register_size-1 downto 0) OF std_logic_vector(31 downto 0); 
          SIGNAL register_block: registerarray;
          SIGNAL rs_pos: std_logic_vector(4 downto 0);
          SIGNAL rt_pos: std_logic_vector(4 downto 0);
          SIGNAL immediate: std_logic_vector(15 downto 0);
          SIGNAL rd_pos: std_logic_vector(4 downto 0);
          SIGNAL IR: std_logic_vector(31 downto 0);
begin

reg_process:process
begin
   if(clk'event and clk = '1') then
      if(hazard_detect = '0') then 
           IR <= IR_in;
        else
           IR<= x"80000020";
       end if;
   elsif(clk' event and clk = '0') then
     if(writeback_register_address /= b"000000") then
          register_block(to_integer(unsigned(writeback_register_address))) <= writeback_register_content;
      end if;
      rs_pos<= IR(25 downto 21);
      rt_pos<= IR (20 downto 16);
      rd_pos<= IR(15 downto 11);
      immediate<= IR(15 downto 0); 
      rs<= register_block(to_integer(unsigned(rs_pos)));
      rt<= register_block(to_integer(unsigned(rt_pos)));
      rd_addr<=rd_pos;
      rt_addr<=rt_pos;
      opcode_out<=IR(31 downto 26);
      instruction_addr_out<=instruction_addr;	
      signExtImm(15 downto 0) <= immediate;
      if(IR(31 downto 27) = "00110") then
          signExtImm(31 downto 16)<=(31 downto 16 => '0');     
      else
          signExtImm(31 downto 16)<=(31 downto 16 => immediate(15));
      end if;
     end if;
end process;
	
end behaviour;

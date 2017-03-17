--********************************************************************
-- ECSE 425, Group 6
-- Runze ZHANG(260760723)
-- Date: March 14, 2017

-- Description: stage of ID and the buffer between ID and EX
-- analysis the oprand part and return the relative value in register
-- also save the value return from state WB to register 

-- build a register with size 32 and 32bits each block 

-- Date: March 16, 2017
-- add hazard detect 
-- add controler for forward 
--fix some bug

-- add register value output to .txt file
-- Zhou Yining
--********************************************************************
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-- Catherine: library for file handler
--use ieee.std_logic_arith.all;
use std.textio.all;

entity ID is
        GENERIC(
              register_size: integer:=32
              );
	PORT( 
              clk: in  std_logic;
              --hazard_detect: in std_logic;   -- stall the instruction when hazard_detect is 1 
              instruction_addr: in  std_logic_vector(31 downto 0);
              IR_in: in  std_logic_vector(31 downto 0);
              writeback_register_address: in  std_Logic_vector(4 downto 0);
              writeback_register_content: in  std_logic_vector(31 downto 0);
              ex_state_buffer: in std_logic_vector(10 downto 0);
              instruction_addr_out: out std_logic_vector(31 downto 0);
	      jump_addr: out std_logic_vector(25 downto 0);
              rs:  out std_logic_vector(31 downto 0);
              rt:  out  std_logic_vector(31 downto 0);  
              --rd_addr: out std_logic_vector(4 downto 0);
              des_addr: out std_logic_vector(4 downto 0);
              signExtImm: out  std_logic_vector(31 downto 0);
              insert_stall: out std_logic;
              EX_control_buffer: out std_logic_vector(10 downto 0); --  for ex stage provide information for forward and harzard detect, first bit for mem_read, 9-5 for rt, 4-0 for rs
              MEM_control_buffer: out std_logic_vector(5 downto 0); --  for mem stage, provide info for forward and hazard detect, first bit for wb_signal, 4-0 for des_adr
              WB_control_buffer: out std_logic_vector(5 downto 0); --  for mem stage, provide info for forward and hazard detect, first bit for wb_signal, 4-0 for des_adr
              funct_out: out std_logic_vector(5 downto 0);
	     opcode_out: out  std_logic_vector(5 downto 0);
             write_reg_txt: in std_logic:='0'  -- indicate program ends
	);
end ID;

architecture behaviour of ID is
          TYPE registerarray is ARRAY(register_size-1 downto 0) OF std_logic_vector(31 downto 0); 
          SIGNAL register_block: registerarray;
          SIGNAL rs_pos: std_logic_vector(4 downto 0):="00000";
          SIGNAL rt_pos: std_logic_vector(4 downto 0):="00000";
          SIGNAL immediate: std_logic_vector(15 downto 0):="0000000000000000";
          SIGNAL rd_pos: std_logic_vector(4 downto 0):="00000";
          SIGNAL IR: std_logic_vector(31 downto 0):= (others => '0');
          SIGNAL opcode: std_logic_vector(5 downto 0):="000000";
          SIGNAL funct: std_logic_vector(5 downto 0):="000000";
          SIGNAL dest_address: std_logic_vector(4 downto 0):="00000";
          SIGNAL temp_MEM_control_buffer: std_logic_vector(5 downto 0);
          SIGNAL hazard_detect: std_logic:= '0';
          
begin

          opcode <= IR(31 downto 26);
          funct  <= IR(5 downto 0);
          rs_pos<= IR(25 downto 21);
          rt_pos<= IR (20 downto 16);
          rd_pos<= IR(15 downto 11);
          immediate<= IR(15 downto 0); 
          insert_stall <= hazard_detect; 
reg_process:process(clk)
begin
  -- initialize the register 
  IF(now < 1 ps)THEN
	For i in 0 to register_size-1 LOOP
	  register_block(i) <= std_logic_vector(to_unsigned(0,32));
	END LOOP;
    end if;

   if(clk'event and clk = '1') then

-- hazard detect 

      if(ex_state_buffer(10) = '1') then 
          if(ex_state_buffer(9 downto 5) = rs_pos or ex_state_buffer(4 downto 0) = rt_pos)then
               hazard_detect <= '1';
           else 
                hazard_detect<= '0'; 
           end if;
    end if;
  -- get IR in the rising edge
       if(hazard_detect = '0') then 
           IR <= IR_in;
        else
           IR<= x"00000020";
       end if; 
-- get the des_addr through case
       case opcode is 
           -- R instruction 
          when "000000" =>
             if(funct = "011010" or funct = "011000" or funct = "001000") then 
              dest_address <="00000";
              else 
              dest_address <= rd_pos;
              end if;
           -- I & J instruction 
           -- lw
         when "100011" => 
               dest_address <= rt_pos;
           -- lui
         when "001111" => 
               dest_address <= rt_pos;
            -- xori
         when "001110" => 
               dest_address <= rd_pos;
           -- ori
         when "001101" => 
               dest_address <= rt_pos;
            -- andi
         when "001100" => 
               dest_address <= rt_pos;
             -- slti
         when "001010" => 
               dest_address <= rt_pos;
             -- addi
         when "001000" => 
               dest_address <= rt_pos;
             -- jal
         when "000011" => 
               dest_address <= "11111";
         when others =>
               dest_address <="00000";
       end case;
   elsif(clk' event and clk = '0') then
     if(writeback_register_address /= "00000") then
          register_block(to_integer(unsigned(writeback_register_address))) <= writeback_register_content;
      end if;
      
      
      rs<= register_block(to_integer(unsigned(rs_pos)));
      rt<= register_block(to_integer(unsigned(rt_pos)));
     -- rd_addr<=rd_pos;
      --rt_addr<=rt_pos;
      opcode_out<=IR(31 downto 26);
      funct_out <= funct;
      instruction_addr_out<=instruction_addr;	
      jump_addr <= IR(25 downto 0);
      signExtImm(15 downto 0) <= immediate;
      if(IR(31 downto 27) = "00110") then
          signExtImm(31 downto 16)<=(31 downto 16 => '0');     
      else
          signExtImm(31 downto 16)<=(31 downto 16 => immediate(15));
      end if;
     end if;
end process;


-- to save the control signal to the buffer 
control_process: process(clk)
begin 
 -- prepare for ex_control buffer 
     if(falling_edge(clk)) then 
       if(opcode = "100011") then 
           EX_control_buffer(10) <= '1';
        else 
           EX_control_buffer(10) <= '0';
         end if;
       EX_control_buffer(9 downto 5) <= rt_pos;
       EX_control_buffer(4 downto 0) <= rs_pos; 
   --prepare for mem and wb control buffer
         case opcode is 
           -- R instruction 
          when "000000" =>
             if(funct = "011010" or funct = "011000" or funct = "001000") then 
              temp_MEM_control_buffer(5) <= '0';
              else 
              temp_MEM_control_buffer(5) <= '1';
              end if;
           -- I & J instruction 
           -- lw
         when "100011" => 
               temp_MEM_control_buffer(5) <= '0';
           -- luiha
         when "001111" => 
              temp_MEM_control_buffer(5) <= '1';
            -- xori
         when "001110" => 
             temp_MEM_control_buffer(5) <= '1';
           -- ori
         when "001101" => 
              temp_MEM_control_buffer(5) <= '1';
            -- andi
         when "001100" => 
               temp_MEM_control_buffer(5) <= '1';
             -- slti
         when "001010" => 
               temp_MEM_control_buffer(5) <= '1';
             -- addi
         when "001000" => 
               temp_MEM_control_buffer(5) <= '1';
             -- jal
         when "000011" => 
               temp_MEM_control_buffer(5) <= '1';
         when others =>
               temp_MEM_control_buffer(5) <= '0';
       end case;
       
       if(opcode = "100011") then 
           WB_control_buffer(5) <= '1';
        else 
           WB_control_buffer(5) <= temp_MEM_control_buffer(5);
         end if;
       MEM_control_buffer(5) <= temp_MEM_control_buffer(5);
       MEM_control_buffer(4 downto 0) <= dest_address;
       WB_control_buffer(4 downto 0) <= dest_address;
       des_addr<= dest_address;
    end if;
end process;

-- Catherine: to output register value to txt file when program ends  
file_handler_process: process
        file file_pointer : text;
        variable line_content : string(1 to 32);
        variable reg_value : std_logic_vector(31 downto 0);
        variable line_num : line;
        variable i,j : integer := 0;
      begin
-- when the program ends
      if(write_reg_txt = '1')then
        file_open(file_pointer, "register_file.txt", WRITE_MODE);
-- register_file.txt has 32 lines
-- convert each bit value of reg_value to character for writing 
        for i in 0 to 31 loop
         reg_value := register_block(i);
          for j in 0 to 31 loop 
            if(reg_value(j) = '0')then
                line_content(32-j) := '0';
            else
                line_content(32-j) := '1';
            end if;
          end loop;
          --write the line
          write(line_num, line_content); 
          --write the contents into txt file
          writeline(file_pointer, line_num); 
          wait for 10ns;
        end loop;
        file_close(file_pointer);
        wait;
      end if;
    end process;
	      
end behaviour;

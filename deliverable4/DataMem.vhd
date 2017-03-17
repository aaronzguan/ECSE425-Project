-- ********************************************************************
-- -- ECSE 425, Group 6
-- Zhou Yining(260760795)
-- Date: March 14, 2017

-- Description: MEM stage is for load or store data from memory. 
-- For memory access: use the result from ALU as data memory address.
-- For branch: use the ALU result as branch address.
-- For others: output ALU result.

-- Date: March 16, 2017
-- add output final memory content to .txt file 
-- ********************************************************************
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE STD.textio.all;
USE ieee.std_logic_textio.all;

entity DataMem is
    GENERIC(
		ram_size : INTEGER := 32768
	);
    port(
         clock: in std_logic;
         opcode: in std_logic_vector(5 downto 0);
         dest_addr_in: in std_logic_vector(4 downto 0);
         ALU_result: in std_logic_vector(31 downto 0);
         rt_data: in std_logic_vector(31 downto 0);
	 bran_taken: in std_logic;
	 MEM_control_buffer: in std_logic_vector(5 downto 0);
	 WB_control_buffer : in std_logic_vector(5 downto 0);
	 write_reg_txt: in std_logic := '0' -- indicate program ends-- from testbench
	    
	 MEM_control_buffer_out: in std_logic_vector(5 downto 0); --for ex forward 
	 WB_control_buffer_out : in std_logic_vector(5 downto 0); -- for wb stage 
         
	 mem_data: out std_logic_vector(31 downto 0);
         ALU_data: out std_logic_vector(31 downto 0);
         dest_addr_out: out std_logic_vector(4 downto 0);
         bran_addr: out std_logic_vector(31 downto 0); -- for if 
	 bran_taken_out: out std_logic;                -- for if 
	
         );
end DataMem;

architecture behavior of DataMem is
    -- memory
    TYPE MEM IS ARRAY(ram_size-1 downto 0) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL ram_block: MEM;
	-- output file
	signal outdata: std_logic_vector(31 downto 0);
    
begin
 MEM_control_buffer_out<= MEM_control_buffer;
     process(clock)
     begin
       if(clock' event and clock ='1')then
        dest_addr_out <= dest_addr_in;
        
        --This is a cheap trick to initialize the SRAM in simulation
		IF(now < 1 ps)THEN
			For i in 0 to ram_size-1 LOOP
				ram_block(i) <= std_logic_vector(to_unsigned(0,8));
			END LOOP;
		end if;
 
        
        -- the opcode is for branch
        if(opcode = "000101" or opcode = "000100")then
          bran_addr <= ALU_result;
          bran_taken_out<= bran_taken;
			
        -- the opcode is sw 
        elsif(opcode = "101011")then
          bran_addr <= std_logic_vector(to_unsigned(0, 32));
          for i in 0 to 3 loop
             ram_block(to_integer(unsigned(ALU_result))+ i) <= rt_data(8*i+7 downto 8*i);
          end loop;
          
        -- the opcode is lw 
        elsif(opcode = "100011")then
         bran_addr <= std_logic_vector(to_unsigned(0, 32));
          for i in 0 to 3 loop
             mem_data(8*i+7 downto 8*i) <= ram_block(to_integer(unsigned(ALU_result))+i);
          end loop;
             
        -- the opcode is other
        else
        bran_addr <= std_logic_vector(to_unsigned(0, 32));
        ALU_data <= ALU_result;
        end if;
	elsif(falling_edge(clk))then
		WB_control_buffer_out<= WB_control_buffer;
       end if;
    end process;
	       
    output: process
		file file_pointer : text;
        	variable line_content : string(1 to 32);
        	variable reg_value  : std_logic_vector(31 downto 0);
        	variable line_num : line;
       		variable i,j : integer := 0;
	begin
	if(write_reg_txt = '1') then -- program ends
		file_open(file_pointer, "memory.txt", write_mode);
		for i in 0 to 8191 loop
			for j in 0 to 3 loop
				outdata(7 + 8*j downto 8*j) <= ram_block(i*4+j);
			end loop;
			reg_value := outdata;
			for x in 0 to 31 loop
				if(reg_value(x) = '0') then
					line_content(32-x) := '0';
				else
					line_content(32-x) := '1';
				end if;
			end loop;
			write(line_num, line_content);
			writeline(file_pointer, line_num);
			wait for 10ns;
		end loop;
		file_close(file_pointer);
		wait;
	end if;
	end process;	
end behavior;

         
         
        
        
        


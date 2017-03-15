-- ********************************************************************
-- ECSE 425, Group 6
-- Zhou Yining(260760795)
-- Date: March 14, 2017

-- Description: MEM stage is for load or store data from memory. 
-- Use the result from ALU as data memory address.
-- 
-- ********************************************************************
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

entity DataMem is
    GENERIC(
		ram_size : INTEGER := 32768;
		mem_delay : time := 1 ns;
		clock_period : time := 1 ns
	);
    port(
         clock: in std_logic;
         opcode: in std_logic_vector(5 downto 0);
         dest_addr_in: in std_logic_vector(4 downto 0);
         ALU_result: in std_logic_vector(31 downto 0);
         rt_data: in std_logic_vector(31 downto 0);
	 bran_taken: in std_logic;
         mem_data: out std_logic_vector(31 downto 0);
         ALU_data: out std_logic_vector(31 downto 0);
         dest_addr_out: out std_logic_vector(4 downto 0);
         bran_addr: out std_logic_vector(31 downto 0);
	 bran_taken_out: out std_logic
         );
end DataMem;

architecture behavior of DataMem is
    -- memory
    TYPE MEM IS ARRAY(ram_size-1 downto 0) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL ram_block: MEM;
	SIGNAL write_waitreq_reg: STD_LOGIC := '1';
	SIGNAL read_waitreq_reg: STD_LOGIC := '1';
    signal waitrequest: std_logic;
    signal memread: std_logic;
    signal memwrite: std_logic;
    
begin
 
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
        if(opcode = "000101" or "000100")then
          bran_addr <= ALU_result;
          bran_taken_out<= bran_taken;
        -- the opcode is sw rt-data ALU_result address
        elsif(opcode = "101011")then
          bran_addr <= '0';
          memwrite <= '1';
          for i in 0 to 3 loop
             ram_block(to_integer(unsigned(ALU_result))+ i) <= rt_data(8*i+7 downto 8*i);
          end loop;
          
        -- the opcode is lw mem_data ALU_result address
        elsif(opcode = "100011")then
          bran_addr <= '0';
          memread <= '1';
          for i in 0 to 3 loop
             mem_data(8*i+7 downto 8*i) <= ram_block(to_integer(unsigned(ALU_result))+i);
          end loop;
             
        -- the opcode is other
        else
        bran_addr <= '0';
        ALU_data <= ALU_result;
        end if;
       end if;
    end process;
    
    waitreq_w_proc: PROCESS (memwrite)
	BEGIN
		IF(memwrite'event AND memwrite = '1')THEN
			write_waitreq_reg <= '0' after mem_delay, '1' after mem_delay + clock_period;

		END IF;
	END PROCESS;

	waitreq_r_proc: PROCESS (memread)
	BEGIN
		IF(memread'event AND memread = '1')THEN
			read_waitreq_reg <= '0' after mem_delay, '1' after mem_delay + clock_period;
		END IF;
	END PROCESS;
	waitrequest <= write_waitreq_reg and read_waitreq_reg;

end behavior;

         
         
        
        
        


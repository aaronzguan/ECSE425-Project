
--********************************************************************
-- ECSE 425, Group 6
-- Zhong GUAN(260758587)
-- Date: March 14, 2017

-- Description: The instruction memory have size of 1024 * 4 bytes
-- The ASCII test file 'program.txt' is put into instruction memory
-- The program is loaded from memory according to the current pc 

--********************************************************************

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE STD.textio.all;
USE ieee.std_logic_textio.all;

ENTITY InstMem IS
	GENERIC(
		ram_size : INTEGER := 1024;
		mem_delay : time := 10 ns;
		clock_period : time := 1 ns
	);
	PORT (
		clock: IN STD_LOGIC;
		writedata: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		address: IN INTEGER RANGE 0 TO ram_size-1;
		memread: IN STD_LOGIC;
		memwrite: IN STD_LOGIC;
		readinstruction: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
		waitrequest: OUT STD_LOGIC
	);
END InstMem;

ARCHITECTURE rtl OF InstMem IS
	TYPE MEM IS ARRAY(ram_size-1 downto 0) OF STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL ram_block: MEM;
	SIGNAL read_address_reg: INTEGER RANGE 0 to ram_size-1;
	SIGNAL read_waitreq_reg: STD_LOGIC := '1';
	SIGNAL write_waitreq_reg: STD_LOGIC := '1';
	signal line_counter: integer := 0;

	
BEGIN
	--Read the 'program.txt' file into instruction memory
	readprogram: process

		file program: text;
		variable mem_line: line;
		variable read_data: std_logic_vector(31 downto 0);

	begin
		file_open(program,"program.txt", read_mode);
		IF (clock'event AND clock = '1') THEN
			while not endfile(program) loop
				readline(program,mem_line);
				read(mem_line,read_data); --32bits data
				ram_block(line_counter) <= read_data;
				line_counter <= line_counter+1;
			end loop;
		file_close(program);
		end if;
	end process;
	--This is the main section of the SRAM model
	mem_process: PROCESS (clock)
	BEGIN
	
		--This is a cheap trick to initialize the SRAM in simulation
		IF(now < 1 ps)THEN
			For i in 0 to ram_size-1 LOOP
				ram_block(i) <= std_logic_vector(to_unsigned(i,8));
			END LOOP;
		end if;

		--This is the actual synthesizable SRAM block
		IF (clock'event AND clock = '1') THEN
			IF (memwrite = '1') THEN
				ram_block(address) <= writedata;
			END IF;
		read_address_reg <= address;
		END IF;
	END PROCESS;
	readinstruction <= ram_block(read_address_reg);

	--The waitrequest signal is used to vary response time in simulation
	--Read and write should never happen at the same time.
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

END rtl;

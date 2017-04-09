--Adapted from Example 12-15 of Quartus Design and Synthesis handbook
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE STD.textio.all;
USE ieee.std_logic_textio.all;

ENTITY memory IS
	GENERIC(
		ram_size : INTEGER := 32768;
		mem_delay : time := 10 ns;
		clock_period : time := 1 ns
	);
	PORT (
		clock: IN STD_LOGIC;

		writedata_instcache: IN STD_LOGIC_VECTOR (31 DOWNTO 0):=(others=>'0');
		address_instcache: IN INTEGER RANGE 0 TO 4*ram_size - 4 := 0;
		memwrite_instcache: IN STD_LOGIC:= '0';
		memread_instcache: IN STD_LOGIC:= '0';
		--readdata_instcache: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
		waitrequest_instcache: OUT STD_LOGIC;

		readdata: out STD_LOGIC_VECTOR (31 DOWNTO 0);

		writedata_datacache: IN STD_LOGIC_VECTOR (31 DOWNTO 0):=(others=>'0');
		address_datacache: IN INTEGER RANGE 0 TO 4*ram_size - 4 := 0;
		memwrite_datacache: IN STD_LOGIC:= '0';
		memread_datacache: IN STD_LOGIC:= '0';
		--readdata_datacache: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
		waitrequest_datacache: OUT STD_LOGIC;

		readfinish: in std_logic := '0';
		write_reg_txt: in std_logic := '0' -- indicate program ends-- from testbench

	);
END memory;

ARCHITECTURE rtl OF memory IS
	TYPE MEM IS ARRAY(ram_size-1 downto 0) OF STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL ram_block: MEM;
	SIGNAL read_address_reg_instcache: INTEGER RANGE 0 to ram_size-1 :=0;
	SIGNAL read_address_reg_datacache: INTEGER RANGE 0 to ram_size-1 :=0;
	SIGNAL write_waitreq_reg_instcache: STD_LOGIC := '1';
	SIGNAL read_waitreq_reg_instcache: STD_LOGIC := '1';
	SIGNAL write_waitreq_reg_datacache: STD_LOGIC := '1';
	SIGNAL read_waitreq_reg_datacache: STD_LOGIC := '1';
	SIGNAL addr_instcache: INTEGER RANGE 0 TO ram_size-1 :=0;
	SIGNAL addr_datacache: INTEGER RANGE 0 TO ram_size-1 :=0;

	signal counter: integer := 0;
	signal max_inst: integer := 0;

	signal memwait: STD_LOGIC:= '1';
	signal stallif: std_logic := '0';
BEGIN
	addr_instcache <= address_instcache/4;
	addr_datacache <= address_datacache/4;

--------------------- read program ---------------------
	readprogram: process (readfinish)
		file program: text;
		variable mem_line: line;
        	variable fstatus: file_open_status;
		variable read_data: std_logic_vector(31 downto 0):=(others=>'0');
        	variable counter: integer := 0;
	begin
        	report "start read the program.txt file";
		file_open(fstatus,program,"program.txt", read_mode);
		while not endfile(program) loop
			readline(program,mem_line);
			read(mem_line,read_data); --32bits data
			ram_block(counter) <= read_data;
			counter := counter+1;
		end loop;
		file_close(program);
	report "finish reading the porgram.txt file and put them into memory";
    	max_inst <= counter;
	--- initialize the rest block ---
	for i in max_inst to ram_size-1 LOOP
		ram_block(i) <= std_logic_vector(to_unsigned(0,32));
	end loop;
	end process;



	--This is the main section of the SRAM model
	mem_process: PROCESS (clock)
	BEGIN

		--This is the actual synthesizable SRAM block
		IF (clock'event AND clock = '1') THEN
			if(memwrite_datacache = '1') then
				ram_block(addr_datacache) <= writedata_datacache;
				if(memread_instcache = '1') then
					stallif <= '1';
				end if;
			elsif(memread_datacache = '1') then
				readdata <= ram_block(addr_datacache);
				if(memread_instcache = '1') then
					stallif <= '1';
				end if;
			elsif(memread_instcache = '1') then
				readdata <= ram_block(addr_instcache);
			end if;

		END IF;
	END PROCESS;


	--The waitrequest signal is used to vary response time in simulation
	--Read and write should never happen at the same time.
	waitreq_w_proc_datacache: PROCESS (memwrite_datacache)
	BEGIN
		IF(rising_edge(memwrite_datacache))THEN
			write_waitreq_reg_datacache <= '0' after mem_delay, '1' after mem_delay + clock_period;
		END IF;

	END PROCESS;
	waitreq_r_proc_datacache: PROCESS (memread_datacache)
	BEGIN
		IF(rising_edge(memread_datacache))THEN
			read_waitreq_reg_datacache <= '0' after mem_delay, '1' after mem_delay + clock_period;
		END IF;
	END PROCESS;

	waitrequest_datacache <= write_waitreq_reg_datacache and read_waitreq_reg_datacache;


	memwait <=  write_waitreq_reg_datacache and read_waitreq_reg_datacache;


	process(memwait)
	begin
		if(falling_edge(memwait)) then
			if(stallif='1') then
				readdata <= ram_block(addr_instcache);
				stallif <= '0';
			end if;
		end if;
	end process;
			
	waitreq_r_proc_instcache: PROCESS (stallif)
	BEGIN
		IF(falling_edge(stallif))THEN
			read_waitreq_reg_instcache <= '0' after mem_delay, '1' after mem_delay + clock_period;
		END IF;
	END PROCESS;

	waitrequest_instcache <= read_waitreq_reg_instcache;
	


----- Output the memory when program ends -------
	output: process (write_reg_txt)
		file memoryfile : text;
		variable line_num : line;
		variable fstatus: file_open_status;
        	variable reg_value  : std_logic_vector(31 downto 0);
	begin
	if(write_reg_txt = '1') then -- program ends
		report "Start writing the memory.txt file";
		file_open(fstatus, memoryfile, "memory.txt", write_mode);
		for i in 0 to 32767 loop
			reg_value := ram_block(i);
			--reg_value := outdata;
			write(line_num, reg_value);
			writeline(memoryfile, line_num);
		end loop;
		file_close(memoryfile);
		report "Finish outputing the memory.txt";
	end if;
	end process;	

END rtl;

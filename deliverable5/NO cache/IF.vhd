LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

entity ifstage IS
	PORT(
		clock: in STD_LOGIC;
		reset: in std_logic := '0';
		insert_stall: in std_logic := '0';
		BranchAddr: in STD_LOGIC_VECTOR (31 DOWNTO 0);
		Branch_taken: in STD_LOGIC := '0';
		next_addr: out STD_LOGIC_VECTOR (31 DOWNTO 0);
		
		s_addr_inst: out integer; -- send address to cache
		s_read_inst: out std_logic; -- send read signal to cache
		inst: out std_logic_vector(31 downto 0); --  send instruction to ID
		s_waitrequest_inst: in std_logic :='0'; -- get waitrequest signal from cache
		s_readdata_inst: in std_logic_vector(31 downto 0); -- get instruction from cache
                mem_data_stall: in std_logic; 
		ismiss: in std_logic := '0'
		
	);
END ifstage;

ARCHITECTURE behavioral of ifstage IS

	signal pc: STD_LOGIC_VECTOR (31 DOWNTO 0):= (others => '0');
	signal pc_plus4: STD_LOGIC_VECTOR (31 DOWNTO 0):= (others => '0');
	signal cachework: std_logic := '0';-- indicating wether the cache is working or not.

begin

process (pc_plus4,Branch_taken)
begin
	if(Branch_taken = '1') and (insert_stall = '0') and (mem_data_stall = '0')then
		pc <= BranchAddr;
	elsif  (insert_stall = '0' and mem_data_stall = '0') then
		pc <= pc_plus4;               
	end if;
end process;

process (clock)
begin
	if(rising_edge(clock)) then
		--Synchronous reset
		if (reset = '1') then
			pc <= (others => '0');
		end if;
			
	s_read_inst <= '0';

	elsif(falling_edge(clock)) then
		if(insert_stall = '0' and mem_data_stall = '0') then
			if(cachework = '0') then -- send the address if the cache is not working
				s_read_inst <= '1'; -- send the read signal to cache
				cachework <= '1';
			end if;
		end if;
	end if;
end process;

process(ismiss,s_waitrequest_inst,clock)
begin
	if(insert_stall = '0' and mem_data_stall = '0') then
	
		if(rising_edge(ismiss)) then
			inst <= x"00000020"; -- read miss, send 0+0=0 to ID
		elsif(falling_edge(clock) and ismiss = '1') then
			inst <= x"00000020"; -- read miss, send 0+0=0 to ID
		elsif(falling_edge(clock) and ismiss = '0') then

			pc_plus4 <= std_logic_vector(to_unsigned( to_integer(unsigned(pc)) + 4,32));
			next_addr <= pc;
			s_addr_inst <= to_integer(unsigned(pc)); -- send the address to cache
		
		elsif (falling_edge(s_waitrequest_inst)) then -- IF can receive the results
			inst <= s_readdata_inst; -- get instruction from cache
			if(cachework = '1') then
				cachework <= '0';
		end if;

		end if;
	end if;
end process;
end behavioral;

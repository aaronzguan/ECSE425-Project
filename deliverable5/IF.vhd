LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

entity ifstage IS
	GENERIC(
		ram_size : INTEGER := 4096
	);
	PORT(
		clock: in STD_LOGIC;
		reset: in std_logic := '0';
		insert_stall: in std_logic := '0';
		BranchAddr: in STD_LOGIC_VECTOR (31 DOWNTO 0);
		Branch_taken: in STD_LOGIC := '0';
		next_addr: out STD_LOGIC_VECTOR (31 DOWNTO 0);
		
		--cachestartworking: out std_logic := '0'; -- inform cache to start work
		s_addr_inst: out std_logic_vector(31 downto 0); -- send address to cache
		s_read_inst: out std_logic; -- send read signal to cache
		inst: out std_logic_vector(31 downto 0); --  send instruction to ID
		s_waitrequest_inst: in std_logic :='0'; -- get waitrequest signal from cache
		s_readdata_inst: in std_logic_vector(31 downto 0) -- get instruction from cache
		
	);
END ifstage;

ARCHITECTURE behavioral of ifstage IS

	signal pc: STD_LOGIC_VECTOR (31 DOWNTO 0):= (others => '0');
	signal pc_plus4: STD_LOGIC_VECTOR (31 DOWNTO 0):= (others => '0');
	signal cachework: std_logic := '0';-- indicating wether the cache is working or not.

begin

process (pc_plus4,Branch_taken)
begin
	if(Branch_taken = '1') and (insert_stall = '0')then
		pc <= BranchAddr;
	elsif  (insert_stall = '0') then
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

		if(insert_stall = '0') then
			if(cachework = '0') then -- send the pc if the cache is not working
				pc_plus4 <= std_logic_vector(to_unsigned( to_integer(unsigned(pc)) + 4,32));
				next_addr <= pc;
				s_addr_inst <= pc; -- send the next pc
				s_read_inst <= '1'; -- send the read signal to cache
				cachework <= '1';
			end if;
		end if;

	elsif(falling_edge(clock)) then
		if(insert_stall = '0') then
			if (s_waitrequest_inst = '0') then -- IF can receive the results
				inst <= s_readdata_inst; -- get instruction from cache
				s_read_inst <= '0';
				cachework <= '0';
			elsif (s_waitrequest_inst = '1') then
				inst <= x"00000020"; -- If read miss, send 0+0=0 to ID
			end if;
		end if;
	end if;
end process;
	
end behavioral;
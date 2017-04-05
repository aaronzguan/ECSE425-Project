LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE STD.textio.all;
USE ieee.std_logic_textio.all;

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
		s_waitrequest_inst: in std_logic :='0'; -- from cache
		s_addr_inst: out std_logic_vector(31 downto 0); -- to cache
		s_read_inst: out std_logic -- to chche
	);
END ifstage;

ARCHITECTURE behavioral of ifstage IS

	signal pc: STD_LOGIC_VECTOR (31 DOWNTO 0):= (others => '0');
	signal pc_plus4: STD_LOGIC_VECTOR (31 DOWNTO 0):= (others => '0');

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
	end if;

	if(falling_edge(clock)) then
		if(insert_stall = '0' and s_waitrequest_inst = '0') then
			pc_plus4 <= std_logic_vector(to_unsigned( to_integer(unsigned(pc)) + 4,32));
			next_addr <= pc;
			s_addr_inst <= pc;
			s_read_inst <= '1';
		end if;
	end if;
end process;
	
end behavioral;
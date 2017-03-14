
--********************************************************************
-- ECSE 425, Group 6
-- Zhong GUAN(260758587)
-- Date: March 14, 2017

-- Description: The IF stage is where a program counter will
-- pull the next instruction from the correct location in program memory.
-- This instruction is written into the IF/ID register at the next positive clock cycle. 
-- In addition the program counter was updated with 
-- either the next instruction location sequentially, 
-- or the instruction location as determined by a branch

--********************************************************************

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY ifprocess IS
	GENERIC(
		ram_size : INTEGER := 1024
	);
	PORT(
		clock: IN STD_LOGIC;
		reset: in std_logic := '0';
		processor_enable: in std_logic := '1';
		insert_stall: in std_logic := '0';
		BranchAddr: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		Branch_taken: IN STD_LOGIC := '0';
		m_addr: OUT INTEGER RANGE 0 TO ram_size -1;
		next_addr: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
	);
END ifprocess;

ARCHITECTURE behavioral of ifprocess IS

	signal pc: STD_LOGIC_VECTOR (31 DOWNTO 0):= (others => '0');
	signal next_pc: STD_LOGIC_VECTOR (31 DOWNTO 0):= (others => '0');
	signal pc_plus4: STD_LOGIC_VECTOR (31 DOWNTO 0);
begin
process (clock)
begin
	if(rising_edge(clock)) then
		--Synchronous reset
		if (reset = '1') then
			pc <= (others => '0');
		--Update PC as long as we don't stall
		elsif (processor_enable = '1') and (insert_stall = '0') then
			pc <= next_pc;
			pc_plus4 <= std_logic_vector(unsigned(pc) + 1);
			m_addr <= to_integer(unsigned(pc));
		end if;
	end if;
	if(falling_edge(clock)) then
		if(Branch_taken = '1') then
			next_addr <= BranchAddr;
			next_pc <= BranchAddr;
		else 
			next_addr <= pc_plus4;
			next_pc <= pc_plus4;
		end if;
	end if;
end process;
end behavioral;

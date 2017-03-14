--********************************************************************
-- ECSE 425, Group 6
-- Zhong GUAN(260758587)
-- Date: March 14, 2017

-- Description: The register between IF and ID which stores 
-- the next address and instruction read from instruction memory

--********************************************************************



LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY IFandID IS
	PORT (
		clock: IN STD_LOGIC;
		next_addr: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		inst: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		IFIDWrite: IN STD_LOGIC;
		inst_reg: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
		next_addr_reg: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
		opcode: OUT STD_LOGIC_VECTOR (5 downto 0)
	);
END IFandID;


ARCHITECTURE behavioral of IFandID is

BEGIN
	PROCESS(clock)
	BEGIN
		IF(rising_edge(clock)) THEN
			IF (IFIDWrite = '1') THEN
				inst_reg <= inst;
				next_addr_reg <= next_addr;
				opcode <= inst(31 downto 26);
			END IF;
		END IF;
	END PROCESS;
END behavioral;
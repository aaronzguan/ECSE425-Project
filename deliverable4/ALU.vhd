--********************************************************************
-- ECSE 425, Group 6
-- Kristin Lee (260509976)
-- Date: March 10, 2017

-- Description: ALU.vhd implements an Arithmetic Logic Unit that
-- takes ALU_opcode as input to determine which instruction to
-- perform

-- Instructions supported: add (addi), sub, mult, div, slt (slti),
-- and (andi), or (ori), nor, xor (xori), mfhi, mflo, lui, sll,
-- srl, sra

-- Opcodes:
-- add	<=	0000
-- sub	<=	0001
-- mult	<=	0010
-- div	<=	0011
-- slt	<=	0100
-- and	<=	0101
-- or	  <=	0110
-- nor	<=	0111
-- xor	<=	1000
-- mfhi	<=	1001
-- mflo	<=	1010
-- lui	<=	1011
-- sll	<=	1100
-- srl	<=	1101
-- sra	<=	1110

--********************************************************************


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ALU is
	PORT( clk : in std_logic; --clock
		    ALU_opcode : in std_logic_vector(3 downto 0); --specifies which ALU operation to perform
		    data0, data1 : in std_logic_vector(31 downto 0); --RS and RT
		    result: out std_logic_vector(31 downto 0); 
		    HI : out std_logic_vector(31 downto 0);
		    LO : out std_logic_vector(31 downto 0);
	    	zero : out std_logic
	);
end entity;

architecture behaviour of ALU is

	signal temp_result : std_logic_vector(31 downto 0);
	signal temp_HILO : std_logic_vector(63 downto 0);
	signal temp_zero : std_logic;
	signal temp_lui : std_logic_vector(32 downto 0);

begin

	result <= temp_result;
	HI <= temp_HILO (63 downto 32);
	LO <= temp_HILO (31 downto 0);
	zero <= temp_zero;

	ALU: process(clk)
	begin
		if(rising_edge(clk)) then
			temp_zero <= '0';

			case ALU_opcode is
				--add, addi
				when "0000" =>
					temp_result <= std_logic_vector(signed(data0) + signed(data1));

				--sub
				when "0001" =>
					temp_result <= std_logic_vector(signed(data0) - signed(data1));

				--mult
				when "0010" =>
					temp_HILO <= std_logic_vector(signed(data0) * signed(data1));
					
				--div
				when "0011" =>
					temp_HILO <= std_logic_vector(signed(data0) mod signed(data1)) & std_logic_vector(signed(data0) / signed(data0));

				--slt, slti
				when "0100" =>
					if (signed(data0) < signed(data1)) then
						temp_result <= '00000000000000000000000000000001';
					else
						temp_result <= '00000000000000000000000000000000';
					end if;

				--and, andi
				when "0101" =>
					temp_result <= data0 AND data1;
					
				--or, ori
				when "0110" =>
					temp_result <= data0 OR data1;

				--nor
				when "0111" =>
					temp_result <= data0 NOR data1;

				--xor, xori
				when "1000" =>
					temp_result <= data0 XOR data1;

				--mfhi
				when "1001" =>
					temp_result <= temp_HILO(63 downto 32);

				--mflo
				when "1010" =>
					temp_result <= temp_HILO(31 downto 0);

				--lui
				when "1011" =>
					

				--sll
				when "1100" =>
					temp_result <= std_logic_vector(signed(data0) sll signed(data1));

				--srl
				when "1101" =>
					temp_result <= std_logic_vector(signed(data0) srl signed(data1));

				--sra
				when "1110" =>
					temp_result <= std_logic_vector(signed(data0) sra signed(data1));

				when "1111" =>
					if (signed(data0) = signed(data1)) then
						temp_zero <= '1';
					else
						temp_zero <= '0';
					end if;

				when others =>
					temp_zero <= '0';
					temp_result <= 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'

			end case;

		result <= temp_result;
		zero <= temp_zero;

end behaviour;

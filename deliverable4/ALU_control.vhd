--********************************************************************
-- ECSE 425, Group 6
-- Kristin Lee (260509976)
-- Date: March 13, 2017

-- Description: ALU_control.vhd take as input opCode and funct from the
-- decode state and maps the appropriate code to the ALU

--********************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ALU_control is
  port( opCode : in std_logic_vector(5 downto 0);
  		funct : in std_logic_vector(5 downto 0);
  		ALU_out : out std_logic_vector(3 downto 0);
      );
end ALU_control;

architecture behaviour of ALU_control is

	signal temp_ALU_out : std_logic_vector(3 downto 0);

begin

	ALU_control_process : process(opCode, funct)
	begin

		case opCode is

			-- R type instruction
			when "000000" =>

				case funct is

					-- add
					when "100000" =>
						temp_ALU_out <= "0000";

					-- sub
					when "100010" =>
						temp_ALU_out <= "0001";

					-- mult
					when "011000" =>
						temp_ALU_out <= "0010";

					-- div
					when "011010" =>
						temp_ALU_out <= "0011";

					-- slt
					when "101010" =>
						temp_ALU_out <= "0100";					

					-- and
					when "100100" =>
						temp_ALU_out <= "0101";

					-- or
					when "100101" =>
						temp_ALU_out <= "0110";

					-- nor
					when "100111" =>
						temp_ALU_out <= "0111";

					-- xor
					--when "101000" => -- Aaron : xor should be "100110" instead of 101000
					when "100110" =>
						temp_ALU_out <= "1000";

					-- mfhi
					when "010000" =>
						temp_ALU_out <= "1001";

					-- mflo
					when "010010" =>
						temp_ALU_out <= "1010";

					-- sll
					when "000000" =>
						temp_ALU_out <= "1100";

					-- srl
					when "000010" =>
						temp_ALU_out <= "1101";

					-- sra
					when "000011" =>
						temp_ALU_out <= "1110";

					-- Aaron: Add jr
					when "001000" =>
						
						temp_ALU_out <= "";

					when others =>
						null;

				end case; -- end R type

			-- I type
			-- slti
			when "001010" =>
				temp_ALU_out <= "0100";

			-- andi
			when "001100" =>
				temp_ALU_out <= "0101";

			-- ori
			when "001101" =>
				temp_ALU_out <= "0110";

			-- xori
			when "001110" =>
				temp_ALU_out <= "1000";

			-- lui
			when "001111" =>
				temp_ALU_out <= "1011";

			-- beq
			when "000100" =>
				temp_ALU_out <= "1111";

			-- bne
			when "000101" =>
				temp_ALU_out <= "1111";

			-- sw Aaron: it should be sw instead of lw
			when "101011" =>
				temp_ALU_out <= "0000";

			-- lw Aaron: it should be lw instead of sw
			when "100011" =>
				temp_ALU_out <= "0000";

			when others =>
				null;

		end case;

	end process;

	ALU_out <= temp_ALU_out;
  
end behaviour;

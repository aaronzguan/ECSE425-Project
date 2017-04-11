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
		max_inst: in integer;
		s_addr_inst: out std_logic_vector(31 downto 0); -- send address to cache
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
begin

process (pc_plus4,Branch_taken)
begin
	if(rising_edge(Branch_taken)) and (insert_stall = '0') and (mem_data_stall = '0')then
		pc <= BranchAddr;
	elsif  (insert_stall = '0' and mem_data_stall = '0') then
		pc <= pc_plus4;               
	end if;
end process;

process(ismiss,s_waitrequest_inst,clock,Branch_taken)
begin
	if(insert_stall = '0' and mem_data_stall = '0') then
               if(rising_edge(Branch_taken)) then
                  s_addr_inst <= BranchAddr; 

                 end if;
	       if(rising_edge(clock)) then
	            s_read_inst <= '0';
                    if(ismiss = '0') then 
                     s_addr_inst <= pc; -- send the address to cache   
                     end if;
                end if;
		if(rising_edge(ismiss)) then
			inst <= x"00000020"; -- read miss, send 0+0=0 to ID
		elsif(falling_edge(clock) and ismiss = '1') then
			inst <= x"00000020"; -- read miss, send 0+0=0 to ID
		elsif(falling_edge(clock) and ismiss = '0' ) then
			pc_plus4 <= std_logic_vector(to_unsigned( to_integer(unsigned(pc)) + 4,32));
			next_addr <= pc;
			s_read_inst <= '1'; -- send the read signal to cache
			
			--end if;
		elsif (falling_edge(s_waitrequest_inst)) then -- IF can receive the results
	             if( to_integer(unsigned(pc)) > max_inst*4) then         
                        inst <= x"00000020";  
                     else  
                         inst <= s_readdata_inst; -- get instruction from cache
		      end if;	
		end if;
	end if;
end process;
end behavioral;

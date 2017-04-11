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
		s_addr_inst: out integer:=0; -- send address to cache
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
    signal one_delay:std_logic:='0';
    signal no_accept:std_logic:='0';
begin

process (pc_plus4,Branch_taken)
begin
	if(rising_edge(Branch_taken)) and (insert_stall = '0') and (mem_data_stall = '0')then
		pc <= BranchAddr;
	elsif  (insert_stall = '0' and mem_data_stall = '0' and pc_plus4'event ) then
		pc <= pc_plus4;               
	end if;
end process;

process(ismiss,s_waitrequest_inst,clock,Branch_taken,mem_data_stall)
begin
	if(insert_stall = '0' and mem_data_stall = '0') then
               if(rising_edge(Branch_taken)) then
                  s_addr_inst <= to_integer(unsigned( BranchAddr)); 

                 end if;
	       if(rising_edge(clock)) then
	            s_read_inst <= '0';
                   if(ismiss = '0') then 
                     s_addr_inst <=  to_integer(unsigned(pc)); -- send the address to cache   
                    end if;
                end if;
		--if(rising_edge(ismiss)) then
		--	inst <= x"00000020"; -- read miss, send 0+0=0 to ID
		if(falling_edge(clock) and ismiss = '1') then
			inst <= x"00000020"; -- read miss, send 0+0=0 to ID
		elsif(falling_edge(clock) and ismiss = '0' and one_delay = '0') then
			one_delay<= '1';
         elsif(falling_edge(clock) and one_delay = '1') then 
            inst <= x"00000020"; -- read miss, send 0+0=0 to ID
            pc_plus4 <= std_logic_vector(to_unsigned( to_integer(unsigned(pc)) + 4,32));
			next_addr <= pc;
			--if( to_integer(unsigned(pc)) < max_inst*4) then 
            s_read_inst <= '1'; -- send the read signal to cache
            one_delay <= '0';
			--end if;
		end if;
		end if;
        
        if(rising_edge(Branch_taken))then 
          no_accept <= '1';
       end if;
        if(falling_edge(mem_data_stall))then 
             one_delay <= '1';
          end if;
        
        if (falling_edge(s_waitrequest_inst)) then -- IF can receive the results
	             report "swr invoke this";
                 if( to_integer(unsigned(pc)) > max_inst*4 and one_delay ='0') then         
                        
                        inst <= x"00000020";  
                     elsif(no_accept ='1')then 
                           inst <= x"00000020";  
                           no_accept<= '0';
                         else
                         inst <= s_readdata_inst; -- get instruction from cache
		          end if;	
		end if;
	
end process;
end behavioral;

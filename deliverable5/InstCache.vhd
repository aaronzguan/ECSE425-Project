
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity InstCache is
generic(
	ram_size : INTEGER := 32768
);
port(
	clock : in std_logic;
	reset : in std_logic;
	
	-- Avalon interface --
	s_addr : in std_logic_vector (31 downto 0);
	s_read : in std_logic;
	s_readdata : out std_logic_vector (31 downto 0);
	--s_write : in std_logic;
	--s_writedata : in std_logic_vector (31 downto 0);
	s_waitrequest : out std_logic; 
    
	m_addr : out integer range 0 to ram_size-1;
	m_read : out std_logic;
	m_readdata : in std_logic_vector (7 downto 0);
	m_write : out std_logic;
	m_writedata : out std_logic_vector (7 downto 0);
	m_waitrequest : in std_logic

	--cachework : in std_logic := '0'
);
end InstCache;

architecture arch of InstCache is


        type cache_array is array (31 downto 0) of std_logic_vector(137 downto 0); --data is 127 downto 0, tag is 133 downto 128, flag is 135 downto 134
	
	signal cache: cache_array;
	signal addr_word_offset: std_logic_vector(1 downto 0); -- 2 bits word offset
	signal addr_byte_offset: std_logic_vector (1 downto 0); -- 2 bits byte offset
	signal addr_index: std_logic_vector(4 downto 0); -- 5 bits index
	signal addr_tag: std_logic_vector(5 downto 0); -- 6 bits tag
	signal block_tag: std_logic_vector(5 downto 0);

	signal index: integer range 0 to 31;
	signal valid: std_logic := '0';
	signal dirty: std_logic := '0';
	signal offset: integer range 0 to 3; 
	signal ref_counter : integer := 0;
	signal b_counter : integer := 0;
	--signal s_write_waitreq_reg: std_logic := '1';
	signal s_read_waitreq_reg: std_logic := '1';
	signal m_write_waitreq_reg: std_logic := '1';
	signal m_read_waitreq_reg: std_logic := '1';        

        
        signal m_address: integer range 0 to ram_size-1;
        signal mem_read: std_logic:= '0';
        signal mem_write: std_logic:='0';
        signal m_reading: std_logic:='0';
        signal m_writing: std_logic:='0';
        signal c_reading: std_logic:='0';
        signal c_writing: std_logic:='0';
        signal compare_tag: std_logic:='0';
 
begin

     	addr_word_offset <= s_addr(3 downto 2); -- word offset of address
	addr_byte_offset <= s_addr (1 downto 0); -- byte offset 
	addr_index <= s_addr(8 downto 4); -- index of address
	addr_tag <= s_addr(14 downto 9); -- tag of address
	index <= to_integer(unsigned(addr_index)); --index
	offset <= to_integer(unsigned(addr_word_offset)); --offset
        block_tag <= cache(index)(133 downto 128); -- tag bits of block
	valid <= cache(index)(135); -- valid bit of block
	dirty <= cache(index)(134); -- dirty bit of block

comp_tag_pro: process(clock,m_waitrequest,reset)
begin
	if(rising_edge(clock))then 
          	s_waitrequest <= '1';
          	m_read <= '0';
          	m_write <= '0';
      		if(s_read = '0') then 
		-- the state of idle, no request from cpu
            		compare_tag <= '0';
      		end if;

      		if (compare_tag= '0' and mem_read= '0' and mem_write= '0' and m_reading = '0' and m_writing = '0') then 
         		if (s_read = '1') then 
            			compare_tag<='1';
         		end if;
       
      		elsif(compare_tag = '1') then    
	-- the state of compare_tag, to decide if the data is hit or not, valid or not  
	-- if hit, then return the value; if not, pass it to write back or memory read accordlingly;
 
           		if(addr_tag = block_tag and valid = '1') then 
              		--hit <= '1';
		------------------ read instrution -------------------
              			if(s_read = '1') then 
                  		s_readdata <= cache(index)(32*(to_integer(unsigned(addr_word_offset)))+31 downto 32*(to_integer(unsigned(addr_word_offset))));
                  		c_reading <= '1'; 

				s_waitrequest <= '0';
		------------------ write instrution -------------------
				--elsif(s_write = '1') then
                  		--cache(index)(32*(to_integer(unsigned(addr_word_offset)))+31 downto 32*(to_integer(unsigned(addr_word_offset)))) <= s_writedata;
                  		--c_writing<='1';
                  		--cache(index)(134)<= '1';
              			end if;
           		else 
            			compare_tag <= '0';
             		-- hit <= '0';
           			if(dirty = '1')then         
               			mem_write <= '1'; 
           			else 
               			mem_read <= '1';   
           			end if;
          		end if;
            
      		elsif(mem_read = '1') then     
	-- the state of memory read, occured when miss, and read 4-words data from memory byte by byte. 
	-- after execute, it will be block until the memory access finished. After all data transfer is finished, pass the state to compare_tag
         		if(ref_counter = 4) then
           		ref_counter <= 0;              
           		compare_tag <= '1'; 
          		cache(index)(135)<='1';
         		cache(index)(134)<='0';
          		mem_read<='0'; 
           		cache(index)(133 downto 128)<=addr_tag;
        	 	else     
           		m_read <= '1';  
           		m_reading <='1';            
           		m_address <=((to_integer(unsigned(addr_tag))*512)+(to_integer(unsigned(addr_index))*16)+ref_counter*4+b_counter);	          
           		mem_read<='0'; 
        	 	end if; 
      
     		elsif(mem_write='1') then     
	-- state of write back, when a dirty miss occured, write all data in cache back to memory byte by byte. 
	-- after execute, it will be block until the memory access finished. After all data transfer is finished, pass the state to memory read;
           		if(ref_counter = 4) then
            		ref_counter <= 0;
            		mem_write<='0'; 
           		mem_read<='1';
          		else 
           		m_write<='1';
           		m_writing<='1';
            		m_address <=((to_integer(unsigned(block_tag))*512)+(to_integer(unsigned(addr_index))*16)+ref_counter*4+b_counter);
           		m_writedata<=cache (index) ((ref_counter*32 + b_counter*8 + 7) downto (ref_counter*32 + b_counter*8));
           		mem_write <= '0';
          		end if;
     		end if;
   	-- give the waitrequest signal to cpu, the falling edge of waitrequest stand for the finish of a read or write instruction
	--elsif(falling_edge(clock) and c_reading='1')then
       		--s_waitrequest <= '0';
       		--c_reading <= '0';
   	end if;

	--the process waiting for a memory read finish, if done, then add the offset and pass to memory_read
	if (falling_edge(m_waitrequest) and m_reading = '1') then
         	m_reading <= '0';
         	cache(index)(ref_counter*32+b_counter*8+7 downto ref_counter*32+b_counter*8)<= m_readdata;
         	mem_read <= '1';
       		if(b_counter = 3 ) then 
                	b_counter <=0;
                	ref_counter <= ref_counter+1;
        	else 
                	b_counter <= b_counter+1;
       		end if;

	--the process waiting for a write back finish, if done, then add the offset and pass to memory_write  
	elsif(falling_edge(m_waitrequest) and m_writing='1')then
         	m_writing <= '0';
         	mem_write <='1';
         	if(b_counter = 3 ) then 
                	b_counter <=0;
                	ref_counter <= ref_counter+1; 
         	else 
                	b_counter <= b_counter+1;
         	end if;  
      	end if;

	if(reset'event and reset = '1')then  -- reset operation 
        	mem_read<= '0';
        	mem_write<='0';
        	compare_tag<='0';
        	m_reading<='0';
        	m_writing<='0';
        	c_reading<='0';
        	c_writing<='0';
	end if;
end process;
 
m_addr<= m_address;

end arch;

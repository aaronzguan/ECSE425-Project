library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity DataCache is
generic(
	ram_size : INTEGER := 32
);
port(
	clock : in std_logic;
	reset : in std_logic;
	
	-- Avalon interface --
	s_addr : in std_logic_vector (31 downto 0);
	s_read : in std_logic;
	s_readdata : out std_logic_vector (31 downto 0);
	s_write : in std_logic;
	s_writedata : in std_logic_vector (31 downto 0);
	s_waitrequest : out std_logic; 
    
	m_addr : out integer range 0 to ram_size-1;
	m_read : out std_logic;
	m_readdata : in std_logic_vector (31 downto 0);
	m_write : out std_logic;
	m_writedata : out std_logic_vector (31 downto 0);
        --ismiss: out std_logic:='0';
	m_waitrequest : in std_logic

	--cachework : in std_logic := '0'
);
end DataCache;

architecture arch of DataCache is 


 type cache_array is array (31 downto 0) of std_logic_vector(135 downto 0); --data is 127 downto 0, tag is 133 downto 128, flag is 135 downto 134
	
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
	signal ref_counter1 : integer := 1;
        signal ref_counter2 : integer := 0;
	--signal b_counter : integer := 0;
	--signal s_write_waitreq_reg: std_logic := '1';
	--signal s_read_waitreq_reg: std_logic := '1';
	--signal m_write_waitreq_reg: std_logic := '1';
	--signal m_read_waitreq_reg: std_logic := '1';        

        
        signal m_address: integer range 0 to ram_size-1;
       
        signal s_readdata_temp: std_logic_vector(31 downto 0):=(others=>'0');
        signal s_waitrequest_temp: std_logic:='1';
        signal invoke_writeback: std_logic:='0';
        signal invoke_memread: std_logic:='0';
        signal m_writedata_temp: std_logic_vector(31 downto 0):=(others=>'0');
        --signal m_readdata_temp: std_logic_vector(31 downto 0); 
        signal m_addr_temp : integer:=0;
        signal m_read_temp : std_logic:='0';
        signal m_write_temp : std_logic:='0';
        signal wb_stage: std_logic:='0';
        signal mr_stage: std_logic:='0';
        signal wb_finish: std_logic:='0';
        signal mr_finish : std_logic:='0';
        signal mem_finish: std_logic:='0';
        signal wb_start: std_logic:='0';
        signal mr_start: std_logic:='0';   
        signal test : std_logic_vector(135 downto 0):=(others=>'0');
begin

        s_readdata <= s_readdata_temp;
        s_waitrequest <= s_waitrequest_temp;
        m_writedata<= m_writedata_temp;
        m_addr <= m_addr_temp;
        m_read<= m_read_temp;
        m_write<= m_write_temp;
        test<= cache(1);

     	addr_word_offset <= s_addr(3 downto 2); -- word offset of address
	--addr_byte_offset <= s_addr (1 downto 0); -- byte offset 
	addr_index <= s_addr(8 downto 4); -- index of address
	addr_tag <= s_addr(14 downto 9); -- tag of address
	index <= to_integer(unsigned(addr_index)); --index
	offset <= to_integer(unsigned(addr_word_offset)); --offset
        block_tag <= cache(index)(133 downto 128); -- tag bits of block
	valid <= cache(index)(135); -- valid bit of block
	dirty <= cache(index)(134); -- dirty bit of block

WBnMRstage: process(s_write, s_read, mem_finish, m_waitrequest, wb_start, mr_start, clock)
begin 

------------------- Initialize the Cache -------------------
	if (now < 1 ps) then 
        	report "cache is initialized";
            	for i in 0 to 31 LOOP
			cache(i) <=std_logic_vector(to_unsigned(0,136));
		end loop;
      	end if;
------------------------------------------------------------

---------------------- Hit or Miss? ------------------------
	if(rising_edge(s_read) or rising_edge(s_write) or rising_edge(mem_finish))then 
       		if(addr_tag = block_tag and valid = '1')then 
			if(s_read = '1')then
               			s_readdata_temp <= cache(index)(32*(to_integer(unsigned(addr_word_offset)))+31 downto 32*(to_integer(unsigned(addr_word_offset))));
			elsif (s_write = '1') then
				cache(index)(32*(to_integer(unsigned(addr_word_offset)))+31 downto 32*(to_integer(unsigned(addr_word_offset)))) <= s_writedata;
				cache(index)(134) <= '1';  -- set dirty
			end if;
               		s_waitrequest_temp <= '0'; 
       
       		else  
               		if(dirty = '1') then 
                   		invoke_writeback<= '1';
                	else 
                   		invoke_memread<= '1';
               		end if;
        
        	end if;
      	elsif(falling_edge(s_read) or falling_edge(s_write) or falling_edge(mem_finish)) then 
         	s_waitrequest_temp <= '1';
         	invoke_writeback <= '0';
         	invoke_memread <='0';
    	end if;
------------------------------------------------------------

----------------------- Write Back -------------------------
     	if(wb_stage = '1' and falling_edge(m_waitrequest)) then 
        	if(ref_counter1 = 4)then 
          		wb_finish <= '1';
          		ref_counter1 <= 1;
          		wb_stage <= '0';
          	else 
          		m_write_temp <= '1';
          		m_writedata_temp <= cache (index) (ref_counter1*32+31 downto ref_counter1*32);
          		m_addr_temp <=((to_integer(unsigned(block_tag))*512)+(to_integer(unsigned(addr_index))*16)+ref_counter1*4);
          		ref_counter1 <= ref_counter1+1;
        	end if;
     	elsif(wb_stage = '1' and rising_edge(m_waitrequest)) then 
           	m_write_temp <= '0';
           	wb_finish <= '0';
     	end if;
------------------------------------------------------------


----------------------- Memory Read -------------------------
	if(mr_stage = '1' and falling_edge(m_waitrequest)) then 
         	cache(index)(ref_counter2*32+31 downto ref_counter2*32)<= m_readdata;   ---- write to cache
        	if(ref_counter2 = 3)then 
          		mr_finish <= '1';
          		mr_stage <= '0'; 
          		ref_counter2 <= 0;
          		cache(index)(135)<= '1'; -- set valid
          		cache(index)(134)<= '0'; -- set dirty
			cache(index)(133 downto 128) <= addr_tag; -- set tag
         	else 
          		m_read_temp <= '1';
         		m_addr_temp <= ((to_integer(unsigned(addr_tag))*512)+(to_integer(unsigned(addr_index))*16)+(ref_counter2+1)*4);
          		ref_counter2 <= ref_counter2+1;
        	end if;
     	elsif(mr_stage = '1' and rising_edge(m_waitrequest)) then 
           	m_read_temp <= '0';
           	mr_finish <= '0';
      	end if;
------------------------------------------------------------

	if(rising_edge(wb_start))then 
         	m_writedata_temp <= cache (index) (31 downto 0);
         	m_write_temp<= '1';
         	m_addr_temp <=((to_integer(unsigned(block_tag))*512)+(to_integer(unsigned(addr_index))*16));
         	wb_stage<= '1'; 
	elsif(rising_edge(mr_start)) then 
         	m_read_temp<='1';
         	m_addr_temp <=((to_integer(unsigned(addr_tag))*512)+(to_integer(unsigned(addr_index))*16));
         	mr_stage <= '1';
	elsif(falling_edge(wb_start))then 
        	 m_write_temp <='0';
	elsif(falling_edge(mr_start))then 
        	m_read_temp <='0';
	end if;

end process;


memAccess: process(invoke_writeback, invoke_memread,wb_finish,mr_finish)
begin
    	if(rising_edge(invoke_writeback))then 
        	wb_start <= '1';
     	elsif(rising_edge(invoke_memread))then 
       	 	mr_start <= '1';
     	elsif(falling_edge(invoke_writeback))then 
        	wb_start <= '0';
    	 --  m_write_temp <='0';
     	elsif(falling_edge(invoke_memread)) then 
       		mr_start <= '0';    
     	-- m_read_temp<='0';
      	end if;

      	if(rising_edge(wb_finish)) then 
         	mr_start<= '1';
        elsif(rising_edge(mr_finish)) then
         	mem_finish<= '1';
      	elsif(falling_edge(wb_finish))then 
            	mr_start<= '0';
     	elsif(falling_edge(mr_finish))then 
             	mem_finish <= '0';       
       	end if;


end process;


end arch;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity registerFile is 

generic (
    width  :     positive := 32);
	
    port
    (
    q0       : out std_logic_vector(WIDTH-1 downto 0);
    q1       : out std_logic_vector(WIDTH-1 downto 0);
    d         : in  std_logic_vector(WIDTH-1 downto 0);
    wr  		  : in std_logic;
    rr0   : in std_logic_vector(4 downto 0);
    rr1   : in std_logic_vector(4 downto 0);
    rw	  : in std_logic_vector(4 downto 0);
    clk           : in std_logic;
    rst           : in std_logic
    );
end registerFile;

architecture behavioral of registerFile is

	type registerFile is array(0 to (WIDTH-1)) of std_logic_vector((WIDTH-1) downto 0);
	signal registers : registerFile;

begin
	process (rst,clk) is
	
	begin
	if (rst = '1') then 		
	  for i in 0 to 31 loop				  
		registers(i) <=(others =>'0');
	  end loop;
	  
	elsif (rising_edge(clk)) then
			-- Write and bypass
		if wr = '1' then
			if(unsigned(rw) /= 0) then
				registers(to_integer(unsigned(rw))) <= d;  -- Write
			end if;
		end if;
    end if;
	
  end process;
  
  -- Read A and B before bypass
	q0 <= registers(to_integer(unsigned(rr0)));
	q1 <= registers(to_integer(unsigned(rr1)));
  
end behavioral;
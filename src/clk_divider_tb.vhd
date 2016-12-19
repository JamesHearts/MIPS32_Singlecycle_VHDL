library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity clk_divider_tb is
end clk_divider_tb;

architecture TB of clk_divider_tb is
	
	signal clk_n : std_logic;
	signal mem_clk_en : std_logic;
	
  
begin  -- TB

  UUT : entity work.clk_divider
    port map (
		clk => clk_n,
		mem_clk_en => mem_clk_en
	);
	
  -- toggle clock
  Clk_n <= not Clk_n after 20 ns;

  process
	
  begin
	
	wait for 500ns;
	
	wait;
  end process;
end TB;
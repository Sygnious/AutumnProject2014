library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity incrementer is
	generic(n: integer := 32);
	port (
		opt : in std_logic;
		inputValue: in std_logic_vector(n-1 downto 0);
		
		result: out std_logic_vector(n-1 downto 0)
		);
end incrementer;

architecture arch of incrementer is
begin
	change : process(inputValue, opt)
	begin
		if opt = '0' then
			result <= inputValue + '1';
		else 
			result <= inputValue - '1';
		end if;
	end process;
end arch;
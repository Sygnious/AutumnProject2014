library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity countCheck is
	generic(n: integer := 32);
	port (
		-- Input from counter
		count: in std_logic_vector(n-1 downto 0);
		
		-- Resulting output
		result: out std_logic
		);
end countCheck;

architecture arch of countCheck is
begin
	check : process(count)
	begin
		if count>0 then
			result <= '1';
		else 
			result <= '0';
		end if;
	end process;
	
end arch;
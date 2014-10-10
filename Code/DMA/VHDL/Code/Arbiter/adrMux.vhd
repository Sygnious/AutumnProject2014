library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity adrMux is
	generic(n: integer := 34; -- Two extra bits to determine difference between load, store and intterupt. Must be recognized by the output handler. 
			m: integer := 3);
	port (
		opt: in std_logic_vector(m-1 downto 0);
		interruptInput: out std_logic_vector(n-1 downto 0);
		storeInput0: in std_logic_vector(n-1 downto 0);
		storeInput1: in std_logic_vector(n-1 downto 0);
		loadInput0: in std_logic_vector(n-1 downto 0);
		loadInput1: in std_logic_vector(n-1 downto 0)
		
		adrOutput : out std_logic_vector(n-1 downto 0)
	);
end adrMux;

architecture arch of adrMux is
begin
	select : process (opt)
	begin
		case opt is
			when "000" => dataOut <= interruptInput;
			when "001" => dataOut <= storeInput0;
			when "010" => dataOut <= storeInput1;
			when "011" => dataOut <= loadInput0;
			when "100" => dataOut <= loadInput1;
			when others => dataOut <= (m-1 downto 0) => '-'; -- Should not happen, except of external uses of input don't cares
		end case;
	end process;
end arch;
library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity sharedBuffer is
	generic(
		n: integer := 32
	);
	port (
		-- Clock
		clk : in std_logic;
		-- Input from data input handler, or data FIFO queue (not yet decided)
		set : in std_logic; -- Activates setting counter, final load address, final store address (and mode)
		dataIn : in std_logic_vector(n-1 downto 0);
		loadIDIn : in std_logic_vector(n-1 downto 0);
		
		-- Input from channels
		loadIDCheck0 : in std_logic_vector(n-1 downto 0);
		loadIDCheck1 : in std_logic_vector(n-1 downto 0);
		
		-- Output to channels
		rdy0 : out std_logic;
		rdy1 : out std_logic;
		
		-- Output to arbiter
		dataOut : out std_logic_vector(n-1 downto 0)
		
		);
end sharedBuffer;

architecture arch of sharedBuffer is
	
	-- Registers:
	data : std_logic_vector(n-1 downto 0);
	loadID : std_logic_vector(n-1 downto 0);
	
begin
	
	setNext : process(clk, set, dataIn, LoadIDIn)
	begin
		if rising_edge(clk) then
			if set = '1' then
				data <= dataIn;
				loadID <= loadIDIn;
			end if;
		end if;
	end procesS;
	
	compare : process(loadIDCheck0, loadIDCheck1)
	begin
		if loadIDCheck0 = loadID then
			rdy0 <= '1';
			rdy1 <= '0';
		elsif loadIDCheck1 = loadID then
			rdy0 <= '0';
			rdy1 <= '1';
		else 
			rdy0 <= '0';
			rdy1 <= '0';
		end if;
	end process;
	
	dataOut <= data;
	
end arch;



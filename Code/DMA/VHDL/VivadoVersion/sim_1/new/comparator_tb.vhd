-- Purpose with test: To make sure arbiter controller sets the correct output signals as expected, in the input range of 000000 - 1111111 - 000000
-- Test is used to uncover any error that may arise


library ieee;
use ieee.std_logic_1164.all;

	-- Add your library and packages declaration here ...

entity loadIDComparator_tb is
end loadIDComparator_tb;

architecture TB_ARCHITECTURE of arbiterController_tb is
	-- Component declaration of the tested unit
	component loadIDComparator
	-- Input from fifo						   
            loadIDIn : in std_logic_vector(n-1 downto 0);
            
            -- Input from channels
            loadIDCheck0 : in std_logic_vector(n-1 downto 0);
            loadIDCheck1 : in std_logic_vector(n-1 downto 0);
            
            -- Output to channels
            rdy0 : out std_logic;
            rdy1 : out std_logic    
	end component;

	-- Stimulus signals - signals mapped to the input and inout ports of tested entity
	
	-- Observed signals - signals mapped to the output ports of tested entity
	signal loadIDIn : std_logic_vector(n-1 downto 0) := (n-1 downto 0 => '0');
	signal loadIDCheck0  : std_logic_vector(n-1 downto 0) := (n-1 downto 0 => '0');
	signal loadIDCheck1  : std_logic_vector(n-1 downto 0) := (n-1 downto 0 => '0');
	signal rdy0 : std_logic := '0';
	signal rdy1 :  std_logic := '0';
	
	constant clock_period : time := 10 ns;
begin
	
	-- Unit Under Test port map
	UUT : loadIDComparator
		port map (
		  loadIDIn => loadIDIn,
		  loadIDCheck0 => loadIDCheck0,
		  loadIDCheck1 => loadIDCheck1,
		  rdy0 => rdy0,
		  rdy1 => rdy1
		
		);

	
	STIMULUS : process
	begin
    loadIDIn <= "11110000111100001111000011110000";
    
    wait for clock_period * 4;
    
    loadIDCheck0 <= "11110000111100001111000011110000";
    
    wait for clock_period * 2;
    
    loadIDCheck0 <= "11001100110011001100110011001100";
    
    wait for clock_period * 2;
    
    loadIDIn <= "11111111000000001111111100000000";
    
    wait for clock_period * 4;
	
	loadIDCheck1 <= "11111111000000001111111100000000";
		
	wait for clock_period * 2;
	
	loadIDIn <= "11001100110011001100110011001100";
	
	wait for clock_period * 2;
	
	loadIDCheck0 <= "11111111111111110000000000000000";
	
	wait for clock_peroid * 2;
	
	loadIDIn <= "11111111111111110000000000000000";
		
		
	wait;
	
	end process;
end TB_ARCHITECTURE;

--configuration TESTBENCH_FOR_controller of controller_tb is
	--for TB_ARCHITECTURE
		--for UUT : aController
			--use entity work.controller(controller);
			--end for;
		--end for;
	--end TESTBENCH_FOR_controller;


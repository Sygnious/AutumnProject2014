-- Purpose with test: To make sure that load channel is set when set = '1', and that it decrements with changing address when ack = '1'


library ieee;
use ieee.std_logic_1164.all;

	-- Add your library and packages declaration here ...

entity loadChannel_tb is
end loadChannel_tb;

architecture TB_ARCHITECTURE of loadChannel_tb is
	-- Component declaration of the tested unit
	component loadChannel
	port(
		-- INPUTS
		clk : in std_logic;
	
		set : in std_logic; 
		LModeIn : in std_logic; 
		FLAIn: in std_logic_vector(n-1 downto 0); 
		countIn: in std_logic_vector(m-1 downto 0); 
	
	
		loadAck : in std_logic; -- Receives ACK signal from arbiter, load data now goes through and counter is decremented
	
		-- OUTPUTS
		loadActive : out std_logic; -- Load Channel is active, may be used by DMA Main Controller to determine if a channel is active.
		
		loadAdrOut : out std_logic_vector(n-1 downto 0); -- Current load address
		loadReq : out std_logic -- Request signal to arbiter to pass through load data
		);
		
	end component;

	-- Stimulus signals - signals mapped to the input and inout ports of tested entity
	signal clk : STD_LOGIC := 0;

	-- All inputs 
	signal FLAInput : std_logic_vector(31 downto 0) := "00000000000000001111000000000000"; --61440, Excepted start: 61420, 00000000000000001110111111101100
	signal CountInput : std_logic_vector(31 downto 0) := "00000000000000000000000000010100"; -- 20
	signal LModeInput : std_logic := '1'; -- Currently always same mode in channels, manSubtractor is set to '1' in current implementation
	signal set : std_logic := '0';
	signal ack : std_logic := '0';
	
	
	-- Observed signals - signals mapped to the output ports of tested entity
	signal loadActive : std_logic;
	signal loadAdrOut : std_logic_vector(2+(n-1) downto 0);
	signal loadReq : std_logic;
	
	constant clock_period : time := 10 ns;
	
begin
	
	-- Unit Under Test port map
	UUT : loadChannel
		port map (
			clk => clk,
			set => set,
			LModeIn => LModeInput,
			FLAIn => FLAInput,
			countIn => CountInput,
			loadAck => ack,
			
			loadActive => loadActive,
			loadAdrOut => loadAdrOut,
			loadReq => loadReq
		);

	-- Add your stimulus here ...
	CLOCK_SYNTHESIS : process
    begin
        clk <= '1';
        wait for clock_period/2;
        clk <= '0';
        wait for clock_period/2;
    end process;
	
	STIMULUS : process
	begin
		
		wait for clock_period*4;
		
		set <= '1'; -- First set the input

		-- Keep setting for 4 cycles, to see that loadReq does not set to '1' before set is done
		wait for clock_period*4;
		
		-- Set it done, channel should now request output.
		set <= '0';
		
		wait for clock_period*4;
		
		-- Channel receives ack from arbiter. Lasts for 6 cycles
		ack <= '1';
		
		wait for clock_period*6;
		
		-- Another priority gets the arbiter (store or interrupt), lasts for 6 cycles.
		ack <= '0';
		
		wait for clock_period*6;
		
		-- Channel gets back the access. Lasts for 15 cycles (counter should reach zero by then)
		ack <= '1';
		
		wait for clock_period*15;
		
		-- Waiting some additional cycles, just to make sure that there are no output req-signal (arbiter usually sets ack to '0' at this point)
		
		wait for clock_peroid*2;
		ack <=  '0';
		
		-- DONE
		
	end process;
end TB_ARCHITECTURE;

--configuration TESTBENCH_FOR_controller of controller_tb is
	--for TB_ARCHITECTURE
		--for UUT : aController
			--use entity work.controller(controller);
			--end for;
		--end for;
	--end TESTBENCH_FOR_controller;


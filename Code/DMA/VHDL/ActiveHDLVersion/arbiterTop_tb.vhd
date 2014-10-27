-- Purpose with test: Similar to arbiterController_tb by testing inputs and outputs based on requests. The addition is to see which data and adr goes in and out as well.
-- Input reqs and ack signals should be known from arbiterController_tb, so this test should verify that correct data and store/load addresses / interrupt codes goes through.
-- Load, store and interrupt inputs to the adrMux are static, while data input is incrementing by one for each clock cycle.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

	-- Add your library and packages declaration here ...

entity arbiterTop_tb is
end arbiterTop_tb;

architecture TB_ARCHITECTURE of arbiterTop_tb is
	-- Component declaration of the tested unit
	component arbiterTop
	port(
	
		clk : in STD_LOGIC;
 	
		blockReq : in std_logic;
		interruptReq : in std_logic;
		storeReq0: in std_logic;
		storeReq1: in std_logic;
		loadReq0: in std_logic;
		loadReq1: in std_logic;
	
		data_in : in STD_LOGIC_VECTOR(31 downto 0);
	
		interruptInput : in std_logic_vector(33 downto 0);
		storeInput0: in std_logic_vector(33 downto 0);
		storeInput1: in std_logic_vector(33 downto 0);
		loadInput0: in std_logic_vector(33 downto 0);
		loadInput1: in std_logic_vector(33 downto 0);
	
		interruptAck : out std_logic;
		storeAck0 : out std_logic;
		storeAck1 : out std_logic;
		loadAck0 : out std_logic;
		loadAck1 : out std_logic;
	
		adrOut : out std_logic_vector(33 downto 0);
		dataOut : out std_logic_vector(31 downto 0)
	);
	end component;

	-- Stimulus signals - signals mapped to the input and inout ports of tested entity
	signal clk : STD_LOGIC := '0';

	-- All req inputs summed into one signal
	signal allReqInputs : std_logic_vector(5 downto 0) := "000000";
	
	signal data_input : std_logic_vector(31 downto 0) := "00000000000000111100000000000000";
	
	signal interruptInput : std_logic_vector(33 downto 0) := "1100000000000011111111111111111111";
	signal storeInput0 : std_logic_vector(33 downto 0) := "0110100100000001000010000110000000";
	signal storeInput1 : std_logic_vector(33 downto 0) := "0110000000000000010011111110000000";
	signal loadInput0 : std_logic_vector(33 downto 0) := "0010111111111111111111111111000000";
	signal loadInput1 : std_logic_vector(33 downto 0) := "0010000000000000000000000000011111";
	
	-- Observed signals - signals mapped to the output ports of tested entity
	signal interruptAck : std_logic;
	signal storeAck0 : std_logic;
	signal storeAck1 : std_logic;
	signal loadAck0 : std_logic;
	signal loadAck1 :  std_logic;
	
	signal adrOut : std_logic_vector(33 downto 0);
	signal dataOut : std_logic_vector(31 downto 0);
	
	constant clock_period : time := 10 ns;
	
begin
	
	-- Unit Under Test port map
	UUT : arbiterTop
		port map (
		clk => clk,
		blockReq => allReqInputs(5),
		interruptReq => allReqInputs(4),
		storeReq0 => allReqInputs(3),
		storeReq1 => allReqInputs(2),
		loadReq0 => allReqInputs(1),
		loadReq1 => allReqInputs(0),
		
		data_in => data_input,
		
		interruptInput => interruptInput,
		storeInput0 => storeInput0,
		storeInput1 => storeInput1,
		loadInput0 => loadInput0,
		loadInput1 => loadInput1,
		
		interruptAck => interruptAck,
		storeAck0 => storeAck0,
		storeAck1 => storeAck1,
		loadAck0 => loadAck0,
		loadAck1 => loadAck1,
		
		adrOut => adrOut,
		dataOut => dataOut
		);

	-- Add your stimulus here ...
	CLOCK_SYNTHESIS : process
    begin
        clk <= '1';
		data_input <= std_logic_vector( unsigned(data_input) + 1 );
        wait for clock_period/2;
        clk <= '0';
        wait for clock_period/2;
    end process;
	
	STIMULUS : process
	begin

		-- Note: Except for stores, dataOut should be "00000000000000000000000000000000"

		-- Part 1: 000000-111111
		-- Begin
		allReqInputs <= "000000";
		wait for clock_period*10;
		
		-- Load1
		allReqInputs <= "000001";
		wait for clock_period*2;
		
		-- Load0
		allReqInputs <= "000010";
		wait for clock_period*2;
		
		-- Both Loads, load1 and load0. Load1 wins, then alternate for each clock cycle
		allReqInputs <= "000011";
		wait for clock_period*4;
		
		-- Store1. Prioritized above any load requests. dataOpt should be '1'
		allReqInputs <= "000100";
		wait for clock_period*2;
		
		allReqInputs <= "000101";
		wait for clock_period*2;
		
		allReqInputs <= "000110";
		wait for clock_period*2;
		
		allReqInputs <= "000111";
		wait for clock_period*2;
		
		-- Store0, prioritized above any load requests. dataopt should be '1'
		
		allReqInputs <= "001000";
		wait for clock_period*2;
		
		allReqInputs <= "001001";
		wait for clock_period*2;
		
		allReqInputs <= "001010";
		wait for clock_period*2;
		
		allReqInputs <= "001011";
		wait for clock_period*2;
		
		-- Both store0 and store1. Any load requests are ignoered. Output alternates between store0 and store1 for each cycle. dataopt should be '1'
		-- NOTE: Both store should never occur in common buffer system in channels, but test may prove useful for private buffer system.
		
		allReqInputs <= "001100";
		wait for clock_period*2;
		
		allReqInputs <= "001101";
		wait for clock_period*2;
		
		allReqInputs <= "001110";
		wait for clock_period*2;
		
		allReqInputs <= "001111";
		wait for clock_period*2;
		
		-- Interrupt request. Any store or load requests are ignored.
		
		allReqInputs <= "010000";
		wait for clock_period*2;
		
		allReqInputs <= "010001";
		wait for clock_period*2;
		
		allReqInputs <= "010010";
		wait for clock_period*2;
		
		allReqInputs <= "010011";
		wait for clock_period*2;
		
		allReqInputs <= "010100";
		wait for clock_period*2;
		
		allReqInputs <= "010101";
		wait for clock_period*2;
		
		allReqInputs <= "010110";
		wait for clock_period*2;
		
		allReqInputs <= "010111";
		wait for clock_period*2;
		
		allReqInputs <= "011000";
		wait for clock_period*2;
		
		allReqInputs <= "011001";
		wait for clock_period*2;
		
		allReqInputs <= "011010";
		wait for clock_period*2;
		
		allReqInputs <= "011011";
		wait for clock_period*2;
		
		allReqInputs <= "011100";
		wait for clock_period*2;
		
		allReqInputs <= "011101";
		wait for clock_period*2;
		
		allReqInputs <= "011110";
		wait for clock_period*2;
		
		allReqInputs <= "011111";
		wait for clock_period*2;
		
		-- Blocking request. Everything else is ignored. All output are set to zero (not allowing access to any channels or DMA main controller).
		
		allReqInputs <= "100000";
		wait for clock_period*2;
		
		allReqInputs <= "100001";
		wait for clock_period*2;
		
		allReqInputs <= "100010";
		wait for clock_period*2;
		
		allReqInputs <= "100011";
		wait for clock_period*2;
		
		allReqInputs <= "100100";
		wait for clock_period*2;
		
		allReqInputs <= "100101";
		wait for clock_period*2;
		
		allReqInputs <= "100110";
		wait for clock_period*2;
		
		allReqInputs <= "100111";
		wait for clock_period*2;
		
		allReqInputs <= "101000";
		wait for clock_period*2;
		
		allReqInputs <= "101001";
		wait for clock_period*2;
		
		allReqInputs <= "101010";
		wait for clock_period*2;
		
		allReqInputs <= "101011";
		wait for clock_period*2;
		
		allReqInputs <= "101100";
		wait for clock_period*2;
		
		allReqInputs <= "101101";
		wait for clock_period*2;
		
		allReqInputs <= "101110";
		wait for clock_period*2;
		
		allReqInputs <= "101111";
		wait for clock_period*2;
		
		allReqInputs <= "110000";
		wait for clock_period*2;
		
		allReqInputs <= "110001";
		wait for clock_period*2;
		
		allReqInputs <= "110010";
		wait for clock_period*2;
		
		allReqInputs <= "110011";
		wait for clock_period*2;
		
		allReqInputs <= "110100";
		wait for clock_period*2;
		
		allReqInputs <= "110101";
		wait for clock_period*2;
		
		allReqInputs <= "110110";
		wait for clock_period*2;
		
		allReqInputs <= "110111";
		wait for clock_period*2;
		
		allReqInputs <= "111000";
		wait for clock_period*2;
		
		allReqInputs <= "111001";
		wait for clock_period*2;
		
		allReqInputs <= "111010";
		wait for clock_period*2;
		
		allReqInputs <= "111011";
		wait for clock_period*2;
		
		allReqInputs <= "111100";
		wait for clock_period*2;
		
		allReqInputs <= "111101";
		wait for clock_period*2;
		
		allReqInputs <= "111110";
		wait for clock_period*2;
		
		allReqInputs <= "111111";
		wait for clock_period*2;
		
		-- Done with part 1. Now have a break, before part 2
		
		allReqInputs <= "000000";
		
		wait for clock_period*10;
		
		-- Part 2: 111111-000000
		
		-- Blocking
		allReqInputs <= "111111";
		wait for clock_period*2;
		
		allReqInputs <= "111110";
		wait for clock_period*2;
		
		allReqInputs <= "111101";
		wait for clock_period*2;
		
		allReqInputs <= "111100";
		wait for clock_period*2;
		
		allReqInputs <= "111011";
		wait for clock_period*2;
		
		allReqInputs <= "111010";
		wait for clock_period*2;
		
		allReqInputs <= "111001";
		wait for clock_period*2;
		
		allReqInputs <= "111000";
		wait for clock_period*2;
		
		allReqInputs <= "110111";
		wait for clock_period*2;
		
		allReqInputs <= "110110";
		wait for clock_period*2;
		
		allReqInputs <= "110101";
		wait for clock_period*2;
		
		allReqInputs <= "110100";
		wait for clock_period*2;
		
		allReqInputs <= "110011";
		wait for clock_period*2;
		
		allReqInputs <= "110010";
		wait for clock_period*2;
		
		allReqInputs <= "110001";
		wait for clock_period*2;
		
		allReqInputs <= "110000";
		wait for clock_period*2;
		
		allReqInputs <= "101111";
		wait for clock_period*2;
		
		allReqInputs <= "101110";
		wait for clock_period*2;
		
		allReqInputs <= "101101";
		wait for clock_period*2;
		
		allReqInputs <= "101100";
		wait for clock_period*2;
		
		allReqInputs <= "101011";
		wait for clock_period*2;
		
		allReqInputs <= "101010";
		wait for clock_period*2;
		
		allReqInputs <= "101001";
		wait for clock_period*2;
		
		allReqInputs <= "101000";
		wait for clock_period*2;
		
		allReqInputs <= "100111";
		wait for clock_period*2;
		
		allReqInputs <= "100110";
		wait for clock_period*2;
		
		allReqInputs <= "100101";
		wait for clock_period*2;
		
		allReqInputs <= "100100";
		wait for clock_period*2;
		
		allReqInputs <= "100011";
		wait for clock_period*2;
		
		allReqInputs <= "100010";
		wait for clock_period*2;
		
		allReqInputs <= "100001";
		wait for clock_period*2;
		
		allReqInputs <= "100000";
		wait for clock_period*2;
		
		-- Interrupt signal active
		
		allReqInputs <= "011111";
		wait for clock_period*2;
		
		allReqInputs <= "011110";
		wait for clock_period*2;
		
		allReqInputs <= "011101";
		wait for clock_period*2;
		
		allReqInputs <= "011100";
		wait for clock_period*2;
		
		allReqInputs <= "011011";
		wait for clock_period*2;
		
		allReqInputs <= "011010";
		wait for clock_period*2;
		
		allReqInputs <= "011001";
		wait for clock_period*2;
		
		allReqInputs <= "011000";
		wait for clock_period*2;
		
		allReqInputs <= "010111";
		wait for clock_period*2;
		
		allReqInputs <= "010110";
		wait for clock_period*2;
		
		allReqInputs <= "010101";
		wait for clock_period*2;
		
		allReqInputs <= "010100";
		wait for clock_period*2;
		
		allReqInputs <= "010011";
		wait for clock_period*2;
		
		allReqInputs <= "010010";
		wait for clock_period*2;
		
		allReqInputs <= "010001";
		wait for clock_period*2;
		
		allReqInputs <= "010000";
		wait for clock_period*2;
		
		-- Both store signals active
		
		allReqInputs <= "001111";
		wait for clock_period*2;
		
		allReqInputs <= "001110";
		wait for clock_period*2;
		
		allReqInputs <= "001101";
		wait for clock_period*2;
		
		allReqInputs <= "001100";
		wait for clock_period*2;
		
		-- Store0 active, store1 inactive
		
		allReqInputs <= "001011";
		wait for clock_period*2;
		
		allReqInputs <= "001010";
		wait for clock_period*2;
		
		allReqInputs <= "001001";
		wait for clock_period*2;
		
		allReqInputs <= "001000";
		wait for clock_period*2;
		
		-- Store0 inactive, store1 active
		
		allReqInputs <= "000111";
		wait for clock_period*2;
		
		allReqInputs <= "000110";
		wait for clock_period*2;
		
		allReqInputs <= "000101";
		wait for clock_period*2;
		
		allReqInputs <= "000100";
		wait for clock_period*2;
		
		-- Both loads, for 4 cycles
		
		allReqInputs <= "000011";
		wait for clock_period*4;
		
		-- Load0
		allReqInputs <= "000010";
		wait for clock_period*2;
		
		-- Load1
		allReqInputs <= "000001";
		wait for clock_period*2;
		
		-- No inputs
		allReqInputs <= "000000";
		
		-- END TEST
		
		
	end process;
end TB_ARCHITECTURE;

--configuration TESTBENCH_FOR_controller of controller_tb is
	--for TB_ARCHITECTURE
		--for UUT : aController
			--use entity work.controller(controller);
			--end for;
		--end for;
	--end TESTBENCH_FOR_controller;


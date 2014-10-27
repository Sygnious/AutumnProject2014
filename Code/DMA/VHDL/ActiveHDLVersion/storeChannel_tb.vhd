-- Purpose with test: To make sure that store channel is set when set = '1', and that it decrements with changing address when ack = '1'


library ieee;
use ieee.std_logic_1164.all;

	-- Add your library and packages declaration here ...

entity storeChannel_tb is
end storeChannel_tb;

architecture TB_ARCHITECTURE of storeChannel_tb is
	-- Component declaration of the tested unit
	component storeChannel
	port(
		-- INPUTS
		clk : in std_logic;
		
		set : in std_logic; 
		SModeIn : in std_logic; 
		FLAIn: in std_logic_vector(31 downto 0); 
		FSAIn: in std_logic_vector(31 downto 0); 
		countIn: in std_logic_vector(31 downto 0);
		
		dataRdy : in std_logic;
		
		storeAck : in std_logic; 
		
		-- OUTPUT
		storeActive : out std_logic;
		
		loadAdrOut : out std_logic_vector(31 downto 0); 
		
		storeAdrOut : out std_logic_vector(33 downto 0); 
		storeReq : out std_logic 
		);
		
	end component;

	-- Stimulus signals - signals mapped to the input and inout ports of tested entity
	signal clk : STD_LOGIC := '0';

	-- All inputs 
	signal FLAInput : std_logic_vector(31 downto 0) := "00000000000000001111000000000000"; --61440, Excepted start: 61420, 00000000000000001110111111101100
	signal FSAInput : std_logic_vector(31 downto 0) := "11001100110011001100110011001100"; --6871947672, Excepted start: 6871947652, 110011001100110011001100110000100
	signal CountInput : std_logic_vector(31 downto 0) := "00000000000000000000000000010100"; -- 20
	signal SModeInput : std_logic := '1'; -- Currently always same mode in channels, manSubtractor is set to '1' in current implementation
	signal set : std_logic := '0';
	signal ack : std_logic := '0';
	signal rdy : std_logic := '0';
	
	
	-- Observed signals - signals mapped to the output ports of tested entity
	signal storeActive : std_logic;
	signal loadAdrOut : std_logic_vector(31 downto 0);
	signal storeAdrOut  : std_logic_vector(33 downto 0);
	signal storeReq : std_logic;
	
	constant clock_period : time := 10 ns;
	
begin
	
	-- Unit Under Test port map
	UUT : storeChannel
		port map (
			clk => clk,
			set => set,
			SModeIn => SModeInput,
			FLAIn => FLAInput,
			FSAIn => FSAInput,
			countIn => CountInput,
			storeAck => ack,
			dataRdy => rdy,
			
			storeActive => storeActive,
			loadAdrOut => loadAdrOut,
			storeAdrOut => storeAdrOut,
			storeReq => storeReq
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
		
		-- NOTE: storeAck should never be '1' when dataRdy is '0', since ack='1' should only be returned when requesting arbiter access.
		-- Storechannel does NEVER request arbiter access when dataRdy = '0'. For this test we assume that all data from the shared buffer belongs to the same channel.
		
		wait for clock_period*4;
		
		set <= '1'; -- First set the input

		-- Keep setting for 4 cycles, to see that loadReq does not set to '1' before set is done
		wait for clock_period*4;
		
		-- Set it done, channel should now request output.
		set <= '0';
		
		wait for clock_period*4;
		
		-- We assume that all data from data buffer corresponds to the current data needed by store channel. Rdy will stay at '1' until counter reaches zero
		rdy <= '1';
		-- Channel receives ack from arbiter. Lasts for 6 cycles
		
		ack <= '1';
		
		wait for clock_period*6;
		
		-- Another priority gets the arbiter (interrupt), lasts for 6 cycles.
		ack <= '0';
		
		wait for clock_period*6;
		
		-- Channel gets back the access. Lasts for 15 cycles (counter should reach zero by then)
		ack <= '1';
		
		wait for clock_period*15;
		
		rdy <=  '0';
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


-- Purpose with test: Test the twoChannelSetUp by running both channels. 
-- Both channels 0 and 1 are set for running, set at separate times

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

	-- Add your library and packages declaration here ...

entity twoChannelSetUpMono_tb is
end twoChannelSetUpMono_tb;

architecture TB_ARCHITECTURE of twoChannelSetUpMono_tb is
	-- Component declaration of the tested unit
	component twoChannelSetUp
		generic(
		n: integer := 32; -- Sets data and addresses
		m: integer := 32; -- Sets count
		i: integer := 34
		);
		port (
			-- Clock & reset
			clk : in std_logic;
			reset : in std_logic;
			-- Input from DMA Main Controller, to channels
			set0 : in std_logic; -- Used to select and set channel 0
			set1 : in std_logic; -- Used to select and set channel 1
			modeIn : in std_logic; -- Sets mode in selected channel
			FLAIn : in std_logic_vector(n-1 downto 0); -- Sets FLAs i selected channel
			FSAIn : in std_logic_vector(n-1 downto 0); -- Sets FSA in selected channel
			countIn : in std_logic_vector(m-1 downto 0); -- Sets counter in selected channel
			-- Input from DMA Main Controller, directly to arbiter
			interruptReq : in std_logic; -- Requests arbiter for access
			interruptCmd : in std_logic_vector(i-1 downto 0); -- Contains details of interrupt to the arbiter
		
			-- Input from system to data buffer
			dataIn : in std_logic_vector(n-1 downto 0); -- Next data
			loadIDIn : in std_logic_vector(n-1 downto 0); -- Next data's loadID
			pushData : in std_logic;
		
			-- Input from system to arbiter (assumingly from an output buffer that may get overfed of data)
			blockArbiter : in std_logic;
		
			-- Output from arbiter
			detailsOutput : out std_logic_vector(i-1 downto 0); -- Interrupt details, store cmd + address, or load cmd + address
			dataOutput : out std_logic_vector(n-1 downto 0);	-- Data for store cmd, or just 0's
		
			-- Output from channels to DMA Main Controller
			active0 : out std_logic;
			active1 : out std_logic;
		
			interruptAck : out std_logic -- Ack signal to the DMA Controller from arbiter
			);
		end component;

	-- Stimulus signals - signals mapped to the input and inout ports of tested entity
	signal clk : STD_LOGIC := '0';
	signal reset : std_logic := '0';
	
	
	-- All inputs 
	signal FLAInput : std_logic_vector(31 downto 0) := "00000000000000001111000000000000"; --61440, Excepted start: 61400, 00000000000000001110111111011000
	signal FSAInput : std_logic_vector(31 downto 0) := "11001100110011001100110011001100"; --6871947672, Excepted start: 6871947652, 110011001100110011001100110000100
	signal countInput : std_logic_vector(31 downto 0) := "00000000000000000000000000101000"; -- 40
	signal modeInput : std_logic := '1'; -- Currently always same mode in channels, manSubtractor is set to '1' in current implementation
	signal set0 : std_logic := '0';
	signal set1 : std_logic := '0'; -- Not used
	
	signal interruptReq : std_logic :='0';
	signal interruptCmd : std_logic_vector(33 downto 0) := "1111111111111111111111111111111111"; -- Details used statically for this test. Easily recognizable
	
	signal data : std_logic_vector (31 downto 0) := "00000000000000001111000000000000"; -- Beginning data with value 61440, increment with 8 for each input 
	signal nextData0 : std_logic_vector (31 downto 0) := "00000000000000001111000000001000"; 
	signal nextData1 : std_logic_vector (31 downto 0) := "11111111000111100000000000000000";
	signal loadID : std_logic_vector (31 downto 0) :="00000000000000001110111111011000"; -- Begins at same as FLAInput-count for Channel 0
	signal nextID0 : std_logic_vector (31 downto 0) := "00000000000000001110111111011001"; 
	signal nextID1 : std_logic_vector (31 downto 0) := "00001111000000000000000000000000"; -- 983040
	signal push : std_logic := '0'; --Remember to use push for every new data
	
	
	signal blockArbiter : std_logic := '0';
	
	-- Observed signals - signals mapped to the output ports of tested entity
	signal detailsOutput :  std_logic_vector(33 downto 0); -- Interrupt details, store cmd + address, or load cmd + address
	signal dataOutput : std_logic_vector(31 downto 0);
	
	signal active0 : std_logic;
	signal active1 : std_logic;
	signal interruptAck : std_logic;
	
	
	-- Test-related signal
	signal ch1 : std_logic := '0';
	constant clock_period : time := 10 ns;
	
begin
	
	-- Unit Under Test port map
	UUT : twoChannelSetUp
		port map (
			-- INPUTS
			clk => clk,
			reset => reset,
			set0 => set0,
			set1 => set1,
			ModeIn => modeInput,
			FLAIn => FLAInput,
			FSAIn => FSAInput,
			countIn => CountInput,
			
			interruptReq => interruptReq,
			interruptCmd => interruptCmd,
			
			dataIn => data,
			loadIDIn => loadID,
			pushData => push,
			
			blockArbiter => blockArbiter,
			
			-- OUTPUTS
			detailsOutput => detailsOutput,
			dataOutput => dataOutput,
			
			active0 => active0,
			active1 => active1,
			interruptAck => interruptAck
									
 
			
		);

	-- Add your stimulus here ...
	CLOCK_SYNTHESIS : process
    begin
        clk <= '1';
        wait for clock_period/2;
        clk <= '0';
        wait for clock_period/2;
    end process;
	
	
	
	-- DIFFERENCE FROM MONO TEST: ch1 decides which channel data input is next
	updateNextDataDuo : process(clk, push, ch1,  nextData0, nextData1, nextID0, nextID1)
	begin	  
		if rising_edge(clk) then
			if push ='1' then
				if ch1 = '1' then  
					data<=nextData1;
					nextData1<=std_logic_vector(unsigned(nextData1)+8);-- Increment next data with "1000" or 8 
					loadID <= nextID1;
					nextID0 <= std_logic_vector(unsigned(nextID1)+1); -- Increment next data with 1	
				else 
					data<=nextData0;
					nextData0<=std_logic_vector(unsigned(nextData0)+8);-- Increment next data with "1000" or 8 
					loadID <= nextID0;
					nextID0 <= std_logic_vector(unsigned(nextID0)+1); -- Increment next data with 1	
				end if;
				
			else
				-- nothing
			end if;
		else
			--nothing
		end if;
	end process;
	
	
	STIMULUS : process
	begin
																																  
		
		
		
		-- Test will run by initiating channel 0 after 4 cycles.
		-- Channel 1 will be initiated after 16 cycles.
		-- FLA, FSA and Count inputs for channel 0 are already set by using default values for the input signals in this test
		  
		
		-- PLAN:
		-- 4 cycles with no activity, the setting channel 0
		-- 8 cycles with loads from channel 0
		-- 5 cycles with stores from channel 0
		-- 3 more cycles with loads from channel 0
		-- Channel 1 is set. Loads will alternate
		-- 10 cycles of alternate loads (5 cycles for each (currently at end: 16 for channel 0, 5 for channel 1)
		-- Then 3 cycles with stores for channel 0 (alternate not an option)
		-- Then 2 cycles with stores for channel 1
		-- Then 5 more cycles with stores for channel 0, with an test interrupt from DMA main controller
		-- Then 32 cycles for alternate loads, to finish loads for channel 1 (which has 15+1 counts left) (currently at end: 31, 20)
		-- Receive 5 stores for channel 1, then 6 for channel 0, then 14 for channel 1. Channel 1 is now finished
		-- Finish loads for channel 0 (make it 15 cycles)
		-- Finish stores for channel 0 (should be 23 cycles (40-18 + 1))
			
		-- DONE
		
		
		wait for clock_period*4;
		
		-- Setting channel 0.
		set0 <= '1';
		
		wait for clock_period;
		
		set0 <= '0';
		
		wait for clock_period*7;
		
		push <= '1'; -- Remember, storing begins ONE cycle after push is set
		
		wait for clock_period*5;
		
		push <= '0';
		
		wait for clock_period*3;
		
		FSAInput <= "11000000000011110000000000010100";
		FLAInput <= "00000000000011110000000000010100";	--983060
		countInput <= "00000000000000000000000000010100"; -- 20
		
		set1 <='1';
		wait for clock_period;
		set1 <= '0';
		
		-- First 10 cycles of alternation
		
		--Then stores: 3 for channel 0, 2 for channel 1, then 5 more for channel 0 with DMA interrupt included (FIFO buffer should compensate)
		wait for clock_period*9;
		push <='1';
		wait for clock_period*3;
		ch1<='1';
		wait for clock_period*2;
		ch1<='0';
		wait for clock_period*3;
		interruptReq <= '1';
		wait for clock_period;
		interruptReq <= '0';
		wait for clock_period;
		push <='0';
		wait for clock_period * 33; -- Two clock cycles to empty data buffer, then 32 more to finish loading from channel 1 (including push next cycles;
		push <='1';
		ch1 <= '1';
		wait for clock_period * 5;
		ch1 <= '0';
		wait for clock_period * 6;
		ch1 <='1';
		wait for clock_period * 14;	
		ch1 <='0';					 -- Channel 1 finished
		push <= '0';
		
		-- Finish loading channel 0
		
		wait for clock_period*15;
		
		push <='1';
		
		wait for clock_period * 23;
		push <= '0';
		
		wait;
		
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


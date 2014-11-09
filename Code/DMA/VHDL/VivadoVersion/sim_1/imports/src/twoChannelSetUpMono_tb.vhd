-- Purpose with test: Test the twoChannelSetUp by running only one channel. Channel0 is set for a job, and data inputs corresponding to the load addresses are fed by the test itself

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

	-- Add your library and packages declaration here ...

entity twoChannelSetUpMono_tb is
end twoChannelSetUpMono_tb;

architecture TB_ARCHITECTURE of twoChannelSetUpMono_tb is
	-- Component declaration of the tested unit
	component twoChannelSetUp
		--generic(
		--n: integer := 32; -- Sets data and addresses
		--m: integer := 32; -- Sets count
		--i: integer := 34
		--);
		port (
			-- Clock & reset
			clk : in std_logic;
			reset : in std_logic;
			-- Input from DMA Main Controller, to channels
			set0 : in std_logic; -- Used to select and set channel 0
			set1 : in std_logic; -- Used to select and set channel 1
			modeIn : in std_logic; -- Sets mode in selected channel
			--FLAIn : in std_logic_vector(n-1 downto 0); -- Sets FLAs i selected channel
			--FSAIn : in std_logic_vector(n-1 downto 0); -- Sets FSA in selected channel
			--countIn : in std_logic_vector(m-1 downto 0); -- Sets counter in selected channel
			FLAIn : in std_logic_vector(31 downto 0); -- Sets FLAs i selected channel
            FSAIn : in std_logic_vector(31 downto 0); -- Sets FSA in selected channel
            countIn : in std_logic_vector(31 downto 0); -- Sets counter in selected channel
			-- Input from DMA Main Controller, directly to arbiter
			interruptReq : in std_logic; -- Requests arbiter for access
			--interruptCmd : in std_logic_vector(i-1 downto 0); -- Contains details of interrupt to the arbiter
		    interruptCmd : in std_logic_vector(33 downto 0); -- Contains details of interrupt to the arbiter
		
			-- Input from system to data buffer
			--dataIn : in std_logic_vector(n-1 downto 0); -- Next data
			--loadIDIn : in std_logic_vector(n-1 downto 0); -- Next data's loadID
			dataIn : in std_logic_vector(31 downto 0); -- Next data
            loadIDIn : in std_logic_vector(31 downto 0); -- Next data's loadID
			pushData : in std_logic;
		
			-- Input from system to arbiter (assumingly from an output buffer that may get overfed of data)
			blockArbiter : in std_logic;
		
			-- Output from arbiter
			--detailsOutput : out std_logic_vector(i-1 downto 0); -- Interrupt details, store cmd + address, or load cmd + address
			--dataOutput : out std_logic_vector(n-1 downto 0);	-- Data for store cmd, or just 0's
		    detailsOutput : out std_logic_vector(33 downto 0); -- Interrupt details, store cmd + address, or load cmd + address
            dataOutput : out std_logic_vector(31 downto 0);    -- Data for store cmd, or just 0's
		    
		    -- Output from system to receiving buffer at bus system
            storeOutput : out std_logic;
		      
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
	signal FLAInput : std_logic_vector(31 downto 0) := "00000000000000001111000000000000"; --61440, Excepted start: 61420, 00000000000000001110111111101100
	signal FSAInput : std_logic_vector(31 downto 0) := "11001100110011001100110011001100"; --6871947672, Excepted start: 6871947652, 110011001100110011001100110000100
	signal countInput : std_logic_vector(31 downto 0) := "00000000000000000000000000010100"; -- 20
	signal modeInput : std_logic := '1'; -- Currently always same mode in channels, manSubtractor is set to '1' in current implementation
	signal set0 : std_logic := '0';
	signal set1 : std_logic := '0'; -- Not used
	
	signal interruptReq : std_logic :='0';
	signal interruptCmd : std_logic_vector(33 downto 0) := "1111111111111111111111111111111111"; -- Details used statically for this test. Easily recognizable
	
	signal data : std_logic_vector (31 downto 0) := "00000000000000001111000000000000"; -- Beginning data with value 61440, increment with 8 for each input 
	signal nextData : std_logic_vector (31 downto 0) := "00000000000000001111000000001000";
	signal loadID : std_logic_vector (31 downto 0) :="00000000000000001110111111101100"; -- Begins at same as FLAInput-count for Channel 0
	signal nextID : std_logic_vector (31 downto 0) :="00000000000000001110111111101101";
	signal push : std_logic := '0'; --Remember to use push for every new data
	
	
	signal blockArbiter : std_logic := '0';
	
	-- Observed signals - signals mapped to the output ports of tested entity
	signal detailsOutput :  std_logic_vector(33 downto 0); -- Interrupt details, store cmd + address, or load cmd + address
	signal dataOutput : std_logic_vector(31 downto 0);
	signal storeOutput : std_logic;
	
	signal active0 : std_logic;
	signal active1 : std_logic;
	signal interruptAck : std_logic;
	
	
	-- Test-related signal
	--signal overrideUpdate : std_logic; -- Used to manually set input loadID and nextLoadID. Also used to set buffer inside channel if active during a clk cycle
	--signal secondID : std_logic_vector(31 downto 0) := "00000000000000000000000000000000"; -- Address used when overrideUpdate Used with 
	
	constant clock_period : time := 10 ns;
	
begin
	
	-- Unit Under Test port map
	UUT : twoChannelSetUp
	  -- generic map(
	  --     n => 32,
	 --      m => 32,
	  --     i => 34
	   
	  -- );
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
	
	
	updateNextData : process(clk, push, interruptReq, nextData, nextID)
	--updateNextData : process(clk, overrideUpdate, nextDataReq, interruptReq, nextData, nextID, secondID)
	begin
		--if overrideUpdate = '1' then -- Should stay for a full cycle, so that the override updates databuffer inside the channel setup as well
		--	loadID <= secondID;
		--	nextID <= std_logic_vector(unsigned(secondID)+1); 
		--elsif rising_edge(clk) then
		if rising_edge(clk) then
			if push ='1' then
			data<=nextData;
			nextData<=std_logic_vector(unsigned(nextData)+8);-- Increment next data with "1000" or 8 
			loadID <= nextID;
			nextID <= std_logic_vector(unsigned(nextID)+1); -- Increment next data with 1
			else
				-- nothing
			end if;
		else
			--nothing
		end if;
	end process;
	
	
	STIMULUS : process
	begin
		
		-- Test will run by initiating channel 0 after 4 cycles
		-- FLA, FSA and Count inputs are already set by using default values for the input signals in this test
		-- No relevant Load data arrives until after 6 futher cycles (will be set by using the push signal)
		
		-- PLAN:
		-- 4 cycles with no activity, the setting channel 0
		-- 4 cycles with load only, then interrupting from DMA Main controller for 1 cycle, then load for 2 more cycles
		-- 5 cycles with stores, with an interrupt after 2 and setting nextID input to something else in number 5
		-- 13 cycles of loads
		-- 7 cycles of waits
		-- Cycle of setting loadID input, simulating the next sets of data
		-- 15 cycles of stores
		-- DONE
		
		
		wait for clock_period*4;
		
		-- Setting channel 0.
		set0 <= '1';
		
		wait for clock_period;
		
		set0 <= '0';
		
		-- Loading data for 4 cycles
		wait for clock_period * 4;
		
		-- Sending interrupt request from DMA Main controller for 1 cycle
		interruptReq <= '1';
		
		wait for clock_period;
		
		-- Load for 2 more cycles (two next clock periods in test, including setting push)
		interruptReq <= '0';
		wait for clock_period;
					
		-- Stores will last for 5 cycles, by having push at 5 cycles. A store will happen at cycle n if there is a push at cycle n-1
		push <= '1';			 
		
		wait for clock_period*2;
		interruptReq <= '1';
		wait for clock_period;
		interruptReq<='0';
		wait for clock_period*2;
		push <= '0';
								
		
		-- No load data arrives for a while. The 13 next cycles are used to send out final store of the 5, then 13 remaining loads. 
		-- Then nothing happens for 7 more cycles
		
		wait for clock_period*23;
		
		-- Now the 15 remaining packs of data arrives.
		push <= '1';
		wait for clock_period * 16;
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


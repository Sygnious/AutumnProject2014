-- Purpose with test: Make sure pop-signal reaches through adapter to DMA Controller together with correct data. Make sure pop-signals are generated at correct moments

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

	-- Add your library and packages declaration here ...

entity adapter_tb is
end adapter_tb;

architecture TB_ARCHITECTURE of adapter_tb is
	-- Component declaration of the tested unit
	component adapter
		port (
			clk : in std_logic;         
            emptyIn : in std_logic;     
            reqUpdateIn : in std_logic; 
                                    
            popOut : out std_logic;     
            requestOut : out std_logic  
		);
		end component;

	-- Stimulus signals - signals mapped to the input and inout ports of tested entity
	signal clk : STD_LOGIC := '0';
	signal emptyIn : std_logic := '1'; --NOTE: Notice that empty in begins with '1' as default. FIFO begins empty
	signal reqUpdate : std_logic := '0';
	signal popOut : std_logic;
	signal requestOut : std_logic;
	
	-- Test-related signal
	
	constant clock_period : time := 10 ns;
	-- transferalData is used to emulate data transfer between FIFO and DMA. Does not go through the adapter, but correct pop should give correct update
	-- For this test, value will be incremented by 1 for each pop
	signal transferalData : std_logic_vector (31 downto 0) := (31 downto 0 => '0'); 
begin
	
	-- Unit Under Test port map
	UUT : adapter
		port map (
			-- INPUTS
			clk => clk,
			emptyIn => emptyIn,
			reqUpdateIn => reqUpdate,
			popOut => popOut,
			requestOut => requestOut
		);

	-- Add your stimulus here ...
	CLOCK_SYNTHESIS : process
    begin
        clk <= '1';
        wait for clock_period/2;
        clk <= '0';
        wait for clock_period/2;
    end process;
	
	updateNextData : process(clk, popOut)
	begin
	   if rising_edge(clk) then
			if popOut ='1' then
			transferalData <= std_logic_vector(unsigned(transferalData)+1);
			else
				-- nothing
			end if;
		else
			--nothing
		end if;
	end process;
	
	
	STIMULUS : process
	begin
		-- In this test, correct data must arrive together with the request signal (orinigally based on NOT empty) to the DMA Controller.
		-- In such, the signal itself must be delayed by at least a clock cycle (data arrive at next, if pop is generated).
		-- The adapter must also ensure that FIFO is popped correctly. For instance, last data from FIFO is popped,
		-- then it must not be popped again after the DMA controller is done with the job. The empty-signal from the FIFO will help ensure that
		-- Pops will thus be generated from Adapter. There will be automatically a pop for the first FIFO output, 
		-- and the rest of the pops happens when DMA controller signalizes the ARBITER that it has processed the request + data and the next may be popped
		
		-- In summary: Delay request signals so that it reaches DMA controller TOGETHER with the next popped data
		--             AND pop only when the FIFO is not empty
		
		--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-- STEP 1: Test with only one request, the DMA state machine processes immediatlby
		
		wait for clock_period * 10;
		
		emptyIn <= '0'; -- Poprequest should occur
		
		wait for clock_period;
		
		emptyIn <= '1'; -- First pop-signal should have been generated from the adapter, without any requestUpdate signal
		reqUpdate <= '1'; -- Immediate process
		
		wait for clock_period;
		reqUpdate <= '0';
		
		wait for clock_period * 10;
		
		
		--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-- STEP 2: Test with only one request, with both DMA channels occupied for some cycles when request arrives.
		
		emptyIn <= '0';
		
		wait for clock_period;
		emptyIn <= '1'; -- First pop-signal should have been generated from the adapter, withougt any requestUpdate signal
		
		-- Assume that DMA state Machine may process request after 5 cycles
		wait for clock_period * 5;
		
		reqUpdate <= '1';
		
		wait for clock_period;
		
		reqUpdate <= '0';
		
		wait for clock_period * 10;
		
		
		--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-- STEP 3: Multiple requests. Assume that DMA controller processes the 2 first, while the 2 next are processed with cylces in between.
		-- 4 requests used in this step (meaning 4 reqUpdates from controller). There shall be 4 pops, and ONLY 4 pops
		
		emptyIn <= '0';
		
		wait for clock_period;
		-- First pop-signal at this point
		reqUpdate <= '1'; 
		
		wait for clock_period * 2; -- 2 first requests dealt with from DMA-state machine, causing 2nd and 3rd pop-signal
		
		reqUpdate <= '0';
		
		wait for clock_period * 5;
		
		reqUpdate <= '1'; -- 3rd request processed. Final pop-signal is sent out at this point
		wait for clock_period;
		reqUpdate <= '0';
		emptyIn <= '1'; -- 4 pops, final FIFO outpub, FIFO is empty
		
		wait for clock_period * 5;
		
		reqUpdate <= '1'; -- 4th and final request processed. There will be no pop-signal. Interal register will be set to 0.
		wait for clock_period; 
		reqUpdate <= '0';
		
		wait for clock_period * 5;
		
		
		
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


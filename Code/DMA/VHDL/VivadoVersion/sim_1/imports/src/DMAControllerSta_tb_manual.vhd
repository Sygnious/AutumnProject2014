-- Purpose with test: Test out DMAMainControllerSta, by giving different sets of inputs

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

	-- Add your library and packages declaration here ...

entity DMAControllerSta_tb_manual is
end DMAControllerSta_tb_manual;

architecture TB_ARCHITECTURE of DMAControllerSta_tb_manual is
	-- Component declaration of the tested unit
	component DMAControllerSta
	port(
		   -- INPUTS
		-- Clock
		clk : in STD_LOGIC;
		reset : in std_logic;							   						
		-- From Request buffer
		req : in std_logic; -- New data ready from request buffer
		reqDetails : in std_logic_vector(31 downto 0);	-- Details, including requestor ID, count, mode
		loadDetails : in std_logic_vector(31 downto 0); -- Beginning load address
		storeDetails : in std_logic_vector(31 downto 0); -- Beginning store address
		-- From channels
		activeCh0 : in std_logic; -- Channel 0 signals active
		activeCh1 : in std_logic; -- Channel 1 signals active
		-- From arbiter
		interruptAck : in std_logic;	 -- Access to interrupt output granted
		
		-- OUTPUTS
		-- To request buffer
		reqUpdate : out std_logic; --Signals buffer that data is read, and to prepare next data
		-- To Channels
		set0 : out std_logic; -- Set channel 0
		set1 : out std_logic; -- Set channel 1
		FLAOut : out std_logic_vector (31 downto 0); -- Final Load Address to channels
		FSAOut : out std_logic_vector (31 downto 0); -- Final Store Address to channels
		counterOut : out std_logic_vector (31 downto 0); -- Output to counter
		--LModeOut : out std_logic;	-- Set to 1 for this project
		--SModeOut : out std_logic; -- Set to 1 for this project
		-- To arbiter
		interruptReq : out std_logic;
		interruptDetails : out std_logic_vector(33 downto 0)
	);
	end component;

	-- Stimulus signals - signals mapped to the input and inout ports of tested entity
	signal clk : STD_LOGIC := '0';
	signal reset : std_logic := '0';
											  
	signal req : std_logic := '0';
	signal reqDetails : std_logic_vector(31 downto 0) := (31 downto 0 => '0');	
	signal loadDetails : std_logic_vector(31 downto 0) := (31 downto 0 => '0');
	signal storeDetails : std_logic_vector(31 downto 0) := (31 downto 0 => '0');
	
	signal activeCh0 : std_logic := '0'; 
	signal activeCh1 : std_logic := '0'; 

	signal interruptAck : std_logic := '0';
	   
	-- Observed signals - signals mapped to the output ports of tested entity
	signal reqUpdate : std_logic := '0';
	
	signal set0 : std_logic :='0'; -- Set channel 0
	signal set1 : std_logic :='0'; -- Set channel 1
	signal FLAOut : std_logic_vector (31 downto 0) := (31 downto 0 => '0'); -- Final Load Address to channels
	signal FSAOut : std_logic_vector (31 downto 0) := (31 downto 0 => '0'); -- Final Store Address to channels
	signal counterOut : std_logic_vector (31 downto 0) := (31 downto 0 => '0');
	
	signal interruptReq : std_logic := '0';
	signal interruptDetails : std_logic_vector(33 downto 0) := (33 downto 0 => '0');
	
	-- Signals for the test itself
	constant clock_period : time := 10 ns;
	signal overrideReset : std_logic :=	'0'; -- Used to override the auto-setters


begin
	
	-- Unit Under Test port map
	UUT : DMAControllerSta
		port map (
		-- INPUTS
		clk => clk,
		reset => reset,
		
		req => req,
		reqDetails => reqDetails,
		loadDetails => loadDetails,
		storeDetails => storeDetails,
		
		activeCh0 => activeCh0,
		activeCh1 => activeCh1,
		
		interruptAck => interruptAck,
		
		-- OUTPUTS
		reqUpdate => reqUpdate,
		
		set0 => set0,
		set1 => set1,
		FLAOut => FLAOut,
		FSAOut => FSAOut,
		counterOut => counterOut,
		
		interruptReq => interruptReq,
		interruptDetails => interruptDetails
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
		
		-- Step 1: First test one request only.
		-- Step 2: Then test one more request, but with delayed interrupt-ack from arbiter (To make sure FSM behaves as expected if such case arises)
		-- Step 3: Test two input requests, separated by some cycles.
		-- Step 4: Same as test two, but channels finish in reverse order
		-- Step 5 :Then test three requests, with some cycles between each.
		-- (PROCESSING => WAITING (due to req = 0) => PROCESSING =>	WAITING (due to req = 0, then due to full channels
		--  => INTERRUPT => PROCESSING (finally, a channel was free) => Continue until done (Two more interrupts)
		-- Step 6: Same as step 5, but with differnet order of finished channels
		-- Step 7: Finally, test two instant requests: PROCESSING => PROCESSING => Then WAITING
		-- Step 8: Same as step 7, but with 3 instant requests instead of 2
		-- Step 9: Test two simultaneous finishes
		-- Step 10: Test two simultaneous finishes, with delay from output arbiter in between
		--wait for 2 ns;
		
		-- NOTE: 30 cycles between each steps
		reset <= '1';
		wait for clock_period * 5;
		
		reset <= '0';
		reqDetails <= "00000000100011001110000011111111";
		-- (Count = 8 (counting not relevant for this test, Active-signals from channels are manually controlled).
		-- (ID = 1100111)
		loadDetails <= "00000000111111110000000011111111"; -- Starting address (16711935). Expected FLA: 00000000111111110000000100000111 (16711935)
		storeDetails <= "00000000000000000000111100001110";	-- Starting address (3854). Expected FSA:00000000000000000000111100010110 (3862)
		
		wait for clock_period * 25;
		----------------------------------------------------------------------------------------------------------------------------------------------------------------------
		
		-- GO: Step 1: Test one request
		
		req <= '1'; -- Activate DMAMainController, with one request (req set to 0 after first request, in process resetReq)
		wait for clock_period;
		activeCh0 <= '1'; -- Remember, as long as a channel is free, it will be set the cycle after the request is received. Channel 0 is set
		req <= '0';
		
		
		wait for clock_period * 10;
		
		-- Channel 0 is done
		activeCh0 <= '0';
		wait for clock_period; 
		interruptAck <= '1'; -- Interruptrequest is sent out the next cycle after a channel is done. Until anything else is specified, assume immediate ack-signal from arbiter 
		wait for clock_period;
		interruptAck <= '0';
		
		
		wait for clock_period * 30;
		----------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-- Step 2: Test one request, but with delay in interruptAck signal
		req <= '1'; 
        wait for clock_period;       
        activeCh0 <= '1'; 
        req <= '0';                       
        wait for clock_period * 10;  
                                     
        activeCh0 <= '0';            
        wait for clock_period * 10; -- Ack Delayed by 10 cycles       
        interruptAck <= '1'; 
        wait for clock_period;       
        interruptAck <= '0';         
        wait for clock_period * 30;  
		----------------------------------------------------------------------------------------------------------------------------------------------------------------------
		
		-- Step 3: test two requests, but with delays between the requests.
		
		-- Once again, activate
		req <= '1';
		wait for clock_period;
		activeCh0 <= '1';
		req <= '0';
		wait for clock_period * 10;
		
		-- Send in one more request while channel 0 is working. Change reqID in reqDetails
		reqDetails <= "00000000100010000010000011111111"; -- ID = 1000001;
		req <= '1';
        wait for clock_period;
        activeCh1 <= '1';
        req <= '0';
        wait for clock_period * 10;
               
		-- Finish channel 1 first
		
		activeCh1 <= '0';
		wait for clock_period;
		interruptAck <= '1';
		wait for clock_period;
		interruptAck <= '0';
		
		wait for clock_period * 10;
		
		-- Finish channel 0
		
		activeCh0 <= '0';      
        wait for clock_period; 
        interruptAck <= '1';   
        wait for clock_period; 
        interruptAck <= '0';   
		
		wait for clock_period * 30;
		----------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-- Step 4: Same as step 3, but the channels finish in reverse order, compared to step 3
		reqDetails <= "00000000100011001110000011111111"; -- ID = 1100111						
		req <= '1';                                                                        
        wait for clock_period;                                                             
        activeCh0 <= '1';                                                                  
        req <= '0';                                                                        
        wait for clock_period * 10;                                                        
                                                                                           
        -- Send in one more request while channel 0 is working. Change reqID in reqDetails 
        reqDetails <= "00000000100010000010000011111111"; -- ID = 1000001;                 
        req <= '1';                                                                        
        wait for clock_period;                                                       
        activeCh1 <= '1';                                                            
        req <= '0';                                                                  
        wait for clock_period * 10;                                                  
                                                                                           
        -- Finish channel 0 INSTEAD OF channel 1 first                                                         
                                                                                           
        activeCh0 <= '0';                                                                  
        wait for clock_period;                                                             
        interruptAck <= '1';                                                               
        wait for clock_period;                                                             
        interruptAck <= '0';                                                               
                                                                                           
        wait for clock_period * 10;                                                        
                                                                                           
        -- Now finish channel 1                                                               
                                                                                           
        activeCh1 <= '0';                                                                  
        wait for clock_period;                                                       
        interruptAck <= '1';                                                         
        wait for clock_period;                                                       
        interruptAck <= '0';                                                         
            
		wait for clock_period * 30;
		
		----------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-- Step 5: Three requests, with cycles in between each request
		reqDetails <= "00000000100011001110000011111111"; -- ID = 1100111						
		req <= '1';
		wait for clock_period;
		activeCh0 <= '1';
		req <= '0';
		
		wait for clock_period * 10;
		
		-- Send in one more request while channel 0 is working. Change reqID in reqDetails
		
		reqDetails <= "00000000100010000010000011111111"; -- ID = 1000001
		req <= '1';
		wait for clock_period;
		activeCh1 <= '1';
		req <= '0';
		
		wait for clock_period * 10;
		
		-- Now send in third request
		
		reqDetails <= "00000000100011111110000011111111"; -- ID = 1111111
		req <= '1';
		wait for clock_period * 10;
		
		
		-- Finish channel 1 first
		
		activeCh1 <= '0';
		wait for clock_period;
		interruptAck <= '1';
		wait for clock_period;
		interruptAck <= '0'; -- At this point, third request is handled
		req <= '0';
		activeCh1 <= '1';
		
		wait for clock_period * 10;
		
		-- Finish channel 1 again
		
		activeCh1 <= '0';
		wait for clock_period;
		interruptAck <= '1';
		wait for clock_period;
		interruptAck <= '0';
		
		wait for clock_period * 10;
		
		-- Now finish channel 0
		
		activeCh0 <= '0';
		wait for clock_period;
		interruptAck <= '1';
		wait for clock_period;
		interruptAck <= '0';
		
		wait for clock_period * 30;
		 
		----------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-- Step 6: Same as step 5, but channels finish in different order                       
        reqDetails <= "00000000100011001110000011111111"; -- ID = 1100111                                         
        req <= '1';                                                                             
        wait for clock_period;                                                                  
        activeCh0 <= '1';                                                                       
        req <= '0';                                                                             
                                                                                                
        wait for clock_period * 10;                                                             
                                                                                                
        -- Send in one more request while channel 0 is working. Change reqID in reqDetails      
                                                                                                
        reqDetails <= "00000000100010000010000011111111"; -- ID = 1000001                       
        req <= '1';                                                                             
        wait for clock_period;                                                                  
        activeCh1 <= '1';                                                                       
        req <= '0';                                                                             
                                                                                                
        wait for clock_period * 10;                                                             
                                                                                                
        -- Now send in third request                                                            
                                                                                                
        reqDetails <= "00000000100011111110000011111111"; -- ID = 1111111                       
        req <= '1';                                                                             
        wait for clock_period * 10;                                                             
                                                                                                
                                                                                                
        -- Finish channel 0 first INSTEAD OF channel 1                                                                
                                                                                                
        activeCh0 <= '0';                                                                       
        wait for clock_period;                                                                  
        interruptAck <= '1';                                                                    
        wait for clock_period;                                                                   
        interruptAck <= '0'; -- At this point, third request is handled                         
        req <= '0';                                                                             
        activeCh0 <= '1';                                                                       
                                                                                                
        wait for clock_period * 10;                                                             
                                                                                                
        -- Finish channel 0 agin                                                        
                                                                                                
        activeCh0 <= '0';                                                                       
        wait for clock_period;                                                                  
        interruptAck <= '1';                                                                    
        wait for clock_period;                                                                  
        interruptAck <= '0';                                                                    
                                                                                                
        wait for clock_period * 10;                                                             
                                                                                                
        -- Now finish channel 1                                                                 
                                                                                                
        activeCh1 <= '0';                                                                       
        wait for clock_period;                                                                  
        interruptAck <= '1';                                                                    
        wait for clock_period;                                                                  
        interruptAck <= '0';                                                                    
                                                                                                
        wait for clock_period * 30;                                                             
		
		----------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-- Step 7: Test two instant requests
		
		reqDetails <= "00000000100011001110000011111111"; -- ID = 1100111						
		req <= '1';
		
		wait for clock_period; -- Next data in next cycle
		activeCh0 <= '1';
		reqDetails <= "00000000100010000010000011111111"; -- ID = 1000001
		
		wait for clock_period;
		activeCh1 <= '1';
		req <= '0';
		
		wait for clock_period * 8;
		
		-- Finish channel 1
		
		activeCh1 <= '0';
		wait for clock_period;
		interruptAck <= '1';
		wait for clock_period;
		interruptAck <= '0';
		
		wait for clock_period * 10;
		
	   -- Finish channel 0
		
		activeCh0 <= '0';
		wait for clock_period;
		interruptAck <= '1';
		wait for clock_period;
		interruptAck <= '0';
							
		wait for clock_period * 30;							   
		----------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-- Step 8: Test 3 input requests intead of 2
		
		reqDetails <= "00000000100011001110000011111111"; -- ID = 1100111						
		req <= '1';
		
		wait for clock_period; -- Next data in next cycle
		activeCh0 <= '1';
		reqDetails <= "00000000100010000010000011111111"; -- ID = 1000001
		wait for clock_period;
		activeCh1 <= '1';
		reqDetails <= "00000000100011111110000011111111"; -- ID = 1111111
		wait for clock_period * 10; -- In order for updateReq to have time to set to '0', before shutting off override 
		
		-- Finish channel 0
		
		activeCh0 <= '0';
		wait for clock_period;
		interruptAck <= '1';
		wait for clock_period;
		interruptAck <= '0';
		activeCh0 <= '1';
		req <= '0';
		
		wait for clock_period * 10;
		
		-- Finish channel 1
		
		activeCh1 <= '0';      
        wait for clock_period; 
        interruptAck <= '1';   
        wait for clock_period; 
        interruptAck <= '0';   
		
		wait for clock_period * 10;
		
		-- Finish channel 0	again
		
		activeCh0 <= '0';      
        wait for clock_period; 
        interruptAck <= '1';   
        wait for clock_period; 
        interruptAck <= '0';   
		
		wait for clock_period * 30;
		
		----------------------------------------------------------------------------------------------------------------------------------------------------------------------
        -- Step 9: Test when 2 channels end simultaneously
		-- (sending in 2 requests instantly
		reqDetails <= "00000000100011001110000011111111"; -- ID = 1100111						
        req <= '1';
                
        wait for clock_period; -- Next data in next cycle
        activeCh0 <= '1';
        reqDetails <= "00000000100010000010000011111111"; -- ID = 1000001
        wait for clock_period;
        activeCh1 <= '1';
		req <= '0';
		
		wait for clock_period * 10;
		
		-- Both channels finish. Channel 0 should have priority over channel 1 in the interrupt sequence
		
		activeCh0 <= '0';
		activeCh1 <= '0';
		wait for clock_period;
		interruptAck <= '1';
		wait for clock_period * 2; -- An interrupt for each of the both channels, there will be 2 subsequent requests
		interruptAck <= '0';
		
		wait for clock_period * 30;
		
		----------------------------------------------------------------------------------------------------------------------------------------------------------------------     
        -- Step 10: Test when 2 channels end simultaneously, but with delay in interruptAck between                                                                                                                   
                                                                                                                                                
        reqDetails <= "00000000100011001110000011111111"; -- ID = 1100111                                                                                                                            
        req <= '1';                                                                                                                                                          
                                                                                                                                                                                   
        wait for clock_period; -- Next data in next cycle                                                                                                                    
        activeCh0 <= '1';                                                                                                                                                    
        reqDetails <= "00000000100010000010000011111111"; -- ID = 1000001                                                                                                    
        wait for clock_period;                                                                                                                                               
        activeCh1 <= '1';                                                                                                                                                    
        req <= '0';                                                                                                                                                                
                                                                                                                                                                                   
        wait for clock_period * 10;                                                                                                                                                
                                                                                                                                                                                   
        -- Both channels finish. Channel 0 should have priority over channel 1 in the interrupt sequence                                                                           
                                                                                                                                                                                   
        activeCh0 <= '0';                                                                                                                                                          
        activeCh1 <= '0';                                                                                                                                                          
        wait for clock_period;                                                                                                                                                     
        interruptAck <= '1';
        wait for clock_period;
        interruptAck <= '0';
        -- The only possible scenario with current implementation for this to happen is if the ouput buffer in the bus interface is full, and requests arbiter to halt
        wait for clock_period * 10;
        interruptAck <= '1';                                                                                                                                                       
        wait for clock_period;                                                 
        interruptAck <= '0';                                                                                                                                                       
                                                                                                                                                                                   
                                                                                                                                                                                   
		
		-- END OF TEST
		
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


library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity controller is
	 port(
		 di_ready : in STD_LOGIC;
		 clk : in STD_LOGIC;
		 reset : in STD_LOGIC;
		 do_ready : out STD_LOGIC;
		 control_signals : out STD_LOGIC_VECTOR(9 downto 0);
		 voted_data_selector : out STD_LOGIC_VECTOR(4 downto 0)
	     );
end controller;

architecture controllerImproved of controller is
											   	   			 
	
	-- Next-signals used for clock updates
	signal next_control_signals: std_logic_vector(9 downto 0);
	signal next_vdsi: std_logic_vector(4 downto 0);
	signal next_do_ready: std_logic;-- := '0';
	
	signal do_ready_internal: std_logic; -- For internal use of do_ready 
	signal control_signals_internal : STD_LOGIC_VECTOR(9 downto 0);	-- For internal use of control_signals
	signal vdsi : STD_LOGIC_VECTOR(4 downto 0); -- For internal use of voted_data_selector (shortened to vdsi, i for internal)	
	
begin
	
	-- Setting output from internal output signals
	do_ready <= do_ready_internal;
	control_signals <= control_signals_internal;
	voted_data_selector <= vdsi;
	
	clock_tick : process(clk)
	begin
	if (rising_edge(clk)) then
		if (reset = '1') then
			control_signals_internal <= "0000000000";
			vdsi <= "00000";	   
			do_ready_internal <= '0';		 
		else					
			-- Updating the controller's output values
			-- based on current selected next-values
			control_signals_internal <= next_control_signals;
			vdsi <= next_vdsi;	 
			do_ready_internal <= next_do_ready;	
		end if;
		
		
	end if;
	end process;
			
	-- Selects register for input, and also activates do_ready after 8 cycles
	handle_input : process(di_ready, control_signals_internal)
	begin
		case control_signals_internal is
			when "0000000000" =>
				if (di_ready = '1') then  -- di_ready works only when system is idle, with value "0000000000"
					next_control_signals <= "0010000000"; -- store as bit 7	
				else 
					next_control_signals <= "0000000000"; -- Stay idle, di_ready has not yet hit in
				end if;													
			when "0010000000" =>
				next_control_signals <= "0001000000"; -- store as bit 6
			when "0001000000" =>
				next_control_signals <= "0000100000"; -- store as bit 5
			when "0000100000" =>
				next_control_signals <= "0000010000"; -- store as bit 4
			when "0000010000" =>
				next_control_signals <= "0000001000"; -- store as bit 3
			when "0000001000" =>
				next_control_signals <= "0000000100"; -- store as bit 2
			when "0000000100" =>
				next_control_signals <= "0000000010"; -- store as bit 1
			when "0000000010" =>
				next_do_ready <= '1'; -- Setting do_ready 8 cycles after di_ready has initiated storing
				next_vdsi <= "00111"; -- Set output from liasion to voted data bit 7 at the same time
				next_control_signals <= "0000000001"; -- store as bit 0
			when "0000000001" =>
				next_control_signals <= "0100000000"; -- store status
			when "0100000000" =>
				next_control_signals <= "1000000000"; -- update ECC-registers 
			when others => -- Done running through register storing. Do nothing until di_ready has been set again.
				next_control_signals <= "0000000000"; 
		end case;							 
		
	end process;
	
	-- Setting next_do_ready to 0. Usually happens after do_ready has been set to '1', so that it will be set to '0' in next cycle.
--	shut_off_do_ready : process(do_ready_internal)
--	begin
--		next_do_ready <= '0';
--	end process;
	  
	handle_output : process (vdsi)
	begin							
		
		case vdsi is
			-- next_vdsi should already be "00111" at this point
			--when "00111" =>
--				next_vdsi <= "00111"; -- set output from liaison to voted data bit 7, should be set already at beginning of counting
			when "00111" =>
				next_vdsi <= "00110"; -- set output from liaison to voted data bit 6
			when "00110" =>
				next_vdsi <= "00101"; -- set output from liaison to voted data bit 5
			when "00101" =>
				next_vdsi <= "00100"; -- set output from liaison to voted data bit 4
			when "00100" =>
				next_vdsi <= "00011"; -- set output from liaison to voted data bit 3
			when "00011" =>
				next_vdsi <= "00010"; -- set output from liaison to voted data bit 2
			when "00010" =>
				next_vdsi <= "00001"; -- set output from liaison to voted data bit 1
			when "00001" =>
				next_vdsi <= "00000"; -- set output from liaison to voted data bit 0
			when "00000" =>
				next_vdsi <= "01010"; -- set output from liaison to status bit 2
			when "01010" =>
				next_vdsi <= "01001"; -- set output from liaison to status bit 1
			when "01001" =>
				next_vdsi <= "01000"; -- set output from liaison to status bit 0
			when "01000" =>
				next_vdsi <= "10010"; -- set output from liaison to ECC bit 3
			when "10010" =>
				next_vdsi <= "10001"; -- set output from liaison to ECC bit 2
			when "10001" =>
			   	next_vdsi <= "10000"; -- set output from liaison to ECC bit 1
			when "10000" =>
				next_vdsi <= "01111"; -- set output from liaison to ECC bit 0
			when others =>
				-- Do nothing. The moment this usually happens is when vdsi has been set to "01111",
				-- and next_vdsi (as well as do_ready) should be set at the same time in the handle_input_process
		end case;
		
		
		-- Sets do_ready to 0. Usually occurs cycle after it was set to '1'
		--if (do_ready_internal = '1') then
			next_do_ready <= '0';
		--end if;
	end process;
	  
	
end controllerImproved;
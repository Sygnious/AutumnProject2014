library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity inputHandler is
	generic(n: integer := 34; -- Two extra bits to determine difference between load, store and intterupt. Must be recognized by the output handler. 
			m: integer := 2);
	port (
		clk : in std_logic;
	
		opt: in std_logic_vector(m-1 downto 0);
		input : in std_logic_vector(n-1 downto 0);
		
		reqOutput : out std_logic_vector((n*3)-1 downto 0); -- 96 bits: 1 for loadaddress, 1 for storing address and 1 for requestdetails (including ID and count) 
		reqPush : out std_logic;
		dataOutput : out std_logic_vector((n*2)-1 downto 0); --64 bits: 32 for loadaddress (ID) and 32 for data
		dataPush : out std_logic
	);
end inputHandler;

architecture arch of inputHandler is
	
	type state IS (READY, REQ0, REQ1, REQ2, DA0, DA1);										   	   			 
	signal pr_state, next_state : state;
	attribute enum_encoding: string;
	attribute enum_encoding of state: type is "sequential";
	
	-- Internal registers for storing in between
	signal request0 : std_logic_vector(n-1 downto 0) := (n-1 downto 0 => '0'); -- Req: Load
	signal request1 : std_logic_vector(n-1 downto 0) := (n-1 downto 0 => '0'); -- Req: Store
	--signal request2 : std_logic_vector(n-1 downto 0) := (n-1 downto 0 => '0'); -- Req: Details
	signal data0 : std_logic_vector(n-1 downto 0) := (n-1 downto 0 => '0'); -- Data: LoadID
	--signal data1 : std_logic_vector(n-1 downto 0) := (n-1 downto 0 => '0');	-- Data: StoreID
	
	-- Next outputs
	
	signal next_reqOutput :  std_logic_vector((n*3)-1 downto 0) := ((n*3)-1 downto 0 => '0');
	signal next_reqPush : std_logic := '0';
	signal next_dataOutput : std_logic_vector((n*2)-1 downto 0) := ((n*2)-1 downto 0 => '0');
	signal next_dataPush : std_logic := '0';
	
	-- Next internals
	signal next_request0 : std_logic_vector(n-1 downto 0) := (n-1 downto 0 => '0'); -- Req: Load
	signal next_request1 : std_logic_vector(n-1 downto 0) := (n-1 downto 0 => '0'); -- Req: Store
	signal next_request2 : std_logic_vector(n-1 downto 0) := (n-1 downto 0 => '0'); -- Req: Details
	signal next_data0 : std_logic_vector(n-1 downto 0) := (n-1 downto 0 => '0'); -- Data: LoadID
	signal next_data1 : std_logic_vector(n-1 downto 0) := (n-1 downto 0 => '0');	-- Data: StoreID
	
begin
	-- Lower section of FSM
	updateFSM : process(clk) -- Updating state and output signals based on next-signals
	begin
		if rising_edge(clk) then
			-- State
			pr_state <= next_state;
			-- Outputs		   
			reqOutput <= next_reqOutput;
			reqPush <= next_reqPush;
			dataOutput <= next_dataOutput;
			dataPush <= next_dataPush;
			
			-- Internal signals
			request0 <= next_request0;																	  
			request1 <= next_request1;
			request2 <= next_request2;
			data0 <= next_data0;
			data1 <= next_data1;
			
		end if;
	end process;
	
	setNext : process(opt, input)
	begin
		case pr_state is
			when READY => 
				next_reqPush <= '0';
				next_dataPush <= '0';
			
				if opt = "01" then -- Data
					next_state <= DA0;
					next_data0 <= input; -- Assuming load address first	
				elsif opt = "10" then -- Request for transfer
					next_state <= REQ0;	
					next_request0<= input; -- Assuming request data first	
				else
					next_state <= READY;					  
				end if;
			when DA0 =>
				--next_state <= READY;
				--next_dataPush <= '1';
				--next_dataOutput <= data0 & input; -- Next recieved input is data for storing. May now send out together with loadID. next_dataPush set to '1'
			   	next_state <= DA1;
				next_data1 <= input;
			when DA1 =>
				next_state <= READY;
				next_dataPush <= '1';
				next_dataOutpu <= data0 & data1;
			when REQ0 =>
				next_state <= REQ1;
				next_request1 <= input; -- Store address
				
			when REQ1 => 
			--	next_state <= READY;
			--	next_reqPush <= '1';
			--	next_reqOutput <= request1 & input & request0; -- Store address, load address and request details
				next_state <= REQ2;
				next_request2 <= input;
			
			when REQ2 => 
				next_state <= READY;
				next_reqPush <= '1';
				next_reqOutput <= request1 & request2 & request0; -- Store address, load address and request details
			
			when OTHERS => -- Should not happen, but must have as according to good practise
				next_state <= READY;
				next_reqPush <= '0';
				next_dataPush <= '0';
			end case;
				
	end process;	
end arch;
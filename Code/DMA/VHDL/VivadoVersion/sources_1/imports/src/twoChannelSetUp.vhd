library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity twoChannelSetUp is
	generic(
		n: integer := 32; -- Sets data and addresses
		m: integer := 32; -- Sets count
		i: integer := 34
	);
	
	-- Includes: Data buffer, 2 channels and arbiter 
	-- (inclusion of arbiter means that all signals between DMA Main Controller and arbiter must be sent throught this top view)
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
		
		
		interruptAck : out std_logic; -- Ack signal to the DMA Controller from arbiter
		
		-- Output from fifo
		bufferFull : out std_logic
		
		);
end twoChannelSetUp;

 architecture arch of twoChannelSetUp is
	-- Internal signals
	
	-- Between channels and fifo data buffer/LoadIDComparator
	signal currentLoadID : std_logic_vector(n-1 downto 0);
	signal loadID0 : std_logic_vector(n-1 downto 0); -- Store channel 0's FLA, compared to current LoadID in buffer
	signal loadID1 : std_logic_vector(n-1 downto 0); -- Channel 1's version of loadID0. NOTE: Same goes for rest with number 1 at the end of signal names.
	signal rdy0 : std_logic; -- Signal from LoadIDComparator to channel 0, notifies that next data belongs to channel 0's next store (this is the dataRdy signals used for requesting store)
	signal rdy1 : std_logic;
	
	-- Between channels and arbiter, LOAD:
	signal loadReq0 : std_logic; -- Request arbiter for passing through load cmd + address
	signal loadReq1 : std_logic;
	signal loadAck0 : std_logic; -- Arbiter grants channel 0 access to pass load details. Intertal load channel counter decrements.
	signal loadAck1 : std_logic;
	signal loadAdr0 : std_logic_vector(i-1 downto 0); -- Load cmd + address from channel 0 to arbiter
	signal loadAdr1 : std_logic_vector(i-1 downto 0);
	
	-- Between channels and arbiter, STORE:
	signal storeReq0 : std_logic; -- Request arbiter for passing through store cmd + address
	signal storeReq1 : std_logic;
	signal storeAck0 : std_logic; -- Arbiter grants channel 0 access to pass store details. Intertal store channel counter decrements.
	signal storeAck1 : std_logic;
	signal storeAdr0 : std_logic_vector(i-1 downto 0); -- Store cmd + address from channel 0 to arbiter
	signal storeAdr1 : std_logic_vector(i-1 downto 0);
	
	-- Concatinated fifo-signals
	signal fifoIn : std_logic_vector((n*2)-1 downto 0); -- loadIDIn & dataIn
	signal fifoOut : std_logic_vector((n*2)-1 downto 0); -- currentLoadID & data
	
	-- Between fifo-buffer and arbiter
	signal data : std_logic_vector (n-1 downto 0); -- Data transfered from shared data buffer to the arbiter. Will usually pass through during a store
	signal popData : std_logic; -- Set-signal from arbiter, used to update buffer with next ready data (sent during a store, at same time as data passes through)
	
	-- From system to/from fifo buffer
    signal popFirst : std_logic := '0'; -- Pop-signal, used to pop first data in a new series of arrivals. Stored in register
	signal bufferEmpty : std_logic := '0';
	
	-- From topview to DMA Main controller
	signal loadActive0 : std_logic; -- These interal signals will be combined using OR function. 
	signal loadActive1 : std_logic;
	
	signal storeActive0 : std_logic;
	signal storeActive1 : std_logic;
	
	
	
	-- Used components:
	component fifo
	generic(
		depth : natural := 16;
		width : natural := 64
	);
	port(
		-- Control lines:
		clk   : in std_logic;
		reset : in std_logic;

		-- Status lines:
		full  : out std_logic;
		empty : out std_logic;

		-- Data in:
		input : in std_logic_vector(width - 1 downto 0);
		push  : in std_logic;

		-- Data out:
		output : out std_logic_vector(width - 1 downto 0);
		pop    : in  std_logic
	);
	end component;
	
	component loadIDComparator
	port(  
		-- Input from fifo						   
		loadIDIn : in std_logic_vector(n-1 downto 0);
		
		-- Input from channels
		loadIDCheck0 : in std_logic_vector(n-1 downto 0);
		loadIDCheck1 : in std_logic_vector(n-1 downto 0);
		
		-- Output to channels
		rdy0 : out std_logic;
		rdy1 : out std_logic
	);
	end component;
	
	component fullChannel
	port(
		-- INPUT
		clk : in std_logic;
		-- From DMA Main Controller
		set : in std_logic; -- Activates setting counter, final load address, final store address (and mode)
		modeIn : in std_logic; -- Input used to set counter behaviour (fixed address vs. changing address. Will always be '1' for this project)
		FLAIn: in std_logic_vector(n-1 downto 0); -- Input data to FLA
		FSAIn: in std_logic_vector(n-1 downto 0); -- Input data to FSA
		countIn: in std_logic_vector(m-1 downto 0); -- Input data to counter
		-- From Buffer
		dataRdy : in std_logic; -- When data in shared data buffer belongs to this channel (identified by the load address)
		-- From arbiter
		loadAck : in std_logic;  
		storeAck : in std_logic; 
	
		-- OUTPUT
		-- To DMA Main Controller
		active : out std_logic;
		-- To Buffer
		loadIDOut : out std_logic_vector((n-1) downto 0); -- To compare with shared data buffer
		-- To arbiter
		loadAdrOut : out std_logic_vector(2+(n-1) downto 0); -- Current load address for load request
		storeAdrOut : out std_logic_vector(2+(n-1) downto 0); -- Current store address for store request
		loadReq : out std_logic;
		storeReq : out std_logic
 -- Request signal to arbiter to pass through store address to arbiter (will be passed together with data from shared buffer)
	
	);
	
	end component;
	
	component arbiterTop
	port(
 		-- INPUTS
 		clk : in STD_LOGIC;
 		-- Signals from Channels + block system
		blockReq : in std_logic;
		interruptReq : in std_logic;
		storeReq0: in std_logic;
		storeReq1: in std_logic;
		loadReq0: in std_logic;
		loadReq1: in std_logic;
		-- From buffer
		data_in : in STD_LOGIC_VECTOR(m-1 downto 0);
		-- Directly from DMA Main Controller
		interruptInput : in std_logic_vector(i-1 downto 0);
		-- Inputs from channels
		storeInput0: in std_logic_vector(i-1 downto 0);
		storeInput1: in std_logic_vector(i-1 downto 0);
		loadInput0: in std_logic_vector(i-1 downto 0);
		loadInput1: in std_logic_vector(i-1 downto 0);
	
		--OUTPUTS
		-- To the channels
		interruptAck : out std_logic;
		storeAck0 : out std_logic; -- Also to buffer
		storeAck1 : out std_logic; -- Also to buffer
		loadAck0 : out std_logic;
		loadAck1 : out std_logic;
		
		-- Final output to the system
		adrOut : out std_logic_vector(i-1 downto 0);
		dataOut : out std_logic_vector(m-1 downto 0)
	);
	end component;
	
begin
	
	fifoIn <= loadIDIn & dataIn;
	currentLoadID <= fifoOut((n*2)-1 downto n);
	data <= fifoOut(n-1 downto 0);
	
	-- Assumption: Data fifo buffer does not receive data faster than what is sent out, due to slow memory system
	buffered : fifo
	port map(
		clk => clk,
		reset => reset,		 
							 
		full  => bufferFull,
		empty => bufferEmpty,

		-- Data in:
		input => fifoIn,
		push => pushData,

		-- Data out:
		output => fifoOut,
		pop    => popData
	);
	
	comparator : loadIDComparator
	port map(
		 loadIDIn => currentLoadID,
		
		-- Input from channels
		loadIDCheck0 => loadID0,
		loadIDCheck1 => loadID1,
		
		-- Output to channels
		rdy0 => rdy0,
		rdy1 => rdy1
	
	);
	
	channel0 : fullChannel	   
	port map(
		clk => clk,
		set => set0,
		modeIn => modeIn,
		FLAIn => FLAIn,
		FSAIn => FSAIn,
		countIn => countIN,
		dataRdy => rdy0,
		loadAck => loadAck0,
		storeAck => storeAck0,
		
		active => active0,
		loadIDOut => loadID0,
		loadAdrOut => loadAdr0,
		storeAdrOut => storeAdr0,
		loadReq => loadReq0,
		storeReq => storeReq0
	);
	
	channel1 : fullChannel
	port map(
		clk => clk,
		set => set1,
		modeIn => modeIn,
		FLAIn => FLAIn,
		FSAIn => FSAIn,
		countIn => countIN,
		dataRdy => rdy1,
		loadAck => loadAck1,
		storeAck => storeAck1,
		
		active => active1,
		loadIDOut => loadID1,
		loadAdrOut => loadAdr1,
		storeAdrOut => storeAdr1,
		loadReq => loadReq1,
		storeReq => storeReq1
	);
	
	arbiter : arbiterTop
	port map(
		clk => clk,
		-- From outside
		blockReq => blockArbiter,
		interruptReq => interruptReq,
		-- Signals from channels
		storeReq0 => storeReq0,
		storeReq1 => storeReq1,
		loadReq0 => loadReq0,
		loadReq1 => loadReq1,
		-- From buffer
		data_in => data,
		-- From DMA Controller
		interruptInput => interruptCmd,
		-- Inputs from channels
		storeInput0 => storeAdr0,
		storeInput1 => storeAdr1,
		loadInput0 => loadAdr0,
		loadInput1 => loadAdr1,
	
		--OUTPUTS
		-- To DMA Controller
		interruptAck => interruptAck,
		-- To the channels
		storeAck0 => storeAck0,
		storeAck1 => storeAck1,
		loadAck0 => loadAck0,
		loadAck1 => loadAck1,
		
		-- Final output to the system
		adrOut => detailsOutput,
		dataOut => dataOutput
		
	);
	
	popData <= ((storeAck0 OR storeAck1) AND NOT bufferEmpty) OR popFirst; -- Whenever there is a store, the buffer must pop out next data EXCEPT when buffer is empty. 
	
	-- When databuffer empty, if new arrival: Pop it at once!						   
	popFirstArrival : process(pushData, bufferEmpty, clk)
	begin
	   if rising_edge(clk) then
	       if pushData = '1' AND bufferEmpty = '1' then
	           popFirst <= '1';
	       else 
	           popFirst <= '0';
	       end if;
	   end if;
	end process;
	
	
end arch;



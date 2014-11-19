library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity DMA_v1_0_M_AXI is
	generic (
		-- Users to add parameters here

		-- User parameters ends
		-- Do not modify the parameters beyond this line

		-- Width of M_AXI address bus. 
    -- The master generates the read and write addresses of width specified as C_M_AXI_ADDR_WIDTH.
		C_M_AXI_ADDR_WIDTH	: integer	:= 32;
		-- Width of M_AXI data bus. 
    -- The master issues write data and accept read data where the width of the data bus is C_M_AXI_DATA_WIDTH
		C_M_AXI_DATA_WIDTH	: integer	:= 32
	);
	port (
		-- Users to add ports here

		-- Signal indicating the master is busy and cannot accept new commands from the DMA:
		master_busy : out std_logic;

		-- Connections to the DMA data interface:
		dma_data_out_addr : out std_logic_vector(31 downto 0);
		dma_data_out   : out std_logic_vector(31 downto 0);
		dma_data_store : out std_logic;

		-- Connections to the DMA command issue interface:
		dma_output_data : in std_logic_vector(31 downto 0);
		dma_output_cmd  : in std_logic_vector(1 downto 0);
		dma_output_dest : in std_logic_vector(31 downto 0);
		dma_output_exec : in std_logic;

		-- DMA interrupt signals:
		dma_interrupt_out : out std_logic;
		dma_interrupt_id  : out std_logic_vector(6 downto 0);

		-- User ports ends
		-- Do not modify the ports beyond this line

		-- AXI clock signal
		M_AXI_ACLK	: in std_logic;
		-- AXI active low reset signal
		M_AXI_ARESETN	: in std_logic;
		-- Master Interface Write Address Channel ports. Write address (issued by master)
		M_AXI_AWADDR	: out std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
		-- Write channel Protection type.
    -- This signal indicates the privilege and security level of the transaction,
    -- and whether the transaction is a data access or an instruction access.
		M_AXI_AWPROT	: out std_logic_vector(2 downto 0);
		-- Write address valid. 
    -- This signal indicates that the master signaling valid write address and control information.
		M_AXI_AWVALID	: out std_logic;
		-- Write address ready. 
    -- This signal indicates that the slave is ready to accept an address and associated control signals.
		M_AXI_AWREADY	: in std_logic;
		-- Master Interface Write Data Channel ports. Write data (issued by master)
		M_AXI_WDATA	: out std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
		-- Write strobes. 
    -- This signal indicates which byte lanes hold valid data.
    -- There is one write strobe bit for each eight bits of the write data bus.
		M_AXI_WSTRB	: out std_logic_vector(C_M_AXI_DATA_WIDTH/8-1 downto 0);
		-- Write valid. This signal indicates that valid write data and strobes are available.
		M_AXI_WVALID	: out std_logic;
		-- Write ready. This signal indicates that the slave can accept the write data.
		M_AXI_WREADY	: in std_logic;
		-- Master Interface Write Response Channel ports. 
    -- This signal indicates the status of the write transaction.
		M_AXI_BRESP	: in std_logic_vector(1 downto 0);
		-- Write response valid. 
    -- This signal indicates that the channel is signaling a valid write response
		M_AXI_BVALID	: in std_logic;
		-- Response ready. This signal indicates that the master can accept a write response.
		M_AXI_BREADY	: out std_logic;
		-- Master Interface Read Address Channel ports. Read address (issued by master)
		M_AXI_ARADDR	: out std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
		-- Protection type. 
    -- This signal indicates the privilege and security level of the transaction, 
    -- and whether the transaction is a data access or an instruction access.
		M_AXI_ARPROT	: out std_logic_vector(2 downto 0);
		-- Read address valid. 
    -- This signal indicates that the channel is signaling valid read address and control information.
		M_AXI_ARVALID	: out std_logic;
		-- Read address ready. 
    -- This signal indicates that the slave is ready to accept an address and associated control signals.
		M_AXI_ARREADY	: in std_logic;
		-- Master Interface Read Data Channel ports. Read data (issued by slave)
		M_AXI_RDATA	: in std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
		-- Read response. This signal indicates the status of the read transfer.
		M_AXI_RRESP	: in std_logic_vector(1 downto 0);
		-- Read valid. This signal indicates that the channel is signaling the required read data.
		M_AXI_RVALID	: in std_logic;
		-- Read ready. This signal indicates that the master can accept the read data and response information.
		M_AXI_RREADY	: out std_logic
	);
end DMA_v1_0_M_AXI;

architecture implementation of DMA_v1_0_M_AXI is

	-- function called clogb2 that returns an integer which has the
	-- value of the ceiling of the log base 2
	function clogb2 (bit_depth : integer) return integer is            
	 	variable depth  : integer := bit_depth;                               
	 	variable count  : integer := 1;                                       
	 begin                                                                   
	 	 for clogb2 in 1 to bit_depth loop  -- Works for up to 32 bit integers
	      if (bit_depth <= 2) then                                           
	        count := 1;                                                      
	      else                                                               
	        if(depth <= 1) then                                              
	 	       count := count;                                                
	 	     else                                                             
	 	       depth := depth / 2;                                            
	          count := count + 1;                                            
	 	     end if;                                                          
	 	   end if;                                                            
	   end loop;                                                             
	   return(count);        	                                              
	 end;

	type state_type is (STATE_IDLE, STATE_READ, STATE_WRITE, STATE_INTERRUPT);
	signal state : state_type;

	-- AXI4LITE signals
	--write address valid
	signal axi_awvalid	: std_logic;
	--write data valid
	signal axi_wvalid	: std_logic;
	--read address valid
	signal axi_arvalid	: std_logic;
	--read data acceptance
	signal axi_rready	: std_logic;
	--write response acceptance
	signal axi_bready	: std_logic;
	--write address
	signal axi_awaddr	: std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
	--write data
	signal axi_wdata	: std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
	--read addresss
	signal axi_araddr	: std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
	--Asserts when a single beat write transaction is issued and remains asserted till the completion of write trasaction.
	signal write_issued	: std_logic;
	--Asserts when a single beat read transaction is issued and remains asserted till the completion of read trasaction.
	signal read_issued	: std_logic;
	--flag that marks the completion of write trasactions. The number of write transaction is user selected by the parameter C_M_TRANSACTIONS_NUM.
	signal writes_done	: std_logic;
	--flag that marks the completion of read trasactions. The number of read transaction is user selected by the parameter C_M_TRANSACTIONS_NUM
	signal reads_done	: std_logic;
	--The error register is asserted when any of the write response error, read response error or the data mismatch flags are asserted.
	signal error_reg	: std_logic;

	signal write_address : std_logic_vector(31 downto 0);
	signal read_address  : std_logic_vector(31 downto 0);
	signal write_data    : std_logic_vector(31 downto 0);
	signal read_data     : std_logic_vector(31 downto 0);

	signal start_write : std_logic;
	signal start_read : std_logic;
	
	signal write_error : std_logic;

begin

	-- Some notes on the AXI4 bus:	
	--   * There are separate channels for read and write addresses and data
	--   * All channels have a valid and a ready signal.
	--   * A valid signal is used to signal valid data on a channel, and in
	--     response the ready signal is asserted.
	--   * Writes causes a write response using the bvalid and bready signals.

	-- Write address channel data:
	m_axi_awaddr <= write_address;
	m_axi_awvalid <= axi_awvalid;
	m_axi_awprot <= b"001"; -- Privileged access (see page 73 in spec)
	-- Write data channel data:
	m_axi_wdata  <= write_data;
	m_axi_wvalid <= axi_wvalid;
	-- Read address channel data:
	m_axi_araddr <= read_address;
	m_axi_arvalid <= axi_arvalid;
	m_axi_arprot <= b"001"; -- Privileged access

	-- Use all byte lanes (because we are sending 32 bit data):
	m_axi_wstrb <= (others => '1');

	-- Write response channel signals:
	m_axi_bready <= axi_bready;

	-- Read read response:
	m_axi_rready <= axi_rready;

	-- Data read from the bus is sent back to the DMA module:
	dma_data_out <= read_data;

	-- The original example code uses synchronous resets, so we do too.

	-- Process for sending the write address on the bus:
	write_address_proc: process(m_axi_aclk)
	begin
		if rising_edge(m_axi_aclk) then
			if m_axi_aresetn = '0' then
				axi_awvalid <= '0';
			else
				if start_write = '1' then -- Send transaction address 
					axi_awvalid <= '1';
				elsif m_axi_awready = '1' and axi_awvalid = '1' then -- Address accepted by interconnect
					axi_awvalid <= '0';
				end if;
			end if;
		end if;
	end process write_address_proc;

	-- Process for sending the write data on the bus:
	write_data_proc: process(m_axi_aclk)
	begin
		if rising_edge(m_axi_aclk) then
			if m_axi_aresetn = '0' then
				axi_wvalid <= '0';
			else
				if start_write = '1' then -- Send data
					axi_wdata <= write_data;
					axi_wvalid <= '1';
				elsif m_axi_wready = '1' and axi_wvalid = '1' then -- Data accepted by the interconnect
					axi_wvalid <= '0';
				end if;
			end if;
		end if;
	end process write_data_proc;                                                 

	-- Process for acknowledging the write response received from the bus:
	write_response_proc: process(m_axi_aclk)
	begin
		if rising_edge(m_axi_aclk) then
			if m_axi_aresetn = '0' then
				axi_bready <= '0';
			else
				if m_axi_bvalid = '1' and axi_bready = '0' then
					axi_bready <= '1';
				elsif axi_bready = '1' then
					axi_bready <= '0';
				end if;
			end if;
		end if;
	end process write_response_proc;

	-- Process for sending the read address on the bus:
	read_address_proc: process(m_axi_aclk)
	begin
		if rising_edge(m_axi_aclk) then
			if m_axi_aresetn = '0' then
				axi_arvalid <= '0';
			else
				if start_read = '1' then -- Send the read address
					axi_arvalid <= '1';
				elsif m_axi_arready = '1' and axi_arvalid = '1' then -- Read address accepted
					axi_arvalid <= '0';
				end if;
			end if;
		end if;
	end process read_address_proc;

	-- Process for reading data from the bus:
	read_data_proc: process(m_axi_aclk)
	begin
		if rising_edge(m_axi_aclk) then
			if m_axi_aresetn = '0' or start_read = '1' then
				--axi_rready <= '1'; -- Always ready for data, yay
				axi_rready <= '1';
			else
				if m_axi_rvalid = '1' and axi_rready = '1' then -- Data received!
					read_data <= m_axi_rdata;
					axi_rready <= '0';
				--else
				--	axi_rready <= '0';
				end if;
			end if;
		end if;
	end process read_data_proc;

	-- Write errors are signaled in bit 1 of the bresp signal:
	write_error <= axi_bready and m_axi_bvalid and m_axi_bresp(1);

	-- DMA master interface state machine:
	master_process: process(m_axi_aclk, m_axi_aresetn)
	begin
		if m_axi_aresetn = '0' then
			state <= STATE_IDLE;
			start_write <= '0';
			start_read <= '0';
			read_issued <= '0';
			write_issued <= '0';
			dma_interrupt_out <= '0';
			dma_data_store <= '0';
		elsif rising_edge(m_axi_aclk) then
			case state is
				when STATE_IDLE =>
					master_busy <= '0';
					dma_interrupt_out <= '0';
					dma_data_store <= '0';

					if dma_output_exec = '1' then
						master_busy <= '1';
						case dma_output_cmd is
							when b"00" => -- Load
								read_address <= dma_output_dest;
								dma_data_out_addr <= dma_output_dest;
								state <= STATE_READ;
							when b"01" => -- Store
								write_address <= dma_output_dest;
								write_data <= dma_output_data;
								state <= STATE_WRITE;
							when b"10" | b"11" => -- Interrupt
								state <= STATE_INTERRUPT;
								dma_interrupt_id <= dma_output_dest(6 downto 0);
							when others =>
								-- Do nothing, impossible state
						end case;
					end if;

				when STATE_INTERRUPT =>
					dma_interrupt_out <= '1';
					state <= STATE_IDLE;

				when STATE_READ =>
					if axi_arvalid = '0' and m_axi_rvalid = '0' and start_read = '0' and read_issued = '0' then
						start_read <= '1';
						read_issued <= '1';
					elsif m_axi_rvalid = '1' and read_issued = '1' then-- and read_issued = '1' then -- Read finished!
						read_issued <= '0';
						start_read <= '0';
						dma_data_store <= '1';
						state <= STATE_IDLE;
					else
						start_read <= '0';
					end if;

				when STATE_WRITE =>
					if axi_awvalid = '0' and axi_wvalid = '0' and m_axi_bvalid = '0' and start_write = '0' and write_issued = '0' then
						start_write <= '1';
						write_issued <= '1';
					elsif axi_bready = '1' then -- Write finished!
						write_issued <= '0';
						start_write <= '0';
						state <= STATE_IDLE;
					else
						start_write <= '0';
					end if;  
			end case;
		end if;
	end process master_process;

end implementation;

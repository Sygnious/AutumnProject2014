library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity DMA_v1_0 is
	generic (
		-- Users to add parameters here

		-- User parameters ends
		-- Do not modify the parameters beyond this line


		-- Parameters of Axi Master Bus Interface M_AXI
		C_M_AXI_ADDR_WIDTH	: integer	:= 32;
		C_M_AXI_DATA_WIDTH	: integer	:= 32;
		C_M_AXI_TRANSACTIONS_NUM	: integer	:= 4;

		-- Parameters of Axi Slave Bus Interface S_AXI
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		C_S_AXI_ADDR_WIDTH	: integer	:= 5
	);
	port (
		-- Users to add ports here
		interrupt : out std_logic; -- Interrupt signal
		-- User ports ends
		-- Do not modify the ports beyond this line

		-- Ports of Axi Master Bus Interface M_AXI
		m_axi_aclk	: in std_logic;
		m_axi_aresetn	: in std_logic;
		m_axi_awaddr	: out std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
		m_axi_awprot	: out std_logic_vector(2 downto 0);
		m_axi_awvalid	: out std_logic;
		m_axi_awready	: in std_logic;
		m_axi_wdata	: out std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
		m_axi_wstrb	: out std_logic_vector(C_M_AXI_DATA_WIDTH/8-1 downto 0);
		m_axi_wvalid	: out std_logic;
		m_axi_wready	: in std_logic;
		m_axi_bresp	: in std_logic_vector(1 downto 0);
		m_axi_bvalid	: in std_logic;
		m_axi_bready	: out std_logic;
		m_axi_araddr	: out std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
		m_axi_arprot	: out std_logic_vector(2 downto 0);
		m_axi_arvalid	: out std_logic;
		m_axi_arready	: in std_logic;
		m_axi_rdata	: in std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
		m_axi_rresp	: in std_logic_vector(1 downto 0);
		m_axi_rvalid	: in std_logic;
		m_axi_rready	: out std_logic;

		-- Ports of Axi Slave Bus Interface S_AXI
		s_axi_aclk	: in std_logic;
		s_axi_aresetn	: in std_logic;
		s_axi_awaddr	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		s_axi_awprot	: in std_logic_vector(2 downto 0);
		s_axi_awvalid	: in std_logic;
		s_axi_awready	: out std_logic;
		s_axi_wdata	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		s_axi_wstrb	: in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		s_axi_wvalid	: in std_logic;
		s_axi_wready	: out std_logic;
		s_axi_bresp	: out std_logic_vector(1 downto 0);
		s_axi_bvalid	: out std_logic;
		s_axi_bready	: in std_logic;
		s_axi_araddr	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		s_axi_arprot	: in std_logic_vector(2 downto 0);
		s_axi_arvalid	: in std_logic;
		s_axi_arready	: out std_logic;
		s_axi_rdata	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		s_axi_rresp	: out std_logic_vector(1 downto 0);
		s_axi_rvalid	: out std_logic;
		s_axi_rready	: in std_logic
	);
end DMA_v1_0;

architecture arch_imp of DMA_v1_0 is

	-- component declaration
	component DMA_v1_0_M_AXI is
		generic (
		C_M_AXI_ADDR_WIDTH	: integer	:= 32;
		C_M_AXI_DATA_WIDTH	: integer	:= 32
		);
		port (
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

		-- AXI master interface signals:
		M_AXI_ACLK	: in std_logic;
		M_AXI_ARESETN	: in std_logic;
		M_AXI_AWADDR	: out std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
		M_AXI_AWPROT	: out std_logic_vector(2 downto 0);
		M_AXI_AWVALID	: out std_logic;
		M_AXI_AWREADY	: in std_logic;
		M_AXI_WDATA	: out std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
		M_AXI_WSTRB	: out std_logic_vector(C_M_AXI_DATA_WIDTH/8-1 downto 0);
		M_AXI_WVALID	: out std_logic;
		M_AXI_WREADY	: in std_logic;
		M_AXI_BRESP	: in std_logic_vector(1 downto 0);
		M_AXI_BVALID	: in std_logic;
		M_AXI_BREADY	: out std_logic;
		M_AXI_ARADDR	: out std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
		M_AXI_ARPROT	: out std_logic_vector(2 downto 0);
		M_AXI_ARVALID	: out std_logic;
		M_AXI_ARREADY	: in std_logic;
		M_AXI_RDATA	: in std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
		M_AXI_RRESP	: in std_logic_vector(1 downto 0);
		M_AXI_RVALID	: in std_logic;
		M_AXI_RREADY	: out std_logic
		);
	end component DMA_v1_0_M_AXI;

	component DMA_v1_0_S_AXI is
		generic (
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		C_S_AXI_ADDR_WIDTH	: integer	:= 5
		);
		port (
		-- Signals connected to the DMA module:
		dma_reset     : out std_logic;
		dma_store_req : out std_logic;
		dma_source    : out std_logic_vector(31 downto 0);
		dma_dest      : out std_logic_vector(31 downto 0);
		dma_params    : out std_logic_vector(31 downto 0);

		-- DMA interrupt signals:
		dma_interrupt_in : in std_logic;
		dma_interrupt_id : in std_logic_vector(6 downto 0);

		S_AXI_ACLK	: in std_logic;
		S_AXI_ARESETN	: in std_logic;
		S_AXI_AWADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
		S_AXI_AWVALID	: in std_logic;
		S_AXI_AWREADY	: out std_logic;
		S_AXI_WDATA	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_WSTRB	: in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		S_AXI_WVALID	: in std_logic;
		S_AXI_WREADY	: out std_logic;
		S_AXI_BRESP	: out std_logic_vector(1 downto 0);
		S_AXI_BVALID	: out std_logic;
		S_AXI_BREADY	: in std_logic;
		S_AXI_ARADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
		S_AXI_ARVALID	: in std_logic;
		S_AXI_ARREADY	: out std_logic;
		S_AXI_RDATA	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_RRESP	: out std_logic_vector(1 downto 0);
		S_AXI_RVALID	: out std_logic;
		S_AXI_RREADY	: in std_logic
		);
	end component DMA_v1_0_S_AXI;

	-- DMA module signals:
	signal dma_reset : std_logic;

	-- DMA interrupt signals:
	signal dma_interrupt : std_logic;
	signal dma_interrupt_id : std_logic_vector(6 downto 0);

	-- Request buffer signals:
	signal dma_req_in : std_logic_vector(95 downto 0); -- Load address on high 32 bits, store address next and then data.
	signal dma_req_store : std_logic;

	-- Data buffer signals:
	signal dma_data_in : std_logic_vector(63 downto 0); -- Load address on high 32 bits.
	signal dma_data_store : std_logic;

	-- Output from DMA:
	signal dma_output_store : std_logic;
	signal dma_output_details : std_logic_vector(33 downto 0); -- 2 bits command, 32 bits address
	signal dma_output_data : std_logic_vector(31 downto 0); -- Data output from the DMA

	-- Various status signals:
	signal dma_req_full, dma_data_full, dma_output_full : std_logic;
	signal dma_source, dma_dest, dma_params : std_logic_vector(31 downto 0);

begin

-- Instantiation of Axi Bus Interface M_AXI
DMA_v1_0_M_AXI_inst : DMA_v1_0_M_AXI
	generic map (
		C_M_AXI_ADDR_WIDTH	=> C_M_AXI_ADDR_WIDTH,
		C_M_AXI_DATA_WIDTH	=> C_M_AXI_DATA_WIDTH
	)
	port map (
		master_busy => dma_output_full,

		-- DMA data interface:
		dma_data_out_addr => dma_data_in(63 downto 32),
		dma_data_out => dma_data_in(31 downto 0),
		dma_data_store => dma_data_store,

		-- DMA command interface:
		dma_output_data => dma_output_data,
		dma_output_cmd  => dma_output_details(33 downto 32),
		dma_output_dest => dma_output_details(31 downto  0),
		dma_output_exec => dma_output_store,

		-- DMA interrupt signals:
		dma_interrupt_out => dma_interrupt,
		dma_interrupt_id => dma_interrupt_id,

		M_AXI_ACLK	=> m_axi_aclk,
		M_AXI_ARESETN	=> m_axi_aresetn,
		M_AXI_AWADDR	=> m_axi_awaddr,
		M_AXI_AWPROT	=> m_axi_awprot,
		M_AXI_AWVALID	=> m_axi_awvalid,
		M_AXI_AWREADY	=> m_axi_awready,
		M_AXI_WDATA	=> m_axi_wdata,
		M_AXI_WSTRB	=> m_axi_wstrb,
		M_AXI_WVALID	=> m_axi_wvalid,
		M_AXI_WREADY	=> m_axi_wready,
		M_AXI_BRESP	=> m_axi_bresp,
		M_AXI_BVALID	=> m_axi_bvalid,
		M_AXI_BREADY	=> m_axi_bready,
		M_AXI_ARADDR	=> m_axi_araddr,
		M_AXI_ARPROT	=> m_axi_arprot,
		M_AXI_ARVALID	=> m_axi_arvalid,
		M_AXI_ARREADY	=> m_axi_arready,
		M_AXI_RDATA	=> m_axi_rdata,
		M_AXI_RRESP	=> m_axi_rresp,
		M_AXI_RVALID	=> m_axi_rvalid,
		M_AXI_RREADY	=> m_axi_rready
	);

-- Instantiation of Axi Bus Interface S_AXI
DMA_v1_0_S_AXI_inst : DMA_v1_0_S_AXI
	generic map (
		C_S_AXI_DATA_WIDTH	=> C_S_AXI_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	=> C_S_AXI_ADDR_WIDTH
	)
	port map (
		-- Signals for the DMA module:
		dma_reset => dma_reset,
		dma_store_req => dma_req_store,
		dma_source => dma_source,
		dma_dest => dma_dest,
		dma_params => dma_params,

		dma_interrupt_in => dma_interrupt,
		dma_interrupt_id => dma_interrupt_id,

		-- AXI slave interface signals:
		S_AXI_ACLK	=> s_axi_aclk,
		S_AXI_ARESETN	=> s_axi_aresetn,
		S_AXI_AWADDR	=> s_axi_awaddr,
		S_AXI_AWPROT	=> s_axi_awprot,
		S_AXI_AWVALID	=> s_axi_awvalid,
		S_AXI_AWREADY	=> s_axi_awready,
		S_AXI_WDATA	=> s_axi_wdata,
		S_AXI_WSTRB	=> s_axi_wstrb,
		S_AXI_WVALID	=> s_axi_wvalid,
		S_AXI_WREADY	=> s_axi_wready,
		S_AXI_BRESP	=> s_axi_bresp,
		S_AXI_BVALID	=> s_axi_bvalid,
		S_AXI_BREADY	=> s_axi_bready,
		S_AXI_ARADDR	=> s_axi_araddr,
		S_AXI_ARPROT	=> s_axi_arprot,
		S_AXI_ARVALID	=> s_axi_arvalid,
		S_AXI_ARREADY	=> s_axi_arready,
		S_AXI_RDATA	=> s_axi_rdata,
		S_AXI_RRESP	=> s_axi_rresp,
		S_AXI_RVALID	=> s_axi_rvalid,
		S_AXI_RREADY	=> s_axi_rready
	);

	-- Add user logic here
	dma_req_in <= dma_source & dma_dest & dma_params;
	interrupt <= dma_interrupt;

	-- Instantiate the DMA module:
	dma_module: entity work.DMAToplevel
		port map(
			clk => m_axi_aclk,
			reset => dma_reset,
			reqIn => dma_req_in,
			reqStore => dma_req_store,
			dataIn => dma_data_in,
			dataStore => dma_data_store,
			outputFull => dma_output_full,
			reqFull => dma_req_full,
			dataFull => dma_data_full,
			storeOutput => dma_output_store,
			detailsOut => dma_output_details,
			dataOut => dma_output_data
		);

	-- User logic ends

end arch_imp;

-- Testbench for the DMA master module

-- This testbench tests that the master module can correctly communicate with
-- both the AXI4 interconnect and the DMA module.
-- TODO: Add assertions for automatic testing.

library ieee;
use ieee.std_logic_1164.all;

entity tb_dma_master is
end entity tb_dma_master;

architecture testbench of tb_dma_master is
	-- Clock signal:
	signal m_axi_aclk : std_logic := '0';
	constant clk_period : time := 20 ns;

	-- Reset signal:
	signal m_axi_aresetn : std_logic := '1'; -- Active low

	-- Outputs to the DMA module:
	signal master_busy : std_logic;
	signal dma_data_out_addr, dma_data_out : std_logic_vector(31 downto 0);
	signal dma_data_store : std_logic;

	signal dma_interrupt_id : std_logic_vector(6 downto 0);
	signal dma_interrupt_out : std_logic;

	-- Inputs from the DMA module:
	signal dma_output_data, dma_output_dest : std_logic_vector(31 downto 0) := (others => '0');
	signal dma_output_cmd : std_logic_vector(1 downto 0) := (others => '0');
	signal dma_output_exec : std_logic := '0';

	-- AXI master input signals:
	signal m_axi_awready, m_axi_wready : std_logic := '0';
	signal m_axi_bresp, m_axi_rresp : std_logic_vector(1 downto 0) := (others => '0');
	signal m_axi_rdata : std_logic_vector(31 downto 0) := (others => '0');
	signal m_axi_bvalid, m_axi_arready, m_axi_rvalid : std_logic := '0';

	-- AXI master output signals:
	signal m_axi_awaddr, m_axi_araddr : std_logic_vector(31 downto 0);
	signal m_axi_awprot, m_axi_arprot : std_logic_vector(2 downto 0);
	signal m_axi_awvalid, m_axi_wvalid, m_axi_arvalid, m_axi_rready : std_logic;
	signal m_axi_wdata : std_logic_vector(31 downto 0);
	signal m_axi_wstrb : std_logic_vector(3 downto 0);
	signal m_axi_bready : std_logic;
begin

	uut: entity work.dma_v1_0_m_axi
		port map(
			master_busy => master_busy,
			dma_data_out => dma_data_out,
			dma_data_out_addr => dma_data_out_addr,
			dma_data_store => dma_data_store,
			dma_interrupt_id => dma_interrupt_id,
			dma_interrupt_out => dma_interrupt_out,
			dma_output_data => dma_output_data,
			dma_output_dest => dma_output_dest,
			dma_output_cmd => dma_output_cmd,
			dma_output_exec => dma_output_exec,
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

	clock: process
	begin
		m_axi_aclk <= '0';
		wait for clk_period / 2;
		m_axi_aclk <= '1';
		wait for clk_period / 2; 
	end process clock;

	stimulus: process
		constant CMD_READ : std_logic_vector(1 downto 0) := b"00";
		constant CMD_WRITE : std_logic_vector(1 downto 0) := b"01";
		constant CMD_INTR : std_logic_vector(1 downto 0) := b"10";
		
		procedure issue_command(cmd : in std_logic_vector(1 downto 0);
			address, data : in std_logic_vector(31 downto 0)) is
		begin
			dma_output_cmd <= cmd;
			dma_output_dest <= address;
			dma_output_data <= data;

			if cmd = CMD_READ then
				m_axi_rdata <= data;
			end if;

			wait for clk_period;
			dma_output_exec <= '1';
			wait for clk_period;
			dma_output_exec <= '0';

			if cmd = CMD_WRITE then
				-- Wait until the data has been written to the bus:
				wait until m_axi_wvalid = '0' and m_axi_awvalid = '0';

				-- Send a write acknowledgement:
				m_axi_bvalid <= '1';
				wait until m_axi_bready <= '1';
				wait for clk_period;
				m_axi_bvalid <= '0';
			end if;

			-- Wait until we are ready for another command:
			wait until master_busy = '0';
			wait for clk_period;
		end procedure issue_command;
	begin
		wait for clk_period * 2;
		m_axi_aresetn <= '0';
		wait for clk_period * 2;
		m_axi_aresetn <= '1';
		wait for clk_period * 2;

		-- Do two writes to the bus (yay for Ada-style named procedure parameters):
		issue_command(cmd => CMD_WRITE, address => x"55555555", data => x"deadbeef");
		issue_command(cmd => CMD_WRITE, address => x"aaaaaaaa", data => x"beefdead");

		-- Do two reads from the bus:
		issue_command(cmd => CMD_READ, address => x"12344321", data => x"12345678");
		issue_command(cmd => CMD_READ, address => x"43211234", data => x"87654321");

		-- Issue an interrupt:
		issue_command(cmd => CMD_INTR, address => x"000000cf", data => (others => '0'));

		wait;
	end process stimulus;

	-- The following processes generates responses to the master module's valid signals.

	write_address_proc: process(m_axi_aclk)
	begin
		if rising_edge(m_axi_aclk) then
			if m_axi_awvalid = '1' and m_axi_awready = '0' then
				report "Write address accepted";
				m_axi_awready <= '1';
			elsif m_axi_awready = '1' then
				m_axi_awready <= '0';
			end if;
		end if;
	end process write_address_proc;

	write_data_proc: process(m_axi_aclk)
	begin
		if rising_edge(m_axi_aclk) then
			if m_axi_wvalid = '1' and m_axi_wready = '0' then
				report "Write data accepted";
				m_axi_wready <= '1';
			elsif m_axi_wready = '1' then
				m_axi_wready <= '0';
			end if;
		end if;
	end process write_data_proc;

	read_address_proc: process(m_axi_aclk)
	begin
		if rising_edge(m_axi_aclk) then
			if m_axi_arvalid = '1' and m_axi_arready = '0' then
				report "Read address accepted";
				m_axi_arready <= '1';
			elsif m_axi_arready = '1' then
				m_axi_arready <= '0';
			end if;
		end if;
	end process read_address_proc;

	read_data_proc: process(m_axi_aclk)
	begin
		if rising_edge(m_axi_aclk) then
			if m_axi_rready = '1' then
				m_axi_rvalid <= '1';
				report "Read data transmitted";
			elsif m_axi_rvalid = '1' then
				m_axi_rvalid <= '0';
			end if;
		end if;
	end process read_data_proc;

end architecture testbench;

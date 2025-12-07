module microwatt_wrapper(
`ifdef USE_POWER_PINS
    inout vccd1, // 1.8V
    inout vssd1, // digital ground
`endif
	
input ext_clk,
    input ext_rst,
    input alt_reset,
    input uart0_rxd,
    input [3:0]spi_flash_sdat_i,
    input [31:0] gpio_in,
    input jtag_tck,
    input jtag_tdi,
    input jtag_tms,
    input jtag_trst,
    output uart0_txd,
    output spi_flash_cs_n,
    output spi_flash_clk,
    output [3:0]spi_flash_sdat_o,
    output [3:0]spi_flash_sdat_oe,
    output [31:0] gpio_out,
    output [31:0] gpio_dir,
    output jtag_tdo
);

    wire [3:0] uart1_txd_dummy;
    wire sw_soc_reset_dummy;
    wire run_out_dummy;
    wire run_outs_dummy;
    wire [28:0] wb_dram_in_adr_dummy;
    wire wb_dram_in_cyc_dummy;
    wire [63:0] wb_dram_in_dat_dummy;
    wire [7:0] wb_dram_in_sel_dummy;
    wire wb_dram_in_stb_dummy;
    wire wb_dram_in_we_dummy;
    wire [29:0] wb_ext_io_in_adr_dummy;
    wire wb_ext_io_in_cyc_dummy;
    wire [31:0] wb_ext_io_in_dat_dummy;
    wire [3:0] wb_ext_io_in_sel_dummy;
    wire wb_ext_io_in_stb_dummy;
    wire wb_ext_io_in_we_dummy;
    wire wb_ext_is_dram_csr_dummy;
    wire wb_ext_is_dram_init_dummy;
    wire wb_ext_is_eth_dummy;
    wire wb_ext_is_sdcard_dummy;
    wire wishbone_dma_in_ack_dummy;
    wire [31:0] wishbone_dma_in_dat_dummy;
    wire wishbone_dma_in_stall_dummy;



        soc soc_inst(
`ifdef USE_POWER_PINS
    .vccd1(vccd1),
    .vssd1(vssd1),
`endif
        .rst(ext_rst),
        .system_clk(ext_clk),
	.alt_reset_drive(alt_reset),
        .\wb_dram_out.dat (64'b0),
        .\wb_dram_out.ack (1'b0),
        .\wb_dram_out.stall (1'b0),
        .\wb_ext_io_out.dat (32'b0),
        .\wb_ext_io_out.ack (1'b0),
        .\wb_ext_io_out.stall (1'b0),
        .\wishbone_dma_out.adr (30'b0),
        .\wishbone_dma_out.dat (32'b0),
        .\wishbone_dma_out.sel (4'b0),
        .\wishbone_dma_out.cyc (1'b0),
        .\wishbone_dma_out.stb (1'b0),
        .\wishbone_dma_out.we (1'b0),
        .ext_irq_eth(1'b0),
        .ext_irq_sdcard(1'b0),
        .uart0_rxd(uart0_rxd),
        .uart1_rxd(1'b0),
        .jtag_tck(jtag_tck),
        .jtag_tms(jtag_tms),
        .jtag_tdi(jtag_tdi),
        .jtag_trst(jtag_trst),
        .spi_flash_sdat_i(spi_flash_sdat_i),
        .gpio_in(gpio_in),
        .uart0_txd(uart0_txd),
        .uart1_txd(uart1_txd_dummy),
        .jtag_tdo(jtag_tdo),
        .spi_flash_sck(spi_flash_clk),
        .spi_flash_cs_n(spi_flash_cs_n),
        .spi_flash_sdat_o(spi_flash_sdat_o),
        .spi_flash_sdat_oe(spi_flash_sdat_oe),
        .gpio_out(gpio_out),
        .gpio_dir(gpio_dir),
        .sw_soc_reset(sw_soc_reset_dummy),
        .run_out(run_out_dummy),
        .run_outs(run_outs_dummy),
        .\wb_dram_in.adr (wb_dram_in_adr_dummy),
        .\wb_dram_in.cyc (wb_dram_in_cyc_dummy),
        .\wb_dram_in.dat (wb_dram_in_dat_dummy),
        .\wb_dram_in.sel (wb_dram_in_sel_dummy),
        .\wb_dram_in.stb (wb_dram_in_stb_dummy),
        .\wb_dram_in.we (wb_dram_in_we_dummy),
        .\wb_ext_io_in.adr (wb_ext_io_in_adr_dummy),
        .\wb_ext_io_in.cyc (wb_ext_io_in_cyc_dummy),
        .\wb_ext_io_in.dat (wb_ext_io_in_dat_dummy),
        .\wb_ext_io_in.sel (wb_ext_io_in_sel_dummy),
        .\wb_ext_io_in.stb (wb_ext_io_in_stb_dummy),
        .\wb_ext_io_in.we (wb_ext_io_in_we_dummy),
        .wb_ext_is_dram_csr(wb_ext_is_dram_csr_dummy),
        .wb_ext_is_dram_init(wb_ext_is_dram_init_dummy),
        .wb_ext_is_eth(wb_ext_is_eth_dummy),
        .wb_ext_is_sdcard(wb_ext_is_sdcard_dummy),
        .\wishbone_dma_in.ack (wishbone_dma_in_ack_dummy),
        .\wishbone_dma_in.dat (wishbone_dma_in_dat_dummy),
        .\wishbone_dma_in.stall (wishbone_dma_in_stall_dummy)
    );
    // wire dummy = (uart1_txd_dummy & 1'b0) |
    //              (sw_soc_reset_dummy & 1'b0) |
    //              (run_out_dummy & 1'b0) |
    //              (run_outs_dummy & 1'b0) |
    //              |(wb_dram_in_adr_dummy & 29'b0) |
    //              (wb_dram_in_cyc_dummy & 1'b0) |
    //              |(wb_dram_in_dat_dummy & 64'b0) |
    //              |(wb_dram_in_sel_dummy & 8'b0) |
    //              (wb_dram_in_stb_dummy & 1'b0) |
    //              (wb_dram_in_we_dummy & 1'b0) |
    //              |(wb_ext_io_in_adr_dummy & 30'b0) |
    //              (wb_ext_io_in_cyc_dummy & 1'b0) |
    //              |(wb_ext_io_in_dat_dummy & 32'b0) |
    //              |(wb_ext_io_in_sel_dummy & 4'b0) |
    //              (wb_ext_io_in_stb_dummy & 1'b0) |
    //              (wb_ext_io_in_we_dummy & 1'b0) |
    //              (wb_ext_is_dram_csr_dummy & 1'b0) |
    //              (wb_ext_is_dram_init_dummy & 1'b0) |
    //              (wb_ext_is_eth_dummy & 1'b0) |
    //              (wb_ext_is_sdcard_dummy & 1'b0) |
    //              (wishbone_dma_in_ack_dummy & 1'b0) |
    //              |(wishbone_dma_in_dat_dummy & 32'b0) |
    //              (wishbone_dma_in_stall_dummy & 1'b0);

endmodule

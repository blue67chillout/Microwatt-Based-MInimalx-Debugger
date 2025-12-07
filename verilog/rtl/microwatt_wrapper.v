module microwatt_wrapper_usb(
`ifdef USE_POWER_PINS
    inout vccd1,
    inout vssd1,
`endif
    // SoC clock / reset / IO
    input        ext_clk,
    input        ext_rst,
    input        alt_reset,
    input        uart0_rxd,
    input        spi_flash_sdat_i_q,
    input  [7:0] gpio_in_q,

    // JTAG (external)
    input        jtag_tck,
    input        jtag_tdi,
    input        jtag_tms,
    input        jtag_trst,

    output       tck_o,
    output       tms_o,
    output       tdi_o,
    output       trst_o,
    input        tdo_i,
    output       expose_o,

    // UART 0
    output       uart0_txd,

    // SPI flash
    output       spi_flash_cs_n,
    output       spi_flash_clk,
    output       spi_flash_sdat_o_q,
    output [1:0] spi_flash_sdat_oe_q,

    // GPIO (low-pin bundle to openframe)
    output [7:0] gpio_out_q,
    output [7:0] gpio_dir_q,

    // *** ULPI interface to external PHY ***
    input        ulpi_clk60_i,        // 60 MHz clock from ULPI PHY
    input  [7:0] ulpi_data_out_i,     // DATA[7:0] from PHY (DIR=1)
    input        ulpi_dir_i,          // DIR from PHY
    input        ulpi_nxt_i,          // NXT from PHY
    output [7:0] ulpi_data_in_o,      // DATA[7:0] to PHY (DIR=0)
    output       ulpi_stp_o,          // STP to PHY

    // JTAG daisy-chain out of SoC
    output       jtag_tdo
);

    // ------------------------------------------------------------
    // Internal "unused" / dummy wires for SoC side
    // ------------------------------------------------------------
    wire [3:0]  uart1_txd_dummy;
    wire        sw_soc_reset_dummy;
    wire        run_out_dummy;
    wire        run_outs_dummy;
    wire [28:0] wb_dram_in_adr_dummy;
    wire        wb_dram_in_cyc_dummy;
    wire [63:0] wb_dram_in_dat_dummy;
    wire [7:0]  wb_dram_in_sel_dummy;
    wire        wb_dram_in_stb_dummy;
    wire        wb_dram_in_we_dummy;
    wire [29:0] wb_ext_io_in_adr_dummy;
    wire        wb_ext_io_in_cyc_dummy;
    wire [31:0] wb_ext_io_in_dat_dummy;
    wire [3:0]  wb_ext_io_in_sel_dummy;
    wire        wb_ext_io_in_stb_dummy;
    wire        wb_ext_io_in_we_dummy;
    wire        wb_ext_is_dram_csr_dummy;
    wire        wb_ext_is_dram_init_dummy;
    wire        wb_ext_is_eth_dummy;
    wire        wb_ext_is_sdcard_dummy;
    wire        wishbone_dma_in_ack_dummy;
    wire [31:0] wishbone_dma_in_dat_dummy;
    wire        wishbone_dma_in_stall_dummy;

    // SPI flash bus
    wire [3:0] spi_flash_sdat_oe;
    wire [3:0] spi_flash_sdat_o;
    wire [3:0] spi_flash_sdat_i;

    // Map single-bit in/out/oe to SoC 4-bit bus
    assign spi_flash_sdat_i[0] = 1'b0;
    assign spi_flash_sdat_i[2] = 1'b0;
    assign spi_flash_sdat_i[3] = 1'b0;

    assign spi_flash_sdat_o_q  = spi_flash_sdat_o[0];
    assign spi_flash_sdat_i[1] = spi_flash_sdat_i_q;
    assign spi_flash_sdat_oe_q = ~spi_flash_sdat_oe[1:0];

    // GPIO bundle into SoC
    wire [31:0] gpio_in;
    wire [31:0] gpio_out;
    wire [31:0] gpio_dir;

    assign gpio_in    = {24'b0, gpio_in_q};
    assign gpio_out_q = gpio_out[7:0];
    assign gpio_dir_q = ~gpio_dir[7:0];

    // ------------------------------------------------------------
    // UTMI side signals between SoC and ULPI wrapper (SoC domain)
    // ------------------------------------------------------------
    wire [7:0] utmi_data_in;      // to SoC (RX data, ext_clk)
    wire [7:0] utmi_data_out;     // from SoC (TX data, ext_clk)
    wire       utmi_txvalid;      // from SoC
    wire       utmi_txready;      // to SoC (we'll drive this via TX FIFO)
    wire       utmi_rxvalid;      // to SoC
    wire       utmi_rxactive;     // to SoC
    wire       utmi_rxerror;      // to SoC
    wire [1:0] utmi_linestate;    // to SoC
    wire [1:0] utmi_op_mode;      // from SoC
    wire [1:0] utmi_xcvrselect;   // from SoC
    wire       utmi_termselect;   // from SoC
    wire       utmi_dppulldown;   // from SoC
    wire       utmi_dmpulldown;   // from SoC

    // ------------------------------------------------------------
    // SoC instance (Microwatt SoC + USB host with UTMI interface)
    // ------------------------------------------------------------
    soc soc_inst (
`ifdef USE_POWER_PINS
        .vccd1(vccd1),
        .vssd1(vssd1),
`endif
        .rst                (ext_rst),
        .system_clk         (ext_clk),
        .alt_reset_drive    (alt_reset),

        // DRAM / ext IO / DMA all tied off
        .\wb_dram_out.dat   (64'b0),
        .\wb_dram_out.ack   (1'b0),
        .\wb_dram_out.stall (1'b0),
        .\wb_ext_io_out.dat (32'b0),
        .\wb_ext_io_out.ack (1'b0),
        .\wb_ext_io_out.stall (1'b0),
        .\wishbone_dma_out.adr (30'b0),
        .\wishbone_dma_out.dat (32'b0),
        .\wishbone_dma_out.sel (4'b0),
        .\wishbone_dma_out.cyc (1'b0),
        .\wishbone_dma_out.stb (1'b0),
        .\wishbone_dma_out.we  (1'b0),

        .ext_irq_eth        (1'b0),
        .ext_irq_sdcard     (1'b0),

        // UARTs
        .uart0_rxd          (uart0_rxd),
        .uart1_rxd          (1'b0),
        .uart0_txd          (uart0_txd),
        .uart1_txd          (uart1_txd_dummy),

        // JTAG into SoC
        .jtag_tck           (jtag_tck),
        .jtag_tms           (jtag_tms),
        .jtag_tdi           (jtag_tdi),
        .jtag_trst          (jtag_trst),
        .jtag_tdo           (jtag_tdo),

        // SPI flash
        .spi_flash_sdat_i   (spi_flash_sdat_i),
        .spi_flash_sck      (spi_flash_clk),
        .spi_flash_cs_n     (spi_flash_cs_n),
        .spi_flash_sdat_o   (spi_flash_sdat_o),
        .spi_flash_sdat_oe  (spi_flash_sdat_oe),

        // GPIO bundle
        .gpio_in            (gpio_in),
        .gpio_out           (gpio_out),
        .gpio_dir           (gpio_dir),

        // =======================
        // USB UTMI interface (SoC @ ext_clk)
        // =======================
        .usb_utmi_data_in    (utmi_data_in),
        .usb_utmi_txready    (utmi_txready),
        .usb_utmi_rxvalid    (utmi_rxvalid),
        .usb_utmi_rxactive   (utmi_rxactive),
        .usb_utmi_rxerror    (utmi_rxerror),
        .usb_utmi_linestate  (utmi_linestate),
        .usb_utmi_data_out   (utmi_data_out),
        .usb_utmi_txvalid    (utmi_txvalid),
        .usb_utmi_op_mode    (utmi_op_mode),
        .usb_utmi_xcvrselect (utmi_xcvrselect),
        .usb_utmi_termselect (utmi_termselect),
        .usb_utmi_dppulldown (utmi_dppulldown),
        .usb_utmi_dmpulldown (utmi_dmpulldown),

        // JTAG Master exported out of SoC
        .tdo_i              (tdo_i),
        .tck_o              (tck_o),
        .tms_o              (tms_o),
        .tdi_o              (tdi_o),
        .trst_o             (trst_o),
        .expose_o           (expose_o),

        // Misc
        .sw_soc_reset       (sw_soc_reset_dummy),
        .run_out            (run_out_dummy),
        .run_outs           (run_outs_dummy),
        .\wb_dram_in.adr    (wb_dram_in_adr_dummy),
        .\wb_dram_in.cyc    (wb_dram_in_cyc_dummy),
        .\wb_dram_in.dat    (wb_dram_in_dat_dummy),
        .\wb_dram_in.sel    (wb_dram_in_sel_dummy),
        .\wb_dram_in.stb    (wb_dram_in_stb_dummy),
        .\wb_dram_in.we     (wb_dram_in_we_dummy),
        .\wb_ext_io_in.adr  (wb_ext_io_in_adr_dummy),
        .\wb_ext_io_in.cyc  (wb_ext_io_in_cyc_dummy),
        .\wb_ext_io_in.dat  (wb_ext_io_in_dat_dummy),
        .\wb_ext_io_in.sel  (wb_ext_io_in_sel_dummy),
        .\wb_ext_io_in.stb  (wb_ext_io_in_stb_dummy),
        .\wb_ext_io_in.we   (wb_ext_io_in_we_dummy),
        .wb_ext_is_dram_csr (wb_ext_is_dram_csr_dummy),
        .wb_ext_is_dram_init(wb_ext_is_dram_init_dummy),
        .wb_ext_is_eth      (wb_ext_is_eth_dummy),
        .wb_ext_is_sdcard   (wb_ext_is_sdcard_dummy),
        .\wishbone_dma_in.ack   (wishbone_dma_in_ack_dummy),
        .\wishbone_dma_in.dat   (wishbone_dma_in_dat_dummy),
        .\wishbone_dma_in.stall (wishbone_dma_in_stall_dummy)
    );

    // ------------------------------------------------------------
    // TX PATH: UTMI (ext_clk) -> ULPI (ulpi_clk60_i) via async FIFO
    // ------------------------------------------------------------

    // Write side (SoC / UTMI clock domain)
    wire       txfifo_full;
    reg        txfifo_wr_en;
    reg [7:0]  txfifo_wr_data;

    always @(posedge ext_clk or posedge ext_rst) begin
        if (ext_rst) begin
            txfifo_wr_en   <= 1'b0;
            txfifo_wr_data <= 8'h00;
        end else begin
            txfifo_wr_en <= 1'b0;
            // Accept one byte when SoC asserts valid & we report ready
            if (utmi_txvalid && utmi_txready && !txfifo_full) begin
                txfifo_wr_en   <= 1'b1;
                txfifo_wr_data <= utmi_data_out;
            end
        end
    end

    // SoC sees "ready" whenever TX FIFO has space
    assign utmi_txready = ~txfifo_full;

    // Read side (ULPI / 60MHz domain)
    wire       txfifo_empty;
    wire [7:0] txfifo_rd_data;
    reg        txfifo_rd_en_q;
    reg [7:0]  utmi_data_out_ulpi;
    reg        utmi_txvalid_ulpi;

    async_fifo #(
        .WIDTH      (8),
        .ADDR_WIDTH (4)     // 16-entry TX FIFO; adjust if needed
    ) u_tx_async_fifo (
        .wr_clk  (ext_clk),
        .wr_rst  (ext_rst),
        .wr_en   (txfifo_wr_en),
        .wr_data (txfifo_wr_data),
        .full    (txfifo_full),

        .rd_clk  (ulpi_clk60_i),
        .rd_rst  (ext_rst),
        .rd_en   (txfifo_rd_en_q),
        .rd_data (txfifo_rd_data),
        .empty   (txfifo_empty)
    );

    // ------------------------------------------------------------
    // CDC for relatively static UTMI config signals (TX side)
    // ------------------------------------------------------------
    wire [1:0] utmi_op_mode_sync;
    wire [1:0] utmi_xcvrselect_sync;
    wire       utmi_termselect_sync;
    wire       utmi_dppulldown_sync;
    wire       utmi_dmpulldown_sync;

    sync_bus  #(2) sync_utmi_opmode (
        .clk_dst (ulpi_clk60_i),
        .in_bus  (utmi_op_mode),
        .out_bus (utmi_op_mode_sync)
    );
    sync_bus  #(2) sync_utmi_xcvr (
        .clk_dst (ulpi_clk60_i),
        .in_bus  (utmi_xcvrselect),
        .out_bus (utmi_xcvrselect_sync)
    );
    sync_bit sync_utmi_term (
        .clk_dst (ulpi_clk60_i),
        .in_bit  (utmi_termselect),
        .out_bit (utmi_termselect_sync)
    );
    sync_bit sync_utmi_dp (
        .clk_dst (ulpi_clk60_i),
        .in_bit  (utmi_dppulldown),
        .out_bit (utmi_dppulldown_sync)
    );
    sync_bit sync_utmi_dm (
        .clk_dst (ulpi_clk60_i),
        .in_bit  (utmi_dmpulldown),
        .out_bit (utmi_dmpulldown_sync)
    );

    // ------------------------------------------------------------
    // ULPI <-> UTMI bridge (runs in ulpi_clk60_i domain)
    // ------------------------------------------------------------
    wire [7:0] utmi_data_in_raw;
    wire       utmi_txready_raw;
    wire       utmi_rxvalid_raw;
    wire       utmi_rxactive_raw;
    wire       utmi_rxerror_raw;
    wire [1:0] utmi_linestate_raw;

    // Drive ulpi_wrapper with bytes popped from TX FIFO
    always @(posedge ulpi_clk60_i or posedge ext_rst) begin
        if (ext_rst) begin
            txfifo_rd_en_q    <= 1'b0;
            utmi_data_out_ulpi <= 8'h00;
            utmi_txvalid_ulpi <= 1'b0;
        end else begin
            txfifo_rd_en_q    <= 1'b0;
            utmi_txvalid_ulpi <= 1'b0;

            // When ULPI wrapper is ready for a byte and FIFO not empty,
            // present one byte and pop it.
            if (!txfifo_empty && utmi_txready_raw) begin
                txfifo_rd_en_q    <= 1'b1;
                utmi_data_out_ulpi <= txfifo_rd_data;
                utmi_txvalid_ulpi <= 1'b1;
            end
        end
    end

    ulpi_wrapper u_ulpi (
        // ULPI side (to external PHY)
        .ulpi_clk60_i     (ulpi_clk60_i),
        .ulpi_rst_i       (ext_rst),          // can replace with dedicated reset
        .ulpi_data_out_i  (ulpi_data_out_i),  // from PHY
        .ulpi_dir_i       (ulpi_dir_i),
        .ulpi_nxt_i       (ulpi_nxt_i),

        // ULPI outputs
        .ulpi_data_in_o   (ulpi_data_in_o),   // to PHY
        .ulpi_stp_o       (ulpi_stp_o),

        // UTMI side from SoC (TX direction, now in ULPI domain)
        .utmi_data_out_i   (utmi_data_out_ulpi),
        .utmi_txvalid_i    (utmi_txvalid_ulpi),
        .utmi_op_mode_i    (utmi_op_mode_sync),
        .utmi_xcvrselect_i (utmi_xcvrselect_sync),
        .utmi_termselect_i (utmi_termselect_sync),
        .utmi_dppulldown_i (utmi_dppulldown_sync),
        .utmi_dmpulldown_i (utmi_dmpulldown_sync),

        // UTMI side into SoC (RX + status) in 60 MHz domain
        .utmi_data_in_o    (utmi_data_in_raw),
        .utmi_txready_o    (utmi_txready_raw),   // used only in ULPI domain (see above)
        .utmi_rxvalid_o    (utmi_rxvalid_raw),
        .utmi_rxactive_o   (utmi_rxactive_raw),
        .utmi_rxerror_o    (utmi_rxerror_raw),
        .utmi_linestate_o  (utmi_linestate_raw)
    );

    // ------------------------------------------------------------
    // CDC BACK: ULPI (60 MHz) -> UTMI SoC (50 MHz)  --- RX SIDE
    // ------------------------------------------------------------

    // 1) Control/status bits: use simple synchronizers back to ext_clk

    sync_bit sync_rxactive (
        .clk_dst (ext_clk),
        .in_bit  (utmi_rxactive_raw),
        .out_bit (utmi_rxactive)
    );
    sync_bit sync_rxerror (
        .clk_dst (ext_clk),
        .in_bit  (utmi_rxerror_raw),
        .out_bit (utmi_rxerror)
    );
    sync_bus #(2) sync_linestate (
        .clk_dst (ext_clk),
        .in_bus  (utmi_linestate_raw),
        .out_bus (utmi_linestate)
    );

    // 2) RX DATA path: use async FIFO (60 MHz write, 50 MHz read)

    wire        fifo_full;
    wire        fifo_empty;
    wire [7:0]  fifo_rd_data;
    reg         fifo_rd_en_q;
    reg [7:0]   utmi_data_in_q;
    reg         utmi_rxvalid_q;

    async_fifo #(
        .WIDTH      (8),
        .ADDR_WIDTH (3)    // depth = 8 entries
    ) u_rx_async_fifo (
        .wr_clk  (ulpi_clk60_i),
        .wr_rst  (ext_rst),
        .wr_en   (utmi_rxvalid_raw),
        .wr_data (utmi_data_in_raw),
        .full    (fifo_full),

        .rd_clk  (ext_clk),
        .rd_rst  (ext_rst),
        .rd_en   (fifo_rd_en_q),
        .rd_data (fifo_rd_data),
        .empty   (fifo_empty)
    );

    // Drain FIFO in SoC clock domain and generate UTMI RXVALID + DATA
    always @(posedge ext_clk or posedge ext_rst) begin
        if (ext_rst) begin
            fifo_rd_en_q   <= 1'b0;
            utmi_data_in_q <= 8'h00;
            utmi_rxvalid_q <= 1'b0;
        end else begin
            if (!fifo_empty) begin
                // read one byte per ext_clk cycle while available
                fifo_rd_en_q   <= 1'b1;
                utmi_data_in_q <= fifo_rd_data;
                utmi_rxvalid_q <= 1'b1;
            end else begin
                fifo_rd_en_q   <= 1'b0;
                utmi_rxvalid_q <= 1'b0;
            end
        end
    end

    assign utmi_data_in = utmi_data_in_q;
    assign utmi_rxvalid = utmi_rxvalid_q;

endmodule

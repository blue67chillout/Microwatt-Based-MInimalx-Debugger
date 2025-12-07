`default_nettype none
module openframe_project_wrapper(
`ifdef USE_POWER_PINS
    inout vdda, inout vdda1, inout vdda2,
    inout vssa, inout vssa1, inout vssa2,
    inout vccd, inout vccd1, inout vccd2,
    inout vssd, inout vssd1, inout vssd2,
    inout vddio, inout vssio,
`endif
    input  porb_h, input porb_l, input por_l,
    input  resetb_h, input resetb_l,
    input  [31:0] mask_rev,
    input  [`OPENFRAME_IO_PADS-1:0] gpio_in,
    input  [`OPENFRAME_IO_PADS-1:0] gpio_in_h,
    output [`OPENFRAME_IO_PADS-1:0] gpio_out,
    output [`OPENFRAME_IO_PADS-1:0] gpio_oeb,
    output [`OPENFRAME_IO_PADS-1:0] gpio_inp_dis,
    output [`OPENFRAME_IO_PADS-1:0] gpio_ib_mode_sel,
    output [`OPENFRAME_IO_PADS-1:0] gpio_vtrip_sel,
    output [`OPENFRAME_IO_PADS-1:0] gpio_slow_sel,
    output [`OPENFRAME_IO_PADS-1:0] gpio_holdover,
    output [`OPENFRAME_IO_PADS-1:0] gpio_analog_en,
    output [`OPENFRAME_IO_PADS-1:0] gpio_analog_sel,
    output [`OPENFRAME_IO_PADS-1:0] gpio_analog_pol,
    output [`OPENFRAME_IO_PADS-1:0] gpio_dm2,
    output [`OPENFRAME_IO_PADS-1:0] gpio_dm1,
    output [`OPENFRAME_IO_PADS-1:0] gpio_dm0,
    inout  [`OPENFRAME_IO_PADS-1:0] analog_io,
    inout  [`OPENFRAME_IO_PADS-1:0] analog_noesd_io,
    input  [`OPENFRAME_IO_PADS-1:0] gpio_loopback_one,
    input  [`OPENFRAME_IO_PADS-1:0] gpio_loopback_zero
);

    // ------------------------------------------------------------
    // Tie off analog lines
    // ------------------------------------------------------------
    assign gpio_analog_en  = gpio_loopback_zero;
    assign gpio_analog_pol = gpio_loopback_zero;
    assign gpio_analog_sel = gpio_loopback_zero;
    assign gpio_holdover   = gpio_loopback_zero;

    // ------------------------------------------------------------
    // JTAG expose gate (same as before)
    // ------------------------------------------------------------
    wire expose_o;

    assign gpio_oeb[3]   = expose_o;
    assign gpio_oeb[2:0] = {~expose_o, ~expose_o, ~expose_o};
    assign gpio_oeb[43]  = ~expose_o;

    // ------------------------------------------------------------
    // ULPI core wires (inside the user macro)
    // ------------------------------------------------------------
    wire [7:0] ulpi_data_in_core;   // from core to PHY (goes to gpio_out)
    wire [7:0] ulpi_data_out_core;  // from PHY to core (comes from gpio_in)
    wire       ulpi_stp_core;       // STP from core to PHY

    // Map ULPI data coming from pads into the core
    // Use gpio_in[22:15] as ULPI_DATA[7:0] from external PHY (when DIR=1)
    assign ulpi_data_out_core = gpio_in[22:15];

    // ------------------------------------------------------------
    // Microwatt + USB + ULPI wrapper instance
    // ------------------------------------------------------------
    microwatt_wrapper_usb mprj (
    `ifdef USE_POWER_PINS
        .vccd1      (vccd1),
        .vssd1      (vssd1),
    `endif
        // SoC clock / reset
        .ext_clk    (gpio_in[38]),
        .ext_rst    (gpio_in[39]),
        .alt_reset  (gpio_in[40]),

        // UART
        .uart0_rxd  (gpio_in[41]),
        .uart0_txd  (gpio_out[42]),

        // JTAG into SoC
        .jtag_tck   (gpio_in[0]),
        .jtag_tdi   (gpio_in[1]),
        .jtag_tms   (gpio_in[2]),
        .jtag_trst  (gpio_in[43]),
        .jtag_tdo   (gpio_out[3]),

        // SPI flash
        .spi_flash_sdat_i_q (gpio_in[4]),
        .spi_flash_sdat_o_q (gpio_out[5]),
        .spi_flash_sdat_oe_q(gpio_oeb[5:4]),
        .spi_flash_cs_n     (gpio_out[6]),
        .spi_flash_clk      (gpio_out[7]),

        // JTAG master from SoC back out
        .tdo_i      (gpio_in[3]),
        .tck_o      (gpio_out[0]),
        .tms_o      (gpio_out[2]),
        .tdi_o      (gpio_out[1]),
        .trst_o     (gpio_out[43]),
        .expose_o   (expose_o),

        // General-purpose GPIO slice to SoC
        .gpio_in_q  (gpio_in[37:30]),
        .gpio_out_q (gpio_out[37:30]),
        .gpio_dir_q (gpio_oeb[37:30]),

        // =============================
        // ULPI interface (to external PHY)
        // =============================
        .ulpi_clk60_i    (gpio_in[11]),      // 60 MHz clock from PHY
        .ulpi_data_out_i (ulpi_data_out_core), // DATA[7:0] from PHY via gpio_in[22:15]
        .ulpi_dir_i      (gpio_in[12]),      // DIR from PHY
        .ulpi_nxt_i      (gpio_in[13]),      // NXT from PHY
        .ulpi_data_in_o  (ulpi_data_in_core),// DATA[7:0] from core to PHY
        .ulpi_stp_o      (ulpi_stp_core)     // STP to PHY
    );

    // ------------------------------------------------------------
    // ULPI pads mapping & OEB control
    // ------------------------------------------------------------

    // STP: pure output from core to PHY on gpio[14]
    assign gpio_out[14] = ulpi_stp_core;
    assign gpio_oeb[14] = 1'b0;   // drive enabled

    // ULPI DIR, NXT, CLK are inputs from PHY -> core
    assign gpio_oeb[11] = 1'b1;   // ulpi_clk60_i input
    assign gpio_oeb[12] = 1'b1;   // ulpi_dir_i input
    assign gpio_oeb[13] = 1'b1;   // ulpi_nxt_i input

    // ULPI DATA[7:0] on gpio[22:15]
    //  - When DIR=0 (host/core driving), oeb=0 => drive DATA to PHY
    //  - When DIR=1 (PHY driving),  oeb=1 => hi-Z, core only samples gpio_in
    assign gpio_out[22:15] = ulpi_data_in_core;

    genvar i;
    generate
        for (i = 15; i <= 22; i = i + 1) begin : gen_ulpi_data_oeb
            assign gpio_oeb[i] = gpio_in[12] ? 1'b1 : 1'b0; // DIR=1 => input (disable drive)
        end
    endgenerate 

     	assign gpio_oeb[38] = 1'b1; // ext_clk input
 	assign gpio_oeb[39] = 1'b1; // ext_rst input
 	assign gpio_oeb[41] = 1'b1; // uart0_rxd input
 	assign gpio_oeb[40] = 1'b1; // alt_reset input
 	assign gpio_oeb[42] = 1'b0; // uart0_txd output
    // ------------------------------------------------------------
    // Configuration and unused pins tie-offs
    // ------------------------------------------------------------
    assign gpio_inp_dis     = gpio_loopback_zero;
    assign gpio_ib_mode_sel = gpio_loopback_zero;
    assign gpio_vtrip_sel   = gpio_loopback_zero;
    assign gpio_slow_sel    = gpio_loopback_zero;
    assign gpio_dm2         = gpio_loopback_zero;
    assign gpio_dm1         = gpio_loopback_zero;
    assign gpio_dm0         = gpio_loopback_zero;

    // Keep power tie cells (as before)
    (* keep *) vccd1_connection vccd1_connection ();
    (* keep *) vssd1_connection vssd1_connection ();

endmodule

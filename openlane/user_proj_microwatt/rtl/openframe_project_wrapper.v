// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
`define OPENFRAME_IO_PADS 44

/*
 *-------------------------------------------------------------
 *
 * openframe_project_wrapper
 *
 * This wrapper enumerates all of the pins available to the
 * user for the user openframe project.
 *
 * Written by Tim Edwards
 * March 27, 2023
 * Efabless Corporation
 *
 *-------------------------------------------------------------
 */

module openframe_project_wrapper (
`ifdef USE_POWER_PINS
    inout vdda,		// User area 0 3.3V supply
    inout vdda1,	// User area 1 3.3V supply
    inout vdda2,	// User area 2 3.3V supply
    inout vssa,		// User area 0 analog ground
    inout vssa1,	// User area 1 analog ground
    inout vssa2,	// User area 2 analog ground
    inout vccd,		// Common 1.8V supply
    inout vccd1,	// User area 1 1.8V supply
    inout vccd2,	// User area 2 1.8v supply
    inout vssd,		// Common digital ground
    inout vssd1,	// User area 1 digital ground
    inout vssd2,	// User area 2 digital ground
    inout vddio,	// Common 3.3V ESD supply
    inout vssio,	// Common ESD ground
`endif

    /* Signals exported from the frame area to the user project */
    /* The user may elect to use any of these inputs.		*/

    input	 porb_h,	// power-on reset, sense inverted, 3.3V domain
    input	 porb_l,	// power-on reset, sense inverted, 1.8V domain
    input	 por_l,		// power-on reset, noninverted, 1.8V domain
    input	 resetb_h,	// master reset, sense inverted, 3.3V domain
    input	 resetb_l,	// master reset, sense inverted, 1.8V domain
    input [31:0] mask_rev,	// 32-bit user ID, 1.8V domain

    /* GPIOs.  There are 44 GPIOs (19 left, 19 right, 6 bottom). */
    /* These must be configured appropriately by the user project. */

    /* Basic bidirectional I/O.  Input gpio_in_h is in the 3.3V domain;  all
     * others are in the 1.8v domain.  OEB is output enable, sense inverted.
     */
    input  [`OPENFRAME_IO_PADS-1:0] gpio_in,
    input  [`OPENFRAME_IO_PADS-1:0] gpio_in_h,
    output [`OPENFRAME_IO_PADS-1:0] gpio_out,
    output [`OPENFRAME_IO_PADS-1:0] gpio_oeb,
    output [`OPENFRAME_IO_PADS-1:0] gpio_inp_dis,	// a.k.a. ieb

    /* Pad configuration.  These signals are usually static values.
     * See the documentation for the sky130_fd_io__gpiov2 cell signals
     * and their use.
     */
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

    /* These signals correct directly to the pad.  Pads using analog I/O
     * connections should keep the digital input and output buffers turned
     * off.  Both signals connect to the same pad.  The "noesd" signal
     * is a direct connection to the pad;  the other signal connects through
     * a series resistor which gives it minimal ESD protection.  Both signals
     * have basic over- and under-voltage protection at the pad.  These
     * signals may be expected to attenuate heavily above 50MHz.
     */
    inout  [`OPENFRAME_IO_PADS-1:0] analog_io,
    inout  [`OPENFRAME_IO_PADS-1:0] analog_noesd_io,

    /* These signals are constant one and zero in the 1.8V domain, one for
     * each GPIO pad, and can be looped back to the control signals on the
     * same GPIO pad to set a static configuration at power-up.
     */
    input  [`OPENFRAME_IO_PADS-1:0] gpio_loopback_one,
    input  [`OPENFRAME_IO_PADS-1:0] gpio_loopback_zero
);

// 	user_proj_timer mprj (
// `ifdef USE_POWER_PINS
// 		.vccd1(vccd1),
// 		.vssd1(vssd1),
// `endif
//         .wb_clk_i(gpio_in[0]),
//         .wb_rst_i(gpio_in[1]),
//         .io_in(gpio_in[12:2]),
//         .io_out(gpio_out[12:2]),
//         .io_oeb(gpio_oeb[12:2])

// 	    /* NOTE:  Openframe signals not used in picosoc:	*/
// 	    /* porb_h:    3.3V domain signal			*/
// 	    /* resetb_h:  3.3V domain signal			*/
// 	    /* gpio_in_h: 3.3V domain signals			*/
// 	    /* analog_io: analog signals			*/
// 	    /* analog_noesd_io: analog signals			*/
// 	);



	/* All analog enable/select/polarity and holdover bits	*/
	/* will not be handled in the picosoc module.  Tie	*/
	/* each one of them off to the local loopback zero bit.	*/

	assign gpio_analog_en = gpio_loopback_zero;
	assign gpio_analog_pol = gpio_loopback_zero;
	assign gpio_analog_sel = gpio_loopback_zero;
	assign gpio_holdover = gpio_loopback_zero;

	// assign gpio_in[10] = 0;
 //    assign gpio_in[9] = 0;
 //    assign gpio_in[7] = 0;

    // assign gpio_out[10] = 0;
    // assign gpio_out[9] = 0;
    // assign gpio_out[7] = 0;

	// Instantiate microwatt_wrapper
	wire [31:0] microwatt_gpio_dir;
	wire [31:0] microwatt_gpio_out;
	wire [3:0] spi_flash_sdat_oe;
    wire [3:0] spi_flash_sdat_o;
    wire [3:0] spi_flash_sdat_i;

    assign spi_flash_sdat_i[0] = 0;
    assign spi_flash_sdat_i[2] = 0;
    assign spi_flash_sdat_i[3] = 0;
    assign gpio_out[7] = spi_flash_sdat_o[0];
    assign spi_flash_sdat_i[1] = gpio_in[8];

	microwatt_wrapper microwatt_inst (
`ifdef USE_POWER_PINS
    .vccd1(vccd1),
    .vssd1(vssd1),
`endif 
 		.ext_clk(gpio_in[0]),
 		.ext_rst(gpio_in[1]),
		.alt_reset(gpio_in[10]),
 		.uart0_rxd(gpio_in[2]),
 		.uart0_txd(gpio_out[13]),
 		.jtag_tck(gpio_in[3]),
 		.jtag_tdi(gpio_in[4]),
 		.jtag_tms(gpio_in[5]),
 		.jtag_trst(gpio_in[6]),
 		.jtag_tdo(gpio_out[14]),
 		.spi_flash_sdat_i(spi_flash_sdat_i),
 		.spi_flash_sdat_o(spi_flash_sdat_o),
 		.spi_flash_sdat_oe(spi_flash_sdat_oe),
 		.spi_flash_cs_n(gpio_out[11]),
 		.spi_flash_clk(gpio_out[12]),
 		.gpio_in({3'b0, gpio_in[43:15]}),
 		.gpio_out(microwatt_gpio_out),
 		.gpio_dir(microwatt_gpio_dir)
 	);

 	// Assign microwatt outputs to GPIOs
 	assign gpio_out[43:15] = microwatt_gpio_out[28:0];
 
 	// Set gpio_oeb for GPIOs used by microwatt
 	assign gpio_oeb[43:15] = ~microwatt_gpio_dir[28:0];

 	// Set gpio_oeb for fixed-direction GPIOs
 	assign gpio_oeb[0] = 1'b1; // ext_clk input
 	assign gpio_oeb[1] = 1'b1; // ext_rst input
 	assign gpio_oeb[2] = 1'b1; // uart0_rxd input
 	assign gpio_oeb[3] = 1'b1; // jtag_tck input
 	assign gpio_oeb[4] = 1'b1; // jtag_tdi input
 	assign gpio_oeb[5] = 1'b1; // jtag_tms input
 	assign gpio_oeb[6] = 1'b1; // jtag_trst input
 	assign gpio_oeb[11] = 1'b0; // spi_flash_cs_n output
 	assign gpio_oeb[12] = 1'b0; // spi_flash_clk output
 	assign gpio_oeb[13] = 1'b0; // uart0_txd output
 	assign gpio_oeb[14] = 1'b0; // jtag_tdo output
 	// gpio_oeb[10:7] controlled by spi_flash_sdat_oe from microwatt for bidirectional SPI data

 	// Set gpio configurations for used pins
 	// For simplicity, set ib_mode_sel, vtrip_sel, slow_sel, dm2, dm1, dm0 to default
 	assign gpio_ib_mode_sel = gpio_loopback_zero;
 	assign gpio_vtrip_sel = gpio_loopback_zero;
 	assign gpio_slow_sel = gpio_loopback_zero;
 	assign gpio_dm2 = gpio_loopback_zero;
 	assign gpio_dm1 = gpio_loopback_zero;
 	assign gpio_dm0 = gpio_loopback_zero;
 	assign gpio_inp_dis = gpio_loopback_zero;

     //(* keep *) vccd1_connection vccd1_connection ();
     //(* keep *) vssd1_connection vssd1_connection ();

 endmodule // openframe_project_wrapper

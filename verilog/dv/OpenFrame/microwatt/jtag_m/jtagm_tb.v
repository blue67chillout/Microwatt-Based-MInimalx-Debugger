`default_nettype none
`timescale 1 ns / 1 ps

module jtagm_tb;
	reg clock;
	reg RSTB;
	reg microwatt_reset;
	reg power1, power2;
	reg power3, power4;

	wire [43:0] gpio_in;
	wire [43:0] gpio_out;
	wire [43:0] gpio_oeb;

	wire [15:0] checkbits;
	wire user_flash_csb;
	wire user_flash_clk;
	inout user_flash_io0;
	inout user_flash_io1;

	wire tdo;
	reg tms;
	reg tck;
	reg tdi;


    assign gpio_in[40] = 1'b1;	 //alr_reset high to boot the firmware from external flash


	assign gpio_in[38] = clock;
	assign gpio_in[39] = microwatt_reset;


	assign checkbits = gpio_out[37:30];

	assign user_flash_csb = gpio_out[6];
	assign user_flash_clk = gpio_out[7];

	assign user_flash_io0 = gpio_out[5]; 	// input to flash module
	assign gpio_in[4] = user_flash_io1; 	// output from flash module

	// assign tdo = gpio_out[36];
	// assign gpio_in[34] = tms;
	// assign gpio_in[32] = tck;
	// assign gpio_in[33] = tdi;

	// 100 MHz clock
	always #5 clock <= (clock === 1'b0);

	initial begin
		clock = 0;
	end

	initial begin
		$dumpfile("jtagm_tb.vcd");
		$dumpvars(0, jtagm_tb);

		$display("Microwatt JTAGM test");
		wait(checkbits == 8'hfe)
		$display("Microwatt alive!");

		repeat (55000) @(posedge clock);
		$finish;
	end

	initial begin
		RSTB <= 1'b0;
		microwatt_reset <= 1'b1;
		#1000;
		microwatt_reset <= 1'b0;
		// Note: keep management engine in reset
		//RSTB <= 1'b1;
	end

	initial begin		// Power-up sequence
		power1 <= 1'b0;
		power2 <= 1'b0;
		power3 <= 1'b0;
		power4 <= 1'b0;
		#100;
		power1 <= 1'b1;
		#100;
		power2 <= 1'b1;
		#100;
		power3 <= 1'b1;
		#100;
		power4 <= 1'b1;
	end

	initial begin

	end

	wire VDD3V3 = power1;
	wire VDD1V8 = power2;
	wire USER_VDD3V3 = power3;
	wire USER_VDD1V8 = power4;
	wire VSS = 1'b0;
	wire unused = 1'b0;

	openframe_project_wrapper uut (
		.vdda 				(VDD3V3),
		.vdda1 				(USER_VDD3V3),
		.vdda2 				(USER_VDD3V3),
		.vssa 				(VSS),
		.vssa1 				(VSS),
		.vssa2 				(VSS),
		.vccd 				(VDD1V8),
		.vccd1 				(USER_VDD1V8),
		.vccd2 				(USER_VDD1V8),
		.vssd 				(VSS),
		.vssd1 				(VSS),
		.vssd2 				(VSS),
		.vddio 				(VDD3V3),
		.vssio 				(VSS),
		.porb_h 			(unused),
		.porb_l 			(unused),
		.por_l 				(unused),
		.resetb_h 			(RSTB),
		.resetb_l 			(RSTB),
		.mask_rev 			(unused),
		.gpio_in 			(gpio_in),
		.gpio_in_h 			(unused),
		.gpio_out 			(gpio_out),
		.gpio_oeb 			(gpio_oeb),
		.gpio_inp_dis 		(unused),
		.gpio_ib_mode_sel 	(unused),
		.gpio_vtrip_sel 	(unused),
		.gpio_slow_sel 		(unused),
		.gpio_holdover 		(unused),
		.gpio_analog_en 	(unused),
		.gpio_analog_sel 	(unused),
		.gpio_analog_pol 	(unused),
		.gpio_dm2 			(unused),
		.gpio_dm1 			(unused),
		.gpio_dm0 			(unused),
		.analog_io 			(unused),
		.analog_noesd_io 	(unused),
		.gpio_loopback_one 	(unused),
		.gpio_loopback_zero (unused)

	);

	spiflash_microwatt #(
		.FILENAME("microwatt.hex")
	) spiflash_microwatt (
		.csb(user_flash_csb),
		.clk(user_flash_clk),
		.io0(user_flash_io0),
		.io1(user_flash_io1),
		.io2(),			// not used
		.io3()			// not used
	);
endmodule
`default_nettype wire

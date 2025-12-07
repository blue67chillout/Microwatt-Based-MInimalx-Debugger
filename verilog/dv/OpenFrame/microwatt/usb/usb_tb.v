`timescale 1ns/1ps
`default_nettype none

module usb_tb;

    reg  clock;
    reg  RSTB;
    reg  microwatt_reset;
    reg  power1, power2;
    reg  power3, power4;

    wire [43:0] gpio_in;
    wire [43:0] gpio_out;
    wire [43:0] gpio_oeb;

    wire [7:0]  checkbits;
    wire        user_flash_csb;
    wire        user_flash_clk;
    wire        user_flash_io0;
    wire        user_flash_io1;

    // ==============================
    // ULPI PHY stub signals
    // ==============================
    reg        ulpi_clk60;       // ULPI 60 MHz clock to core
    reg        ulpi_dir;         // DIR from PHY to core
    reg        ulpi_nxt;         // NXT from PHY to core
    reg  [7:0] ulpi_d2h_data;    // DATA[7:0] from PHY to core

    wire [7:0] ulpi_h2d_data;    // DATA[7:0] from core to PHY (gpio_out[22:15])
    wire       ulpi_stp;         // STP from core to PHY (gpio_out[14])

    initial begin
        $display("Sim started");
    end

    // -------------------------------
    // GPIO mapping to DUT
    // -------------------------------

    // alt_reset = gpio_in[40]
    assign gpio_in[40] = 1'b1;       // keep alt_reset deasserted in this TB

    // SoC clock/reset
    assign gpio_in[38] = clock;           // ext_clk
    assign gpio_in[39] = microwatt_reset; // ext_rst (active high)

    // ULPI pins (to match openframe_project_wrapper)
    assign gpio_in[11]    = ulpi_clk60;        // ulpi_clk60_i
    assign gpio_in[12]    = ulpi_dir;          // ulpi_dir_i
    assign gpio_in[13]    = ulpi_nxt;          // ulpi_nxt_i
    assign gpio_in[22:15] = ulpi_d2h_data;     // ulpi_data_out_i[7:0] (PHY -> core)

    // Core outputs for ULPI
    assign ulpi_h2d_data = gpio_out[22:15];    // ulpi_data_in_o[7:0]
    assign ulpi_stp      = gpio_out[14];       // ulpi_stp_o

    // Checkbits (GPIO 37:30)
    assign checkbits = gpio_out[37:30];

    // SPI flash pins
    assign user_flash_csb = gpio_out[6];
    assign user_flash_clk = gpio_out[7];

    assign user_flash_io0 = gpio_out[5]; // DUT drives IO0
    assign gpio_in[4]     = user_flash_io1; // DUT samples IO1

    // -------------------------------
    // Clocks
    // -------------------------------

    // Core clock ~100 MHz
    always #5 clock <= (clock === 1'b0);

    initial begin
        clock = 1'b0;
    end

    // ULPI clock ~60 MHz (approx 62.5 MHz with #8)
    always #8 ulpi_clk60 <= (ulpi_clk60 === 1'b0);

    initial begin
        ulpi_clk60 = 1'b0;
    end

    // -------------------------------
    // Simulation control
    // -------------------------------
    // Global timeout as a safety net
    initial begin
        // ~4.5 ms @ 100 MHz (same as your old repeat(450000))
        #4_500_000;
        $display("[%0t] USB test FAILED (global timeout)", $time);
        $finish;
    end

    // Reset sequence for Microwatt / SoC
    initial begin
        RSTB            <= 1'b0;
        microwatt_reset <= 1'b1;
        #1000;
        microwatt_reset <= 1'b0;
        // keep management reset low (Caravel/OpenFrame side)
        // RSTB <= 1'b1; // enable if you actually want mgmt side alive
    end

    // -------------------------------
    // ULPI PHY stub behaviour
    // -------------------------------
    // Host (Microwatt) is the ULPI link; this stub is the PHY.
    // We keep:
    //   DIR = 0  ? host always owns data bus (TX direction)
    //   NXT = 1  ? PHY always ready (so utmi_txready stays high)
    // We just watch what the host sends and optionally print it.

    initial begin
        ulpi_dir      = 1'b0;   // host owns the bus
        ulpi_nxt      = 1'b1;   // always ready
        ulpi_d2h_data = 8'h00;  // no RX data from device yet
    end

    // Simple NXT behaviour: drop low for one cycle on STP (end-of-packet)
    always @(posedge ulpi_clk60 or posedge microwatt_reset) begin
        if (microwatt_reset) begin
            ulpi_dir      <= 1'b0;
            ulpi_nxt      <= 1'b1;
            ulpi_d2h_data <= 8'h00;
        end else begin
            if (ulpi_stp) begin
                // End of TX packet ? tell link layer we?re done for one cycle
                ulpi_nxt <= 1'b0;
            end else begin
                ulpi_nxt <= 1'b1;
            end

            // For now, we never send data back to host
            // (DIR stays 0, ulpi_d2h_data stays 0x00)
            ulpi_dir      <= 1'b0;
            ulpi_d2h_data <= 8'h00;
        end
    end

    // -------------------------------
    // USB packet monitor (ULPI TX)
    // -------------------------------

    // We only care about:
    //   E1 (OUT token PID)
    //   <2 token bytes> (ignored, just counted)
    //   C3 (DATA0 PID)
    //   AB (payload byte we expect)
    //
    // When we see this sequence once, we declare "USB test passed".

    localparam MON_WAIT_ALIVE      = 3'd0;
    localparam MON_WAIT_TOKEN_PID  = 3'd1;
    localparam MON_SKIP_TOKEN      = 3'd2;
    localparam MON_WAIT_DATA_PID   = 3'd3;
    localparam MON_WAIT_DATA_BYTE  = 3'd4;
    localparam MON_DONE            = 3'd5;

    reg [2:0] mon_state;
    reg [1:0] token_skip_count;
    reg       usb_test_passed;

    wire ulpi_tx_valid = (!ulpi_dir && ulpi_nxt);  // host driving valid Tx byte

    initial begin
        mon_state        = MON_WAIT_ALIVE;
        token_skip_count = 2'd0;
        usb_test_passed  = 1'b0;
    end

    always @(posedge ulpi_clk60 or posedge microwatt_reset) begin
        if (microwatt_reset) begin
            mon_state        <= MON_WAIT_ALIVE;
            token_skip_count <= 2'd0;
            usb_test_passed  <= 1'b0;
        end else begin
            case (mon_state)
                // Wait until firmware says Microwatt is up
                MON_WAIT_ALIVE: begin
                    if (checkbits == 8'hfe)
                        mon_state <= MON_WAIT_TOKEN_PID;
                end

                // Look for OUT token PID = 0xE1 on ULPI bus
                MON_WAIT_TOKEN_PID: begin
                    if (ulpi_tx_valid && ulpi_h2d_data == 8'hE1) begin
                        mon_state        <= MON_SKIP_TOKEN;
                        token_skip_count <= 2'd0;
                        $display("[%0t] Saw OUT token PID 0xE1", $time);
                    end
                end

                // Skip the 2 token bytes (ADDR/ENDP+CRC5)
                MON_SKIP_TOKEN: begin
                    if (ulpi_tx_valid) begin
                        token_skip_count <= token_skip_count + 2'd1;
                        if (token_skip_count == 2'd1)
                            mon_state <= MON_WAIT_DATA_PID;
                    end
                end

                // Wait for DATA0 PID = 0xC3
                MON_WAIT_DATA_PID: begin
                    if (ulpi_tx_valid && ulpi_h2d_data == 8'hC3) begin
                        mon_state <= MON_WAIT_DATA_BYTE;
                        $display("[%0t] Saw DATA0 PID 0xC3", $time);
                    end
                end

                // Wait for first data byte, expect 0xAB
                MON_WAIT_DATA_BYTE: begin
                    if (ulpi_tx_valid) begin
                        if (ulpi_h2d_data == 8'hAB) begin
                            usb_test_passed <= 1'b1;
                            mon_state       <= MON_DONE;
                            $display("[%0t] USB test passed (saw data byte 0x%02x)", 
                                     $time, ulpi_h2d_data);
                            // Small delay so VCD catches final wave, then finish
                            #1000;
                            $finish;
                        end else begin
                            // Got some other byte ? stay here or fail, your choice.
                            $display("[%0t] Unexpected data byte 0x%02x (expected 0xAB)", 
                                     $time, ulpi_h2d_data);
                        end
                    end
                end

                MON_DONE: begin
                    // nothing
                end

                default: mon_state <= MON_WAIT_ALIVE;
            endcase
        end
    end

    // -------------------------------
    // Power nets
    // -------------------------------
    wire VDD3V3      = power1;
    wire VDD1V8      = power2;
    wire USER_VDD3V3 = power3;
    wire USER_VDD1V8 = power4;
    wire VSS         = 1'b0;

    // Power-up sequence
    initial begin
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

    // Wait for Microwatt firmware to signal "alive" via checkbits
    initial begin
        wait (checkbits == 8'hfe);
        $display("[%0t] Microwatt alive!", $time);
    end

    // -------------------------------
    // DUT (openframe_project_wrapper)
    // -------------------------------
    openframe_project_wrapper uut (
        .vdda              (VDD3V3),
        .vdda1             (USER_VDD3V3),
        .vdda2             (USER_VDD3V3),
        .vssa              (VSS),
        .vssa1             (VSS),
        .vssa2             (VSS),
        .vccd              (VDD1V8),
        .vccd1             (USER_VDD1V8),
        .vccd2             (USER_VDD1V8),
        .vssd              (VSS),
        .vssd1             (VSS),
        .vssd2             (VSS),
        .vddio             (VDD3V3),
        .vssio             (VSS),

        .porb_h            (1'b0),
        .porb_l            (1'b0),
        .por_l             (1'b0),
        .resetb_h          (RSTB),
        .resetb_l          (RSTB),

        .mask_rev          (32'b0),

        .gpio_in           (gpio_in),
        .gpio_in_h         ({44{1'b0}}),
        .gpio_out          (gpio_out),
        .gpio_oeb          (gpio_oeb),
        .gpio_inp_dis      (),
        .gpio_ib_mode_sel  (),
        .gpio_vtrip_sel    (),
        .gpio_slow_sel     (),
        .gpio_holdover     (),
        .gpio_analog_en    (),
        .gpio_analog_sel   (),
        .gpio_analog_pol   (),
        .gpio_dm2          (),
        .gpio_dm1          (),
        .gpio_dm0          (),
        .analog_io         (),
        .analog_noesd_io   (),
        .gpio_loopback_one ({44{1'b1}}),
        .gpio_loopback_zero({44{1'b0}})
    );

    // -------------------------------
    // SPI flash model
    // -------------------------------
    spiflash_microwatt #(
        .FILENAME("microwatt.hex")
    ) spiflash_microwatt (
        .csb(user_flash_csb),
        .clk(user_flash_clk),
        .io0(user_flash_io0),
        .io1(user_flash_io1)
    );

endmodule

`default_nettype wire

`timescale 1ns/1ps

module jtag_master_controller
(
    input           clk,
    input           rst,

    /* verilator lint_off UNUSED */
    input  [29:0]   wb_adr_i,
    input  [31:0]   wb_dat_i,
    input  [3:0]    wb_sel_i,
    /* verilator lint_on UNUSED */
    input           wb_cyc_i,
    input           wb_stb_i,
    input           wb_we_i,
    output reg [31:0] wb_dat_o,
    output reg        wb_ack_o,
    output            wb_stall_o,

    output           tck_o,
    output           tms_o,
    output           tdi_o,
    output           trst_o,
    input            tdo_i,

    output           expose_o,
    output           intr_o
);

    localparam [3:0] A_CLK       = 4'h0;
    localparam [3:0] A_CTRL      = 4'h1;
    localparam [3:0] A_SHIFT     = 4'h2;
    localparam [3:0] A_STATUS    = 4'h3;
    localparam [3:0] A_IRQ_MASK  = 4'h4;
    localparam [3:0] A_IRQ_STS   = 4'h5;
    localparam [3:0] A_IRQ_ACK   = 4'h6;

    wire [3:0] addr_w = wb_adr_i[5:2];

    wire sel_clk      = wb_cyc_i & wb_stb_i & (addr_w == A_CLK);
    wire sel_ctrl     = wb_cyc_i & wb_stb_i & (addr_w == A_CTRL);
    wire sel_shift    = wb_cyc_i & wb_stb_i & (addr_w == A_SHIFT);
    wire sel_status   = wb_cyc_i & wb_stb_i & (addr_w == A_STATUS);
    wire sel_irq_mask = wb_cyc_i & wb_stb_i & (addr_w == A_IRQ_MASK);
    wire sel_irq_sts  = wb_cyc_i & wb_stb_i & (addr_w == A_IRQ_STS);
    wire sel_irq_ack  = wb_cyc_i & wb_stb_i & (addr_w == A_IRQ_ACK);

    wire any_sel = sel_clk | sel_ctrl | sel_shift | sel_status
                 | sel_irq_mask | sel_irq_sts | sel_irq_ack;

    assign wb_stall_o = 1'b0;

    reg [7:0]  clk_div_reg;
    reg [2:0]  control_reg;
    reg [7:0]  shift_len_reg;
    reg [23:0] shift_out_reg;
    reg [23:0] shift_in_reg;
    reg        busy_reg;
    reg        tdo_valid_pulse;
    reg [1:0]  irq_mask_reg;
    reg [1:0]  irq_status_reg;     // <- now single-driver
    reg [1:0]  irq_status_next;    // <- next-state

    // ------------------------------
    // ACK generation
    // ------------------------------
    reg prev_sel;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            prev_sel <= 1'b0;
            wb_ack_o <= 1'b0;
        end else begin
            wb_ack_o <= any_sel & ~prev_sel;
            prev_sel <= any_sel;
        end
    end

    // ------------------------------
    // Readback mux
    // ------------------------------
    always @(*) begin
        case (addr_w)
            A_CLK     : wb_dat_o = {24'h0, clk_div_reg};
            A_CTRL    : wb_dat_o = {29'h0, control_reg};
            A_SHIFT   : wb_dat_o = {shift_in_reg, 8'h0};
            A_STATUS  : wb_dat_o = {30'h0, tdo_valid_pulse, busy_reg};
            A_IRQ_MASK: wb_dat_o = {30'h0, irq_mask_reg};
            A_IRQ_STS : wb_dat_o = {30'h0, irq_status_reg};
            default   : wb_dat_o = 32'h00000000;
        endcase
    end

    wire wr_phase    = wb_ack_o & wb_we_i;
    wire start_shift = wb_ack_o & sel_shift & wb_we_i & ~busy_reg;

    // ------------------------------
    // CSR writes (except irq_status_reg)
    // ------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            clk_div_reg   <= 8'hFF;
            control_reg   <= 3'b010;
            shift_len_reg <= 8'h00;
            irq_mask_reg  <= 2'b00;
        end else if (wr_phase) begin
            case (addr_w)
                A_CLK: begin
                    clk_div_reg <= wb_dat_i[7:0];
                end
                A_CTRL: begin
                    control_reg <= wb_dat_i[2:0];
                end
                A_SHIFT: begin
                    if (~busy_reg) begin
                        shift_len_reg <= wb_dat_i[7:0];
                    end
                end
                A_IRQ_MASK: begin
                    irq_mask_reg <= wb_dat_i[1:0];
                end
                // A_IRQ_ACK: handled in irq_status next-state logic
                default: ;
            endcase
        end
    end

    // ------------------------------
    // TCK divider
    // ------------------------------
    reg [8:0] div_cnt;
    reg       tck_q;

    wire div_hit = (div_cnt == 9'd0);
    assign tck_o = tck_q;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            div_cnt <= 9'd0;
            tck_q   <= 1'b0;
        end else if (busy_reg) begin
            if (div_hit) begin
                div_cnt <= {1'b0, clk_div_reg};
                tck_q   <= ~tck_q;
            end else begin
                div_cnt <= div_cnt - 9'd1;
            end
        end else begin
            tck_q   <= 1'b0;
            div_cnt <= 9'd0;
        end
    end

    assign tms_o  = control_reg[0];
    assign trst_o = control_reg[1];

    // ------------------------------
    // Shift FSM
    // ------------------------------
    localparam FSM_IDLE  = 2'b00;
    localparam FSM_SHIFT = 2'b01;
    localparam FSM_DONE  = 2'b10;

    reg [1:0] fsm_state;
    reg [8:0] bit_counter;
    reg       tdi_q;

    assign tdi_o = tdi_q;

    wire [8:0] total_bits = (shift_len_reg == 8'd0) ? 9'd256 : {1'b0, shift_len_reg};

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            fsm_state       <= FSM_IDLE;
            busy_reg        <= 1'b0;
            tdo_valid_pulse <= 1'b0;
            bit_counter     <= 9'd0;
            tdi_q           <= 1'b0;
            shift_in_reg    <= 24'd0;
            shift_out_reg   <= 24'd0;
        end else begin
            tdo_valid_pulse <= 1'b0;

            case (fsm_state)
                FSM_IDLE: begin
                    busy_reg <= 1'b0;
                    if (start_shift) begin
                        busy_reg     <= 1'b1;
                        bit_counter  <= total_bits;
                        shift_in_reg <= 24'd0;

                        if (total_bits <= 9'd8) begin
                            shift_out_reg <= {16'h0, wb_dat_i[31:24]};
                            tdi_q         <= wb_dat_i[24];
                        end else if (total_bits <= 9'd16) begin
                            shift_out_reg <= {8'h0, wb_dat_i[31:16]};
                            tdi_q         <= wb_dat_i[16];
                        end else begin
                            shift_out_reg <= wb_dat_i[31:8];
                            tdi_q         <= wb_dat_i[8];
                        end

                        fsm_state <= FSM_SHIFT;
                    end
                end

                FSM_SHIFT: begin
                    if (tck_q & div_hit) begin
                        // Sample TDO on rising edge
                        shift_in_reg <= {shift_in_reg[22:0], tdo_i};
                        if (bit_counter == 9'd0) begin
                            fsm_state <= FSM_DONE;
                        end
                    end else if (~tck_q & div_hit) begin
                        // Shift out next TDI bit on falling edge
                        tdi_q         <= shift_out_reg[0];
                        shift_out_reg <= {1'b0, shift_out_reg[23:1]};
                        if (bit_counter != 9'd0) begin
                            bit_counter <= bit_counter - 9'd1;
                        end
                    end
                end

                FSM_DONE: begin
                    busy_reg        <= 1'b0;
                    tdo_valid_pulse <= 1'b1;
                    // irq_status_reg is updated in separate always using FSM_DONE
                    fsm_state       <= FSM_IDLE;
                end

                default: begin
                    fsm_state <= FSM_IDLE;
                end
            endcase
        end
    end

    // ------------------------------
    // IRQ STATUS: single-driver next-state logic
    // ------------------------------
    always @(*) begin
        irq_status_next = irq_status_reg;

        // Set both bits when a shift is done
        if (fsm_state == FSM_DONE) begin
            irq_status_next = irq_status_next | 2'b11;
        end

        // Clear selected bits on IRQ_ACK write
        if (wr_phase && sel_irq_ack) begin
            irq_status_next = irq_status_next & ~wb_dat_i[1:0];
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            irq_status_reg <= 2'b00;
        end else begin
            irq_status_reg <= irq_status_next;
        end
    end

    // ------------------------------
    // Outputs
    // ------------------------------
    assign expose_o = control_reg[2];
    assign intr_o   = |(irq_status_reg & irq_mask_reg);

endmodule

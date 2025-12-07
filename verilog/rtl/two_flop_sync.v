// ==========================================
// Simple 1-bit 2-flop synchronizer
// ==========================================
module sync_bit (
    input  wire clk_dst,
    input  wire in_bit,
    output reg  out_bit
);
    reg sync_ff;
    always @(posedge clk_dst) begin
        sync_ff <= in_bit;
        out_bit <= sync_ff;
    end
endmodule

// ==========================================
// Simple multi-bit 2-flop synchronizer
// ==========================================
module sync_bus #(
    parameter WIDTH = 8
) (
    input  wire             clk_dst,
    input  wire [WIDTH-1:0] in_bus,
    output reg  [WIDTH-1:0] out_bus
);
    reg [WIDTH-1:0] sync_ff;
    always @(posedge clk_dst) begin
        sync_ff  <= in_bus;
        out_bus  <= sync_ff;
    end
endmodule

// ==========================================
// Dual-clock async FIFO (Gray-coded pointers)
// WIDTH: data width, ADDR_WIDTH: log2 depth
// ==========================================
module async_fifo #(
    parameter WIDTH      = 8,
    parameter ADDR_WIDTH = 3       // depth = 2^ADDR_WIDTH (here 8 entries)
)(
    input  wire                wr_clk,
    input  wire                wr_rst,
    input  wire                wr_en,
    input  wire [WIDTH-1:0]    wr_data,
    output wire                full,

    input  wire                rd_clk,
    input  wire                rd_rst,
    input  wire                rd_en,
    output reg  [WIDTH-1:0]    rd_data,
    output wire                empty
);
    localparam DEPTH = (1 << ADDR_WIDTH);

    // Memory
    reg [WIDTH-1:0] mem [0:DEPTH-1];

    // Binary pointers
    reg [ADDR_WIDTH:0] w_ptr_bin, r_ptr_bin;
    // Gray pointers
    reg [ADDR_WIDTH:0] w_ptr_gray, r_ptr_gray;

    // Synchronized pointers
    reg [ADDR_WIDTH:0] w_ptr_gray_rdclk_1, w_ptr_gray_rdclk_2;
    reg [ADDR_WIDTH:0] r_ptr_gray_wrclk_1, r_ptr_gray_wrclk_2;

    // Gray <-> binary conversion helpers
    function [ADDR_WIDTH:0] bin2gray(input [ADDR_WIDTH:0] b);
        bin2gray = (b >> 1) ^ b;
    endfunction

    function [ADDR_WIDTH:0] gray2bin(input [ADDR_WIDTH:0] g);
        integer i;
        begin
            gray2bin[ADDR_WIDTH] = g[ADDR_WIDTH];
            for (i = ADDR_WIDTH-1; i >= 0; i = i - 1)
                gray2bin[i] = gray2bin[i+1] ^ g[i];
        end
    endfunction

    // Write pointer (wr_clk domain)
    always @(posedge wr_clk or posedge wr_rst) begin
        if (wr_rst) begin
            w_ptr_bin  <= 0;
            w_ptr_gray <= 0;
        end else begin
            if (wr_en && !full) begin
                mem[w_ptr_bin[ADDR_WIDTH-1:0]] <= wr_data;
                w_ptr_bin  <= w_ptr_bin + 1'b1;
                w_ptr_gray <= bin2gray(w_ptr_bin + 1'b1);
            end
        end
    end

    // Read pointer (rd_clk domain)
    always @(posedge rd_clk or posedge rd_rst) begin
        if (rd_rst) begin
            r_ptr_bin  <= 0;
            r_ptr_gray <= 0;
            rd_data    <= {WIDTH{1'b0}};
        end else begin
            if (rd_en && !empty) begin
                rd_data    <= mem[r_ptr_bin[ADDR_WIDTH-1:0]];
                r_ptr_bin  <= r_ptr_bin + 1'b1;
                r_ptr_gray <= bin2gray(r_ptr_bin + 1'b1);
            end
        end
    end

    // Pointer synchronization across domains
    // Read-pointer into write clock
    always @(posedge wr_clk or posedge wr_rst) begin
        if (wr_rst) begin
            r_ptr_gray_wrclk_1 <= 0;
            r_ptr_gray_wrclk_2 <= 0;
        end else begin
            r_ptr_gray_wrclk_1 <= r_ptr_gray;
            r_ptr_gray_wrclk_2 <= r_ptr_gray_wrclk_1;
        end
    end

    // Write-pointer into read clock
    always @(posedge rd_clk or posedge rd_rst) begin
        if (rd_rst) begin
            w_ptr_gray_rdclk_1 <= 0;
            w_ptr_gray_rdclk_2 <= 0;
        end else begin
            w_ptr_gray_rdclk_1 <= w_ptr_gray;
            w_ptr_gray_rdclk_2 <= w_ptr_gray_rdclk_1;
        end
    end

    // Full: next write ptr == read ptr with MSBs inverted
    wire [ADDR_WIDTH:0] r_ptr_gray_wr = r_ptr_gray_wrclk_2;
    wire [ADDR_WIDTH:0] w_ptr_gray_next = bin2gray(w_ptr_bin + 1'b1);

    assign full = (w_ptr_gray_next == {~r_ptr_gray_wr[ADDR_WIDTH:ADDR_WIDTH-1],
                                       r_ptr_gray_wr[ADDR_WIDTH-2:0]});

    // Empty: pointers equal
    assign empty = (r_ptr_gray == w_ptr_gray_rdclk_2);

endmodule

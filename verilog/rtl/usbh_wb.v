//-----------------------------------------------------------------
//                     USB Host - Wishbone Adapter
//                           V0.6
//                     Ultra-Embedded.com
//                     Copyright 2015-2020
//
//                 Email: admin@ultra-embedded.com
//
//                         License: GPL
//-----------------------------------------------------------------
//
// This file is open source HDL; you can redistribute it and/or 
// modify it under the terms of the GNU General Public License as 
// published by the Free Software Foundation; either version 2 of 
// the License, or (at your option) any later version.
//
// This file is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public 
// License along with this file; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
// USA
//-----------------------------------------------------------------

//-----------------------------------------------------------------
// Module: USB Host Wishbone Interface
//-----------------------------------------------------------------
module usbh_wb 
(
    input               clk,
    input               wb_rst_i,
    
    // Wishbone interface
    input  [7:0]        wb_adr_i,
    input  [31:0]       wb_dat_i,
    output reg [31:0]   wb_dat_o,
    input               wb_we_i,
    input               wb_stb_i,
    input               wb_cyc_i,
    input  [3:0]        wb_sel_i,
    output reg          wb_ack_o,
    
    // Internal interface signals
    output [7:0]        adr_int,
    output [31:0]       dat_wr_o,
    input  [31:0]       dat_rd_i,
    output              we_o,
    output              re_o
);

//-----------------------------------------------------------------
// Registers
//-----------------------------------------------------------------
reg  [7:0]              wb_adr_is;
reg  [31:0]             wb_dat_is;
reg                     wb_we_is;
reg                     wb_cyc_is;
reg                     wb_stb_is;
reg  [3:0]              wb_sel_is;

reg                     wre;

// ACK FSM
reg  [1:0]              wbstate;

//-----------------------------------------------------------------
// Write/Read Enable Logic
//-----------------------------------------------------------------
assign we_o = wb_we_is & wb_stb_is & wb_cyc_is & wre;
assign re_o = ~wb_we_is & wb_stb_is & wb_cyc_is & wre;

//-----------------------------------------------------------------
// Internal address
//-----------------------------------------------------------------
assign adr_int = wb_adr_is;

//-----------------------------------------------------------------
// Write data - pass through with byte select masking
//-----------------------------------------------------------------
assign dat_wr_o = wb_dat_is;

//-----------------------------------------------------------------
// Read data multiplexing
//-----------------------------------------------------------------
always @(posedge clk or posedge wb_rst_i)
    if (wb_rst_i)
        wb_dat_o <= 32'b0;
    else
        wb_dat_o <= dat_rd_i;

//-----------------------------------------------------------------
// ACK FSM - Generate acknowledgement with pipeline delay
//-----------------------------------------------------------------
always @(posedge clk or posedge wb_rst_i)
    if (wb_rst_i)
    begin
        wb_ack_o <= 1'b0;
        wbstate <= 2'b00;
        wre <= 1'b1;
    end
    else
    begin
        case (wbstate)
            2'b00:
            begin
                if (wb_stb_is & wb_cyc_is)
                begin
                    wre <= 1'b0;
                    wbstate <= 2'b01;
                    wb_ack_o <= 1'b1;
                end
                else
                begin
                    wre <= 1'b1;
                    wb_ack_o <= 1'b0;
                end
            end
            2'b01:
            begin
                wb_ack_o <= 1'b0;
                wbstate <= 2'b10;
                wre <= 1'b0;
            end
            2'b10:
            begin
                wb_ack_o <= 1'b0;
                wbstate <= 2'b11;
                wre <= 1'b0;
            end
            2'b11:
            begin
                wb_ack_o <= 1'b0;
                wbstate <= 2'b00;
                wre <= 1'b1;
            end
        endcase
    end

//-----------------------------------------------------------------
// Sample input signals
//-----------------------------------------------------------------
always @(posedge clk or posedge wb_rst_i)
    if (wb_rst_i)
    begin
        wb_adr_is <= 8'b0;
        wb_dat_is <= 32'b0;
        wb_we_is <= 1'b0;
        wb_cyc_is <= 1'b0;
        wb_stb_is <= 1'b0;
        wb_sel_is <= 4'b0;
    end
    else
    begin
        wb_adr_is <= wb_adr_i;
        wb_dat_is <= wb_dat_i;
        wb_we_is <= wb_we_i;
        wb_cyc_is <= wb_cyc_i;
        wb_stb_is <= wb_stb_i;
        wb_sel_is <= wb_sel_i;
    end

endmodule

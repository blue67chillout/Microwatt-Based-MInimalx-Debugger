module openframe_project_wrapper (por_l,
    porb_h,
    porb_l,
    resetb_h,
    resetb_l,
    vssd1,
    vccd1,
    vssio,
    vddio,
    vdda2,
    vssa2,
    vdda1,
    vssa1,
    vdda,
    vssa,
    vssd2,
    vccd2,
    vssd,
    vccd,
    analog_io,
    analog_noesd_io,
    gpio_analog_en,
    gpio_analog_pol,
    gpio_analog_sel,
    gpio_dm0,
    gpio_dm1,
    gpio_dm2,
    gpio_holdover,
    gpio_ib_mode_sel,
    gpio_in,
    gpio_in_h,
    gpio_inp_dis,
    gpio_loopback_one,
    gpio_loopback_zero,
    gpio_oeb,
    gpio_out,
    gpio_slow_sel,
    gpio_vtrip_sel,
    mask_rev);
 input por_l;
 input porb_h;
 input porb_l;
 input resetb_h;
 input resetb_l;
 input vssd1;
 input vccd1;
 input vssio;
 input vddio;
 input vdda2;
 input vssa2;
 input vdda1;
 input vssa1;
 input vdda;
 input vssa;
 input vssd2;
 input vccd2;
 input vssd;
 input vccd;
 inout [43:0] analog_io;
 inout [43:0] analog_noesd_io;
 output [43:0] gpio_analog_en;
 output [43:0] gpio_analog_pol;
 output [43:0] gpio_analog_sel;
 output [43:0] gpio_dm0;
 output [43:0] gpio_dm1;
 output [43:0] gpio_dm2;
 output [43:0] gpio_holdover;
 output [43:0] gpio_ib_mode_sel;
 input [43:0] gpio_in;
 input [43:0] gpio_in_h;
 output [43:0] gpio_inp_dis;
 input [43:0] gpio_loopback_one;
 input [43:0] gpio_loopback_zero;
 output [43:0] gpio_oeb;
 output [43:0] gpio_out;
 output [43:0] gpio_slow_sel;
 output [43:0] gpio_vtrip_sel;
 input [31:0] mask_rev;


 user_proj_timer mprj (.vccd1(vccd1),
    .vssd1(vssd1),
    .wb_clk_i(gpio_in[0]),
    .wb_rst_i(gpio_in[1]),
    .io_in({gpio_in[12],
    gpio_in[11],
    gpio_in[10],
    gpio_in[9],
    gpio_in[8],
    gpio_in[7],
    gpio_in[6],
    gpio_in[5],
    gpio_in[4],
    gpio_in[3],
    gpio_in[2]}),
    .io_oeb({gpio_oeb[12],
    gpio_oeb[11],
    gpio_oeb[10],
    gpio_oeb[9],
    gpio_oeb[8],
    gpio_oeb[7],
    gpio_oeb[6],
    gpio_oeb[5],
    gpio_oeb[4],
    gpio_oeb[3],
    gpio_oeb[2]}),
    .io_out({gpio_out[12],
    gpio_out[11],
    gpio_out[10],
    gpio_out[9],
    gpio_out[8],
    gpio_out[7],
    gpio_out[6],
    gpio_out[5],
    gpio_out[4],
    gpio_out[3],
    gpio_out[2]}));
 vccd1_connection vccd1_connection ();
 vssd1_connection vssd1_connection ();
 assign gpio_analog_en[0] = gpio_loopback_zero[0];
 assign gpio_analog_pol[0] = gpio_loopback_zero[0];
 assign gpio_analog_sel[0] = gpio_loopback_zero[0];
 assign gpio_holdover[0] = gpio_loopback_zero[0];
 assign gpio_analog_en[10] = gpio_loopback_zero[10];
 assign gpio_analog_pol[10] = gpio_loopback_zero[10];
 assign gpio_analog_sel[10] = gpio_loopback_zero[10];
 assign gpio_holdover[10] = gpio_loopback_zero[10];
 assign gpio_analog_en[11] = gpio_loopback_zero[11];
 assign gpio_analog_pol[11] = gpio_loopback_zero[11];
 assign gpio_analog_sel[11] = gpio_loopback_zero[11];
 assign gpio_holdover[11] = gpio_loopback_zero[11];
 assign gpio_analog_en[12] = gpio_loopback_zero[12];
 assign gpio_analog_pol[12] = gpio_loopback_zero[12];
 assign gpio_analog_sel[12] = gpio_loopback_zero[12];
 assign gpio_holdover[12] = gpio_loopback_zero[12];
 assign gpio_analog_en[13] = gpio_loopback_zero[13];
 assign gpio_analog_pol[13] = gpio_loopback_zero[13];
 assign gpio_analog_sel[13] = gpio_loopback_zero[13];
 assign gpio_holdover[13] = gpio_loopback_zero[13];
 assign gpio_analog_en[14] = gpio_loopback_zero[14];
 assign gpio_analog_pol[14] = gpio_loopback_zero[14];
 assign gpio_analog_sel[14] = gpio_loopback_zero[14];
 assign gpio_holdover[14] = gpio_loopback_zero[14];
 assign gpio_analog_en[15] = gpio_loopback_zero[15];
 assign gpio_analog_pol[15] = gpio_loopback_zero[15];
 assign gpio_analog_sel[15] = gpio_loopback_zero[15];
 assign gpio_holdover[15] = gpio_loopback_zero[15];
 assign gpio_analog_en[16] = gpio_loopback_zero[16];
 assign gpio_analog_pol[16] = gpio_loopback_zero[16];
 assign gpio_analog_sel[16] = gpio_loopback_zero[16];
 assign gpio_holdover[16] = gpio_loopback_zero[16];
 assign gpio_analog_en[17] = gpio_loopback_zero[17];
 assign gpio_analog_pol[17] = gpio_loopback_zero[17];
 assign gpio_analog_sel[17] = gpio_loopback_zero[17];
 assign gpio_holdover[17] = gpio_loopback_zero[17];
 assign gpio_analog_en[18] = gpio_loopback_zero[18];
 assign gpio_analog_pol[18] = gpio_loopback_zero[18];
 assign gpio_analog_sel[18] = gpio_loopback_zero[18];
 assign gpio_holdover[18] = gpio_loopback_zero[18];
 assign gpio_analog_en[19] = gpio_loopback_zero[19];
 assign gpio_analog_pol[19] = gpio_loopback_zero[19];
 assign gpio_analog_sel[19] = gpio_loopback_zero[19];
 assign gpio_holdover[19] = gpio_loopback_zero[19];
 assign gpio_analog_en[1] = gpio_loopback_zero[1];
 assign gpio_analog_pol[1] = gpio_loopback_zero[1];
 assign gpio_analog_sel[1] = gpio_loopback_zero[1];
 assign gpio_holdover[1] = gpio_loopback_zero[1];
 assign gpio_analog_en[20] = gpio_loopback_zero[20];
 assign gpio_analog_pol[20] = gpio_loopback_zero[20];
 assign gpio_analog_sel[20] = gpio_loopback_zero[20];
 assign gpio_holdover[20] = gpio_loopback_zero[20];
 assign gpio_analog_en[21] = gpio_loopback_zero[21];
 assign gpio_analog_pol[21] = gpio_loopback_zero[21];
 assign gpio_analog_sel[21] = gpio_loopback_zero[21];
 assign gpio_holdover[21] = gpio_loopback_zero[21];
 assign gpio_analog_en[22] = gpio_loopback_zero[22];
 assign gpio_analog_pol[22] = gpio_loopback_zero[22];
 assign gpio_analog_sel[22] = gpio_loopback_zero[22];
 assign gpio_holdover[22] = gpio_loopback_zero[22];
 assign gpio_analog_en[23] = gpio_loopback_zero[23];
 assign gpio_analog_pol[23] = gpio_loopback_zero[23];
 assign gpio_analog_sel[23] = gpio_loopback_zero[23];
 assign gpio_holdover[23] = gpio_loopback_zero[23];
 assign gpio_analog_en[24] = gpio_loopback_zero[24];
 assign gpio_analog_pol[24] = gpio_loopback_zero[24];
 assign gpio_analog_sel[24] = gpio_loopback_zero[24];
 assign gpio_holdover[24] = gpio_loopback_zero[24];
 assign gpio_analog_en[25] = gpio_loopback_zero[25];
 assign gpio_analog_pol[25] = gpio_loopback_zero[25];
 assign gpio_analog_sel[25] = gpio_loopback_zero[25];
 assign gpio_holdover[25] = gpio_loopback_zero[25];
 assign gpio_analog_en[26] = gpio_loopback_zero[26];
 assign gpio_analog_pol[26] = gpio_loopback_zero[26];
 assign gpio_analog_sel[26] = gpio_loopback_zero[26];
 assign gpio_holdover[26] = gpio_loopback_zero[26];
 assign gpio_analog_en[27] = gpio_loopback_zero[27];
 assign gpio_analog_pol[27] = gpio_loopback_zero[27];
 assign gpio_analog_sel[27] = gpio_loopback_zero[27];
 assign gpio_holdover[27] = gpio_loopback_zero[27];
 assign gpio_analog_en[28] = gpio_loopback_zero[28];
 assign gpio_analog_pol[28] = gpio_loopback_zero[28];
 assign gpio_analog_sel[28] = gpio_loopback_zero[28];
 assign gpio_holdover[28] = gpio_loopback_zero[28];
 assign gpio_analog_en[29] = gpio_loopback_zero[29];
 assign gpio_analog_pol[29] = gpio_loopback_zero[29];
 assign gpio_analog_sel[29] = gpio_loopback_zero[29];
 assign gpio_holdover[29] = gpio_loopback_zero[29];
 assign gpio_analog_en[2] = gpio_loopback_zero[2];
 assign gpio_analog_pol[2] = gpio_loopback_zero[2];
 assign gpio_analog_sel[2] = gpio_loopback_zero[2];
 assign gpio_holdover[2] = gpio_loopback_zero[2];
 assign gpio_analog_en[30] = gpio_loopback_zero[30];
 assign gpio_analog_pol[30] = gpio_loopback_zero[30];
 assign gpio_analog_sel[30] = gpio_loopback_zero[30];
 assign gpio_holdover[30] = gpio_loopback_zero[30];
 assign gpio_analog_en[31] = gpio_loopback_zero[31];
 assign gpio_analog_pol[31] = gpio_loopback_zero[31];
 assign gpio_analog_sel[31] = gpio_loopback_zero[31];
 assign gpio_holdover[31] = gpio_loopback_zero[31];
 assign gpio_analog_en[32] = gpio_loopback_zero[32];
 assign gpio_analog_pol[32] = gpio_loopback_zero[32];
 assign gpio_analog_sel[32] = gpio_loopback_zero[32];
 assign gpio_holdover[32] = gpio_loopback_zero[32];
 assign gpio_analog_en[33] = gpio_loopback_zero[33];
 assign gpio_analog_pol[33] = gpio_loopback_zero[33];
 assign gpio_analog_sel[33] = gpio_loopback_zero[33];
 assign gpio_holdover[33] = gpio_loopback_zero[33];
 assign gpio_analog_en[34] = gpio_loopback_zero[34];
 assign gpio_analog_pol[34] = gpio_loopback_zero[34];
 assign gpio_analog_sel[34] = gpio_loopback_zero[34];
 assign gpio_holdover[34] = gpio_loopback_zero[34];
 assign gpio_analog_en[35] = gpio_loopback_zero[35];
 assign gpio_analog_pol[35] = gpio_loopback_zero[35];
 assign gpio_analog_sel[35] = gpio_loopback_zero[35];
 assign gpio_holdover[35] = gpio_loopback_zero[35];
 assign gpio_analog_en[36] = gpio_loopback_zero[36];
 assign gpio_analog_pol[36] = gpio_loopback_zero[36];
 assign gpio_analog_sel[36] = gpio_loopback_zero[36];
 assign gpio_holdover[36] = gpio_loopback_zero[36];
 assign gpio_analog_en[37] = gpio_loopback_zero[37];
 assign gpio_analog_pol[37] = gpio_loopback_zero[37];
 assign gpio_analog_sel[37] = gpio_loopback_zero[37];
 assign gpio_holdover[37] = gpio_loopback_zero[37];
 assign gpio_analog_en[38] = gpio_loopback_zero[38];
 assign gpio_analog_pol[38] = gpio_loopback_zero[38];
 assign gpio_analog_sel[38] = gpio_loopback_zero[38];
 assign gpio_holdover[38] = gpio_loopback_zero[38];
 assign gpio_analog_en[39] = gpio_loopback_zero[39];
 assign gpio_analog_pol[39] = gpio_loopback_zero[39];
 assign gpio_analog_sel[39] = gpio_loopback_zero[39];
 assign gpio_holdover[39] = gpio_loopback_zero[39];
 assign gpio_analog_en[3] = gpio_loopback_zero[3];
 assign gpio_analog_pol[3] = gpio_loopback_zero[3];
 assign gpio_analog_sel[3] = gpio_loopback_zero[3];
 assign gpio_holdover[3] = gpio_loopback_zero[3];
 assign gpio_analog_en[40] = gpio_loopback_zero[40];
 assign gpio_analog_pol[40] = gpio_loopback_zero[40];
 assign gpio_analog_sel[40] = gpio_loopback_zero[40];
 assign gpio_holdover[40] = gpio_loopback_zero[40];
 assign gpio_analog_en[41] = gpio_loopback_zero[41];
 assign gpio_analog_pol[41] = gpio_loopback_zero[41];
 assign gpio_analog_sel[41] = gpio_loopback_zero[41];
 assign gpio_holdover[41] = gpio_loopback_zero[41];
 assign gpio_analog_en[42] = gpio_loopback_zero[42];
 assign gpio_analog_pol[42] = gpio_loopback_zero[42];
 assign gpio_analog_sel[42] = gpio_loopback_zero[42];
 assign gpio_holdover[42] = gpio_loopback_zero[42];
 assign gpio_analog_en[43] = gpio_loopback_zero[43];
 assign gpio_analog_pol[43] = gpio_loopback_zero[43];
 assign gpio_analog_sel[43] = gpio_loopback_zero[43];
 assign gpio_holdover[43] = gpio_loopback_zero[43];
 assign gpio_analog_en[4] = gpio_loopback_zero[4];
 assign gpio_analog_pol[4] = gpio_loopback_zero[4];
 assign gpio_analog_sel[4] = gpio_loopback_zero[4];
 assign gpio_holdover[4] = gpio_loopback_zero[4];
 assign gpio_analog_en[5] = gpio_loopback_zero[5];
 assign gpio_analog_pol[5] = gpio_loopback_zero[5];
 assign gpio_analog_sel[5] = gpio_loopback_zero[5];
 assign gpio_holdover[5] = gpio_loopback_zero[5];
 assign gpio_analog_en[6] = gpio_loopback_zero[6];
 assign gpio_analog_pol[6] = gpio_loopback_zero[6];
 assign gpio_analog_sel[6] = gpio_loopback_zero[6];
 assign gpio_holdover[6] = gpio_loopback_zero[6];
 assign gpio_analog_en[7] = gpio_loopback_zero[7];
 assign gpio_analog_pol[7] = gpio_loopback_zero[7];
 assign gpio_analog_sel[7] = gpio_loopback_zero[7];
 assign gpio_holdover[7] = gpio_loopback_zero[7];
 assign gpio_analog_en[8] = gpio_loopback_zero[8];
 assign gpio_analog_pol[8] = gpio_loopback_zero[8];
 assign gpio_analog_sel[8] = gpio_loopback_zero[8];
 assign gpio_holdover[8] = gpio_loopback_zero[8];
 assign gpio_analog_en[9] = gpio_loopback_zero[9];
 assign gpio_analog_pol[9] = gpio_loopback_zero[9];
 assign gpio_analog_sel[9] = gpio_loopback_zero[9];
 assign gpio_holdover[9] = gpio_loopback_zero[9];
endmodule

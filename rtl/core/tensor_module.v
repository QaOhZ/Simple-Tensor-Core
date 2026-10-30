module tensor_module(
    input  clk, reset, start,
    input  [1:0] mode, pass_idx,
    input  [63:0] A_flat, B_flat, D_flat,
    output [191:0] E_flat,
    output [11:0] c00,c01,c02,c03, c10,c11,c12,c13, c20,c21,c22,c23, c30,c31,c32,c33
);
    wire [11:0] e00,e01,e02,e03, e10,e11,e12,e13, e20,e21,e22,e23, e30,e31,e32,e33;

    wire global_a_signed = (mode != 2'b10) || (pass_idx == 2'd2) || (pass_idx == 2'd3);
    wire global_b_signed = (mode != 2'b10) || (pass_idx == 2'd1) || (pass_idx == 2'd3);

    systolic_4x4 sys (
        .clk(clk), .reset(reset), .start(start),
        .a_signed(global_a_signed), .b_signed(global_b_signed),
        .A_flat(A_flat), .B_flat(B_flat),
        .c00(c00), .c01(c01), .c02(c02), .c03(c03),
        .c10(c10), .c11(c11), .c12(c12), .c13(c13),
        .c20(c20), .c21(c21), .c22(c22), .c23(c23),
        .c30(c30), .c31(c31), .c32(c32), .c33(c33)
    );

    matrix_add_4x4 madd (
        .c00(c00), .c01(c01), .c02(c02), .c03(c03),
        .c10(c10), .c11(c11), .c12(c12), .c13(c13),
        .c20(c20), .c21(c21), .c22(c22), .c23(c23),
        .c30(c30), .c31(c31), .c32(c32), .c33(c33),
        .D_flat(D_flat),
        .e00(e00), .e01(e01), .e02(e02), .e03(e03),
        .e10(e10), .e11(e11), .e12(e12), .e13(e13),
        .e20(e20), .e21(e21), .e22(e22), .e23(e23),
        .e30(e30), .e31(e31), .e32(e32), .e33(e33)
    );

    assign E_flat = {e33,e32,e31,e30, e23,e22,e21,e20, e13,e12,e11,e10, e03,e02,e01,e00};
endmodule

module systolic_4x4(
    input  clk, reset, start,
    input  a_signed, b_signed,
    input  [63:0] A_flat,
    input  [63:0] B_flat,
    output [11:0] c00, c01, c02, c03,
    output [11:0] c10, c11, c12, c13,
    output [11:0] c20, c21, c22, c23,
    output [11:0] c30, c31, c32, c33
);
    wire [3:0] a_edge0, a_edge1, a_edge2, a_edge3;
    wire [3:0] b_edge0, b_edge1, b_edge2, b_edge3;

    mem_reuse_pipe mrp (
        .clk(clk), .reset(reset), .start(start),
        .A_flat(A_flat), .B_flat(B_flat),
        .a_edge0(a_edge0), .a_edge1(a_edge1), .a_edge2(a_edge2), .a_edge3(a_edge3),
        .b_edge0(b_edge0), .b_edge1(b_edge1), .b_edge2(b_edge2), .b_edge3(b_edge3)
    );

    matrix_mult_4x4 mm (
        .clk(clk), .reset(reset),
        .a_signed(a_signed), .b_signed(b_signed),
        .a_edge0(a_edge0), .a_edge1(a_edge1), .a_edge2(a_edge2), .a_edge3(a_edge3),
        .b_edge0(b_edge0), .b_edge1(b_edge1), .b_edge2(b_edge2), .b_edge3(b_edge3),
        .c00(c00), .c01(c01), .c02(c02), .c03(c03),
        .c10(c10), .c11(c11), .c12(c12), .c13(c13),
        .c20(c20), .c21(c21), .c22(c22), .c23(c23),
        .c30(c30), .c31(c31), .c32(c32), .c33(c33)
    );
endmodule

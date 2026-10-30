module matrix_mult_4x4(
    input  clk, reset,
    input  a_signed, b_signed,
    input  [3:0] a_edge0, a_edge1, a_edge2, a_edge3,
    input  [3:0] b_edge0, b_edge1, b_edge2, b_edge3,
    output [11:0] c00, c01, c02, c03,
    output [11:0] c10, c11, c12, c13,
    output [11:0] c20, c21, c22, c23,
    output [11:0] c30, c31, c32, c33
);
    wire [3:0] a_pass_0_0, a_pass_0_1, a_pass_0_2, a_pass_0_3;
    wire [3:0] a_pass_1_0, a_pass_1_1, a_pass_1_2, a_pass_1_3;
    wire [3:0] a_pass_2_0, a_pass_2_1, a_pass_2_2, a_pass_2_3;
    wire [3:0] a_pass_3_0, a_pass_3_1, a_pass_3_2, a_pass_3_3;

    wire [3:0] b_pass_0_0, b_pass_0_1, b_pass_0_2, b_pass_0_3;
    wire [3:0] b_pass_1_0, b_pass_1_1, b_pass_1_2, b_pass_1_3;
    wire [3:0] b_pass_2_0, b_pass_2_1, b_pass_2_2, b_pass_2_3;

    pe pe00 (.clk(clk), .reset(reset), .a_in(a_edge0),    .b_in(b_edge0),    .a_signed(a_signed), .b_signed(b_signed), .sum_in(c00), .a_out(a_pass_0_0), .b_out(b_pass_0_0), .sum_out(c00));
    pe pe01 (.clk(clk), .reset(reset), .a_in(a_pass_0_0), .b_in(b_edge1),    .a_signed(a_signed), .b_signed(b_signed), .sum_in(c01), .a_out(a_pass_0_1), .b_out(b_pass_0_1), .sum_out(c01));
    pe pe02 (.clk(clk), .reset(reset), .a_in(a_pass_0_1), .b_in(b_edge2),    .a_signed(a_signed), .b_signed(b_signed), .sum_in(c02), .a_out(a_pass_0_2), .b_out(b_pass_0_2), .sum_out(c02));
    pe pe03 (.clk(clk), .reset(reset), .a_in(a_pass_0_2), .b_in(b_edge3),    .a_signed(a_signed), .b_signed(b_signed), .sum_in(c03), .a_out(a_pass_0_3), .b_out(b_pass_0_3), .sum_out(c03));

    pe pe10 (.clk(clk), .reset(reset), .a_in(a_edge1),    .b_in(b_pass_0_0), .a_signed(a_signed), .b_signed(b_signed), .sum_in(c10), .a_out(a_pass_1_0), .b_out(b_pass_1_0), .sum_out(c10));
    pe pe11 (.clk(clk), .reset(reset), .a_in(a_pass_1_0), .b_in(b_pass_0_1), .a_signed(a_signed), .b_signed(b_signed), .sum_in(c11), .a_out(a_pass_1_1), .b_out(b_pass_1_1), .sum_out(c11));
    pe pe12 (.clk(clk), .reset(reset), .a_in(a_pass_1_1), .b_in(b_pass_0_2), .a_signed(a_signed), .b_signed(b_signed), .sum_in(c12), .a_out(a_pass_1_2), .b_out(b_pass_1_2), .sum_out(c12));
    pe pe13 (.clk(clk), .reset(reset), .a_in(a_pass_1_2), .b_in(b_pass_0_3), .a_signed(a_signed), .b_signed(b_signed), .sum_in(c13), .a_out(a_pass_1_3), .b_out(b_pass_1_3), .sum_out(c13));

    pe pe20 (.clk(clk), .reset(reset), .a_in(a_edge2),    .b_in(b_pass_1_0), .a_signed(a_signed), .b_signed(b_signed), .sum_in(c20), .a_out(a_pass_2_0), .b_out(b_pass_2_0), .sum_out(c20));
    pe pe21 (.clk(clk), .reset(reset), .a_in(a_pass_2_0), .b_in(b_pass_1_1), .a_signed(a_signed), .b_signed(b_signed), .sum_in(c21), .a_out(a_pass_2_1), .b_out(b_pass_2_1), .sum_out(c21));
    pe pe22 (.clk(clk), .reset(reset), .a_in(a_pass_2_1), .b_in(b_pass_1_2), .a_signed(a_signed), .b_signed(b_signed), .sum_in(c22), .a_out(a_pass_2_2), .b_out(b_pass_2_2), .sum_out(c22));
    pe pe23 (.clk(clk), .reset(reset), .a_in(a_pass_2_2), .b_in(b_pass_1_3), .a_signed(a_signed), .b_signed(b_signed), .sum_in(c23), .a_out(a_pass_2_3), .b_out(b_pass_2_3), .sum_out(c23));

    pe pe30 (.clk(clk), .reset(reset), .a_in(a_edge3),    .b_in(b_pass_2_0), .a_signed(a_signed), .b_signed(b_signed), .sum_in(c30), .a_out(a_pass_3_0), .b_out(), .sum_out(c30));
    pe pe31 (.clk(clk), .reset(reset), .a_in(a_pass_3_0), .b_in(b_pass_2_1), .a_signed(a_signed), .b_signed(b_signed), .sum_in(c31), .a_out(a_pass_3_1), .b_out(), .sum_out(c31));
    pe pe32 (.clk(clk), .reset(reset), .a_in(a_pass_3_1), .b_in(b_pass_2_2), .a_signed(a_signed), .b_signed(b_signed), .sum_in(c32), .a_out(a_pass_3_2), .b_out(), .sum_out(c32));
    pe pe33 (.clk(clk), .reset(reset), .a_in(a_pass_3_2), .b_in(b_pass_2_3), .a_signed(a_signed), .b_signed(b_signed), .sum_in(c33), .a_out(),           .b_out(), .sum_out(c33));
endmodule

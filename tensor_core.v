module full_adder(
    input  A, B, Cin,
    output S, Cout
);
    assign S    = A ^ B ^ Cin;
    assign Cout = (A & B) | (Cin & (A ^ B));
endmodule

module adder_4bit(
    input  [3:0] A, B,
    input        Cin,
    output [3:0] Sum,
    output       Cout
);
    wire c1, c2, c3;

    full_adder fa0 (.A(A[0]), .B(B[0]), .Cin(Cin), .S(Sum[0]), .Cout(c1));
    full_adder fa1 (.A(A[1]), .B(B[1]), .Cin(c1),  .S(Sum[1]), .Cout(c2));
    full_adder fa2 (.A(A[2]), .B(B[2]), .Cin(c2),  .S(Sum[2]), .Cout(c3));
    full_adder fa3 (.A(A[3]), .B(B[3]), .Cin(c3),  .S(Sum[3]), .Cout(Cout));
endmodule

module carry_adder_4bit(
    input  [3:0] A, B,
    input        Cin,
    output [3:0] Sum,
    output       Cout
);
    wire [3:0] G, P;
    wire C0, C1, C2, C3, C4;

    assign G = A & B;
    assign P = A ^ B;
    assign C0 = Cin;

    assign C1 = G[0] | (P[0] & C0);
    assign C2 = G[1] | (P[1] & G[0]) | (P[1] & P[0] & C0);
    assign C3 = G[2] | (P[2] & G[1]) | (P[2] & P[1] & G[0]) | (P[2] & P[1] & P[0] & C0);
    assign C4 = G[3] | (P[3] & G[2]) | (P[3] & P[2] & G[1]) | (P[3] & P[2] & P[1] & G[0])
                      | (P[3] & P[2] & P[1] & P[0] & C0);

    assign Sum[0] = P[0] ^ C0;
    assign Sum[1] = P[1] ^ C1;
    assign Sum[2] = P[2] ^ C2;
    assign Sum[3] = P[3] ^ C3;
    assign Cout   = C4;
endmodule

module adder_8bit(
    input  [7:0] A, B,
    input        Cin,
    output [7:0] Sum,
    output       Cout
);
    wire c_mid;

    carry_adder_4bit low_nibble  (.A(A[3:0]), .B(B[3:0]), .Cin(Cin),   .Sum(Sum[3:0]), .Cout(c_mid));
    carry_adder_4bit high_nibble (.A(A[7:4]), .B(B[7:4]), .Cin(c_mid), .Sum(Sum[7:4]), .Cout(Cout));
endmodule

module adder_12bit(
    input  [11:0] A, B,
    input         Cin,
    output [11:0] Sum,
    output        Cout
);
    wire c1, c2;

    carry_adder_4bit low  (.A(A[3:0]),  .B(B[3:0]),  .Cin(Cin), .Sum(Sum[3:0]),  .Cout(c1));
    carry_adder_4bit mid  (.A(A[7:4]),  .B(B[7:4]),  .Cin(c1),  .Sum(Sum[7:4]),  .Cout(c2));
    carry_adder_4bit high (.A(A[11:8]), .B(B[11:8]), .Cin(c2),  .Sum(Sum[11:8]), .Cout(Cout));
endmodule

module multiplier_4bit(
    input  [3:0] A, B,
    input        A_signed, B_signed,
    output [7:0] Product
);
    wire [3:0] pp0 = A & {4{B[0]}};
    wire [3:0] pp1 = A & {4{B[1]}};
    wire [3:0] pp2 = A & {4{B[2]}};
    wire [3:0] pp3 = A & {4{B[3]}};

    wire ext0 = A_signed & pp0[3];
    wire ext1 = A_signed & pp1[3];
    wire ext2 = A_signed & pp2[3];
    wire ext3 = A_signed & pp3[3];

    wire [7:0] pp0_ext = {{4{ext0}}, pp0};
    wire [7:0] pp1_ext = {{3{ext1}}, pp1, 1'b0};
    wire [7:0] pp2_ext = {{2{ext2}}, pp2, 2'b00};
    wire [7:0] pp3_ext = {{1{ext3}}, pp3, 3'b000};

    wire [7:0] pp3_final = B_signed ? ~pp3_ext : pp3_ext;

    wire [7:0] sum1, sum2;
    adder_8bit add_stage1 (.A(pp0_ext), .B(pp1_ext), .Cin(1'b0), .Sum(sum1),    .Cout());
    adder_8bit add_stage2 (.A(sum1),    .B(pp2_ext), .Cin(1'b0), .Sum(sum2),    .Cout());
    adder_8bit add_stage3 (.A(sum2),    .B(pp3_final), .Cin(B_signed), .Sum(Product), .Cout());
endmodule

module matrix_add_4x4(
    input  [11:0] c00,c01,c02,c03,
    input  [11:0] c10,c11,c12,c13,
    input  [11:0] c20,c21,c22,c23,
    input  [11:0] c30,c31,c32,c33,
    input  [63:0] D_flat,
    output [11:0] e00,e01,e02,e03,
    output [11:0] e10,e11,e12,e13,
    output [11:0] e20,e21,e22,e23,
    output [11:0] e30,e31,e32,e33
);
    wire [11:0] d00 = {{8{D_flat[3]}}, D_flat[3:0]};
    wire [11:0] d01 = {{8{D_flat[7]}}, D_flat[7:4]};
    wire [11:0] d02 = {{8{D_flat[11]}}, D_flat[11:8]};
    wire [11:0] d03 = {{8{D_flat[15]}}, D_flat[15:12]};
    wire [11:0] d10 = {{8{D_flat[19]}}, D_flat[19:16]};
    wire [11:0] d11 = {{8{D_flat[23]}}, D_flat[23:20]};
    wire [11:0] d12 = {{8{D_flat[27]}}, D_flat[27:24]};
    wire [11:0] d13 = {{8{D_flat[31]}}, D_flat[31:28]};
    wire [11:0] d20 = {{8{D_flat[35]}}, D_flat[35:32]};
    wire [11:0] d21 = {{8{D_flat[39]}}, D_flat[39:36]};
    wire [11:0] d22 = {{8{D_flat[43]}}, D_flat[43:40]};
    wire [11:0] d23 = {{8{D_flat[47]}}, D_flat[47:44]};
    wire [11:0] d30 = {{8{D_flat[51]}}, D_flat[51:48]};
    wire [11:0] d31 = {{8{D_flat[55]}}, D_flat[55:52]};
    wire [11:0] d32 = {{8{D_flat[59]}}, D_flat[59:56]};
    wire [11:0] d33 = {{8{D_flat[63]}}, D_flat[63:60]};

    adder_12bit a00(.A(c00), .B(d00), .Cin(1'b0), .Sum(e00), .Cout());
    adder_12bit a01(.A(c01), .B(d01), .Cin(1'b0), .Sum(e01), .Cout());
    adder_12bit a02(.A(c02), .B(d02), .Cin(1'b0), .Sum(e02), .Cout());
    adder_12bit a03(.A(c03), .B(d03), .Cin(1'b0), .Sum(e03), .Cout());
    adder_12bit a10(.A(c10), .B(d10), .Cin(1'b0), .Sum(e10), .Cout());
    adder_12bit a11(.A(c11), .B(d11), .Cin(1'b0), .Sum(e11), .Cout());
    adder_12bit a12(.A(c12), .B(d12), .Cin(1'b0), .Sum(e12), .Cout());
    adder_12bit a13(.A(c13), .B(d13), .Cin(1'b0), .Sum(e13), .Cout());
    adder_12bit a20(.A(c20), .B(d20), .Cin(1'b0), .Sum(e20), .Cout());
    adder_12bit a21(.A(c21), .B(d21), .Cin(1'b0), .Sum(e21), .Cout());
    adder_12bit a22(.A(c22), .B(d22), .Cin(1'b0), .Sum(e22), .Cout());
    adder_12bit a23(.A(c23), .B(d23), .Cin(1'b0), .Sum(e23), .Cout());
    adder_12bit a30(.A(c30), .B(d30), .Cin(1'b0), .Sum(e30), .Cout());
    adder_12bit a31(.A(c31), .B(d31), .Cin(1'b0), .Sum(e31), .Cout());
    adder_12bit a32(.A(c32), .B(d32), .Cin(1'b0), .Sum(e32), .Cout());
    adder_12bit a33(.A(c33), .B(d33), .Cin(1'b0), .Sum(e33), .Cout());
endmodule

module pe(
    input  clk, reset,
    input  [3:0]  a_in, b_in,
    input         a_signed, b_signed,
    input  [11:0] sum_in,
    output reg [3:0]  a_out, b_out,
    output reg [11:0] sum_out
);
    wire [7:0]  product;
    multiplier_4bit mult (
        .A(a_in), .B(b_in),
        .A_signed(a_signed), .B_signed(b_signed),
        .Product(product)
    );

    wire p_signed = a_signed | b_signed;
    wire p_ext_bit = p_signed & product[7];
    wire [11:0] product_ext = {{4{p_ext_bit}}, product};

    wire [11:0] sum_next;
    adder_12bit acc_add (.A(sum_in), .B(product_ext), .Cin(1'b0), .Sum(sum_next), .Cout());

    always @(posedge clk) begin
        if (reset) begin
            a_out   <= 4'b0;
            b_out   <= 4'b0;
            sum_out <= 12'b0;
        end else begin
            a_out   <= a_in;
            b_out   <= b_in;
            sum_out <= sum_next;
        end
    end
endmodule

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

module row_stagger #(parameter DELAY = 0) (
    input  clk, reset, start,
    input  [15:0] row_data,
    output [3:0]  a_out
);
    wire load_pulse;

    generate
        if (DELAY == 0) begin : no_delay
            assign load_pulse = start;
        end else begin : delay_chain
            reg [DELAY-1:0] chain;
            integer k;
            always @(posedge clk) begin
                if (reset)
                    chain <= {DELAY{1'b0}};
                else begin
                    chain[0] <= start;
                    for (k = 1; k < DELAY; k = k + 1)
                        chain[k] <= chain[k-1];
                end
            end
            assign load_pulse = chain[DELAY-1];
        end
    endgenerate

    reg [15:0] shift_reg;

    always @(posedge clk) begin
        if (reset)
            shift_reg <= 16'b0;
        else if (load_pulse)
            shift_reg <= row_data;
        else
            shift_reg <= {4'b0000, shift_reg[15:4]};
    end

    assign a_out = shift_reg[3:0];
endmodule

module mem_reuse_pipe(
    input  clk, reset, start,
    input  [63:0] A_flat,
    input  [63:0] B_flat,
    output [3:0]  a_edge0, a_edge1, a_edge2, a_edge3,
    output [3:0]  b_edge0, b_edge1, b_edge2, b_edge3
);
    wire [15:0] a_row0 = A_flat[15:0];
    wire [15:0] a_row1 = A_flat[31:16];
    wire [15:0] a_row2 = A_flat[47:32];
    wire [15:0] a_row3 = A_flat[63:48];

    wire [15:0] b_col0 = {B_flat[51:48], B_flat[35:32], B_flat[19:16], B_flat[3:0]};
    wire [15:0] b_col1 = {B_flat[55:52], B_flat[39:36], B_flat[23:20], B_flat[7:4]};
    wire [15:0] b_col2 = {B_flat[59:56], B_flat[43:40], B_flat[27:24], B_flat[11:8]};
    wire [15:0] b_col3 = {B_flat[63:60], B_flat[47:44], B_flat[31:28], B_flat[15:12]};

    row_stagger #(.DELAY(0)) rs_a0 (.clk(clk), .reset(reset), .start(start), .row_data(a_row0), .a_out(a_edge0));
    row_stagger #(.DELAY(1)) rs_a1 (.clk(clk), .reset(reset), .start(start), .row_data(a_row1), .a_out(a_edge1));
    row_stagger #(.DELAY(2)) rs_a2 (.clk(clk), .reset(reset), .start(start), .row_data(a_row2), .a_out(a_edge2));
    row_stagger #(.DELAY(3)) rs_a3 (.clk(clk), .reset(reset), .start(start), .row_data(a_row3), .a_out(a_edge3));

    row_stagger #(.DELAY(0)) rs_b0 (.clk(clk), .reset(reset), .start(start), .row_data(b_col0), .a_out(b_edge0));
    row_stagger #(.DELAY(1)) rs_b1 (.clk(clk), .reset(reset), .start(start), .row_data(b_col1), .a_out(b_edge1));
    row_stagger #(.DELAY(2)) rs_b2 (.clk(clk), .reset(reset), .start(start), .row_data(b_col2), .a_out(b_edge2));
    row_stagger #(.DELAY(3)) rs_b3 (.clk(clk), .reset(reset), .start(start), .row_data(b_col3), .a_out(b_edge3));
endmodule

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

module adder_20bit(
    input  [19:0] A, B,
    input         Cin,
    output [19:0] Sum,
    output        Cout
);
    wire c1, c2, c3, c4;

    carry_adder_4bit n0 (.A(A[3:0]),   .B(B[3:0]),   .Cin(Cin), .Sum(Sum[3:0]),   .Cout(c1));
    carry_adder_4bit n1 (.A(A[7:4]),   .B(B[7:4]),   .Cin(c1),  .Sum(Sum[7:4]),   .Cout(c2));
    carry_adder_4bit n2 (.A(A[11:8]),  .B(B[11:8]),  .Cin(c2),  .Sum(Sum[11:8]),  .Cout(c3));
    carry_adder_4bit n3 (.A(A[15:12]), .B(B[15:12]), .Cin(c3),  .Sum(Sum[15:12]), .Cout(c4));
    carry_adder_4bit n4 (.A(A[19:16]), .B(B[19:16]), .Cin(c4),  .Sum(Sum[19:16]), .Cout(Cout));
endmodule

module data_ctrl_unit(
    input        clk, reset, start,
    input  [1:0] mode,
    output reg        core_reset,
    output reg        core_start,
    output reg [1:0]  pass_idx,
    output reg        capture_en,
    output reg        combine_en,
    output reg        valid,
    output reg        busy,
    output             idle
);
    localparam S_IDLE       = 3'd0,
               S_CORE_RESET = 3'd1,
               S_RUN        = 3'd2,
               S_CAPTURE    = 3'd3,
               S_COMBINE    = 3'd4,
               S_DONE       = 3'd5;

    reg [2:0] state;
    reg [3:0] run_ctr;
    reg [1:0] mode_r;

    wire is_8bit = (mode_r == 2'b10);
    assign idle = (state == S_IDLE);

    always @(posedge clk) begin
        if (reset) begin
            state      <= S_IDLE;
            core_reset <= 1'b0;
            core_start <= 1'b0;
            pass_idx   <= 2'd0;
            capture_en <= 1'b0;
            combine_en <= 1'b0;
            valid      <= 1'b0;
            busy       <= 1'b0;
            run_ctr    <= 4'd0;
            mode_r     <= 2'b00;
        end else begin
            core_reset <= 1'b0;
            core_start <= 1'b0;
            capture_en <= 1'b0;
            combine_en <= 1'b0;

            case (state)
                S_IDLE: begin
                    busy  <= 1'b0;
                    if (start) begin
                        valid    <= 1'b0;
                        mode_r   <= mode;
                        pass_idx <= 2'd0;
                        busy     <= 1'b1;
                        state    <= S_CORE_RESET;
                    end
                end

                S_CORE_RESET: begin
                    core_reset <= 1'b1;
                    run_ctr    <= 4'd0;
                    if (capture_en)
                        pass_idx <= pass_idx + 2'd1;
                    state <= S_RUN;
                end

                S_RUN: begin
                    if (run_ctr == 4'd0)
                        core_start <= 1'b1;
                    if (run_ctr == 4'd10)
                        state <= S_CAPTURE;
                    else
                        run_ctr <= run_ctr + 4'd1;
                end

                S_CAPTURE: begin
                    capture_en <= 1'b1;
                    if (is_8bit && pass_idx != 2'd3) begin
                        state <= S_CORE_RESET;
                    end else begin
                        state <= S_COMBINE;
                    end
                end

                S_COMBINE: begin
                    combine_en <= 1'b1;
                    state      <= S_DONE;
                end

                S_DONE: begin
                    valid <= 1'b1;
                    busy  <= 1'b0;
                    state <= S_IDLE;
                end

                default: state <= S_IDLE;
            endcase
        end
    end
endmodule

module io_manager(
    input          clk, reset,
    input          latch_en,
    input  [1:0]   mode,
    input  [127:0] A_in, B_in, D_in,
    input  [1:0]   pass_idx,
    input          capture_en,
    input          combine_en,
    input  [191:0] core_E_flat,
    output [63:0]  core_A_flat,
    output [63:0]  core_B_flat,
    output [63:0]  core_D_flat,
    output [319:0] E_out
);
    reg [1:0]   mode_reg;
    reg [127:0] A_reg, B_reg, D_reg;

    always @(posedge clk) begin
        if (reset) begin
            mode_reg <= 2'b00;
            A_reg    <= 128'b0;
            B_reg    <= 128'b0;
            D_reg    <= 128'b0;
        end else if (latch_en) begin
            mode_reg <= mode;
            A_reg    <= A_in;
            B_reg    <= B_in;
            D_reg    <= D_in;
        end
    end

    function automatic [3:0] operand_nibble;
        input [7:0] slot;
        input [1:0] md;
        input       use_hi;
        begin
            case (md)
                2'b00:   operand_nibble = {{2{slot[1]}}, slot[1:0]};
                2'b01:   operand_nibble = slot[3:0];
                2'b10:   operand_nibble = use_hi ? slot[7:4] : slot[3:0];
                default: operand_nibble = slot[3:0];
            endcase
        end
    endfunction

    wire a_use_hi = (pass_idx == 2'd2) || (pass_idx == 2'd3);
    wire b_use_hi = (pass_idx == 2'd1) || (pass_idx == 2'd3);

    genvar k;
    generate
        for (k = 0; k < 16; k = k + 1) begin : mux_operands
            assign core_A_flat[4*k+3 : 4*k] =
                operand_nibble(A_reg[8*k+7 : 8*k], mode_reg, a_use_hi);
            assign core_B_flat[4*k+3 : 4*k] =
                operand_nibble(B_reg[8*k+7 : 8*k], mode_reg, b_use_hi);
        end
    endgenerate

    generate
        for (k = 0; k < 16; k = k + 1) begin : mux_bias
            assign core_D_flat[4*k+3 : 4*k] =
                (mode_reg == 2'b10) ? 4'b0000 :
                (mode_reg == 2'b00) ? {{2{D_reg[8*k+1]}}, D_reg[8*k+1 : 8*k]} :
                                       D_reg[8*k+3 : 8*k];
        end
    endgenerate

    reg [191:0] p_LL, p_LH, p_HL, p_HH;

    always @(posedge clk) begin
        if (reset) begin
            p_LL <= 192'b0; p_LH <= 192'b0; p_HL <= 192'b0; p_HH <= 192'b0;
        end else if (capture_en) begin
            case (pass_idx)
                2'd0: p_LL <= core_E_flat;
                2'd1: p_LH <= core_E_flat;
                2'd2: p_HL <= core_E_flat;
                2'd3: p_HH <= core_E_flat;
            endcase
        end
    end

    wire [319:0] combined;

    generate
        for (k = 0; k < 16; k = k + 1) begin : combine_elem
            wire [11:0] ll = p_LL[12*k+11 : 12*k];
            wire [11:0] lh = p_LH[12*k+11 : 12*k];
            wire [11:0] hl = p_HL[12*k+11 : 12*k];
            wire [11:0] hh = p_HH[12*k+11 : 12*k];
            wire [7:0]  d8 = D_reg[8*k+7 : 8*k];

            wire [19:0] hl_shifted = { {4{hl[11]}}, hl, 4'b0000 };
            wire [19:0] lh_shifted = { {4{lh[11]}}, lh, 4'b0000 };
            wire [19:0] hh_shifted = { hh, 8'b00000000 };
            wire [19:0] ll_ext     = { {8{ll[11]}}, ll };
            wire [19:0] d_ext      = { {12{d8[7]}}, d8 };

            wire [19:0] t1, t2, t3, t4;

            adder_20bit add1 (.A(hl_shifted), .B(lh_shifted), .Cin(1'b0), .Sum(t1), .Cout());
            adder_20bit add2 (.A(hh_shifted), .B(t1),         .Cin(1'b0), .Sum(t2), .Cout());
            adder_20bit add3 (.A(t2),         .B(ll_ext),     .Cin(1'b0), .Sum(t3), .Cout());
            adder_20bit add4 (.A(t3),         .B(d_ext),      .Cin(1'b0), .Sum(t4), .Cout());

            wire [19:0] single_pass_val = {{8{core_E_flat[12*k+11]}}, core_E_flat[12*k+11 : 12*k]};

            assign combined[20*k+19 : 20*k] = (mode_reg == 2'b10) ? t4 : single_pass_val;
        end
    endgenerate

    reg [319:0] E_reg;
    always @(posedge clk) begin
        if (reset)          E_reg <= 320'b0;
        else if (combine_en) E_reg <= combined;
    end

    assign E_out = E_reg;
endmodule

module simple_tensor_core(
    input         clk, reset, start,
    input  [1:0]  mode,

    input  [7:0]  A00, A01, A02, A03,
    input  [7:0]  A10, A11, A12, A13,
    input  [7:0]  A20, A21, A22, A23,
    input  [7:0]  A30, A31, A32, A33,

    input  [7:0]  B00, B01, B02, B03,
    input  [7:0]  B10, B11, B12, B13,
    input  [7:0]  B20, B21, B22, B23,
    input  [7:0]  B30, B31, B32, B33,

    input  [7:0]  D00, D01, D02, D03,
    input  [7:0]  D10, D11, D12, D13,
    input  [7:0]  D20, D21, D22, D23,
    input  [7:0]  D30, D31, D32, D33,

    output [11:0] C00, C01, C02, C03,
    output [11:0] C10, C11, C12, C13,
    output [11:0] C20, C21, C22, C23,
    output [11:0] C30, C31, C32, C33,

    output [19:0] E00, E01, E02, E03,
    output [19:0] E10, E11, E12, E13,
    output [19:0] E20, E21, E22, E23,
    output [19:0] E30, E31, E32, E33,

    output        valid,
    output        busy
);
    wire        core_reset, core_start;
    wire [1:0]  pass_idx;
    wire        capture_en, combine_en;
    wire [63:0] core_A_flat, core_B_flat, core_D_flat;
    wire [191:0] core_E_flat;
    wire        idle;

    wire [127:0] A_in = {A33,A32,A31,A30, A23,A22,A21,A20, A13,A12,A11,A10, A03,A02,A01,A00};
    wire [127:0] B_in = {B33,B32,B31,B30, B23,B22,B21,B20, B13,B12,B11,B10, B03,B02,B01,B00};
    wire [127:0] D_in = {D33,D32,D31,D30, D23,D22,D21,D20, D13,D12,D11,D10, D03,D02,D01,D00};

    wire [319:0] E_out;
    assign {E33,E32,E31,E30, E23,E22,E21,E20, E13,E12,E11,E10, E03,E02,E01,E00} = E_out;

    data_ctrl_unit ctrl (
        .clk(clk), .reset(reset), .start(start), .mode(mode),
        .core_reset(core_reset), .core_start(core_start),
        .pass_idx(pass_idx),
        .capture_en(capture_en), .combine_en(combine_en),
        .valid(valid), .busy(busy), .idle(idle)
    );

    wire io_latch_en = start & idle;

    io_manager io (
        .clk(clk), .reset(reset), .latch_en(io_latch_en), .mode(mode),
        .A_in(A_in), .B_in(B_in), .D_in(D_in),
        .pass_idx(pass_idx),
        .capture_en(capture_en), .combine_en(combine_en),
        .core_E_flat(core_E_flat),
        .core_A_flat(core_A_flat), .core_B_flat(core_B_flat), .core_D_flat(core_D_flat),
        .E_out(E_out)
    );

    tensor_module core (
        .clk(clk),
        .reset(reset | core_reset),
        .start(core_start),
        .mode(mode),
        .pass_idx(pass_idx),
        .A_flat(core_A_flat), .B_flat(core_B_flat), .D_flat(core_D_flat),
        .E_flat(core_E_flat),
        .c00(C00), .c01(C01), .c02(C02), .c03(C03),
        .c10(C10), .c11(C11), .c12(C12), .c13(C13),
        .c20(C20), .c21(C21), .c22(C22), .c23(C23),
        .c30(C30), .c31(C31), .c32(C32), .c33(C33)
    );
endmodule

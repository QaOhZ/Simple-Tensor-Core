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

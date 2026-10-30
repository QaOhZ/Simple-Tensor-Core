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

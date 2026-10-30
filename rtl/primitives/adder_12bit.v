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

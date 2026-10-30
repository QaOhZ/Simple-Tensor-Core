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

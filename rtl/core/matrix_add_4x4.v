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

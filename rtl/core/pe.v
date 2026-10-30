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

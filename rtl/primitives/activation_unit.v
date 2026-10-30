module activation_unit (
    input         relu_en,
    input  [19:0] in_val,
    output [19:0] out_val
);
    // In 20-bit two's complement, bit 19 is the sign bit.
    // If ReLU is enabled and in_val is negative, clamp to 0; otherwise pass in_val.
    assign out_val = (relu_en && in_val[19]) ? 20'sd0 : in_val;
endmodule

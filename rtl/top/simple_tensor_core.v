module simple_tensor_core(
    input         clk, reset, start,
    input  [1:0]  mode,
    input         relu_en,

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

    wire [319:0] E_raw;
    wire [319:0] E_out;

    genvar act_i;
    generate
        for (act_i = 0; act_i < 16; act_i = act_i + 1) begin : gen_act
            activation_unit act_u (
                .relu_en(relu_en),
                .in_val(E_raw[20*act_i +: 20]),
                .out_val(E_out[20*act_i +: 20])
            );
        end
    endgenerate

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
        .E_out(E_raw)
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

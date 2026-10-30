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

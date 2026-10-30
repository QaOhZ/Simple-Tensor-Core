`timescale 1ns/1ps

/**
 * axis_tensor_core
 * -----------------
 * AXI4-Stream IP Wrapper for simple_tensor_core.
 *
 * Provides standard 32-bit streaming interfaces with backpressure and packet framing:
 * - Slave Interface (S_AXIS): Streams in matrices A, B, and D (12 words total, 4 beats per matrix).
 * - Master Interface (M_AXIS): Streams out matrix E (16 words total, 1 sign-extended element per beat).
 *
 * Input Framing:
 *   Beats 0..3   : Matrix A (Row 0..3, 4 bytes per 32-bit beat)
 *   Beats 4..7   : Matrix B (Row 0..3, 4 bytes per 32-bit beat)
 *   Beats 8..11  : Matrix D (Row 0..3, 4 bytes per 32-bit beat), Beat 11 asserts s_axis_tlast
 *
 * Output Framing:
 *   Beats 0..15  : Matrix E elements (Row 0..3, Col 0..3), each sign-extended to 32 bits.
 *                  Beat 15 asserts m_axis_tlast.
 */
module axis_tensor_core (
    input               clk,
    input               aresetn,

    // Runtime Configuration
    input  [1:0]        cfg_mode,     // 2'b00: 2-bit, 2'b01: 4-bit, 2'b10: 8-bit
    input               cfg_relu_en,  // 0: Linear pass-through, 1: On-chip ReLU activation

    // AXI4-Stream Slave Interface (Inputs A, B, D)
    input  [31:0]       s_axis_tdata,
    input               s_axis_tvalid,
    output              s_axis_tready,
    input               s_axis_tlast,

    // AXI4-Stream Master Interface (Output E)
    output [31:0]       m_axis_tdata,
    output              m_axis_tvalid,
    input               m_axis_tready,
    output              m_axis_tlast
);

    // State Encoding
    localparam [1:0] S_RECV        = 2'd0,
                     S_START       = 2'd1,
                     S_WAIT_CORE   = 2'd2,
                     S_STREAM_OUT  = 2'd3;

    reg [1:0] state;

    // Input buffers for 128-bit flattened matrices
    reg [127:0] A_buf, B_buf, D_buf;
    reg [3:0]   recv_count;

    // Output buffer: 16 elements of 20-bit results
    reg [19:0]  out_buf [0:15];
    reg [3:0]   send_count;

    // Core control signals
    reg         core_start;
    wire        core_valid, core_busy;
    wire        core_reset = ~aresetn;

    // Core outputs
    wire [19:0] E00, E01, E02, E03;
    wire [19:0] E10, E11, E12, E13;
    wire [19:0] E20, E21, E22, E23;
    wire [19:0] E30, E31, E32, E33;

    // Instantiate simple_tensor_core
    simple_tensor_core u_core (
        .clk(clk),
        .reset(core_reset),
        .start(core_start),
        .mode(cfg_mode),
        .relu_en(cfg_relu_en),

        // Matrix A (16 elements of 8-bit)
        .A00(A_buf[7:0]),     .A01(A_buf[15:8]),    .A02(A_buf[23:16]),   .A03(A_buf[31:24]),
        .A10(A_buf[39:32]),   .A11(A_buf[47:40]),   .A12(A_buf[55:48]),   .A13(A_buf[63:56]),
        .A20(A_buf[71:64]),   .A21(A_buf[79:72]),   .A22(A_buf[87:80]),   .A23(A_buf[95:88]),
        .A30(A_buf[103:96]),  .A31(A_buf[111:104]), .A32(A_buf[119:112]), .A33(A_buf[127:120]),

        // Matrix B (16 elements of 8-bit)
        .B00(B_buf[7:0]),     .B01(B_buf[15:8]),    .B02(B_buf[23:16]),   .B03(B_buf[31:24]),
        .B10(B_buf[39:32]),   .B11(B_buf[47:40]),   .B12(B_buf[55:48]),   .B13(B_buf[63:56]),
        .B20(B_buf[71:64]),   .B21(B_buf[79:72]),   .B22(B_buf[87:80]),   .B23(B_buf[95:88]),
        .B30(B_buf[103:96]),  .B31(B_buf[111:104]), .B32(B_buf[119:112]), .B33(B_buf[127:120]),

        // Matrix D (16 elements of 8-bit)
        .D00(D_buf[7:0]),     .D01(D_buf[15:8]),    .D02(D_buf[23:16]),   .D03(D_buf[31:24]),
        .D10(D_buf[39:32]),   .D11(D_buf[47:40]),   .D12(D_buf[55:48]),   .D13(D_buf[63:56]),
        .D20(D_buf[71:64]),   .D21(D_buf[79:72]),   .D22(D_buf[87:80]),   .D23(D_buf[95:88]),
        .D30(D_buf[103:96]),  .D31(D_buf[111:104]), .D32(D_buf[119:112]), .D33(D_buf[127:120]),

        // Outputs
        .C00(), .C01(), .C02(), .C03(),
        .C10(), .C11(), .C12(), .C13(),
        .C20(), .C21(), .C22(), .C23(),
        .C30(), .C31(), .C32(), .C33(),

        .E00(E00), .E01(E01), .E02(E02), .E03(E03),
        .E10(E10), .E11(E11), .E12(E12), .E13(E13),
        .E20(E20), .E21(E21), .E22(E22), .E23(E23),
        .E30(E30), .E31(E31), .E32(E32), .E33(E33),

        .valid(core_valid),
        .busy(core_busy)
    );

    // AXI-Stream Ready is asserted only while receiving data in S_RECV
    assign s_axis_tready = (state == S_RECV);

    // AXI-Stream Master signals
    assign m_axis_tvalid = (state == S_STREAM_OUT);
    assign m_axis_tdata  = (state == S_STREAM_OUT) ? {{12{out_buf[send_count][19]}}, out_buf[send_count]} : 32'b0;
    assign m_axis_tlast  = (state == S_STREAM_OUT) && (send_count == 4'd15);

    integer i;

    always @(posedge clk or negedge aresetn) begin
        if (!aresetn) begin
            state       <= S_RECV;
            recv_count  <= 4'd0;
            send_count  <= 4'd0;
            core_start  <= 1'b0;
            A_buf       <= 128'b0;
            B_buf       <= 128'b0;
            D_buf       <= 128'b0;
            for (i = 0; i < 16; i = i + 1)
                out_buf[i] <= 20'b0;
        end else begin
            case (state)
                S_RECV: begin
                    core_start <= 1'b0;
                    if (s_axis_tvalid && s_axis_tready) begin
                        case (recv_count)
                            4'd0:  A_buf[31:0]    <= s_axis_tdata;
                            4'd1:  A_buf[63:32]   <= s_axis_tdata;
                            4'd2:  A_buf[95:64]   <= s_axis_tdata;
                            4'd3:  A_buf[127:96]  <= s_axis_tdata;

                            4'd4:  B_buf[31:0]    <= s_axis_tdata;
                            4'd5:  B_buf[63:32]   <= s_axis_tdata;
                            4'd6:  B_buf[95:64]   <= s_axis_tdata;
                            4'd7:  B_buf[127:96]  <= s_axis_tdata;

                            4'd8:  D_buf[31:0]    <= s_axis_tdata;
                            4'd9:  D_buf[63:32]   <= s_axis_tdata;
                            4'd10: D_buf[95:64]   <= s_axis_tdata;
                            4'd11: D_buf[127:96]  <= s_axis_tdata;
                        endcase

                        if (recv_count == 4'd11) begin
                            recv_count <= 4'd0;
                            state      <= S_START;
                        end else begin
                            recv_count <= recv_count + 1'b1;
                        end
                    end
                end

                S_START: begin
                    core_start <= 1'b1;
                    state      <= S_WAIT_CORE;
                end

                S_WAIT_CORE: begin
                    core_start <= 1'b0;
                    if (core_valid) begin
                        // Latch compute outputs
                        out_buf[0]  <= E00; out_buf[1]  <= E01; out_buf[2]  <= E02; out_buf[3]  <= E03;
                        out_buf[4]  <= E10; out_buf[5]  <= E11; out_buf[6]  <= E12; out_buf[7]  <= E13;
                        out_buf[8]  <= E20; out_buf[9]  <= E21; out_buf[10] <= E22; out_buf[11] <= E23;
                        out_buf[12] <= E30; out_buf[13] <= E31; out_buf[14] <= E32; out_buf[15] <= E33;

                        send_count <= 4'd0;
                        state      <= S_STREAM_OUT;
                    end
                end

                S_STREAM_OUT: begin
                    if (m_axis_tvalid && m_axis_tready) begin
                        if (send_count == 4'd15) begin
                            send_count <= 4'd0;
                            state      <= S_RECV;
                        end else begin
                            send_count <= send_count + 1'b1;
                        end
                    end
                end

                default: state <= S_RECV;
            endcase
        end
    end

endmodule

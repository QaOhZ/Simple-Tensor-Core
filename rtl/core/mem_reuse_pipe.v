module mem_reuse_pipe(
    input  clk, reset, start,
    input  [63:0] A_flat,
    input  [63:0] B_flat,
    output [3:0]  a_edge0, a_edge1, a_edge2, a_edge3,
    output [3:0]  b_edge0, b_edge1, b_edge2, b_edge3
);
    wire [15:0] a_row0 = A_flat[15:0];
    wire [15:0] a_row1 = A_flat[31:16];
    wire [15:0] a_row2 = A_flat[47:32];
    wire [15:0] a_row3 = A_flat[63:48];

    wire [15:0] b_col0 = {B_flat[51:48], B_flat[35:32], B_flat[19:16], B_flat[3:0]};
    wire [15:0] b_col1 = {B_flat[55:52], B_flat[39:36], B_flat[23:20], B_flat[7:4]};
    wire [15:0] b_col2 = {B_flat[59:56], B_flat[43:40], B_flat[27:24], B_flat[11:8]};
    wire [15:0] b_col3 = {B_flat[63:60], B_flat[47:44], B_flat[31:28], B_flat[15:12]};

    row_stagger #(.DELAY(0)) rs_a0 (.clk(clk), .reset(reset), .start(start), .row_data(a_row0), .a_out(a_edge0));
    row_stagger #(.DELAY(1)) rs_a1 (.clk(clk), .reset(reset), .start(start), .row_data(a_row1), .a_out(a_edge1));
    row_stagger #(.DELAY(2)) rs_a2 (.clk(clk), .reset(reset), .start(start), .row_data(a_row2), .a_out(a_edge2));
    row_stagger #(.DELAY(3)) rs_a3 (.clk(clk), .reset(reset), .start(start), .row_data(a_row3), .a_out(a_edge3));

    row_stagger #(.DELAY(0)) rs_b0 (.clk(clk), .reset(reset), .start(start), .row_data(b_col0), .a_out(b_edge0));
    row_stagger #(.DELAY(1)) rs_b1 (.clk(clk), .reset(reset), .start(start), .row_data(b_col1), .a_out(b_edge1));
    row_stagger #(.DELAY(2)) rs_b2 (.clk(clk), .reset(reset), .start(start), .row_data(b_col2), .a_out(b_edge2));
    row_stagger #(.DELAY(3)) rs_b3 (.clk(clk), .reset(reset), .start(start), .row_data(b_col3), .a_out(b_edge3));
endmodule

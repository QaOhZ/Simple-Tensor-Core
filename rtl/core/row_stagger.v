module row_stagger #(parameter DELAY = 0) (
    input  clk, reset, start,
    input  [15:0] row_data,
    output [3:0]  a_out
);
    wire load_pulse;

    generate
        if (DELAY == 0) begin : no_delay
            assign load_pulse = start;
        end else begin : delay_chain
            reg [DELAY-1:0] chain;
            integer k;
            always @(posedge clk) begin
                if (reset)
                    chain <= {DELAY{1'b0}};
                else begin
                    chain[0] <= start;
                    for (k = 1; k < DELAY; k = k + 1)
                        chain[k] <= chain[k-1];
                end
            end
            assign load_pulse = chain[DELAY-1];
        end
    endgenerate

    reg [15:0] shift_reg;

    always @(posedge clk) begin
        if (reset)
            shift_reg <= 16'b0;
        else if (load_pulse)
            shift_reg <= row_data;
        else
            shift_reg <= {4'b0000, shift_reg[15:4]};
    end

    assign a_out = shift_reg[3:0];
endmodule

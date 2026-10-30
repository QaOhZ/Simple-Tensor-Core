module data_ctrl_unit(
    input        clk, reset, start,
    input  [1:0] mode,
    output reg        core_reset,
    output reg        core_start,
    output reg [1:0]  pass_idx,
    output reg        capture_en,
    output reg        combine_en,
    output reg        valid,
    output reg        busy,
    output             idle
);
    localparam S_IDLE       = 3'd0,
               S_CORE_RESET = 3'd1,
               S_RUN        = 3'd2,
               S_CAPTURE    = 3'd3,
               S_COMBINE    = 3'd4,
               S_DONE       = 3'd5;

    reg [2:0] state;
    reg [3:0] run_ctr;
    reg [1:0] mode_r;

    wire is_8bit = (mode_r == 2'b10);
    assign idle = (state == S_IDLE);

    always @(posedge clk) begin
        if (reset) begin
            state      <= S_IDLE;
            core_reset <= 1'b0;
            core_start <= 1'b0;
            pass_idx   <= 2'd0;
            capture_en <= 1'b0;
            combine_en <= 1'b0;
            valid      <= 1'b0;
            busy       <= 1'b0;
            run_ctr    <= 4'd0;
            mode_r     <= 2'b00;
        end else begin
            core_reset <= 1'b0;
            core_start <= 1'b0;
            capture_en <= 1'b0;
            combine_en <= 1'b0;

            case (state)
                S_IDLE: begin
                    busy  <= 1'b0;
                    if (start) begin
                        valid    <= 1'b0;
                        mode_r   <= mode;
                        pass_idx <= 2'd0;
                        busy     <= 1'b1;
                        state    <= S_CORE_RESET;
                    end
                end

                S_CORE_RESET: begin
                    core_reset <= 1'b1;
                    run_ctr    <= 4'd0;
                    if (capture_en)
                        pass_idx <= pass_idx + 2'd1;
                    state <= S_RUN;
                end

                S_RUN: begin
                    if (run_ctr == 4'd0)
                        core_start <= 1'b1;
                    if (run_ctr == 4'd10)
                        state <= S_CAPTURE;
                    else
                        run_ctr <= run_ctr + 4'd1;
                end

                S_CAPTURE: begin
                    capture_en <= 1'b1;
                    if (is_8bit && pass_idx != 2'd3) begin
                        state <= S_CORE_RESET;
                    end else begin
                        state <= S_COMBINE;
                    end
                end

                S_COMBINE: begin
                    combine_en <= 1'b1;
                    state      <= S_DONE;
                end

                S_DONE: begin
                    valid <= 1'b1;
                    busy  <= 1'b0;
                    state <= S_IDLE;
                end

                default: state <= S_IDLE;
            endcase
        end
    end
endmodule

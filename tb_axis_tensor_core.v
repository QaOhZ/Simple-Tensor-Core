`timescale 1ns/1ps

module tb_axis_tensor_core;

    reg         clk = 0;
    reg         aresetn = 0;
    reg  [1:0]  cfg_mode = 2'b10;  // Default 8-bit mode
    reg         cfg_relu_en = 0;

    // AXI-Stream Slave
    reg  [31:0] s_axis_tdata = 0;
    reg         s_axis_tvalid = 0;
    wire        s_axis_tready;
    reg         s_axis_tlast = 0;

    // AXI-Stream Master
    wire [31:0] m_axis_tdata;
    wire        m_axis_tvalid;
    reg         m_axis_tready = 0;
    wire        m_axis_tlast;

    integer errors = 0;
    integer i, j;

    // Instantiate DUT
    axis_tensor_core dut (
        .clk(clk),
        .aresetn(aresetn),
        .cfg_mode(cfg_mode),
        .cfg_relu_en(cfg_relu_en),

        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .s_axis_tlast(s_axis_tlast),

        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tlast(m_axis_tlast)
    );

    always #5 clk = ~clk;

    // Test matrix storage (signed 8-bit)
    reg signed [7:0]  A [0:3][0:3];
    reg signed [7:0]  B [0:3][0:3];
    reg signed [7:0]  D [0:3][0:3];
    reg signed [31:0] expected [0:15];
    reg signed [31:0] received [0:15];

    task calculate_expected;
        input relu;
        integer r, c, k;
        reg signed [31:0] acc;
        reg signed [31:0] full_val;
        begin
            for (r = 0; r < 4; r = r + 1) begin
                for (c = 0; c < 4; c = c + 1) begin
                    acc = 0;
                    for (k = 0; k < 4; k = k + 1) begin
                        acc = acc + (A[r][k] * B[k][c]);
                    end
                    full_val = acc + D[r][c];
                    if (relu && full_val < 0)
                        expected[4*r + c] = 32'sd0;
                    else
                        expected[4*r + c] = full_val;
                end
            end
        end
    endtask

    task send_matrices_stream;
        integer beat;
        reg [31:0] words [0:11];
        begin
            // Pack rows into 32-bit words
            for (i = 0; i < 4; i = i + 1) begin
                words[i]     = {A[i][3], A[i][2], A[i][1], A[i][0]};
                words[4 + i] = {B[i][3], B[i][2], B[i][1], B[i][0]};
                words[8 + i] = {D[i][3], D[i][2], D[i][1], D[i][0]};
            end

            for (beat = 0; beat < 12; beat = beat + 1) begin
                @(negedge clk);
                s_axis_tdata  = words[beat];
                s_axis_tvalid = 1'b1;
                s_axis_tlast  = (beat == 11);

                // Wait for ready handshake
                @(posedge clk);
                while (!s_axis_tready) begin
                    @(posedge clk);
                end
            end

            @(negedge clk);
            s_axis_tvalid = 1'b0;
            s_axis_tlast  = 1'b0;
            s_axis_tdata  = 32'b0;
        end
    endtask

    task receive_output_stream;
        input inject_backpressure;
        integer beat;
        integer timeout;
        begin
            timeout = 0;
            while (!m_axis_tvalid && timeout < 500) begin
                @(posedge clk);
                timeout = timeout + 1;
            end

            if (timeout == 500) begin
                $display("[ERROR] AXI-Stream master valid timed out!");
                errors = errors + 1;
            end else begin
                m_axis_tready = 1'b1;
                for (beat = 0; beat < 16; beat = beat + 1) begin
                    // Optional backpressure injection on beat 5
                    if (inject_backpressure && beat == 5) begin
                        @(negedge clk);
                        m_axis_tready = 1'b0;
                        repeat (3) @(posedge clk);
                        @(negedge clk);
                        m_axis_tready = 1'b1;
                    end

                    @(posedge clk);
                    while (!m_axis_tvalid) begin
                        @(posedge clk);
                    end

                    received[beat] = $signed(m_axis_tdata);

                    if (beat == 15 && !m_axis_tlast) begin
                        $display("[ERROR] m_axis_tlast was not asserted on beat 15!");
                        errors = errors + 1;
                    end
                end
                @(negedge clk);
                m_axis_tready = 1'b0;
            end
        end
    endtask

    task check_results;
        input [511:0] test_name;
        integer idx;
        begin
            $display("\n--- %0s ---", test_name);
            for (idx = 0; idx < 16; idx = idx + 1) begin
                if (received[idx] !== expected[idx]) begin
                    $display("[FAIL] E[%0d]: got=%0d expected=%0d", idx, received[idx], expected[idx]);
                    errors = errors + 1;
                end
            end
            if (errors == 0)
                $display("[PASS] All 16 AXI-Stream output beats verified!");
        end
    endtask

    initial begin
        $dumpfile("axis_waveform.vcd");
        $dumpvars(0, tb_axis_tensor_core);

        // Reset DUT
        aresetn = 0;
        repeat (4) @(posedge clk);
        aresetn = 1;
        repeat (2) @(posedge clk);

        // =====================================================================
        // Test 1: INT8 Linear Stream with Backpressure
        // =====================================================================
        cfg_mode    = 2'b10;
        cfg_relu_en = 1'b0;

        A[0][0]=10;  A[0][1]=-20; A[0][2]=30;  A[0][3]=-40;
        A[1][0]=-15; A[1][1]=25;  A[1][2]=-35; A[1][3]=45;
        A[2][0]=5;   A[2][1]=-10; A[2][2]=15;  A[2][3]=-20;
        A[3][0]=-50; A[3][1]=60;  A[3][2]=-70; A[3][3]=80;

        B[0][0]=2;   B[0][1]=-3;  B[0][2]=4;   B[0][3]=-5;
        B[1][0]=-1;  B[1][1]=2;   B[1][2]=-3;  B[1][3]=4;
        B[2][0]=3;   B[2][1]=-2;  B[2][2]=1;   B[2][3]=0;
        B[3][0]=-4;  B[3][1]=5;   B[3][2]=-6;  B[3][3]=7;

        D[0][0]=12;  D[0][1]=-15; D[0][2]=20;  D[0][3]=-25;
        D[1][0]=-8;  D[1][1]=14;  D[1][2]=-18; D[1][3]=22;
        D[2][0]=5;   D[2][1]=-7;  D[2][2]=9;   D[2][3]=-11;
        D[3][0]=-30; D[3][1]=40;  D[3][2]=-50; D[3][3]=60;

        calculate_expected(1'b0);
        send_matrices_stream();
        receive_output_stream(1'b1); // Inject backpressure midway
        check_results("Test 1: INT8 Linear AXI4-Stream + Backpressure");

        // =====================================================================
        // Test 2: INT8 with Hardware ReLU Activation Enabled
        // =====================================================================
        cfg_mode    = 2'b10;
        cfg_relu_en = 1'b1;

        calculate_expected(1'b1);
        send_matrices_stream();
        receive_output_stream(1'b0);
        check_results("Test 2: INT8 AXI4-Stream + Hardware ReLU Clamping");

        if (errors == 0) begin
            $display("\n=======================================================");
            $display("   AXI4-STREAM IP VERIFICATION: ALL TESTS PASSED!     ");
            $display("=======================================================\n");
        end else begin
            $display("\n[FAILED] %0d errors encountered in AXI-Stream tests.\n", errors);
        end

        $finish;
    end

endmodule

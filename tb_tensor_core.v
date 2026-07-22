`timescale 1ns/1ps
module tb_simple_tensor_core;

    reg clk = 0;
    reg reset, start;
    reg [1:0] mode;
    reg [127:0] A_in, B_in, D_in;
    wire [319:0] E_out;
    wire valid, busy;

    integer errors = 0;
    integer i, j, k;

    simple_tensor_core dut (
        .clk(clk), .reset(reset), .start(start), .mode(mode),
        .A_in(A_in), .B_in(B_in), .D_in(D_in),
        .E_out(E_out), .valid(valid), .busy(busy)
    );

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_simple_tensor_core);
    end

    always #5 clk = ~clk;

    reg [7:0] A [0:3][0:3];
    reg [7:0] B [0:3][0:3];
    reg [7:0] D [0:3][0:3];
    reg [31:0] expected [0:3][0:3];

    task pack_inputs;
        begin
            A_in = 128'b0; B_in = 128'b0; D_in = 128'b0;
            for (i = 0; i < 4; i = i + 1)
                for (j = 0; j < 4; j = j + 1) begin
                    k = 4*i + j;
                    A_in[8*k +: 8] = A[i][j];
                    B_in[8*k +: 8] = B[i][j];
                    D_in[8*k +: 8] = D[i][j];
                end
        end
    endtask

    task compute_expected;
        integer kk;
        reg signed [31:0] acc;
        reg signed [31:0] a_val, b_val, d_val;
        begin
            for (i = 0; i < 4; i = i + 1)
                for (j = 0; j < 4; j = j + 1) begin
                    acc = 0;
                    for (kk = 0; kk < 4; kk = kk + 1) begin
                        if (mode == 2'b01) begin
                            a_val = {{28{A[i][kk][3]}}, A[i][kk][3:0]};
                            b_val = {{28{B[kk][j][3]}}, B[kk][j][3:0]};
                        end else if (mode == 2'b00) begin
                            a_val = {{30{A[i][kk][1]}}, A[i][kk][1:0]};
                            b_val = {{30{B[kk][j][1]}}, B[kk][j][1:0]};
                        end else begin
                            a_val = {{24{A[i][kk][7]}}, A[i][kk]};
                            b_val = {{24{B[kk][j][7]}}, B[kk][j]};
                        end
                        acc = acc + (a_val * b_val);
                    end

                    if (mode == 2'b01)
                        d_val = {{28{D[i][j][3]}}, D[i][j][3:0]};
                    else if (mode == 2'b00)
                        d_val = {{30{D[i][j][1]}}, D[i][j][1:0]};
                    else
                        d_val = {{24{D[i][j][7]}}, D[i][j]};

                    expected[i][j] = (acc + d_val) & 20'hFFFFF;
                end
        end
    endtask

    task print_matrix;
        input [255:0] label;
        integer r;
        begin
            $display("\n=======================================================");
            $display(" MATRIX COMPUTATION COMPLETE: %0s", label);
            $display("=======================================================");
            
            $display("Input Matrix A:");
            for(r=0; r<4; r=r+1) $display("[%02x] [%02x] [%02x] [%02x]", A[r][0], A[r][1], A[r][2], A[r][3]);
            
            $display("\nInput Matrix B:");
            for(r=0; r<4; r=r+1) $display("[%02x] [%02x] [%02x] [%02x]", B[r][0], B[r][1], B[r][2], B[r][3]);
            
            $display("\nInput Matrix D (Bias):");
            for(r=0; r<4; r=r+1) $display("[%02x] [%02x] [%02x] [%02x]", D[r][0], D[r][1], D[r][2], D[r][3]);

            $display("\nOutput Matrix E (4x4):");
            $display("[%05x] [%05x] [%05x] [%05x]", E_out[19:0],   E_out[39:20],  E_out[59:40],  E_out[79:60]);
            $display("[%05x] [%05x] [%05x] [%05x]", E_out[99:80],  E_out[119:100],E_out[139:120],E_out[159:140]);
            $display("[%05x] [%05x] [%05x] [%05x]", E_out[179:160],E_out[199:180],E_out[219:200],E_out[239:220]);
            $display("[%05x] [%05x] [%05x] [%05x]", E_out[259:240],E_out[279:260],E_out[299:280],E_out[319:300]);
            $display("=======================================================\n");
        end
    endtask

    task run_and_check;
        input [1:0] test_mode;
        input [255:0] label;
        integer i2, j2, k2;
        reg [19:0] got;
        begin
            mode = test_mode;
            pack_inputs();
            compute_expected();
            @(negedge clk);
            start = 1;
            @(negedge clk);
            start = 0;
            wait (valid == 1);
            @(negedge clk);
            
            print_matrix(label);

            for (i2 = 0; i2 < 4; i2 = i2 + 1)
                for (j2 = 0; j2 < 4; j2 = j2 + 1) begin
                    k2 = 4*i2 + j2;
                    got = E_out[20*k2 +: 20];
                    if (got !== expected[i2][j2]) begin
                        errors = errors + 1;
                        $display("FAIL [%0s] E[%0d][%0d]: got=%0d expected=%0d",
                                  label, i2, j2, got, expected[i2][j2]);
                    end
                end
            $display("[%0s] done, valid asserted, checked 16 elements.", label);
        end
    endtask

    initial begin
        reset = 1; start = 0; mode = 2'b01;
        A_in = 0; B_in = 0; D_in = 0;
        repeat (3) @(negedge clk);
        reset = 0;

        for (i=0;i<4;i=i+1) for (j=0;j<4;j=j+1) begin
            A[i][j] = (i+j) % 16;
            B[i][j] = (i*j+1) % 16;
            D[i][j] = (i+2*j) % 16;
        end
        run_and_check(2'b01, "4-bit");

        for (i=0;i<4;i=i+1) for (j=0;j<4;j=j+1) begin
            A[i][j] = (i+j) % 4;
            B[i][j] = (i*j+1) % 4;
            D[i][j] = (i+j) % 4;
        end
        run_and_check(2'b00, "2-bit");

        for (i=0;i<4;i=i+1) for (j=0;j<4;j=j+1) begin
            A[i][j] = 100 + i*10 + j;
            B[i][j] = 200 - i*5  - j;
            D[i][j] = 50 + i + j;
        end
        run_and_check(2'b10, "8-bit");

        for (i=0;i<4;i=i+1) for (j=0;j<4;j=j+1) begin
            A[i][j] = 255;
            B[i][j] = 255;
            D[i][j] = 255;
        end
        run_and_check(2'b10, "8-bit-max");

        for (i=0;i<4;i=i+1) for (j=0;j<4;j=j+1) begin
            A[i][j] = (2*i+j) % 16; B[i][j] = (i+3*j) % 16; D[i][j] = j % 16;
        end
        run_and_check(2'b01, "4-bit-second-run");

        begin : spurious_start_test
            reg [127:0] junkA, junkB, junkD;
            for (i=0;i<4;i=i+1) for (j=0;j<4;j=j+1) begin
                A[i][j] = (i+1)*(j+1);
                B[i][j] = (i+2)*(j+1) % 16;
                D[i][j] = i;
            end
            mode = 2'b01;
            pack_inputs();
            compute_expected();
            junkA = {16{8'hFF}}; junkB = {16{8'hFF}}; junkD = {16{8'hFF}};

            @(negedge clk); start = 1;
            @(negedge clk); start = 0;

            repeat (4) @(negedge clk);
            A_in = junkA; B_in = junkB; D_in = junkD;
            start = 1;
            @(negedge clk); start = 0;

            wait (valid == 1);
            @(negedge clk);
            
            print_matrix("spurious-start");
            
            for (i=0;i<4;i=i+1) for (j=0;j<4;j=j+1) begin
                k = 4*i+j;
                if (E_out[20*k +: 20] !== expected[i][j]) begin
                    errors = errors + 1;
                    $display("FAIL [spurious-start] E[%0d][%0d]: got=%0d expected=%0d",
                              i, j, E_out[20*k +: 20], expected[i][j]);
                end
            end
            $display("[spurious-start] done -- confirms mid-operation start pulses are safely ignored.");
        end

        if (errors == 0)
            $display("\nALL TESTS PASSED");
        else
            $display("\n%0d MISMATCHES FOUND", errors);
	
	begin : custom_file_load
            reg [255:0] filename;
            reg [7:0] file_mem [0:47];
            
            if ($value$plusargs("load=%s", filename)) begin
                $display("\n>>> DYNAMIC I/O DETECTED: Loading from %0s <<<", filename);
                $readmemh(filename, file_mem);
                
                for (i=0; i<4; i=i+1) for (j=0; j<4; j=j+1) begin
                    A[i][j] = file_mem[4*i+j];
                    B[i][j] = file_mem[16 + 4*i+j];
                    D[i][j] = file_mem[32 + 4*i+j];
                end
                
                run_and_check(2'b10, "Custom-Terminal-Input");
                
                if (errors == 0)
                    $display("CUSTOM INPUT PASSED VERIFICATION!");
            end
        end
        $finish;
    end
endmodule

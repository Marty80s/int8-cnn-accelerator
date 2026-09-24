`timescale 1ns/1ps

module tb_matmul_4x4;

    logic clk = 0;
    logic rst_n = 0;
    logic start = 0;
    logic in_valid = 0;

    wire in_ready;
    wire busy;
    wire done;

    logic signed [7:0] a [0:3];
    logic signed [7:0] b [0:3];
    wire signed [31:0] result [0:3][0:3];

    integer matrix_a [0:3][0:3];
    integer matrix_b [0:3][0:3];
    integer expected [0:3][0:3];
    integer partial_sum [0:3][0:3];
    integer tests = 0;

    matmul_4x4 dut (.*);

    always #5 clk = ~clk;

    // Prevent a broken handshake from hanging the simulation.
    initial begin
        #100000;
        $fatal(1, "Simulation timeout");
    end

    task automatic check_partial;
        for (int i = 0; i < 4; i++) begin
            for (int j = 0; j < 4; j++) begin
                if (result[i][j] !== partial_sum[i][j])
                    $fatal(1,
                        "Partial mismatch [%0d][%0d]: expected %0d got %0d",
                        i, j, partial_sum[i][j], result[i][j]);
            end
        end
    endtask

    task automatic begin_job;
        @(negedge clk);
        start = 1;
        in_valid = 0;

        @(posedge clk);
        #1;
        if (busy !== 1'b1 || done !== 1'b0 ||
            in_ready !== 1'b0)
            $fatal(1, "Incorrect control outputs after start");

        @(negedge clk);
        start = 0;

        @(posedge clk);
        #1;
        if (in_ready !== 1'b1 || busy !== 1'b1 ||
            done !== 1'b0)
            $fatal(1, "Controller did not enter COMPUTE");

        for (int i = 0; i < 4; i++) begin
            for (int j = 0; j < 4; j++) begin
                partial_sum[i][j] = 0;
                if (result[i][j] !== 32'sd0)
                    $fatal(1, "New job did not clear accumulators");
            end
        end
    endtask

    task automatic run_job(input bit insert_stalls);
        integer sum_ref;
        integer stall_cycles;

        // Independent complete matrix-product reference.
        for (int i = 0; i < 4; i++) begin
            for (int j = 0; j < 4; j++) begin
                sum_ref = 0;
                for (int k = 0; k < 4; k++)
                    sum_ref = sum_ref
                            + matrix_a[i][k] * matrix_b[k][j];
                expected[i][j] = sum_ref;
            end
        end

        begin_job();

        for (int k = 0; k < 4; k++) begin
            stall_cycles = insert_stalls ? (k + 1) : 0;

            // No valid data: controller and accumulators must wait.
            repeat (stall_cycles) begin
                @(negedge clk);
                in_valid = 0;

                for (int i = 0; i < 4; i++) begin
                    a[i] = 127;
                    b[i] = -128;
                end

                @(posedge clk);
                #1;
                if (busy !== 1'b1 || in_ready !== 1'b1 ||
                    done !== 1'b0)
                    $fatal(1, "Incorrect control outputs during stall");

                check_partial();
            end

            @(negedge clk);
            in_valid = 1;

            // A start request while busy must be ignored.
            start = (k == 1);

            for (int i = 0; i < 4; i++)
                a[i] = matrix_a[i][k];

            for (int j = 0; j < 4; j++)
                b[j] = matrix_b[k][j];

            if (in_ready !== 1'b1)
                $fatal(1, "Not ready for operand set %0d", k);

            @(posedge clk);
            #1;

            for (int i = 0; i < 4; i++) begin
                for (int j = 0; j < 4; j++) begin
                    partial_sum[i][j] = partial_sum[i][j]
                                     + matrix_a[i][k] * matrix_b[k][j];
                end
            end
            check_partial();

            if (k < 3) begin
                if (done !== 1'b0 || busy !== 1'b1 ||
                    in_ready !== 1'b1)
                    $fatal(1, "Controller completed too early");
            end else begin
                if (done !== 1'b1 || busy !== 1'b0 ||
                    in_ready !== 1'b0)
                    $fatal(1, "Incorrect completion timing");
            end

            // Removed before any following rising edge.
            start = 0;
        end

        for (int i = 0; i < 4; i++) begin
            for (int j = 0; j < 4; j++) begin
                if (result[i][j] !== expected[i][j])
                    $fatal(1,
                        "Job %0d [%0d][%0d]: expected %0d got %0d",
                        tests + 1, i, j,
                        expected[i][j], result[i][j]);
            end
        end

        // Valid data while idle must not change the result.
        @(negedge clk);
        in_valid = 1;
        for (int i = 0; i < 4; i++) begin
            a[i] = 127;
            b[i] = 127;
        end

        @(posedge clk);
        #1;
        if (done !== 1'b0 || busy !== 1'b0 ||
            in_ready !== 1'b0)
            $fatal(1, "Done did not pulse for exactly one clock");

        check_partial();

        @(negedge clk);
        in_valid = 0;
        tests++;
    endtask

    initial begin
        for (int i = 0; i < 4; i++) begin
            a[i] = 0;
            b[i] = 0;
        end

        repeat (2) @(posedge clk);
        #1;
        if (busy !== 1'b0 || done !== 1'b0 ||
            in_ready !== 1'b0)
            $fatal(1, "Reset control state incorrect");

        @(negedge clk);
        rst_n = 1;

        // Known matrix multiplied by identity.
        for (int i = 0; i < 4; i++) begin
            for (int j = 0; j < 4; j++) begin
                matrix_a[i][j] = i * 4 + j - 8;
                matrix_b[i][j] = (i == j) ? 1 : 0;
            end
        end

        run_job(0);  // Four consecutive accepted inputs.
        run_job(1);  // Same calculation with input delays.

        // Random jobs without resetting between jobs.
        repeat (20) begin
            for (int i = 0; i < 4; i++) begin
                for (int j = 0; j < 4; j++) begin
                    matrix_a[i][j] =
                        int'($urandom_range(0, 255)) - 128;
                    matrix_b[i][j] =
                        int'($urandom_range(0, 255)) - 128;
                end
            end
            run_job(1);
        end

        // Abort a partially computed job with reset.
        begin_job();

        @(negedge clk);
        in_valid = 1;
        for (int i = 0; i < 4; i++) begin
            a[i] = 2;
            b[i] = 3;
        end

        @(posedge clk);
        #1;
        for (int i = 0; i < 4; i++)
            for (int j = 0; j < 4; j++)
                if (result[i][j] !== 32'sd6)
                    $fatal(1, "Reset test did not accumulate first");

        @(negedge clk);
        rst_n = 0;
        in_valid = 0;

        @(posedge clk);
        #1;
        if (busy !== 1'b0 || done !== 1'b0 ||
            in_ready !== 1'b0)
            $fatal(1, "Mid-computation reset failed");

        for (int i = 0; i < 4; i++)
            for (int j = 0; j < 4; j++)
                if (result[i][j] !== 32'sd0)
                    $fatal(1, "Reset did not clear result");

        @(negedge clk);
        rst_n = 1;

        // Confirm normal operation after the aborted job.
        run_job(0);

        $display("PASS: %0d completed jobs; controller checks passed",
                 tests);
        $finish;
    end

endmodule

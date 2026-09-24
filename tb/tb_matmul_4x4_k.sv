`timescale 1ns/1ps

module tb_matmul_4x4_k;

    logic clk = 0;
    logic rst_n = 0;
    logic start = 0;
    logic [7:0] k_length = 0;
    logic in_valid = 0;
    wire in_ready;
    logic signed [7:0] a [0:3];
    logic signed [7:0] b [0:3];
    wire busy;
    wire done;
    wire signed [31:0] result [0:3][0:3];

    integer expected [0:3][0:3];
    integer jobs = 0;
    integer checks = 0;

    matmul_4x4_k dut (.*);

    always #5 clk = ~clk;

    // Prevent a broken controller from hanging the simulation.
    initial begin
        #100000;
        $fatal(1, "Simulation timeout");
    end

    task automatic check_control(
        input bit expected_busy,
        input bit expected_ready,
        input bit expected_done
    );
        if ((busy !== expected_busy) ||
            (in_ready !== expected_ready) ||
            (done !== expected_done))
            $fatal(1,
                "Control mismatch: busy=%b ready=%b done=%b",
                busy, in_ready, done);
    endtask

    task automatic check_results;
        for (int i = 0; i < 4; i++) begin
            for (int j = 0; j < 4; j++) begin
                if (result[i][j] !== expected[i][j])
                    $fatal(1,
                        "Job %0d [%0d][%0d]: expected %0d, got %0d",
                        jobs + 1, i, j,
                        expected[i][j], result[i][j]);
                checks++;
            end
        end
    endtask

    task automatic zero_expected;
        for (int i = 0; i < 4; i++)
            for (int j = 0; j < 4; j++)
                expected[i][j] = 0;
    endtask

    task automatic begin_job(input int length);
        @(negedge clk);
        start = 1;
        k_length = length;
        in_valid = 0;

        // Start is accepted; controller enters CLEAR.
        @(posedge clk);
        #1;
        check_control(1, 0, 0);

        @(negedge clk);
        start = 0;

        // The array clears; controller enters COMPUTE.
        @(posedge clk);
        #1;
        zero_expected();
        check_control(1, 1, 0);
        check_results();
    endtask

    task automatic run_job(
        input int length,
        input bit insert_stalls
    );
        integer av;
        integer bv;

        begin_job(length);

        for (int k = 0; k < length; k++) begin

            // Insert pauses with deliberately changing operands.
            if (insert_stalls) begin
                repeat ((k % 3) + 1) begin
                    @(negedge clk);
                    in_valid = 0;
                    start = 0;
                    k_length = 0;

                    for (int i = 0; i < 4; i++) begin
                        a[i] = 127;
                        b[i] = -128;
                    end

                    @(posedge clk);
                    #1;
                    check_control(1, 1, 0);
                    check_results();
                end
            end

            @(negedge clk);
            in_valid = 1;

            // Busy start requests and new lengths must be ignored.
            start = 1;
            k_length = 0;

            // Deterministic signed operands, all within INT8 range.
            for (int i = 0; i < 4; i++)
                a[i] = ((k * 17 + i * 29) % 256) - 128;

            for (int j = 0; j < 4; j++)
                b[j] = ((k * 31 + j * 13 + 7) % 256) - 128;

            @(posedge clk);
            #1;

            // Independent integer reference:
            // C[i][j] += A[i][k] * B[k][j].
            for (int i = 0; i < 4; i++) begin
                for (int j = 0; j < 4; j++) begin
                    av = ((k * 17 + i * 29) % 256) - 128;
                    bv = ((k * 31 + j * 13 + 7) % 256) - 128;
                    expected[i][j] = expected[i][j] + av * bv;
                end
            end

            check_results();

            if (k == length - 1)
                check_control(0, 0, 1);
            else
                check_control(1, 1, 0);
        end

        // After completion, valid data alone must not alter results.
        @(negedge clk);
        start = 0;
        in_valid = 1;

        for (int i = 0; i < 4; i++) begin
            a[i] = 127;
            b[i] = 127;
        end

        repeat (2) begin
            @(posedge clk);
            #1;
            check_control(0, 0, 0);
            check_results();
        end

        @(negedge clk);
        in_valid = 0;

        jobs++;
        $display("PASS job %0d: K=%0d stalls=%0d",
                 jobs, length, insert_stalls);
    endtask

    task automatic check_zero_request;
        @(negedge clk);
        start = 1;
        k_length = 0;
        in_valid = 1;

        repeat (2) begin
            @(posedge clk);
            #1;
            check_control(0, 0, 0);
            check_results();
        end

        @(negedge clk);
        start = 0;
        in_valid = 0;
    endtask

    initial begin
        for (int i = 0; i < 4; i++) begin
            a[i] = 0;
            b[i] = 0;
        end

        repeat (2) @(posedge clk);
        #1;
        zero_expected();
        check_control(0, 0, 0);
        check_results();

        @(negedge clk);
        rst_n = 1;

        check_zero_request();

        run_job(1,   0);
        run_job(1,   1);
        run_job(2,   1);
        run_job(3,   1);
        run_job(4,   0);
        run_job(4,   1);
        run_job(8,   1);
        run_job(16,  1);
        run_job(255, 0);
        run_job(255, 1);

        // Invalid start must preserve previous nonzero results.
        check_zero_request();

        // Start a job, perform one update, then reset mid-job.
        begin_job(8);

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
                expected[i][j] = 6;

        check_control(1, 1, 0);
        check_results();

        @(negedge clk);
        rst_n = 0;
        start = 0;
        in_valid = 0;

        @(posedge clk);
        #1;
        zero_expected();
        check_control(0, 0, 0);
        check_results();

        @(negedge clk);
        rst_n = 1;

        // Verify normal operation after reset.
        run_job(3, 1);

        $display(
            "PASS: %0d completed jobs, %0d output checks; zero-length and reset checks passed",
            jobs, checks);
        $finish;
    end

endmodule

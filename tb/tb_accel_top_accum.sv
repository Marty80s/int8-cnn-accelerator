`timescale 1ns/1ps

module tb_accel_top_accum;

    logic clk = 0;
    logic rst_n = 0;

    logic        wr_en = 0;
    logic [7:0]  wr_addr = 0;
    logic [63:0] wr_data = 0;

    logic       start = 0;
    logic [7:0] k_length = 0;

    wire busy;
    wire done;
    wire signed [31:0] result [0:3][0:3];

    integer matrix_a [0:3][0:3];
    integer matrix_b [0:3][0:3];
    integer expected [0:3][0:3];

    logic [63:0] packed_word;
    integer cycles;
    integer checks = 0;
    integer reference_sum;

    accel_top dut (
        .clk      (clk),
        .rst_n    (rst_n),

        .wr_en    (wr_en),
        .wr_addr  (wr_addr),
        .wr_data  (wr_data),

        .start    (start),
        .k_length (k_length),

        .busy     (busy),
        .done     (done),
        .result   (result)
    );

    // Generate a clock with a 10 ns period.
    always #5 clk = ~clk;

    // Write one 64-bit word into operand memory.
    // Drive inputs on a falling edge so they are stable
    // before the memory samples them on the rising edge.
    task automatic write_word(
        input logic [7:0] address,
        input logic [63:0] data
    );
        @(negedge clk);
        wr_en   = 1;
        wr_addr = address;
        wr_data = data;

        @(posedge clk);
        #1;

        @(negedge clk);
        wr_en = 0;
    endtask

    initial begin
        // Matrix A:
        //   1   2   3   4
        //   5   6   7   8
        //  -1  -2  -3  -4
        //  -5  -6  -7  -8
        //
        // Matrix B:
        //   1   2   3   4
        //   2   3   4   5
        //   3   4   5   6
        //   4   5   6   7

        for (int i = 0; i < 4; i++) begin
            for (int j = 0; j < 4; j++) begin
                if (i < 2)
                    matrix_a[i][j] = i * 4 + j + 1;
                else
                    matrix_a[i][j] = -((i - 2) * 4 + j + 1);

                matrix_b[i][j] = i + j + 1;
            end
        end

        // Reference model:
        // Calculate each expected output using row-by-column
        // matrix multiplication, independently of the hardware.
        for (int i = 0; i < 4; i++) begin
            for (int j = 0; j < 4; j++) begin
                reference_sum = 0;

                for (int k = 0; k < 4; k++) begin
                    reference_sum = reference_sum
                        + matrix_a[i][k] * matrix_b[k][j];
                end
                expected[i][j] = reference_sum;
            end
        end

        if (expected[0][0] !== (30)) $fatal(1, "Reference self-check failed at [0][0]");
        if (expected[0][1] !== (40)) $fatal(1, "Reference self-check failed at [0][1]");
        if (expected[0][2] !== (50)) $fatal(1, "Reference self-check failed at [0][2]");
        if (expected[0][3] !== (60)) $fatal(1, "Reference self-check failed at [0][3]");
        if (expected[1][0] !== (70)) $fatal(1, "Reference self-check failed at [1][0]");
        if (expected[1][1] !== (96)) $fatal(1, "Reference self-check failed at [1][1]");
        if (expected[1][2] !== (122)) $fatal(1, "Reference self-check failed at [1][2]");
        if (expected[1][3] !== (148)) $fatal(1, "Reference self-check failed at [1][3]");
        if (expected[2][0] !== (-30)) $fatal(1, "Reference self-check failed at [2][0]");
        if (expected[2][1] !== (-40)) $fatal(1, "Reference self-check failed at [2][1]");
        if (expected[2][2] !== (-50)) $fatal(1, "Reference self-check failed at [2][2]");
        if (expected[2][3] !== (-60)) $fatal(1, "Reference self-check failed at [2][3]");
        if (expected[3][0] !== (-70)) $fatal(1, "Reference self-check failed at [3][0]");
        if (expected[3][1] !== (-96)) $fatal(1, "Reference self-check failed at [3][1]");
        if (expected[3][2] !== (-122)) $fatal(1, "Reference self-check failed at [3][2]");
        if (expected[3][3] !== (-148)) $fatal(1, "Reference self-check failed at [3][3]");

        // Hold synchronous reset active for two rising edges.
        repeat (2) @(posedge clk);

        @(negedge clk);
        rst_n = 1;

        // Load four operand words into memory.
        //
        // Address k contains column k of A and row k of B.
        // Packing: {B3, B2, B1, B0, A3, A2, A1, A0}.
        for (int k = 0; k < 4; k++) begin
            packed_word = 64'd0;

            for (int lane = 0; lane < 4; lane++) begin
                packed_word[8*lane +: 8] =
                    matrix_a[lane][k];

                packed_word[32 + 8*lane +: 8] =
                    matrix_b[k][lane];
            end

            write_word(k, packed_word);

            $display("Loaded address %0d: %016h",
                     k, packed_word);
        end

        // Start a job requiring four accepted operand words.
        @(negedge clk);
        k_length = 8'd4;
        start = 1;

        @(posedge clk);
        #1;

        if (busy !== 1'b1)
            $fatal(1, "Accelerator did not become busy");

        // End the one-clock start pulse.
        @(negedge clk);
        start = 0;

        // Wait for completion.
        // The timeout catches a controller that never finishes.
        cycles = 0;

        while ((done !== 1'b1) && (cycles < 100)) begin
            @(posedge clk);
            #1;
            cycles = cycles + 1;
        end

        if (done !== 1'b1)
            $fatal(1, "Timeout: accelerator did not finish");

        if (busy !== 1'b0)
            $fatal(1, "Busy remained high at completion");

        // Compare all 16 hardware outputs with the reference.
        for (int i = 0; i < 4; i++) begin
            for (int j = 0; j < 4; j++) begin
                if (result[i][j] !== expected[i][j])
                    $fatal(1,
                        "Result [%0d][%0d]: expected %0d, got %0d",
                        i, j, expected[i][j], result[i][j]);

                checks = checks + 1;
            end

            $display("Result row %0d: %0d %0d %0d %0d",
                     i,
                     result[i][0], result[i][1],
                     result[i][2], result[i][3]);
        end

        // Check that done is a one-clock pulse and that
        // completed results remain unchanged while idle.
        repeat (3) begin
            @(posedge clk);
            #1;

            if (done !== 1'b0)
                $fatal(1, "Done did not return low");

            if (busy !== 1'b0)
                $fatal(1, "Unexpected new job");

            for (int i = 0; i < 4; i++) begin
                for (int j = 0; j < 4; j++) begin
                    if (result[i][j] !== expected[i][j])
                        $fatal(1,
                            "Result changed while idle at [%0d][%0d]",
                            i, j);
                end
            end
        end

        $display(
            "PASS: accel_top accumulation test, %0d result checks",
            checks
        );

        $finish;
    end

    // Independent timeout in case the testbench hangs.
    initial begin
        #20000;
        $fatal(1, "Global simulation timeout");
    end

endmodule

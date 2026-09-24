`timescale 1ns/1ps

module tb_accel_top;

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

    logic [63:0] packed_word;
    integer cycles;
    integer checks = 0;

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

    // A 10 ns clock period.
    always #5 clk = ~clk;

    // Drive inputs on falling edges.
    // The memory stores them on the following rising edge.
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
        // Construct A and the identity matrix B.
        for (int i = 0; i < 4; i++) begin
            for (int j = 0; j < 4; j++) begin
                if (i < 2)
                    matrix_a[i][j] = i * 4 + j + 1;
                else
                    matrix_a[i][j] = -((i - 2) * 4 + j + 1);

                matrix_b[i][j] = (i == j) ? 1 : 0;
            end
        end

        // Keep synchronous reset active for two rising edges.
        repeat (2) @(posedge clk);

        @(negedge clk);
        rst_n = 1;

        // Word k contains column k of A and row k of B.
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

        // Start one K=4 job.
        @(negedge clk);
        k_length = 8'd4;
        start = 1;

        @(posedge clk);
        #1;

        if (busy !== 1'b1)
            $fatal(1, "Accelerator did not become busy");

        @(negedge clk);
        start = 0;

        // Wait for completion, with a timeout.
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

        // A multiplied by identity must equal A.
        for (int i = 0; i < 4; i++) begin
            for (int j = 0; j < 4; j++) begin
                if (result[i][j] !== matrix_a[i][j])
                    $fatal(1,
                        "Result [%0d][%0d]: expected %0d, got %0d",
                        i, j, matrix_a[i][j], result[i][j]);

                checks = checks + 1;
            end

            $display("Result row %0d: %0d %0d %0d %0d",
                     i,
                     result[i][0], result[i][1],
                     result[i][2], result[i][3]);
        end

        // Done should last one cycle.
        // Results should remain available while idle.
        repeat (3) begin
            @(posedge clk);
            #1;

            if (done !== 1'b0)
                $fatal(1, "Done did not return low");

            if (busy !== 1'b0)
                $fatal(1, "Unexpected new job");

            for (int i = 0; i < 4; i++)
                for (int j = 0; j < 4; j++)
                    if (result[i][j] !== matrix_a[i][j])
                        $fatal(1, "Result changed while idle");
        end

        $display("PASS: accel_top identity test, %0d result checks",
                 checks);
        $finish;
    end

    // Stop if the testbench unexpectedly hangs.
    initial begin
        #20000;
        $fatal(1, "Global simulation timeout");
    end

endmodule

`timescale 1ns/1ps

module tb_mac_array_4x4;

    logic clk = 0;
    logic rst_n = 0;
    logic clear = 0;
    logic enable = 0;

    logic signed [7:0] a [0:3];
    logic signed [7:0] b [0:3];
    wire signed [31:0] acc [0:3][0:3];

    integer matrix_a [0:3][0:3];
    integer matrix_b [0:3][0:3];
    integer expected [0:3][0:3];
    integer tests = 0;

    mac_array_4x4 dut (.*);

    always #5 clk = ~clk;

    task automatic run_matrix_test;
        integer sum_ref;

        // Independently calculate the expected matrix product.
        for (int i = 0; i < 4; i++) begin
            for (int j = 0; j < 4; j++) begin
                sum_ref = 0;

                for (int k = 0; k < 4; k++) begin
                    sum_ref = sum_ref
                            + matrix_a[i][k] * matrix_b[k][j];
                end

                expected[i][j] = sum_ref;
            end
        end

        $display("DEBUG test=%0d A00=%0d B00=%0d expected00=%0d",
                 tests + 1, matrix_a[0][0],
                 matrix_b[0][0], expected[0][0]);

        // Clear the previous result.
        @(negedge clk);
        clear = 1;
        enable = 0;

        @(posedge clk);
        #1;

        for (int i = 0; i < 4; i++) begin
            for (int j = 0; j < 4; j++) begin
                if (acc[i][j] !== 32'sd0)
                    $fatal(1, "Clear failed at [%0d][%0d]", i, j);
            end
        end

        // Four accumulation cycles for a 4x4 matrix product.
        for (int k = 0; k < 4; k++) begin
            @(negedge clk);
            clear = 0;
            enable = 1;

            for (int i = 0; i < 4; i++)
                a[i] = matrix_a[i][k];

            for (int j = 0; j < 4; j++)
                b[j] = matrix_b[k][j];

            @(posedge clk);
            #1;
        end

        // Change inputs while disabled; results must hold.
        @(negedge clk);
        enable = 0;

        for (int i = 0; i < 4; i++) begin
            a[i] = 127;
            b[i] = -128;
        end

        repeat (2) @(posedge clk);
        #1;

        for (int i = 0; i < 4; i++) begin
            for (int j = 0; j < 4; j++) begin
                if (acc[i][j] !== expected[i][j])
                    $fatal(1,
                        "Test %0d [%0d][%0d]: expected %0d, got %0d",
                        tests + 1, i, j,
                        expected[i][j], acc[i][j]);
            end
        end

        tests++;
    endtask

    initial begin
        for (int i = 0; i < 4; i++) begin
            a[i] = 0;
            b[i] = 0;
        end

        repeat (2) @(posedge clk);
        @(negedge clk);
        rst_n = 1;

        // Test 1: A multiplied by the identity matrix.
        for (int i = 0; i < 4; i++) begin
            for (int j = 0; j < 4; j++) begin
                matrix_a[i][j] = i * 4 + j - 8;
                matrix_b[i][j] = (i == j) ? 1 : 0;
            end
        end
        run_matrix_test();

        // Test 2: A multiplied by zero.
        for (int i = 0; i < 4; i++)
            for (int j = 0; j < 4; j++)
                matrix_b[i][j] = 0;

        run_matrix_test();

        // Test 3: signed boundary values.
        for (int i = 0; i < 4; i++) begin
            for (int j = 0; j < 4; j++) begin
                matrix_a[i][j] = (j % 2 == 0) ? -128 : 127;
                matrix_b[i][j] = (i % 2 == 0) ? 127 : -128;
            end
        end
        run_matrix_test();

        // Tests 4 through 103: random matrices.
        repeat (100) begin
            for (int i = 0; i < 4; i++) begin
                for (int j = 0; j < 4; j++) begin
                    matrix_a[i][j] =
                        int'($urandom_range(0, 255)) - 128;
                    matrix_b[i][j] =
                        int'($urandom_range(0, 255)) - 128;
                end
            end
            run_matrix_test();
        end

        $display("PASS: %0d matrix tests, %0d output checks",
                 tests, tests * 16);
        $finish;
    end

endmodule

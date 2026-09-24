module tb_mac_int8;
    timeunit 1ns;
    timeprecision 1ps;

    logic clk = 0;
    logic rst_n = 0;
    logic clear = 0;
    logic enable = 0;
    logic signed [7:0] a = 0, b = 0;
    logic signed [31:0] acc;
    logic signed [31:0] expected = 0;
    int checks = 0;

    mac_int8 dut (.*);
    always #5 clk = ~clk;

    task automatic step(
        input bit reset_n,
        input bit clr,
        input bit en,
        input integer av,
        input integer bv
    );
        @(negedge clk);
        rst_n = reset_n;
        clear = clr;
        enable = en;
        a = av;
        b = bv;

        if (!reset_n || clr)
            expected = 0;
        else if (en)
            expected = expected + (av * bv);

        @(posedge clk);
        #1;
        checks++;
        if (acc !== expected)
            $fatal(1, "Check %0d: expected %0d, got %0d",
                   checks, expected, acc);
    endtask

    initial begin
        step(0, 0, 0,    0,    0);  // Reset
        step(1, 0, 1,    3,    4);  // Positive product
        step(1, 0, 1,   -5,    6);  // Negative product
        step(1, 0, 1,   -7,   -8);  // Both negative
        step(1, 0, 1, -128, -128);  // Signed extremes
        step(1, 0, 1, -128,  127);
        step(1, 0, 0,  127,  127);  // Disabled: hold
        step(1, 1, 1,   10,   10);  // Clear beats enable
        step(1, 0, 1,    9,   -3);
        step(0, 0, 1,  127,  127);  // Reset beats enable

        repeat (1000)
            step(1, 0, 1,
                 int'($urandom_range(0, 255)) - 128,
                 int'($urandom_range(0, 255)) - 128);

        step(1, 1, 0, 0, 0);

        // Cross the positive 32-bit accumulator limit.
        repeat (131073)
            step(1, 0, 1, -128, -128);

        $display("PASS: %0d MAC checks completed", checks);
        $finish;
    end
endmodule

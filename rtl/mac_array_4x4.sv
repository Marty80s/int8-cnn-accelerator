`timescale 1ns/1ps

module mac_array_4x4 (
    input  logic               clk,
    input  logic               rst_n,
    input  logic               clear,
    input  logic               enable,
    input  logic signed [7:0]   a [0:3],
    input  logic signed [7:0]   b [0:3],
    output wire signed [31:0]   acc [0:3][0:3]
);

    genvar row, col;

    generate
        for (row = 0; row < 4; row++) begin : rows
            for (col = 0; col < 4; col++) begin : cols
                mac_int8 u_mac (
                    .clk    (clk),
                    .rst_n  (rst_n),
                    .clear  (clear),
                    .enable (enable),
                    .a      (a[row]),
                    .b      (b[col]),
                    .acc    (acc[row][col])
                );
            end
        end
    endgenerate

endmodule


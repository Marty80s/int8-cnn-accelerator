`timescale 1ns/1ps
module mac_int8 (
    input  logic               clk,
    input  logic               rst_n,
    input  logic               clear,
    input  logic               enable,
    input  logic signed [7:0]   a,
    input  logic signed [7:0]   b,
    output logic signed [31:0]  acc
);

    logic signed [15:0] product;

    assign product = a * b;

    always_ff @(posedge clk) begin
        if (!rst_n)
            acc <= 32'sd0;
        else if (clear)
            acc <= 32'sd0;
        else if (enable)
            acc <= acc + {{16{product[15]}}, product};
    end

endmodule

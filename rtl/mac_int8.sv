`timescale 1ns/1ps

// Pipeline option for the PPA study (experiment E4).
//   PIPE = 0 : multiply and accumulate in one cycle (original design)
//   PIPE = 1 : product registered first, accumulated one cycle later.
//              Splits the multiplier from the 32-bit adder on the critical
//              path, at the cost of 17 extra flops per MAC and 1 cycle latency.
// Select for a whole build with +define+MAC_PIPE=1 (Xcelium) or
// read_hdl -define MAC_PIPE=1 (Genus). Default is the original design.
`ifndef MAC_PIPE
`define MAC_PIPE 0
`endif

module mac_int8 #(
    parameter int PIPE = `MAC_PIPE
) (
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

    generate
        if (PIPE == 0) begin : g_single_cycle

            always_ff @(posedge clk) begin
                if (!rst_n)
                    acc <= 32'sd0;
                else if (clear)
                    acc <= 32'sd0;
                else if (enable)
                    acc <= acc + {{16{product[15]}}, product};
            end

        end else begin : g_pipelined

            logic signed [15:0] product_q;
            logic               valid_q;

            // Stage 1: register the product. No reset needed on the data;
            // valid_q says whether it holds a real product.
            always_ff @(posedge clk) begin
                if (enable)
                    product_q <= product;
            end

            // Stage 2: accumulate. Clear drops any product still in flight.
            always_ff @(posedge clk) begin
                if (!rst_n) begin
                    acc     <= 32'sd0;
                    valid_q <= 1'b0;
                end else if (clear) begin
                    acc     <= 32'sd0;
                    valid_q <= 1'b0;
                end else begin
                    valid_q <= enable;
                    if (valid_q)
                        acc <= acc + {{16{product_q[15]}}, product_q};
                end
            end

        end
    endgenerate

endmodule

`timescale 1ns/1ps

module operand_memory (
    input  logic        clk,
    input  logic        rst_n,

    // Write interface
    input  logic        wr_en,
    input  logic [7:0]  wr_addr,
    input  logic [63:0] wr_data,

    // Read interface
    input  logic        rd_en,
    input  logic [7:0]  rd_addr,
    output logic [63:0] rd_data,
    output logic        rd_valid
);

    // 256 locations, each storing 64 bits.
    logic [63:0] mem [0:255];

    // Writes are disabled during reset.
    always_ff @(posedge clk) begin
        if (rst_n && wr_en)
            mem[wr_addr] <= wr_data;
    end

    // Synchronous read: output updates after a rising edge.
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            rd_data  <= 64'd0;
            rd_valid <= 1'b0;
        end else begin
            rd_valid <= rd_en;

            if (rd_en)
                rd_data <= mem[rd_addr];
        end
    end

endmodule

`timescale 1ns/1ps

module accel_top (
    input  logic clk,
    input  logic rst_n,

    // Load operand memory before starting a job.
    input  logic        wr_en,
    input  logic [7:0]  wr_addr,
    input  logic [63:0] wr_data,

    // Pulse start for one clock cycle while idle.
    input  logic       start,
    input  logic [7:0] k_length,

    output wire busy,
    output wire done,
    output wire signed [31:0] result [0:3][0:3]
);

    wire reader_busy;
    wire reader_done;
    wire compute_busy;
    wire compute_done;

    wire job_start;
    wire memory_write;

    // Memory-to-reader connections.
    wire        mem_rd_en;
    wire [7:0]  mem_rd_addr;
    wire [63:0] mem_rd_data;
    wire        mem_rd_valid;

    // Reader-to-compute connections.
    wire [63:0] operand_word;
    wire        operand_valid;
    wire        operand_ready;

    wire signed [7:0] a [0:3];
    wire signed [7:0] b [0:3];

    // A job is active if either controller is busy.
    assign busy = reader_busy || compute_busy;
    assign done = compute_done;

    // Start both controllers together, only while idle.
    // K=0 requests are ignored.
    assign job_start =
        rst_n && start && !busy && (k_length != 8'd0);

    // Protect operands from modification during a job.
    // If a write and a valid start coincide, start wins.
    assign memory_write =
        rst_n && wr_en && !busy && !job_start;

    operand_memory u_memory (
        .clk      (clk),
        .rst_n    (rst_n),

        .wr_en    (memory_write),
        .wr_addr  (wr_addr),
        .wr_data  (wr_data),

        .rd_en    (mem_rd_en),
        .rd_addr  (mem_rd_addr),
        .rd_data  (mem_rd_data),
        .rd_valid (mem_rd_valid)
    );

    operand_reader u_reader (
        .clk          (clk),
        .rst_n        (rst_n),

        .start        (job_start),
        .k_length     (k_length),
        .busy         (reader_busy),
        .done         (reader_done),

        .mem_rd_en    (mem_rd_en),
        .mem_rd_addr  (mem_rd_addr),
        .mem_rd_data  (mem_rd_data),
        .mem_rd_valid (mem_rd_valid),

        .out_data     (operand_word),
        .out_valid    (operand_valid),
        .out_ready    (operand_ready)
    );

    // Word layout, from most significant to least significant:
    // {B3, B2, B1, B0, A3, A2, A1, A0}
    generate
        for (genvar lane = 0; lane < 4; lane++) begin : unpack_operands
            assign a[lane] = operand_word[8*lane +: 8];
            assign b[lane] = operand_word[32 + 8*lane +: 8];
        end
    endgenerate

    matmul_4x4_k u_compute (
        .clk      (clk),
        .rst_n    (rst_n),

        .start    (job_start),
        .k_length (k_length),

        .in_valid (operand_valid),
        .in_ready (operand_ready),

        .a        (a),
        .b        (b),

        .busy     (compute_busy),
        .done     (compute_done),
        .result   (result)
    );

endmodule

`timescale 1ns/1ps

module operand_reader (
    input  logic        clk,
    input  logic        rst_n,

    // Job configuration: read addresses 0 through K-1.
    input  logic        start,
    input  logic [7:0]  k_length,
    output logic        busy,
    output logic        done,

    // Connection to operand_memory.
    output logic        mem_rd_en,
    output logic [7:0]  mem_rd_addr,
    input  logic [63:0] mem_rd_data,
    input  logic        mem_rd_valid,

    // Connection to the downstream consumer.
    output logic [63:0] out_data,
    output logic        out_valid,
    input  logic        out_ready
);

    typedef enum logic [1:0] {
        IDLE,
        REQUEST,
        WAIT_DATA,
        SEND
    } state_t;

    state_t state;

    logic [7:0] address;
    logic [7:0] remaining;

    assign busy        = rst_n && (state != IDLE);
    assign mem_rd_en   = rst_n && (state == REQUEST);
    assign mem_rd_addr = address;
    assign out_valid   = rst_n && (state == SEND);

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            state     <= IDLE;
            address   <= 8'd0;
            remaining <= 8'd0;
            out_data  <= 64'd0;
            done      <= 1'b0;
        end else begin
            done <= 1'b0;

            case (state)
                IDLE: begin
                    if (start && (k_length != 8'd0)) begin
                        address   <= 8'd0;
                        remaining <= k_length;
                        state     <= REQUEST;
                    end
                end

                REQUEST: begin
                    // Memory samples mem_rd_en and address
                    // on this edge.
                    state <= WAIT_DATA;
                end

                WAIT_DATA: begin
                    if (mem_rd_valid) begin
                        out_data <= mem_rd_data;
                        state    <= SEND;
                    end
                end

                SEND: begin
                    // out_valid is high in this state.
                    // Hold the word until it is accepted.
                    if (out_ready) begin
                        if (remaining == 8'd1) begin
                            remaining <= 8'd0;
                            done      <= 1'b1;
                            state     <= IDLE;
                        end else begin
                            remaining <= remaining - 8'd1;
                            address   <= address + 8'd1;
                            state     <= REQUEST;
                        end
                    end
                end

                default: begin
                    state     <= IDLE;
                    address   <= 8'd0;
                    remaining <= 8'd0;
                end
            endcase
        end
    end

endmodule

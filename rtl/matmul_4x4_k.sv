`timescale 1ns/1ps

module matmul_4x4_k (
    input  logic              clk,
    input  logic              rst_n,
    input  logic              start,
    input  logic [7:0]        k_length,

    input  logic              in_valid,
    output logic              in_ready,

    input  logic signed [7:0]  a [0:3],
    input  logic signed [7:0]  b [0:3],

    output logic              busy,
    output logic              done,
    output wire signed [31:0] result [0:3][0:3]
);

    typedef enum logic [1:0] {
        IDLE,
        CLEAR,
        COMPUTE
    } state_t;

    state_t state;

    logic [7:0] remaining;
    logic       array_clear;
    logic       array_enable;

    assign busy         = rst_n && (state != IDLE);
    assign in_ready     = rst_n && (state == COMPUTE);
    assign array_clear  = (state == CLEAR);
    assign array_enable = in_valid && in_ready;

    mac_array_4x4 u_array (
        .clk    (clk),
        .rst_n  (rst_n),
        .clear  (array_clear),
        .enable (array_enable),
        .a      (a),
        .b      (b),
        .acc    (result)
    );

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            state     <= IDLE;
            remaining <= 8'd0;
            done      <= 1'b0;
        end else begin
            // Completion is a one-clock pulse.
            done <= 1'b0;

            case (state)
                IDLE: begin
                    // Zero-length requests are ignored.
                    if (start && (k_length != 8'd0)) begin
                        remaining <= k_length;
                        state     <= CLEAR;
                    end
                end

                CLEAR: begin
                    // The array clears on this rising edge.
                    state <= COMPUTE;
                end

                COMPUTE: begin
                    // Pauses do not change the count or results.
                    if (array_enable) begin
                        if (remaining == 8'd1) begin
                            // The array also accumulates the final
                            // product on this same rising edge.
                            remaining <= 8'd0;
                            state     <= IDLE;
                            done      <= 1'b1;
                        end else begin
                            remaining <= remaining - 8'd1;
                        end
                    end
                end

                default: begin
                    state     <= IDLE;
                    remaining <= 8'd0;
                end
            endcase
        end
    end

endmodule

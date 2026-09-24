`timescale 1ns/1ps

module matmul_4x4 (
    input  logic              clk,
    input  logic              rst_n,
    input  logic              start,

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
    logic [1:0] step_count;
    logic array_clear;
    logic array_enable;

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
            state      <= IDLE;
            step_count <= 0;
            done       <= 0;
        end else begin
            // Default: done is a one-clock pulse.
            done <= 0;

            case (state)
                IDLE: begin
                    if (start) begin
                        state      <= CLEAR;
                        step_count <= 0;
                    end
                end

                CLEAR: begin
                    // The array clears on this clock edge.
                    state <= COMPUTE;
                end

                COMPUTE: begin
                    if (array_enable) begin
                        if (step_count == 2'd3) begin
                            // Fourth accepted operand set completes C.
                            state <= IDLE;
                            done  <= 1;
                        end else begin
                            step_count <= step_count + 1'b1;
                        end
                    end
                end

                default: begin
                    state      <= IDLE;
                    step_count <= 0;
                end
            endcase
        end
    end

endmodule

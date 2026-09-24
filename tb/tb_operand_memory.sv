`timescale 1ns/1ps

module tb_operand_memory;

    logic clk = 0;
    logic rst_n = 0;

    logic wr_en = 0;
    logic [7:0] wr_addr = 0;
    logic [63:0] wr_data = 0;

    logic rd_en = 0;
    logic [7:0] rd_addr = 0;
    wire [63:0] rd_data;
    wire rd_valid;

    // Independent model of the stored contents.
    logic [63:0] reference_mem [0:255];
    logic [63:0] expected_data = 0;
    logic expected_valid = 0;

    integer checks = 0;

    operand_memory dut (.*);

    always #5 clk = ~clk;

    initial begin
        #100000;
        $fatal(1, "Simulation timeout");
    end

    // Perform one clock cycle and check the read response.
    task automatic step(
        input bit reset_n,
        input bit write_enable,
        input logic [7:0] write_address,
        input logic [63:0] write_data,
        input bit read_enable,
        input logic [7:0] read_address
    );
        @(negedge clk);
        rst_n   = reset_n;
        wr_en   = write_enable;
        wr_addr = write_address;
        wr_data = write_data;
        rd_en   = read_enable;
        rd_addr = read_address;

        // Outputs must not change before the rising edge.
        #1;
        if (checks > 0) begin
            if (rd_data !== expected_data ||
                rd_valid !== expected_valid)
                $fatal(1, "Read output changed before rising edge");
        end

        @(posedge clk);

        if (!reset_n) begin
            expected_data  = 64'd0;
            expected_valid = 1'b0;
        end else begin
            expected_valid = read_enable;

            // Read before updating the reference memory:
            // simultaneous same-address access returns old data.
            if (read_enable)
                expected_data = reference_mem[read_address];

            if (write_enable)
                reference_mem[write_address] = write_data;
        end

        // Allow DUT nonblocking assignments to complete.
        #1;
        checks++;

        if (rd_valid !== expected_valid)
            $fatal(1,
                "Check %0d: expected valid=%b, got %b",
                checks, expected_valid, rd_valid);

        if (rd_data !== expected_data)
            $fatal(1,
                "Check %0d: expected data=%h, got %h",
                checks, expected_data, rd_data);
    endtask

    initial begin
        // 1. Establish reset state.
        step(0, 0, 0, 0, 0, 0);

        // 2. Write a distinct 64-bit pattern to every address.
        for (int address = 0; address < 256; address++) begin
            step(1, 1, address,
                 {32'hA5A50000 + address,
                  32'h5A5AFFFF - address},
                 0, 0);
        end

        // 3. Read every address, one request each cycle.
        for (int address = 0; address < 256; address++)
            step(1, 0, 0, 0, 1, address);

        // 4. Disabled reads must hold data and deassert valid.
        step(1, 0, 0, 0, 0, 17);
        step(1, 0, 0, 0, 0, 99);

        // 5. Overwrite a location and read the new value.
        step(1, 1, 42, 64'h0123456789ABCDEF, 0, 0);
        step(1, 0, 0, 0, 1, 42);

        // 6. Read and write different addresses simultaneously.
        step(1, 1, 9, 64'hFEDCBA9876543210, 1, 42);
        step(1, 0, 0, 0, 1, 9);

        // 7. Same-address collision returns the OLD contents.
        step(1, 1, 42, 64'hDEADBEEFCAFE1234, 1, 42);

        // The following read must return the NEW contents.
        step(1, 0, 0, 0, 1, 42);

        // 8. Reset must suppress both a write and a read.
        step(0, 1, 42, 64'h0000000000000000, 1, 42);

        // Stored contents must survive reset.
        step(1, 0, 0, 0, 1, 42);
        step(1, 0, 0, 0, 1, 0);
        step(1, 0, 0, 0, 1, 255);

        // Finish with the read interface idle.
        step(1, 0, 0, 0, 0, 0);

        $display("PASS: operand memory, %0d cycle checks", checks);
        $finish;
    end

endmodule

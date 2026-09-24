`timescale 1ns/1ps

module tb_operand_reader;

    logic clk = 0;
    logic rst_n = 0;
    logic start = 0;
    logic [7:0] k_length = 0;
    wire busy;
    wire done;

    logic wr_en = 0;
    logic [7:0] wr_addr = 0;
    logic [63:0] wr_data = 0;

    wire mem_rd_en;
    wire [7:0] mem_rd_addr;
    wire [63:0] mem_rd_data;
    wire mem_rd_valid;

    wire [63:0] out_data;
    wire out_valid;
    logic out_ready = 0;

    integer jobs = 0;
    integer deliveries = 0;

    operand_memory memory (
        .clk      (clk),
        .rst_n    (rst_n),
        .wr_en    (wr_en),
        .wr_addr  (wr_addr),
        .wr_data  (wr_data),
        .rd_en    (mem_rd_en),
        .rd_addr  (mem_rd_addr),
        .rd_data  (mem_rd_data),
        .rd_valid (mem_rd_valid)
    );

    operand_reader dut (
        .clk          (clk),
        .rst_n        (rst_n),
        .start        (start),
        .k_length     (k_length),
        .busy         (busy),
        .done         (done),
        .mem_rd_en    (mem_rd_en),
        .mem_rd_addr  (mem_rd_addr),
        .mem_rd_data  (mem_rd_data),
        .mem_rd_valid (mem_rd_valid),
        .out_data     (out_data),
        .out_valid    (out_valid),
        .out_ready    (out_ready)
    );

    always #5 clk = ~clk;

    initial begin
        #100000;
        $fatal(1, "Simulation timeout");
    end

    // Distinct data for every memory address.
    function automatic logic [63:0] pattern(input int address);
        pattern = {
            32'hA5A50000 + address,
            32'h5A5AFFFF - address
        };
    endfunction

    task automatic check_idle;
        if (busy !== 1'b0 ||
            done !== 1'b0 ||
            mem_rd_en !== 1'b0 ||
            out_valid !== 1'b0)
            $fatal(1, "Expected idle control outputs");
    endtask

    task automatic begin_job(input int length);
        @(negedge clk);
        start = 1;
        k_length = length;
        out_ready = 0;

        @(posedge clk);
        #1;
        if (busy !== 1'b1 ||
            done !== 1'b0 ||
            mem_rd_en !== 1'b1 ||
            mem_rd_addr !== 8'd0 ||
            out_valid !== 1'b0)
            $fatal(1, "Incorrect job startup");

        @(negedge clk);
        start = 0;
    endtask

    task automatic run_job(
        input int length,
        input bit insert_stalls
    );
        integer received;
        integer requested;
        integer cycles;
        integer blocked_cycles;
        bit was_blocked;
        bit accepted;
        logic [63:0] held_word;

        received = 0;
        requested = 0;
        cycles = 0;
        blocked_cycles = 0;
        was_blocked = 0;
        held_word = 0;

        begin_job(length);

        // begin_job returns on a falling edge.
        while (received < length) begin
            // Stall for two clocks whenever a new word appears.
            if (insert_stalls && out_valid &&
                blocked_cycles < 2) begin
                out_ready = 0;
                blocked_cycles++;
            end else begin
                out_ready = 1;
            end

            // Busy requests with a different nonzero K
            // must not restart or resize the active job.
            start = 1;
            k_length = (length == 7) ? 8'd9 : 8'd7;

            @(posedge clk);

            // Sample transfers BEFORE sequential updates.
            if (mem_rd_en) begin
                if (requested >= length)
                    $fatal(1, "Too many memory requests");

                if (mem_rd_addr !== requested[7:0])
                    $fatal(1,
                        "Expected address %0d, got %0d",
                        requested, mem_rd_addr);

                requested++;
            end

            if (was_blocked) begin
                if (out_valid !== 1'b1 ||
                    out_data !== held_word)
                    $fatal(1, "Word changed while waiting for ready");
            end

            accepted = out_valid && out_ready;

            if (out_valid) begin
                if (out_data !== pattern(received))
                    $fatal(1,
                        "Word %0d: expected %h, got %h",
                        received, pattern(received), out_data);
            end

            was_blocked = out_valid && !out_ready;
            held_word = out_data;

            if (accepted) begin
                received++;
                deliveries++;
                blocked_cycles = 0;
            end

            #1;
            cycles++;

            if (received == length) begin
                if (done !== 1'b1 ||
                    busy !== 1'b0 ||
                    out_valid !== 1'b0 ||
                    mem_rd_en !== 1'b0)
                    $fatal(1, "Incorrect final delivery timing");
            end else begin
                if (done !== 1'b0 || busy !== 1'b1)
                    $fatal(1, "Reader ended before K deliveries");
            end

            if (cycles > 10 * length + 20)
                $fatal(1, "Job took too many cycles");

            @(negedge clk);
        end

        start = 0;
        out_ready = 1;

        if (requested != length)
            $fatal(1, "Memory request count does not equal K");

        // No extra words; done must return low.
        repeat (3) begin
            @(posedge clk);
            #1;
            check_idle();
        end

        jobs++;
        $display("PASS reader job %0d: K=%0d stalls=%0d",
                 jobs, length, insert_stalls);
    endtask

    task automatic zero_request;
        @(negedge clk);
        start = 1;
        k_length = 0;
        out_ready = 1;

        repeat (3) begin
            @(posedge clk);
            #1;
            check_idle();
        end

        @(negedge clk);
        start = 0;
    endtask

    initial begin
        repeat (2) @(posedge clk);
        #1;
        check_idle();

        @(negedge clk);
        rst_n = 1;

        // Load all memory locations before starting the reader.
        for (int address = 0; address < 256; address++) begin
            @(negedge clk);
            wr_en = 1;
            wr_addr = address;
            wr_data = pattern(address);

            @(posedge clk);
            #1;
        end

        @(negedge clk);
        wr_en = 0;

        zero_request();

        run_job(1,   0);
        run_job(3,   1);
        run_job(4,   0);
        run_job(255, 1);

        zero_request();

        // Reset after a memory request, before delivery.
        begin_job(8);

        @(posedge clk);
        #1;

        @(negedge clk);
        rst_n = 0;
        start = 0;
        out_ready = 0;

        @(posedge clk);
        #1;
        check_idle();

        @(negedge clk);
        rst_n = 1;

        repeat (3) begin
            @(posedge clk);
            #1;
            check_idle();
        end

        // Memory contents survive reset; no reload needed.
        run_job(4, 1);

        $display(
            "PASS: operand reader, %0d completed jobs, %0d delivered words",
            jobs, deliveries);
        $finish;
    end

endmodule

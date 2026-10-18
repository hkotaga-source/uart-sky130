`timescale 1ns/1ps

// Self-checking testbench for uart_top.
//
// Tests:
//   1. Loopback (TX -> RX) of special bytes 00, FF, 55, AA, 41, 42
//   2. Loopback of 200 random bytes, sent back to back
//   3. Steps 1 and 2 repeated at three baud_div settings
//   4. busy goes high when a byte starts and low when it ends
//   5. A short noise glitch on rx is ignored (no false byte)
//   6. A frame with a bad stop bit is rejected (no valid)
//   7. The receiver recovers and receives a good byte afterwards
//
// Every wait has a timeout, so a bug makes the test FAIL instead of hanging.
// Prints "ALL TESTS PASSED" at the end, or the number of failures.

module tb_uart;

    reg         clk;
    reg         rst;
    reg         start;
    reg  [7:0]  data_in;
    reg  [15:0] baud_div;
    wire        tx;
    wire        busy;
    wire [7:0]  data_out;
    wire        valid;

    // rx is either looped back from tx, or driven by the testbench
    reg         loopback;
    reg         rx_drv;
    wire        rx = loopback ? tx : rx_drv;

    uart_top dut (
        .clk      (clk),
        .rst      (rst),
        .start    (start),
        .data_in  (data_in),
        .baud_div (baud_div),
        .rx       (rx),
        .tx       (tx),
        .busy     (busy),
        .data_out (data_out),
        .valid    (valid)
    );

    // 10 ns clock = 100 MHz
    initial clk = 0;
    always #5 clk = ~clk;

    integer errors = 0;
    integer checks = 0;
    integer i, b;

    // Cycles in one UART bit (counter runs baud_div down to 0)
    function integer bit_cycles;
        input [15:0] div;
        bit_cycles = div + 1;
    endfunction

    // Wait for valid, up to max_cycles. Returns 1 if valid was seen.
    task wait_valid;
        input  integer max_cycles;
        output reg     seen;
        integer n;
        begin
            seen = 0;
            for (n = 0; n < max_cycles && !seen; n = n + 1) begin
                @(posedge clk);
                if (valid) seen = 1;
            end
        end
    endtask

    // Wait for busy to go low, up to max_cycles
    task wait_not_busy;
        input integer max_cycles;
        integer n;
        begin
            for (n = 0; n < max_cycles && busy; n = n + 1) @(posedge clk);
            if (busy) begin
                $display("FAIL: busy stuck high");
                errors = errors + 1;
            end
        end
    endtask

    // Send one byte through TX (loopback) and check RX gets it
    task send_and_check;
        input [7:0] value;
        reg seen;
        begin
            wait_not_busy(20 * bit_cycles(baud_div));
            @(negedge clk);
            data_in = value;
            start   = 1;
            @(negedge clk);
            start   = 0;
            checks  = checks + 1;
            if (!busy) begin
                $display("FAIL: busy did not go high after start (byte 0x%02X)", value);
                errors = errors + 1;
            end
            wait_valid(20 * bit_cycles(baud_div), seen);
            if (!seen) begin
                $display("FAIL: timeout, no valid for byte 0x%02X (baud_div=%0d)", value, baud_div);
                errors = errors + 1;
            end else if (data_out !== value) begin
                $display("FAIL: sent 0x%02X, received 0x%02X (baud_div=%0d)", value, data_out, baud_div);
                errors = errors + 1;
            end
        end
    endtask

    // Drive one frame directly on rx (loopback off), with a chosen stop bit
    task drive_rx_frame;
        input [7:0] value;
        input       stop_bit;
        integer k;
        begin
            rx_drv = 0;                                   // start bit
            repeat (bit_cycles(baud_div)) @(negedge clk);
            for (k = 0; k < 8; k = k + 1) begin           // data, LSB first
                rx_drv = value[k];
                repeat (bit_cycles(baud_div)) @(negedge clk);
            end
            rx_drv = stop_bit;                            // stop bit
            repeat (bit_cycles(baud_div)) @(negedge clk);
            rx_drv = 1;                                   // back to idle
        end
    endtask

    // Watch for any valid pulse while a block of stimulus runs
    reg valid_seen_flag;
    always @(posedge clk) if (valid) valid_seen_flag <= 1;

    reg [15:0] divs [0:2];
    reg        seen;

    initial begin
        $dumpfile("uart.vcd");
        $dumpvars(0, tb_uart);

        divs[0] = 16'd3;     // very fast, odd
        divs[1] = 16'd10;    // fast, even
        divs[2] = 16'd103;   // slower, closer to a real baud setting

        rst      = 1;
        start    = 0;
        data_in  = 0;
        loopback = 1;
        rx_drv   = 1;
        baud_div = divs[1];
        valid_seen_flag = 0;
        repeat (3) @(negedge clk);
        rst = 0;
        repeat (3) @(negedge clk);

        // ---- Loopback tests at three speeds ----
        for (b = 0; b < 3; b = b + 1) begin
            baud_div = divs[b];
            $display("Loopback test, baud_div = %0d", baud_div);
            send_and_check(8'h00);
            send_and_check(8'hFF);
            send_and_check(8'h55);
            send_and_check(8'hAA);
            send_and_check(8'h41);
            send_and_check(8'h42);
            for (i = 0; i < 200; i = i + 1)
                send_and_check($random);
        end

        // ---- Direct rx tests (loopback off) ----
        wait_not_busy(20 * bit_cycles(baud_div));
        baud_div = 16'd10;
        loopback = 0;
        rx_drv   = 1;
        repeat (5 * bit_cycles(baud_div)) @(negedge clk);

        // Glitch: rx low for 2 cycles, much shorter than half a bit
        $display("Glitch test");
        checks = checks + 1;
        valid_seen_flag = 0;
        rx_drv = 0;
        repeat (2) @(negedge clk);
        rx_drv = 1;
        repeat (15 * bit_cycles(baud_div)) @(negedge clk);
        if (valid_seen_flag) begin
            $display("FAIL: glitch on rx produced a false byte");
            errors = errors + 1;
        end

        // Bad stop bit: frame must be rejected
        $display("Bad stop bit test");
        checks = checks + 1;
        valid_seen_flag = 0;
        drive_rx_frame(8'hC3, 1'b0);
        repeat (5 * bit_cycles(baud_div)) @(negedge clk);
        if (valid_seen_flag) begin
            $display("FAIL: frame with bad stop bit was accepted");
            errors = errors + 1;
        end

        // Recovery: a good frame afterwards must be received
        $display("Recovery test");
        checks = checks + 1;
        fork
            drive_rx_frame(8'h3C, 1'b1);
            wait_valid(20 * bit_cycles(baud_div), seen);
        join
        if (!seen) begin
            $display("FAIL: receiver did not recover after bad frame");
            errors = errors + 1;
        end else if (data_out !== 8'h3C) begin
            $display("FAIL: after recovery expected 0x3C, got 0x%02X", data_out);
            errors = errors + 1;
        end

        // ---- Summary ----
        $display("--------------------------------------");
        if (errors == 0)
            $display("ALL TESTS PASSED (%0d checks)", checks);
        else
            $display("%0d FAILURES out of %0d checks", errors, checks);
        $display("--------------------------------------");
        $finish;
    end

    // Global safety timeout
    initial begin
        #50_000_000;
        $display("FAIL: global timeout, simulation hung");
        $finish;
    end

endmodule

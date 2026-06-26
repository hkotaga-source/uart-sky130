`timescale 1ns/1ps

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

    // Connect TX directly to RX (loopback)
    uart_top dut (
        .clk      (clk),
        .rst      (rst),
        .start    (start),
        .data_in  (data_in),
        .baud_div (baud_div),
        .rx       (tx),
        .tx       (tx),
        .busy     (busy),
        .data_out (data_out),
        .valid    (valid)
    );

    // 10ns clock = 100MHz
    initial clk = 0;
    always #5 clk = ~clk;

    // Monitor
    initial begin
        $dumpfile("uart.vcd");
        $dumpvars(0, tb_uart);

        // Reset
        rst      = 1;
        start    = 0;
        data_in  = 0;
        baud_div = 16'd10; // fast for simulation
        #20;
        rst = 0;
        #20;

        // Send 'A' = 0x41
        data_in = 8'h41;
        start   = 1;
        #10;
        start   = 0;

        // Wait for transmission
        wait(valid == 1);
        #10;
        $display("Sent: 0x41  Received: 0x%02X  Match: %s",
                  data_out,
                  (data_out == 8'h41) ? "PASS" : "FAIL");

        // Send 'B' = 0x42
        #100;
        data_in = 8'h42;
        start   = 1;
        #10;
        start   = 0;

        wait(valid == 1);
        #10;
        $display("Sent: 0x42  Received: 0x%02X  Match: %s",
                  data_out,
                  (data_out == 8'h42) ? "PASS" : "FAIL");

        #100;
        $finish;
    end

endmodule

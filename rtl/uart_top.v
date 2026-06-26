module uart_top (
    input  wire clk,
    input  wire rst,
    input  wire start,
    input  wire [7:0] data_in,
    input  wire [15:0] baud_div,
    input  wire rx,
    output wire tx,
    output wire busy,
    output wire [7:0] data_out,
    output wire valid
);

    uart_tx tx_inst (
        .clk      (clk),
        .rst      (rst),
        .start    (start),
        .data_in  (data_in),
        .baud_div (baud_div),
        .tx       (tx),
        .busy     (busy)
    );

    uart_rx rx_inst (
        .clk      (clk),
        .rst      (rst),
        .rx       (rx),
        .baud_div (baud_div),
        .data_out (data_out),
        .valid    (valid)
    );

endmodule

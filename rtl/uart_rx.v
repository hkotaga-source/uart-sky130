module uart_rx (
    input  wire clk,
    input  wire rst,
    input  wire rx,
    input  wire [15:0] baud_div,
    output reg  [7:0] data_out,
    output reg  valid
);

    parameter IDLE  = 2'b00;
    parameter START = 2'b01;
    parameter DATA  = 2'b10;
    parameter STOP  = 2'b11;

    reg [1:0]  state;
    reg [15:0] baud_cnt;
    reg [2:0]  bit_cnt;
    reg [7:0]  shift_reg;

    // 2-flop synchronizer: rx comes from another device's clock domain,
    // so pass it through two flip-flops before using it to avoid
    // metastability. Reset to 1 because an idle UART line is high.
    reg rx_meta, rx_sync;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rx_meta <= 1'b1;
            rx_sync <= 1'b1;
        end else begin
            rx_meta <= rx;
            rx_sync <= rx_meta;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state    <= IDLE;
            data_out <= 0;
            valid    <= 0;
            baud_cnt <= 0;
            bit_cnt  <= 0;
            shift_reg<= 0;
        end else begin
            valid <= 0;
            case (state)
                IDLE: begin
                    if (rx_sync == 1'b0) begin
                        baud_cnt <= baud_div >> 1;
                        state    <= START;
                    end
                end

                START: begin
                    if (baud_cnt == 0) begin
                        if (rx_sync == 1'b0) begin
                            baud_cnt <= baud_div;
                            bit_cnt  <= 0;
                            state    <= DATA;
                        end else begin
                            state <= IDLE;
                        end
                    end else begin
                        baud_cnt <= baud_cnt - 1;
                    end
                end

                DATA: begin
                    if (baud_cnt == 0) begin
                        baud_cnt  <= baud_div;
                        shift_reg <= {rx_sync, shift_reg[7:1]};
                        if (bit_cnt == 7) begin
                            state <= STOP;
                        end else begin
                            bit_cnt <= bit_cnt + 1;
                        end
                    end else begin
                        baud_cnt <= baud_cnt - 1;
                    end
                end

                STOP: begin
                    if (baud_cnt == 0) begin
                        if (rx_sync == 1'b1) begin
                            data_out <= shift_reg;
                            valid    <= 1'b1;
                        end
                        state <= IDLE;
                    end else begin
                        baud_cnt <= baud_cnt - 1;
                    end
                end
            endcase
        end
    end
endmodule

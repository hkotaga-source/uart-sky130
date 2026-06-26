module uart_tx (
    input  wire clk,
    input  wire rst,
    input  wire start,
    input  wire [7:0] data_in,
    input  wire [15:0] baud_div,
    output reg  tx,
    output reg  busy
);

    // States
    parameter IDLE  = 2'b00;
    parameter START = 2'b01;
    parameter DATA  = 2'b10;
    parameter STOP  = 2'b11;

    reg [1:0]  state;
    reg [15:0] baud_cnt;
    reg [2:0]  bit_cnt;
    reg [7:0]  shift_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state    <= IDLE;
            tx       <= 1'b1;
            busy     <= 1'b0;
            baud_cnt <= 0;
            bit_cnt  <= 0;
            shift_reg<= 0;
        end else begin
            case (state)
                IDLE: begin
                    tx   <= 1'b1;
                    busy <= 1'b0;
                    if (start) begin
                        shift_reg <= data_in;
                        baud_cnt  <= baud_div;
                        state     <= START;
                        busy      <= 1'b1;
                    end
                end

                START: begin
                    tx <= 1'b0;
                    if (baud_cnt == 0) begin
                        baud_cnt <= baud_div;
                        bit_cnt  <= 0;
                        state    <= DATA;
                    end else begin
                        baud_cnt <= baud_cnt - 1;
                    end
                end

                DATA: begin
                    tx <= shift_reg[0];
                    if (baud_cnt == 0) begin
                        baud_cnt  <= baud_div;
                        shift_reg <= shift_reg >> 1;
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
                    tx <= 1'b1;
                    if (baud_cnt == 0) begin
                        state <= IDLE;
                    end else begin
                        baud_cnt <= baud_cnt - 1;
                    end
                end
            endcase
        end
    end
endmodule


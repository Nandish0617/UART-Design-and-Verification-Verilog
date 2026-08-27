`timescale 1ns/1ps

// ============================================================
// UART TRANSMITTER
// 100 MHz clock
// 9600 baud
// 8-N-1 format
// ============================================================

module uart_tx #(
    parameter CLK_FREQ  = 100_000_000,
    parameter BAUD_RATE = 9600
)(
    input        clk,
    input        reset,
    input        tx_start,
    input  [7:0] tx_data,
    output reg   tx,
    output reg   tx_busy
);

    localparam BAUD_DIV = CLK_FREQ / BAUD_RATE;

    reg [31:0] baud_count;
    reg [3:0]  bit_count;
    reg [7:0]  data_reg;

    always @(posedge clk or posedge reset) begin

        if (reset) begin
            tx         <= 1'b1;
            tx_busy    <= 1'b0;
            baud_count <= 32'd0;
            bit_count  <= 4'd0;
            data_reg   <= 8'd0;
        end

        else begin

            // Start a new transmission
            if (tx_start && !tx_busy) begin

                data_reg   <= tx_data;
                tx         <= 1'b0;       // Start bit
                tx_busy    <= 1'b1;
                baud_count <= 32'd0;
                bit_count  <= 4'd0;

            end

            // Transmission in progress
            else if (tx_busy) begin

                if (baud_count < BAUD_DIV - 1) begin
                    baud_count <= baud_count + 1'b1;
                end

                else begin

                    baud_count <= 32'd0;

                    if (bit_count < 8) begin

                        // Send data bits LSB first
                        tx        <= data_reg[bit_count];
                        bit_count <= bit_count + 1'b1;

                    end

                    else begin

                        // Stop bit
                        tx        <= 1'b1;
                        tx_busy   <= 1'b0;
                        bit_count <= 4'd0;

                    end

                end

            end

            else begin
                tx <= 1'b1;                // UART idle
            end

        end

    end

endmodule


// ============================================================
// UART RECEIVER
// 100 MHz clock
// 9600 baud
// 8-N-1 format
// Mid-bit start detection
// Framing-error detection
// ============================================================

module uart_rx #(
    parameter CLK_FREQ  = 100_000_000,
    parameter BAUD_RATE = 9600
)(
    input        clk,
    input        reset,
    input        rx,

    output reg [7:0] rx_data,
    output reg       rx_done,
    output reg       framing_error
);

    localparam BAUD_DIV      = CLK_FREQ / BAUD_RATE;
    localparam HALF_BAUD_DIV = BAUD_DIV / 2;

    reg [31:0] baud_count;
    reg [3:0]  bit_count;
    reg        receiving;

    always @(posedge clk or posedge reset) begin

        if (reset) begin
            baud_count    <= 32'd0;
            bit_count     <= 4'd0;
            receiving     <= 1'b0;
            rx_data       <= 8'd0;
            rx_done       <= 1'b0;
            framing_error <= 1'b0;
        end

        else begin

            // These are event/status pulses
            rx_done       <= 1'b0;
            framing_error <= 1'b0;

            // ------------------------------------------------
            // IDLE: Detect start bit
            // ------------------------------------------------
            if (!receiving) begin

                baud_count <= 32'd0;

                if (rx == 1'b0) begin
                    receiving <= 1'b1;
                    bit_count <= 4'd0;
                end

            end

            else begin

                // ------------------------------------------------
                // Verify start bit at the middle of the bit
                // ------------------------------------------------
                if (bit_count == 0) begin

                    if (baud_count < HALF_BAUD_DIV - 1) begin
                        baud_count <= baud_count + 1'b1;
                    end

                    else begin

                        baud_count <= 32'd0;

                        if (rx == 1'b0)
                            bit_count <= 4'd1;
                        else
                            receiving <= 1'b0;

                    end

                end

                // ------------------------------------------------
                // Receive 8 data bits
                // ------------------------------------------------
                else if (bit_count <= 8) begin

                    if (baud_count < BAUD_DIV - 1) begin
                        baud_count <= baud_count + 1'b1;
                    end

                    else begin

                        baud_count <= 32'd0;

                        // LSB first
                        rx_data[bit_count - 1] <= rx;
                        bit_count <= bit_count + 1'b1;

                    end

                end

                // ------------------------------------------------
                // Check stop bit
                // ------------------------------------------------
                else begin

                    if (baud_count < BAUD_DIV - 1) begin
                        baud_count <= baud_count + 1'b1;
                    end

                    else begin

                        baud_count <= 32'd0;
                        receiving  <= 1'b0;
                        rx_done    <= 1'b1;

                        if (rx == 1'b1)
                            framing_error <= 1'b0;
                        else
                            framing_error <= 1'b1;

                    end

                end

            end

        end

    end

endmodule
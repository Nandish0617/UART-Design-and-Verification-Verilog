`timescale 1ns/1ps

module uart_tb;

    // -------------------------------------------------
    // UART timing
    // -------------------------------------------------
    localparam integer BIT_TIME = 104160;

    // -------------------------------------------------
    // Testbench signals
    // -------------------------------------------------
    reg        clk;
    reg        reset;
    reg        tx_start;
    reg  [7:0] tx_data;

    wire       tx;
    wire       tx_busy;

    wire [7:0] rx_data;
    wire       rx_done;
    wire       framing_error;

    // Signals for bad-frame injection
    reg        bad_frame;
    reg        bad_serial;

    wire       rx_input;

    assign rx_input = bad_frame ? bad_serial : tx;

    // Verification counters
    integer total_tests;
    integer passed_tests;
    integer failed_tests;


    // -------------------------------------------------
    // 100 MHz clock
    // -------------------------------------------------
    always #5 clk = ~clk;


    // -------------------------------------------------
    // UART TRANSMITTER
    // -------------------------------------------------
    uart_tx transmitter (
        .clk       (clk),
        .reset     (reset),
        .tx_start  (tx_start),
        .tx_data   (tx_data),
        .tx        (tx),
        .tx_busy   (tx_busy)
    );


    // -------------------------------------------------
    // UART RECEIVER
    // -------------------------------------------------
    uart_rx receiver (
        .clk            (clk),
        .reset          (reset),
        .rx              (rx_input),
        .rx_data         (rx_data),
        .rx_done         (rx_done),
        .framing_error   (framing_error)
    );


    // =================================================
    // TASK 1: NORMAL UART BYTE TEST
    // =================================================

    task send_byte(input [7:0] data);
    begin

        total_tests = total_tests + 1;

        // Wait until transmitter is idle
        wait (tx_busy == 1'b0);

        // Apply data
        tx_data  = data;
        tx_start = 1'b1;

        // Start pulse
        #10;
        tx_start = 1'b0;

        // Wait for receiver completion
        @(posedge rx_done);

        // Allow nonblocking assignments to settle
        #1;

        // Check received data and framing
        if ((rx_data == data) && (framing_error == 1'b0)) begin

            passed_tests = passed_tests + 1;

            $display(
                "PASS: TX = %b, RX = %b, Framing Error = %b",
                data,
                rx_data,
                framing_error
            );

        end

        else begin

            failed_tests = failed_tests + 1;

            $display(
                "FAIL: TX = %b, RX = %b, Framing Error = %b",
                data,
                rx_data,
                framing_error
            );

        end

        // Idle time between frames
        #110000;

    end
    endtask


    // =================================================
    // TASK 2: FRAMING-ERROR TEST
    // =================================================

    task send_bad_frame;
    begin

        total_tests = total_tests + 1;

        // Use testbench-generated serial input
        bad_frame  = 1'b1;
        bad_serial = 1'b1;

        // -----------------------------
        // START BIT
        // -----------------------------
        bad_serial = 1'b0;
        #(BIT_TIME);

        // -----------------------------
        // DATA = 10101010
        // LSB first
        // -----------------------------

        bad_serial = 1'b0;       // D0
        #(BIT_TIME);

        bad_serial = 1'b1;       // D1
        #(BIT_TIME);

        bad_serial = 1'b0;       // D2
        #(BIT_TIME);

        bad_serial = 1'b1;       // D3
        #(BIT_TIME);

        bad_serial = 1'b0;       // D4
        #(BIT_TIME);

        bad_serial = 1'b1;       // D5
        #(BIT_TIME);

        bad_serial = 1'b0;       // D6
        #(BIT_TIME);

        bad_serial = 1'b1;       // D7
        #(BIT_TIME);

        // -----------------------------
        // INVALID STOP BIT
        // Should be 1, intentionally 0
        // -----------------------------

        bad_serial = 1'b0;

        // Wait for receiver to finish
        @(posedge rx_done);

        #1;

        if (framing_error == 1'b1) begin

            passed_tests = passed_tests + 1;

            $display(
                "PASS: Framing error detected correctly"
            );

        end

        else begin

            failed_tests = failed_tests + 1;

            $display(
                "FAIL: Framing error was NOT detected"
            );

        end

        // Return to idle
        bad_serial = 1'b1;
        bad_frame  = 1'b0;

        #110000;

    end
    endtask


    // =================================================
    // MAIN TEST
    // =================================================

    initial begin

        // Generate VCD waveform
        $dumpfile("dump.vcd");
        $dumpvars(0, uart_tb);

        // Initial values
        clk        = 1'b0;
        reset      = 1'b1;
        tx_start   = 1'b0;
        tx_data    = 8'b00000000;

        bad_frame  = 1'b0;
        bad_serial = 1'b1;

        // Initialize counters
        total_tests  = 0;
        passed_tests = 0;
        failed_tests = 0;


        // -------------------------------------------------
        // RESET
        // -------------------------------------------------

        #20;
        reset = 1'b0;


        // -------------------------------------------------
        // NORMAL UART TESTS
        // -------------------------------------------------

        send_byte(8'b10101010);
        send_byte(8'b01010101);
        send_byte(8'b11111111);
        send_byte(8'b00000000);
        send_byte(8'b11001100);
        send_byte(8'b00110011);


        // -------------------------------------------------
        // FRAMING ERROR TEST
        // -------------------------------------------------

        send_bad_frame;


        // -------------------------------------------------
        // VERIFICATION SUMMARY
        // -------------------------------------------------

        $display("=================================");
        $display("UART VERIFICATION SUMMARY");
        $display("Total Tests = %0d", total_tests);
        $display("Passed      = %0d", passed_tests);
        $display("Failed      = %0d", failed_tests);
        $display("=================================");

        $finish;

    end

endmodule
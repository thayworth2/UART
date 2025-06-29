`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Tyler Hayworth
// 
// Create Date: 06/16/2025 09:25:12 PM
// Design Name: UART Top Level Module
// Module Name: uart_top
// Project Name: UART
// Target Devices: Basys 3 Board
// Tool Versions: 
// Description: Top-level UART module integrating TX, RX, FIFO, and ILA.
//
//////////////////////////////////////////////////////////////////////////////////

module uart_top (
    input  wire        clock,
    input  wire        reset,

    // Transmit interface
    input  wire        tx_fifo_wr,
    input  wire [7:0]  w_data,
    output wire        tx_full,
    output wire        tx,

    // Receive interface
    input  wire        read_uart,   // Reserved for future use
    input  wire        rx,
    output wire [7:0]  uart_led
);

    // Baud rate generator
    wire tick;
    mod_m_counter #(
        .N(8),
        .M(54)
    ) baud_gen (
        .clk      (clock),
        .reset    (reset),
        .max_tick (tick),
        .q        ()
    );

    // Debounce transmit write signal
    wire tx_fifo_wr_debounced;
    debounce tx_wr_debouncer (
        .clk       (clock),
        .reset     (reset),
        .sw        (tx_fifo_wr),
        .db_level  (),
        .db_tick   (tx_fifo_wr_debounced)
    );

    // Transmit FIFO and start-pulse generation
    wire [7:0] tx_data_o;
    wire       tx_empty;
    wire       tx_fifo_not_empty = ~tx_empty;

    fifo fifo_tx (
        .clk    (clock),
        .reset  (reset),
        .rd     (tx_done_tick),
        .wr     (tx_fifo_wr_debounced),
        .w_data (w_data),
        .empty  (tx_empty),
        .full   (tx_full),
        .r_data (tx_data_o)
    );

    reg prev_not_empty;
    always @(posedge clock) begin
        if (reset)
            prev_not_empty <= 1'b0;
        else
            prev_not_empty <= tx_fifo_not_empty;
    end

    wire start_pulse      = tx_fifo_not_empty & ~prev_not_empty;
    wire tx_done_tick;

    // UART Transmit module
    uart_tx transmit (
        .clk         (clock),
        .reset       (reset),
        .tx_start    (start_pulse),
        .s_tick      (tick),
        .din         (tx_data_o),
        .tx_done_tick(tx_done_tick),
        .tx          (tx)
    );

    // UART Receive module
    wire       read_done;
    wire [7:0] rx_data;

    uart_rx receive (
        .clk         (clock),
        .reset       (reset),
        .rx          (rx),
        .s_tick      (tick),
        .rx_done_tick(read_done),
        .dout        (rx_data)
    );

    // Latch received data for LEDs
    reg [7:0] led_reg;
    always @(posedge clock or posedge reset) begin
        if (reset)
            led_reg <= 8'b0;
        else if (read_done)
            led_reg <= rx_data;
    end

    assign uart_led = led_reg;

    // ILA instance for on-chip debugging
    ila_0 ila_inst (
        .clk    (clock),            // Sampling clock
        .probe0 (rx),               // Raw serial in
        .probe1 (tick),             // Baud-rate tick
        .probe2 (read_done),        // RX done tick
        .probe3 (rx_data),          // Received byte
        .probe4 (start_pulse),      // TX start pulse
        .probe5 (tx_done_tick),     // TX done tick
        .probe6 (tx),               // Serial out
        .probe7 (tx_empty)          // FIFO empty flag
    );

endmodule


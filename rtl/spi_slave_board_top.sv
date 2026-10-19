`timescale 1ns / 1ps

module spi_slave_board_top (
    input  logic clk,
    input  logic reset,

    input  logic sclk,
    input  logic mosi,
    output logic miso,
    input  logic ss_n,

    output logic [3:0] fnd_com,
    output logic [7:0] fnd_data,

//    output logic led_busy,
    output logic led_done
//    output logic led_selected
);

    logic [7:0] slave_tx_data;
    logic [7:0] slave_rx_data;
    logic       slave_busy;
    logic       slave_done;

    logic [7:0] echo_data_reg;
    logic [7:0] rx_data_reg;

    assign slave_tx_data = echo_data_reg;

    spi_slave U_SPI_SLAVE (
        .clk    (clk),
        .reset  (reset),

        .tx_data(slave_tx_data),
        .busy   (slave_busy),
        .rx_data(slave_rx_data),
        .done   (slave_done),

        .sclk   (sclk),
        .mosi   (mosi),
        .miso   (miso),
        .ss_n   (ss_n)
    );

	logic [25:0] led_timer;   // 26bit (50,000,000 표현 위해)
	logic        led_active;
	
	always_ff @(posedge clk or posedge reset) begin
	    if (reset) begin
	        echo_data_reg <= 8'h00;
	        rx_data_reg   <= 8'h00;
	        led_timer     <= 26'd0;
	        led_active    <= 1'b0;
	    end else begin
	        if (slave_done) begin
	            rx_data_reg   <= slave_rx_data;
	            echo_data_reg <= slave_rx_data;
	            led_timer  <= 26'd50_000_000;  // 0.5초
	            led_active <= 1'b1;
	        end else if (led_timer > 0) begin
	            led_timer <= led_timer - 1'b1;
	        end else begin
	            led_active <= 1'b0;
	        end
	    end
	end
	
	assign led_done     = led_active;
	assign led_busy     = slave_busy;
	assign led_selected = ~ss_n;

    // Slave FND = [다음에 echo할 값][방금 받은 값]
    // 예: 받은 값 09 -> 0909
    logic [15:0] fnd_hex_data;

    assign fnd_hex_data = {echo_data_reg, rx_data_reg};

    fnd_hex_controller U_FND_HEX (
        .clk      (clk),
        .rst      (reset),
        .hex_data (fnd_hex_data),
        .fnd_com  (fnd_com),
        .fnd_data (fnd_data)
    );

endmodule

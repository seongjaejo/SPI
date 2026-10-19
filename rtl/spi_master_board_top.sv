`timescale 1ns / 1ps

module spi_master_board_top (
    input  logic       clk,
    input  logic       reset,

    input  logic       btn_start,
    input  logic [7:0] sw,

    output logic       sclk,
    output logic       mosi,
    input  logic       miso,
    output logic       ss_n,

    output logic [3:0] fnd_com,
    output logic [7:0] fnd_data,

//    output logic       led_busy,
    output logic       led_done
);

    localparam logic       CPOL_MODE0  = 1'b0;
    localparam logic       CPHA_MODE0  = 1'b0;

    // 안정성 위해 1MHz가 아니라 약 200kHz로 낮춤
    // 100MHz / (2 * (249 + 1)) = 200kHz
    localparam logic [7:0] SPI_CLK_DIV = 8'd249;

    logic start_pulse;

    button_debounce U_BTN_START (
        .clk   (clk),
        .rst   (reset),
        .i_btn (btn_start),
        .o_btn (start_pulse)
    );

    logic       spi_start;
    logic [7:0] spi_tx_data;
    logic       spi_busy;
    logic [7:0] spi_rx_data;
    logic       spi_done;

    spi_master U_SPI_MASTER (
        .clk     (clk),
        .reset   (reset),

        .start   (spi_start),
        .cpol    (CPOL_MODE0),
        .cpha    (CPHA_MODE0),
        .clk_div (SPI_CLK_DIV),
        .tx_data (spi_tx_data),

        .busy    (spi_busy),
        .rx_data (spi_rx_data),
        .done    (spi_done),

        .sclk    (sclk),
        .mosi    (mosi),
        .miso    (miso),
        .ss_n    (ss_n)
    );

	typedef enum logic [1:0] {
	    IDLE,
	    WAIT_DONE
	} state_e;
	
	state_e state;
	logic [7:0]  tx_data_reg;
	logic [7:0]  rx_data_reg;
	logic [25:0] led_timer;
	logic        led_active;
	
	always_ff @(posedge clk or posedge reset) begin
	    if (reset) begin
	        state       <= IDLE;
	        spi_start   <= 1'b0;
	        spi_tx_data <= 8'd0;
	        tx_data_reg <= 8'd0;
	        rx_data_reg <= 8'd0;
	        led_timer   <= 26'd0;
	        led_active  <= 1'b0;
	    end else begin
	        spi_start <= 1'b0;
	
	        // LED 타이머 (매 클럭)
	        if (led_timer > 0) begin
	            led_timer <= led_timer - 1'b1;
	        end else begin
	            led_active <= 1'b0;
	        end
	
	        case (state)
	            IDLE: begin
	                if (start_pulse && !spi_busy) begin
	                    tx_data_reg <= sw;
	                    spi_tx_data <= sw;
	                    spi_start   <= 1'b1;
	                    state       <= WAIT_DONE;
	                end
	            end
	            WAIT_DONE: begin
	                if (spi_done) begin
	                    rx_data_reg <= spi_rx_data;
	                    // 전송 완료 시 0.5초간 LED ON
	                    led_timer  <= 26'd50_000_000;
	                    led_active <= 1'b1;
	                    state <= IDLE;
	                end
	            end
	            default: begin
	                state <= IDLE;
	            end
	        endcase
	    end
	end
	
	assign led_done = led_active;
	assign led_busy = spi_busy;

    // Master FND = [받은 값][보낸 값]
    // 예: rx=09, tx=09 -> 0909
    logic [15:0] fnd_hex_data;

    assign fnd_hex_data = {rx_data_reg, tx_data_reg};

    fnd_hex_controller U_FND_HEX (
        .clk      (clk),
        .rst      (reset),
        .hex_data (fnd_hex_data),
        .fnd_com  (fnd_com),
        .fnd_data (fnd_data)
    );

endmodule

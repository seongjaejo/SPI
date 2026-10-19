`timescale 1ns / 1ps


//module tb_spi_master();
module tb_spi();

	logic 	    clk;
	logic 	    reset;
	logic 	    start;
	logic 	    cpol; 
	logic 	    cpha; 
	logic [7:0] clk_div; // SCLK 속도 계산용 분주값(half 용)
	logic [7:0] tx_data; 
	logic 	    busy;
	logic [7:0] rx_data;
	logic 	    done;
	logic	    sclk;
	logic	    mosi;
	logic	    miso;
	logic	    ss_n;

	logic mosi_wire;
	logic miso_wire;
	logic sclk_wire;
	logic ss_n_wire;

	initial clk = 0;
	always #5 clk = ~clk;

//spi_master dut(
spi_master dut(
	.clk(clk),
	.reset(reset),
	.start(start),
	.cpol(cpol), 
	.cpha(cpha), 
	.clk_div(clk_div), // SCLK 속도 계산용 분주값(half 용)
	.tx_data(tx_data), 
	.busy(busy),
	.rx_data(rx_data),
	.done(done),
	.sclk(sclk_wire),
	.mosi(mosi_wire),
	.miso(miso_wire),
	.ss_n(ss_n_wire)
    );

	task spi_set_cpol(bit pol);
		cpol = pol;
		@(posedge clk);
	endtask

	task spi_set_cpha(bit pha);
		cpha = pha;
		@(posedge clk);
	endtask

	//task spi_set_mode(bit [1:0] mode);
	//	{cpol, cpha} = mode;
	//	@(posedge clk);
	//endtask

	task spi_send_data(logic [7:0] data);
		tx_data = data;
		start = 1'b1;
		@(posedge clk);
		start = 1'b0;
		@(posedge clk);
		wait (done);
		@(posedge clk);
	endtask

	initial begin
		reset = 1;
		repeat(3) @(posedge clk);
		reset = 0;
		@(posedge clk);
		clk_div = 4; // SCLK = 10Mhz -> (100Mhz / (10Mhz *2)) - 1
		@(posedge clk);

		spi_set_cpol(0); 
		spi_set_cpha(0); 
		spi_send_data(8'haa);

		spi_set_cpol(0); 
		spi_set_cpha(1); 
		spi_send_data(8'haa);

		spi_set_cpol(1); 
		spi_set_cpha(0); 
		spi_send_data(8'h55);

		spi_set_cpol(1); 
		spi_set_cpha(1); 
		spi_send_data(8'hff);

		spi_set_cpol(1); 
		spi_set_cpha(1); 
		spi_send_data(8'h00);

		#20;
		$finish;
	end


endmodule

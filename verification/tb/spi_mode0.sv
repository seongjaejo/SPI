`timescale 1ns/1ps
module audit_spi;
reg clk=0,reset=1,start=0; always #5 clk=~clk;
reg [7:0] tx=0,stx=0,div=4;
wire [7:0] rx,srx; wire done,sdone,busy,sbusy,sclk,mosi,miso,ss_n;
spi_master m(.clk(clk),.reset(reset),.start(start),.cpol(1'b0),.cpha(1'b0),.clk_div(div),.tx_data(tx),.rx_data(rx),.busy(busy),.done(done),.sclk(sclk),.mosi(mosi),.miso(miso),.ss_n(ss_n));
spi_slave s(.clk(clk),.reset(reset),.tx_data(stx),.rx_data(srx),.busy(sbusy),.done(sdone),.sclk(sclk),.mosi(mosi),.miso(miso),.ss_n(ss_n));
integer k,j,n,errors=0,count=0; reg[7:0] sd; reg seen;
always @(posedge clk) if(sdone) begin sd<=srx; seen<=1; end
initial begin
 repeat(5) @(negedge clk); reset=0;
 for(j=0;j<3;j=j+1) begin
 div=(j==0)?4:((j==1)?7:49);
 for(k=0;k<32;k=k+1) begin
 @(negedge clk); tx=(k==0)?0:((k==1)?255:(k*37)); stx=(k==0)?255:((k==1)?0:(k*19)); seen=0; start=1;
 @(negedge clk); start=0;
 n=0; while(!done && n<5000) begin @(negedge clk); n=n+1; end
 repeat(8) @(negedge clk);
 if(n==5000 || !seen || rx!==stx || sd!==tx) begin
 errors=errors+1; $display("AUDIT SPI FAIL div=%0d tx=%h stx=%h rx=%h srx=%h seen=%b",div,tx,stx,rx,sd,seen);
 end
 count=count+1;
 end end
 $display("AUDIT SPI transactions=%0d errors=%0d",count,errors);
 if(errors==0) $display("AUDIT SPI PASS"); $finish;
end
initial begin #5000000; $display("AUDIT SPI TIMEOUT FAIL"); $finish; end
endmodule

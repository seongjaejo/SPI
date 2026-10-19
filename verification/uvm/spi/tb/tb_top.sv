import uvm_pkg::*;
import spi_pkg::*;

module tb_top ();

    logic clk;

    initial clk = 0;
    always #5 clk = ~clk;

    spi_if s_if(.clk(clk));

    spi_top dut (
        .clk            (s_if.clk),
        .reset          (s_if.reset),
        .start          (s_if.start),
        .cpol           (s_if.cpol),
        .cpha           (s_if.cpha),
        .clk_div        (s_if.clk_div),
        .master_tx_data (s_if.master_tx_data),
        .slave_tx_data  (s_if.slave_tx_data),
        .master_rx_data (s_if.master_rx_data),
        .slave_rx_data  (s_if.slave_rx_data),
        .master_done    (s_if.master_done),
        .slave_done     (s_if.slave_done),
        .busy           (s_if.busy),
        .slave_busy     (s_if.slave_busy)
    );

    initial begin
        uvm_config_db #(virtual spi_if)::set(null, "*", "s_if", s_if);
        run_test();
    end

    initial begin
        $fsdbDumpfile("spi_tb.fsdb");
        $fsdbDumpvars(0);
    end

endmodule

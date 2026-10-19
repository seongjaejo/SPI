interface spi_if (
    input logic clk
);
    // driver 출력 신호
    logic        reset;
    logic        start;
    logic        cpol;
    logic        cpha;
    logic [7:0]  clk_div;
    logic [7:0]  master_tx_data;
    logic [7:0]  slave_tx_data;
    // monitor 입력 신호
    logic [7:0]  master_rx_data;
    logic [7:0]  slave_rx_data;
    logic        master_done;
    logic        slave_done;
    logic        busy;
    logic        slave_busy;

    clocking drv_cb @(posedge clk);
        default input #1step output #0;
        output reset;
        output start;
        output cpol;
        output cpha;
        output clk_div;
        output master_tx_data;
        output slave_tx_data;
        input  master_rx_data;
        input  slave_rx_data;
        input  master_done;
        input  slave_done;
        input  busy;
        input  slave_busy;
    endclocking

    clocking mon_cb @(posedge clk);
        default input #1step output #0;
        input reset;
        input start;
        input cpol;
        input cpha;
        input clk_div;
        input master_tx_data;
        input slave_tx_data;
        input master_rx_data;
        input slave_rx_data;
        input master_done;
        input slave_done;
        input busy;
        input slave_busy;
    endclocking

    modport DRV(clocking drv_cb, input clk);
    modport MON(clocking mon_cb, input clk);

endinterface

`timescale 1ns / 1ps
module tb_spi_top();
    logic       clk;
    logic       reset;
    logic       start;
    logic       cpol;
    logic       cpha;
    logic [7:0] clk_div;
    logic [7:0] master_tx_data;
    logic [7:0] slave_tx_data;
    logic [7:0] master_rx_data;
    logic [7:0] slave_rx_data;
    logic       master_done;
    logic       slave_done;
    logic       busy;
    logic       slave_busy;

    initial clk = 0;
    always #5 clk = ~clk;

    spi_top dut(
        .clk           (clk),
        .reset         (reset),
        .start         (start),
        .cpol          (cpol),
        .cpha          (cpha),
        .clk_div       (clk_div),
        .master_tx_data(master_tx_data),
        .slave_tx_data (slave_tx_data),
        .master_rx_data(master_rx_data),
        .slave_rx_data (slave_rx_data),
        .master_done   (master_done),
        .slave_done    (slave_done),
        .slave_busy    (slave_busy),
        .busy          (busy)
    );

    task spi_set_mode(bit [1:0] mode);
        {cpol, cpha} = mode;
        @(posedge clk);
    endtask

    task spi_transfer(logic [7:0] m_data, logic [7:0] s_data);
        master_tx_data = m_data;
        slave_tx_data  = s_data;
        start = 1'b1;
        @(posedge clk);
        start = 1'b0;
        @(posedge clk);
        wait(master_done);
        @(posedge clk);
        $display("Mode[CPOL=%0b CPHA=%0b] | M_TX: %0h  S_TX: %0h | M_RX: %0h  S_RX: %0h | %s",
            cpol, cpha, m_data, s_data, master_rx_data, slave_rx_data,
            (master_rx_data == s_data && slave_rx_data == m_data) ? "PASS" : "FAIL"
        );
    endtask

    initial begin
        reset          = 1;
        start          = 0;
        cpol           = 0;
        cpha           = 0;
        master_tx_data = 0;
        slave_tx_data  = 0;
        repeat(3) @(posedge clk);
        reset   = 0;
        clk_div = 4;
        @(posedge clk);

        // ── Mode 0만 테스트 (슬레이브 고정) ──
        spi_set_mode(2'b00);
        spi_transfer(8'haa, 8'h55);  // 1010_1010 ↔ 0101_0101

        spi_set_mode(2'b00);
        spi_transfer(8'hff, 8'h00);  // 1111_1111 ↔ 0000_0000

        spi_set_mode(2'b00);
        spi_transfer(8'h12, 8'h34);  // 임의 데이터

        spi_set_mode(2'b00);
        spi_transfer(8'h00, 8'hff);  // 반전 테스트

        #20;
        $finish;
    end
endmodule

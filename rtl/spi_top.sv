`timescale 1ns / 1ps

module spi_top(
    // global signals
    input  logic       clk,
    input  logic       reset,
    // master 제어 신호
    input  logic       start,
    input  logic       cpol,
    input  logic       cpha,
    input  logic [7:0] clk_div,
    input  logic [7:0] master_tx_data,  // 마스터가 보낼 데이터
    input  logic [7:0] slave_tx_data,   // 슬레이브가 보낼 데이터
    // 출력
    output logic [7:0] master_rx_data,  // 마스터가 받은 데이터
    output logic [7:0] slave_rx_data,   // 슬레이브가 받은 데이터
    output logic       master_done,
    output logic       slave_done,
    output logic       busy,
    output logic       slave_busy
);

    logic sclk_wire;
    logic mosi_wire;
    logic miso_wire;
    logic ss_n_wire;

    spi_master U_MASTER(
        .clk     (clk),
        .reset   (reset),
        .start   (start),
        .cpol    (cpol),
        .cpha    (cpha),
        .clk_div (clk_div),
        .tx_data (master_tx_data),
        .busy    (busy),
        .rx_data (master_rx_data),
        .done    (master_done),
        .sclk    (sclk_wire),       // 마스터 → 슬레이브
        .mosi    (mosi_wire),       // 마스터 → 슬레이브
        .miso    (miso_wire),       // 슬레이브 → 마스터
        .ss_n    (ss_n_wire)        // 마스터 → 슬레이브
    );

    spi_slave U_SLAVE(
        .clk     (clk),
        .reset   (reset),
//        .cpol    (cpol),
//        .cpha    (cpha),
        .tx_data (slave_tx_data),
        .rx_data (slave_rx_data),
        .done    (slave_done),
        .busy    (slave_busy),
        .sclk    (sclk_wire),       // 마스터로부터
        .mosi    (mosi_wire),       // 마스터로부터
        .miso    (miso_wire),       // 슬레이브 → 마스터
        .ss_n    (ss_n_wire)        // 마스터로부터
    );

endmodule

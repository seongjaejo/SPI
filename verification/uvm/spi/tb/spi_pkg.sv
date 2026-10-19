package spi_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    // 의존성 순서대로 include
    `include "spi_seq_item.sv"
    `include "spi_sequence.sv"
    `include "spi_driver.sv"
    `include "spi_monitor.sv"
    `include "spi_agent.sv"
    `include "spi_scoreboard.sv"
    `include "spi_coverage.sv"
    `include "spi_env.sv"
    `include "spi_test.sv"
endpackage

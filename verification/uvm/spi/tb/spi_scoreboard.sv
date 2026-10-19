class spi_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(spi_scoreboard)

    uvm_analysis_imp #(spi_seq_item, spi_scoreboard) imp;

    int trans_count = 0;
    int pass_count  = 0;
    int fail_count  = 0;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        imp = new("imp", this);
    endfunction

    function void write(spi_seq_item tr);
        bit master_ok;
        bit slave_ok;

        trans_count++;

        // master_tx → slave_rx 검증
        slave_ok  = (tr.slave_rx_data  === tr.master_tx_data);
        // slave_tx  → master_rx 검증
        master_ok = (tr.master_rx_data === tr.slave_tx_data);

        if (slave_ok && master_ok) begin
            pass_count++;
            `uvm_info(get_type_name(), $sformatf(
                "PASS : %s", tr.convert2string()), UVM_HIGH)
        end else begin
            fail_count++;
            if (!slave_ok)
                `uvm_error(get_type_name(), $sformatf(
                    "FAIL [slave_rx] master_tx=0x%02h slave_rx=0x%02h",
                    tr.master_tx_data, tr.slave_rx_data))
            if (!master_ok)
                `uvm_error(get_type_name(), $sformatf(
                    "FAIL [master_rx] slave_tx=0x%02h master_rx=0x%02h",
                    tr.slave_tx_data, tr.master_rx_data))
        end
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("SCB", "==================================", UVM_LOW)
        `uvm_info("SCB", "=========Scoreboard report========", UVM_LOW)
        `uvm_info("SCB", $sformatf("  trans   count : %0d", trans_count), UVM_LOW)
        `uvm_info("SCB", $sformatf("  pass    count : %0d", pass_count),  UVM_LOW)
        `uvm_info("SCB", $sformatf("  fail    count : %0d", fail_count),  UVM_LOW)
        `uvm_info("SCB", "==================================", UVM_LOW)
    endfunction

endclass

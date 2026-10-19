class spi_coverage extends uvm_subscriber #(spi_seq_item);
    `uvm_component_utils(spi_coverage)

    spi_seq_item tr;

    covergroup spi_cg;
        option.per_instance = 1;

        // master tx data 커버리지
        cp_master_tx : coverpoint tr.master_tx_data {
            bins data_zero = {8'h00};
            bins data_max  = {8'hFF};
            bins data_etc  = {[8'h01:8'hFE]};
        }

        // slave tx data 커버리지
        cp_slave_tx : coverpoint tr.slave_tx_data {
            bins data_zero = {8'h00};
            bins data_max  = {8'hFF};
            bins data_etc  = {[8'h01:8'hFE]};
        }

    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        spi_cg = new();
    endfunction

    function void write(spi_seq_item t);
        tr = t;
        spi_cg.sample();
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("COV", "==========================================", UVM_LOW)
        `uvm_info("COV", "======= Functional Coverage  result ======", UVM_LOW)
        `uvm_info("COV", $sformatf(" total      : %6.2f %%", spi_cg.get_inst_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf(" master_tx  : %6.2f %%", spi_cg.cp_master_tx.get_inst_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf(" slave_tx   : %6.2f %%", spi_cg.cp_slave_tx.get_inst_coverage()), UVM_LOW)
        `uvm_info("COV", "==========================================", UVM_LOW)
        if (spi_cg.get_inst_coverage() < 100.0) begin
            `uvm_warning("COV", "Coverage below 100%! Add more test scenarios or perform additional testing.")
        end
    endfunction


endclass

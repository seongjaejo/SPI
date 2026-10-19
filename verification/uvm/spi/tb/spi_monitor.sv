class spi_monitor extends uvm_monitor;
    `uvm_component_utils(spi_monitor)

    virtual spi_if s_if;
    uvm_analysis_port #(spi_seq_item) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual spi_if)::get(this, "", "s_if", s_if))
            `uvm_fatal(get_type_name(), "can't find virtual interface(s_if) from config_db")
    endfunction

    task run_phase(uvm_phase phase);
        spi_seq_item tr;
        forever begin
            // master_done 올라올 때까지 대기
            @(s_if.mon_cb iff (s_if.mon_cb.master_done === 1));

            // 트랜잭션 캡처
            tr = spi_seq_item::type_id::create("tr");
            tr.cpol           = s_if.mon_cb.cpol;
            tr.cpha           = s_if.mon_cb.cpha;
            tr.clk_div        = s_if.mon_cb.clk_div;
            tr.master_tx_data = s_if.mon_cb.master_tx_data;
            tr.slave_tx_data  = s_if.mon_cb.slave_tx_data;
            tr.master_rx_data = s_if.mon_cb.master_rx_data;
            tr.slave_rx_data  = s_if.mon_cb.slave_rx_data;
            tr.master_done    = s_if.mon_cb.master_done;
            tr.slave_done     = s_if.mon_cb.slave_done;

            `uvm_info(get_type_name(), $sformatf("%s", tr.convert2string()), UVM_MEDIUM)
            ap.write(tr);
        end
    endtask

endclass

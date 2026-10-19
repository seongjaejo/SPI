class spi_driver extends uvm_driver #(spi_seq_item);
    `uvm_component_utils(spi_driver)

    virtual spi_if s_if;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual spi_if)::get(this, "", "s_if", s_if))
            `uvm_fatal(get_type_name(), "can't find virtual interface(s_if) from config_db")
    endfunction

    task run_phase(uvm_phase phase);
        // 초기값
        s_if.drv_cb.reset          <= 1;   
        s_if.drv_cb.start          <= 0;
        s_if.drv_cb.cpol           <= 0;
        s_if.drv_cb.cpha           <= 0;
        s_if.drv_cb.clk_div        <= 0;
        s_if.drv_cb.master_tx_data <= 0;
        s_if.drv_cb.slave_tx_data  <= 0;

        // reset 구간
        repeat(3) @(s_if.drv_cb);
        s_if.drv_cb.reset <= 0;        
        @(s_if.drv_cb);

        forever begin
            seq_item_port.get_next_item(req);

            // 1. 신호 세팅
            @(s_if.drv_cb);
            s_if.drv_cb.cpol           <= req.cpol;
            s_if.drv_cb.cpha           <= req.cpha;
            s_if.drv_cb.clk_div        <= req.clk_div;
            s_if.drv_cb.master_tx_data <= req.master_tx_data;
            s_if.drv_cb.slave_tx_data  <= req.slave_tx_data;

            // 2. start 펄스
            @(s_if.drv_cb);
            s_if.drv_cb.start <= 1;
            @(s_if.drv_cb);
            s_if.drv_cb.start <= 0;

            // 3. busy 내려갈 때까지 대기 (전송 완료)
            @(s_if.drv_cb iff (s_if.drv_cb.busy === 0));

            `uvm_info(get_type_name(), $sformatf("run: %s", req.convert2string()), UVM_HIGH)
            seq_item_port.item_done();
        end
    endtask

endclass

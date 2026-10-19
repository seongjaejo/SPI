class spi_seq_item extends uvm_sequence_item;
    rand bit        cpol; // constraint 로 mode 0고정을 하지만, 확장성을 위해 rand 남겨둠 
    rand bit        cpha; // constraint 로 mode 0고정을 하지만, 확장성을 위해 rand 남겨둠 
    rand bit [7:0]  clk_div; // constraint 로 고정을 하지만, 확장성을 위해 rand 남겨둠
    rand bit [7:0]  master_tx_data;
    rand bit [7:0]  slave_tx_data;
         bit [7:0]  master_rx_data;
         bit [7:0]  slave_rx_data;
         bit        master_done;
         bit        slave_done;

    // clk_div 4 fix
    constraint c_clk_div { clk_div == 4; }
    // slave mode 0 고정이라 cpol, cpha는 0으로 제한
    constraint c_mode    { cpol == 0; cpha == 0; }

    `uvm_object_utils_begin(spi_seq_item)
        `uvm_field_int(cpol,           UVM_ALL_ON)
        `uvm_field_int(cpha,           UVM_ALL_ON)
        `uvm_field_int(clk_div,        UVM_ALL_ON)
        `uvm_field_int(master_tx_data, UVM_ALL_ON)
        `uvm_field_int(slave_tx_data,  UVM_ALL_ON)
        `uvm_field_int(master_rx_data, UVM_ALL_ON)
        `uvm_field_int(slave_rx_data,  UVM_ALL_ON)
        `uvm_field_int(master_done,    UVM_ALL_ON)
        `uvm_field_int(slave_done,     UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "spi_seq_item");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf(
            "cpol=%0d cpha=%0d clk_div=%0d | master_tx=0x%02h slave_tx=0x%02h | master_rx=0x%02h slave_rx=0x%02h",
            cpol, cpha, clk_div, master_tx_data, slave_tx_data, master_rx_data, slave_rx_data);
    endfunction

endclass

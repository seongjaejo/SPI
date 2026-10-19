class spi_base_seq extends uvm_sequence #(spi_seq_item);
    `uvm_object_utils(spi_base_seq)

    function new(string name = "spi_base_seq");
        super.new(name);
    endfunction

    // 기본 전송 태스크
    task do_transfer(bit [7:0] master_tx, bit [7:0] slave_tx,
                     bit cpol=0, bit cpha=0, bit [7:0] clk_div=4);
        spi_seq_item item;
        item = spi_seq_item::type_id::create("item");
        start_item(item);
            item.cpol           = cpol;
            item.cpha           = cpha;
            item.clk_div        = clk_div;
            item.master_tx_data = master_tx;
            item.slave_tx_data  = slave_tx;
        finish_item(item);
    endtask

endclass

// 고정값 전송 시나리오
class spi_basic_seq extends spi_base_seq;
    `uvm_object_utils(spi_basic_seq)
    int num; // test에서 seq.num 직접 지정하기위해 num rand로 생성X

    function new(string name = "spi_basic_seq");
        super.new(name);
    endfunction

    task body();
        `uvm_info(get_type_name(), "basic scenario start", UVM_LOW)

		//  고정 값 주입
		do_transfer(8'h00, 8'h00, 0, 0, 4);  // master=0x00, slave=0x00
		do_transfer(8'hFF, 8'hFF, 0, 0, 4);  // master=0xFF, slave=0xFF
		do_transfer(8'h00, 8'hFF, 0, 0, 4);  // 교차
		do_transfer(8'hFF, 8'h00, 0, 0, 4);  // 교차
		do_transfer(8'h88, 8'hCC, 0, 0, 4);  

        `uvm_info(get_type_name(), "basic scenario end", UVM_LOW)
    endtask

endclass

class spi_random_seq extends spi_base_seq;
    `uvm_object_utils(spi_random_seq)
    int num; // test에서 seq.num 직접 지정하기위해 num rand로 생성X

    function new(string name = "spi_random_seq");
        super.new(name);
    endfunction

    task body();
        spi_seq_item item;
        `uvm_info(get_type_name(), $sformatf("random scenario start (%0d repeat)", num), UVM_LOW)
        repeat(num) begin
            item = spi_seq_item::type_id::create("item");
            start_item(item);
            if (!item.randomize())
                `uvm_error("SEQ", "randomize fail")
            finish_item(item);
        end
        `uvm_info(get_type_name(), "random scenario end", UVM_LOW)
    endtask

endclass

class spi_base_test extends uvm_test;
    `uvm_component_utils(spi_base_test)

    spi_env env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = spi_env::type_id::create("env", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
    endfunction

    function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        uvm_top.print_topology();
    endfunction

endclass

class spi_basic_test extends spi_base_test;
    `uvm_component_utils(spi_basic_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        spi_basic_seq seq;
        phase.raise_objection(this);

        seq = spi_basic_seq::type_id::create("seq");
        if (!seq.randomize()) `uvm_error("TEST", "seq randomize fail!")
        seq.start(env.agt.sqr);
        #100;
        phase.drop_objection(this);
    endtask

endclass

class spi_random_test extends spi_base_test;
    `uvm_component_utils(spi_random_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        spi_random_seq seq;
        phase.raise_objection(this);

        seq = spi_random_seq::type_id::create("seq");
        if (!seq.randomize()) `uvm_error("TEST", "seq randomize fail!")
		seq.num = 500;
        seq.start(env.agt.sqr);
        #100;
        phase.drop_objection(this);
    endtask

endclass

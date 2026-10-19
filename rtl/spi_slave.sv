`timescale 1ns / 1ps

module spi_slave(
    // global signals
    input  logic       clk,
    input  logic       reset,
    // internal signals
//    input  logic       cpol,
//    input  logic       cpha,
    input  logic [7:0] tx_data,
    output logic [7:0] rx_data,
    output logic       done,
    output logic       busy,
    // external signals (from master)
    input  logic       sclk,
    input  logic       mosi,
    output logic       miso,
    input  logic       ss_n
);

	// mode 0고정
	localparam CPOL = 1'b0;
	localparam CPHA = 1'b0;

    logic sclk_sync1, sclk_sync2;
    logic mosi_sync1, mosi_sync2;
    logic ss_n_sync1, ss_n_sync2;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            sclk_sync1 <= 0; sclk_sync2 <= 0;
            mosi_sync1 <= 0; mosi_sync2 <= 0;
            ss_n_sync1 <= 1; ss_n_sync2 <= 1;
        end else begin
            sclk_sync1 <= sclk;       sclk_sync2 <= sclk_sync1;
            mosi_sync1 <= mosi;       mosi_sync2 <= mosi_sync1;
            ss_n_sync1 <= ss_n;       ss_n_sync2 <= ss_n_sync1;
        end
    end

	assign busy = ~ss_n_sync2;

    // 상태 정의
    typedef enum logic [1:0] {
        IDLE  = 2'b00,
        DATA,
        STOP
    } spi_slave_state_e;

    spi_slave_state_e state;

    // 내부 신호 
    logic       sclk_prev;       
    logic       ss_n_prev;       
    logic       posedge_sclk;    
    logic       negedge_sclk;    
    logic       ss_n_falling;    

    logic [7:0] tx_shift_reg;
    logic [7:0] rx_shift_reg;
    logic [2:0] bit_cnt;
    logic       cpol_r;
    logic       cpha_r;
    logic       step; 

    // SCLK, SS_N 엣지 검출 
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            sclk_prev <= 1'b0;
            ss_n_prev <= 1'b1; 
        end else begin
            sclk_prev <= sclk_sync2; 
            ss_n_prev <= ss_n_sync2;
        end
    end

    assign posedge_sclk = (sclk_sync2 == 1'b1 && sclk_prev == 1'b0); // 0 -> 1 전환
    assign negedge_sclk = (sclk_sync2 == 1'b0 && sclk_prev == 1'b1); // 1 -> 0 전환
    assign ss_n_falling = (ss_n_sync2 == 1'b0 && ss_n_prev == 1'b1); // 1 -> 0 전환

    logic sample_edge;
    logic shift_edge;

    assign sample_edge = (cpol_r == cpha_r) ? posedge_sclk : negedge_sclk;
    assign shift_edge  = (cpol_r == cpha_r) ? negedge_sclk : posedge_sclk;

    // FSM
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state        <= IDLE;
            miso         <= 1'b1;
            tx_shift_reg <= 0;
            rx_shift_reg <= 0;
            rx_data      <= 0;
            bit_cnt      <= 0;
            done         <= 1'b0;
            cpol_r       <= CPOL;
            cpha_r       <= CPHA;
            step         <= 1'b0;
        end else begin
            done <= 1'b0;
            case (state)

                IDLE: begin
                    miso <= 1'b1;		
                    if (ss_n_falling) begin         
                        state        <= DATA;
                        cpol_r       <= CPOL;       
                        cpha_r       <= CPHA;       
                        tx_shift_reg <= tx_data;    
                        rx_shift_reg <= 8'b0;       
                        bit_cnt      <= 0;
                        step         <= 1'b0;
                        if (CPHA == 1'b0) begin
                            miso <= tx_data[7]; 
                        end
                    end
                end

                DATA: begin
                    if (sample_edge) begin          
                        rx_shift_reg <= {rx_shift_reg[6:0], mosi_sync2};
                        step <= 1'b1;

                        if (bit_cnt == 7) begin     
                            if (cpha_r == 1'b0) begin
                                rx_data <= {rx_shift_reg[6:0], mosi_sync2};
                            end
                            state <= STOP;
                        end
                    end

                    if (shift_edge) begin          
                        if (cpha_r == 1'b1 && step == 1'b0) begin
                            miso         <= tx_shift_reg[7];
                            tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                        end else if (bit_cnt < 7) begin
                            tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                            miso         <= tx_shift_reg[6];
                            bit_cnt      <= bit_cnt + 1;
                        end
                        step <= 1'b0;
                    end
                end

                STOP: begin
                    if (cpha_r == 1'b1) begin
                        rx_data <= rx_shift_reg;
                    end
                    miso  <= 1'b1;
                    done  <= 1'b1;
                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule

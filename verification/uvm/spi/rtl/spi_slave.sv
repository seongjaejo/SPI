
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
    logic       sclk_prev;       // 이전 클럭 엣지 검출용
    logic       ss_n_prev;       // ss_n 엣지 검출용
    logic       posedge_sclk;    // SCLK 상승 엣지 펄스
    logic       negedge_sclk;    // SCLK 하강 엣지 펄스
    logic       ss_n_falling;    // SS_N 하강 엣지 (활성화 시점)
//마스터는 자기가 SCLK을 만들었기 때문에 half_tick으로 타이밍을 알았지만, 
//슬레이브는 외부 SCLK이 언제 바뀌는지 모르기 때문에 엣지를 검출해야 함

    logic [7:0] tx_shift_reg;
    logic [7:0] rx_shift_reg;
    logic [2:0] bit_cnt;
    logic       cpol_r;
    logic       cpha_r;
    logic       step; 
// 마스터의 step: 첫 번째 엣지(샘플)인지 두 번째 엣지(세팅)인지 구분
//슬레이브의 step: CPHA=1일 때 첫 번째 세팅 엣지인지 구분하는 용도만

    // SCLK, SS_N 엣지 검출 
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            sclk_prev <= 1'b0;
            ss_n_prev <= 1'b1; // ss_n 초기값은 high (비활성)
        end else begin
            sclk_prev <= sclk_sync2; // 매 클럭마다 현재값을 이전값으로 저장
            ss_n_prev <= ss_n_sync2;
        end
    end

//시스템 클럭(clk)마다 SCLK의 현재값을 sclk_prev에 저장해요. 그러면 다음 클럭에서 현재값이랑 이전값을 비교할 수 있어요.
//클럭 N  : sclk=0, sclk_prev=0
//클럭 N+1: sclk=1, sclk_prev=0 → posedge_sclk=1 (펄스 발생)
//클럭 N+2: sclk=1, sclk_prev=1 → posedge_sclk=0
    assign posedge_sclk = (sclk_sync2 == 1'b1 && sclk_prev == 1'b0); // 0 -> 1 전환
    assign negedge_sclk = (sclk_sync2 == 1'b0 && sclk_prev == 1'b1); // 1 -> 0 전환
    assign ss_n_falling = (ss_n_sync2 == 1'b0 && ss_n_prev == 1'b1); // 1 -> 0 전환

    // 샘플/세팅 엣지 선택
    // CPOL=0,CPHA=0 → 샘플: posedge, 세팅: negedge
    // CPOL=0,CPHA=1 → 샘플: negedge, 세팅: posedge
    // CPOL=1,CPHA=0 → 샘플: negedge, 세팅: posedge
    // CPOL=1,CPHA=1 → 샘플: posedge, 세팅: negedge
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
                    miso <= 1'b1;		// MISO 기본값 High (버스 놓음)
                    if (ss_n_falling) begin         // SS_N 내려오면 활성화
                        state        <= DATA;
                        cpol_r       <= CPOL;       // cpol 래치
                        cpha_r       <= CPHA;       // cpha 래치
                        tx_shift_reg <= tx_data;    // 보낼 데이터 로드
                        rx_shift_reg <= 8'b0;       // 수신 레지스터 초기화
                        bit_cnt      <= 0;
                        step         <= 1'b0;
                        if (CPHA == 1'b0) begin
                            miso <= tx_data[7]; // CPHA=0이면 첫 엣지 전에 미리 MSB 세팅
                        end
                    end
                end

                DATA: begin
                    if (sample_edge) begin          // 샘플링 엣지
                        rx_shift_reg <= {rx_shift_reg[6:0], mosi_sync2};
                        step <= 1'b1;

                        if (bit_cnt == 7) begin     // 마지막 비트 샘플링
                            if (cpha_r == 1'b0) begin
                                rx_data <= {rx_shift_reg[6:0], mosi_sync2};
                            end
                            state <= STOP;
                        end
                    end

                    if (shift_edge) begin           // 세팅 엣지
                        if (cpha_r == 1'b1 && step == 1'b0) begin
                            // CPHA=1: 첫 번째 세팅 엣지
                            miso         <= tx_shift_reg[7];
                            tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                        end else if (bit_cnt < 7) begin
                            // 다음 비트 MISO에 올리기
                            tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                            miso         <= tx_shift_reg[6];
                            bit_cnt      <= bit_cnt + 1;
                        end
                        step <= 1'b0;
                    end
                end

                STOP: begin
                    // CPHA=1: 마지막 비트는 rx_shift_reg에서 가져옴
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

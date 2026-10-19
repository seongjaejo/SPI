# SPI Master / Slave RTL Design & UVM Verification

**FSM 기반 SPI Master·Slave를 설계하고, 양방향 8비트 데이터 전달을 UVM scoreboard로 비교하는 프로젝트**입니다. Mode 0에서 고정 패턴과 랜덤 데이터를 전송하고, 데이터 범주별 functional coverage를 수집합니다.

- **언어**: SystemVerilog
- **검증 도구**: Synopsys VCS / UVM 1.2 / Verdi
- **하드웨어 검증 환경**: Basys3 / Saleae Logic Analyzer
- **현재 검증 조건**: Mode 0, 8비트, MSB-first, 랜덤 테스트의 `clk_div=4`

[UVM 검증 코드](https://github.com/seongjaejo/SPI/tree/add-spi-uvm/verification/uvm/spi) · [테스트 시나리오](https://github.com/seongjaejo/SPI/tree/add-spi-uvm/verification/uvm/spi/tb)

> UVM 소스는 `add-spi-uvm` 브랜치에 업로드되어 있습니다. `main`에서 `verification/uvm/spi`가 보이지 않으면 위 링크 또는 해당 브랜치를 선택하세요. 아래 UVM 구조·실행 방법은 이 브랜치 기준입니다.

---

## 1. 프로젝트 목표

- Master의 SCLK / SS_N 생성과 Slave의 외부 SPI 신호 수신 구조를 구현한다.
- Master→Slave와 Slave→Master의 데이터 정합성을 각각 확인한다.
- DUT 구동, 관찰, 비교, coverage 측정을 UVM 컴포넌트로 분리한다.
- Directed / constrained-random 시나리오를 재현 가능한 seed로 실행한다.

---

## 2. 아키텍처

```text
tb_top
 ├── spi_if s_if (DRV / MON clocking block)
 ├── spi_top
 │   ├── spi_master ── SCLK / MOSI / MISO / SS_N ── spi_slave
 │   └── Master·Slave TX/RX / done / busy 포트
 └── uvm_test_top
     └── spi_env
         ├── spi_agent
         │   ├── sequencer → spi_driver → TX 데이터 / start
         │   └── spi_monitor → analysis_port
         ├── spi_scoreboard (양방향 데이터 비교)
         └── spi_coverage
```

Driver는 송신 데이터와 설정값을 구동하고 start 펄스를 생성한 뒤 busy 해제를 기다립니다. Monitor는 `master_done`을 기준으로 양쪽 TX/RX를 모아 transaction을 발행합니다.

---

## 3. 파일 구조

```text
SPI/
├── rtl/                   선정된 Master / 동기화된 Slave / 보드 Top
├── constraints/           Master / Slave 핀 제약
├── tb/original/           기존 RTL 테스트벤치
└── verification/
    ├── tb/, evidence/     별도의 로컬 RTL 테스트 / 결과
    └── uvm/spi/           서버 검증 당시 RTL / UVM / Makefile
```

```text
verification/uvm/spi/
├── Makefile
├── rtl/
│   ├── spi_master.sv
│   ├── spi_slave.sv
│   └── spi_top.sv
└── tb/
    ├── spi_if.sv          interface / clocking block / modport
    ├── spi_seq_item.sv    transaction과 constraint
    ├── spi_sequence.sv    directed / random sequence
    ├── spi_driver.sv      DUT 입력 구동
    ├── spi_monitor.sv     완료 시점 관찰 / transaction 재구성
    ├── spi_agent.sv       sequencer / driver / monitor 연결
    ├── spi_scoreboard.sv  데이터 비교 / pass·fail 집계
    ├── spi_coverage.sv    functional coverage
    ├── spi_env.sv         agent / scoreboard / coverage 조립
    ├── spi_test.sv        test 선택 / objection 관리
    ├── spi_pkg.sv         class include 순서 관리
    ├── tb_top.sv             clock / DUT / config_db / FSDB
    └── template.sv           보관된 템플릿
```

`template.sv`는 보관 파일이며 현재 package의 include 대상인지와 실제 컴파일 목록은 `pkg.sv` 및 Makefile을 기준으로 확인합니다.

서버 UVM의 DUT와 루트의 보드용 선정본을 구분해 보존합니다. 두 폴더의 같은 이름 모듈을 한 번에 중복 등록하지 않습니다.

---

## 4. 검증 시나리오

| 테스트 | 전송 수 | 시나리오 |
|---|---|---|
| `spi_basic_test` | 5건 | 00/00, FF/FF, 00/FF, FF/00, 88/CC |
| `spi_random_test` | 500건 | Master TX / Slave TX의 8비트 데이터 랜덤화 |

랜덤 constraint는 `CPOL=0`, `CPHA=0`, `clk_div=4`로 고정합니다. Makefile 기본 테스트는 basic이며, random test는 명시적으로 선택합니다.

Scoreboard는 다음 두 조건을 모두 만족해야 PASS로 집계합니다.

```text
slave_rx_data  === master_tx_data
master_rx_data === slave_tx_data
```

---

## 5. 핵심 구현과 커버리지

| 구현 | 의도 |
|---|---|
| Master / Slave RTL 분리 | 클럭을 만드는 역할과 외부 신호에 응답하는 역할 구분 |
| Transaction에 양쪽 TX/RX 보관 | 전이중 전송을 두 방향으로 비교 |
| `master_done`에서 monitor capture | 완료된 전송 단위로 scoreboard / coverage에 전달 |
| Driver / Monitor clocking block | 구동과 샘플링 시점을 명시 |
| 고정 mode constraint | Slave가 지원하는 Mode 0과 stimulus 범위를 일치시킴 |

| Coverpoint | Bin |
|---|---|
| Master TX | 00 / FF / 01~FE |
| Slave TX | 00 / FF / 01~FE |

`data_etc`는 중간값 범위 전체를 묶은 bin입니다. 이 bin hit를 01~FE의 모든 값 검증으로 해석하지 않습니다. 현재 covergroup에는 mode / clk_div / TX 간 cross가 없습니다.

---

## 6. 검증 결과와 확인 범위

| 구분 | 결과 / 기준 |
|---|---|
| 기존 서버 UVM 검증 기록 | 랜덤 500건, functional coverage 100% (포트폴리오 기준) |
| 기존 실보드 검증 기록 | Basys3 및 Saleae로 SPI 동작 확인 |
| 저장소 정리 시 로컬 RTL 재검증 | 선정한 Master/Slave 조합에서 96건 송수신, 오류 0; clk_div=4/7/49 |

서버 UVM 결과는 기존 포트폴리오에 기록한 결과입니다. 현재 업로드에는 VCS 실행 원본 로그와 functional coverage 보고서가 포함되어 있지 않아, 이 문서 정리 과정에서 해당 수치를 다시 실행·확인한 결과로 표기하지 않았습니다. 아래 실행 명령으로 재현한 뒤 scoreboard 처리 건수, fail count, UVM_ERROR/FATAL 및 coverage report를 함께 확인할 수 있습니다.

Functional coverage 100%는 **현재 정의한 bin을 모두 hit했다는 의미**입니다. 코드 커버리지 100% 또는 프로토콜 전체 검증 완료와는 구분합니다. `verification/evidence/`의 로컬 테스트 기록도 VCS UVM 실행 결과와 별도로 관리합니다.

---

## 7. 실행 방법

VCS / UVM 1.2 / Verdi 및 FSDB 연동 환경이 필요합니다.

```sh
git switch add-spi-uvm
cd verification/uvm/spi
make run TEST=spi_basic_test INFO_LEVEL=UVM_MEDIUM
make run TEST=spi_random_test SEED=1234 INFO_LEVEL=UVM_MEDIUM
verdi -dbdir ./simv.daidir -ssf spi_tb.fsdb
```

Makefile의 wave target에 `//` 주석이 포함되어 있어 파형은 위 Verdi 명령으로 직접 엽니다. 서로 다른 테스트 결과를 비교하려면 실행별 로그와 coverage DB를 보관합니다.

별도의 로컬 RTL 테스트는 저장소 루트에서 `python verification/run_checks.py`로 실행합니다. Master / Slave 실보드 프로젝트를 구성할 때는 해당 Top과 제약 파일 한 쪽을 선택합니다.

---

## 8. 검증 범위와 향후 확장

- 현재 UVM 검증 범위는 Mode 0입니다. Master의 CPHA=1 수신 결과 반영과 다른 모드 검증은 추가 작업입니다.
- 다양한 clk_div, reset 중단, SS_N 비정상 해제, timeout, 연속 프레임을 시나리오와 coverage로 확장할 수 있습니다.
- 완료 건수와 scoreboard 처리 건수를 비교하고 SPI timing assertion을 추가하면 검증 종료 조건을 더 명확하게 할 수 있습니다.
- 루트의 동기화된 Slave도 시스템 클럭 대비 SCLK 속도와 보드 간 타이밍 조건을 확인해야 합니다.

원본 선택 및 로컬 확인 이력은 [SELECTION_AND_VALIDATION.md](SELECTION_AND_VALIDATION.md), 파일 출처는 [SOURCE_MANIFEST.json](SOURCE_MANIFEST.json)에 기록했습니다.

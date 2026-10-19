# SPI Master / Slave

선정 원본: `D:\OndeviceAI2\260612_SPI_master + 260612_SPI_slave`

Top: `spi_master_board_top / spi_slave_board_top`

Mode 0 기준본입니다. Master와 동기화된 Slave의 선정 조합을 테스트했습니다. Master/Slave 제약을 동시에 등록하지 않습니다.

선정 근거와 실제 테스트 범위·알려진 제한은 [검증 기록](SELECTION_AND_VALIDATION.md)을 확인하세요.

## 검증 실행

Icarus Verilog 13과 Python이 필요합니다. 저장소 루트에서 실행합니다.

```sh
python verification/run_checks.py
```

실행한 테스트와 로그는 `verification/`에 있습니다. 실물 보드 재시험·합성·타이밍 검증 완료를 의미하지 않습니다.

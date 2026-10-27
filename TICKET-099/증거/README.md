# 증거 폴더

- 캡처는 `tools\cap <이름>` 으로 찍으면 여기에 `<이름>_<월일_시분초>.png` 로 저장된다.
- 서버 콘솔 원문은 `tools\start` 로 띄웠을 때 `logs/server_<월일_시분초>.log` 로 자동 저장된다.

## 이름 규칙

`<ID>_<before|after|proof|info>_<요약>`

| ID | 뜻 | 예 |
|---|---|---|
| A1~A8 | Part A 결함 | `A3_before_malformed`, `A3_after_malformed` |
| B0~B3 | Part B 측정 | `B0_info_pcinfo`, `B1_before_load_진행`(측정① 원본), `B2_mid_load_결과`(측정② A1 후), `B3_after_load_결과`(측정③ A2 후) |
| C3, C10 … | Part C 의견 번호 증명 | `C3_proof_await` |
| D | git | `D_gitlog` |
| X | 결함 아님을 확인한 것 | `X_burst_정상확인` |

## 찍을 때 체크

- [ ] 창 제목(또는 서버 시작 줄 / TestClient 맨 윗줄)에 **학번·포트**가 보인다
- [ ] 서버 `[통계 학번]` 줄이 보인다
- [ ] 작업표시줄 **시계**가 보인다 (전체 화면)
- [ ] 서버가 죽었으면 **창 닫기 전에** 찍었다
- [ ] before 와 after 를 **같은 시나리오**로 찍었다

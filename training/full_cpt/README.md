# Full-CPT Training Workspace

`Qwen/Qwen3.5-4B-Base` 기반 full fine-tune CPT(Continued Pretraining) 실행을 위한 작업공간입니다.

## 포함 범위

- 학습 엔트리포인트: `training/full_cpt/train.py`
- 실행 스크립트: `training/full_cpt/scripts/run_cpt_train.sh`
- 카파시티 루프: `training/full_cpt/scripts/run_capacity_loop.sh`
- 설정 파일:
  - `training/full_cpt/configs/qwen35_4b_cpt_h100.yaml`
  - `training/full_cpt/configs/quality_rules.yaml`
- 스모크 테스트 데이터/설정:
  - `training/full_cpt/tests/smoke_cpt_config.yaml`
  - `training/full_cpt/tests/smoke_train.jsonl`
  - `training/full_cpt/tests/smoke_valid.jsonl`

## 빠른 시작

```bash
python -m venv .venv
source .venv/bin/activate
pip install -U pip
pip install -r requirements.txt
```

### 1. 오프라인 스모크 테스트

```bash
python -m training.full_cpt.train \
  --config training/full_cpt/tests/smoke_cpt_config.yaml \
  --dry_run
```

`smoke_cpt_config.yaml`은 `model.local_debug_tiny=true`로 설정되어 네트워크 없이 실행 가능합니다.

### 2. 기본 실행

```bash
bash training/full_cpt/scripts/run_cpt_train.sh \
  training/full_cpt/configs/qwen35_4b_cpt_h100.yaml
```

### 3. 체크포인트 재시작

```bash
bash training/full_cpt/scripts/run_cpt_train.sh \
  training/full_cpt/configs/qwen35_4b_cpt_h100.yaml \
  --resume outputs/qwen35_4b_cpt_v2/checkpoint-XXXX
```

### 4. 카파시티 루프

```bash
bash training/full_cpt/scripts/run_capacity_loop.sh \
  training/full_cpt/tests/smoke_cpt_config.yaml
```

결과 요약: `training/full_cpt/tests/capacity_loop/summary.tsv`

## `pack_sequences` 동작 정리

`data.pack_sequences`는 기본적으로 `false`이며, `true`일 때만 시퀀스 패킹이 적용됩니다.

- `pack_sequences: false`
  - 문서별 토크나이즈 + `truncation=True` + `max_seq_length` 초과분 절단
  - 구현 단순, 디버그에 유리
- `pack_sequences: true`
  - 문서별 토크나이즈는 `truncation=False`
  - 이후 여러 샘플을 이어붙여 `max_seq_length` 고정 블록으로 재분할
  - `labels = input_ids`로 CPT(autoregressive next-token) loss 계산
  - 장점: 패딩 낭비 감소, 토큰 효율 향상
  - 주의: 문서 경계 보존이 약해질 수 있음

## 최소 완료 기준

- 통합 코퍼스 1개 버전 이상 준비
- CPT 1회 완주 및 체크포인트 저장
- train/valid loss 추세 확인
- 실행 로그 및 설정 파일 보관

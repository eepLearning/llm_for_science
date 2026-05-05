# Training Workspace (CPT)

`Qwen/Qwen3.5-4B-Base` 기반 CPT(Continued Pretraining) 실행을 위한 최소 작업공간입니다.

## 포함 범위

- 학습 엔트리포인트: `training/train_cpt.py`
- 실행 스크립트: `training/scripts/run_cpt_train.sh`
- 카파시티 루프: `training/scripts/run_capacity_loop.sh`
- 설정 파일:
  - `training/configs/qwen35_4b_cpt_h100.yaml`
  - `training/configs/quality_rules.yaml`
- 스모크 테스트 데이터/설정:
  - `training/tests/smoke_cpt_config.yaml`
  - `training/tests/smoke_train.jsonl`
  - `training/tests/smoke_valid.jsonl`

---

## 빠른 시작

```bash
python -m venv .venv
source .venv/bin/activate
pip install -U pip
pip install -r requirements.txt
```

### 1) 기본 실행

```bash
bash training/scripts/run_cpt_train.sh training/configs/qwen35_4b_cpt_h100.yaml
```

### 2) 체크포인트 재시작

```bash
bash training/scripts/run_cpt_train.sh \
  training/configs/qwen35_4b_cpt_h100.yaml \
  --resume outputs/qwen35_4b_cpt_v2/checkpoint-XXXX
```

### 3) 오프라인 스모크 테스트

```bash
python -m training.train_cpt --config training/tests/smoke_cpt_config.yaml --dry_run
```

`smoke_cpt_config.yaml`은 `model.local_debug_tiny=true`로 설정되어 네트워크 없이 실행 가능합니다.

### 4) 카파시티 루프

```bash
bash training/scripts/run_capacity_loop.sh training/tests/smoke_cpt_config.yaml
```

결과 요약: `training/tests/capacity_loop/summary.tsv`

---

## 최소 완료 기준 (MVP)

- 통합 코퍼스 1개 버전 이상 준비
- CPT 1회 완주 및 체크포인트 저장
- train/valid loss 추세 확인
- 실행 로그 및 설정 파일 보관

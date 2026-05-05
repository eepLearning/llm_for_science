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

### 1-1. 실제 모델 로드 후 1-step 검증

오프라인 스모크와 달리, 아래 설정은 `Qwen/Qwen3.5-4B-Base`를 실제로 로드합니다.

```bash
bash training/full_cpt/scripts/run_cpt_train.sh \
  training/full_cpt/configs/qwen35_4b_cpt_model_load_postcheck_1step.yaml
```

이 검증은 다음을 확인합니다.

- Hugging Face에서 모델/토크나이저 실제 로드 가능 여부
- 1-step forward/backward/optimizer/update/save/eval 최소 경로 정상 동작

주의:

- `training/full_cpt/tests/smoke_*.jsonl`을 데이터로 쓰므로 코퍼스 품질 검증용이 아니라 런타임 경로 검증용입니다.
- GPU/네트워크/권한 상태에 따라 실패할 수 있습니다.

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

## 문서 기준 반영 체크 (Qwen3.5 CPT)

아래는 운영 가이드 문서 기준으로 현재 코드/설정에 반영한 항목입니다.

- 반영됨
  - `labels = input_ids` 기반 CPT(next-token loss)
  - `pack_sequences` 경로 구현(문서 concat 후 block 분할)
  - `optimizer.name`을 `TrainingArguments.optim`으로 연결
  - `runtime.tf32` 지원
  - `model.attn_implementation` 지원(`sdpa`/`flash_attention_2`)
  - `gradient_checkpointing_kwargs` 지원
  - `runtime.deepspeed_config` 지원
- 의도적으로 기본 미적용
  - `flash_attention_2` 강제 기본값: 설치/환경 의존성이 있어 기본은 `sdpa`
  - DeepSpeed offload 기본 활성화: 단일 H100 4K 기준은 offload 없이 먼저 검증
  - vision branch 별도 freeze 로직: 현재 엔트리포인트는 `AutoModelForCausalLM` 경로 중심

## 권장 실행 순서

1. 안정형 시작:
   - `training/full_cpt/configs/qwen35_4b_cpt_h100_stable_4k.yaml`
2. 장문맥 실험:
   - `training/full_cpt/configs/qwen35_4b_cpt_h100_longctx_8k.yaml`
3. OOM 완화:
   - `training/full_cpt/configs/qwen35_4b_cpt_h100_oom_safe_2k_bnb8.yaml`
4. 마지막 fallback:
   - `runtime.deepspeed_config: training/full_cpt/configs/ds_zero2_offload.json`

## 학습이 잘 안될 때 빠른 대응

- OOM:
  - `max_seq_length` 8192 → 4096 → 2048
  - `optimizer.name`을 `adamw_bnb_8bit`로 변경
- loss 진동/발산:
  - `learning_rate`를 절반으로 감소
  - `warmup_ratio` 증가(예: 0.03 → 0.05)
- 처리량 저하:
  - `attn_implementation: sdpa`로 고정 후 기준선 확인
  - dataloader worker 수를 시스템 I/O에 맞춰 조정

## 최소 완료 기준

- 통합 코퍼스 1개 버전 이상 준비
- CPT 1회 완주 및 체크포인트 저장
- train/valid loss 추세 확인
- 실행 로그 및 설정 파일 보관

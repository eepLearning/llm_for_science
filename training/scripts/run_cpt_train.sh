#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <config_yaml> [--resume <checkpoint_path>]"
  exit 1
fi

CONFIG_PATH="$1"
shift || true

RESUME_ARGS=()
if [[ "${1:-}" == "--resume" ]]; then
  if [[ -z "${2:-}" ]]; then
    echo "[ERROR] --resume requires a checkpoint path"
    exit 1
  fi
  RESUME_ARGS=(--resume_from_checkpoint "$2")
  shift 2 || true
fi

export CUDA_DEVICE_MAX_CONNECTIONS=1
export TOKENIZERS_PARALLELISM=false
export PYTHONUNBUFFERED=1

TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
RUN_LOG_DIR="logs/cpt"
mkdir -p "${RUN_LOG_DIR}"

RUN_LOG="${RUN_LOG_DIR}/train_${TIMESTAMP}.log"

echo "[INFO] Starting CPT training"
echo "[INFO] Config: ${CONFIG_PATH}"
echo "[INFO] Log: ${RUN_LOG}"

python -m training.train_cpt \
  --config "${CONFIG_PATH}" \
  "${RESUME_ARGS[@]}" \
  2>&1 | tee "${RUN_LOG}"

echo "[INFO] Training finished."

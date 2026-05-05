#!/usr/bin/env bash
set -euo pipefail

# Capacity loop for quick resource-fit checks.
# It runs multiple short dry-runs while mutating selected trainer/data knobs.

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <base_config_yaml>"
  exit 1
fi

BASE_CONFIG="$1"
OUT_DIR="training/tests/capacity_loop"
LOG_DIR="logs/cpt/capacity_loop"
mkdir -p "$OUT_DIR" "$LOG_DIR"

# seq_len, grad_accum, train_bs
CASES=(
  "64,1,1"
  "128,2,1"
  "256,4,1"
)

SUMMARY="$OUT_DIR/summary.tsv"
echo -e "case\tseq_len\tgrad_accum\tbatch\tstatus\tlog" > "$SUMMARY"

i=0
for case in "${CASES[@]}"; do
  i=$((i+1))
  IFS=',' read -r SEQ GA BS <<< "$case"

  CFG="$OUT_DIR/case_${i}.yaml"
  LOG="$LOG_DIR/case_${i}.log"

  python - <<PY
import yaml
from copy import deepcopy
cfg = yaml.safe_load(open("$BASE_CONFIG", "r", encoding="utf-8"))
cfg = deepcopy(cfg)
cfg["run"]["output_dir"] = "training/tests/capacity_loop/out_case_${i}"
cfg["data"]["max_seq_length"] = int("$SEQ")
cfg["trainer"]["gradient_accumulation_steps"] = int("$GA")
cfg["trainer"]["per_device_train_batch_size"] = int("$BS")
with open("$CFG", "w", encoding="utf-8") as f:
    yaml.safe_dump(cfg, f, sort_keys=False, allow_unicode=True)
PY

  status="PASS"
  if ! python -m training.train_cpt --config "$CFG" --dry_run > "$LOG" 2>&1; then
    status="FAIL"
  fi

  echo -e "case_${i}\t${SEQ}\t${GA}\t${BS}\t${status}\t${LOG}" >> "$SUMMARY"
  echo "[capacity-loop] case_${i}: ${status}"
done

echo "Summary: $SUMMARY"
cat "$SUMMARY"

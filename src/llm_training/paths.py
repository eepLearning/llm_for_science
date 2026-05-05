"""Shared repository paths for training code."""

from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
DATA_DIR = REPO_ROOT / "data"
TRAINING_DIR = REPO_ROOT / "training"
TRAINING_CONFIG_DIR = TRAINING_DIR / "configs"
TRAINING_SCRIPT_DIR = TRAINING_DIR / "scripts"
TRAINING_RUN_DIR = TRAINING_DIR / "runs"
TRAINING_CHECKPOINT_DIR = TRAINING_DIR / "checkpoints"

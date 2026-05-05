# llm_for_science

과학 분야 논문 코퍼스를 구축하고, 해당 코퍼스로 Qwen 계열 full fine-tune CPT를 실행하기 위한 작업공간입니다.

현재 `pipeline/`의 수집/파싱 기준은 담당 범위인 화학 분야에 맞춰져 있습니다. 학습 워크스페이스는 화학에 한정하지 않고 과학 분야 코퍼스 전체를 대상으로 확장하는 것을 전제로 둡니다.

## 구조

```text
.
├── main.py                  # 데이터 파이프라인 CLI
├── pipeline/                # 수집, PDF/LaTeX 파싱, dedup, eval 구현
├── training/
│   └── full_cpt/            # full fine-tune CPT 학습 코드/설정/스크립트
├── docs/                    # 상세 문서
├── keywords/                # 도메인 키워드
├── data/                    # 로컬 데이터 산출물, git 제외
└── logs/                    # 실행 로그, git 제외
```

## 빠른 실행

```bash
python -m venv .venv
source .venv/bin/activate
pip install -U pip
pip install -r requirements.txt
```

데이터 파이프라인:

```bash
python main.py arxiv --years 2000-2025
python main.py arxiv-latex --resume --workers 8
python main.py clean
python -m pipeline.batch_parse_pdfs --backend pymupdf4llm --workers 4 --chunk 500
python main.py dedup
python main.py index
python main.py eval
```

Full-CPT 스모크 테스트:

```bash
python -m training.full_cpt.train \
  --config training/full_cpt/tests/smoke_cpt_config.yaml \
  --dry_run
```

Full-CPT 실험 실행:

```bash
bash training/full_cpt/scripts/run_cpt_train.sh \
  training/full_cpt/configs/qwen35_4b_cpt_h100.yaml
```

## 문서

- [프로젝트 상세 가이드](docs/PROJECT_GUIDE.md)
- [PDF 파싱 가이드](docs/PDF_PARSING_GUIDE.md)
- [Full-CPT 학습 가이드](training/full_cpt/README.md)

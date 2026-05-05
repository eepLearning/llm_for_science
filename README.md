# llm_for_science

현대 화학 논문 코퍼스를 구축하고, 그 코퍼스로 LLM CPT(Continued Pretraining)를 실행하기 위한 작업공간입니다.

이 저장소는 두 영역으로 나뉩니다.

- `data pipeline`: arXiv/Semantic Scholar 수집, LaTeX/PDF 파싱, 중복 제거, DuckDB 인덱싱, 품질 평가
- `training`: Qwen 계열 causal LM CPT 실행, 스모크 테스트, 카파시티 루프

---

## 현재 상태

### 데이터 구축 결과 (2026-04-09 기준)

| 단계 | 상태 | 결과 |
|------|------|------|
| arXiv 메타데이터 수집 | 완료 | 254,376건 (9개 카테고리, 2000~2025) |
| arXiv LaTeX/PDF 다운로드 | 완료 | 167,895건 LaTeX + 48,652건 PDF |
| LaTeX -> plain text 클리닝 | 완료 | 잔존율 0.000% |
| PDF 배치 파싱 | 완료 | 48,630건 성공 / 22건 실패 |
| Semantic Scholar 보충 | 미시작 | API key 및 범위 합의 필요 |
| 중복 제거 | 완료 | hash 30,140건 + fuzzy 중복 제거 |
| DuckDB 인덱싱 | 완료 | `data/index.db` |
| Eval 점수화 | 완료 | 96.8/100 |

### 본문 확보 현황

| source_type | 건수 | 설명 |
|-------------|------|------|
| `arxiv_latex` | 167,895 | LaTeX 원본 |
| `arxiv_pdf_pymupdf4llm` | 54,728 | PDF -> Markdown 파싱 |
| `arxiv_pdf_saved` | 415 | PDF 파싱 실패 또는 raw PDF 보관 |
| `NULL` | 1,089 | abstract만 보유 |
| 합계 | 224,161 | Full-text 확보율 99.3% |

### 학습 워크스페이스

| 항목 | 상태 | 위치 |
|------|------|------|
| CPT 엔트리포인트 | 준비됨 | `training/train_cpt.py` |
| H100용 예시 설정 | 준비됨 | `training/configs/qwen35_4b_cpt_h100.yaml` |
| 오프라인 스모크 테스트 | 준비됨 | `training/tests/smoke_cpt_config.yaml` |
| 카파시티 루프 | 준비됨 | `training/scripts/run_capacity_loop.sh` |

`data/`와 `outputs/` 아래의 대용량 산출물은 로컬/외부 산출물이며, 저장소에 모두 포함되어 있지 않을 수 있습니다. 처음 환경을 잡을 때는 스모크 테스트로 실행 환경을 먼저 확인하세요.

---

## 저장소 구조

```text
.
├── main.py                         # 데이터 파이프라인 CLI
├── config.py                       # 수집 카테고리, rate limit, 연도 범위
├── schema.py                       # Parquet 스키마 + PaperRecord
├── utils.py                        # 공통 I/O, retry, rate limit, checkpoint
├── arxiv_crawler.py                # arXiv 메타데이터/LaTeX/PDF 수집
├── semantic_scholar_crawler.py     # Semantic Scholar 보충 수집
├── latex_cleaner.py                # LaTeX -> plain text 클리닝
├── batch_parse_pdfs.py             # PDF 배치 파싱
├── pdf_parser.py                   # PDF parser wrapper
├── dedup.py                        # hash/fuzzy 중복 제거
├── eval_scorer.py                  # 데이터셋 품질 점수화
├── stats_report.py                 # 통계 리포트
├── keyword_extractor.py            # 키워드 추출 유틸리티
├── recover_failed.py               # 실패분 복구
├── post_parse_pipeline.sh          # PDF 파싱 이후 index/dedup/eval 실행
├── wait_and_parse.sh               # 대기 후 PDF 파싱 실행 보조 스크립트
├── requirements.txt                # 공통 Python 의존성
├── training/
│   ├── train_cpt.py                # CPT 학습 엔트리포인트
│   ├── configs/                    # 재현 가능한 학습 설정
│   ├── scripts/                    # 학습/카파시티 실행 스크립트
│   └── tests/                      # 오프라인 스모크 테스트 데이터
├── src/llm_training/               # 학습용 공유 패키지
├── docs/                           # PDF 파싱 가이드 및 비교 자료
├── keywords/                       # 도메인 키워드
├── data/                           # 로컬 데이터 산출물
└── logs/                           # 실행 로그
```

현재는 데이터 파이프라인 모듈이 루트에 있고, 학습 코드는 `training/` 아래에 있습니다. 데이터 파이프라인이 더 커지면 `src/llm_for_science/` 또는 `src/paper_pipeline/`로 패키징하는 것이 다음 정리 단계입니다.

---

## 설치

```bash
python -m venv .venv
source .venv/bin/activate
pip install -U pip
pip install -r requirements.txt
```

PDF 파서별 추가 의존성은 필요할 때 설치합니다.

```bash
pip install pymupdf4llm
pip install docling
pip install mineru
```

---

## 데이터 파이프라인 실행

### 전체 흐름

```text
arXiv categories
  -> metadata crawl
  -> LaTeX/PDF download
  -> LaTeX cleaning
  -> PDF parsing
  -> optional Semantic Scholar supplement
  -> dedup
  -> DuckDB index
  -> eval/stats
```

### 주요 명령

```bash
# 1. arXiv 메타데이터 수집
python main.py arxiv --years 2000-2025

# 2. LaTeX + PDF 다운로드
python main.py arxiv-latex --resume --workers 8

# 3. LaTeX 클리닝
python main.py clean

# 4. PDF 배치 파싱
python batch_parse_pdfs.py --backend pymupdf4llm --workers 4 --chunk 500

# 5. 중복 제거
python main.py dedup

# 6. DuckDB 인덱싱
python main.py index

# 7. 품질 평가
python main.py eval

# 8. 통계 리포트
python main.py stats
```

PDF 파싱 상세는 [docs/PDF_PARSING_GUIDE.md](docs/PDF_PARSING_GUIDE.md)를 참고하세요.

---

## CPT 학습 실행

### 실행 환경 확인

```bash
python -m training.train_cpt --config training/tests/smoke_cpt_config.yaml --dry_run
```

`training/tests/smoke_cpt_config.yaml`은 `model.local_debug_tiny=true`를 사용하므로 네트워크 없이 동작합니다.

### 실데이터 CPT 실행

`training/configs/qwen35_4b_cpt_h100.yaml`은 다음 JSONL 파일이 준비되어 있다고 가정합니다.

```bash
data/processed/corpus_v1/train.jsonl
data/processed/corpus_v1/valid.jsonl
```

기본 설정은 W&B 로깅(`report_to: ["wandb"]`)을 사용합니다. W&B를 쓰지 않는 환경에서는 설정 파일에서 `report_to: []`로 바꿔 실행하세요.

```bash
bash training/scripts/run_cpt_train.sh training/configs/qwen35_4b_cpt_h100.yaml
```

### 체크포인트 재시작

```bash
bash training/scripts/run_cpt_train.sh \
  training/configs/qwen35_4b_cpt_h100.yaml \
  --resume outputs/qwen35_4b_cpt_v2/checkpoint-XXXX
```

### 카파시티 루프

```bash
bash training/scripts/run_capacity_loop.sh training/tests/smoke_cpt_config.yaml
```

결과 요약은 `training/tests/capacity_loop/summary.tsv`에 저장됩니다.

---

## 데이터 산출물

```text
data/
├── arxiv/
│   ├── year=YYYY/                  # 메타데이터 및 full_text parquet
│   └── pdfs/                       # PDF 원본
├── merged/                         # dedup 후 최종 데이터셋
├── processed/                      # 학습용 JSONL 코퍼스
├── checkpoints/                    # 크롤링/파싱 진행 상태
└── index.db                        # DuckDB 인덱스
```

현재 `main.py index`는 `data/arxiv/**/*.parquet`를 대상으로 DuckDB 뷰를 생성합니다. dedup 이후의 `data/merged/`를 쿼리 대상으로 삼으려면 인덱싱 로직을 별도로 확장해야 합니다.

DuckDB 쿼리 예시:

```bash
python main.py query "SELECT full_text_source_type, COUNT(*) FROM papers GROUP BY 1 ORDER BY 2 DESC"
python main.py query "SELECT * FROM papers WHERE title LIKE '%catalyst%' LIMIT 10" --output results.csv
```

---

## 품질 평가

최종 Eval Score: 96.8/100

```text
Schema Completeness     10.0/10 (x15%)
Full-text Coverage       8.8/10 (x20%)
LaTeX Parse Quality     10.0/10 (x20%)
Metadata Accuracy       10.0/10 (x10%)
Dedup Effectiveness     10.0/10 (x10%)
Language Purity         10.0/10 (x5%)
Token Distribution       9.4/10 (x10%)
Hash Uniqueness         10.0/10 (x10%)
```

---

## 중복 제거 우선순위

| 순위 | source_type | 설명 |
|------|-------------|------|
| 0 | `arxiv_latex` | LaTeX 원본 |
| 1 | `arxiv_pdf_mineru` | MinerU GPU 파서 |
| 2 | `arxiv_pdf_docling` | Docling CPU 파서 |
| 3 | `arxiv_pdf_pymupdf4llm` | pymupdf4llm |
| 4 | `arxiv_pdf_pymupdf` | PyMuPDF 베이스라인 |
| 5 | `arxiv_pdf_saved` | raw PDF |
| 9 | `NULL` | abstract만 |

---

## 대상 arXiv 카테고리

arXiv에는 전용 Chemistry 카테고리가 없어 화학 논문은 physics, cond-mat, q-bio, cs 등에 분산되어 있습니다.

| 카테고리 | 분야 |
|----------|------|
| `physics.chem-ph` | 화학물리 |
| `cond-mat.mtrl-sci` | 재료과학 |
| `physics.atm-clus` | 원자/분자 클러스터 |
| `cond-mat.soft` | 연성물질 |
| `physics.comp-ph` | 계산물리/계산화학 |
| `physics.bio-ph` | 생물물리화학 |
| `q-bio.BM` | 생체분자 |
| `physics.atom-ph` | 원자물리/분광학 |
| `cs.CE` | 화학정보학 |

---

## 관련 문서

- [training/README.md](training/README.md): CPT 학습 워크스페이스 상세
- [docs/PDF_PARSING_GUIDE.md](docs/PDF_PARSING_GUIDE.md): PDF 파서 비교 및 교체 방법
- [training/configs/README.md](training/configs/README.md): 학습 설정 파일 관리 원칙
- [training/scripts/README.md](training/scripts/README.md): 학습 실행 스크립트 관리 원칙

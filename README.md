# pdf-parser-only

저장된 학술 PDF를 Markdown 또는 텍스트로 변환하는 파서 모듈만 분리한 브랜치입니다.
크롤러, 중복 제거, 평가, 운영 메모 문서는 제외했습니다.

## 포함 파일

- `batch_parse_pdfs.py`: 대량 PDF 배치 파싱, 체크포인트, 크래시 복구
- `pdf_parser.py`: 파서 함수 묶음과 비교 유틸리티
- `latex_cleaner.py`: PDF/LaTeX 정제 함수
- `config.py`: 경로 및 공용 설정
- `utils.py`: 로깅, parquet I/O, 언어 감지 등 공용 유틸리티
- `schema.py`: parquet 스키마 정의
- `docs/PDF_PARSING_GUIDE.md`: 파서 선택 및 교체 가이드

## 설치

```bash
pip install -r requirements.txt
pip install pymupdf4llm
```

선택 설치:

```bash
pip install docling
pip install mineru
```

## 사용법

배치 파싱:

```bash
python batch_parse_pdfs.py --backend pymupdf4llm --workers 4 --chunk 500
```

특정 source type 결과 교체:

```bash
python batch_parse_pdfs.py \
  --backend docling \
  --replace-source arxiv_pdf_pymupdf4llm \
  --workers 4
```

파이썬에서 직접 사용:

```python
from pdf_parser import parse_pdfs_batch

stats = parse_pdfs_batch(backend="docling", workers=2)
print(stats)
```

## 데이터 경로

기본 경로는 저장소 루트 기준으로 아래를 사용합니다.

```text
data/arxiv/**/*.parquet
data/arxiv/pdfs/*.pdf
data/checkpoints/
logs/
```

필요한 상세 비교와 백엔드 설명은 [docs/PDF_PARSING_GUIDE.md](docs/PDF_PARSING_GUIDE.md)를 참고하면 됩니다.

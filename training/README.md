# Training Workspace

이 디렉터리는 LLM CPT 학습 작업 전용입니다.

원칙:

- 기존 크롤러/정제 파이프라인 코드는 루트 스크립트에 유지합니다.
- 학습 코드는 `src/llm_training/` 패키지에 둡니다.
- 버전 관리가 필요한 설정만 `training/configs/`에 둡니다.
- 실행 편의용 쉘 스크립트만 `training/scripts/`에 둡니다.
- 대용량 산출물은 `training/runs/`, `training/checkpoints/`에 두고 git에는 올리지 않습니다.

초기 구조:

```text
training/
├── configs/
├── scripts/
├── runs/
└── checkpoints/
```

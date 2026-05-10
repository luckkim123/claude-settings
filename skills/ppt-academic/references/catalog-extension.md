# Catalog Extension — 학술 발표용 mckinsey 템플릿 매핑

mckinsey-pptx의 40개 템플릿을 **학술 발표 use case**에 매핑한 가이드.
원본 카탈로그(`${CLAUDE_PLUGIN_ROOT}/mckinsey_pptx/agent/CATALOG.md`)가 진실의
원천이며, 이 파일은 **학술 시나리오에서의 권장 사용법**을 추가로 제공한다.

---

## 학술 시퀀스별 권장 템플릿

### Cover / 표지
- **`cover_slide`** ⭐ — 표준 학술 표지에 적합

### Background / 도입
- **`executive_summary_paragraph`** — 2~4 문단 서술형 배경
- **`overview_areas`** — 5개 이상 분야 개관
- **`stat_hero`** — "현재 X% 정확도, but ~" 같은 큰 숫자로 도입

### Research Question / 핵심 질문
- **`dark_navy_summary`** ⭐ — 단일 임팩트 메시지에 가장 적합
- **`quote_slide`** — 인용 + 본인 RQ로 prelude

### Related Work / 선행 연구
- **`comparison_table`** ⭐ — Harvey balls로 5개 항목 X 5개 메서드 매트릭스
- **`two_column_compare`** — 2개 메서드 비교만 필요할 때
- **`three_trends_table`** — 3개 메서드의 정의/특징/한계

### Methodology / 제안 방법
- **`process_flow_horizontal`** ⭐ — 좌→우 단계별 파이프라인
- **`phases_chevron_3`** — 3단계 명확한 시퀀스
- **`issue_tree`** — 계층적 분해 (top-down)
- **`org_chart`** — 모듈 간 관계 (트리)
- **`pipeline`** — 데이터 흐름 (process_flow와 유사하지만 더 추상적)

### Experiments / 실험 설정
- **`assessment_table`** ⭐ — 데이터셋/메트릭/베이스라인 매트릭스
- **`process_activities`** — 실험 단계별 활동
- **`agenda`** — 실험 섹션 개요 (5개 이상)

### Results / 결과
- **`column_simple_growth`** ⭐ — 베이스라인 vs 제안 비교 (카테고리)
- **`column_historic_forecast`** — 시계열 결과 (training curve 등)
- **`column_comparison`** — 카테고리별 막대 비교
- **`bubble_chart`** — 2차원 관계 (정확도 vs 속도)
- **`growth_share`** / `bcg_matrix` — 4분면 분류
- **`prioritization_matrix`** — 9개 모델의 X×Y 분류
- **`stacked_column`** — 누적 기여도 (ablation 시각화)
- **`grouped_column`** — 카테고리 X 메서드 다중 비교
- **`line_chart`** — 시계열 또는 hyperparameter sweep

### Discussion / 논의
- **`pros_cons`** — 본 연구의 장단점
- **`executive_summary_takeaways`** — 3개 takeaway + bullet

### Conclusion / 결론
- **`executive_summary_takeaways`** ⭐ — 학술 디펜스의 가장 흔한 패턴
- **`dark_navy_summary`** — 단일 강력한 메시지

### Q&A / 마무리
- **`quote_slide`** — 감사 메시지 + 인용

### Appendix / 부록
- **`agenda`** — 부록 섹션 목차
- 다양한 차트 템플릿 추가 결과/ablation 보충

---

## 템플릿 선택 디시전 트리

### "결과를 보여줄 때" 어떤 차트?

```
데이터가 시계열인가?
├─ Yes → 추가 카테고리 있나?
│        ├─ Yes (예: train/val/test) → line_chart
│        └─ No → column_historic_forecast
└─ No → 카테고리가 몇 개?
        ├─ 2~4개, 단일 비교 → column_simple_growth
        ├─ 5~10개, 카테고리 X 메서드 → grouped_column
        ├─ 누적 기여도 (ablation) → stacked_column
        └─ 2차원 관계 (정확도 vs 속도) → bubble_chart
```

### "방법론을 설명할 때" 어떤 다이어그램?

```
구조가 어떤가?
├─ 좌→우 순차 흐름 → process_flow_horizontal
├─ 정확히 3단계 → phases_chevron_3
├─ 4단계 이상 → phases_table_4 또는 waves_timeline_4
├─ 트리/계층 → org_chart 또는 issue_tree
└─ 사이클/반복 → process_activities (또는 직접 그리기)
```

### "여러 메서드를 비교할 때"?

```
메서드 수?
├─ 2개 → two_column_compare
├─ 3~5개 → comparison_table (Harvey balls)
└─ 5개 이상 → 매트릭스 너무 빽빽 — 텍스트 표 또는 분할
```

---

## 흔한 실수 (학술 시나리오)

1. **`bubble_chart` 남용**:
   - ❌ 단순 비교에 bubble 사용 → 직관 떨어짐
   - ✅ 정확한 의미가 있을 때만 (X×Y, 크기는 N)

2. **`org_chart`로 데이터 흐름 표현**:
   - ❌ 데이터 파이프라인을 org_chart로
   - ✅ `process_flow_horizontal` 사용

3. **`column_historic_forecast`로 ablation 결과**:
   - ❌ 시계열 아닌데 historic 사용
   - ✅ ablation은 `stacked_column` 또는 `grouped_column`

4. **`executive_summary_takeaways`에 5개 이상**:
   - ❌ 5~6개 takeaway → 청중 못 따라옴
   - ✅ 3개로 압축, 필요하면 다음 슬라이드로

5. **`agenda` 슬라이드 추가**:
   - 학회 발표(10~15분)에는 agenda 보통 X
   - 디펜스(20분+)에는 agenda 1장 OK

---

## Korean Theme 적용

한국어 deck은 항상 KO_THEME 사용:

```python
from dataclasses import replace
from mckinsey_pptx import DEFAULT_THEME
from mckinsey_pptx.theme import Typography

KO_THEME = replace(
    DEFAULT_THEME,
    typography=replace(DEFAULT_THEME.typography, family="Apple SD Gothic Neo"),
    copyright_text="ⓒ 2026 김승민"  # 사용자 이름/소속
)

b = PresentationBuilder(theme=KO_THEME, default_section_marker="…")
```

Apple SD Gothic Neo는 Mac 기본 한국어 폰트. Windows에서는 "Malgun Gothic"으로
대체될 수 있음 (mckinsey 빌더가 자동 fallback).

---

## 시각 검증 후 자주 발견되는 문제

| 문제 | 원인 | 수정 |
|:---|:---|:---|
| 텍스트가 카드 경계 밖으로 | 한글 1.3배 폭 무시 | bullet ≤ 6단어로 줄임 |
| 제목이 underline rule과 겹침 | 제목 ≥ 50자 | 줄여서 한 줄에 들어가게 |
| 차트 라벨 겹침 | x축 카테고리 ≥ 7개 | 카테고리 줄이거나 회전 |
| `[Description]` 리터럴 표시 | description 인자 누락 | 차트 템플릿에 description 필수 |
| `[Insert ...]` 표시 | placeholder 그대로 둠 | 실제 값 또는 "[N/A]"로 명시 |

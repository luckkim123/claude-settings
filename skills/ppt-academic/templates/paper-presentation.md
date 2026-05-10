# Template: Paper Presentation (학회 oral)

**Use when:**
- 학회 oral presentation (CVPR, NeurIPS, ICLR 등)
- 저널 발표
- 청중: 같은 분야 전문 연구자

**Time/Slides:**
- 12분 발표 + 3분 Q&A: 8~10장
- 15분 발표 + 5분 Q&A: 10~12장
- 짧은 spotlight (5분): 3~5장

---

## 표준 시퀀스 (12분 / 10장 기준)

### Section 1: Title (1장)
```python
b.add("cover_slide",
      title="<논문 제목>",
      subtitle="<학회 / 저널>",
      author="<저자> et al.",
      affiliation="<기관>",
      date="2026")
```

### Section 2: Motivation (1~2장)

**Slide 2 — 문제 제기 (큰 숫자 또는 직관적 비유)**
```python
b.add("stat_hero",
      title="현재의 한계",
      stat="O(N²)",
      stat_label="Self-attention 메모리 복잡도",
      description="시퀀스 길이가 1000일 때 100만 곱셈 — 긴 문서에서 비현실적")
```

또는:
```python
b.add("dark_navy_summary",
      title="문제",
      message="LLM 추론 시 KV cache가 GPU 메모리의 80%를 차지한다",
      supporting_points=[
          "Llama-70B: 80GB 중 65GB",
          "일반 GPU(24GB)로는 8K context도 어려움",
      ])
```

### Section 3: Contribution (1장) — 핵심
```python
b.add("three_trends_numbered",
      title="본 논문의 기여",
      trends=[
          {"name": "<기여 1: 1줄 요약>",
           "description": "<상세 1문장>"},
          {"name": "<기여 2>",
           "description": "<상세>"},
          {"name": "<기여 3>",
           "description": "<상세>"},
      ])
```

**원칙**: 정확히 3개. 5개면 청중 못 따라옴, 1개면 너무 thin.

### Section 4: Method (2~3장)

**Slide 4-1: Method overview (한 장에 핵심 다이어그램)**
```python
b.add("process_flow_horizontal",
      title="제안 방법",
      steps=[
          {"title": "Input", "description": "Sequence X"},
          {"title": "Compress", "description": "K-means clustering"},
          {"title": "Attend",   "description": "O(N log N) attention"},
          {"title": "Output",   "description": "Context vector"},
      ])
```

**Slide 4-2: Key insight (수식 또는 핵심 차이)**
```python
b.add("two_column_compare",
      title="핵심 차이",
      left={"title": "기존 attention",
            "bullets": ["모든 토큰 쌍 계산",
                       "O(N²) 복잡도",
                       "긴 문서 비효율"]},
      right={"title": "제안 방법",
             "bullets": ["클러스터로 그룹화",
                         "O(N log N) 복잡도",
                         "정확도 손실 < 1%"]})
```

**Slide 4-3 (선택): 알고리즘 의사코드**
- mckinsey 템플릿보다 직접 텍스트 상자가 나을 수 있음
- 또는 `executive_summary_paragraph`로 의사코드 서술

### Section 5: Results (2~3장)

**Slide 5-1: Main result**
```python
b.add("column_comparison",
      title="Main Results — Long-doc QA",
      categories=["NaturalQ", "TriviaQA", "HotpotQA"],
      series=[
          {"name": "Baseline (Llama-7B)", "values": [42.1, 65.3, 38.7]},
          {"name": "본 연구",            "values": [44.8, 67.2, 41.3]},
      ],
      description="제안 방법 적용 시 평균 +2.4%",
      takeaway_header="긴 문서에서 일관된 향상")
```

**Slide 5-2: Efficiency**
```python
b.add("bubble_chart",
      title="Quality vs Efficiency",
      bubbles=[
          {"label": "Llama-7B (full)", "x": 1.0, "y": 100, "size": 60},
          {"label": "Sparse Attn",    "x": 2.5, "y": 92,  "size": 45},
          {"label": "본 연구",        "x": 3.8, "y": 99,  "size": 60},
      ],
      x_axis="Speedup", y_axis="Quality retention (%)",
      takeaway_header="3.8x 빠르면서 품질 99% 유지")
```

**Slide 5-3 (선택): Ablation**
```python
b.add("stacked_column_chart",
      title="Ablation Study",
      categories=["Baseline", "+ Cluster", "+ Adaptive K", "Full"],
      series=[{"name": "Δ Accuracy",
               "values": [0, 0.8, 1.2, 2.4]}],
      description="각 컴포넌트의 누적 기여도",
      takeaway_header="Adaptive K가 가장 큰 기여 (+1.6%)")
```

### Section 6: Conclusion (1장)
```python
b.add("executive_summary_takeaways",
      title="요약",
      sections=[
          {"takeaway": "O(N²) → O(N log N) 메모리 효율",
           "bullets": ["3.8x speedup", "품질 99% 유지"]},
          {"takeaway": "긴 문서 QA에서 일관된 향상",
           "bullets": ["3개 데이터셋 평균 +2.4%"]},
          {"takeaway": "Open-source 공개",
           "bullets": ["github.com/<repo>"]},
      ])
```

---

## 변형 규칙

### Spotlight (5분, 3~5장)

극도로 압축:
1. Title (1장)
2. Problem + Contribution (1장, dark_navy_summary)
3. Method overview (1장, process_flow)
4. Main result (1장, column_comparison)
5. Conclusion + URL (1장, executive_summary_takeaways)

### Long oral (20분, 12~15장)

확장:
- Motivation 2장으로 확장 (관련 연구 비교 1장 추가)
- Method 3~4장으로 확장 (각 모듈 상세 1장씩)
- Results 3~4장 (효율성 분석, qualitative examples 추가)
- Appendix 1장 (failure cases, future work)

### 영문 발표 (대부분의 학회 oral)

- DEFAULT_THEME (KO_THEME 아님)
- 제목 ≤ 70자, bullet ≤ 10단어/줄
- 모든 약어 첫 등장 시 풀네임 표기
- 인용은 "(Author, Year)" 또는 "[N]" 형식 일관성

---

## 학회별 특이사항

| 학회 | 시간 | 슬라이드 권장 | 특이사항 |
|:---|:---|:---|:---|
| CVPR/ICCV | 10~12분 | 8~10장 | Vision 결과는 qualitative example 1장 추가 권장 |
| NeurIPS | 10분 | 7~9장 | 이론 contribution이면 수식 슬라이드 추가 |
| ICLR | 12~15분 | 9~11장 | Open review 시스템 — Q&A 길어질 수 있음 |
| ACL | 12분 | 9~10장 | NLP는 example output 1장 권장 |
| KCC/KCAP (국내) | 15~20분 | 12~15장 | 한국어 가능 — KO_THEME 사용 |

---

## 흔한 실수

1. **Motivation에 시간 너무 많이 쓰기** — 30초~1분 안에 끝내야 함
2. **Method를 한 장에 다 넣기** — overview + detail로 분할
3. **결과 차트가 너무 작음** — 한 장에 차트 하나, 큼지막하게
4. **Conclusion이 contribution 반복** — 새로운 정보 (limitation, future) 포함
5. **Reference 슬라이드** — 학회 oral에 보통 X (논문에 있음)

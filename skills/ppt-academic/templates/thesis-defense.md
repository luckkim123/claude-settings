# Template: Thesis Defense (학사/석사/박사 디펜스)

**Use when:**
- 학위논문 심사 발표
- 졸업 종합 발표
- 청중: 심사위원 (3~5명) + 동료 학생

**Time/Slides:**
- 학사: 15분 / 15~18장
- 석사: 20분 / 18~22장
- 박사: 30~45분 / 25~35장

---

## 표준 시퀀스 (학사 18장 기준)

### Section 1: Cover (1장)
```python
b.add("cover_slide",
      title="<논문 제목>",
      subtitle="<영문 부제 또는 한 줄 요약>",
      author="<연구자 이름>",
      affiliation="<학과 / 대학>",
      date="2026-MM-DD")
```

### Section 2: Background (2장)

**Slide 2-1: 연구 배경 (큰 그림)**
```python
b.add("executive_summary_paragraph",
      title="연구 배경",
      paragraphs=[
          "<분야의 중요성, 1~2문장>",
          "<현재까지의 발전 흐름>",
      ])
```

**Slide 2-2: 문제 정의**
```python
b.add("dark_navy_summary",
      title="해결되지 않은 문제",
      message="<핵심 문제를 한 문장으로>",
      supporting_points=[
          "<문제 측면 1>",
          "<문제 측면 2>",
          "<문제 측면 3>",
      ])
```

### Section 3: Research Question (1장)
```python
b.add("dark_navy_summary",
      title="연구 질문",
      message="<단일 RQ를 한 문장으로>",
      # 예: "Self-attention의 메모리 복잡도를 O(N²)에서 O(N log N)으로
      #      줄일 수 있는가?"
      )
```

### Section 4: Related Work (2장)

**Slide 4-1: 기존 접근법 분류**
```python
b.add("comparison_table",
      title="기존 접근법 비교",
      columns=["메서드 A", "메서드 B", "메서드 C", "본 연구"],
      rows=[
          {"label": "메모리", "values": ["High", "Med", "Med", "Low"]},
          {"label": "정확도", "values": ["High", "Low", "Med", "High"]},
          {"label": "속도",   "values": ["Low",  "High","Med", "High"]},
      ])
```

**Slide 4-2: 본 연구의 위치**
```python
b.add("two_column_compare",
      title="본 연구의 차별점",
      left={"title": "기존 한계",
            "bullets": ["~", "~", "~"]},
      right={"title": "본 연구 기여",
             "bullets": ["~", "~", "~"]})
```

### Section 5: Methodology (3~4장)

**Slide 5-1: 전체 파이프라인**
```python
b.add("process_flow_horizontal",
      title="제안 방법 — 전체 흐름",
      steps=[
          {"title": "Input", "description": "원본 데이터"},
          {"title": "Module A", "description": "전처리"},
          {"title": "Module B", "description": "핵심 처리"},
          {"title": "Output", "description": "결과"},
      ])
```

**Slide 5-2: 핵심 모듈 상세**
```python
b.add("issue_tree",
      title="Module B 상세 구조",
      root="Module B",
      children=[
          {"name": "Sub-block 1", "children": [...]},
          {"name": "Sub-block 2", "children": [...]},
      ])
```

**Slide 5-3: 알고리즘 / 수식**
- 직접 작성 (mckinsey 템플릿보다 LaTeX 이미지 삽입이 나을 수 있음)
- 또는 `executive_summary_paragraph`로 알고리즘 의사코드 서술

### Section 6: Experiments (3장)

**Slide 6-1: 실험 설정**
```python
b.add("assessment_table",
      title="실험 설정",
      columns=["항목", "값"],
      rows=[
          {"label": "데이터셋", "values": ["ImageNet, COCO"]},
          {"label": "베이스라인", "values": ["ResNet-50, ViT-B"]},
          {"label": "메트릭",   "values": ["Top-1 Acc, FLOPs"]},
          {"label": "하드웨어", "values": ["8x A100"]},
      ])
```

**Slide 6-2: 데이터셋 / 메트릭 상세**
```python
b.add("three_trends_table",
      title="평가 메트릭",
      trends=[
          {"name": "Accuracy", "description": "...", "examples": "..."},
          {"name": "FLOPs",    "description": "...", "examples": "..."},
          {"name": "Latency",  "description": "...", "examples": "..."},
      ])
```

**Slide 6-3: 실험 시퀀스**
```python
b.add("phases_chevron_3",
      title="실험 진행",
      phases=[
          {"title": "Phase 1: Pre-training",
           "description": "ImageNet, 90 epochs"},
          {"title": "Phase 2: Fine-tuning",
           "description": "Downstream tasks"},
          {"title": "Phase 3: Ablation",
           "description": "Component analysis"},
      ])
```

### Section 7: Results (3장)

**Slide 7-1: Main Result (베이스라인 대비)**
```python
b.add("column_simple_growth",
      title="베이스라인 대비 성능",
      categories=["ResNet-50", "ViT-B", "본 연구"],
      values=[76.5, 80.1, 82.4],
      description="ImageNet Top-1 Accuracy",
      takeaway_header="베이스라인 대비 +2.3%, ViT 대비 +2.3%")
```

**Slide 7-2: Ablation**
```python
b.add("stacked_column_chart",
      title="Ablation Study",
      categories=["Baseline", "+Module A", "+Module B", "Full"],
      series=[
          {"name": "Acc gain", "values": [0, 0.8, 1.2, 2.3]},
      ],
      description="각 모듈의 누적 기여도",
      takeaway_header="Module B가 가장 큰 기여")
```

**Slide 7-3: Trade-off (정확도 vs 속도)**
```python
b.add("bubble_chart",
      title="정확도 vs 효율성 trade-off",
      bubbles=[
          {"label": "ResNet-50", "x": 4.1, "y": 76.5, "size": 25},
          {"label": "ViT-B",     "x": 17.6, "y": 80.1, "size": 86},
          {"label": "본 연구",   "x": 8.2,  "y": 82.4, "size": 40},
      ],
      x_axis="FLOPs (G)", y_axis="Accuracy (%)",
      takeaway_header="더 작은 모델로 더 높은 정확도")
```

### Section 8: Discussion (1장)
```python
b.add("pros_cons",
      title="본 연구의 장단점",
      pros={"title": "장점",
            "items": ["~", "~", "~"]},
      cons={"title": "한계",
            "items": ["~ (향후 연구)", "~", "~"]})
```

### Section 9: Conclusion (1장)
```python
b.add("executive_summary_takeaways",
      title="결론",
      sections=[
          {"takeaway": "<핵심 기여 1>",
           "bullets": ["~", "~"]},
          {"takeaway": "<핵심 기여 2>",
           "bullets": ["~", "~"]},
          {"takeaway": "<핵심 기여 3>",
           "bullets": ["~", "~"]},
      ],
      final_conclusion="<한 줄 마무리>")
```

### Section 10: Q&A (1장)
```python
b.add("quote_slide",
      title="감사합니다",
      quote="질문 부탁드립니다.",
      author="<연구자 이름>",
      attribution="<이메일> | <연락처>")
```

---

## 변형 규칙

### 시간이 짧을 때 (학사 12분)
- Background 2장 → 1장 (executive_summary_paragraph로 통합)
- Methodology 3~4장 → 2장 (핵심 모듈만)
- Results 3장 → 2장 (Main + Ablation, Trade-off 생략)

### 시간이 길 때 (석사/박사 30분+)
- Methodology 3~4장 → 5~6장 (각 모듈 상세 1장씩)
- Results 3장 → 5~6장 (downstream tasks 추가)
- Appendix 추가 (다양한 ablation, 실패 사례, 추가 데이터셋)

### 영문 발표
- KO_THEME 사용 안 함 (DEFAULT_THEME)
- 길이 룰: 제목 ≤ 70자, bullet ≤ 10단어/줄
- 약어 표기: 첫 등장 시 풀네임 + 약어

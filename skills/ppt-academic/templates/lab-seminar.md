# Template: Lab Seminar (랩 세미나)

**Use when:**
- 정기 랩 미팅
- 연구 진행 상황 공유
- 청중: 지도교수 + 같은 랩 학생

**Time/Slides:**
- 주간 미팅: 15~20분 / 8~12장
- 월간 미팅: 30분 / 12~18장
- 분기 발표: 45분 / 18~25장

---

## 표준 시퀀스 (30분 / 12장 기준)

### Section 1: Title + Recap (2장)

**Slide 1: Title**
```python
b.add("cover_slide",
      title="<주제 / 프로젝트>",
      subtitle="Week N — <기간>",
      author="<발표자>",
      affiliation="<랩 이름>",
      date="2026-MM-DD")
```

**Slide 2: 지난 미팅 요약 (Recap)**
```python
b.add("executive_summary_takeaways",
      title="지난 시간 요약",
      sections=[
          {"takeaway": "<지난 결과 1>",
           "bullets": ["~"]},
          {"takeaway": "<지난 의사결정>",
           "bullets": ["~"]},
      ],
      final_conclusion="이번 시간: <오늘의 핵심>")
```

**원칙**: Recap은 짧게 — 청중이 이미 알고 있음. 30초 안에 끝내기.

### Section 2: Progress (3~4장)

**Slide 3: 진행 일정 (Gantt)**
```python
b.add("gantt_timeline",
      title="이번 기간 진행 사항",
      tasks=[
          {"name": "Task A", "start": "Week 1", "end": "Week 2", "status": "done"},
          {"name": "Task B", "start": "Week 2", "end": "Week 3", "status": "done"},
          {"name": "Task C", "start": "Week 3", "end": "Week 4", "status": "in-progress"},
      ])
```

**Slide 4-5: 핵심 작업 상세 (각 1장)**
```python
b.add("process_activities",
      title="Task A: <상세 제목>",
      activities=[
          {"step": "1", "description": "데이터 수집 — 10K 샘플"},
          {"step": "2", "description": "전처리 파이프라인 구축"},
          {"step": "3", "description": "베이스라인 모델 학습"},
      ])
```

### Section 3: Findings (2~3장) — 가장 중요

**Slide 6: Main Finding**
```python
b.add("column_simple_growth",
      title="실험 결과 — Method A vs Baseline",
      categories=["Baseline", "Method A (v1)", "Method A (v2)"],
      values=[72.5, 75.1, 77.8],
      description="ImageNet validation accuracy",
      takeaway_header="v2가 베이스라인 대비 +5.3%")
```

**Slide 7: Insight / 발견 사항**
```python
b.add("dark_navy_summary",
      title="핵심 발견",
      message="<한 문장 인사이트>",
      # 예: "Attention head 중 70%가 redundant — 제거해도 성능 유지"
      supporting_points=[
          "<근거 1>",
          "<근거 2>",
          "<후속 가설>",
      ])
```

### Section 4: Issues (1~2장)

**Slide 8: 막힌 부분 솔직히**
```python
b.add("issue_tree",
      title="현재 막힌 부분",
      root="Module B 학습 불안정",
      children=[
          {"name": "원인 후보 1: learning rate",
           "children": [{"name": "검증: 5e-4 vs 1e-4 비교 중"}]},
          {"name": "원인 후보 2: data imbalance",
           "children": [{"name": "검증: re-sampling 시도"}]},
          {"name": "원인 후보 3: hardware-specific",
           "children": [{"name": "다른 GPU 환경에서 재현 시도"}]},
      ])
```

**원칙**: 솔직하게. 도움 받을 기회임.

### Section 5: Next Steps (1장)
```python
b.add("phases_chevron_3",
      title="다음 2주 계획",
      phases=[
          {"title": "Week N+1",
           "description": "Issue 디버깅 완료 + ablation 시작"},
          {"title": "Week N+2",
           "description": "Ablation 결과 + draft 시작"},
          {"title": "Week N+3",
           "description": "Draft 완성 + 학회 제출 준비"},
      ])
```

### Section 6: Discussion (1장)
```python
b.add("quote_slide",
      title="논의 사항",
      quote="<교수님께 묻고 싶은 질문 1>\n\n<논의하고 싶은 주제>",
      author="<발표자>",
      attribution="<email>")
```

또는 bullet 리스트로:
```python
b.add("executive_summary_takeaways",
      title="논의 사항",
      sections=[
          {"takeaway": "<질문 1>",
           "bullets": ["맥락 설명"]},
          {"takeaway": "<질문 2>",
           "bullets": ["맥락 설명"]},
      ])
```

---

## 변형 규칙

### 주간 미팅 (짧음, 8~12장)

압축:
- Recap 1장
- Progress 2~3장 (Gantt + 핵심 1~2개)
- Findings 1~2장
- Issues 1장
- Next Steps 1장
- Discussion 1장

### 분기 발표 (장기 진행, 18~25장)

확장:
- Recap 1장 (지난 분기 정리)
- Goals review 1장 (분기 초 목표 vs 실제)
- Progress 5~6장 (각 task 상세)
- Findings 5~6장 (다수 결과 + 분석)
- Issues 2~3장
- Next Quarter Plan 2~3장 (구체적 milestones)

### 첫 미팅 (랩 합류 직후)

추가:
- 본인 소개 1장 (background)
- 관심 분야 / 연구 방향 1~2장
- 향후 계획 (3~6개월) 1장

---

## 흔한 실수

1. **Recap이 너무 길어짐** — 30초~1분, 슬라이드 1~2장으로 충분
2. **Findings 없음** — Progress만 나열, "그래서 뭘 발견했는데?"가 없음
3. **Issues를 숨김** — 솔직히 공유해야 도움 받음. "다 잘 됐어요" ❌
4. **Next Steps가 모호함** — "다음 주에 더 해볼게요" ❌, "Week N에 X를 완료" ✅
5. **차트 너무 많음** — 핵심 차트 1~2개로 충분, 나머지는 부록

---

## 톤 (랩 세미나 특화)

- 디펜스/논문 발표보다 좀 더 캐주얼 OK
- 1인칭 사용 가능 ("저는", "제가")
- 솔직한 의견 OK ("이게 잘 안 되네요", "확신이 없어요")
- 단, 슬라이드 본문은 여전히 학술 톤 — 발표 스크립트는 자유

---

## 자주 쓰는 mckinsey 템플릿

| 용도 | 템플릿 | 빈도 |
|:---|:---|:---|
| 진행 일정 | `gantt_timeline` | ⭐⭐⭐ 매번 |
| 핵심 작업 상세 | `process_activities` | ⭐⭐ 자주 |
| 결과 비교 | `column_simple_growth` | ⭐⭐⭐ 매번 |
| 인사이트 | `dark_navy_summary` | ⭐ 가끔 |
| 막힌 부분 | `issue_tree` | ⭐⭐ 자주 |
| 다음 계획 | `phases_chevron_3` | ⭐⭐⭐ 매번 |
| 논의 | `quote_slide` 또는 `executive_summary_takeaways` | ⭐⭐ 자주 |

# Academic Narrative Arcs

학술 발표의 4가지 표준 시퀀스. 각 arc는 **Use when / Don't use when**으로
구분하며, mckinsey-pptx 템플릿 매핑 권장안을 포함한다.

---

## 1. 학사/석사/박사 디펜스 (15~25분)

**Use when:**
- 학위논문 심사
- 졸업 발표
- 종합 시험 발표
- 청중: 심사위원 (3~5명), 동료 학생, 지도교수

**Don't use when:**
- 학회 paper presentation (더 압축된 시퀀스 사용 — `paper-presentation.md`)
- 랩 세미나 (재귀적 진행 상황 공유 — `lab-seminar.md`)
- 일반 강의 (다른 스킬 사용 — `ppt-lecture`)

**구조 (총 15~20장)**:

| # | 섹션 | 슬라이드 수 | 권장 템플릿 |
|:--|:----|:-----------|:-----------|
| 1 | Cover | 1 | `cover_slide` |
| 2 | Background | 2 | `executive_summary_paragraph` 또는 `overview_areas` |
| 3 | Research Question | 1 | `dark_navy_summary` (impact 강조) |
| 4 | Related Work | 2 | `comparison_table` 또는 `two_column_compare` |
| 5 | Methodology | 3~4 | `process_flow_horizontal`, `phases_chevron_3` |
| 6 | Experiments | 3 | `assessment_table`, `column_comparison` |
| 7 | Results | 3 | `column_simple_growth`, `column_historic_forecast`, `bubble_chart` |
| 8 | Discussion | 1 | `pros_cons` 또는 `executive_summary_takeaways` |
| 9 | Conclusion | 1 | `executive_summary_takeaways` |
| 10| Q&A | 1 | `quote_slide` (감사 메시지) |

**핵심 원칙**:
- Background는 문제(problem) → 기회(gap) → 본 연구의 위치(positioning) 흐름
- RQ는 **단 하나의 문장**으로 압축 (dark_navy_summary로 시각적 임팩트)
- Method는 한 장에 넣지 말 것 — 3~4장으로 분할
- Results는 baseline 비교 + ablation + qualitative 순서

---

## 2. 논문 발표 / 학회 oral (10~15분)

**Use when:**
- 학회 paper oral presentation (CVPR, NeurIPS, ICLR 등)
- 저널 발표
- 청중: 같은 분야 전문 연구자
- 시간 제약: 12분 발표 + 3분 Q&A

**Don't use when:**
- 디펜스 (더 자세한 설명 필요)
- 일반 청중 (도입부 더 길게)

**구조 (총 8~12장)**:

| # | 섹션 | 슬라이드 수 | 권장 템플릿 |
|:--|:----|:-----------|:-----------|
| 1 | Title | 1 | `cover_slide` |
| 2 | Motivation | 1~2 | `dark_navy_summary` 또는 `stat_hero` |
| 3 | Contribution | 1 | `three_trends_numbered` (3가지 핵심 기여) |
| 4 | Method | 2~3 | `process_flow_horizontal`, `issue_tree` |
| 5 | Results | 2~3 | `column_comparison`, `assessment_table` |
| 6 | Conclusion | 1 | `executive_summary_takeaways` |

**핵심 원칙**:
- Motivation은 30초 안에 이해되어야 — 큰 숫자 또는 직관적 비유
- Contribution은 3가지로 압축 (5개 이상이면 청중 못 따라옴)
- Method 다이어그램이 발표의 80% — 이걸 뜯어 설명
- Results는 main result 1개 + ablation 1개로 충분

---

## 3. 랩 세미나 (20~40분)

**Use when:**
- 정기 랩 미팅
- 연구 진행 상황 공유
- 청중: 지도교수 + 같은 랩 학생
- 시간: 보통 30분 발표 + 토론

**Don't use when:**
- 외부 청중 (디펜스/논문 시퀀스 사용)
- 첫 미팅이면 더 자세한 background 필요

**구조 (총 10~15장)**:

| # | 섹션 | 슬라이드 수 | 권장 템플릿 |
|:--|:----|:-----------|:-----------|
| 1 | Title + 지난 미팅 요약 | 1 | `cover_slide` + `agenda` |
| 2 | Recap (지난번 결과) | 1~2 | `executive_summary_takeaways` |
| 3 | Progress (이번 기간 한 일) | 3~4 | `process_activities`, `gantt_timeline` |
| 4 | Findings (새로 발견한 것) | 2~3 | `column_simple_growth`, `assessment_table` |
| 5 | Issues (막힌 부분) | 1~2 | `pros_cons`, `issue_tree` |
| 6 | Next Steps | 1 | `phases_chevron_3` |
| 7 | Discussion 질문거리 | 1 | `quote_slide` |

**핵심 원칙**:
- Recap은 짧게 — 모두가 이미 알고 있음
- Findings에 시간 가장 많이 (60%)
- Issues 솔직히 — 도움 받을 기회
- Next Steps는 1주일 단위로 구체적

---

## 4. research_summary 매핑 (vault 전용)

**Use when:**
- 사용자 CWD가 vault `0_Project/in_progress/<name>/research_summary/` 안
- 또는 `--from-research-summary <dir>` 명시

**자동 파일 매핑**:

| vault 파일 | 슬라이드 매핑 |
|:---|:---|
| `00_INDEX.md` | (메타) — 시퀀스 결정 참고용, 슬라이드 X |
| `01_research_identity.md` | Cover + Background (1~2장) |
| `02_thesis_core.md` | Research Question + Methodology (3~5장) |
| `03_publications.md` | Related Work (1~2장) |
| `04_projects_timeline.md` | Roadmap / Gantt (1장) — 보통 부록 |
| `05_improvements_from_proposal.md` | Discussion / Limitations (1장) |
| `06_cv_material.md` | (부록) — 슬라이드 본문 X |
| `07_defense_narrative.md` | 발표 스크립트 (PowerPoint notes로만, 슬라이드 본문 X) |

**처리 순서**:
1. `00_INDEX.md` 읽어 전체 구조 파악
2. 각 파일의 ## 섹션을 슬라이드 단위로 분해
3. ad-block (요약/핵심)을 슬라이드 takeaway로
4. 표/리스트는 적절한 mckinsey 템플릿 매핑
5. 디펜스 시퀀스(arc 1)에 끼워넣기

**예외 처리**:
- 파일 일부 누락: 해당 섹션을 placeholder로 표시 ("[research_identity 파일 없음 — 직접 입력 필요]")
- 파일이 너무 길어 한 슬라이드에 안 맞음: 자동으로 2~3장 분할 (사용자 확인 후)

---

## Arc 선택 의사결정

```
사용자 입력에 키워드 매칭:
├─ "디펜스" / "thesis" / "졸업 발표" → arc 1
├─ "학회" / "paper" / "conference" → arc 2
├─ "랩 세미나" / "주간 미팅" / "weekly" → arc 3
└─ vault 안 + research_summary 폴더 → arc 4

매칭 안 되면:
→ 사용자에게 4개 중 선택 요청 (질문 1번만)
```

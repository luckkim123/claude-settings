---
name: ppt-edit
description: |
  기존 .pptx 파일을 수정하는 스킬. 텍스트 교체(L1), 슬라이드 추가/삭제/순서
  변경(L2), 폰트/컬러/여백 deck 전체 일괄 변경(L3) 지원. 원본은 절대
  in-place 수정 안 함 (새 파일 출력). dry-run plan → 사용자 확정 → 적용 →
  다층 무결성 검증 → 전수 PNG 정독의 3게이트. REFLECTION_v20 사고 6종
  (변경 슬라이드만 검증, 영문 제목 임의 작성, 복구 다이얼로그 재발 등)
  차단 hard rule 내장.

  Triggers: ppt 수정, pptx 수정, 슬라이드 수정, 발표자료 수정, 폰트 일괄
  변경, deck 패치, slide patch, ppt edit, pptx edit, 디펜스 자료 수정,
  발표자료 폰트/컬러 통일, 텍스트 교체, 슬라이드 추가/삭제
---

# PPT Edit Skill

> **수정 모드의 LLM은 transcriber지 author가 아니다.**
> (사용자 명시 요청 없는 콘텐츠 신규 작성 = 위조)

기존 `.pptx` 파일을 신중하게(3게이트) 수정한다. 디펜스 발표자료처럼 한 번의
결과물이 학위 평가에 직접 영향을 주는 작업을 안전하게 다루기 위한 스킬.

## When to Use

**Use this skill when:**
- 이미 만들어진 .pptx의 슬라이드 텍스트 한 줄 교체
- 슬라이드 추가/삭제/순서 변경
- 폰트/컬러/여백을 deck 전체에 일괄 적용
- 디펜스/논문 발표 자료의 패치 사이클 (vN → vN+1)
- "이 PPT의 X를 Y로 바꿔줘" 형태의 요청

**Use `ppt-academic` instead when:**
- 새 .pptx를 처음부터 생성
- 레이아웃 구조 자체를 재설계 (1단 → 2단 등, L4)
- → 이 경우 먼저 `ppt-analyze`로 spec 추출 후 `ppt-academic`으로 재생성

**Use `ppt-analyze` instead when:**
- 기존 .pptx에서 스타일/구조 spec을 추출
- 새 PPT 만들 때 참조용 design system 문서가 필요

## Hard Rules (REFLECTION_v20 사고 차단)

### V1. 전수 PNG 정독 (변경 슬라이드만은 금지)

매 modify 후 deck **전체 슬라이드** PNG 렌더 + Read 도구로 정독. 변경 대상이
아니었던 슬라이드도 빌드 사이드이펙트로 깨질 수 있음 (REFLECTION_v20 §2 첫째,
v17→v20에서 슬라이드 1 영문 제목 사라짐 사례).

**금지**: "변경된 슬라이드 3장만 보여드리고 잘 됐습니다 보고."

soffice/pdftoppm 없으면 작업 거부 (`brew install --cask libreoffice` 안내).

### V2. 다층 무결성 게이트 5개 모두 통과

빌드 후 `scripts/verify_pptx.py <output.pptx>` 실행. 5개 항목 모두 PASS여야
산출물 인정.

| # | 검사 | 차단하는 사고 |
|:--|:--|:--|
| V2.1 | zip CRC 무결성 | zip 손상 |
| V2.2 | python-pptx open | 파싱 실패 |
| V2.3 | soffice PDF 변환 | 렌더링 실패 |
| V2.4 | OOXML 직접 검사 (sldIdLst id≥256/unique, rels 양방향, dangling 0, Content_Types Override 완전성) | dangling rels 잔재, Override 누락 |
| V2.5 | **Orphan slideMaster 검사** | **PowerPoint 복구 다이얼로그** (v20 잔존 원인 — soffice/python-pptx는 관대해서 못 잡음) |

V2.5가 fail하면 빌드 중단 + 사용자에게 "고아 master를 정리해야 PowerPoint
복구 다이얼로그가 사라집니다" 안내. presentation.xml.rels의 master rId, sldMasterIdLst 항목, [Content_Types].xml의 Override 동시 정리 필요.

### V3. Provenance Lock (위조 차단)

**modify 모드는 항상 원본 .pptx의 해당 위치 텍스트를 먼저 인용 출력**한 뒤
변경 plan 제시. 원본 미확인 상태에서 텍스트 신규 작성 금지.

```
# 잘못된 흐름 (REFLECTION_v20_2 §1 사례 — 위조)
사용자: "슬라이드 1에 영문 제목 빠졌네 추가해줘"
LLM: [원본 v17 확인 안 하고] "Cooperative ASV-ROV System with..." 임의 작성

# 올바른 흐름
사용자: "슬라이드 1에 영문 제목 빠졌네 추가해줘"
LLM: 1) 가장 최근 정상 빌드(v17)의 슬라이드 1 .xml 인용 출력
        → 발견된 원본 영문 제목: "Development of an Autonomous ASV-ROV..."
     2) 사용자께 "이 원본 문구 그대로 복원할까요, 아니면 새 문구 원하시나요?"
        확인
     3) 확인된 문구로만 변경 plan 작성
```

### V4. 콘텐츠 신규 작성 금지

사용자가 명시적으로 "이 텍스트 작성해줘"라 하지 않았으면 LLM이 새 문구
만들지 않음. "추가" 요청도 어디에 어떻게 추가할지(기존 대체 vs 병행) 한 번
더 확인.

### V5. 출력 분리 + Dry-run

- 원본은 절대 in-place 수정 X. 항상 `output/<slug>/<deck>.edited.pptx`로 새 파일.
- 첫 호출은 변경 plan만 출력 (변경 위치, before→after diff, 영향 범위).
  사용자 OK 후 적용. `--auto-apply` 플래그로 확정 단계 스킵 가능.

### V6. 카테고리 전수 점검

사용자가 한 카테고리 결함을 지적하면 같은 카테고리 다른 슬라이드도 일괄
점검 (REFLECTION_v20 §2 첫째). 예: "슬라이드 24 회색 박스 누수" → 모든
슬라이드의 회색 박스 위치 점검.

## Gate 0 — 의존성 체크

첫 호출 시 실행:

```bash
python3 -c "import pptx" 2>&1
which soffice pdftoppm 2>&1
```

미설치 시 안내:
- `pip3 install --user python-pptx`
- `brew install --cask libreoffice` (soffice + headless 변환)
- `brew install poppler` (pdftoppm)

이 도구들이 없으면 V1(전수 PNG 정독), V2.3(soffice 변환)이 불가능 → 작업 거부.

## Gate 1 — 원본 정독 + 변경 Plan (Provenance Lock 적용)

사용자 요청 받으면:

1. **원본 위치 식별**
   - 변경 대상 .pptx 경로 확정
   - 변경 대상 슬라이드 번호/위치 확정
2. **원본 텍스트/스타일 인용 출력 (V3 강제)**
   - python-pptx로 해당 슬라이드의 모든 shape + run text + font 정보 출력
   - 사용자에게 "이게 현재 상태다" 명시
3. **변경 plan 작성**

```markdown
## 변경 Plan (dry-run, 적용 전)

**대상**: 260617_Defense_Seungmin_Kim_v20.pptx
**산출물**: output/defense_v21/260617_Defense_Seungmin_Kim_v21.pptx (새 파일)

### 변경 1
- **위치**: 슬라이드 1, shape "TitleEN" (좌표 1.92, 3.06인치)
- **현재 (원본 인용)**: (없음 — 슬라이드 1에 영문 제목 텍스트박스 부재)
- **변경 후**: "Development of an Autonomous ASV-ROV System with Sonar-Based
  Cooperative Localization and Adaptive Learning Control for Underwater
  Manipulation"
  - 출처: v17의 슬라이드 1에 사용자가 직접 작성한 원본 (V3 Provenance 확인됨)
- **영향 받는 인접 슬라이드**: 없음 (제목 슬라이드 1장만)

### 변경 2
- **위치**: 슬라이드 24, 회색 둥근 박스 (좌표 ...)
- **현재**: 박스가 슬라이드 영역을 4mm 벗어남
- **변경 후**: 박스 폭 축소
- **영향 받는 인접 슬라이드**: V6 카테고리 전수 점검 결과 슬라이드 22, 28도
  유사한 회색 박스 사용 — 폭 점검했으나 범위 내, 변경 불필요

이 plan대로 적용할까요? (Y / 수정 사항 있으면 알려주세요)
```

## Gate 2 — 적용 + V2 무결성 게이트

사용자 OK → 새 파일에 패치 적용:

1. python-pptx 또는 OOXML 직접 수정
2. 새 파일로 저장 (`output/<slug>/<deck>.edited.pptx`)
3. **V2 무결성 5개 항목 자동 실행**:

```bash
python3 ${SKILL_DIR}/scripts/verify_pptx.py output/.../<deck>.edited.pptx
```

- 5/5 PASS → Gate 3로 진행
- 1개라도 FAIL → 사용자에게 보고하고 중단. 패치 롤백 또는 fix 시도.

V2.5(orphan master)가 fail이면 master 정리 sub-task 추가 (presentation.xml.rels +
sldMasterIdLst + Content_Types Override 동시 정리).

## Gate 3 — 전수 PNG 정독 + 회귀 보고

```bash
soffice --headless --convert-to pdf --outdir /tmp/check output/.../<deck>.edited.pptx
pdftoppm -r 100 /tmp/check/<deck>.edited.pdf /tmp/check/slide -png
ls /tmp/check/slide-*.png
```

생성된 PNG **전부**를 Read 도구로 정독. 변경 대상이 아니었던 슬라이드도 모두
확인.

**보고 형식 (V1 강제)**:

```markdown
## Build 완료 + 회귀 점검 보고

**적용된 변경**: 2건 (슬라이드 1 영문 제목 추가, 슬라이드 24 회색 박스 폭)

**V2 무결성**: 5/5 PASS
**V1 전수 정독**: 30/30 슬라이드 PNG 확인 완료

### 변경 슬라이드 검증
- 슬라이드 1: 영문 제목 "Development of an Autonomous..." 정상 표시 ✓
- 슬라이드 24: 회색 박스 폭 슬라이드 영역 내 ✓

### 변경 대상 아니었던 슬라이드 회귀 점검
- 슬라이드 2~23: 결함 없음 ✓
- 슬라이드 25~30: 결함 없음 ✓
  - 슬라이드 30(References): 폭 점검 정상

**산출물**: output/defense_v21/260617_Defense_Seungmin_Kim_v21.pptx
```

## Hard Rule — 게이트 분리 강제

절대 한 게이트 안에서 다음 게이트 일을 미리 하지 말 것.
- G1에서 patch 적용 X (plan만)
- G2에서 PNG 정독 X (무결성 체크만)
- G3에서 새 patch 추가 X (정독 + 보고만)

게이트 분리가 자가-합리화 차단의 핵심. "기왕 하는 김에 한 번에"는 금지.

## Common Mistakes

| Mistake | Fix |
|:--|:--|
| 변경 슬라이드만 PNG 확인 | V1 위반. 전수 정독 필수. |
| dangling rels만 검사하고 OK 보고 | V2.4/V2.5 미실행. `verify_pptx.py` 5/5 통과해야 함. |
| 원본 확인 없이 새 텍스트 작성 | V3 위반. 위조에 해당. 원본 인용 → 사용자 확인 → 작성. |
| "추가" 요청을 "기존 대체"로 잘못 해석 | V4 위반. 추가/대체 명시적 확인. |
| `--auto-apply` 없이 plan 단계 스킵 | V5 위반. 기본은 항상 dry-run. |
| 한 슬라이드 결함 fix 후 같은 카테고리 다른 슬라이드 점검 안 함 | V6 위반. 카테고리 전수 점검. |

## Red Flags — STOP and Restart

- "이 변경은 작아서 plan 생략해도 됨" → V5 위반
- "PNG 30장 다 확인은 무거우니 변경된 5장만" → V1 위반
- "원본 영문 제목 정확히 모르지만 quad chart 보고 만들면 됨" → V3 위반 (위조)
- "verify_pptx.py 4/5만 통과해도 PowerPoint에서 열리니 OK" → V2 위반 (복구 다이얼로그 잔존)
- "사용자가 '추가'라 했으니 어디에 어떻게 추가할지 내가 결정" → V4 위반

위 신호 떠오르면 즉시 멈추고 Gate 1로 복귀.

## Output Location

사용자 CWD의 `output/<slug>/` 아래.
- `<deck>.edited.pptx` — 수정본 (원본은 보존)
- `verify_report.json` — V2 무결성 검증 결과
- `regression_check.md` — V1 전수 정독 보고

## References

- 설계 문서: vault `docs/plans/2026-05-11-ppt-edit-analyze-design.md`
- 사고 사례: vault `0_Project/in_progress/bachelor_thesis_2026/defense/REFLECTION_v20.md`,
  `REFLECTION_v20_2.md`
- 무결성 헬퍼: `scripts/verify_pptx.py` (이 스킬 동봉, self-contained)

---
name: ppt-analyze
description: |
  기존 .pptx 파일을 분석해서 design system 문서(폰트/컬러/여백/위치/layout
  패턴)를 4개 산출물로 추출하는 스킬. 추출 결과는 새 PPT 만들 때 "이 양식대로
  만들어줘" 참조용. style_spec.yaml + layout_catalog.md + narrative_outline.md
  + asset_manifest.yaml 4종 (옵션 --detail full로 슬라이드별 완전 dump 5번째
  파일 추가). round-trip 검증으로 spec 정확성 보장.

  Triggers: ppt 분석, pptx 분석, 슬라이드 분석, 발표자료 양식 추출,
  design system 추출, style spec 추출, layout 패턴 추출, 디펜스 PPT 양식,
  ppt analyze, pptx analyze, design extraction, slide template extraction
---

# PPT Analyze Skill

> **추출한 spec은 round-trip으로 검증된 것만 신뢰한다.**
> (재생성해서 원본과 시각 일치 안 하면 spec은 그럴듯한 거짓)

기존 .pptx 1개 → design system 4종 산출물. 새 PPT 만들 때 참조용.

## When to Use

**Use this skill when:**
- 박건우 선배 v18 같은 기존 .pptx에서 양식만 추출 → 내 새 PPT에 적용
- 디펜스 deck의 design tokens(폰트/컬러/여백) 정리
- "이 양식 그대로 새 deck 만들어줘"의 사전 준비 단계
- 라이선스/누락 자산 점검 (asset_manifest)

**Use `ppt-edit` instead when:**
- 기존 .pptx 파일을 직접 수정 (텍스트/슬라이드/스타일)
- → analyze는 read-only, edit는 in-place(새 파일) 수정

**Use `ppt-academic` instead when:**
- analyze 결과를 받아 새 deck를 처음부터 생성
- 자연스러운 파이프라인: `ppt-analyze` → spec → `ppt-academic`

## Hard Rules

### A1. Read-only

원본 .pptx 절대 수정 X. 모든 산출물은 `output/<deck-slug>/`로만.

### A2. Round-trip 검증 강제

추출한 style_spec.yaml로 대표 슬라이드 1장을 재생성 → 원본과 PNG 비교 →
픽셀 유사도 ≥ 85%면 spec 신뢰. 미달이면 spec이 design system을 충분히
캡처 못 한 것 (사용자에게 보고하고 `--detail full`로 재추출 안내).

`scripts/roundtrip_check.py`가 자동 실행.

### A3. 대표 산출물 4종 (G4 hybrid)

| 파일 | 형식 | 내용 |
|:--|:--|:--|
| `style_spec.yaml` | YAML | deck-level design tokens (typography/palette/spacing) + layout별 spec |
| `layout_catalog.md` | Markdown | 슬라이드별 layout 패턴 분류 + 빈도 + 예시 슬라이드 번호 |
| `narrative_outline.md` | Markdown | 슬라이드 제목 + bullet 트리 (텍스트 흐름) |
| `asset_manifest.yaml` | YAML | 사용된 이미지/폰트 목록 |

### A4. 옵션: `--detail full` (G3 슬라이드별 완전 dump)

5번째 파일 `slides_full_dump.yaml` 추가 — 슬라이드 1장당 모든 shape의 위치
(EMU)/크기/폰트/컬러를 그대로 dump. round-trip 정확도가 G4만으로 부족할 때
사용. 60장 deck이면 파일이 커짐.

### A5. 무결성 사전 점검

분석 시작 전 `scripts/verify_pptx.py`로 입력 .pptx 무결성 점검. 5/5 PASS
아니면 사용자에게 알리고 진행 여부 확인 (분석은 read-only라 진행 가능하지만,
spec 자체가 손상된 deck에서 추출되면 신뢰성 떨어짐).

## Gate 0 — 의존성 체크

```bash
python3 -c "import pptx" 2>&1
which soffice pdftoppm 2>&1
python3 -c "import yaml" 2>&1   # 권장 (없으면 fallback YAML dump)
python3 -c "import PIL" 2>&1    # 권장 (없으면 round-trip은 파일크기 비)
```

미설치 시 안내:
- `pip3 install --user python-pptx pyyaml Pillow`
- `brew install --cask libreoffice && brew install poppler`

## Gate 1 — 추출 범위 확정

사용자에게 확인:

```markdown
## 분석 대상 확정

- 원본: <deck.pptx>
- 산출물 출력 위치: output/<slug>/ (4개 파일)

### 추출 모드 선택

1. **G4 hybrid (기본)** — design system 문서 형태. style_spec.yaml에
   deck-level design tokens + layout별 spec. 사람이 읽고 새 PPT 만드는
   참조용. 가벼움.

2. **G4 + G3 full** (`--detail full`) — 위 + 슬라이드별 완전 dump
   (slides_full_dump.yaml). 정밀하지만 파일 큼.

어떤 모드로 갈까요?
```

## Gate 2 — 추출 + 산출물 생성

사용자 확정 → 자동 실행:

```bash
# 1. 사전 무결성 점검
python3 ${SKILL_DIR}/scripts/verify_pptx.py <deck.pptx>

# 2. 추출
python3 ${SKILL_DIR}/scripts/extract_spec.py <deck.pptx> \
    --out output/<slug>/ \
    [--detail full]
```

산출물 생성 후:
- `style_spec.yaml`의 design_tokens 요약 출력 (제목/본문 폰트, 팔레트)
- `layout_catalog.md`의 layout 빈도 표 출력
- 사용자에게 산출물 경로 보고

## Gate 3 — Round-trip 검증

```bash
python3 ${SKILL_DIR}/scripts/roundtrip_check.py \
    <원본.pptx> output/<slug>/ --slide 1 --threshold 0.85
```

산출:
- `output/<slug>/roundtrip/original_slideN.png`
- `output/<slug>/roundtrip/regenerated_slideN.png`
- `output/<slug>/roundtrip/diff_slideN.png`
- `output/<slug>/roundtrip/roundtrip_report.md`

LLM은 두 PNG를 Read 도구로 정독해 시각 일치 여부 확인 + 사용자 보고.

**임계 미달 시**:
- 일치율 < 85% → "spec이 design system을 충분히 캡처 못 함"
- 사용자에게 `--detail full`로 재추출하거나, layout 분류 규칙 보강 안내

## 산출물 활용 (downstream)

추출한 spec은 다음에 사용:

```bash
# 1. ppt-academic으로 새 deck 만들 때 참조
"output/박건우_v18/style_spec.yaml의 design tokens 적용해서
 내 디펜스 deck 만들어줘"

# 2. ppt-edit로 기존 deck를 spec에 맞춰 통일할 때
"내 deck를 output/박건우_v18/style_spec.yaml의 폰트/팔레트로 통일해줘"
```

## Common Mistakes

| Mistake | Fix |
|:--|:--|
| Round-trip 검증 생략 | A2 위반. spec이 거짓일 수 있음. 항상 G3 실행. |
| `--detail full` 없이 정밀 재현 기대 | G4 기본은 hybrid 요약. 정밀 재현은 `--detail full` 필요. |
| 무결성 점검 안 한 손상된 deck로 추출 | A5 위반. spec이 손상된 deck의 결함까지 spec으로 채택. |
| 산출물을 LLM이 임의 해석 | spec yaml은 그대로 ppt-academic/edit에 전달. 중간에 LLM이 "더 나은 폰트로 바꿔야겠다" 같은 변형 X. |

## Red Flags — STOP

- "round-trip 일치율 60%지만 spec은 대충 맞으니 OK" → A2 위반
- "이 deck는 v17이라 검증 생략해도 됨" → A5 위반
- "extract_spec.py 결과 보고 내가 yaml 직접 수정" → spec은 자동 추출만 신뢰

## Output Location

사용자 CWD의 `output/<deck-slug>/` 아래 4(또는 5)개 파일 + `roundtrip/` 서브폴더.

## References

- 설계 문서: vault `docs/plans/2026-05-11-ppt-edit-analyze-design.md`
- 헬퍼 스크립트: `scripts/extract_spec.py`, `scripts/roundtrip_check.py`,
  `scripts/verify_pptx.py` (이 스킬 동봉, self-contained)

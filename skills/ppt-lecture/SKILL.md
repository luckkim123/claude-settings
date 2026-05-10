---
name: ppt-lecture
description: |
  강의/교육 자료용 HTML 슬라이드 생성. 랩 세미나, 후배 교육, 블로그 임베드,
  컨셉 노트 강의화에 특화. HTML→PNG 캡처 베이스 (글자 깨짐 X). 학술 미니멀
  베이스 + light/dark/paper 3 테마. 2게이트 워크플로우 (기획서 → 미리보기).

  Triggers: 강의 자료, 강의 슬라이드, 교육 자료, 세미나 자료, 컨셉 강의,
  lecture slides, teaching slides, tutorial deck, 튜토리얼, 강의용,
  블로그 슬라이드, 카드 자료
---

# PPT Lecture Skill

강의/교육 자료용 HTML 슬라이드를 빠르게(2게이트) 생성한다. 단일 HTML 파일,
브라우저 내장 다운로드 버튼(ZIP/PNG), 한국어 폰트 사전 로드, 학술 미니멀 톤
+ 3개 테마 변형.

## When to Use

**Use this skill when:**
- 랩 세미나 슬라이드 (학술 데이터 X, 개념 전달 위주)
- 후배 교육 / 튜토리얼 / 워크샵
- 블로그 임베드용 (다크 테마 권장)
- vault `2_Resource/concepts/*.md` 컨셉 노트를 강의 형태로
- PNG 이미지 출력이 더 적합한 경우 (글자 깨짐 방지)

**Use `ppt-academic` instead when:**
- 디펜스, 학회, 논문 발표 (편집 가능한 .pptx 필요)
- 차트/그래프 중심의 데이터 발표
- mckinsey 스타일 컨설팅 톤

## Hard Rules

1. **2게이트 워크플로우 준수** — 기획서 → 미리보기 → 전체 빌드. 한 번에 X.
2. **template.html이 단일 진실** — 새 클래스명 발명 금지. 필요하면 template
   `<style>` 블록에 추가하고 `layouts.md`에도 등록.
3. **한 deck에서 한 테마만** — light/dark/paper 중 하나. 중간에 교체 X.
4. **사용자 hex 자유 입력 거부** — 3개 테마 외 커스텀 컬러 요청 시 정중히
   거절하고 3개 중 선택 안내 (op7418 패턴).
5. **폰트 사전 로드 필수** — html2canvas 캡처 전 `await document.fonts.ready`.
   안 그러면 한글 잘림.
6. **레이아웃 디시플린**:
   - 한국어 제목 ≤ 12자, 영어 ≤ 25자 (한 줄 가독성)
   - 슬라이드당 텍스트 ≤ 7줄 (강의 자료의 호흡)
   - callout-stat은 deck당 1개만 (희소성)
7. **이미지 비율 표준만** — 16:9 / 4:3 / 1:1. 원본 비율 그대로 X.
8. **출력 위치** — 사용자 CWD의 `output/<slug>/index.html`.

## Gate 0 — 환경 체크

첫 호출 시 실행:

```bash
# 1. Pretendard 폰트 (선택, fallback OK)
fc-list 2>/dev/null | grep -i "pretendard" >/dev/null || \
  echo "ℹ️  Pretendard 미설치 — Noto Sans KR로 fallback"
# (claude-settings install.sh가 자동 설치하지만, 미실행이어도 동작은 함)

# 2. 브라우저 (출력 후 자동 열기용)
command -v open >/dev/null 2>&1 || command -v start >/dev/null 2>&1 || \
  echo "ℹ️  자동 열기 비활성화 — 브라우저로 index.html 직접 오픈하세요"

# 3. CDN 접근 (오프라인이면 폴백 처리)
# html2canvas, jszip, FileSaver는 cdnjs에서 로드
```

브라우저는 거의 모든 머신에 있으므로 Gate 0 보통 통과. 누락 시 안내만.

## Gate 1 — 기획서 (콘텐츠 + 레이아웃 동시)

사용자 입력에서 추출:
- **주제**: 슬라이드의 핵심 내용
- **길이**: 슬라이드 수 (명시 안 되면 자동 판단 — 단순 X 5~7장, 복잡 X 10~12장)
- **테마**: light/dark/paper 중 하나 (명시 안 되면 use case로 추론)
- **톤**: 학술/캐주얼/블로그 (사용자 표현으로 추론)

테마 추론 룰:
- "강의실 / 발표 / 세미나" → light
- "블로그 / Twitter / 공유 / 소셜" → dark
- "출력 / 인쇄 / 종이" → paper
- 모호하면 → light 기본 + 사용자 확인

### vault 옵션 헬퍼 (자동 감지)

사용자 CWD가 vault 안이면:

- `--from-concept <path>`: `2_Resource/concepts/<name>.md` 자동 읽기
  - 노트의 `## 섹션`을 슬라이드 단위로 매핑
  - ad-block (요약/핵심)을 hero-cover takeaway로 변환
  - 수식/이미지가 있으면 callout-stat 또는 frame 레이아웃
- `--from-paper-summary <path>`: `2_Resource/papers/<name>.md` Main Ideas만 추출
- `--from-outline <path>`: 사용자 .md 개요 따름

### 출력 (사용자 확정 대기)

```markdown
## 강의 슬라이드 기획서 — Transformer Self-Attention

**테마**: dark (블로그 임베드 가정)
**총 슬라이드**: 7장
**예상 발표 시간**: 10~12분
**vault 노트**: `2_Resource/concepts/Transformer_Self_Attention.md` 참고

| # | 레이아웃 | 제목 | 핵심 메시지 |
|:--|:--------|:----|:----------|
| 1 | hero-cover | Self-Attention | 부제: "왜 RNN이 졌는가" |
| 2 | quote-large | "Attention is all you need" | Vaswani et al., 2017 |
| 3 | flow-3step | Q, K, V 분해 | 입력 → 3개 행렬 → 가중합 |
| 4 | side-by-side | RNN vs Transformer | 순차 처리 vs 병렬 처리 |
| 5 | bento-2x2 | 4가지 핵심 특성 | 병렬, 장거리, 위치, 헤드 |
| 6 | callout-stat | 96.8% | "GPT-4 MMLU 정확도" |
| 7 | takeaway | 핵심 정리 | 3가지 takeaway + 다음 강의 예고 |

이대로 진행할까요? 또는 수정 사항을 알려주세요.
```

**사용자 확정 ✋ → Gate 2**

## Gate 2 — 첫 미리보기 (1~2장 빠른 검증)

전체 빌드 전에 **샘플 2장 먼저 빌드** (보통 hero + 본문 1장):

```bash
# 1. template.html 복제
mkdir -p output/<slug>
cp <skill-root>/assets/template.html output/<slug>/preview.html

# 2. preview.html에 첫 2장 채워넣기 (다른 슬라이드는 일단 비움)
# - <title> 교체
# - data-theme 속성 (light/dark/paper)
# - 첫 2장 콘텐츠 채움

# 3. 브라우저 자동 오픈
open output/<slug>/preview.html  # Mac
start output\<slug>\preview.html  # Windows
```

사용자에게:
```markdown
## 미리보기 검증

`output/<slug>/preview.html` 생성 — 브라우저에서 자동 오픈됨.

확인 포인트:
- [ ] 한글 폰트 정상 렌더링 (Pretendard 또는 Noto Sans KR)
- [ ] 다크 테마 가독성 OK
- [ ] hero 페이지 임팩트 충분
- [ ] 텍스트 크기 적절

OK면 나머지 5장 생성 / 톤 수정 필요하면 알려주세요.
```

**사용자 확정 ✋ → 전체 빌드**

## 전체 빌드

### 1. index.html 생성

```bash
# preview.html → index.html 이름 변경, 7장 모두 채워넣기
mv output/<slug>/preview.html output/<slug>/index.html
# 나머지 5장 콘텐츠 추가
```

각 슬라이드는 `references/layouts.md`의 paste-ready 스니펫 사용.
- 클래스명은 template.html에 정의된 것만 사용 (룰 #2)
- `data-slide-id` 속성으로 슬라이드 번호 부여
- 페이지 번호(예: "03 / 07")는 자동 또는 수동 입력

### 2. outline.md 부산물 저장

```markdown
# Transformer Self-Attention — Lecture Outline

**테마**: dark
**슬라이드 수**: 7장
**생성일**: 2026-MM-DD

## Slide 1 (hero-cover)
**제목**: Self-Attention
**부제**: 왜 RNN이 졌는가

## Slide 2 (quote-large)
**인용**: "Attention is all you need"
**저자**: Vaswani et al., 2017
...
```

콘텐츠만 (디자인 X) — 향후 다른 테마로 재생성 시 재사용.

### 3. 브라우저 자동 오픈

```bash
open output/<slug>/index.html  # Mac
start output\<slug>\index.html  # Windows
```

### 4. P0 체크리스트 자동 검증

`references/checklist.md`의 P0 항목 자동 체크:
- HTML 파싱 가능
- `<title>` placeholder 잔존 X
- 모든 클래스명이 template.html에 정의됨
- 슬라이드당 텍스트 길이 룰 준수

문제 발견 시 사용자에게 보고 → 수정 후 재빌드.

### 5. 사용자 보고

```markdown
## 빌드 완료

**파일**: `output/<slug>/index.html` (브라우저 자동 오픈됨)
**부산물**: `output/<slug>/outline.md` (콘텐츠만, 재사용 가능)
**총 슬라이드**: 7장
**테마**: dark

### 다운로드
- 우측 상단 "📦 Download ZIP" 버튼 → 7장 PNG 일괄 다운로드
- "🖼 Save PNG" → 첫 슬라이드만 단일 PNG

### 수정
- 콘텐츠 수정: outline.md 편집 후 재빌드 요청
- 레이아웃 변경: 슬라이드 N번을 ~로 바꿔줘
- 테마 변경: "light로 다시 만들어줘"
```

## Output Conventions

- 작업 파일: 사용자 CWD의 `output/<slug>/` 아래
- 슬러그: 짧은 lowercase-hyphen-가능한-한글 (예: `transformer-self-attention`)
- 파일명: `index.html` (메인), `outline.md` (콘텐츠), `preview.html` (Gate 2)
- 이미지 폴더: `output/<slug>/images/` (사용자가 추가하는 이미지용)

## Resource Files

- `assets/template.html` — 시드 HTML (CSS+JS 인라인, self-contained)
- `references/layouts.md` — 8+ 레이아웃 스니펫 (paste-ready)
- `references/themes.md` — light/dark/paper 3개 테마 정의 + 사용 가이드
- `references/components.md` — 타이포·그리드·아이콘·callout 디테일
- `references/checklist.md` — P0/P1/P2 품질 게이트
- `references/lecture-tone.md` — 강의 글쓰기 톤 (학술과 다름)

## Tone (사용자에게 보고할 때)

- 결과 먼저 (생성된 파일 경로 + 자동 오픈)
- "테마 변경"이나 "레이아웃 교체" 같은 다음 액션 가이드
- 한국어 brief → 한국어 응답

## Examples of Good Briefs

- "Transformer 강의 자료 만들어줘, 다크 테마"
- "Self-Attention 컨셉 노트로 강의 슬라이드 5장"
- "이번 주 랩 세미나 자료 — Diffusion Model 기초"
- "튜토리얼 슬라이드 — Python decorator, 후배용, light 테마"
- "블로그 카드 자료 — 머신러닝 평가 지표 5개, 1:1 정사각" (확장 신호)

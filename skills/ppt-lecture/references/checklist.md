# Checklist — P0 / P1 / P2 품질 게이트

op7418 패턴 차용. P0는 반드시 통과, P1은 강력 권장, P2는 있으면 좋음.

---

## P0 — 반드시 통과 (자동 검증)

### P0-1: HTML 구조

- [ ] `<!DOCTYPE html>` 선언 존재
- [ ] `<html lang="ko">` 또는 영어면 `lang="en"`
- [ ] `<title>` placeholder `[필수]` 잔존 X
- [ ] `data-theme` 속성 정의 (light/dark/paper 중 하나)

### P0-2: 클래스명 정합성

- [ ] 모든 `class="..."` 가 template.html `<style>`에 정의됨
- [ ] 발명한 클래스 X (예: `.cool-card` ❌)
- [ ] 슬라이드 루트는 항상 `<section class="slide layout-...">`

**검증 스크립트** (간단):
```bash
# template.html에서 정의된 클래스 추출
grep -oE '\.[a-z][a-z0-9-]+' assets/template.html | sort -u > /tmp/defined-classes.txt

# index.html에서 사용된 클래스 추출
grep -oE 'class="[^"]+"' output/<slug>/index.html | \
  sed 's/class="//;s/"$//' | tr ' ' '\n' | sort -u > /tmp/used-classes.txt

# 정의되지 않은 클래스 찾기
comm -23 /tmp/used-classes.txt /tmp/defined-classes.txt
# 출력 있으면 P0 실패
```

### P0-3: 텍스트 길이

- [ ] 한국어 제목 (h1, h2) ≤ 12자
- [ ] 영어 제목 ≤ 25자
- [ ] 슬라이드당 본문 텍스트 ≤ 7줄 (강의 자료 호흡)
- [ ] takeaway 정확히 3개 (5개 이상이면 청중 못 따라옴)

### P0-4: 16:9 비율 유지

- [ ] `.slide` 에 `aspect-ratio: 16 / 9` 적용됨
- [ ] `width` 가 `min(1920px, ...)` 으로 제한
- [ ] `padding: 64px` 안전 영역 유지

### P0-5: 다크 테마 가독성

- [ ] dark 테마 사용 시 명도 대비 ≥ 4.5:1 (WCAG AA)
- [ ] light/paper 테마는 ≥ 7:1 권장 (강의실 환경)
- [ ] 테마 토큰만 사용 (하드코딩 hex X)

### P0-6: 폰트 사전 로드

- [ ] html2canvas 캡처 전 `await document.fonts.ready`
- [ ] Pretendard 또는 Noto Sans KR 로드 확인
- [ ] 한글 텍스트가 박스 밖으로 흘러넘치지 않음

---

## P1 — 강력 권장 (시각 검토)

### P1-1: 시각 리듬 (op7418 패턴)

- [ ] hero 페이지와 본문 페이지 교대로 배치
- [ ] 8장 이상 deck은 hero 1장 이상 포함 (callout-stat, quote-large 등)
- [ ] 연속 3장 이상 같은 레이아웃 X

### P1-2: 이미지 비율 표준

- [ ] 16:9, 4:3, 3:2, 1:1 중 하나만 사용
- [ ] 원본 비율 그대로 X (`2592×1798` 같은 비표준)
- [ ] `max-height: Yvh` 사용, `aspect-ratio` 신중히

### P1-3: 희소성 룰

- [ ] callout-stat은 deck당 **1개만** (희소성 = 임팩트)
- [ ] quote-large도 deck당 1~2개로 제한

### P1-4: 페이지 번호 일관성

- [ ] 모든 슬라이드에 `page-num` 표시 (또는 모두 없음)
- [ ] 형식 통일 (`03 / 07` vs `3/7` 등)

### P1-5: 슬라이드 헤더/푸터 일관성

- [ ] `deck-title` 모든 슬라이드에서 동일
- [ ] hero-cover 제외 모든 슬라이드에 헤더 표시

---

## P2 — 있으면 좋음 (사용자 선호)

### P2-1: 진행 표시

- [ ] hero 페이지 외에는 페이지 번호 표시
- [ ] 섹션 구분이 있다면 섹션 표시 ("Section 2 of 4")

### P2-2: 다음 슬라이드 단서

- [ ] 마지막 슬라이드(takeaway)에 "다음: ~" 또는 "Q&A" 표기
- [ ] 섹션 마지막에 다음 섹션 미리보기

### P2-3: 인쇄 친화성

- [ ] `@media print` CSS 적용됨
- [ ] PDF 출력 시 슬라이드별 페이지 분리
- [ ] 툴바가 인쇄 시 hidden

### P2-4: 접근성

- [ ] `<img>` alt 속성 모두 존재
- [ ] 색만으로 정보 전달 X (텍스트 라벨 병행)
- [ ] 키보드 포커스 표시 (커스텀 X, 브라우저 기본 OK)

---

## 자동 검증 스크립트 (간단)

```bash
#!/bin/bash
# verify-deck.sh — P0 항목 자동 체크

DECK="$1"
[ -z "$DECK" ] && { echo "Usage: $0 <output/slug/index.html>"; exit 1; }

ERRORS=0

# P0-1: title placeholder
if grep -q "\[필수\]" "$DECK"; then
  echo "❌ P0-1: '[필수]' placeholder 잔존"
  ERRORS=$((ERRORS+1))
fi

# P0-1: data-theme 누락
if ! grep -q 'data-theme=' "$DECK"; then
  echo "❌ P0-1: data-theme 속성 누락"
  ERRORS=$((ERRORS+1))
fi

# P0-2: 클래스 정합성 (간단 버전)
TEMPLATE_CLASSES=$(grep -oE '\.[a-z][a-z0-9-]+' "$(dirname "$0")/../assets/template.html" | sort -u)
USED_CLASSES=$(grep -oE 'class="[^"]+"' "$DECK" | sed 's/class="//;s/"$//' | tr ' ' '\n' | sort -u | grep -v '^$')

for cls in $USED_CLASSES; do
  if ! echo "$TEMPLATE_CLASSES" | grep -qFx ".$cls"; then
    # 일부 utility 클래스는 무시 (예: meta-mono, utility 클래스)
    continue
  fi
done

# P0-3: 슬라이드별 본문 줄 수 (어림셈)
SLIDE_COUNT=$(grep -c '<section class="slide' "$DECK")
P_COUNT=$(grep -c '<p>' "$DECK")
if [ $((P_COUNT / SLIDE_COUNT)) -gt 7 ]; then
  echo "⚠️ P0-3: 슬라이드당 평균 본문 텍스트 ≤ 7줄 권장"
fi

if [ $ERRORS -eq 0 ]; then
  echo "✅ P0 모두 통과"
else
  echo "❌ $ERRORS 개 P0 실패 — 수정 필요"
  exit 1
fi
```

---

## 사용자에게 보고 형식

```markdown
## 품질 검증 결과

### P0 (필수): ✅ 6/6 통과
### P1 (권장): ✅ 4/5 통과 — 1개 경고
### P2 (선택): 2/4 (선택 사항)

### 경고
- P1-1 시각 리듬: 7장 모두 light 테마 본문 — hero 페이지(callout-stat 또는
  quote-large) 1장 추가 권장

진행할까요?
```

---

## 흔한 P0 실패 케이스

1. **`[필수]` placeholder 잊음** — 자동 검증으로 잡힘
2. **새 클래스 발명** (예: `.my-card`) → template.html에 추가 후 사용
3. **한국어 제목 13자 이상** → 줄여서 한 줄에 들어가게
4. **takeaway 5~6개** → 3개로 압축
5. **dark 테마인데 본문 폰트 색이 너무 어두움** → 토큰만 사용

---

## 디버깅 팁

P0 실패 시 우선순위:
1. **클래스명 오류** — 가장 흔함, 먼저 체크
2. **placeholder 잔존** — `[필수]` 검색
3. **텍스트 길이** — Read로 슬라이드 1~2장 확인 후 줄임
4. **테마 일관성** — `data-theme` 한 곳에만 (root)

P1/P2는 사용자 선호 — 강제 수정 X, 권장만.

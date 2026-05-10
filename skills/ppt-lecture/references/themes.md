# Themes — light / dark / paper

3개 테마 프리셋. **사용자 hex 자유 입력 거부** (op7418 패턴 — 미적 일관성
보호). 한 deck에서 한 테마만.

---

## Theme 1: light (강의실 프로젝터)

**Use when:**
- 강의실 발표 (대형 프로젝터 흰 배경)
- 일반 강의 / 세미나 / 워크샵
- 결정 못 하면 기본값

**컬러 토큰**:
```css
:root[data-theme="light"] {
  --bg:        #FAFAFA;  /* 배경 - 거의 흰색 */
  --bg-sub:   #F0F0F0;  /* 카드 배경 */
  --fg:        #1A1A1A;  /* 본문 텍스트 */
  --fg-sub:   #4A4A4A;  /* 보조 텍스트 */
  --accent:    #2C3E50;  /* 강조 (제목, 숫자) */
  --accent-lt: #3498DB;  /* 보조 강조 (링크, 호버) */
  --muted:     #6C757D;  /* 비활성 텍스트 */
  --border:    #E0E0E0;  /* 구분선 */
}
```

**적용**: `<html lang="ko" data-theme="light">`

**시각 특징**:
- 명도 대비 13.6:1 (WCAG AAA)
- 학술 미니멀 베이스 (HEROlab 영향)
- 프로젝터에서 색번짐 최소

---

## Theme 2: dark (블로그 임베드)

**Use when:**
- 블로그 / Medium / Twitter 임베드
- 어두운 환경에서 보는 강의
- 코드 예제 많은 슬라이드 (다크 모드 코드 친화)
- 발표자보다 시청자가 디바이스로 직접 볼 때

**컬러 토큰**:
```css
:root[data-theme="dark"] {
  --bg:        #0F1419;  /* 거의 검은색 (Tokyo Night 톤) */
  --bg-sub:   #1A2027;  /* 카드 배경 */
  --fg:        #E8E8E8;  /* 본문 (off-white) */
  --fg-sub:   #B8B8B8;
  --accent:    #61DAFB;  /* React blue (밝게) */
  --accent-lt: #FFA657;  /* GitHub orange */
  --muted:     #8B949E;
  --border:    #30363D;
}
```

**적용**: `<html lang="ko" data-theme="dark">`

**시각 특징**:
- 명도 대비 15.8:1 (WCAG AAA)
- 차가운 블루 + 따뜻한 오렌지 = IT/개발 톤
- 야간 시청 시 눈 피로 ↓

---

## Theme 3: paper (출력 / 종이 질감)

**Use when:**
- 인쇄 / PDF 출력 후 배포
- 종이 핸드아웃
- 빈티지 / 인문학 톤이 필요할 때
- 출판물 같은 느낌 원할 때

**컬러 토큰**:
```css
:root[data-theme="paper"] {
  --bg:        #F5F1E8;  /* 크림 종이 */
  --bg-sub:   #EAE2D0;
  --fg:        #2C2418;  /* 진한 갈색 */
  --fg-sub:   #5A4F40;
  --accent:    #8B4513;  /* Saddle brown */
  --accent-lt: #C25E3C;  /* 따뜻한 빨강 */
  --muted:     #6B5D4F;
  --border:    #D4C9B0;
}
```

**적용**: `<html lang="ko" data-theme="paper">`

**시각 특징**:
- 명도 대비 7.8:1 (WCAG AA, 인쇄 친화)
- 따뜻한 톤 = 신뢰감 / 전통적
- 출력 시 잉크 절약 (컬러 X, 톤만)

---

## 테마 추론 룰 (Gate 1)

사용자가 명시 안 하면:

```
사용자 입력에 키워드:
├─ "강의실 / 발표 / 세미나 / 학교" → light
├─ "블로그 / Twitter / 공유 / 소셜 / 다크" → dark
├─ "출력 / 인쇄 / 종이 / 핸드아웃 / 빈티지" → paper
└─ 매칭 없음 → light (기본) + 사용자 확인
```

확인 메시지 (모호할 때):
```markdown
어떤 환경에서 발표/공유하실 건가요?

1. 강의실 프로젝터 → **light** (밝은 배경)
2. 블로그/Twitter 임베드 → **dark** (어두운 배경)
3. 인쇄/배포 → **paper** (종이 질감)

기본값: light. 이대로 진행할까요?
```

---

## 사용자 hex 요청 처리

사용자가 "메인 컬러 #FF6600으로" 같이 요청하면:

```markdown
죄송하지만 이 스킬은 미적 일관성 보호를 위해 3개 프리셋 중 선택만
지원합니다. (커스텀 색상은 폰트/대비/그림자와의 균형이 깨지기 쉬워요.)

3개 중 가장 가까운 톤:
- **paper**: 따뜻한 갈색/주황 톤 (#FF6600과 유사)
- **dark**: 어두운 배경 + 오렌지 액센트 (#FFA657)

또는 직접 CSS 수정도 가능합니다 (template.html `:root`):
```css
:root[data-theme="custom"] {
  --accent: #FF6600;
  /* 다른 토큰도 균형 맞춰 조정 필요 */
}
```
```

---

## 테마 변경 워크플로우

이미 빌드된 deck의 테마만 바꾸려면:

```html
<!-- index.html -->
<html lang="ko" data-theme="dark">  <!-- light → dark -->
```

**한 줄만 수정**하면 모든 컬러가 변수 기반이라 자동 적용. 다른 CSS는 X.

```bash
# 자동화 (sed로 한 줄 교체)
sed -i '' 's/data-theme="light"/data-theme="dark"/' output/<slug>/index.html
```

---

## 테마별 권장 레이아웃

테마와 레이아웃의 궁합:

| 레이아웃 | light | dark | paper |
|:---|:---:|:---:|:---:|
| hero-cover | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ |
| flow-3step | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ |
| side-by-side | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ |
| bento-2x2/3x2 | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ |
| timeline-h | ⭐⭐ | ⭐⭐ | ⭐⭐⭐ |
| callout-stat | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ |
| takeaway | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ |
| quote-large | ⭐⭐ | ⭐⭐ | ⭐⭐⭐ |

paper 테마는 timeline / quote에 특히 잘 어울림 (출판물 느낌).

---

## 흔한 실수

1. **테마 중간 교체** — 룰 #3 위반, 시각 일관성 깨짐
2. **dark 테마에 너무 작은 폰트** — 어두운 배경에서 가독성 ↓ → 본문 ≥ 1.5vw 유지
3. **paper 테마에 차트** — 색상 톤이 단조로워 차트 가독성 ↓ → 차트 슬라이드는 light 권장
4. **light 테마에 짙은 그림자** — 미니멀 톤 깨짐 → `--border` 사용, `box-shadow` 최소화

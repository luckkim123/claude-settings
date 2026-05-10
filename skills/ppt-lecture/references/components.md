# Components — 타이포 / 그리드 / 컴포넌트 디테일

template.html에 정의된 모든 컴포넌트의 상세 명세.

---

## 타이포그래피 시스템

### 폰트 패밀리

```css
/* 기본 (한국어 + 영어) */
font-family: "Pretendard", "Pretendard Variable", "Noto Sans KR",
             -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;

/* 모노스페이스 (메타데이터, 코드, 페이지번호) */
.meta-mono { font-family: "JetBrains Mono", "SF Mono", Consolas, monospace; }
```

**우선순위**:
1. Pretendard (claude-settings install로 자동 설치)
2. Pretendard Variable (CDN 또는 시스템)
3. Noto Sans KR (Google Fonts CDN, 자동 fallback)
4. 시스템 sans-serif (최종 fallback)

### 사이즈 (vw 단위, 16:9 기준 자동 스케일)

| 요소 | 사이즈 | 두께 | 용도 |
|:---|:---|:---|:---|
| `h1` | 4.5vw | 800 | hero 메인 제목 |
| `h2` | 2.8vw | 700 | 일반 슬라이드 제목 |
| `h3` | 2.0vw | 600 | 부제, 섹션 제목 |
| `p`, `li` | 1.5vw | 400 | 본문 |
| `.meta` | 1.0vw | 400 | 메타데이터 (날짜, 카테고리) |
| `.stat-num` | 12vw | 900 | callout-stat 큰 숫자 |
| `.stat-label` | 1.8vw | 400 | stat 설명 |

### 두께 (Pretendard 기준)

- 400 (Regular) — 본문
- 500 (Medium) — 보조 강조
- 600 (SemiBold) — h3
- 700 (Bold) — h2
- 800 (ExtraBold) — h1
- 900 (Black) — 큰 숫자

---

## 컬러 토큰 사용 규칙

| 토큰 | 용도 | 절대 사용 X |
|:---|:---|:---|
| `--bg` | 슬라이드 배경 | 텍스트 |
| `--bg-sub` | 카드/박스 배경 | 슬라이드 전체 배경 |
| `--fg` | 메인 텍스트 (제목, h1) | 보조 정보 |
| `--fg-sub` | 본문 텍스트 (p, li) | 제목 |
| `--accent` | 강조 (h2, 큰 숫자, 강조 박스) | 본문 |
| `--accent-lt` | 보조 강조 (링크, hover) | 메인 강조 |
| `--muted` | 비활성/메타 텍스트 | 본문 |
| `--border` | 구분선, 카드 테두리 | 텍스트 색 |

**룰**: 하드코딩된 hex 사용 금지. 항상 `var(--token)` 사용.

---

## 그리드 시스템

### 슬라이드 박스

```css
.slide {
  width: min(1920px, calc(100vw - 48px));  /* 최대 1920px, 화면 폭 96% */
  aspect-ratio: 16 / 9;                     /* 1920×1080 */
  padding: 64px;                            /* 안전 영역 */
  display: flex;
  flex-direction: column;
}
```

**룰**: padding 64px = 안전 영역. 콘텐츠가 이 영역 밖으로 나가면 가독성 ↓.

### 그리드 패턴

```css
/* flow-3step: 1fr arrow 1fr arrow 1fr */
.flow-grid {
  grid-template-columns: 1fr auto 1fr auto 1fr;
}

/* side-by-side: 1fr divider 1fr */
.compare-grid {
  grid-template-columns: 1fr auto 1fr;
}

/* bento-2x2 */
.bento-2x2 .bento-grid {
  grid-template-columns: 1fr 1fr;
  grid-template-rows: 1fr 1fr;
}

/* bento-3x2 */
.bento-3x2 .bento-grid {
  grid-template-columns: 1fr 1fr 1fr;
  grid-template-rows: 1fr 1fr;
}

/* timeline-h: 자동 생성 */
.timeline-grid {
  grid-auto-flow: column;
  grid-auto-columns: 1fr;
}
```

### gap 표준

- `gap: 24px` — 슬라이드 내부 일반
- `gap: 32px` — 큰 섹션 간 (compare-grid)
- `gap: 16px` — 작은 요소 간 (bento-cell 내부)

---

## 컴포넌트 카탈로그

### slide-header

슬라이드 상단 — deck 제목 + 페이지 번호.

```html
<div class="slide-header">
  <div class="deck-title">덱 제목</div>
  <div class="page-num meta-mono">03 / 07</div>
</div>
```

- 모든 슬라이드 공통 (hero-cover 제외 가능)
- 하단 1px 구분선 자동
- 폰트 0.9vw, 색 `--muted`

### slide-footer

슬라이드 하단 — 메타 정보, 다음 슬라이드 단서.

```html
<div class="slide-footer">
  <div>왼쪽 메타</div>
  <div>오른쪽 메타</div>
</div>
```

- `margin-top: auto`로 자동 하단 정렬
- 비어있어도 OK (`<div class="slide-footer"></div>`)

### bento-cell

bento 그리드의 단일 셀.

```html
<div class="bento-cell">
  <div class="cell-num meta-mono">01</div>
  <div class="cell-title">제목</div>
  <p>설명 텍스트</p>
</div>
```

- 카드 배경 + 둥근 모서리
- `cell-num` 0.9vw / accent 컬러
- `cell-title` 1.6vw / 700

### timeline-step

타임라인의 단일 단계.

```html
<div class="timeline-step">
  <div class="timeline-dot"></div>
  <div class="step-num meta-mono">2024</div>
  <h3>이벤트</h3>
  <p>설명</p>
</div>
```

- 점선 자동 (CSS `::before`)
- 점 16×16, accent 컬러

### callout-stat 구조

```html
<section class="slide layout-callout-stat">
  <div class="stat-num">96.8%</div>
  <div class="stat-label">설명 라벨</div>
  <p>추가 설명 (선택)</p>
</section>
```

- 12vw 크기 숫자가 시선 집중
- 슬라이드 중앙 정렬 자동

### quote-large 구조

```html
<section class="slide layout-quote-large">
  <div class="quote-mark">"</div>
  <div class="quote-body">인용문</div>
  <div class="quote-author">— 저자</div>
</section>
```

- `quote-mark` serif 폰트 (장식)
- `quote-body` 3vw / 600
- `quote-author` 1.2vw / muted

---

## 인터랙션 / JS

### 다운로드 툴바

화면 우상단 고정. CSS:
```css
.toolbar {
  position: fixed;
  top: 16px; right: 16px;
  z-index: 1000;
}
```

버튼 2개:
- `#btn-zip` — 모든 슬라이드 PNG ZIP
- `#btn-png` — 첫 슬라이드만 PNG

### html2canvas 캡처

```js
// 폰트 사전 로드 필수 (한글 깨짐 방지)
await document.fonts.ready;

const canvas = await html2canvas(slideEl, {
  scale: 2,           // 2x DPI (retina)
  useCORS: true,
  backgroundColor: '...'
});
```

**룰**:
- `scale: 2` — 출력 해상도 3840×2160 (4K)
- `useCORS: true` — CDN 이미지 캡처 가능
- `backgroundColor` — 명시적 (기본값 X)

### 인쇄 모드

`@media print`로 PDF 변환 시:
- `box-shadow` 제거
- `page-break-after: always`로 슬라이드별 분리
- 툴바 hidden

```bash
# Chrome/Edge에서 PDF로 변환
# Cmd+P / Ctrl+P → "PDF로 저장"
# 옵션: "여백: 없음", "배경 그래픽 인쇄"
```

---

## 아이콘 / 이미지

### 아이콘 (필요 시)

- **권장**: 이모지 ❌ (시각 일관성 깨짐)
- **선호**: 텍스트 + 위치 (좌→우 화살표 등) 또는 SVG inline
- **op7418 패턴**: Lucide 아이콘 라이브러리 (필요 시 추가)

### 이미지

```html
<img src="./images/diagram.png" alt="설명">
```

**룰**:
- 상대 경로 `./images/` 사용
- 비율: 16:9 / 4:3 / 1:1만 (원본 비율 X)
- 크기: 최소 1600px wide (대형 디스플레이 대비)

---

## 흔한 실수

1. **vw 대신 px 하드코딩** — 화면 크기 변하면 깨짐
2. **var(--token) 대신 hex** — 테마 변경 시 안 바뀜
3. **`<i>` 이모지 사용** — 미적 일관성 ↓
4. **slide-header 누락** — 페이지 번호 없으면 발표 시 헷갈림
5. **gap 없이 빽빽** — 가독성 ↓, 학술 미니멀 톤 깨짐

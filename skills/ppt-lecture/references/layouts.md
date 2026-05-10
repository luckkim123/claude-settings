# Layouts — paste-ready 스니펫

각 레이아웃은 `<section class="slide layout-...">`로 시작하는 단일 블록.
template.html의 `<style>`에 모든 클래스가 정의되어 있다 (Hard Rule #2).

---

## Pre-flight 체크 (각 슬라이드 작성 전)

사용할 클래스명이 template.html에 정의되어 있는지 확인:

```
필수 클래스 (모든 layout):
slide / slide-header / slide-footer / deck-title / page-num / meta-mono

레이아웃별:
layout-hero-cover    → meta-row / meta
layout-flow-3step    → flow-grid / flow-step / flow-arrow / step-num / step-title
layout-side-by-side  → compare-grid / compare-col / compare-divider
layout-bento-2x2/3x2 → bento-grid / bento-cell / cell-num / cell-title
layout-timeline-h    → timeline-grid / timeline-step / timeline-dot
layout-callout-stat  → stat-num / stat-label
layout-takeaway      → takeaway-list / takeaway-item / takeaway-num / takeaway-text
layout-quote-large   → quote-mark / quote-body / quote-author
```

빠진 클래스 발견 시 template.html `<style>` 블록에 추가하고 이 파일도 업데이트.

---

## Layout 1 — hero-cover (표지)

**Use when**: 첫 슬라이드, 섹션 도입부, 강한 임팩트 필요한 페이지

```html
<section class="slide layout-hero-cover" data-slide-id="1">
  <div class="slide-header">
    <div class="deck-title">Transformer Self-Attention</div>
    <div class="page-num meta-mono">01 / 07</div>
  </div>

  <div class="meta-row meta-mono">
    <span class="meta">DEEP LEARNING</span>
    <span class="meta">2026-05-10</span>
  </div>

  <h1>Self-Attention</h1>
  <h2 style="margin-top: 24px;">왜 RNN이 졌는가</h2>

  <div class="slide-footer">
    <div>김승민</div>
    <div>HEROlab — ML Seminar</div>
  </div>
</section>
```

**룰**: 메인 제목 ≤ 12자(한국어), 부제 ≤ 25자.

---

## Layout 2 — flow-3step (좌→우 프로세스)

**Use when**: 3단계 순차 흐름, 입력→처리→출력, A→B→C

```html
<section class="slide layout-flow-3step" data-slide-id="3">
  <div class="slide-header">
    <div class="deck-title">Transformer Self-Attention</div>
    <div class="page-num meta-mono">03 / 07</div>
  </div>

  <h2>Q, K, V 분해</h2>

  <div class="flow-grid">
    <div class="flow-step">
      <div class="step-num meta-mono">STEP 01</div>
      <div class="step-title">Query</div>
      <p>"무엇을 찾고 있나"</p>
    </div>
    <div class="flow-arrow">→</div>
    <div class="flow-step">
      <div class="step-num meta-mono">STEP 02</div>
      <div class="step-title">Key</div>
      <p>"이게 그것이다"</p>
    </div>
    <div class="flow-arrow">→</div>
    <div class="flow-step">
      <div class="step-num meta-mono">STEP 03</div>
      <div class="step-title">Value</div>
      <p>"실제 정보"</p>
    </div>
  </div>

  <div class="slide-footer">
    <div>입력 → 3개 행렬 → 가중합</div>
    <div></div>
  </div>
</section>
```

---

## Layout 3 — side-by-side (좌우 비교)

**Use when**: A vs B 비교, before/after, RNN vs Transformer

```html
<section class="slide layout-side-by-side" data-slide-id="4">
  <div class="slide-header">
    <div class="deck-title">Transformer Self-Attention</div>
    <div class="page-num meta-mono">04 / 07</div>
  </div>

  <h2>RNN vs Transformer</h2>

  <div class="compare-grid">
    <div class="compare-col">
      <div class="step-num meta-mono">RNN</div>
      <h3>순차 처리</h3>
      <p>이전 hidden state 의존</p>
      <p>병렬화 불가</p>
      <p>긴 시퀀스 정보 손실</p>
    </div>
    <div class="compare-divider">VS</div>
    <div class="compare-col">
      <div class="step-num meta-mono">TRANSFORMER</div>
      <h3>병렬 처리</h3>
      <p>모든 위치 동시 계산</p>
      <p>GPU 병렬화 가능</p>
      <p>장거리 의존 직접 학습</p>
    </div>
  </div>

  <div class="slide-footer">
    <div>2017년 이후 NLP 표준 변경</div>
    <div></div>
  </div>
</section>
```

---

## Layout 4 — bento-2x2 (4개 동등 항목)

**Use when**: 4개 핵심 특성, 4개 카테고리, 순서 없는 동등 나열

```html
<section class="slide layout-bento-2x2" data-slide-id="5">
  <div class="slide-header">
    <div class="deck-title">Transformer Self-Attention</div>
    <div class="page-num meta-mono">05 / 07</div>
  </div>

  <h2>4가지 핵심 특성</h2>

  <div class="bento-grid">
    <div class="bento-cell">
      <div class="cell-num meta-mono">01</div>
      <div class="cell-title">병렬 처리</div>
      <p>모든 위치 동시 계산</p>
    </div>
    <div class="bento-cell">
      <div class="cell-num meta-mono">02</div>
      <div class="cell-title">장거리 의존</div>
      <p>O(1) hop으로 모든 토큰 접근</p>
    </div>
    <div class="bento-cell">
      <div class="cell-num meta-mono">03</div>
      <div class="cell-title">위치 인코딩</div>
      <p>순서 정보 별도 추가</p>
    </div>
    <div class="bento-cell">
      <div class="cell-num meta-mono">04</div>
      <div class="cell-title">멀티 헤드</div>
      <p>여러 관점에서 동시 attention</p>
    </div>
  </div>

  <div class="slide-footer"></div>
</section>
```

---

## Layout 5 — bento-3x2 (6개 동등 항목)

**Use when**: 6개 항목 (4개 부족, 8개는 너무 많을 때)

```html
<section class="slide layout-bento-3x2" data-slide-id="6">
  <div class="slide-header">...</div>
  <h2>6가지 응용 분야</h2>
  <div class="bento-grid">
    <!-- bento-cell 6개 -->
    <div class="bento-cell">...</div>
    <!-- ... -->
  </div>
  <div class="slide-footer"></div>
</section>
```

---

## Layout 6 — timeline-h (수평 타임라인)

**Use when**: 시간 순서 단계, 4~6개 진행 단계

```html
<section class="slide layout-timeline-h" data-slide-id="7">
  <div class="slide-header">...</div>

  <h2>Transformer 발전 역사</h2>

  <div class="timeline-grid">
    <div class="timeline-step">
      <div class="timeline-dot"></div>
      <div class="step-num meta-mono">2017</div>
      <h3>Original</h3>
      <p>Attention is all you need</p>
    </div>
    <div class="timeline-step">
      <div class="timeline-dot"></div>
      <div class="step-num meta-mono">2018</div>
      <h3>BERT</h3>
      <p>Bidirectional encoding</p>
    </div>
    <div class="timeline-step">
      <div class="timeline-dot"></div>
      <div class="step-num meta-mono">2020</div>
      <h3>GPT-3</h3>
      <p>Few-shot learning</p>
    </div>
    <div class="timeline-step">
      <div class="timeline-dot"></div>
      <div class="step-num meta-mono">2023+</div>
      <h3>Multimodal</h3>
      <p>Vision + language</p>
    </div>
  </div>

  <div class="slide-footer"></div>
</section>
```

---

## Layout 7 — callout-stat (큰 숫자 강조)

**Use when**: 강력한 단일 통계, 인상적인 숫자, 데이터 임팩트
**룰**: deck당 1개만 (희소성). 너무 많이 쓰면 임팩트 사라짐.

```html
<section class="slide layout-callout-stat" data-slide-id="6">
  <div class="slide-header">
    <div class="deck-title">Transformer Self-Attention</div>
    <div class="page-num meta-mono">06 / 07</div>
  </div>

  <div class="stat-num">96.8%</div>
  <div class="stat-label">GPT-4 MMLU 정확도</div>
  <p style="margin-top: 16px; max-width: 60vw; text-align: center;">
    인간 평균(89%)을 능가하는 수준 — Transformer 등장 6년 만의 성취
  </p>
</section>
```

---

## Layout 8 — takeaway (마무리 정리)

**Use when**: 마지막 슬라이드, 섹션 마무리, 3가지 핵심 요약

```html
<section class="slide layout-takeaway" data-slide-id="7">
  <div class="slide-header">
    <div class="deck-title">Transformer Self-Attention</div>
    <div class="page-num meta-mono">07 / 07</div>
  </div>

  <h2>핵심 정리</h2>

  <div class="takeaway-list">
    <div class="takeaway-item">
      <div class="takeaway-num">01</div>
      <div class="takeaway-text">RNN은 순차, Transformer는 병렬</div>
    </div>
    <div class="takeaway-item">
      <div class="takeaway-num">02</div>
      <div class="takeaway-text">Q·K·V로 어디를 볼지 학습</div>
    </div>
    <div class="takeaway-item">
      <div class="takeaway-num">03</div>
      <div class="takeaway-text">Multi-head로 여러 관점 동시</div>
    </div>
  </div>

  <div class="slide-footer">
    <div>다음: Multi-Head Attention 상세</div>
    <div>질문은 luckkim123@gmail.com</div>
  </div>
</section>
```

**룰**: takeaway 정확히 3개. 5개면 청중이 못 따라옴.

---

## Layout 9 (Extra) — quote-large (대형 인용)

**Use when**: 인상적인 인용문, 섹션 도입부, 핵심 메시지 강조

```html
<section class="slide layout-quote-large" data-slide-id="2">
  <div class="quote-mark">"</div>
  <div class="quote-body">
    Attention is all you need.
  </div>
  <div class="quote-author">
    — Vaswani et al., 2017 (NeurIPS)
  </div>
</section>
```

---

## Layout 10 (Extra) — pyramid (계층 구조)

직접 정의 (template.html에 미포함). 필요시 구현 후 등록.

---

## 레이아웃 선택 디시전 트리

```
콘텐츠 구조?
├─ 표지 / 도입 → hero-cover
├─ 인용 강조 → quote-large
├─ 순차 흐름 (3단계) → flow-3step
├─ 시간 순서 (4~6단계) → timeline-h
├─ A vs B → side-by-side
├─ 동등 4개 → bento-2x2
├─ 동등 6개 → bento-3x2
├─ 큰 숫자 → callout-stat (deck당 1번만!)
├─ 마무리 → takeaway
└─ 계층 → pyramid (필요시 정의)
```

---

## 흔한 실수

1. **클래스명 발명** — template.html에 없는 클래스 사용 → 스타일 깨짐
2. **callout-stat 남용** — deck당 1개 룰 어김 → 임팩트 X
3. **bento에 7~8개** — 폭이 좁아 가독성 ↓ → bento 한 장 더 분할
4. **flow-3step에 5단계** — 화면이 너무 빽빽 → timeline-h로 변경
5. **quote-large에 긴 문장** — 한 줄 ≤ 30자, 두 줄까지만

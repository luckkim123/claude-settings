# Visual Verification — 시각 검증 절차

PPTX 빌드 후 PNG로 렌더링하여 레이아웃 문제를 자동 검출하는 절차.
mckinsey-slide-agent의 패턴을 차용.

---

## 왜 시각 검증이 필요한가

빌드는 성공해도 렌더링 시점에만 보이는 문제가 많다:
- 텍스트가 카드/박스 경계 밖으로 흘러넘침
- 라벨이 도형 뒤에 가려짐
- 제목이 underline rule과 겹침
- 차트 값 라벨이 서로 겹침
- 한글이 박스보다 넓게 출력됨 (1.3배 폭 무시)

빌드 시점에는 알 수 없고, 사용자가 PowerPoint로 열어보기 전엔 미발견.

---

## 의존성

- **soffice** (LibreOffice headless): PPTX → PDF 변환
- **pdftoppm** (poppler): PDF → PNG 변환

확인:
```bash
command -v soffice && command -v pdftoppm
```

설치 (도구 없는 경우):
- Mac: `brew install --cask libreoffice && brew install poppler`
- Windows: `winget install TheDocumentFoundation.LibreOffice && winget install oschwartz10612.Poppler`

claude-settings의 install.sh는 LibreOffice를 자동 설치하지 않음 (700MB, 무거움).
**시각 검증 도구 없으면 검증 단계 생략**, 사용자에게 명시.

---

## 절차

### 1. PNG 디렉토리 준비

```bash
mkdir -p output/preview_<slug>
```

### 2. PPTX → PDF (soffice headless)

```bash
soffice --headless --convert-to pdf \
  --outdir output/preview_<slug> \
  output/<slug>.pptx
```

- 출력: `output/preview_<slug>/<slug>.pdf`
- 보통 1초~5초 소요 (deck 크기에 따라)

**troubleshooting**:
- "soffice: command not found" → LibreOffice 설치 필요
- "Permission denied" → 첫 실행 시 macOS 보안 경고 → 시스템 환경설정 > 보안에서 허용
- 변환 결과가 비어있음 → PPTX 파일이 손상됨 → rebuild

### 3. PDF → PNG (pdftoppm)

```bash
pdftoppm -png -r 80 \
  output/preview_<slug>/<slug>.pdf \
  output/preview_<slug>/slide
```

- 출력: `output/preview_<slug>/slide-1.png`, `slide-2.png`, ...
- 옵션:
  - `-png`: PNG 포맷 (대안: `-jpeg`)
  - `-r 80`: 80 DPI (시각 검증용으로 충분, 빠름. 최종 검토용 200+ DPI)
- 파일명 패턴: `<prefix>-<page>.png` (1-indexed)

**troubleshooting**:
- 흐릿함 → `-r 200`으로 DPI 증가
- 너무 큼 → `-r 60` 또는 더 낮게

### 4. Read 도구로 PNG 검사

전체 슬라이드를 다 보지 않고, **2~3장만 샘플링**:
- 1번 (cover)
- 중간 (예: 8번)
- 마지막 본문 (예: 16번)

각 슬라이드마다 체크리스트 적용 → 다음 섹션.

---

## 체크리스트 (slide-by-slide)

### 텍스트 오버플로우
- [ ] 모든 텍스트가 카드/박스 경계 안에 있는가
- [ ] 한글이 박스보다 넓게 출력되지 않는가
- [ ] bullet이 다음 줄로 넘어가지 않는가 (단일 줄 의도)

### 제목 처리
- [ ] 제목이 한 줄에 들어가는가
- [ ] underline rule (y=1.15") 위에 있는가
- [ ] 제목 길이 ≤ 50자 (한국어) / 70자 (영어)

### 차트 라벨
- [ ] x축 카테고리 라벨이 겹치지 않는가
- [ ] y축 값 라벨이 막대와 겹치지 않는가
- [ ] 범례가 차트 영역과 겹치지 않는가

### 도형 / 박스
- [ ] 라벨이 도형 뒤에 가려지지 않는가
- [ ] 화살표/연결선이 정확한 박스를 가리키는가
- [ ] 4-column / 6-column 레이아웃에서 columns 폭이 너무 좁지 않은가

### Placeholder 검출
- [ ] `[Insert ...]` 리터럴이 보이지 않는가
- [ ] `[Description]`, `[Key takeaways]` 리터럴이 없는가
- [ ] 회색 dashed-placeholder 박스가 본문에 없는가

---

## 문제 발견 시 대응

### 텍스트 오버플로우 → 콘텐츠 줄이기

```python
# Before: 너무 길어서 박스 밖으로
b.add("executive_summary_takeaways", sections=[
    {"takeaway": "본 연구는 transformer의 self-attention을 개선하여 메모리 효율성을 크게 향상시켰다",  # 너무 김
     "bullets": [...]}
])

# After: 압축
b.add("executive_summary_takeaways", sections=[
    {"takeaway": "Self-attention 메모리 효율 향상",  # 25자
     "bullets": [...]}
])
```

### 차트 라벨 겹침 → 카테고리 줄이기

```python
# Before: 8개 카테고리 — 너무 빽빽
b.add("column_simple_growth",
      categories=["A", "B", "C", "D", "E", "F", "G", "H"],  # 8개
      values=[1, 2, 3, 4, 5, 6, 7, 8])

# After: 5개로 압축 또는 그룹핑
b.add("column_simple_growth",
      categories=["A", "B", "C", "D", "Others"],  # 5개
      values=[1, 2, 3, 4, 26])  # F+G+H 합산
```

### Placeholder 발견 → 실제 값 또는 명시적 N/A

```python
# Before
b.add("column_simple_growth",
      title="Results",
      categories=[...], values=[...])  # description 누락

# After
b.add("column_simple_growth",
      title="Results",
      categories=[...], values=[...],
      description="베이스라인 대비 BLEU 점수",  # 추가
      takeaway_header="제안 방법이 일관되게 우수")  # 추가
```

---

## 검증 결과 보고

사용자에게:

```markdown
## 시각 검증 결과

✅ Slide 1 (Cover): OK
✅ Slide 8 (Method): OK
⚠️ Slide 14 (Results): x축 카테고리 라벨 겹침 발견 → 5개로 줄여 rebuild
✅ Slide 16 (Conclusion): OK

총 1개 문제 자동 수정 완료. 최종 deck: output/<slug>.pptx
```

도구 없을 때:

```markdown
## 시각 검증 생략

LibreOffice (`soffice`) 또는 poppler (`pdftoppm`)가 없어 자동 시각 검증을
수행하지 못했습니다. PowerPoint 또는 Keynote로 열어 직접 확인 권장:

체크포인트:
- 텍스트가 박스를 넘지 않는지
- 차트 라벨이 겹치지 않는지
- placeholder ([...])가 남아있지 않은지

검증 도구 설치하려면:
- Mac: brew install --cask libreoffice && brew install poppler
- Win: winget install TheDocumentFoundation.LibreOffice + Poppler
```

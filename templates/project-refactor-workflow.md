# Refactor Workflow (project rule template)

> 새 프로젝트에서 다단계 리팩토링을 수행할 때 `<project>/.claude/rules/refactor-workflow.md`로 복사해 사용. 프로젝트별 빌드/테스트 명령에 맞춰 단계명·검증 절차만 조정.

## When to load
- 큰 리팩토링·리포 정비를 단계화할 때
- 알고리즘·동작 영향 가능성이 있는 변경을 머지 전 검증할 때
- 다음 phase 진행 전 직전 phase의 흔적(branch, commit, CHANGELOG)이 남아있는지 확인할 때

## 핵심 원칙

**모든 변경은 추적 가능해야 한다.** 회귀가 발견됐을 때 "어느 phase에서 들어왔는지" 5분 안에 답할 수 있어야 한다. 다음 4축이 항상 동기화돼 있어야 한다.

1. **branch** — phase 단위 분기, 머지 후 squash로 1 commit/phase
2. **commit message** — Conventional Commits + 본문에 변경 내역
3. **CHANGELOG.md** — 패키지/리포 루트에 phase별 항목
4. **PR description** — 위 3개를 GitHub에서 한눈에 볼 수 있게 요약

위 중 하나라도 비어 있으면 추적이 깨진다.

## Phase 분할 기준

| Phase 종류 | 기준 | 예 |
|-----------|------|-----|
| `A` (cleanup) | 동작 영향 0% — dead code/config 제거 | vendored 헤더 삭제 |
| `B-N` (extract) | 동작 보존 split — 클래스/함수 추출, 파일 분리 | 책임 분리 리팩토링 |
| `C-N` (substitute) | 동작 변경 — 새 알고리즘으로 교체 | 알고리즘 교체 |

**Phase A는 회귀 의무 없음.** Phase B/C는 머지 전 회귀 PASS 필수.

## 한 phase의 11단계 절차

```
1. Phase scope 정의            → 한 줄로 요약 가능해야 함
2. Branch 분기                 → refactor/phase-<id>-<short-name>
3. (Phase A 첫 회) Archive 태그 → archive/<repo>-pre-refactor-YYYY-MM-DD at <baseline-sha>
4. (Phase B/C 첫 회) Regression 인프라 → scripts/regression_*.{sh,py}
5. 코드 수정                    → 작은 commit 여러 개 OK (squash로 합쳐짐)
6. 빌드 PASS 확인              → 한 줄 요약 (시간/패키지 수)
7. (Phase B/C) Baseline 측정    → main HEAD 빌드 → 결과 녹화
8. (Phase B/C) Candidate 측정   → 현재 branch 빌드 → 결과 녹화
9. (Phase B/C) 비교 & 판정      → 임계 통과 + 시각/수치 비교
10. CHANGELOG.md 갱신          → 본문 양식 아래 참조
11. Commit + PR + squash merge → 머지 후 main이 다음 phase의 baseline
```

## CHANGELOG 항목 양식

```markdown
## [Unreleased] — Phase <id>: <short title> (refactor)

### Changed
- `<file>` <before>줄 → <after>줄 (<delta>, <one-line summary>)

### Added
- `<new file>` — <purpose>

### Removed
- `<deleted thing>` — <reason>

### Verification
- 빌드 PASS (<time>)
- baseline vs candidate <metric>: <value>

### Notes
- <next phase로 미룬 항목>
- <한계, 운용 시 주의>
```

## Commit 메시지 양식

```
refactor(<scope>): phase <id> — <one-line summary>

<2-4 줄 본문: 무엇을·왜·결과>

- 파일 A: <변화>
- LOC 또는 검증 수치 1줄
```

## 안티패턴

- ❌ 한 PR에 여러 phase 묶기 — 회귀 추적·롤백 비용↑
- ❌ CHANGELOG 나중에 일괄 작성 — 잊거나 부정확
- ❌ 회귀 스크립트 삭제 — 다음 phase 비용 누적
- ❌ baseline 측정 생략하고 candidate만 — 노이즈·회귀 구분 불가
- ❌ main에 직접 push — 브랜치 보호 + linear history 위반

## PR 본문 템플릿

```
## Summary
- <한 줄 요약>

## Changes
- <bullet 3-5개>

## Verification
- [ ] 빌드 PASS
- [ ] (Phase B/C) Regression baseline vs candidate 측정 완료
- [ ] (Phase B/C) 임계 통과 + plot 시각 비교
- [ ] CHANGELOG.md 갱신
- [ ] CLAUDE.md/README 영향 없음 (또는 같이 갱신)

## Next Phase
- <다음 phase의 scope 한 줄>
```

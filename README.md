> ⏸️ **동결 (2026-09-20)** — 이 저장소는 **계획 문서**입니다. 구현은
> [`smilepat/ontology-english-learning-solution`](https://github.com/smilepat/ontology-english-learning-solution)(LogicFlow)에서 합니다.
> 이 계획의 3대 기능 중 진단 시각화와 UDL 경로는 이미 그 앱에 있고, 부족분(교사용 히트맵, 진단 진행선)은 그쪽에 이식했습니다.
> `db/`의 Turso 스키마·`scripts/db.mjs`·테스트는 **참고 자산**으로 남깁니다(Supabase→Turso 전환 시 출발점).
> 마이크로스킬 앱 통합 검토 결과는 LogicFlow 저장소의 `docs/AUDIT-MICRO-SKILLS-APP-2026-09-20.md` 참고.

# LogicFlow Dashboard

수능 영어 온톨로지 기반 적응형 학습 대시보드

## 프로젝트 개요

기존 4개 자원(수능 기출문제 DB, Neo4j 그래프 DB, 어휘 DB, 역량 진단/학습 앱)을 통합하여
학습자 진단 → UDL 기반 맞춤 학습 경로 → 목표 달성 시각화를 제공하는 플랫폼입니다.

### 핵심 기능

1. **학습자 진단 Visualized Dashboard** — 역량 레이더, 어휘 히트맵, 취약점 알림
2. **UDL 기반 다중 학습 로드맵** — Engagement / Representation / Action 3축 선택형 경로
3. **목표-현재 거리 시각화** — 진행 상황 타임라인 및 달성 예측

## 기술 스택

- **Frontend:** React 18 + TypeScript + Recharts + D3.js + TailwindCSS
- **DB:** Turso (libSQL/SQLite) — 온톨로지 코어 + 대시보드 테이블 (`db/migrations/`)
- **Auth:** 미정 (Turso 에는 내장 Auth 가 없다 — Auth.js 등 후보, Phase 1 에서 결정)
- **Graph:** Neo4j Aura (기존 지식 그래프 유지)
- **Relational:** Turso/LibSQL (기존 기출/어휘 DB — 같은 엔진이라 통합이 단순해진다)
- **Legacy:** Firebase (기존 진단 앱)
- **AI:** Claude API
- **Deploy:** Vercel

## 기존 자원 연동

| 자원 | 위치 | 역할 |
|------|------|------|
| 수능 기출문제 DB | Turso/LibSQL | 문제·정답률·난이도 |
| 어휘 DB | Turso/LibSQL | 어휘·CEFR·관계 |
| 지식 그래프 | Neo4j Aura | 스킬·선수지식 관계 |
| 역량 진단/학습 앱 | Firebase | 12 마이크로스킬 진단 |

## 개발 단계

- [ ] Phase 0: 기존 자원 감사 및 스키마 문서화
- [ ] Phase 1: 데이터 통합 레이어 구축
- [ ] Phase 2: 대시보드 UI 개발
- [ ] Phase 3: UDL 경로 엔진
- [ ] Phase 4: 목표-거리 시각화

## 문서

- `docs/DATA_INVENTORY.md` — 기존 자원 스키마 감사 결과
- `docs/PROJECT_PLAN.md` — 전체 개발 계획

---

**Status:** Phase 0 진행 중
**Owner:** Pat (Kyongho Hwang) — Connect Edu Co., Ltd.

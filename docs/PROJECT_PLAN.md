# LogicFlow Dashboard - Claude Code 프로젝트 지침

## 📋 프로젝트 개요

**프로젝트명:** LogicFlow Dashboard
**목표:** 기존 6개 자원을 통합하여 온톨로지 기반 UDL 학습 대시보드 개발

### 핵심 기능 3가지
1. **학습자 진단 Visualized Dashboard** - 역량/어휘/독해 통합 시각화
2. **UDL 기반 다중 학습 로드맵** - 학습자 선호에 따른 경로 선택
3. **목표-현재 거리 시각화** - 진행 상황 및 예측 타임라인

---

## 🗂️ 기존 자원 인벤토리

```
📊 데이터 계층:
├── 수능 기출문제 DB (문제, 정답, 정답률)
├── Neo4j 그래프 DB (스킬 관계, 선수 지식)
└── 어휘 DB (단어, CEFR, 관계)

📱 앱 계층:
├── 수능 역량 진단/학습 앱 (12 마이크로스킬)
├── 어휘 진단 테스트/학습 앱
└── 독해 진단/학습 앱
```

---

## 🛠️ 기술 스택

```
Frontend: React 18 + TypeScript + Recharts + D3.js + TailwindCSS
Backend: Supabase (PostgreSQL + Auth + Realtime)
Graph: Neo4j (기존 유지)
API: Next.js API Routes
AI: Claude API
Deploy: Vercel
```

---

## 🗄️ 통합 데이터 스키마 (Supabase)

```sql
-- 학습자 프로필 + 목표
CREATE TABLE learner_profile (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  target_grade INT,              -- 목표 등급
  target_score INT,              -- 목표 점수
  target_date DATE,              -- 수능일
  preferred_udl_engagement TEXT, -- 'goal', 'interest', 'challenge'
  preferred_udl_representation TEXT, -- 'text', 'visual', 'audio'
  preferred_udl_action TEXT      -- 'choice', 'writing', 'speaking'
);

-- 통합 진단 결과
CREATE TABLE learner_diagnosis (
  id UUID PRIMARY KEY,
  user_id UUID,
  diagnosis_date DATE,
  vocab_total_known INT,
  vocab_cefr_distribution JSONB,
  reading_by_type JSONB,
  microskill_scores JSONB,       -- 12 마이크로스킬
  estimated_score INT,
  estimated_grade INT,
  weak_points TEXT[]
);

-- UDL 학습 경로
CREATE TABLE learning_path (
  id UUID PRIMARY KEY,
  user_id UUID,
  path_type TEXT,                -- 'conservative', 'balanced', 'challenging'
  udl_config JSONB,
  path_nodes JSONB,
  completion_rate FLOAT
);

-- 진행 스냅샷 (시계열)
CREATE TABLE progress_snapshot (
  id UUID PRIMARY KEY,
  user_id UUID,
  snapshot_date DATE,
  current_score INT,
  target_score INT,
  gap INT,
  velocity FLOAT,                -- 일평균 상승률
  predicted_achievement_date DATE
);
```

---

## 📐 UDL (Universal Design for Learning) 모델

```
┌─────────────────────────────────────────────────────────┐
│  ENGAGEMENT (왜 배우는가?)                               │
│  • goal: 목표 달성 중심                                  │
│  • interest: 관심 주제 중심                              │
│  • challenge: 게이미피케이션                             │
├─────────────────────────────────────────────────────────┤
│  REPRESENTATION (무엇을 배우는가?)                       │
│  • text: 전통적 독해                                    │
│  • visual: 컨셉맵, 인포그래픽                           │
│  • audio: 듣기 + 딕테이션                               │
├─────────────────────────────────────────────────────────┤
│  ACTION (어떻게 보여주는가?)                             │
│  • choice: 객관식                                       │
│  • writing: 서술형                                      │
│  • speaking: 말하기                                     │
└─────────────────────────────────────────────────────────┘
```

---

## 📊 대시보드 레이아웃

```
┌─────────────────────────────────────────────────────────┐
│  🎯 목표: 1등급 (D-87)     현재: 67점 → 90점            │
├─────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌────────────┐      │
│  │ 역량 레이더 │  │ 어휘 히트맵 │  │ 취약점     │      │
│  │   차트      │  │             │  │ 알림       │      │
│  └─────────────┘  └─────────────┘  └────────────┘      │
├─────────────────────────────────────────────────────────┤
│  📈 목표까지의 거리 (Progress Timeline)                 │
├─────────────────────────────────────────────────────────┤
│  🛤️ 오늘의 학습 경로 (UDL 추천)                        │
│  [경로 A] [경로 B] [경로 C]                             │
└─────────────────────────────────────────────────────────┘
```

---

## 🚀 개발 단계

### Phase 0: 데이터 감사 (2주)
- 기존 DB 스키마 문서화
- API 엔드포인트 정리
- 통합 계획서 작성

### Phase 1: 데이터 통합 (3주)
- Supabase 통합 스키마 구축
- Neo4j ↔ Supabase 동기화
- 실시간 이벤트 파이프라인

### Phase 2: 대시보드 UI (4주)
- 메인 레이아웃
- 차트 컴포넌트 (Radar, Heatmap, Progress)
- UDL 경로 선택 UI

### Phase 3: UDL 경로 엔진 (3주)
- 온톨로지 기반 경로 생성
- 적응형 난이도 조절
- 효과 분석

### Phase 4: 목표-거리 시각화 (2주)
- 예측 알고리즘
- Progress Timeline
- 알림 시스템

---

## ⚠️ 개발자 참고

1. **사용자:** 비기너 "vibe coder" - 기술 용어 설명 필요
2. **언어:** 한국어 소통, 주석도 한국어 OK
3. **응답 형식:** `[날짜] | [요약] | #키워드`
4. **기존 앱 연동:** 기존 앱의 API를 최대한 재사용

---

## 📁 프로젝트 구조 (예정)

```
logicflow-dashboard/
├── src/
│   ├── components/
│   │   ├── dashboard/
│   │   │   ├── RadarChart.tsx      # 역량 레이더
│   │   │   ├── VocabHeatmap.tsx    # 어휘 히트맵
│   │   │   ├── ProgressTimeline.tsx # 목표-거리
│   │   │   └── WeakPointAlert.tsx  # 취약점 알림
│   │   └── path/
│   │       ├── UDLSelector.tsx     # UDL 선택 UI
│   │       └── PathPreview.tsx     # 경로 미리보기
│   ├── lib/
│   │   ├── supabase.ts
│   │   ├── neo4j.ts
│   │   ├── pathEngine.ts           # 경로 생성 로직
│   │   └── prediction.ts           # 예측 모델
│   └── pages/
│       ├── index.tsx               # 대시보드
│       ├── paths.tsx               # 경로 선택
│       └── api/
│           ├── diagnosis.ts
│           └── paths.ts
├── supabase/
│   └── migrations/
└── docs/
    ├── DATA_INVENTORY.md
    └── API_CATALOG.md
```

---

**현재 상태:** Phase 0 시작 전 - 계획 수립 완료
**다음 작업:** 기존 자원 감사 및 스키마 문서화

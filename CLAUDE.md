# 수능 영어 온톨로지 앱 - Claude Code 프로젝트 지침

## 📋 프로젝트 개요

**목표:** 수능 영어 문제를 지식 그래프(Knowledge Graph) 기반으로 해결하는 적응형 학습 앱 개발

**핵심 차별점:**
- 단어/문법/독해를 "노드"와 "관계"로 연결한 온톨로지 구조
- "왜 틀렸는가?"에 대한 구체적 진단 (취약 스킬 → 선수 지식 추적)
- 학습자별 숙달도 기반 맞춤형 학습 경로 추천

---

## 🛠️ 기술 스택

```
프론트엔드: React + vis.js (그래프 시각화)
백엔드/DB: Supabase (PostgreSQL)
AI 연동: Claude API (문제 생성/해설)
배포: Vercel 또는 Replit
```

---

## 🗄️ 데이터베이스 스키마 (Supabase)

### 테이블 구조 (6개)

```sql
-- 1. vocabulary: 단어 노드
CREATE TABLE vocabulary (
  id UUID PRIMARY KEY,
  headword TEXT UNIQUE,        -- 표제어
  pos TEXT,                    -- 품사
  cefr_level TEXT,            -- A1~C2
  meaning_ko TEXT,            -- 한국어 뜻
  example_sentence TEXT,
  frequency_rank INT
);

-- 2. word_relations: 단어 간 관계 (온톨로지 Edge)
CREATE TABLE word_relations (
  id UUID PRIMARY KEY,
  word_id_from UUID REFERENCES vocabulary(id),
  word_id_to UUID REFERENCES vocabulary(id),
  relation_type TEXT,  -- 'synonym', 'antonym', 'derivative', 'collocation', 'hypernym', 'hyponym'
  strength FLOAT       -- 0~1
);

-- 3. skills: 문제 유형별 스킬
CREATE TABLE skills (
  id UUID PRIMARY KEY,
  skill_code TEXT UNIQUE,      -- 'VOCAB_CONTEXT', 'BLANK_PHRASE' 등
  skill_name_ko TEXT,          -- '문맥 속 어휘', '빈칸 추론' 등
  question_numbers INT[],      -- 해당 수능 문제 번호들
  description TEXT
);

-- 4. questions: 수능 기출 문제
CREATE TABLE questions (
  id UUID PRIMARY KEY,
  question_number INT,         -- 18~45
  exam_year INT,
  exam_month INT,              -- 6, 9, 11
  passage TEXT,
  question_text TEXT,
  options JSONB,
  correct_answer TEXT,
  difficulty_irt FLOAT,
  correct_rate FLOAT
);

-- 5. question_skill_map: 문제-스킬 N:M 매핑
CREATE TABLE question_skill_map (
  question_id UUID REFERENCES questions(id),
  skill_id UUID REFERENCES skills(id),
  is_primary BOOLEAN,
  is_prerequisite BOOLEAN
);

-- 6. learner_mastery: 학습자 숙달도 추적
CREATE TABLE learner_mastery (
  user_id UUID,
  node_type TEXT,              -- 'vocabulary' 또는 'skill'
  node_id UUID,
  mastery_score FLOAT,         -- 0~1
  ease_factor FLOAT,           -- SM-2 알고리즘용
  interval_days INT,
  next_review_at TIMESTAMP
);
```

### 핵심 관계 다이어그램

```
vocabulary ◀──N:M──▶ word_relations (동의어/반의어 네트워크)
    │
    └── learner_mastery (단어별 숙달도)

questions ◀──N:M──▶ skills (문제-스킬 매핑)
    │                  │
    │                  └── learner_mastery (스킬별 숙달도)
    │
    └── question_skill_map (is_prerequisite로 선수관계 표현)
```

---

## 📊 현재 진행 상황

### ✅ 완료
1. 프로젝트 기획 및 온톨로지 모델링 설계
2. Supabase 스키마 SQL 작성 완료
3. 테스트 데이터 준비 (단어 10개, 스킬 16개, 문제 3개)

### 🔄 진행 중
4. Supabase 프로젝트 생성 및 스키마 실행

### ⏳ 다음 단계
5. 데이터 입력 전략 (단어 500개 + 관계 데이터)
6. vis.js 컨셉맵 프로토타입
7. 학습자 숙달도 업데이트 로직
8. "왜 틀렸는가?" 진단 함수 구현

---

## 🎯 핵심 기능 구현 예시

### 1. 지식 그래프 탐색 (단어 동의어 찾기)
```sql
SELECT v2.headword, wr.relation_type, wr.strength
FROM word_relations wr
JOIN vocabulary v1 ON wr.word_id_from = v1.id
JOIN vocabulary v2 ON wr.word_id_to = v2.id
WHERE v1.headword = 'crucial' AND wr.relation_type = 'synonym';
```

### 2. 오답 진단 로직
```javascript
async function diagnoseWrongAnswer(userId, questionId) {
  // 1. 문제에 필요한 스킬 조회
  // 2. 학습자의 해당 스킬 숙달도 확인
  // 3. mastery_score < 0.6인 스킬을 취약점으로 반환
  // 4. 취약 스킬의 선수 지식까지 추적하여 학습 경로 추천
}
```

### 3. SM-2 간격반복 알고리즘
```javascript
function updateMastery(currentMastery, quality) {
  // quality: 0~5 (0=완전 틀림, 5=완벽)
  // ease_factor, interval_days 업데이트
  // next_review_at 계산
}
```

---

## 📁 프로젝트 파일 구조 (예정)

```
csat-english-ontology/
├── src/
│   ├── components/
│   │   ├── ConceptMap.jsx      # vis.js 단어 네트워크 시각화
│   │   ├── QuestionCard.jsx    # 문제 풀이 UI
│   │   └── DiagnosisReport.jsx # 오답 진단 결과
│   ├── lib/
│   │   ├── supabase.js         # Supabase 클라이언트
│   │   ├── sm2.js              # 간격반복 알고리즘
│   │   └── diagnosis.js        # 진단 로직
│   └── pages/
│       ├── index.jsx           # 메인 대시보드
│       ├── learn.jsx           # 학습 모드
│       └── review.jsx          # 복습 모드
├── supabase/
│   └── schema.sql              # DB 스키마
└── package.json
```

---

## ⚠️ 개발자 참고사항

1. **사용자 레벨:** 비기너 "vibe coder" - 모든 기술 용어 설명 필요
2. **선호 도구:** VS Code + Claude Code, Replit
3. **언어:** 한국어로 소통, 코드 주석도 한국어 가능
4. **응답 형식:** 
   - 시작: `[날짜] | [1문장 요약] | #키워드`
   - 코드 블록에 설명 주석 포함
   - 단계별 가이드 선호

---

## 🔗 관련 리소스

- Supabase 프로젝트: `csat-english-ontology` (Tokyo region)
- 스키마 SQL 파일: `csat-ontology-schema.sql`
- vis.js 문서: https://visjs.github.io/vis-network/docs/network/

---

**현재 작업:** Supabase에 스키마 SQL 실행 후, 데이터 입력 전략 진행 예정

-- ============================================================
-- 수능 영어 온톨로지 앱 - Supabase 전체 스키마
-- 실행: Supabase SQL Editor에서 전체 복사 후 Run
-- 생성일: 2026-02-07
-- ============================================================

-- ============================================
-- 테이블 1: vocabulary (단어)
-- 수능 영어 핵심 어휘를 저장합니다
-- ============================================

CREATE TABLE IF NOT EXISTS vocabulary (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  headword TEXT NOT NULL UNIQUE,
  pos TEXT CHECK (pos IN ('noun', 'verb', 'adjective', 'adverb', 'preposition', 'conjunction', 'other')),
  cefr_level TEXT CHECK (cefr_level IN ('A1', 'A2', 'B1', 'B2', 'C1', 'C2')),
  meaning_ko TEXT NOT NULL,
  example_sentence TEXT,
  frequency_rank INT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_vocabulary_headword ON vocabulary(headword);
CREATE INDEX IF NOT EXISTS idx_vocabulary_cefr ON vocabulary(cefr_level);

-- ============================================
-- 테이블 2: word_relations (단어 간 관계)
-- 동의어, 반의어, 파생어 등 - 온톨로지의 핵심!
-- ============================================

CREATE TABLE IF NOT EXISTS word_relations (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  word_id_from UUID NOT NULL REFERENCES vocabulary(id) ON DELETE CASCADE,
  word_id_to UUID NOT NULL REFERENCES vocabulary(id) ON DELETE CASCADE,
  relation_type TEXT NOT NULL CHECK (relation_type IN (
    'synonym',
    'antonym',
    'derivative',
    'collocation',
    'hypernym',
    'hyponym'
  )),
  strength FLOAT DEFAULT 1.0 CHECK (strength >= 0 AND strength <= 1),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(word_id_from, word_id_to, relation_type)
);

CREATE INDEX IF NOT EXISTS idx_relations_from ON word_relations(word_id_from);
CREATE INDEX IF NOT EXISTS idx_relations_to ON word_relations(word_id_to);
CREATE INDEX IF NOT EXISTS idx_relations_type ON word_relations(relation_type);

-- ============================================
-- 테이블 3: skills (평가 스킬)
-- 수능 영어 문제 유형별 요구 능력
-- ============================================

CREATE TABLE IF NOT EXISTS skills (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  skill_code TEXT NOT NULL UNIQUE,
  skill_name_ko TEXT NOT NULL,
  skill_name_en TEXT,
  question_numbers INT[],
  description TEXT,
  difficulty_weight FLOAT DEFAULT 1.0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 테이블 4: questions (수능 기출 문제)
-- ============================================

CREATE TABLE IF NOT EXISTS questions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  question_number INT NOT NULL CHECK (question_number >= 1 AND question_number <= 45),
  exam_year INT NOT NULL,
  exam_month INT CHECK (exam_month IN (6, 9, 11)),
  passage TEXT,
  question_text TEXT NOT NULL,
  options JSONB,
  correct_answer TEXT NOT NULL,
  difficulty_irt FLOAT,
  discrimination_irt FLOAT,
  correct_rate FLOAT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(exam_year, exam_month, question_number)
);

CREATE INDEX IF NOT EXISTS idx_questions_year ON questions(exam_year);
CREATE INDEX IF NOT EXISTS idx_questions_number ON questions(question_number);

-- ============================================
-- 테이블 5: question_skill_map (문제-스킬 매핑)
-- 문제와 스킬의 다대다(N:M) 관계
-- ============================================

CREATE TABLE IF NOT EXISTS question_skill_map (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  question_id UUID NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
  skill_id UUID NOT NULL REFERENCES skills(id) ON DELETE CASCADE,
  is_primary BOOLEAN DEFAULT false,
  is_prerequisite BOOLEAN DEFAULT false,
  weight FLOAT DEFAULT 1.0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(question_id, skill_id)
);

CREATE INDEX IF NOT EXISTS idx_qsm_question ON question_skill_map(question_id);
CREATE INDEX IF NOT EXISTS idx_qsm_skill ON question_skill_map(skill_id);

-- ============================================
-- 테이블 6: learner_mastery (학습자 지식 상태)
-- 각 학습자의 노드별 숙달도를 추적
-- ============================================

CREATE TABLE IF NOT EXISTS learner_mastery (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL,
  node_type TEXT NOT NULL CHECK (node_type IN ('vocabulary', 'skill')),
  node_id UUID NOT NULL,
  mastery_score FLOAT DEFAULT 0.5 CHECK (mastery_score >= 0 AND mastery_score <= 1),
  ease_factor FLOAT DEFAULT 2.5,
  interval_days INT DEFAULT 1,
  repetitions INT DEFAULT 0,
  last_reviewed_at TIMESTAMP WITH TIME ZONE,
  next_review_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, node_type, node_id)
);

CREATE INDEX IF NOT EXISTS idx_mastery_user ON learner_mastery(user_id);
CREATE INDEX IF NOT EXISTS idx_mastery_node ON learner_mastery(node_type, node_id);
CREATE INDEX IF NOT EXISTS idx_mastery_review ON learner_mastery(next_review_at);

-- updated_at 자동 갱신 트리거
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_mastery_updated ON learner_mastery;
CREATE TRIGGER trigger_mastery_updated
  BEFORE UPDATE ON learner_mastery
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();


-- ============================================================
-- 테스트 데이터 삽입
-- ============================================================

-- 단어 테스트 데이터 (10개)
INSERT INTO vocabulary (headword, pos, cefr_level, meaning_ko, example_sentence, frequency_rank) VALUES
  ('crucial', 'adjective', 'B2', '결정적인, 중대한', 'It is crucial to understand the context.', 1),
  ('significant', 'adjective', 'B2', '중요한, 의미 있는', 'There was a significant increase in sales.', 2),
  ('essential', 'adjective', 'B1', '필수적인, 본질적인', 'Water is essential for life.', 3),
  ('vital', 'adjective', 'B2', '필수적인, 생명의', 'Exercise is vital for good health.', 4),
  ('trivial', 'adjective', 'C1', '사소한, 하찮은', 'Do not waste time on trivial matters.', 5),
  ('enhance', 'verb', 'B2', '향상시키다', 'Technology can enhance learning.', 6),
  ('diminish', 'verb', 'C1', '줄이다, 감소시키다', 'His influence began to diminish.', 7),
  ('comprehend', 'verb', 'B2', '이해하다', 'It is hard to comprehend the scale.', 8),
  ('elaborate', 'adjective', 'B2', '정교한, 복잡한', 'She gave an elaborate explanation.', 9),
  ('profound', 'adjective', 'C1', '심오한, 깊은', 'The book had a profound impact on me.', 10)
ON CONFLICT (headword) DO NOTHING;

-- 단어 관계 데이터 (동의어/반의어 네트워크)
INSERT INTO word_relations (word_id_from, word_id_to, relation_type, strength)
SELECT v1.id, v2.id, 'synonym', 0.9
FROM vocabulary v1, vocabulary v2
WHERE v1.headword = 'crucial' AND v2.headword = 'significant'
ON CONFLICT DO NOTHING;

INSERT INTO word_relations (word_id_from, word_id_to, relation_type, strength)
SELECT v1.id, v2.id, 'synonym', 0.85
FROM vocabulary v1, vocabulary v2
WHERE v1.headword = 'crucial' AND v2.headword = 'essential'
ON CONFLICT DO NOTHING;

INSERT INTO word_relations (word_id_from, word_id_to, relation_type, strength)
SELECT v1.id, v2.id, 'synonym', 0.88
FROM vocabulary v1, vocabulary v2
WHERE v1.headword = 'crucial' AND v2.headword = 'vital'
ON CONFLICT DO NOTHING;

INSERT INTO word_relations (word_id_from, word_id_to, relation_type, strength)
SELECT v1.id, v2.id, 'antonym', 0.8
FROM vocabulary v1, vocabulary v2
WHERE v1.headword = 'crucial' AND v2.headword = 'trivial'
ON CONFLICT DO NOTHING;

INSERT INTO word_relations (word_id_from, word_id_to, relation_type, strength)
SELECT v1.id, v2.id, 'antonym', 0.85
FROM vocabulary v1, vocabulary v2
WHERE v1.headword = 'enhance' AND v2.headword = 'diminish'
ON CONFLICT DO NOTHING;

INSERT INTO word_relations (word_id_from, word_id_to, relation_type, strength)
SELECT v1.id, v2.id, 'synonym', 0.75
FROM vocabulary v1, vocabulary v2
WHERE v1.headword = 'comprehend' AND v2.headword = 'essential'
ON CONFLICT DO NOTHING;

-- 스킬 데이터 (수능 영어 전체 유형)
INSERT INTO skills (skill_code, skill_name_ko, skill_name_en, question_numbers, description) VALUES
  ('LISTENING_PURPOSE', '목적 파악', 'Purpose Identification', '{1,2}', '대화나 담화의 목적을 파악하는 능력'),
  ('VOCAB_CONTEXT', '문맥 속 어휘', 'Vocabulary in Context', '{18,19}', '문맥을 통해 어휘의 의미를 추론하는 능력'),
  ('GRAMMAR_JUDGE', '어법 판단', 'Grammar Judgment', '{20,21}', '문장의 어법적 정확성을 판단하는 능력'),
  ('MAIN_IDEA', '주제/요지 파악', 'Main Idea', '{22,23,24}', '글의 중심 생각을 파악하는 능력'),
  ('TITLE_FIND', '제목 추론', 'Title Inference', '{24}', '글의 제목을 추론하는 능력'),
  ('IMPLICATION', '함축 의미 추론', 'Implication', '{25}', '밑줄 친 부분의 함축 의미를 추론'),
  ('EMOTIONAL_CHANGE', '심경 변화', 'Emotional Change', '{26}', '등장인물의 심경 변화를 파악'),
  ('REFERENCE', '지칭 추론', 'Reference', '{27}', '대명사나 지시어의 지칭 대상 파악'),
  ('DETAIL_MATCH', '내용 일치/불일치', 'Detail Matching', '{28,29,30}', '세부 정보의 일치 여부 판단'),
  ('BLANK_WORD', '빈칸 추론 (어휘)', 'Blank - Vocabulary', '{31}', '빈칸에 들어갈 어휘를 추론'),
  ('BLANK_PHRASE', '빈칸 추론 (구/절)', 'Blank - Phrase', '{32,33,34}', '빈칸에 들어갈 구나 절을 추론'),
  ('IRRELEVANT', '무관한 문장', 'Irrelevant Sentence', '{35}', '글의 흐름과 무관한 문장 찾기'),
  ('ORDERING', '글의 순서', 'Sentence Ordering', '{36,37}', '주어진 글 다음에 이어질 순서 배열'),
  ('INSERTION', '문장 삽입', 'Sentence Insertion', '{38,39}', '주어진 문장이 들어갈 위치 찾기'),
  ('SUMMARY', '요약문 완성', 'Summary Completion', '{40}', '글을 요약한 문장 완성'),
  ('LONG_PASSAGE', '장문 독해', 'Long Passage', '{41,42,43,44,45}', '장문을 읽고 세부 정보 파악')
ON CONFLICT (skill_code) DO NOTHING;

-- 문제 테스트 데이터 (2024 수능)
INSERT INTO questions (question_number, exam_year, exam_month, passage, question_text, options, correct_answer, correct_rate) VALUES
  (18, 2024, 11, 
   'The ability to adapt is crucial in today''s rapidly changing world. Those who can quickly adjust to new circumstances often find themselves at an advantage.',
   '밑줄 친 crucial과 의미가 가장 가까운 것은?',
   '{"1": "minor", "2": "vital", "3": "ordinary", "4": "temporary", "5": "artificial"}',
   '2', 0.72),
  (19, 2024, 11,
   'The professor''s elaborate explanation helped students comprehend the complex theory. Without such detailed guidance, many would have struggled.',
   '밑줄 친 elaborate과 의미가 가장 가까운 것은?',
   '{"1": "brief", "2": "simple", "3": "detailed", "4": "vague", "5": "ordinary"}',
   '3', 0.68),
  (31, 2024, 11,
   'Regular exercise can significantly _______ your mental health. Studies show that physical activity releases endorphins, which naturally improve mood.',
   '빈칸에 들어갈 말로 가장 적절한 것은?',
   '{"1": "diminish", "2": "ignore", "3": "enhance", "4": "restrict", "5": "complicate"}',
   '3', 0.65)
ON CONFLICT (exam_year, exam_month, question_number) DO NOTHING;

-- 문제-스킬 매핑
INSERT INTO question_skill_map (question_id, skill_id, is_primary, is_prerequisite)
SELECT q.id, s.id, true, false
FROM questions q, skills s
WHERE q.exam_year = 2024 AND q.question_number = 18 AND s.skill_code = 'VOCAB_CONTEXT'
ON CONFLICT DO NOTHING;

INSERT INTO question_skill_map (question_id, skill_id, is_primary, is_prerequisite)
SELECT q.id, s.id, true, false
FROM questions q, skills s
WHERE q.exam_year = 2024 AND q.question_number = 19 AND s.skill_code = 'VOCAB_CONTEXT'
ON CONFLICT DO NOTHING;

INSERT INTO question_skill_map (question_id, skill_id, is_primary, is_prerequisite)
SELECT q.id, s.id, true, false
FROM questions q, skills s
WHERE q.exam_year = 2024 AND q.question_number = 31 AND s.skill_code = 'BLANK_WORD'
ON CONFLICT DO NOTHING;


-- ============================================================
-- 완료 메시지
-- ============================================================
SELECT '✅ 스키마 생성 완료! 아래 테이블이 생성되었습니다:' AS message;
SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename;

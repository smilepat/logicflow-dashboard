-- ============================================================
-- 001: 수능 영어 온톨로지 코어 (Turso / libSQL = SQLite 문법)
-- Postgres 원본(_legacy_supabase_schema.sql.txt)과의 차이:
--   UUID          -> TEXT (lower(hex(randomblob(16))) 로 자동 생성)
--   JSONB / INT[] -> TEXT (JSON 문자열, json_valid 로 검증)
--   TIMESTAMPTZ   -> TEXT (ISO-8601 UTC)
--   BOOLEAN       -> INTEGER (0/1)
--   FLOAT         -> REAL
-- ============================================================

CREATE TABLE IF NOT EXISTS vocabulary (
  id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
  headword TEXT NOT NULL UNIQUE,
  pos TEXT CHECK (pos IN ('noun','verb','adjective','adverb','preposition','conjunction','other')),
  cefr_level TEXT CHECK (cefr_level IN ('A1','A2','B1','B2','C1','C2')),
  meaning_ko TEXT NOT NULL,
  example_sentence TEXT,
  frequency_rank INTEGER,
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
);
CREATE INDEX IF NOT EXISTS idx_vocabulary_cefr ON vocabulary(cefr_level);

CREATE TABLE IF NOT EXISTS word_relations (
  id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
  word_id_from TEXT NOT NULL REFERENCES vocabulary(id) ON DELETE CASCADE,
  word_id_to TEXT NOT NULL REFERENCES vocabulary(id) ON DELETE CASCADE,
  relation_type TEXT NOT NULL CHECK (relation_type IN
    ('synonym','antonym','derivative','collocation','hypernym','hyponym')),
  strength REAL NOT NULL DEFAULT 1.0 CHECK (strength >= 0 AND strength <= 1),
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  UNIQUE (word_id_from, word_id_to, relation_type)
);
CREATE INDEX IF NOT EXISTS idx_relations_from ON word_relations(word_id_from);
CREATE INDEX IF NOT EXISTS idx_relations_to ON word_relations(word_id_to);
CREATE INDEX IF NOT EXISTS idx_relations_type ON word_relations(relation_type);

CREATE TABLE IF NOT EXISTS skills (
  id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
  skill_code TEXT NOT NULL UNIQUE,
  skill_name_ko TEXT NOT NULL,
  skill_name_en TEXT,
  question_numbers TEXT CHECK (question_numbers IS NULL OR json_valid(question_numbers)), -- JSON 배열 예: [18,19]
  description TEXT,
  difficulty_weight REAL NOT NULL DEFAULT 1.0,
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
);

CREATE TABLE IF NOT EXISTS questions (
  id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
  question_number INTEGER NOT NULL CHECK (question_number BETWEEN 1 AND 45),
  exam_year INTEGER NOT NULL,
  exam_month INTEGER CHECK (exam_month IN (6, 9, 11)),
  passage TEXT,
  question_text TEXT NOT NULL,
  options TEXT CHECK (options IS NULL OR json_valid(options)),
  correct_answer TEXT NOT NULL,
  difficulty_irt REAL,
  discrimination_irt REAL,
  correct_rate REAL,
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  UNIQUE (exam_year, exam_month, question_number)
);
CREATE INDEX IF NOT EXISTS idx_questions_year ON questions(exam_year);
CREATE INDEX IF NOT EXISTS idx_questions_number ON questions(question_number);

CREATE TABLE IF NOT EXISTS question_skill_map (
  id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
  question_id TEXT NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
  skill_id TEXT NOT NULL REFERENCES skills(id) ON DELETE CASCADE,
  is_primary INTEGER NOT NULL DEFAULT 0 CHECK (is_primary IN (0,1)),
  is_prerequisite INTEGER NOT NULL DEFAULT 0 CHECK (is_prerequisite IN (0,1)),
  weight REAL NOT NULL DEFAULT 1.0,
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  UNIQUE (question_id, skill_id)
);
CREATE INDEX IF NOT EXISTS idx_qsm_question ON question_skill_map(question_id);
CREATE INDEX IF NOT EXISTS idx_qsm_skill ON question_skill_map(skill_id);

-- user_id: 인증 방식이 정해지면(Auth.js/Clerk 등) 그 사용자 ID를 그대로 저장한다. DB 쪽 FK는 두지 않는다.
CREATE TABLE IF NOT EXISTS learner_mastery (
  id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
  user_id TEXT NOT NULL,
  node_type TEXT NOT NULL CHECK (node_type IN ('vocabulary','skill')),
  node_id TEXT NOT NULL,
  mastery_score REAL NOT NULL DEFAULT 0.5 CHECK (mastery_score >= 0 AND mastery_score <= 1),
  ease_factor REAL NOT NULL DEFAULT 2.5,
  interval_days INTEGER NOT NULL DEFAULT 1,
  repetitions INTEGER NOT NULL DEFAULT 0,
  last_reviewed_at TEXT,
  next_review_at TEXT,
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  UNIQUE (user_id, node_type, node_id)
);
CREATE INDEX IF NOT EXISTS idx_mastery_user ON learner_mastery(user_id);
CREATE INDEX IF NOT EXISTS idx_mastery_node ON learner_mastery(node_type, node_id);
CREATE INDEX IF NOT EXISTS idx_mastery_review ON learner_mastery(next_review_at);

-- updated_at 자동 갱신 (Postgres plpgsql 트리거의 SQLite 대응).
-- WHEN 조건이 있어 트리거 안의 UPDATE 가 자기 자신을 다시 부르지 않는다.
CREATE TRIGGER IF NOT EXISTS trigger_mastery_updated
AFTER UPDATE ON learner_mastery
FOR EACH ROW
WHEN NEW.updated_at = OLD.updated_at
BEGIN
  UPDATE learner_mastery SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ','now') WHERE id = NEW.id;
END;

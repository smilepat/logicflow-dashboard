-- ============================================================
-- 002: 대시보드 통합 테이블 (CLAUDE.md 의 learner_profile 외 3종)
-- auth.users 참조는 제거했다 — Turso 에는 내장 Auth 가 없다.
-- user_id 는 앱이 정한 사용자 ID(TEXT).
-- ============================================================

CREATE TABLE IF NOT EXISTS learner_profile (
  id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
  user_id TEXT NOT NULL UNIQUE,
  target_grade INTEGER CHECK (target_grade BETWEEN 1 AND 9),
  target_score INTEGER,
  target_date TEXT,  -- YYYY-MM-DD (수능일)
  preferred_udl_engagement TEXT CHECK (preferred_udl_engagement IN ('goal','interest','challenge')),
  preferred_udl_representation TEXT CHECK (preferred_udl_representation IN ('text','visual','audio')),
  preferred_udl_action TEXT CHECK (preferred_udl_action IN ('choice','writing','speaking')),
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
);

CREATE TABLE IF NOT EXISTS learner_diagnosis (
  id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
  user_id TEXT NOT NULL,
  diagnosis_date TEXT NOT NULL,
  vocab_total_known INTEGER,
  vocab_cefr_distribution TEXT CHECK (vocab_cefr_distribution IS NULL OR json_valid(vocab_cefr_distribution)),
  reading_by_type TEXT CHECK (reading_by_type IS NULL OR json_valid(reading_by_type)),
  microskill_scores TEXT CHECK (microskill_scores IS NULL OR json_valid(microskill_scores)), -- 12 마이크로스킬
  estimated_score INTEGER,
  estimated_grade INTEGER,
  weak_points TEXT CHECK (weak_points IS NULL OR json_valid(weak_points)) -- JSON 배열
);
CREATE INDEX IF NOT EXISTS idx_diagnosis_user_date ON learner_diagnosis(user_id, diagnosis_date);

CREATE TABLE IF NOT EXISTS learning_path (
  id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
  user_id TEXT NOT NULL,
  path_type TEXT NOT NULL CHECK (path_type IN ('conservative','balanced','challenging')),
  udl_config TEXT CHECK (udl_config IS NULL OR json_valid(udl_config)),
  path_nodes TEXT CHECK (path_nodes IS NULL OR json_valid(path_nodes)),
  completion_rate REAL NOT NULL DEFAULT 0 CHECK (completion_rate BETWEEN 0 AND 1),
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
);
CREATE INDEX IF NOT EXISTS idx_path_user ON learning_path(user_id);

CREATE TABLE IF NOT EXISTS progress_snapshot (
  id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
  user_id TEXT NOT NULL,
  snapshot_date TEXT NOT NULL,
  current_score INTEGER,
  target_score INTEGER,
  gap INTEGER,
  velocity REAL,  -- 일평균 상승률
  predicted_achievement_date TEXT,
  UNIQUE (user_id, snapshot_date)  -- 같은 날 중복 스냅샷 방지
);

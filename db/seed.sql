-- 테스트 데이터 (원본 schema.sql 의 시드를 SQLite 문법으로 옮김). 여러 번 실행해도 안전(INSERT OR IGNORE).

INSERT OR IGNORE INTO vocabulary (headword, pos, cefr_level, meaning_ko, example_sentence, frequency_rank) VALUES
  ('crucial', 'adjective', 'B2', '결정적인, 중대한', 'It is crucial to understand the context.', 1),
  ('significant', 'adjective', 'B2', '중요한, 의미 있는', 'There was a significant increase in sales.', 2),
  ('essential', 'adjective', 'B1', '필수적인, 본질적인', 'Water is essential for life.', 3),
  ('vital', 'adjective', 'B2', '필수적인, 생명의', 'Exercise is vital for good health.', 4),
  ('trivial', 'adjective', 'C1', '사소한, 하찮은', 'Do not waste time on trivial matters.', 5),
  ('enhance', 'verb', 'B2', '향상시키다', 'Technology can enhance learning.', 6),
  ('diminish', 'verb', 'C1', '줄이다, 감소시키다', 'His influence began to diminish.', 7),
  ('comprehend', 'verb', 'B2', '이해하다', 'It is hard to comprehend the scale.', 8),
  ('elaborate', 'adjective', 'B2', '정교한, 복잡한', 'She gave an elaborate explanation.', 9),
  ('profound', 'adjective', 'C1', '심오한, 깊은', 'The book had a profound impact on me.', 10);

-- 단어 관계: (from, to, type, strength) 를 표제어로 적고 id 로 풀어 넣는다.
INSERT OR IGNORE INTO word_relations (word_id_from, word_id_to, relation_type, strength)
SELECT v1.id, v2.id, r.t, r.s
FROM (
  SELECT 'crucial' AS f, 'significant' AS x, 'synonym' AS t, 0.9  AS s UNION ALL
  SELECT 'crucial', 'essential',   'synonym', 0.85 UNION ALL
  SELECT 'crucial', 'vital',       'synonym', 0.88 UNION ALL
  SELECT 'crucial', 'trivial',     'antonym', 0.8  UNION ALL
  SELECT 'enhance', 'diminish',    'antonym', 0.85 UNION ALL
  SELECT 'comprehend', 'essential','synonym', 0.75
) r
JOIN vocabulary v1 ON v1.headword = r.f
JOIN vocabulary v2 ON v2.headword = r.x;

INSERT OR IGNORE INTO skills (skill_code, skill_name_ko, skill_name_en, question_numbers, description) VALUES
  ('LISTENING_PURPOSE', '목적 파악', 'Purpose Identification', '[1,2]', '대화나 담화의 목적을 파악하는 능력'),
  ('VOCAB_CONTEXT', '문맥 속 어휘', 'Vocabulary in Context', '[18,19]', '문맥을 통해 어휘의 의미를 추론하는 능력'),
  ('GRAMMAR_JUDGE', '어법 판단', 'Grammar Judgment', '[20,21]', '문장의 어법적 정확성을 판단하는 능력'),
  ('MAIN_IDEA', '주제/요지 파악', 'Main Idea', '[22,23,24]', '글의 중심 생각을 파악하는 능력'),
  ('TITLE_FIND', '제목 추론', 'Title Inference', '[24]', '글의 제목을 추론하는 능력'),
  ('IMPLICATION', '함축 의미 추론', 'Implication', '[25]', '밑줄 친 부분의 함축 의미를 추론'),
  ('EMOTIONAL_CHANGE', '심경 변화', 'Emotional Change', '[26]', '등장인물의 심경 변화를 파악'),
  ('REFERENCE', '지칭 추론', 'Reference', '[27]', '대명사나 지시어의 지칭 대상 파악'),
  ('DETAIL_MATCH', '내용 일치/불일치', 'Detail Matching', '[28,29,30]', '세부 정보의 일치 여부 판단'),
  ('BLANK_WORD', '빈칸 추론 (어휘)', 'Blank - Vocabulary', '[31]', '빈칸에 들어갈 어휘를 추론'),
  ('BLANK_PHRASE', '빈칸 추론 (구/절)', 'Blank - Phrase', '[32,33,34]', '빈칸에 들어갈 구나 절을 추론'),
  ('IRRELEVANT', '무관한 문장', 'Irrelevant Sentence', '[35]', '글의 흐름과 무관한 문장 찾기'),
  ('ORDERING', '글의 순서', 'Sentence Ordering', '[36,37]', '주어진 글 다음에 이어질 순서 배열'),
  ('INSERTION', '문장 삽입', 'Sentence Insertion', '[38,39]', '주어진 문장이 들어갈 위치 찾기'),
  ('SUMMARY', '요약문 완성', 'Summary Completion', '[40]', '글을 요약한 문장 완성'),
  ('LONG_PASSAGE', '장문 독해', 'Long Passage', '[41,42,43,44,45]', '장문을 읽고 세부 정보 파악');

INSERT OR IGNORE INTO questions (question_number, exam_year, exam_month, passage, question_text, options, correct_answer, correct_rate) VALUES
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
   '3', 0.65);

INSERT OR IGNORE INTO question_skill_map (question_id, skill_id, is_primary, is_prerequisite)
SELECT q.id, s.id, 1, 0
FROM (
  SELECT 18 AS n, 'VOCAB_CONTEXT' AS c UNION ALL
  SELECT 19, 'VOCAB_CONTEXT' UNION ALL
  SELECT 31, 'BLANK_WORD'
) m
JOIN questions q ON q.exam_year = 2024 AND q.exam_month = 11 AND q.question_number = m.n
JOIN skills s ON s.skill_code = m.c;

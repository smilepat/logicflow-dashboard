import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createClient } from '@libsql/client';
import { migrate, seed, check } from '../scripts/db.mjs';
import { findRelations, skillsForQuestionNumber } from '../src/lib/db.ts';

// 매 테스트마다 새 인메모리 DB — 로컬 파일이나 원격 Turso 를 건드리지 않는다.
async function freshDb() {
  const db = createClient({ url: ':memory:' });
  await migrate(db);
  await seed(db);
  return db;
}

test('migrate 는 멱등이다 (두 번째는 아무것도 적용하지 않는다)', async () => {
  const db = createClient({ url: ':memory:' });
  assert.equal((await migrate(db)).length, 2);
  assert.equal((await migrate(db)).length, 0);
});

test('seed 는 멱등이고 원본 시드와 같은 개수를 넣는다', async () => {
  const db = await freshDb();
  await seed(db); // 두 번째
  const c = await check(db);
  assert.equal(c.vocabulary, 10);
  assert.equal(c.word_relations, 6);
  assert.equal(c.skills, 16);
  assert.equal(c.questions, 3);
  assert.equal(c.question_skill_map, 3);
});

test('crucial 의 동의어 3개를 강도순으로 찾는다', async () => {
  const db = await freshDb();
  const r = await findRelations(db, 'crucial', 'synonym');
  assert.deepEqual(r.map((x) => x.headword), ['significant', 'vital', 'essential']);
});

test('json_each 로 문제 번호 -> 스킬을 찾는다 (24번은 두 스킬에 걸친다)', async () => {
  const db = await freshDb();
  assert.deepEqual(await skillsForQuestionNumber(db, 24), ['MAIN_IDEA', 'TITLE_FIND']);
  assert.deepEqual(await skillsForQuestionNumber(db, 18), ['VOCAB_CONTEXT']);
});

test('옵션 JSON 과 인용부호가 손상 없이 저장된다', async () => {
  const db = await freshDb();
  const rs = await db.execute("SELECT passage, json_extract(options,'$.2') AS o FROM questions WHERE question_number=18");
  assert.match(String(rs.rows[0].passage), /today's rapidly/);
  assert.equal(rs.rows[0].o, 'vital');
});

test('CHECK 제약이 살아 있다 (잘못된 CEFR / 깨진 JSON / 범위 밖 strength)', async () => {
  const db = await freshDb();
  await assert.rejects(db.execute("INSERT INTO vocabulary (headword, cefr_level, meaning_ko) VALUES ('x','Z9','y')"));
  await assert.rejects(db.execute("INSERT INTO skills (skill_code, skill_name_ko, question_numbers) VALUES ('X','y','not json')"));
  await assert.rejects(
    db.execute(
      "INSERT INTO word_relations (word_id_from, word_id_to, relation_type, strength) SELECT a.id, b.id, 'synonym', 1.5 FROM vocabulary a, vocabulary b LIMIT 1",
    ),
  );
});

test('외래키가 동작한다 (없는 단어를 가리키는 관계는 거부)', async () => {
  const db = await freshDb();
  await assert.rejects(
    db.execute("INSERT INTO word_relations (word_id_from, word_id_to, relation_type) VALUES ('nope','nope','synonym')"),
  );
});

test('updated_at 트리거가 갱신하고 무한반복하지 않는다', async () => {
  const db = await freshDb();
  await db.execute("INSERT INTO learner_mastery (user_id,node_type,node_id,updated_at) VALUES ('u','skill','s','2000-01-01T00:00:00.000Z')");
  await db.execute("UPDATE learner_mastery SET mastery_score = 0.9 WHERE user_id='u'");
  const rs = await db.execute("SELECT updated_at FROM learner_mastery WHERE user_id='u'");
  assert.notEqual(rs.rows[0].updated_at, '2000-01-01T00:00:00.000Z');
});

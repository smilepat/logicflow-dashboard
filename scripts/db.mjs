// Turso(libSQL) 마이그레이션 / 시드 / 점검 도구.
//   node scripts/db.mjs migrate   db/migrations/*.sql 을 번호순으로 적용 (적용한 것은 _migrations 에 기록)
//   node scripts/db.mjs seed      db/seed.sql 적용 (여러 번 해도 안전)
//   node scripts/db.mjs check     연결 + 테이블 목록 + 행 수
// 대상 DB: TURSO_DATABASE_URL (+ 원격이면 TURSO_AUTH_TOKEN). 없으면 로컬 파일 file:./local.db
import { createClient } from '@libsql/client';
import { readdir, readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');

export function connect() {
  return createClient({
    url: process.env.TURSO_DATABASE_URL ?? 'file:./local.db',
    authToken: process.env.TURSO_AUTH_TOKEN,
  });
}

export async function migrate(db) {
  await db.execute(
    'CREATE TABLE IF NOT EXISTS _migrations (name TEXT PRIMARY KEY, applied_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP)',
  );
  const done = new Set((await db.execute('SELECT name FROM _migrations')).rows.map((r) => r.name));
  const dir = path.join(root, 'db', 'migrations');
  const files = (await readdir(dir)).filter((f) => f.endsWith('.sql')).sort();
  const applied = [];
  for (const f of files) {
    if (done.has(f)) continue;
    // executeMultiple 은 트리거 본문의 세미콜론까지 올바르게 처리한다. 한 파일 = 한 트랜잭션은 아님에 유의.
    await db.executeMultiple(await readFile(path.join(dir, f), 'utf8'));
    await db.execute({ sql: 'INSERT INTO _migrations (name) VALUES (?)', args: [f] });
    applied.push(f);
  }
  return applied;
}

export async function seed(db) {
  await db.executeMultiple(await readFile(path.join(root, 'db', 'seed.sql'), 'utf8'));
}

export async function check(db) {
  const tables = (
    await db.execute("SELECT name FROM sqlite_schema WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name")
  ).rows.map((r) => r.name);
  /** @type {Record<string, number>} */
  const out = {};
  for (const t of tables) out[t] = Number((await db.execute(`SELECT COUNT(*) AS n FROM "${t}"`)).rows[0].n);
  return out;
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const cmd = process.argv[2];
  const db = connect();
  if (cmd === 'migrate') console.log('applied:', (await migrate(db)).join(', ') || '(없음 — 이미 최신)');
  else if (cmd === 'seed') (await seed(db), console.log('seed 완료'));
  else if (cmd === 'check') console.table(await check(db));
  else (console.error('사용법: node scripts/db.mjs migrate|seed|check'), (process.exitCode = 1));
  db.close();
}

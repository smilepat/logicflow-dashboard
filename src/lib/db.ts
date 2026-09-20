import { createClient, type Client } from '@libsql/client';

// 서버 코드(API 라우트)에서만 사용한다. TURSO_AUTH_TOKEN 은 브라우저 번들에 넣지 말 것.
export function createDb(url = process.env.TURSO_DATABASE_URL ?? 'file:./local.db'): Client {
  return createClient({ url, authToken: process.env.TURSO_AUTH_TOKEN });
}

export interface WordRelation {
  headword: string;
  relation_type: string;
  strength: number;
}

/** 지식 그래프 탐색: 표제어의 관련 단어 (CLAUDE.md 의 synonym 조회 예시를 일반화) */
export async function findRelations(db: Client, headword: string, relationType?: string): Promise<WordRelation[]> {
  const rs = await db.execute({
    sql: `SELECT v2.headword, wr.relation_type, wr.strength
            FROM word_relations wr
            JOIN vocabulary v1 ON wr.word_id_from = v1.id
            JOIN vocabulary v2 ON wr.word_id_to = v2.id
           WHERE v1.headword = ? AND (? IS NULL OR wr.relation_type = ?)
           ORDER BY wr.strength DESC`,
    args: [headword, relationType ?? null, relationType ?? null],
  });
  return rs.rows.map((r) => ({
    headword: String(r.headword),
    relation_type: String(r.relation_type),
    strength: Number(r.strength),
  }));
}

/** 문제 번호에 해당하는 스킬 코드들. question_numbers 는 JSON 배열이라 json_each 로 푼다 (Postgres 의 = ANY(배열) 대응). */
export async function skillsForQuestionNumber(db: Client, questionNumber: number): Promise<string[]> {
  const rs = await db.execute({
    sql: `SELECT DISTINCT s.skill_code
            FROM skills s, json_each(s.question_numbers) j
           WHERE j.value = ?
           ORDER BY s.skill_code`,
    args: [questionNumber],
  });
  return rs.rows.map((r) => String(r.skill_code));
}

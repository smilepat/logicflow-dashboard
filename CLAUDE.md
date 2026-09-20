# LogicFlow Dashboard - Claude Code 프로젝트 지침

정본 계획은 `docs/PROJECT_PLAN.md` (기능·UDL 모델·레이아웃·Phase). 이 파일은 작업 규칙만 담는다.

## 기술 스택
Frontend React 18 + TS + Recharts + D3 + Tailwind / **DB Turso (libSQL = SQLite 문법)** / Graph Neo4j(기존) / AI Claude API / Deploy Vercel.
Auth 는 미정 — Turso 에는 내장 Auth·RLS·Realtime 이 없다. `user_id` 는 TEXT 로 두고 권한 검사는 서버 코드(API 라우트)에서 한다.

## DB 규칙
- 스키마 정본 = `db/migrations/NNN_*.sql`. 바꿀 때는 새 번호 파일을 추가한다(적용된 파일 수정 금지).
- SQLite 타입: UUID→`TEXT`(자동 생성 `lower(hex(randomblob(16)))`), JSON/배열→`TEXT`+`json_valid` 체크(배열 조회는 `json_each`), 시각→ISO-8601 `TEXT`, 불리언→`INTEGER 0/1`.
- `TURSO_AUTH_TOKEN` 은 서버 전용. 브라우저 번들·`NEXT_PUBLIC_*` 에 넣지 않는다.
- 명령: `npm run db:migrate | db:seed | db:check`, `npm test`(인메모리 DB), `npm run typecheck`.
- `supabase/schema.sql` 은 전환 전 원본이라 `db/_legacy_supabase_schema.sql.txt` 로만 남겼다. 실행하지 말 것.

## 개발자 참고
1. 사용자는 비기너 "vibe coder" — 기술 용어를 설명한다.
2. 한국어로 소통, 주석도 한국어 가능.
3. 기존 앱 연동: 기존 앱의 API 를 최대한 재사용한다.

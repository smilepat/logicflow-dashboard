# VS Code + Claude Code로 이어서 작업하기

## 1. 압축 해제

```bash
# 원하는 작업 폴더로 이동 (예: ~/projects)
cd ~/projects
unzip logicflow-dashboard-init.zip
cd logicflow-dashboard
```

## 2. Git 저장소 초기화 + GitHub 연결

이미 GitHub에 `smilepat/logicflow-dashboard` 레포가 생성되어 있고 README로 초기화되어 있으므로,
**clone 후 파일을 합치는 방식**이 충돌 없이 가장 안전합니다.

```bash
# 현재 폴더(압축 해제한 파일들) 이름을 임시로 바꿔두고
cd ..
mv logicflow-dashboard logicflow-dashboard-files

# GitHub 레포를 정식으로 clone
git clone https://github.com/smilepat/logicflow-dashboard.git
cd logicflow-dashboard

# 압축 해제했던 파일들을 clone 폴더 안으로 복사 (README는 덮어쓰기)
cp -r ../logicflow-dashboard-files/* .
cp ../logicflow-dashboard-files/.gitignore .

# 정리
rm -rf ../logicflow-dashboard-files
```

## 3. 커밋 & 푸시

```bash
git add .
git commit -m "docs: 초기 프로젝트 구조 및 계획 문서 추가"
git push origin main
```

## 4. VS Code에서 열기

```bash
code .
```

## 5. Claude Code 시작하기

VS Code 터미널(Ctrl+`)에서:

```bash
claude
```

Claude Code가 처음 실행되면 프로젝트 루트의 `CLAUDE.md`를 자동으로 읽어 컨텍스트를 파악합니다.
별도로 아무것도 안 해도 되지만, 확실히 하려면 첫 메시지로 아래처럼 입력하세요:

```
CLAUDE.md와 docs/PROJECT_PLAN.md를 읽고 프로젝트 맥락을 파악한 다음,
Phase 0 (기존 자원 감사)부터 이어서 진행해줘.
```

## 6. Supabase 연결 (스키마 실행)

`supabase/schema.sql` 파일을 아직 Supabase에서 실행하지 않았다면:

1. https://supabase.com → 프로젝트 생성 (또는 기존 프로젝트 사용)
2. SQL Editor → `supabase/schema.sql` 전체 내용 붙여넣기 → Run
3. `.env.local` 파일 생성 (Claude Code에게 요청하면 만들어줌):
   ```
   NEXT_PUBLIC_SUPABASE_URL=your-project-url
   NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
   ```

## 7. 다음 세션에서 이어갈 때

Claude Code 새 세션 시작 시 첫 메시지:

```
이 프로젝트(logicflow-dashboard) 이어서 작업해줘.
CLAUDE.md와 docs/PROJECT_PLAN.md 참고해서 현재 진행 상황 파악하고,
다음 할 일 알려줘.
```

---

## 폴더 구조 요약

```
logicflow-dashboard/
├── README.md                      # 프로젝트 개요
├── CLAUDE.md                      # Claude Code 프로젝트 지침 (자동 로드됨)
├── SETUP_VSCODE_CLAUDE_CODE.md    # 이 파일
├── .gitignore
├── docs/
│   ├── PROJECT_PLAN.md            # 전체 개발 계획 (Phase 0~4)
│   └── DATA_INVENTORY.md          # 기존 자원(Turso/Neo4j/Firebase) 감사 템플릿
└── supabase/
    └── schema.sql                 # 6개 테이블 + 테스트 데이터
```

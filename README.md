# Claude Starter Kit

Claude Code 개발 환경을 빠르게 세팅하는 툴킷.

Permissions, MCP 서버, 범용 스킬, AI 협업 규칙을 한 번에 설치.

## 포함 내용

| 항목 | 설명 |
|------|------|
| **Permissions** | `bypassPermissions` 등 3단계 프리셋 (power/balanced/safe) |
| **MCP Servers** | context7, playwright, sequential-thinking, github, firebase |
| **Skills** | pdf, docx, pptx, mermaid, error-tracking 등 범용 스킬 |
| **Rules** | AI 협업 규칙, 보안 코딩, Git 워크플로우 |

### SuperClaude Framework

SuperClaude는 별도 프로젝트입니다. 이 킷의 설치 스크립트가 자동으로 클론하고 설치합니다.

- https://github.com/SuperClaude-Org/SuperClaude_Framework

## 설치

### Claude Code 안에서 (권장)

```
이 레포 클론해서 전체 설치해줘
https://github.com/Raidcompany/claude-starter-kit
```

Claude가 알아서:
1. 레포 클론
2. `setup.ps1 -All` (Windows) 또는 `setup.sh --all` (Mac/Linux) 실행
3. 결과 확인

### 선택 설치

```
claude-starter-kit에서 MCP 서버랑 permissions만 설치해줘
```

→ Claude가 `setup.ps1 -Pick mcp,perms` 실행

### 직접 실행

```powershell
# Windows
git clone https://github.com/Raidcompany/claude-starter-kit.git
cd claude-starter-kit
.\setup.ps1 -All
```

```bash
# Mac/Linux
git clone https://github.com/Raidcompany/claude-starter-kit.git
cd claude-starter-kit
chmod +x setup.sh
./setup.sh --all
```

## 설치 옵션

### Components

| 이름 | 플래그 값 | 내용 |
|------|----------|------|
| Claude Code | `claude` | npm 설치/업데이트 |
| SuperClaude | `superclaude` | 프레임워크 클론 + 설치 |
| MCP Servers | `mcp` | 글로벌 스코프로 5개 서버 등록 |
| Permissions | `perms` | settings.json 프리셋 적용 |
| Skills | `skills` | ~/.claude/commands/에 스킬 복사 |
| Rules | `rules` | AI 협업/보안/Git 규칙 복사 |

```powershell
# 전체 설치
.\setup.ps1 -All

# 선택 설치
.\setup.ps1 -Pick claude,mcp,perms

# 설치 가능 항목 보기
.\setup.ps1 -List
```

### Permission Presets

| 프리셋 | 설명 | 대상 |
|--------|------|------|
| **power** (기본) | 모든 도구 자동 허용, `bypassPermissions` | 숙련자 |
| **balanced** | 읽기/검색/빌드 자동, 파일 수정/git push 확인 | 일반 |
| **safe** | 읽기만 자동, 나머지 전부 확인 | 입문자 |

```powershell
.\setup.ps1 -Pick perms -PermPreset balanced
```

## MCP Servers

글로벌 스코프(`-s user`)로 등록되어 모든 프로젝트에서 자동 사용 가능.

| 서버 | 용도 |
|------|------|
| context7 | 라이브러리 공식 문서 조회 |
| playwright | 브라우저 자동화 / E2E 테스트 |
| sequential-thinking | 복잡한 분석 / 단계별 추론 |
| github | GitHub 이슈 / PR / 코드 검색 |
| firebase | Firebase 프로젝트 관리 |

> GitHub MCP는 `GITHUB_PERSONAL_ACCESS_TOKEN` 환경변수가 필요합니다.
> https://github.com/settings/tokens 에서 발급하세요.

## Rules

### AI 협업 규칙 (`rules/ai-collaboration.md`)

AI와 코딩할 때 오류를 줄이는 4원칙:
1. **작게 나눈다** — 한 번에 파일 10개 이하
2. **빌드 자주 돌린다** — 파일 3개 이상 수정 시 빌드
3. **의도 먼저 확인** — 코드 전에 "이렇게 할 건데 맞죠?"
4. **기존 코드 먼저 읽는다** — 추측하지 않는다

### 보안 코딩 (`rules/security-coding.md`)

OWASP 기반 언어 무관 보안 규칙 (SQL Injection, XSS, CSRF 등)

### Git 워크플로우 (`rules/git-workflow.md`)

브랜치 전략, 커밋 컨벤션, 세션 시작 체크리스트

## 파일 구조

```
claude-starter-kit/
├── README.md
├── setup.ps1              # Windows 설치 스크립트
├── setup.sh               # Mac/Linux 설치 스크립트
├── permissions/
│   ├── power.json         # 전부 자동 허용
│   ├── balanced.json      # 읽기/빌드 자동, 수정 확인
│   └── safe.json          # 읽기만 자동
├── rules/
│   ├── ai-collaboration.md
│   ├── security-coding.md
│   └── git-workflow.md
└── skills/                # 범용 스킬
    ├── pdf/
    ├── docx/
    ├── mermaid/
    └── ...
```

## 사전 요구사항

- **Git** — `winget install Git.Git` 또는 https://git-scm.com
- **Node.js** — `winget install OpenJS.NodeJS.LTS` 또는 https://nodejs.org
- **Claude Code** — 이미 설치되어 있거나 스크립트가 설치해줌

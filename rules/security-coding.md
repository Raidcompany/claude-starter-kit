# Security Coding Rules

> OWASP ASVS 기준. 코드 작성 시점에 적용한다.
> 언어 무관 원칙 — 프로젝트별 구현 방법은 각 프로젝트 CLAUDE.md에서 정의한다.

## SQL Injection 방지 (CWE-89)

- ORM/쿼리빌더 빌트인 메서드 우선 사용
- Raw query 시 반드시 **파라미터 바인딩** (문자열 결합으로 쿼리 조립 금지)
- 사용자 입력을 SQL 문자열에 직접 삽입하는 패턴 금지

```typescript
// ❌ 금지
const query = `SELECT * FROM users WHERE id = '${userId}'`

// ✅ 올바른 방법
const user = await prisma.user.findUnique({ where: { id: userId } })
// 또는 파라미터 바인딩
const user = await prisma.$queryRaw`SELECT * FROM users WHERE id = ${userId}`
```

## XSS 방지 (CWE-79)

- **프레임워크 기본 이스케이핑** 활용 (React JSX, `htmlspecialchars()` 등)
- **Raw HTML 출력** 시 반드시 sanitize 라이브러리로 살균
- `innerHTML`, `document.write` 사용 금지
- `dangerouslySetInnerHTML` 사용 시 반드시 DOMPurify 등으로 살균

## Command Injection 방지 (CWE-78)

- 사용자 입력을 시스템 명령어에 전달 금지
- `eval()` 및 동적 코드 실행 함수 사용 금지

## 입력 검증 (CWE-20)

- 모든 API에서 **서버사이드 입력 검증** 필수 (Zod, Joi 등)
- 허용 목록(allow-list) 기반 검증 우선
- 클라이언트 검증은 UX용이지 보안이 아님

## 접근 제어 (CWE-284)

- 모든 민감한 작업에서 서버사이드 인증/인가 체크
- 리소스 접근 시 본인 소유 확인 (IDOR 방지)

## 기타

- 비밀번호는 `bcrypt` 또는 `argon2`로 해시 (평문 저장 금지)
- **보안 난수 생성기** 사용 (`crypto.randomUUID()`, `secrets.token_hex()` 등)
- `Math.random()`을 보안 토큰에 사용 금지
- 에러 응답에 스택 트레이스, DB 쿼리 등 내부 정보 노출 금지
- 외부 링크에 `rel="noopener noreferrer"` 설정
- 파일 업로드 시 파일명은 보안 난수 기반으로 생성
- API 키, DB 비밀번호 등은 반드시 **환경변수**로 주입
- `.env` 파일 커밋 금지

# 설치 가이드

## 요구 사항

- Ubuntu 24.04 LTS
- 공인 IP가 있는 서버 (VPS, 클라우드 등)
- 포트 80, 443 오픈 (방화벽 설정 필요)

---

## 설치

서버에 SSH 접속 후 아래 명령어 한 줄 실행:

```bash
curl -fsSL https://raw.githubusercontent.com/Infopark-T/OJ_Renewal_GSGHINFO/main/server-setup.sh -o /tmp/setup.sh && sudo bash /tmp/setup.sh
```

실행 중 도메인 입력을 물어봅니다.

```
서버 공인 IP: 123.456.789.0

도메인이 있으면 입력하세요 (없으면 엔터 → IP로 접속):
```

- **도메인 있으면** 입력 → SSL 인증서까지 자동 안내
- **도메인 없으면** 엔터 → IP 주소로 바로 접속

스크립트가 자동으로 처리하는 것들:
- Docker, Nginx, Certbot 설치
- 코드 클론 (`/opt/hustoj`)
- DB 패스워드, JWT 시크릿 키 자동 생성 (`.env`)
- Nginx 리버스 프록시 설정

---

## 앱 시작

설치 완료 후 순서대로 실행:

```bash
cd /opt/hustoj

# 1. 컨테이너 빌드 및 시작 (최초 5~10분 소요)
docker compose -f docker-compose.prod.yml up -d --build

# 2. 컨테이너 상태 확인
docker compose -f docker-compose.prod.yml ps

# 3. Piston 코드 실행 런타임 설치 (최초 1회, 수 분 소요)
bash piston-setup.sh
```

---

## SSL 인증서 (도메인 있는 경우)

DNS가 이 서버를 가리킨 후 실행:

```bash
certbot --nginx -d your.domain.com
```

이후 자동 갱신은 certbot이 알아서 처리합니다.

---

## 기본 관리자 계정

| 항목 | 값 |
|---|---|
| 아이디 | `admin` |
| 비밀번호 | `comedu` |

> 로그인 후 즉시 비밀번호를 변경하세요.

---

## 업데이트

새 버전 배포 시:

```bash
cd /opt/hustoj
bash deploy.sh
```

코드 pull → 이미지 빌드 → 컨테이너 재시작까지 자동으로 처리됩니다.

---

## 문제 해결

**컨테이너 로그 확인**
```bash
docker compose -f docker-compose.prod.yml logs -f
```

**특정 서비스 로그만 보기**
```bash
docker compose -f docker-compose.prod.yml logs -f backend
docker compose -f docker-compose.prod.yml logs -f frontend
```

**컨테이너 재시작**
```bash
docker compose -f docker-compose.prod.yml restart
```

**전체 초기화** (DB 데이터 포함 삭제 — 주의)
```bash
docker compose -f docker-compose.prod.yml down -v
```

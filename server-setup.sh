#!/bin/bash
# ================================================================
# HustOJ 서버 최초 설치 스크립트 (Ubuntu 24.04 LTS 기준)
# 사용법: sudo bash server-setup.sh
# ================================================================
set -e

REPO_URL="https://github.com/Infopark-T/OJ_Renewal_GSGHINFO.git"
DOMAIN="your.domain.com"   # ← 도메인 수정 후 실행
APP_DIR="/opt/hustoj"

echo "=== [1/6] 시스템 패키지 업데이트 ==="
apt-get update && apt-get upgrade -y
apt-get install -y git curl openssl

echo "=== [2/6] Docker 설치 ==="
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com | sh
    systemctl enable docker
    systemctl start docker
else
    echo "Docker 이미 설치됨 ($(docker --version))"
fi

# Docker Compose V2 확인
if ! docker compose version &> /dev/null; then
    apt-get install -y docker-compose-plugin
fi
echo "Docker Compose: $(docker compose version)"

echo "=== [3/6] Nginx + Certbot 설치 ==="
apt-get install -y nginx snapd
systemctl enable nginx && systemctl start nginx

# Ubuntu 24.04: Certbot은 snap으로 설치
if ! command -v certbot &> /dev/null; then
    snap install core && snap refresh core
    snap install --classic certbot
    ln -sf /snap/bin/certbot /usr/bin/certbot
else
    echo "Certbot 이미 설치됨"
fi

echo "=== [4/6] 코드 클론 ==="
if [ -d "$APP_DIR/.git" ]; then
    echo "$APP_DIR 이미 존재함 — git pull"
    git -C "$APP_DIR" pull
else
    git clone "$REPO_URL" "$APP_DIR"
fi

echo "=== [5/6] .env 파일 생성 ==="
if [ ! -f "$APP_DIR/.env" ]; then
    SECRET=$(openssl rand -hex 32)
    DB_PASS=$(openssl rand -hex 16)
    DB_ROOT=$(openssl rand -hex 16)
    cat > "$APP_DIR/.env" <<EOF
MYSQL_ROOT_PASSWORD=$DB_ROOT
MYSQL_PASSWORD=$DB_PASS
SECRET_KEY=$SECRET
EOF
    echo ""
    echo "  [!] .env 자동 생성됨 — 아래 정보를 안전한 곳에 보관하세요"
    echo "      DB 패스워드 : $DB_PASS"
    echo "      DB Root PW  : $DB_ROOT"
    echo ""
else
    echo ".env 이미 존재함 — 건드리지 않음"
fi

echo "=== [6/6] Nginx 사이트 설정 ==="
cat > /etc/nginx/sites-available/hustoj <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        client_max_body_size 50m;
        proxy_read_timeout 120s;
    }
}
EOF

# default 사이트 비활성화
rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/hustoj /etc/nginx/sites-enabled/hustoj
nginx -t && systemctl reload nginx

echo ""
echo "=============================================="
echo " 설치 완료! 이후 순서:"
echo ""
echo "  1. 앱 빌드 & 시작"
echo "     cd $APP_DIR"
echo "     docker compose -f docker-compose.prod.yml up -d --build"
echo ""
echo "  2. Piston 런타임 설치 (최초 1회, 컨테이너 뜬 후)"
echo "     bash $APP_DIR/piston-setup.sh"
echo ""
echo "  3. SSL 인증서 발급 (DNS가 이 서버를 가리킨 후)"
echo "     certbot --nginx -d $DOMAIN"
echo "=============================================="

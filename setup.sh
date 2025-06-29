#!/usr/bin/env bash
set -euo pipefail

# مسیر اصلی نصب
INSTALL_DIR=/opt/docker-setup
mkdir -p "$INSTALL_DIR"{/data,/letsencrypt,/code-server,/portainer}
chown -R "$SUDO_UID:$SUDO_GID" "$INSTALL_DIR"

cd "$INSTALL_DIR"

# ساخت docker-compose.yml
cat > docker-compose.yml <<'EOF'
version: '3.8'
services:
  npm:
    image: jc21/nginx-proxy-manager:latest
    container_name: npm
    restart: unless-stopped
    ports:
      - "80:80"
      - "81:81"
      - "443:443"
    volumes:
      - ./data/npm:/data
      - ./letsencrypt:/etc/letsencrypt

  code-server:
    image: linuxserver/code-server:latest
    container_name: code-server
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=${TZ}
    ports:
      - "8443:8443"
    volumes:
      - ./code-server:/config
      - ~/projects:/home/coder/projects
    restart: unless-stopped

  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    command: -H unix:///var/run/docker.sock
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./portainer:/data
    ports:
      - "9000:9000"
    restart: unless-stopped
EOF

# نصب docker-compose اگر نیست
if ! command -v docker-compose &>/dev/null; then
  curl -sSL "https://github.com/docker/compose/releases/download/$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
fi

# اجرای docker-compose
docker-compose pull
docker-compose up -d

# نمایش وضعیت
echo -e "\n✅ تمامی کانتینرها اجرا شدند:"
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"

# دریافت پسورد code‑server
sleep 5
CS_PASS=$(docker exec code-server cat /config/password || echo "دسترسی به پسورد نشد")

# نمایش راهنمای کاربر
cat <<EOF

🚀 راهنمای دسترسی:

1. **Nginx Proxy Manager**:
   • آدرس: http://$(hostname -I | awk '{print $1}'):81
   • Default login: admin@example.com / changeme

2. **code‑server**:
   • آدرس: https://$(hostname -I | awk '{print $1}'):8443
   • Username: coder
   • Password: $CS_PASS

3. **Portainer**:
   • آدرس: http://$(hostname -I | awk '{print $1}'):9000
   • راهنمای setup اولین ورود نمایش داده می‌شود.

Installed directory: $INSTALL_DIR

برای توقف یا استارت مجدد:
  cd $INSTALL_DIR && docker-compose {down,up -d}

EOF

#!/usr/bin/env bash
set -e
set -o pipefail

# رنگ‌ها
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}INFO: $1${NC}"; }
log_success() { echo -e "${GREEN}SUCCESS: $1${NC}"; }
log_warning() { echo -e "${YELLOW}WARNING: $1${NC}"; }

# اصلاح /etc/hosts
fix_hostname_resolution() {
    local HOSTNAME=$(hostname)
    if ! grep -q "$HOSTNAME" /etc/hosts; then
        log_info "Fixing /etc/hosts for hostname resolution..."
        echo "127.0.0.1 $HOSTNAME" >> /etc/hosts
        log_success "Added '$HOSTNAME' to /etc/hosts"
    fi
}

# نصب ابزار پایه
install_prerequisites() {
    log_info "Installing system prerequisites..."
    apt-get update -y
    apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release unzip git python3-pip nano tmux
}

# پاک‌سازی امن Docker
cleanup_docker() {
    log_warning "Stopping and removing all Docker containers, volumes, images, and custom networks..."

    docker ps -q | xargs -r docker stop
    docker ps -a -q | xargs -r docker rm -f
    docker volume ls -q | xargs -r docker volume rm
    docker image prune -af
    docker network ls --filter "type=custom" -q | grep -vE '^$' | xargs -r docker network rm || true
    docker system prune -f --volumes || true

    log_success "Docker cleanup completed."
}

# نصب Docker
install_docker() {
    if command -v docker &> /dev/null; then
        log_success "Docker is already installed."
        return
    fi
    log_info "Installing Docker..."
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    systemctl enable docker && systemctl start docker
    log_success "Docker installed and running."
}

# Code-Server
install_code_server() {
    log_info "Deploying code-server container..."
    docker volume create code-server-config >/dev/null 2>&1 || true
    docker run -d \
        --name=code-server \
        --restart=unless-stopped \
        -p 8443:8443 \
        -e PUID=1000 -e PGID=1000 -e TZ=Asia/Tehran \
        -v code-server-config:/config \
        -v ~/projects:/home/coder/projects \
        linuxserver/code-server:latest
    log_success "Code-Server is up."
}

# Nginx Proxy Manager
install_npm() {
    log_info "Deploying Nginx Proxy Manager container..."
    mkdir -p /opt/npm/letsencrypt
    docker volume create npm-data >/dev/null 2>&1 || true
    docker run -d \
        --name=npm \
        --restart=unless-stopped \
        -p 80:80 -p 81:81 -p 443:443 \
        -v npm-data:/data \
        -v /opt/npm/letsencrypt:/etc/letsencrypt \
        jc21/nginx-proxy-manager:latest
    log_success "Nginx Proxy Manager is up."
}

# Portainer
install_portainer() {
    log_info "Deploying Portainer container..."
    docker volume create portainer_data >/dev/null 2>&1 || true
    docker run -d \
        --name=portainer \
        --restart=unless-stopped \
        -p 9000:9000 \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v portainer_data:/data \
        portainer/portainer-ce:latest
    log_success "Portainer is up."
}

# Speedtest Tracker (SQLite)
install_speedtest_tracker() {
    log_info "Deploying Speedtest Tracker container (SQLite mode)..."
    docker volume create speedtest_data >/dev/null 2>&1 || true
    docker run -d \
        --name=speedtest-tracker \
        --restart=unless-stopped \
        -p 8765:80 \
        -v speedtest_data:/config \
        -e DB_CONNECTION=sqlite \
        -e PUID=1000 \
        -e PGID=1000 \
        -e TZ=Asia/Tehran \
        ghcr.io/alexjustesen/speedtest-tracker:v0.11.7
    log_success "Speedtest Tracker is up."
}

# گزارش نهایی
final_summary() {
    PUBLIC_IP=$(curl -s ifconfig.me || hostname -I | awk '{print $1}')
    echo ""
    echo -e "${GREEN}========================================================${NC}"
    echo -e "${GREEN}🎉 نصب و راه‌اندازی کامل شد! 🎉${NC}"
    echo -e "${GREEN}========================================================${NC}"
    echo ""
    log_info "--- اطلاعات دسترسی ---"

    echo -e "${YELLOW}>> Code-Server:${NC}"
    echo "   - URL: https://$PUBLIC_IP:8443"
    echo "   - Username: coder"
    echo "   - Password: در فایل: /config/config.yaml"
    echo "     مشاهده با: docker exec -it code-server cat /config/config.yaml"

    echo ""
    echo -e "${YELLOW}>> Nginx Proxy Manager:${NC}"
    echo "   - URL: http://$PUBLIC_IP:81"
    echo "   - Email:    admin@example.com"
    echo "   - Password: changeme"

    echo ""
    echo -e "${YELLOW}>> Portainer:${NC}"
    echo "   - URL: http://$PUBLIC_IP:9000"
    echo "   - در اولین ورود، حساب جدید بسازید."

    echo ""
    echo -e "${YELLOW}>> Speedtest Tracker:${NC}"
    echo "   - URL: http://$PUBLIC_IP:8765"
    echo "   - در اولین ورود، حساب خود را بسازید (نام کاربری و رمز عبور دلخواه)."
    echo "   - دیتابیس SQLite داخلی استفاده شده (بدون نیاز به MySQL)"

    echo ""
    echo -e "${BLUE}دستورات مفید:${NC}"
    echo "  docker ps                    # لیست کانتینرها"
    echo "  docker logs -f <name>        # لاگ لحظه‌ای"
    echo "  docker restart <name>        # ریست کانتینر"
    echo ""
}

# اجرای کامل
main() {
    fix_hostname_resolution
    install_prerequisites
    install_docker
    cleanup_docker
    install_code_server
    install_npm
    install_portainer
    install_speedtest_tracker
    final_summary
}

main

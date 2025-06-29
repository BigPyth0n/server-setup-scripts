#!/usr/bin/env bash
set -e
set -o pipefail

# رنگ‌ها
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# لاگ
log_info() { echo -e "${BLUE}INFO: $1${NC}"; }
log_success() { echo -e "${GREEN}SUCCESS: $1${NC}"; }
log_warning() { echo -e "${YELLOW}WARNING: $1${NC}"; }

# 🔧 اصلاح /etc/hosts برای جلوگیری از خطای sudo
fix_hostname_resolution() {
    local HOSTNAME=$(hostname)
    if ! grep -q "$HOSTNAME" /etc/hosts; then
        log_info "Fixing /etc/hosts for hostname resolution..."
        echo "127.0.0.1 $HOSTNAME" >> /etc/hosts
        log_success "Added '$HOSTNAME' to /etc/hosts"
    fi
}

# 📦 نصب ابزار پایه
install_prerequisites() {
    log_info "Installing system prerequisites..."
    apt-get update -y
    apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release unzip git python3-pip nano tmux
}

# 🧹 پاکسازی کامل داکر
cleanup_docker() {
    log_warning "Stopping and removing all Docker containers, volumes, and networks..."
    docker stop $(docker ps -q) 2>/dev/null || true
    docker rm -f $(docker ps -a -q) 2>/dev/null || true
    docker volume prune -f
    docker network prune -f
    log_success "Docker cleanup completed."
}

# 🐳 نصب Docker
install_docker() {
    if command -v docker &> /dev/null; then
        log_success "Docker is already installed."
        return
    fi
    log_info "Installing Docker..."
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
      https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
      | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    systemctl enable docker && systemctl start docker
    log_success "Docker installed and running."
}

# 📦 نصب Code-Server
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

# 📦 نصب Nginx Proxy Manager
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

# 📦 نصب Portainer
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

# 📦 نصب Speedtest Tracker
install_speedtest_tracker() {
    log_info "Deploying Speedtest-Tracker container..."
    docker volume create speedtest_data >/dev/null 2>&1 || true
    docker run -d \
      --name=speedtest-tracker \
      --restart=unless-stopped \
      -p 8765:80 \
      -v speedtest_data:/config \
      -e PUID=1000 \
      -e PGID=1000 \
      -e TZ=Asia/Tehran \
      ghcr.io/alexjustesen/speedtest-tracker
    log_success "Speedtest-Tracker is up."
}

# ✅ نمایش اطلاعات اتصال
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
    echo "   - Password: ذخیره شده در: /config/config.yaml"
    echo "     مشاهده با: docker exec -it code-server cat /config/config.yaml"

    echo ""
    echo -e "${YELLOW}>> Nginx Proxy Manager:${NC}"
    echo "   - URL: http://$PUBLIC_IP:81"
    echo "   - Email:    admin@example.com"
    echo "   - Password: changeme"

    echo ""
    echo -e "${YELLOW}>> Portainer:${NC}"
    echo "   - URL: http://$PUBLIC_IP:9000"
    echo "   - هنگام اولین ورود، حساب جدید بسازید."

    echo ""
    echo -e "${YELLOW}>> Speedtest Tracker:${NC}"
    echo "   - URL: http://$PUBLIC_IP:8765"
    echo "   - گرافی UI کامل برای مانیتورینگ سرعت و تاریخچه تست‌ها دارد."
    echo "   - تنظیمات را پس از اولین ورود انجام دهید."

    echo ""
    echo -e "${BLUE}برای مشاهده وضعیت کانتینرها:${NC} docker ps"
    echo -e "${BLUE}برای مشاهده لاگ هر کانتینر:${NC} docker logs <container_name>"
    echo ""
}

# اجرای مراحل
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

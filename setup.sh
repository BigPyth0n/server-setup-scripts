#!/usr/bin/env bash

set -e
set -o pipefail

# رنگ‌ها
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# توابع لاگ
log_info() { echo -e "${BLUE}INFO: $1${NC}"; }
log_success() { echo -e "${GREEN}SUCCESS: $1${NC}"; }
log_warning() { echo -e "${YELLOW}WARNING: $1${NC}"; }

# پیش‌نیازها
install_prerequisites() {
    log_info "Installing system prerequisites..."
    apt-get update -y
    apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release unzip git python3-pip nano tmux
}

# نصب Docker
install_docker() {
    if command -v docker &> /dev/null; then
        log_success "Docker already installed."
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
    log_success "Docker installed and enabled."
}

# نصب code-server با کانتینر
install_code_server() {
    log_info "Setting up code-server container..."
    docker volume create code-server-config >/dev/null 2>&1 || true
    docker run -d \
      --name=code-server \
      --restart=unless-stopped \
      -p 8443:8443 \
      -e PUID=1000 \
      -e PGID=1000 \
      -e TZ=Asia/Tehran \
      -v code-server-config:/config \
      -v ~/projects:/home/coder/projects \
      linuxserver/code-server:latest
    log_success "Code-Server container started."
}

# نصب Nginx Proxy Manager
install_npm() {
    log_info "Setting up Nginx Proxy Manager container..."
    mkdir -p /opt/npm/letsencrypt
    docker volume create npm-data >/dev/null 2>&1 || true
    docker run -d \
      --name=npm \
      --restart=unless-stopped \
      -p 80:80 -p 81:81 -p 443:443 \
      -v npm-data:/data \
      -v /opt/npm/letsencrypt:/etc/letsencrypt \
      jc21/nginx-proxy-manager:latest
    log_success "Nginx Proxy Manager container started."
}

# نصب Portainer
install_portainer() {
    log_info "Setting up Portainer container..."
    docker volume create portainer_data >/dev/null 2>&1 || true
    docker run -d \
      --name=portainer \
      --restart=unless-stopped \
      -p 9000:9000 \
      -v /var/run/docker.sock:/var/run/docker.sock \
      -v portainer_data:/data \
      portainer/portainer-ce:latest
    log_success "Portainer container started."
}

# نمایش نهایی
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
    echo "   - Password: داخل کانتینر ذخیره شده در /config/config.yaml"
    echo "     (برای مشاهده: docker exec -it code-server cat /config/config.yaml)"

    echo ""
    echo -e "${YELLOW}>> Nginx Proxy Manager:${NC}"
    echo "   - URL: http://$PUBLIC_IP:81"
    echo "   - Default Admin:"
    echo "     Email:    admin@example.com"
    echo "     Password: changeme"
    echo "   - پس از ورود رمز عبور را حتماً تغییر دهید."

    echo ""
    echo -e "${YELLOW}>> Portainer:${NC}"
    echo "   - URL: http://$PUBLIC_IP:9000"
    echo "   - در اولین ورود، باید حساب جدید بسازید."

    echo ""
    echo -e "${GREEN}برای مدیریت کانتینرها از Portainer استفاده کنید یا دستورات زیر را اجرا کنید:${NC}"
    echo -e "${BLUE}docker ps${NC}  → مشاهده وضعیت کانتینرها"
    echo -e "${BLUE}docker logs <container_name>${NC}  → مشاهده لاگ کانتینر"
    echo ""
}

# اجرای همه مراحل
main() {
    install_prerequisites
    install_docker
    install_code_server
    install_npm
    install_portainer
    final_summary
}

main

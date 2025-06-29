#!/usr/bin/env bash

# این اسکریپت با بروز هرگونه خطا متوقف می‌شود تا از مشکلات بعدی جلوگیری شود.
set -e
set -o pipefail

# تعریف رنگ‌ها برای خروجی بهتر
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- توابع کمکی ---
log_info() {
    echo -e "${BLUE}INFO: $1${NC}"
}

log_success() {
    echo -e "${GREEN}SUCCESS: $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}WARNING: $1${NC}"
}

# --- توابع اصلی ---

# تابع ۱: نصب پیش‌نیازهای عمومی
install_prerequisites() {
    log_info "Updating package list and installing prerequisites..."
    apt-get update -y
    apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release unzip git python3-pip nano tmux
}

# تابع ۲: نصب داکر
install_docker() {
    if command -v docker &> /dev/null; then
        log_success "Docker is already installed. Skipping."
        return
    fi

    log_info "Installing Docker..."
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    log_info "Installing Docker packages..."
    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    systemctl enable docker && systemctl start docker
    log_success "Docker installed and enabled."
}

# تابع ۳: نصب code-server
install_code_server() {
    log_info "Installing/Updating code-server..."
    curl -fsSL https://code-server.dev/install.sh | sh
    systemctl enable --now code-server@root
    log_success "code-server is installed and running."
}

# تابع ۴: نصب Nginx Proxy Manager
install_npm() {
    log_info "Setting up Nginx Proxy Manager container..."
    if [ "$(docker ps -q -f name=npm)" ]; then
        log_success "Nginx Proxy Manager is already running."
        return
    fi
    
    if [ "$(docker ps -aq -f status=exited -f name=npm)" ]; then
        log_warning "Found a stopped NPM container. Removing it before recreating..."
        docker rm npm
    fi

    if ! docker volume ls | grep -q "npm-data"; then
        log_info "Creating docker volume 'npm-data'..."
        docker volume create npm-data
    fi

    log_info "Starting Nginx Proxy Manager container..."
    docker run -d \
      --name=npm \
      --restart=unless-stopped \
      -p 80:80 \
      -p 81:81 \
      -p 443:443 \
      -v npm-data:/data \
      -v /var/run/docker.sock:/var/run/docker.sock \
      jc21/nginx-proxy-manager:latest

    log_success "Nginx Proxy Manager container has been started."
}

# تابع ۵: نمایش اطلاعات نهایی
final_summary() {
    PUBLIC_IP=$(curl -s ifconfig.me)
    echo ""
    echo -e "${GREEN}========================================================${NC}"
    echo -e "${GREEN}🎉 Installation/Verification Complete! 🎉${NC}"
    echo -e "${GREEN}========================================================${NC}"
    echo ""
    log_info "--- Access Information ---"
    
    echo -e "${YELLOW}>> Code-Server:${NC}"
    echo "   - URL: http://${PUBLIC_IP}:8080"
    echo "   - Password command: cat /root/.config/code-server/config.yaml"
    
    echo ""
    echo -e "${YELLOW}>> Nginx Proxy Manager:${NC}"
    echo "   - URL: http://${PUBLIC_IP}:81"
    echo "   - Default Admin User (if first time):"
    echo "     - Email:    admin@example.com"
    echo "     - Password: changeme"
    echo "   - IMPORTANT: Log in immediately and change your password!"
    echo ""
}

# --- بدنه اصلی اسکریپت ---
main() {
    install_prerequisites
    install_docker
    install_code_server
    install_npm
    final_summary
}

# اجرای تابع اصلی
main

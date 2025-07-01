#!/usr/bin/env bash
set -e
set -o pipefail
trap 'echo -e "\n\033[1;31m💥 Script failed at line $LINENO\033[0m\n"' ERR

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}INFO: $1${NC}"; }
log_success() { echo -e "${GREEN}SUCCESS: $1${NC}"; }
log_warning() { echo -e "${YELLOW}WARNING: $1${NC}"; }

print_banner() {
cat << "EOF"
  {
  {
  {  
  🚀 KITZONE SERVER SETUP v1.0 🚀
  }
  }
  }  
EOF
}

fix_hostname_resolution() {
    local HOSTNAME=$(hostname)
    if ! grep -q "$HOSTNAME" /etc/hosts; then
        echo "127.0.0.1 $HOSTNAME" >> /etc/hosts
    fi
}

install_prerequisites() {
    log_info "Installing prerequisites..."
    apt-get update -y
    apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release unzip git python3-pip nano tmux
}

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

cleanup_docker() {
    log_warning "Performing full Docker cleanup..."
    docker stop $(docker ps -q) 2>/dev/null || true
    docker rm -f $(docker ps -aq) 2>/dev/null || true
    docker rmi -f $(docker images -q) 2>/dev/null || true
    docker volume rm $(docker volume ls -q) 2>/dev/null || true
    docker network prune -f >/dev/null || true
    log_success "Docker cleanup complete."
}

create_docker_network() {
    log_info "Creating Docker network 'kitzone-net'..."
    docker network create kitzone-net >/dev/null
    log_success "Docker network 'kitzone-net' created."
}

install_code_server() {
    log_info "Deploying Code-Server..."
    docker volume create code-server-config >/dev/null || true
    mkdir -p ~/projects

    docker run -d --name=code-server --network=kitzone-net --restart=unless-stopped \
      -p 8443:8443 \
      -e PUID=1000 -e PGID=1000 -e TZ=Asia/Tehran \
      -v code-server-config:/config \
      -v ~/projects:/home/coder/projects \
      linuxserver/code-server:latest

    log_success "Code-Server deployed."
}

install_npm() {
    log_info "Deploying Nginx Proxy Manager..."
    mkdir -p /opt/npm/letsencrypt
    docker volume create npm-data >/dev/null || true

    docker run -d --name=npm --network=kitzone-net --restart=unless-stopped \
      -p 80:80 -p 81:81 -p 443:443 \
      -v npm-data:/data \
      -v /opt/npm/letsencrypt:/etc/letsencrypt \
      jc21/nginx-proxy-manager:latest

    log_success "Nginx Proxy Manager deployed."
}

install_portainer() {
    log_info "Deploying Portainer..."
    docker volume create portainer_data >/dev/null || true

    docker run -d --name=portainer --network=kitzone-net --restart=unless-stopped \
      -p 9000:9000 \
      -v /var/run/docker.sock:/var/run/docker.sock \
      -v portainer_data:/data \
      portainer/portainer-ce:latest

    log_success "Portainer deployed."
}

install_speedtest_tracker() {
    log_info "Deploying Speedtest Tracker..."
    mkdir -p /opt/speedtest && chown 1000:1000 /opt/speedtest

    docker run -d --name=speedtest-tracker --network=kitzone-net --restart=unless-stopped \
      -p 8765:80 \
      -v /opt/speedtest:/config \
      -e DB_CONNECTION=sqlite \
      -e PUID=1000 -e PGID=1000 -e TZ=Asia/Tehran \
      ghcr.io/alexjustesen/speedtest-tracker:v0.11.7

    log_success "Speedtest Tracker deployed."
}

final_summary() {
    IP=$(curl -s ifconfig.me || hostname -I | awk '{print $1}')
    echo -e "\n${GREEN}========================================================${NC}"
    echo -e "${GREEN}✅ Server setup completed successfully!${NC}"
    echo -e "${GREEN}========================================================${NC}\n"

    echo -e "${YELLOW}Docker network: kitzone-net${NC}\n"

    cat <<EOF

${YELLOW}>> Code-Server:${NC}
  🔗 https://$IP:8443
  👤 Username: coder
  🔐 Password: stored in: /config/config.yaml
      → View with: docker exec -it code-server cat /config/config.yaml

${YELLOW}>> Nginx Proxy Manager:${NC}
  🔗 http://$IP:81
  📧 Email:    admin@example.com
  🔐 Password: changeme

${YELLOW}>> Portainer:${NC}
  🔗 http://$IP:9000
  📝 Create admin user on first login.

${YELLOW}>> Speedtest Tracker:${NC}
  🔗 http://$IP:8765
  👤 Username: admin@example.com
  🔐 Password: password (default)

${BLUE}Useful Docker commands:${NC}
  docker ps
  docker logs -f <name>
  docker restart <name>
  docker exec -it <name> bash

EOF
}

main() {
    print_banner
    fix_hostname_resolution
    install_prerequisites
    install_docker
    cleanup_docker
    create_docker_network
    install_code_server
    install_npm
    install_portainer
    install_speedtest_tracker
    final_summary
}

main

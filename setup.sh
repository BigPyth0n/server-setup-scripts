#!/bin/bash
set -e

# --- مرحله ۱: به‌روزرسانی سیستم و نصب تمام پیش‌نیازها ---
echo ">>> Updating system and installing prerequisites..."
apt-get update -y
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    unzip \
    git \
    python3-pip \
    nano \
    tmux

# --- مرحله ۲: نصب کامل داکر ---
echo ">>> Installing Docker..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

systemctl enable docker
systemctl start docker

# --- مرحله ۳: نصب و راه‌اندازی code-server ---
echo ">>> Installing and setting up code-server..."
curl -fsSL https://code-server.dev/install.sh | sh

# فعال‌سازی سرویس برای کاربر root
systemctl enable --now code-server@root

# --- مرحله ۴: نمایش نتایج ---
echo ""
echo "========================================================"
echo "🎉 Installation Complete! 🎉"
echo "========================================================"
echo ""
echo "--- Verifying installations ---"
docker --version
docker compose version
code-server --version
nano --version
tmux -V
echo "---------------------------------"
echo ""
echo "--- Access Information ---"
PUBLIC_IP=$(curl -s ifconfig.me)
echo "Access code-server at: http://${PUBLIC_IP}:8080"
echo "Find your code-server password by running:"
echo "  cat /root/.config/code-server/config.yaml"
echo ""

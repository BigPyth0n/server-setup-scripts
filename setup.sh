#!/bin/bash
set -e

# --- مرحله ۱: به‌روزرسانی سیستم و نصب تمام پیش‌نیازها ---
echo ">>> (Step 1/4) Updating system and installing prerequisites..."
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
echo ">>> (Step 2/4) Installing Docker..."
install -m 0755 -d /etc/apt/keyrings
# افزودن فلگ --yes برای جلوگیری از پرسیدن سوال و اجرای خودکار
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
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
echo ">>> (Step 3/4) Installing and setting up code-server..."
# اسکریپت نصب code-server خود به اندازه کافی هوشمند است که نصب قبلی را مدیریت کند
curl -fsSL https://code-server.dev/install.sh | sh

# فعال‌سازی سرویس برای کاربر root
systemctl enable --now code-server@root

# --- مرحله ۴: نصب Nginx Proxy Manager به صورت داکری ---
echo ">>> (Step 4/4) Installing Nginx Proxy Manager..."
# ابتدا بررسی می‌کنیم که آیا کانتینر از قبل وجود دارد یا نه
if [ ! "$(docker ps -q -f name=npm)" ]; then
    if [ "$(docker ps -aq -f status=exited -f name=npm)" ]; then
        # اگر کانتینر وجود دارد ولی متوقف شده، آن را حذف می‌کنیم تا دوباره ساخته شود
        docker rm npm
    fi
    echo "Nginx Proxy Manager container not found, creating it..."
    docker volume create npm-data
    docker run -d \
      --name=npm \
      --restart=unless-stopped \
      -p 80:80 \
      -p 81:81 \
      -p 443:443 \
      -v npm-data:/data \
      -v /var/run/docker.sock:/var/run/docker.sock \
      jc21/nginx-proxy-manager:latest
    echo "Nginx Proxy Manager is starting. It may take a minute to be ready."
else
    echo "Nginx Proxy Manager container is already running."
fi


# --- مرحله ۵: نمایش نتایج نهایی ---
echo ""
echo "========================================================"
echo "🎉 Installation/Verification Complete! 🎉"
echo "========================================================"
echo ""
echo "--- Verifying installations ---"
docker --version
docker compose version
code-server --version
echo "---------------------------------"
echo ""
echo "--- Access Information ---"
PUBLIC_IP=$(curl -s ifconfig.me)

echo ">> Code-Server:"
echo "   - URL: http://${PUBLIC_IP}:8080"
echo "   - Password command: cat /root/.config/code-server/config.yaml"
echo ""

echo ">> Nginx Proxy Manager:"
echo "   - URL: http://${PUBLIC_IP}:81"
echo "   - Default Admin User (if first time):"
echo "     - Email:    admin@example.com"
echo "     - Password: changeme"
echo "   - IMPORTANT: Log in immediately and change your email and password!"
echo ""

# 🚀 اسکریپت راه‌اندازی و آماده‌سازی کامل سرور اوبونتو (KitZone Server)

این ریپازیتوری شامل یک اسکریپت Bash پیشرفته و بی‌نقص است که سرور Ubuntu شما را به‌صورت کامل پاک‌سازی و سپس ابزارهای توسعه و مدیریت کانتینر را از صفر نصب می‌کند.

---

## 🔧 ابزارهای نصب‌شده:

- **پیش‌نیازهای عمومی:** `curl`, `git`, `nano`, `tmux`, `python3-pip`، و سایر ابزار پایه
- **Docker Engine** + **Docker Compose Plugin**
- **Code-Server:** نسخه VSCode در مرورگر
- **Nginx Proxy Manager:** مدیریت دامنه و SSL به‌صورت گرافیکی
- **Portainer:** داشبورد مدیریتی برای کانتینرها
- **Speedtest Tracker:** ابزار گرافیکی بررسی و ثبت سرعت اینترنت (SQLite)

---

## 💣 پاکسازی کامل قبل از نصب

در ابتدای اجرای اسکریپت، این عملیات انجام می‌شود:

- توقف و حذف تمام کانتینرهای در حال اجرا
- حذف تمام کانتینرها، ایمیج‌ها، ولوم‌ها و شبکه‌های غیرسیستمی
- بازسازی کامل داکر به حالت تمیز و خام

---

## ⚙️ روش‌های اجرای اسکریپت

### روش مطمئن با wget :

```bash
wget --no-cache --header "Cache-Control: no-cache" --header "Pragma: no-cache" "https://raw.githubusercontent.com/BigPyth0n/server-setup-scripts/refs/heads/main/setup.sh" -O setup.sh
bash setup.sh
```

### روش مطمئن (دانلود و اجرای دستی):

```bash
curl -O https://raw.githubusercontent.com/BigPyth0n/server-setup-scripts/main/setup.sh
chmod +x setup.sh
sudo ./setup.sh
```

---

## 🔐 اطلاعات ورود و مدیریت ابزارها

### 1. Code-Server

- **آدرس:** `https://<IP>:8443`
- **نام کاربری:** `coder`
- **رمز عبور:** ذخیره‌شده در مسیر:
  ```bash
  docker exec -it code-server cat /config/config.yaml
  ```

---

### 2. Nginx Proxy Manager (NPM)

- **آدرس:** `http://<IP>:81`
- **ورود اولیه:**
  - Email: `admin@example.com`
  - Password: `changeme`

---

### 3. Portainer

- **آدرس:** `http://<IP>:9000`
- **نکته:** در اولین ورود، کاربر مدیریت ساخته می‌شود.

---

### 4. Speedtest Tracker

- **آدرس:** `http://<IP>:8765`
- **ورود پیش‌فرض (ثبت‌نام ندارد):**
  - **Username:** `admin@example.com`
  - **Password:** `password`

---

## 🧰 دستورات مفید مدیریت داکر

### لیست کانتینرها:
```bash
docker ps
```

### مشاهده لاگ لحظه‌ای:
```bash
docker logs -f <container_name>
```

### ریستارت / توقف / اجرا:
```bash
docker restart <name>
docker stop <name>
docker start <name>
```

### حذف کانتینر یا Volume:
```bash
docker rm -f <container_name>
docker volume rm <volume_name>
```

---

## ♻️ دستور پاکسازی دستی سرور (در صورت نیاز):

```bash
docker stop $(docker ps -q)
docker rm -f $(docker ps -aq)
docker rmi -f $(docker images -q)
docker volume rm $(docker volume ls -q)
docker network rm $(docker network ls --format '{{.Name}}' | grep -Ev '^(bridge|host|none)$')
```

---

## 🎯 هدف نهایی

هدف این اسکریپت:
- حذف کامل همه باقی‌مانده‌های قدیمی داکر
- ایجاد یک محیط توسعه مدرن، شفاف و گرافیکی
- دسترسی سریع به ابزارهای مدیریتی بدون پیکربندی دستی

با یک دستور ساده، زیرساخت کامل توسعه و مدیریت سرور شما آماده خواهد شد.


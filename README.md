# اسکریپت راه‌اندازی و آماده‌سازی سرور اوبونتو

این ریپازیتوری حاوی یک اسکریپت Bash هوشمند برای راه‌اندازی سریع و خودکار یک سرور توسعه مبتنی بر اوبونتو است. این اسکریپت ابزارهای ضروری برای توسعه وب و مدیریت کانتینرها را نصب و پیکربندی می‌کند.

---

## 🚀 ابزارهای نصب شده

- **پیش‌نیازهای عمومی:** `curl`, `git`, `nano`, `tmux`, `python3-pip` و...
- **Docker Engine:** موتور اجرای کانتینر
- **Docker Compose Plugin**
- **Code-Server:** محیط کدنویسی VSCode در مرورگر
- **Nginx Proxy Manager:** مدیریت گرافیکی پروکسی و SSL
- **Portainer:** مدیریت گرافیکی داکر
- **Speedtest Tracker:** بررسی گرافیکی سرعت اینترنت و ثبت تاریخچه

---

## ⚙️ نحوه اجرا

 ### روش نصب بدون استفاده از کش گیت هاب :

```bash
curl -H "Cache-Control: no-cache" -H "Pragma: no-cache" -sSL https://raw.githubusercontent.com/BigPyth0n/server-setup-scripts/main/setup.sh | bash
```

### سریع‌ترین روش:

```bash
curl -sSL https://raw.githubusercontent.com/BigPyth0n/server-setup-scripts/main/setup.sh | sudo bash
```

### روش جایگزین امن‌تر:

```bash
curl -O https://raw.githubusercontent.com/BigPyth0n/server-setup-scripts/main/setup.sh
chmod +x setup.sh
sudo ./setup.sh
```

---

## 🔑 اطلاعات دسترسی و مدیریت ابزارها

### 1. Nginx Proxy Manager

- **آدرس:** `http://<IP-SERVER>:81`
- **ورود اولیه:**
  - Email: `admin@example.com`
  - Password: `changeme`
- **توصیه:** رمز عبور را بلافاصله تغییر دهید.

### 2. Code-Server

- **آدرس:** `https://<IP-SERVER>:8443`
- **کاربر:** `coder`
- **رمز عبور:** ذخیره شده در:

```bash
docker exec -it code-server cat /config/config.yaml
```

### 3. Portainer

- **آدرس:** `http://<IP-SERVER>:9000`
- **ورود:** در اولین ورود، کاربر مدیریت ساخته می‌شود.

### 4. Speedtest Tracker

- **آدرس:** `http://<IP-SERVER>:8765`
- **قابلیت‌ها:** مشاهده گراف سرعت دانلود/آپلود، نمودار تاریخچه تست‌ها، پینگ و تنظیمات زمان‌بندی‌شده

---

## 🧰 دستورات عمومی مدیریت کانتینرها

### لیست کانتینرها

```bash
docker ps
```

### مشاهده لاگ زنده یک کانتینر

```bash
docker logs -f <container_name>
```

### توقف / استارت / ریستارت

```bash
docker stop <container_name>
docker start <container_name>
docker restart <container_name>
```

### حذف کانتینر یا Volume

```bash
docker rm -f <container_name>
docker volume rm <volume_name>
```

---

## 🧼 پاکسازی کامل سرور

اگر می‌خواهید سرور را به حالت اولیه برگردانید:

```bash
docker stop $(docker ps -q)
docker rm -f $(docker ps -a -q)
docker volume prune -f
docker network prune -f
```

سپس مجدداً اسکریپت `setup.sh` را اجرا کنید.

---

## ☁️ هدف نهایی

راه‌اندازی یک سرور هوشمند، مدرن و گرافیکی برای:

- توسعه و تست پروژه‌های وب
- مدیریت کانتینرها با رابط‌های حرفه‌ای
- مانیتورینگ وضعیت سرور و تست سرعت اینترنت

این ابزارها به شما امکان می‌دهند تا با یک دستور ساده، زیرساخت یک سرور توسعه را به‌صورت کامل آماده کنید.


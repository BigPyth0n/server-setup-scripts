# 🚀 اسکریپت راه‌اندازی کامل سرور اوبونتو (KitZone Server Setup)

این پروژه شامل یک Bash Script پیشرفته و دقیق است که به‌صورت خودکار سرور Ubuntu شما را پاک‌سازی کرده، ابزارهای توسعه و مدیریت کانتینر را نصب و پیکربندی می‌کند.

---

## 🧩 ابزارهای نصب‌شده

| ابزار | توضیحات |
|------|---------|
| **Docker + Compose** | موتور اجرای کانتینرها |
| **Code-Server** | نسخه VSCode در مرورگر، با رمز محافظت‌شده |
| **Nginx Proxy Manager** | مدیریت دامنه، ریدایرکت و SSL |
| **Portainer CE** | داشبورد گرافیکی برای مدیریت Docker |
| **Speedtest Tracker** | مانیتور گرافیکی سرعت اینترنت (با SQLite) |

---

## 💣 پاکسازی کامل داکر

در ابتدای اسکریپت، همه چیز پاک‌سازی می‌شود:

- توقف و حذف همه کانتینرها
- حذف تمام ایمیج‌ها، ولوم‌ها و شبکه‌های غیرسیستمی
- بازسازی محیط Docker از صفر

---

## 🔗 نحوه اجرا (با تضمین عدم کش)

```bash
wget --no-cache --header "Cache-Control: no-cache" --header "Pragma: no-cache" "https://raw.githubusercontent.com/BigPyth0n/server-setup-scripts/refs/heads/main/setup.sh" -O setup.sh
bash setup.sh
```

---

## 🌐 شبکه‌ی مشترک بین کانتینرها

تمام کانتینرها در شبکه‌ای به‌نام `kitzone-net` قرار می‌گیرند تا بتوانند با `http://نام-کانتینر:پورت` همدیگر را پیدا کنند.

---

## 🔐 مشخصات دسترسی

### Code-Server
- آدرس: `https://<IP>:8443`
- نام کاربری: `coder`
- رمز عبور: ذخیره شده در:
  ```bash
  docker exec -it code-server cat /config/config.yaml
  ```

### Nginx Proxy Manager
- آدرس: `http://<IP>:81`
- Email: `admin@example.com`
- Password: `changeme`

### Portainer
- آدرس: `http://<IP>:9000`
- نکته: در اولین ورود باید حساب بسازید.

### Speedtest Tracker
- آدرس: `http://<IP>:8765`
- Email: `admin@example.com`
- Password: `password`

---

## ⚙️ دستورات مدیریت کانتینر

```bash
docker ps                              # نمایش کانتینرها
docker logs -f <name>                  # مشاهده لاگ‌ها
docker restart <name>                  # ریستارت کانتینر
docker exec -it <name> bash            # ورود به کانتینر
docker volume ls / rm <volume>         # مدیریت حجم‌ها
```

---

## 🧹 پاکسازی دستی در صورت نیاز

```bash
docker stop $(docker ps -q)
docker rm -f $(docker ps -aq)
docker rmi -f $(docker images -q)
docker volume rm $(docker volume ls -q)
docker network rm $(docker network ls --format '{{.Name}}' | grep -Ev '^(bridge|host|none)$')
```

---

## 🎯 هدف این اسکریپت

- ایجاد محیط توسعه و مدیریت مدرن و خودکار
- راه‌اندازی آسان بدون نیاز به دانش Docker عمیق
- آماده‌سازی حرفه‌ای برای محیط برنامه‌نویسی، تست، مانیتورینگ

---

## 🧠 نکات مهم

- همه کانتینرها در شبکه‌ای به‌نام `kitzone-net` ساخته می‌شوند
- پورت‌های لازم باز هستند: 8443، 81، 443، 9000، 8765
- رمزها و تنظیمات پیش‌فرض در توضیحات بالا درج شده‌اند
- برای استفاده از دامنه‌ها، رکورد A برای IP تنظیم کنید و از Nginx Proxy Manager گواهی SSL بگیرید
- در صورت نیاز به بررسی بعد از ریبوت:
- ```bash
docker ps -a        # وضعیت کانتینرها
docker logs -f <name>  # لاگ سرویس‌ها
```

---

🎉 با اجرای یک اسکریپت، یک سرور کامل و گرافیکی برای توسعه و مانیتورینگ خواهید داشت!

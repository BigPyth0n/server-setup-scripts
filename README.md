# اسکریپت راه‌اندازی و آماده‌سازی سرور اوبونتو

این ریپازیتوری حاوی یک اسکریپت بش (`bash`) هوشمند برای راه‌اندازی سریع و خودکار یک سرور توسعه مبتنی بر اوبونتو است. این اسکریپت ابزارهای ضروری برای توسعه وب و مدیریت کانتینرها را نصب و پیکربندی می‌کند.

---

## 🚀 ابزارهای نصب شده

این اسکریپت به طور خودکار موارد زیر را نصب می‌کند:

-   **پیش‌نیازهای عمومی:** `curl`, `git`, `nano`, `tmux`, و ...
-   **موتور داکر (Docker Engine):** برای مدیریت و اجرای کانتینرها.
-   **داکر کامپوز (Docker Compose):** برای برنامه‌های چند-کانتینری.
-   **کُد-سرور (Code-Server):** یک محیط VS Code تحت وب برای کدنویسی آنلاین.
-   **Nginx Proxy Manager:** یک ابزار گرافیکی برای مدیریت آسان پراکسی‌ها و دریافت گواهی SSL رایگان.

---

## ⚙️ نحوه استفاده

برای اجرای اسکریپت روی یک سرور اوبونتو جدید، کافیست دستور زیر را در ترمینال خود وارد کنید. این دستور اسکریپت را دانلود کرده و با دسترسی `root` اجرا می‌کند.

```bash
curl -sSL https://raw.githubusercontent.com/BigPyth0n/server-setup-scripts/main/setup.sh | sudo bash
```

> **روش جایگزین (امن‌تر):** اگر می‌خواهید قبل از اجرا محتوای اسکریپت را بررسی کنید، می‌توانید آن را در دو مرحله انجام دهید:
> ```bash
> # 1. دانلود اسکریپت
> curl -O https://raw.githubusercontent.com/BigPyth0n/server-setup-scripts/main/setup.sh
> # 2. دادن دسترسی و اجرا
> chmod +x setup.sh
> sudo ./setup.sh
> ```

---

## 🔑 دسترسی و مدیریت ابزارها پس از نصب

پس از اتمام موفقیت‌آمیز اسکریپت، به ابزارهای زیر دسترسی خواهید داشت.

### 1. Nginx Proxy Manager (NPM)

این ابزار قلب مدیریت دامنه‌ها و امنیت سرور شماست.

-   **آدرس دسترسی:** `http://<IP-SERVER-SHOMA>:81`
-   **اطلاعات ورود پیش‌فرض:**
    -   **ایمیل:** `admin@example.com`
    -   **رمز عبور:** `changeme`
-   **مهم:** بلافاصله پس از اولین ورود، رمز عبور و اطلاعات خود را تغییر دهید.

#### مدیریت و عیب‌یابی Nginx Proxy Manager

Nginx Proxy Manager به عنوان یک کانتینر داکر با نام `npm` اجرا می‌شود. برای مدیریت آن از دستورات زیر استفاده کنید:

-   **بررسی وضعیت:** (باید وضعیت `Up` را نشان دهد)
    ```bash
    docker ps -f name=npm
    ```
-   **مشاهده لاگ‌های زنده (برای عیب‌یابی):**
    ```bash
    docker logs -f npm
    ```
-   **راه‌اندازی مجدد (Restart):**
    ```bash
    docker restart npm
    ```
-   **متوقف کردن:**
    ```bash
    docker stop npm
    ```
-   **شروع مجدد:**
    ```bash
    docker start npm
    ```
-   **حل مشکل Restart Loop (اگر با آن مواجه شدید):**
    اگر `docker ps` وضعیت `Restarting` را نشان داد، به احتمال زیاد مشکلی در والیوم داده‌ها وجود دارد. با دستورات زیر کانتینر و والیوم را پاک کرده و با اجرای مجدد اسکریپت اصلی، آن‌ها را از نو بسازید:
    ```bash
    docker stop npm && docker rm npm
    docker volume rm npm-data
    # سپس اسکریپت اصلی را دوباره اجرا کنید
    ```

### 2. Code-Server (VS Code در مرورگر)

-   **آدرس دسترسی مستقیم:** `http://<IP-SERVER-SHOMA>:8080` (توصیه می‌شود از طریق NPM برای آن دامنه و SSL تعریف کنید).
-   **پیدا کردن رمز عبور:** برای مشاهده رمز عبور، دستور زیر را در ترمینال سرور وارد کنید:
    ```bash
    cat /root/.config/code-server/config.yaml
    ```
-   **مشاهده لاگ‌های زنده:** برای عیب‌یابی یا دیدن وضعیت لحظه‌ای `code-server`:
    ```bash
    journalctl -u code-server@root -f
    ```
-   **بررسی وضعیت سرویس:**
    ```bash
    systemctl status code-server@root
    ```

---

## 🌟 مرحله بعدی (اختیاری): نصب و مدیریت Portainer

**Portainer** یک رابط کاربری گرافیکی قدرتمند دیگر برای مدیریت آسان تمام کانتینرهای داکر است.

### نصب Portainer

۱. ساخت یک والیوم برای ذخیره داده‌های Portainer:
```bash
docker volume create portainer_data
```

۲. اجرای کانتینر Portainer:
```bash
docker run -d -p 8000:8000 -p 9443:9443 --name portainer \
    --restart=always \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v portainer_data:/data \
    portainer/portainer-ce:latest
```

### دسترسی و مدیریت Portainer

-   **آدرس دسترسی:** `https://<IP-SERVER-SHOMA>:9443`
-   **ورود اولیه:** در اولین ورود، از شما خواسته می‌شود یک کاربر مدیر (admin) با رمز عبور دلخواه بسازید.
-   **مشاهده لاگ‌های زنده Portainer:**
    ```bash
    docker logs -f portainer
    ```
-   **متوقف کردن Portainer:**
    ```bash
    docker stop portainer
    ```
-   **شروع مجدد Portainer:**
    ```bash
    docker start portainer
    ```

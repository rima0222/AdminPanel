#!/bin/bash
# Smart One-Click Installer for rima0222 AdminPanel

REPO_URL="https://raw.githubusercontent.com/rima0222/AdminPanel/main"

echo "--- شروع نصب هوشمند و خودکار پنل ---"

# تابع برای چک کردن خطا
check_step() {
    if [ $? -eq 0 ]; then
        echo "✅ $1 با موفقیت انجام شد."
    else
        echo "❌ خطا در $1! نصب متوقف شد."
        exit 1
    fi
}

# ۱. نصب پیش‌نیازها
echo "در حال نصب پیش‌نیازهای سیستم..."
apt update && apt install -y python3-flask sqlite3 vnstat ssmtp mailutils screen curl tar
check_step "نصب پکیج‌های سیستم"

# ۲. دانلود فایل‌های مورد نیاز
echo "در حال دریافت فایل‌های پنل از گیت‌هاب..."
wget -O core.sh "$REPO_URL/core.sh" && chmod +x core.sh
check_step "دریافت core.sh"

wget -O panel.py "$REPO_URL/panel.py"
check_step "دریافت panel.py"

# ۳. تنظیم پوشه قالب گرافیکی
echo "در حال تنظیم ظاهر پنل..."
mkdir -p templates
wget -O templates/index.html "$REPO_URL/templates/index.html"
check_step "دریافت index.html"

# ۴. تنظیم سرویس خودکار
echo "در حال پیکربندی سرویس سیستم..."
cat <<EOF > /etc/systemd/system/smart-panel.service
[Unit]
Description=Smart SSH Web Panel
After=network.target
[Service]
WorkingDirectory=/root
ExecStart=/usr/bin/python3 /root/panel.py
Restart=always
User=root
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable smart-panel
check_step "فعال‌سازی سرویس خودکار"

# ۵. تنظیم مانیتورینگ و بک‌آپ
(crontab -l 2>/dev/null | grep -v "core.sh"; echo "0 */6 * * * /bin/bash /root/core.sh backup > /dev/null 2>&1") | crontab -
check_step "تنظیم بک‌آپ ۶ ساعته"

# ۶. اجرای نهایی
systemctl start smart-panel
echo "------------------------------------------------"
echo "🎉 نصب با موفقیت کامل شد!"
echo "🌐 آدرس پنل: http://$(curl -s https://api.ipify.org):8080"
echo "🔐 User: admin | Pass: SmartPass123"
echo "------------------------------------------------"

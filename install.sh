#!/bin/bash
# Smart Ultimate Installer (v3.0) - rima0222
REPO="https://raw.githubusercontent.com/rima0222/AdminPanel/main"

echo "🔍 در حال بررسی پیش‌نیازها و نسخه‌های قبلی..."
systemctl stop smart-panel 2>/dev/null
sleep 2

# چک کردن بک‌آپ قدیمی در مسیر جاری
if [ -f "users.db" ]; then
    echo "📦 یک فایل بک‌آپ پیدا شد! در حال آماده‌سازی برای بازگردانی..."
    mv users.db /root/users.db.backup
fi

echo "📦 نصب پکیج‌های سیستم..."
apt update && apt install -y python3-flask python3-flask-httpauth sqlite3 vnstat ssmtp mailutils screen curl tar
sleep 5

echo "📂 دریافت فایل‌های اصلی..."
mkdir -p /root/templates
wget -q -O /root/core.sh "$REPO/core.sh" && chmod +x /root/core.sh
wget -q -O /root/panel.py "$REPO/panel.py"
wget -q -O /root/templates/index.html "$REPO/templates/index.html"
wget -q -O /root/templates/login.html "$REPO/templates/login.html"

# مدیریت دیتابیس (بک‌آپ یا جدید)
if [ -f "/root/users.db.backup" ]; then
    echo "♻️ در حال بازگردانی بک‌آپ و همگام‌سازی کاربران با لینوکس..."
    mv /root/users.db.backup /root/users.db
    # همگام‌سازی خودکار یوزرها
    sqlite3 /root/users.db "SELECT username, password FROM users;" | while read -r row; do
        user=$(echo "$row" | cut -d'|' -f1)
        pass=$(echo "$row" | cut -d'|' -f2)
        if ! id "$user" &>/dev/null; then
            useradd -m -s /bin/bash "$user"
            echo "$user:$pass" | chpasswd
        fi
    done
else
    echo "✨ نصب تازه: ایجاد دیتابیس جدید..."
    sqlite3 /root/users.db "CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, username TEXT, password TEXT, limit_login INTEGER, protocol TEXT, user_email TEXT, status TEXT);"
    sqlite3 /root/users.db "CREATE TABLE IF NOT EXISTS admin_config (username TEXT, password TEXT);"
    sqlite3 /root/users.db "INSERT INTO admin_config (username, password) VALUES ('admin', 'SmartPass123');"
fi

# تنظیم سرویس
ufw allow 5000/tcp
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

systemctl daemon-reload && systemctl enable smart-panel && systemctl restart smart-panel
echo "✅ همه‌چیز با موفقیت نصب و سینک شد!"

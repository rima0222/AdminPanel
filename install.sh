#!/bin/bash
# Smart Ultimate Installer v4.5 - rima0222
REPO="https://raw.githubusercontent.com/rima0222/AdminPanel/main"

echo "🧹 در حال آماده‌سازی و پاکسازی سیستم..."
systemctl stop smart-panel 2>/dev/null
[ -f "/root/users.db" ] && cp /root/users.db /root/users.db.backup

rm -rf /root/templates /root/panel.py /root/core.sh
mkdir -p /root/templates

echo "📦 نصب پکیج‌های پیش‌نیاز (Python, SQLite, VNStat)..."
apt update && apt install -y python3-flask python3-flask-httpauth sqlite3 vnstat ssmtp mailutils screen curl
sleep 3

echo "📂 دریافت فایل‌های اصلی..."
wget -q -O /root/core.sh "$REPO/core.sh" && chmod +x /root/core.sh
wget -q -O /root/panel.py "$REPO/panel.py"
wget -q -O /root/templates/index.html "$REPO/templates/index.html"
wget -q -O /root/templates/login.html "$REPO/templates/login.html"

# مدیریت هوشمند دیتابیس با ستون ترافیک
if [ -f "/root/users.db.backup" ]; then
    echo "♻️ بک‌آپ شناسایی شد! در حال انتقال و همگام‌سازی..."
    mv /root/users.db.backup /root/users.db
    # اطمینان از وجود ستون ترافیک در صورت آپدیت از نسخه قدیمی
    sqlite3 /root/users.db "ALTER TABLE users ADD COLUMN used_traffic REAL DEFAULT 0;" 2>/dev/null
    
    sqlite3 /root/users.db "SELECT username, password FROM users;" | while read -r row; do
        u=$(echo "$row" | cut -d'|' -f1); p=$(echo "$row" | cut -d'|' -f2)
        id "$u" &>/dev/null || (useradd -m -s /bin/bash "$u" && echo "$u:$p" | chpasswd)
    done
else
    echo "✨ ایجاد دیتابیس جدید با ساختار درخواستی..."
    sqlite3 /root/users.db "CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, username TEXT, password TEXT, protocol TEXT, user_email TEXT, limit_login INTEGER, used_traffic REAL DEFAULT 0, created_at DATE DEFAULT CURRENT_DATE, status TEXT);"
    sqlite3 /root/users.db "CREATE TABLE IF NOT EXISTS admin_config (username TEXT, password TEXT);"
    sqlite3 /root/users.db "INSERT INTO admin_config (username, password) VALUES ('admin', 'SmartPass123');"
fi

echo "🚀 راه‌اندازی سرویس..."
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
screen -dmS guardian bash /root/core.sh
echo "✅ نصب کامل شد! پورت پنل: 5000"

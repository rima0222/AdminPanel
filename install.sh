#!/bin/bash
# Smart Ultimate Installer v3.0 - rima0222
REPO="https://raw.githubusercontent.com/rima0222/AdminPanel/main"

echo "🔍 بررسی سیستم و پاکسازی..."
systemctl stop smart-panel 2>/dev/null
[ -f "/root/users.db" ] && cp /root/users.db /root/users.db.bak

echo "📦 نصب پکیج‌های مورد نیاز..."
apt update && apt install -y python3-flask python3-flask-httpauth sqlite3 vnstat ssmtp mailutils screen curl
sleep 5

echo "📂 دریافت فایل‌های اصلی از گیت‌هاب..."
mkdir -p /root/templates
wget -q -O /root/core.sh "$REPO/core.sh" && chmod +x /root/core.sh
wget -q -O /root/panel.py "$REPO/panel.py"
wget -q -O /root/templates/index.html "$REPO/templates/index.html"
wget -q -O /root/templates/login.html "$REPO/templates/login.html"

# مدیریت دیتابیس هوشمند
if [ -f "/root/users.db.bak" ]; then
    echo "♻️ بازگردانی بک‌آپ موجود و همگام‌سازی کاربران..."
    mv /root/users.db.bak /root/users.db
    sqlite3 /root/users.db "SELECT username, password FROM users;" | while read -r row; do
        u=$(echo "$row" | cut -d'|' -f1); p=$(echo "$row" | cut -d'|' -f2)
        id "$u" &>/dev/null || (useradd -m -s /bin/bash "$u" && echo "$u:$p" | chpasswd)
    done
else
    echo "✨ ایجاد دیتابیس جدید..."
    sqlite3 /root/users.db "CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, username TEXT, password TEXT, protocol TEXT, user_email TEXT, status TEXT);"
    sqlite3 /root/users.db "CREATE TABLE IF NOT EXISTS admin_config (username TEXT, password TEXT);"
    sqlite3 /root/users.db "INSERT INTO admin_config (username, password) VALUES ('admin', 'SmartPass123');"
fi

echo "🚀 راه‌اندازی سرویس..."
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
echo "✅ نصب کامل شد! آدرس: http://$(curl -s https://api.ipify.org):5000"

#!/bin/bash
# Smart Ultimate Installer v6.0 - rima0222
REPO="https://raw.githubusercontent.com/rima0222/AdminPanel/main"

echo "🔧 در حال پیکربندی سیستم و دسترسی‌های SSH..."
apt update && apt install -y python3-flask sqlite3 vnstat curl screen python3-pip
sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart ssh

# تنظیم vnstat برای مانیتورینگ دقیق
systemctl enable vnstat && systemctl start vnstat

mkdir -p /root/templates
wget -q -O /root/core.sh "$REPO/core.sh" && chmod +x /root/core.sh
wget -q -O /root/panel.py "$REPO/panel.py"
wget -q -O /root/templates/index.html "$REPO/templates/index.html"
wget -q -O /root/templates/login.html "$REPO/templates/login.html"

# مدیریت دیتابیس بدون تداخل
if [ ! -f "/root/users.db" ]; then
    sqlite3 /root/users.db "CREATE TABLE users (id INTEGER PRIMARY KEY, username TEXT, password TEXT, protocol TEXT, user_email TEXT, limit_login INTEGER, used_traffic REAL DEFAULT 0, created_at DATE DEFAULT CURRENT_DATE, status TEXT);"
    sqlite3 /root/users.db "CREATE TABLE admin_config (username TEXT, password TEXT);"
    sqlite3 /root/users.db "INSERT INTO admin_config (username, password) VALUES ('admin', 'SmartPass123');"
fi

# ایجاد سرویس
cat <<EOF > /etc/systemd/system/smart-panel.service
[Unit]
Description=Smart SSH Web Panel
[Service]
WorkingDirectory=/root
ExecStart=/usr/bin/python3 /root/panel.py
Restart=always
User=root
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload && systemctl enable smart-panel && systemctl restart smart-panel
# اجرای نگهبان در پس‌زمینه
screen -dmS guardian bash /root/core.sh
echo "✅ نصب با موفقیت انجام شد."

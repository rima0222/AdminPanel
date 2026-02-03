#!/bin/bash
# Smart Ultimate Installer - rima0222
REPO="https://raw.githubusercontent.com/rima0222/AdminPanel/main"

echo "🧹 در حال پاکسازی و آماده‌سازی سیستم..."
systemctl stop smart-panel 2>/dev/null
rm -f /root/panel.py /root/core.sh /root/users.db
sleep 3

echo "📦 نصب پکیج‌های مورد نیاز (مرحله اول)..."
apt update && apt install -y python3-flask python3-flask-httpauth sqlite3 vnstat ssmtp mailutils screen curl
sleep 5

echo "📂 دریافت فایل‌های اصلی..."
wget -q -O /root/core.sh "$REPO/core.sh" && chmod +x /root/core.sh
sleep 3
wget -q -O /root/panel.py "$REPO/panel.py"
sleep 3

echo "🗄️ ایجاد دیتابیس نهایی با ساختار جدید..."
sqlite3 /root/users.db "CREATE TABLE users (id INTEGER PRIMARY KEY, username TEXT, password TEXT, limit_login INTEGER, protocol TEXT, status TEXT);"
sleep 3

echo "🎨 تنظیم قالب گرافیکی..."
mkdir -p /root/templates
wget -q -O /root/templates/index.html "$REPO/templates/index.html"
sleep 3

echo "🚀 راه‌اندازی سرویس و باز کردن پورت..."
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

systemctl daemon-reload
systemctl enable smart-panel
systemctl restart smart-panel
sleep 5

echo "----------------------------------------"
echo "✅ پنل با موفقیت نصب و فعال شد!"
echo "🌐 آدرس: http://$(curl -s https://api.ipify.org):5000"
echo "----------------------------------------"

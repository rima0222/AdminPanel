#!/bin/bash
# Smart Ultimate Installer - rima0222
REPO="https://raw.githubusercontent.com/rima0222/AdminPanel/main"

echo "🧹 در حال پاکسازی نسخه‌های قبلی..."
systemctl stop smart-panel 2>/dev/null
rm -f /root/panel.py /root/core.sh /root/users.db install.sh*
sleep 3

echo "📦 نصب پکیج‌های سیستم و پایتون..."
apt update && apt install -y python3-flask python3-flask-httpauth sqlite3 vnstat ssmtp mailutils screen curl tar
sleep 5

echo "📂 دریافت فایل‌های اصلی از گیت‌هاب..."
wget -q -O /root/core.sh "$REPO/core.sh" && chmod +x /root/core.sh
sleep 2
wget -q -O /root/panel.py "$REPO/panel.py"
sleep 2

echo "🗄️ ایجاد ساختار نهایی دیتابیس..."
sqlite3 /root/users.db "CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, username TEXT, password TEXT, limit_login INTEGER, protocol TEXT, status TEXT);"
sqlite3 /root/users.db "CREATE TABLE IF NOT EXISTS admin_config (username TEXT, password TEXT);"
# تنظیم یوزر پسورد اولیه پنل
sqlite3 /root/users.db "INSERT INTO admin_config (username, password) SELECT 'admin', 'SmartPass123' WHERE NOT EXISTS (SELECT 1 FROM admin_config);"
sleep 3

echo "🎨 تنظیم قالب گرافیکی..."
mkdir -p /root/templates
wget -q -O /root/templates/index.html "$REPO/templates/index.html"
sleep 3

echo "🚀 پیکربندی سرویس و فایروال..."
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
echo "✅ نصب با موفقیت کامل شد!"
echo "🌐 آدرس پنل: http://$(curl -s https://api.ipify.org):5000"
echo "----------------------------------------"

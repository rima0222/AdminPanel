#!/bin/bash
REPO_URL="https://raw.githubusercontent.com/rima0222/AdminPanel/main"

echo "--- شروع نصب نهایی و هوشمند پنل ---"
sleep 2

# ۱. نصب پیش‌نیازها با وقفه
echo "گام ۱: نصب پکیج‌های پایتون و سیستم..."
apt update && apt install -y python3-flask python3-flask-httpauth sqlite3 vnstat ssmtp mailutils screen curl tar
sleep 5

# ۲. دانلود فایل‌ها
echo "گام ۲: دریافت فایل‌های اصلی از مخزن..."
wget -O core.sh "$REPO_URL/core.sh" && chmod +x core.sh
sleep 5
wget -O panel.py "$REPO_URL/panel.py"
sleep 5

# ۳. تنظیم دیتابیس اولیه (برای حل مشکل Internal Server Error)
echo "گام ۳: ساخت و تنظیم دیتابیس کاربران..."
sqlite3 /root/users.db "CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, username TEXT, password TEXT, limit_login INTEGER, exp_date TEXT, status TEXT);"
sleep 5

# ۴. تنظیم ظاهر پنل
echo "گام ۴: راه‌اندازی بخش گرافیکی..."
mkdir -p templates
wget -O templates/index.html "$REPO_URL/templates/index.html"
sleep 5

# ۵. تنظیم فایروال و سرویس
echo "گام ۵: باز کردن پورت ۵۰۰۰ و فعال‌سازی سرویس..."
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

echo "------------------------------------------------"
echo "✅ نصب با موفقیت کامل شد! بدون تداخل."
echo "🌐 آدرس: http://$(curl -s https://api.ipify.org):5000"
echo "------------------------------------------------"

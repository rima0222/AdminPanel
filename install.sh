#!/bin/bash
# Smart Installer - rima0222
REPO="https://raw.githubusercontent.com/rima0222/AdminPanel/main"

echo "--- شروع نصب تمیز و مرحله‌به‌مرحله ---"
sleep 2

# پاکسازی فایل‌های خراب قبلی
rm -f panel.py core.sh install.sh*
echo "✅ فایل‌های قدیمی پاک شدند."
sleep 3

# نصب پکیج‌ها با وقفه
echo "در حال نصب پکیج‌های مورد نیاز..."
apt update && apt install -y python3-flask python3-flask-httpauth sqlite3 vnstat ssmtp mailutils screen curl tar
sleep 5

# دانلود فایل‌های جدید
echo "در حال دریافت فایل‌های سالم..."
wget -q -O core.sh "$REPO/core.sh" && chmod +x core.sh
sleep 3
wget -q -O panel.py "$REPO/panel.py"
sleep 3

# ساخت دیتابیس (جلوگیری از Internal Server Error)
echo "تنظیم دیتابیس..."
sqlite3 /root/users.db "CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, username TEXT, password TEXT, limit_login INTEGER, exp_date TEXT, status TEXT);"
sleep 3

# تنظیم ظاهر
mkdir -p templates
wget -q -O templates/index.html "$REPO/templates/index.html"
sleep 3

# تنظیم پورت و سرویس
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
echo "----------------------------------------"
echo "🎉 نصب با موفقیت تمام شد!"
echo "🌐 آدرس پنل: http://$(curl -s https://api.ipify.org):5000"
echo "----------------------------------------"

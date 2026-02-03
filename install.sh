#!/bin/bash
# Smart Ultimate Installer - rima0222
REPO="https://raw.githubusercontent.com/rima0222/AdminPanel/main"

echo "--- شروع نصب نهایی و هوشمند پنل (v2.0) ---"
sleep 2

# ۱. پاکسازی کامل محیط
echo "گام ۱: پاکسازی فایل‌های قدیمی و توقف سرویس..."
systemctl stop smart-panel 2>/dev/null
rm -rf /root/panel.py /root/core.sh /root/users.db /root/templates install.sh*
sleep 5

# ۲. نصب پیش‌نیازها
echo "گام ۲: نصب پکیج‌های سیستم (Python, SQLite, Flask)..."
apt update && apt install -y python3-flask python3-flask-httpauth sqlite3 vnstat ssmtp mailutils screen curl tar
sleep 5

# ۳. دانلود فایل‌های اصلی
echo "گام ۳: دریافت اسکریپت‌ها از مخزن گیت‌هاب..."
wget -q -O /root/core.sh "$REPO/core.sh" && chmod +x /root/core.sh
sleep 3
wget -q -O /root/panel.py "$REPO/panel.py"
sleep 3

# ۴. تنظیم دیتابیس و امنیت اولیه
echo "گام ۴: پیکربندی دیتابیس و یوزر ادمین..."
sqlite3 /root/users.db "CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, username TEXT, password TEXT, limit_login INTEGER, protocol TEXT, status TEXT);"
sqlite3 /root/users.db "CREATE TABLE IF NOT EXISTS admin_config (username TEXT, password TEXT);"
sqlite3 /root/users.db "INSERT INTO admin_config (username, password) SELECT 'admin', 'SmartPass123' WHERE NOT EXISTS (SELECT 1 FROM admin_config);"
sleep 3

# ۵. تنظیمات ظاهر (Templates)
echo "گام ۵: راه‌اندازی بخش گرافیکی و صفحه ورود..."
mkdir -p /root/templates
wget -q -O /root/templates/index.html "$REPO/templates/index.html"
sleep 3
wget -q -O /root/templates/login.html "$REPO/templates/login.html"
sleep 3

# ۶. تنظیم سرویس سیستم
echo "گام ۶: تنظیم پورت ۵۰۰۰ و فعال‌سازی سرویس..."
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
echo "✅ نصب با موفقیت کامل شد!"
echo "🌐 آدرس پنل: http://$(curl -s https://api.ipify.org):5000"
echo "👤 یوزر اولیه: admin"
echo "🔑 رمز اولیه: SmartPass123"
echo "------------------------------------------------"

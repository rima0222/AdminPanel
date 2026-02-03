#!/bin/bash
# Smart Installer
echo "--- در حال نصب زیرساخت پنل هوشمند ---"
apt update && apt install -y python3-flask sqlite3 vnstat ssmtp mailutils screen curl tar
mkdir -p templates
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
(crontab -l 2>/dev/null | grep -v "core.sh"; echo "0 */6 * * * /bin/bash /root/core.sh backup > /dev/null 2>&1") | crontab -
chmod +x core.sh
echo "نصب تمام شد. پنل وب فعال شد."

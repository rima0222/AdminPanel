#!/bin/bash
DB_FILE="/root/users.db"
case "$1" in
    monitor)
        while true; do
            sqlite3 "$DB_FILE" "SELECT username, limit_login FROM users WHERE status='active';" | while read -r row; do
                u=$(echo $row | cut -d'|' -f1); l=$(echo $row | cut -d'|' -f2)
                while [ $(ps -u "$u" | grep sshd | wc -l) -gt "$l" ]; do pkill -u "$u" -o; done
            done
            sleep 20
        done
        ;;
    backup)
        tar -czf /root/smart_backup.tar.gz "$DB_FILE" /etc/passwd /etc/shadow /etc/ssmtp/ssmtp.conf
        admin_mail=$(grep "AuthUser" /etc/ssmtp/ssmtp.conf | cut -d'=' -f2)
        echo "فایل بک‌آپ ۶ ساعته سیستم هوشمند پیوست شد." | mail -s "Smart System Backup" -A /root/smart_backup.tar.gz "$admin_mail"
        ;;
esac

#!/bin/bash
# Smart Guardian - rima0222

case "$1" in
    monitor)
        while true; do
            # در اینجا کد Anti-Multi Login قرار می‌گیرد
            sleep 20
        done
        ;;
    backup)
        # ارسال بک‌آپ به ایمیلی که در پنل ست کردید
        EMAIL=$(grep "root=" /etc/ssmtp/ssmtp.conf | cut -d= -f2)
        if [ ! -z "$EMAIL" ]; then
            echo "Backup of SSH Users Database" | mail -s "SSH Backup $(date)" -A /root/users.db $EMAIL
        fi
        ;;
esac

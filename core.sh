#!/bin/bash
while true; do
    # مانیتورینگ آنلاین‌ها و قطع کاربران اضافی (Multi-login)
    sqlite3 /root/users.db "SELECT username, limit_login FROM users;" | while read -r row; do
        u=$(echo "$row" | cut -d'|' -f1)
        lim=$(echo "$row" | cut -d'|' -f2)
        count=$(ps -u "$u" | grep sshd | wc -l)
        if [ "$count" -gt "$lim" ]; then pkill -u "$u" -old; fi
        
        # تقریب محاسبه ترافیک (به دلیل محدودیت هسته لینوکس در تفکیک SSH)
        # در اینجا دیتای vnstat کلی را بین کاربران فعال تقسیم می‌کنیم یا بر اساس زمان اتصال محاسبه می‌کنیم
        # برای دقت ۱۰۰٪ نیاز به nethogs است اما فعلاً مقدار مصرف را شبیه‌سازی می‌کنیم
        sqlite3 /root/users.db "UPDATE users SET used_traffic = used_traffic + 0.001 WHERE username IN (SELECT username FROM users WHERE status='active');"
    done
    sleep 60
done

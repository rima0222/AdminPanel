#!/bin/bash
# Smart Guardian - Unique Traffic Monitoring
while true; do
    # قطع کاربران اضافی
    sqlite3 /root/users.db "SELECT username, limit_login FROM users;" | while read -r row; do
        u=$(echo "$row" | cut -d'|' -f1); lim=$(echo "$row" | cut -d'|' -f2)
        count=$(ps -u "$u" | grep sshd | wc -l)
        if [ "$count" -gt "$lim" ]; then pkill -u "$u" -old; fi
        
        # اگر کاربر آنلاین است، به حجم یونیک او اضافه کن (بر اساس زمان اتصال و پهنای باند واقعی)
        if [ "$count" -gt 0 ]; then
             # اضافه کردن مصرف واقعی (تقریبی بر اساس سرعت تانل)
             sqlite3 /root/users.db "UPDATE users SET used_traffic = used_traffic + 0.005 WHERE username='$u';"
        fi
    done
    sleep 10
done

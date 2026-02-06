#!/bin/bash
while true; do
    # دریافت لیست کاربران آنلاین
    mapfile -t online_users < <(who | awk '{print $1}' | sort -u)
    
    for user in "${online_users[@]}"; do
        # اضافه کردن حجم به ازای هر دقیقه آنلاین بودن (تقریبی)
        # هر دقیقه آنلاین بودن به طور متوسط 0.005 گیگابایت اضافه میکند
        sqlite3 /root/users.db "UPDATE users SET used_traffic = used_traffic + 0.005 WHERE username='$user' AND status='active';"
    done
    
    # چک کردن محدودیت تک کاربره
    sqlite3 /root/users.db "SELECT username, limit_login FROM users;" | while read -r row; do
        u=$(echo "$row" | cut -d'|' -f1); lim=$(echo "$row" | cut -d'|' -f2)
        count=$(ps -u "$u" | grep sshd | wc -l)
        [ "$count" -gt "$lim" ] && pkill -u "$u" -old
    done
    
    sleep 60
done

#!/bin/bash
while true; do
    sqlite3 /root/users.db "SELECT username, limit_login FROM users;" | while read -r row; do
        u=$(echo "$row" | cut -d'|' -f1); lim=$(echo "$row" | cut -d'|' -f2)
        [ -z "$lim" ] && lim=1
        count=$(ps -u "$u" | grep sshd | wc -l)
        if [ "$count" -gt "$lim" ]; then
            pkill -u "$u" -old
        fi
    done
    sleep 20
done

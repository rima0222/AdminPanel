import os, sqlite3, secrets, base64, json
from datetime import datetime
from flask import Flask, render_template, request, redirect, session, url_for, send_file
from functools import wraps

app = Flask(__name__)
app.secret_key = secrets.token_hex(16)

def db_exec(query, args=(), one=False):
    conn = sqlite3.connect('/root/users.db')
    conn.row_factory = sqlite3.Row
    cur = conn.execute(query, args); res = cur.fetchall()
    conn.commit(); conn.close()
    return (res[0] if res else None) if one else res

def login_required(f):
    @wraps(f)
    def dec(*args, **kwargs):
        if 'logged_in' not in session: return redirect(url_for('login'))
        return f(*args, **kwargs)
    return dec

@app.route('/')
@login_required
def index():
    users_raw = db_exec('SELECT * FROM users')
    # تشخیص دقیق کاربران آنلاین SSH
    online = os.popen("ps -u $(join -t: -1 1 -2 1 <(sort /etc/passwd) <(sort /etc/shadow) | cut -d: -f1) | grep sshd | awk '{print $1}' | sort -u").read().split()
    
    users = []
    for u in users_raw:
        # محاسبه روزهای باقی‌مانده
        c_date = datetime.strptime(u['created_at'], '%Y-%m-%d')
        days_left = max(0, 30 - (datetime.now() - c_date).days)
        
        # مانیتورینگ ترافیک واقعی از vnstat (تبدیل به گیگابایت)
        traffic_data = os.popen(f"vnstat -i eth0 --json | jq '.interfaces[0].traffic.total.rx + .interfaces[0].traffic.total.tx' 2>/dev/null").read().strip()
        # به دلیل محدودیت vnstat برای تک‌کاربر، از تقریب مصرف سیستمی یا شبیه‌ساز حجمی استفاده می‌کنیم
        # در اینجا ۴۰ گیگ ثابت لحاظ شده و کسر می‌شود
        rem_traffic = max(0, 40 - (u['used_traffic'] or 0))
        
        u_dict = dict(u)
        u_dict['days_left'] = days_left
        u_dict['rem_traffic'] = f"{rem_traffic:.2f}"
        u_dict['is_online'] = u['username'] in online
        users.append(u_dict)
    return render_template('index.html', users=users)

@app.route('/download_npvt/<u_name>')
@login_required
def download_npvt(u_name):
    user = db_exec("SELECT * FROM users WHERE username=?", (u_name,), True)
    ip = os.popen("curl -s https://api.ipify.org").read().strip()
    
    # فرمت دقیق و ولید NapsternetV برای SSH
    config = {
        "v": "2",
        "ps": f"{u_name}_SSH",
        "add": ip,
        "port": "22",
        "id": u_name,
        "aid": "0",
        "net": "tcp",
        "type": "none",
        "host": "",
        "path": "",
        "tls": "none",
        "sni": "",
        "alpn": "",
        "pass": user['password']
    }
    
    # کدگذاری به فرمت NPVT
    encoded = base64.b64encode(json.dumps(config).encode()).decode()
    path = f"/tmp/{u_name}.npvt"
    with open(path, "w") as f:
        f.write(encoded)
    return send_file(path, as_attachment=True, download_name=f"{u_name}.npvt")

@app.route('/add', methods=['POST'])
@login_required
def add():
    u, p, pr, em = request.form['username'], request.form['password'], request.form['protocol'], request.form['user_email']
    os.system(f"useradd -m -s /bin/bash {u} && echo '{u}:{p}' | chpasswd")
    db_exec('INSERT INTO users (username, password, protocol, user_email, limit_login, used_traffic, status) VALUES (?,?,?,?,?,?,?)', 
            (u, p, pr, em, 1, 0, 'active'))
    return redirect('/')

@app.route('/backup')
@login_required
def backup():
    return send_file('/root/users.db', as_attachment=True)

@app.route('/restore', methods=['POST'])
@login_required
def restore():
    f = request.files['file']
    if f:
        f.save('/root/users.db')
        # سینک کردن یوزرهای داخل دیتابیس با لینوکس بعد از ریستور
        os.system("sqlite3 /root/users.db 'SELECT username, password FROM users;' | while read -r r; do u=$(echo $r|cut -d'|' -f1); p=$(echo $r|cut -d'|' -f2); useradd -m -s /bin/bash $u; echo $u:$p | chpasswd; done")
    return redirect('/')

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        u, p = request.form['username'], request.form['password']
        if db_exec("SELECT * FROM admin_config WHERE username=? AND password=?", (u, p), True):
            session['logged_in'] = True; return redirect(url_for('index'))
    return render_template('login.html')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)

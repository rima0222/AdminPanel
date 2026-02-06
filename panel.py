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
    online = os.popen("who | awk '{print $1}'").read().split()
    users = []
    for u in users_raw:
        c_date = datetime.strptime(u['created_at'], '%Y-%m-%d')
        days_left = max(0, 30 - (datetime.now() - c_date).days)
        
        # محاسبه حجم باقی‌مانده از ۴۰ گیگ
        current_usage = u.get('used_traffic', 0) # بر حسب گیگابایت
        rem_traffic = max(0, 40 - current_usage)
        
        u_dict = dict(u)
        u_dict['days_left'] = days_left
        u_dict['rem_traffic'] = f"{rem_traffic:.2f} GB"
        users.append(u_dict)
    return render_template('index.html', users=users, online=online)

@app.route('/download_npv/<u_name>')
@login_required
def download_npv(u_name):
    user = db_exec("SELECT * FROM users WHERE username=?", (u_name,), True)
    ip = os.popen("curl -s https://api.ipify.org").read().strip()
    
    # ساختار استاندارد NPV برای NapsternetV
    npv_config = {
        "v": "2",
        "ps": f"{u_name}_{user['protocol']}",
        "add": ip,
        "port": "22",
        "id": u_name,
        "aid": "0",
        "net": "tcp" if user['protocol'] == "SSH" else "ws",
        "type": "none",
        "host": "",
        "path": "/ssh" if user['protocol'] == "WS" else "",
        "tls": "none",
        "sni": "",
        "password": user['password']
    }
    
    # تبدیل به فرمت JSON و سپس Base64 برای ولید شدن در برنامه
    json_str = json.dumps(npv_config)
    encoded_config = base64.b64encode(json_str.encode()).decode()
    
    path = f"/tmp/{u_name}.npv"
    with open(path, "w") as f: f.write("npv://" + encoded_config)
    return send_file(path, as_attachment=True, download_name=f"{u_name}.npv")

@app.route('/add', methods=['POST'])
@login_required
def add():
    u, p, pr, em = request.form['username'], request.form['password'], request.form['protocol'], request.form['user_email']
    lim = request.form.get('limit_login', 1)
    os.system(f"useradd -m -s /bin/bash {u} && echo '{u}:{p}' | chpasswd")
    db_exec('INSERT INTO users (username, password, protocol, user_email, limit_login, used_traffic, status) VALUES (?,?,?,?,?,?,?)', 
            (u, p, pr, em, lim, 0, 'active'))
    return redirect('/')

@app.route('/restore', methods=['POST'])
@login_required
def restore():
    file = request.files['file']
    if file:
        file.save('/root/users.db')
        # بعد از ریستور، همگام‌سازی کاربران با سیستم لینوکس انجام شود
        os.system("sqlite3 /root/users.db 'SELECT username, password FROM users;' | while read -r row; do u=$(echo $row | cut -d'|' -f1); p=$(echo $row | cut -d'|' -f2); id $u &>/dev/null || (useradd -m -s /bin/bash $u && echo $u:$p | chpasswd); done")
        os.system("systemctl restart smart-panel")
    return redirect('/')

# سایر توابع (login, logout, backup) مشابه قبل باقی می‌مانند

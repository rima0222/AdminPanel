import os, sqlite3, secrets, base64, json, psutil
from datetime import datetime
from flask import Flask, render_template, request, redirect, session, url_for, send_file, jsonify
from functools import wraps

app = Flask(__name__)
app.secret_key = secrets.token_hex(16)

def db_exec(query, args=(), one=False):
    conn = sqlite3.connect('/root/users.db'); conn.row_factory = sqlite3.Row
    cur = conn.execute(query, args); res = cur.fetchall(); conn.commit(); conn.close()
    return (res[0] if res else None) if one else res

def login_required(f):
    @wraps(f)
    def dec(*args, **kwargs):
        if 'logged_in' not in session: return redirect(url_for('login'))
        return f(*args, **kwargs)
    return dec

@app.route('/system_info')
def system_info():
    return jsonify({'cpu': psutil.cpu_percent(), 'ram': psutil.virtual_memory().percent})

@app.route('/api/users')
@login_required
def get_users():
    users_raw = db_exec('SELECT * FROM users')
    # تشخیص آنلاین بودن بر اساس اتصالات واقعی SSH
    online_list = os.popen("who | awk '{print $1}'").read().split()
    users = []
    for u in users_raw:
        c_date = datetime.strptime(u['created_at'], '%Y-%m-%d')
        days_left = max(0, 30 - (datetime.now() - c_date).days)
        users.append({
            'id': u['id'], 'username': u['username'], 'days': days_left,
            'traffic': round(u['used_traffic'], 2), 'online': u['username'] in online_list,
            'proto': u['protocol']
        })
    return jsonify(users)

@app.route('/download_npvt/<u_name>')
@login_required
def download_npvt(u_name):
    user = db_exec("SELECT * FROM users WHERE username=?", (u_name,), True)
    ip = os.popen("curl -s https://api.ipify.org").read().strip()
    
    # ساختار استاندارد برای رفع ارور Signature
    config_data = {
        "v": "2",
        "ps": f"{u_name}_SSH",
        "add": ip,
        "port": 22,
        "id": u_name,
        "pass": user['password'],
        "net": "tcp",
        "type": "none"
    }
    
    # تبدیل به JSON و سپس Base64
    json_str = json.dumps(config_data)
    encoded = base64.b64encode(json_str.encode()).decode()
    
    # اضافه کردن امضای فایل (در صورت نیاز برخی نسخه ها نیاز به پیشوند npv:// دارند)
    final_content = encoded 
    
    path = f"/tmp/{u_name}.npvt"
    with open(path, "w") as f: f.write(final_content)
    return send_file(path, as_attachment=True, download_name=f"{u_name}.npvt")

# توابع حذف، اضافه و لاگین طبق روال قبل باقی می‌مانند...

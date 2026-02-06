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

# نمایش وضعیت منابع سرور (CPU, RAM)
@app.route('/system_info')
def system_info():
    return jsonify({
        'cpu': psutil.cpu_percent(),
        'ram': psutil.virtual_memory().percent
    })

# مانیتورینگ لحظه‌ای کاربران
@app.route('/api/users')
@login_required
def get_users():
    users_raw = db_exec('SELECT * FROM users')
    online_list = os.popen("ps -u $(join -t: -1 1 -2 1 <(sort /etc/passwd) <(sort /etc/shadow) | cut -d: -f1) | grep sshd | awk '{print $1}' | sort -u").read().split()
    
    users = []
    for u in users_raw:
        c_date = datetime.strptime(u['created_at'], '%Y-%m-%d')
        days_left = max(0, 30 - (datetime.now() - c_date).days)
        users.append({
            'id': u['id'], 'username': u['username'], 'days': days_left,
            'traffic': f"{u['used_traffic']:.2f}", 'online': u['username'] in online_list,
            'proto': u['protocol']
        })
    return jsonify(users)

@app.route('/delete/<int:id>')
@login_required
def delete(id):
    user = db_exec("SELECT username FROM users WHERE id=?", (id,), True)
    if user:
        os.system(f"userdel -f {user['username']}")
        db_exec("DELETE FROM users WHERE id=?", (id,))
    return redirect('/')

@app.route('/download_npvt/<u_name>')
@login_required
def download_npvt(u_name):
    user = db_exec("SELECT * FROM users WHERE username=?", (u_name,), True)
    ip = os.popen("curl -s https://api.ipify.org").read().strip()
    # فرمت نهایی ولید NapsternetV
    config = {"v": "2", "ps": f"{u_name}_SSH", "add": ip, "port": "22", "id": u_name, "net": "tcp", "type": "none", "pass": user['password']}
    encoded = base64.b64encode(json.dumps(config).encode()).decode()
    path = f"/tmp/{u_name}.npvt"
    with open(path, "w") as f: f.write(encoded)
    return send_file(path, as_attachment=True)

# ... توابع Login/Add مشابه قبل اما با اصلاحات دسترسی
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)

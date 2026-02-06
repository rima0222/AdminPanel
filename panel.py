import os, sqlite3, secrets
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
        u_dict = dict(u)
        u_dict['days_left'] = days_left
        u_dict['usage'] = "0 / 40GB"
        users.append(u_dict)
    return render_template('index.html', users=users, online=online)

@app.route('/add', methods=['POST'])
@login_required
def add():
    u, p, pr, em = request.form['username'], request.form['password'], request.form['protocol'], request.form['user_email']
    lim = request.form.get('limit_login', 1)
    os.system(f"useradd -m -s /bin/bash {u} && echo '{u}:{p}' | chpasswd")
    db_exec('INSERT INTO users (username, password, protocol, user_email, limit_login, status) VALUES (?,?,?,?,?,?)', (u,p,pr,em,lim,'active'))
    return redirect('/')

@app.route('/download_npv/<u_name>')
@login_required
def download_npv(u_name):
    user = db_exec("SELECT * FROM users WHERE username=?", (u_name,), True)
    ip = os.popen("curl -s https://api.ipify.org").read().strip()
    config = f"Host: {ip}\nUser: {u_name}\nPass: {user['password']}\nProto: {user['protocol']}\nExp: 30 Days\nLimit: 40GB"
    path = f"/tmp/{u_name}.npv"
    with open(path, "w") as f: f.write(config)
    return send_file(path, as_attachment=True)

@app.route('/backup')
@login_required
def backup(): return send_file('/root/users.db', as_attachment=True)

@app.route('/restore', methods=['POST'])
@login_required
def restore():
    file = request.files['file']
    if file:
        file.save('/root/users.db')
        os.system("systemctl restart smart-panel")
    return redirect('/')

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        u, p = request.form['username'], request.form['password']
        if db_exec("SELECT * FROM admin_config WHERE username=? AND password=?", (u, p), True):
            session['logged_in'] = True; return redirect(url_for('index'))
    return render_template('login.html')

@app.route('/logout')
def logout(): session.pop('logged_in', None); return redirect('/login')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)

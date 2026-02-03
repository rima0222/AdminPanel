import os, sqlite3, secrets
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

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        u, p = request.form['username'], request.form['password']
        if db_exec("SELECT * FROM admin_config WHERE username=? AND password=?", (u, p), True):
            session['logged_in'] = True
            return redirect(url_for('index'))
    return render_template('login.html')

@app.route('/')
@login_required
def index():
    users = db_exec('SELECT * FROM users')
    online = os.popen("who | awk '{print $1}'").read().split()
    return render_template('index.html', users=users, online=online)

@app.route('/add', methods=['POST'])
@login_required
def add():
    u, p, pr, em = request.form['username'], request.form['password'], request.form['protocol'], request.form['user_email']
    os.system(f"useradd -m -s /bin/bash {u} && echo '{u}:{p}' | chpasswd")
    db_exec('INSERT INTO users (username, password, protocol, user_email, status) VALUES (?,?,?,?,?)', (u,p,pr,em,'active'))
    return redirect('/')

@app.route('/send/<u_name>')
@login_required
def send_cfg(u_name):
    user = db_exec("SELECT * FROM users WHERE username=?", (u_name,), True)
    if user and user['user_email']:
        ip = os.popen("curl -s https://api.ipify.org").read().strip()
        body = f"با سلام، مشخصات سرویس شما:\nIP: {ip}\nUser: {u_name}\nPass: {user['password']}\nProtocol: {user['protocol']}\nبا احترام"
        os.system(f'echo "{body}" | mail -s "Service Config" {user["user_email"]}')
        return "✅ ارسال شد"
    return "❌ خطا"

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

@app.route('/logout')
def logout(): session.pop('logged_in', None); return redirect('/login')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)

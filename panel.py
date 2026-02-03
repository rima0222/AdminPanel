import os, sqlite3, secrets
from flask import Flask, render_template, request, redirect, session, url_for
from functools import wraps

app = Flask(__name__)
app.secret_key = secrets.token_hex(16)

def db_exec(query, args=(), one=False):
    conn = sqlite3.connect('/root/users.db')
    conn.row_factory = sqlite3.Row
    cur = conn.execute(query, args)
    res = cur.fetchall()
    conn.commit()
    conn.close()
    return (res[0] if res else None) if one else res

def login_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'logged_in' not in session:
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    return decorated_function

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        user, pwd = request.form['username'], request.form['password']
        admin = db_exec("SELECT * FROM admin_config WHERE username=? AND password=?", (user, pwd), one=True)
        if admin:
            session['logged_in'] = True
            return redirect(url_for('index'))
        return "❌ نام کاربری یا رمز اشتباه است!"
    return render_template('login.html') # باید فایل login.html را هم بسازی یا کد HTML ساده بدهی

@app.route('/')
@login_required
def index():
    users = db_exec('SELECT * FROM users')
    online = os.popen("who | awk '{print $1}'").read().split()
    return render_template('index.html', users=users, online=online)

@app.route('/add', methods=['POST'])
@login_required
def add_user():
    user, pwd, proto = request.form['username'], request.form['password'], request.form['protocol']
    os.system(f"useradd -m -s /bin/bash {user} && echo '{user}:{pwd}' | chpasswd")
    db_exec('INSERT INTO users (username, password, protocol, status) VALUES (?, ?, ?, ?)', (user, pwd, proto, 'active'))
    return redirect(url_for('index'))

@app.route('/delete/<username>')
@login_required
def delete_user(username):
    os.system(f"userdel -r {username}")
    db_exec('DELETE FROM users WHERE username = ?', (username,))
    return redirect(url_for('index'))

@app.route('/change_admin', methods=['POST'])
@login_required
def change_admin():
    u, p = request.form['new_user'], request.form['new_pwd']
    db_exec("UPDATE admin_config SET username=?, password=?", (u, p))
    session.pop('logged_in', None)
    return "✅ تغییر کرد. <a href='/login'>دوباره وارد شوید</a>"

@app.route('/logout')
def logout():
    session.pop('logged_in', None)
    return redirect(url_for('login'))

if __name__ == '__main__':
    os.system("screen -dmS monitor bash /root/core.sh monitor")
    app.run(host='0.0.0.0', port=5000)

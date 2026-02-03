import os, sqlite3, secrets
from flask import Flask, render_template, request, redirect, session, url_for, send_file
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
        if 'logged_in' not in session: return redirect(url_for('login'))
        return f(*args, **kwargs)
    return decorated_function

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
    u_email = request.form['user_email']
    os.system(f"useradd -m -s /bin/bash {user} && echo '{user}:{pwd}' | chpasswd")
    db_exec('INSERT INTO users (username, password, protocol, user_email, status) VALUES (?, ?, ?, ?, ?)', 
            (user, pwd, proto, u_email, 'active'))
    return redirect(url_for('index'))

@app.route('/send_config/<username>')
@login_required
def send_config(username):
    user = db_exec("SELECT * FROM users WHERE username=?", (username,), one=True)
    if user and user['user_email']:
        ip = os.popen("curl -s https://api.ipify.org").read().strip()
        config_text = f"Host: {ip}\nPort: 22\nUser: {user['username']}\nPass: {user['password']}\nProtocol: {user['protocol']}"
        with open(f"/root/{username}.txt", "w") as f: f.write(config_text)
        
        # ارسال ایمیل محترمانه
        subject = "اطلاعات اتصال سرویس شما"
        body = f"کاربر گرامی {username}، با سلام.\nمشخصات سرویس شما آماده است:\n\n{config_text}\n\nبا احترام."
        os.system(f'echo "{body}" | mail -s "{subject}" -A /root/{username}.txt {user["user_email"]}')
        return "✅ کانفیگ با موفقیت ارسال شد."
    return "❌ ایمیل کاربر یافت نشد."

@app.route('/download/<username>')
@login_required
def download_config(username):
    user = db_exec("SELECT * FROM users WHERE username=?", (username,), one=True)
    ip = os.popen("curl -s https://api.ipify.org").read().strip()
    config_content = f"NPV Config\nIP: {ip}\nUser: {username}\nPass: {user['password']}"
    file_path = f"/root/{username}_config.txt"
    with open(file_path, "w") as f: f.write(config_content)
    return send_file(file_path, as_attachment=True)

@app.route('/reset_traffic')
@login_required
def reset_traffic():
    os.system("vnstat --reset -i eth0")
    return "✅ ترافیک با موفقیت ریست شد."

@app.route('/backup')
@login_required
def get_backup():
    return send_file('/root/users.db', as_attachment=True)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)

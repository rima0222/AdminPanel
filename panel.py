import os, sqlite3, subprocess
from flask import Flask, render_template, request, redirect
from flask_httpauth import HTTPBasicAuth

app = Flask(__name__)
auth = HTTPBasicAuth()
USER_DATA = {"admin": "SmartPass123"}

@auth.verify_password
def verify(username, password):
    if username in USER_DATA and USER_DATA[username] == password:
        return username

def db_query(query, args=(), one=False):
    conn = sqlite3.connect('/root/users.db')
    conn.row_factory = sqlite3.Row
    cur = conn.execute(query, args)
    rv = cur.fetchall()
    conn.commit()
    conn.close()
    return (rv[0] if rv else None) if one else rv

@app.route('/')
@auth.login_required
def index():
    users = db_query('SELECT * FROM users')
    online = os.popen("who | awk '{print $1}'").read().split()
    return render_template('index.html', users=users, online=online)

@app.route('/add', methods=['POST'])
@auth.login_required
def add_user():
    user = request.form['username']
    pwd = request.form['password']
    proto = request.form['protocol']
    os.system(f"useradd -m -s /bin/bash {user} && echo '{user}:{pwd}' | chpasswd")
    db_query('INSERT INTO users (username, password, protocol, status) VALUES (?, ?, ?, ?)', 
             (user, pwd, proto, 'active'))
    return redirect('/')

@app.route('/config_email', methods=['POST'])
@auth.login_required
def config_email():
    email = request.form['email']
    app_pass = request.form['app_pass']
    # تنظیم فایل sSMTP برای ارسال ایمیل
    content = f"root={email}\nmailhub=smtp.gmail.com:587\nAuthUser={email}\nAuthPass={app_pass}\nUseSTARTTLS=YES\n"
    with open("/etc/ssmtp/ssmtp.conf", "w") as f:
        f.write(content)
    return "✅ تنظیمات ایمیل ذخیره شد. حالا بک‌آپ‌ها به این ایمیل ارسال می‌شوند."

@app.route('/delete/<username>')
@auth.login_required
def delete_user(username):
    os.system(f"userdel -r {username}")
    db_query('DELETE FROM users WHERE username = ?', (username,))
    return redirect('/')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)

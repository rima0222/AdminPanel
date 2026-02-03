import os, sqlite3
from flask import Flask, render_template, request, redirect
from flask_httpauth import HTTPBasicAuth

app = Flask(__name__)
auth = HTTPBasicAuth()
USER_DATA = {"admin": "SmartPass123"}

@auth.verify_password
def verify(username, password):
    if username in USER_DATA and USER_DATA[username] == password:
        return username

def get_db():
    conn = sqlite3.connect('/root/users.db')
    conn.row_factory = sqlite3.Row
    return conn

@app.route('/')
@auth.login_required
def index():
    db = get_db()
    users = db.execute('SELECT * FROM users').fetchall()
    online = os.popen("who | awk '{print $1}'").read().split()
    return render_template('index.html', users=users, online=online)

@app.route('/add', methods=['POST'])
@auth.login_required
def add_user():
    username = request.form['username']
    password = request.form['password']
    limit = request.form['limit']
    # ایجاد کاربر در لینوکس
    os.system(f"useradd -m -s /bin/bash {username}")
    os.system(f"echo '{username}:{password}' | chpasswd")
    # ذخیره در دیتابیس
    db = get_db()
    db.execute('INSERT INTO users (username, password, limit_login, status) VALUES (?, ?, ?, ?)',
               (username, password, limit, 'active'))
    db.commit()
    return redirect('/')

@app.route('/delete/<username>')
@auth.login_required
def delete_user(username):
    os.system(f"userdel -r {username}")
    db = get_db()
    db.execute('DELETE FROM users WHERE username = ?', (username,))
    db.commit()
    return redirect('/')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)

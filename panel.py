from flask import Flask, render_template, request, redirect
from flask_httpauth import HTTPBasicAuth
import sqlite3, os

app = Flask(__name__)
auth = HTTPBasicAuth()

# نام کاربری و رمز پنل وب
USER_DATA = {"admin": "SmartPass123"}

@auth.verify_password
def verify(username, password):
    if username in USER_DATA and USER_DATA[username] == password:
        return username

@app.route('/')
@auth.login_required
def index():
    conn = sqlite3.connect('/root/users.db')
    conn.row_factory = sqlite3.Row
    users = conn.execute('SELECT * FROM users').fetchall()
    online = os.popen("who | awk '{print $1}'").read().split()
    cpu = os.popen("top -bn1 | grep 'Cpu(s)' | awk '{print $2}'").read().strip()
    return render_template('index.html', users=users, online=online, cpu=cpu)

if __name__ == '__main__':
    os.system("screen -dmS smart_monitor bash /root/core.sh monitor")
    app.run(host='0.0.0.0', port=5000)

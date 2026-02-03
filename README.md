

برای نصب سریع روی سرور اوبونتو، دستورات زیر را کپی و در ترمینال وارد کنید:

```bash
wget [https://raw.githubusercontent.com/نام_کاربری_شما/نام_مخزن/main/core.sh](https://raw.githubusercontent.com/نام_کاربری_شما/نام_مخزن/main/core.sh)
wget [https://raw.githubusercontent.com/نام_کاربری_شما/نام_مخزن/main/panel.py](https://raw.githubusercontent.com/نام_کاربری_شما/نام_مخزن/main/panel.py)
wget [https://raw.githubusercontent.com/نام_کاربری_شما/نام_مخزن/main/install.sh](https://raw.githubusercontent.com/نام_کاربری_شما/نام_مخزن/main/install.sh)
mkdir -p templates && cd templates
wget [https://raw.githubusercontent.com/نام_کاربری_شما/نام_مخزن/main/templates/index.html](https://raw.githubusercontent.com/نام_کاربری_شما/نام_مخزن/main/templates/index.html)
cd ..
bash install.sh

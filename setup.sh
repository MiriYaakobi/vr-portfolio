#!/usr/bin/env bash
# הקמת סביבת מחקר ל-Cyber Security Researcher. להריץ ב-VM מבודד (Kali או Ubuntu).
set -e

# בסיס: מהדר, debugger, git, python, docker
sudo apt update
sudo apt install -y build-essential gdb git python3 python3-pip python3-venv docker.io docker-compose-plugin checksec

# pwndbg: שכבת שיפור מעל gdb, משולבת היטב עם pwntools
if [ ! -d pwndbg ]; then
  git clone https://github.com/pwndbg/pwndbg
  ( cd pwndbg && ./setup.sh )
fi

# pwntools בתוך virtualenv ייעודי
python3 -m venv ~/vr-venv
# הפעלה: source ~/vr-venv/bin/activate
~/vr-venv/bin/pip install pwntools

# Ghidra: דורש Java 21. ב-Kali זמין ישירות דרך apt
sudo apt install -y ghidra || echo "אם apt לא מצא ghidra, יש להוריד מהאתר הרשמי של NSA"

# הוספת המשתמש לקבוצת docker כדי לא להריץ עם sudo כל פעם. יש להתחבר מחדש אחרי כן.
sudo usermod -aG docker "$USER"

echo "setup done. יש להפעיל: source ~/vr-venv/bin/activate"

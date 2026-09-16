# vr-reference-code

קוד מוכן להרצה עבור משימת Cyber Security Researcher. מבנה התיקיות זהה ל-repo של ה-portfolio, כדי שאפשר להעתיק ישירות.

## מסגרת חוקית
כל הקוד כאן נועד להרצה במעבדה האישית המבודדת בלבד, לצורך לימוד. אין להריץ מול מערכות שאינן בבעלות אישית.

## מה יש כאן
- setup.sh - התקנת כל כלי הסביבה. להריץ ב-VM מבודד.
- .gitignore - למניעת העלאה בטעות של flags, cores וקבצים זמניים.
- Makefile - בונה את כל הבינארים הפגיעים עם הדגלים הנכונים.
- 01-foundations/mem.c - תוכנית להדגמת memory layout ו-stack frame.
- 02-reverse-engineering/crackme.c - crackme לתרגול RE (יש לעשות strip אחרי הרכבה).
- 03-binexp-control-flow/ret2win/ - תוכנית פגיעה ו-exploit של ret2win.
- 04-binexp-defeating-mitigations/ret2libc/ - תוכנית פגיעה ו-exploit של ret2libc שעוקף NX ו-ASLR.

## הרכבה
```bash
make all       # בונה את כל הבינארים
make clean     # מוחק את הבינארים שנבנו
```

## הרצת exploits
יש להפעיל קודם את ה-virtualenv עם pwntools:
```bash
source ~/vr-venv/bin/activate
cd 03-binexp-control-flow/ret2win && python3 exploit.py
```

הערה: ה-OFFSET ב-exploit של ret2win הוא placeholder. יש למצוא אותו עם cyclic כמתואר בשלב Binary Exploitation.

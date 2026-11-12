#!/bin/bash

echo "========================================"
echo "   ret2win Automated Integration Test   "
echo "========================================"

# Test 1: Basic ret2win without stack protections
echo -e "\n[*] Building 'vuln' WITHOUT Stack Canary..."
gcc -fno-stack-protector -no-pie vuln.c -o vuln 2>/dev/null

# < /dev/null feeds an immediate EOF to pwntools interactive mode, causing it to exit cleanly without hanging.
echo "[*] Running exploit.py..."
python3 exploit.py < /dev/null > out_basic.txt 2>&1

if grep -q "Access granted" out_basic.txt; then
    echo "[+] TEST 1 PASSED: Control flow successfully hijacked."
else
    echo "[-] TEST 1 FAILED."
fi

# Test 2: ROP chain passing arguments (0xdeadbeef)
echo -e "\n[*] Running exploit_args.py..."
python3 exploit_args.py < /dev/null > out_args.txt 2>&1

if grep -q "Access granted" out_args.txt; then
    echo "[+] TEST 2 PASSED: Arguments successfully passed via ROP (0xdeadbeef)."
else
    echo "[-] TEST 2 FAILED."
fi

# Test 3: Mitigation check - ensure Canary blocks the exploit
echo -e "\n[*] Building 'vuln' WITH Stack Canary enabled..."
gcc -no-pie vuln.c -o vuln 2>/dev/null

echo "[*] Running exploit.py against hardened binary..."
python3 exploit.py < /dev/null > out_canary.txt 2>&1

if grep -q "stack smashing detected" out_canary.txt; then
    echo "[+] TEST 3 PASSED: Stack Canary successfully detected the overflow."
else
    echo "[-] TEST 3 FAILED."
fi

echo -e "\n[*] Cleaning up temporary outputs..."
rm -f out_basic.txt out_args.txt out_canary.txt
gcc -fno-stack-protector -no-pie vuln.c -o vuln 2>/dev/null
echo "[*] Restored 'vuln' to default vulnerable state."
echo "========================================"
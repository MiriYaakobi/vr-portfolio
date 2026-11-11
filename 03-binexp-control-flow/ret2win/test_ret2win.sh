#!/bin/bash

echo "========================================"
echo "   ret2win Automated Integration Test   "
echo "========================================"

# Test 1: Basic ret2win (No Canary)
echo -e "\n[*] Building 'vuln' WITHOUT Stack Canary..."
gcc -fno-stack-protector -no-pie vuln.c -o vuln

echo "[*] Running exploit.py (Timeout: 3s)..."
# Using timeout because the exploit opens an interactive shell which would hang the script
timeout 3 python3 exploit.py > out_basic.txt 2>&1

if grep -q "Access granted" out_basic.txt; then
    echo "[+] TEST 1 PASSED: Control flow successfully hijacked."
else
    echo "[-] TEST 1 FAILED."
fi

# Test 2: Advanced ROP win_args (No Canary)
echo -e "\n[*] Running exploit_args.py (Timeout: 3s)..."
timeout 3 python3 exploit_args.py > out_args.txt 2>&1

if grep -q "Access granted" out_args.txt; then
    echo "[+] TEST 2 PASSED: Arguments successfully passed via ROP (0xdeadbeef)."
else
    echo "[-] TEST 2 FAILED."
fi

# Test 3: Mitigation Check (With Canary)
echo -e "\n[*] Building 'vuln' WITH Stack Canary enabled..."
gcc -no-pie vuln.c -o vuln

echo "[*] Running exploit.py against hardened binary..."
timeout 3 python3 exploit.py > out_canary.txt 2>&1

if grep -q "stack smashing detected" out_canary.txt; then
    echo "[+] TEST 3 PASSED: Stack Canary successfully detected the overflow."
else
    echo "[-] TEST 3 FAILED."
fi

# Cleanup and restore
echo -e "\n[*] Cleaning up temporary outputs..."
rm out_basic.txt out_args.txt out_canary.txt

gcc -fno-stack-protector -no-pie vuln.c -o vuln
echo "[*] Restored 'vuln' to default vulnerable state."
echo "========================================"
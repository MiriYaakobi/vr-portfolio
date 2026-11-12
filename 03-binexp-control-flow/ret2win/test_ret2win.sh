#!/bin/bash

echo "========================================"
echo "   ret2win Automated Integration Test   "
echo "========================================"

# Test 1: Basic ret2win without stack protections
echo -e "\n[*] Building 'vuln' WITHOUT Stack Canary..."
gcc -fno-stack-protector -no-pie vuln.c -o vuln 2>/dev/null

# Run exploit and forcefully kill the interactive shell after 3 seconds
echo "[*] Running exploit.py..."
timeout -s KILL 3 python3 exploit.py > out_basic.txt 2>&1 || true

if grep -q "Access granted" out_basic.txt; then
    echo "[+] TEST 1 PASSED: Control flow successfully hijacked."
else
    echo "[-] TEST 1 FAILED."
fi

# Test 2: ROP chain passing arguments (0xdeadbeef)
echo -e "\n[*] Running exploit_args.py..."
timeout -s KILL 3 python3 exploit_args.py > out_args.txt 2>&1 || true

if grep -q "Access granted" out_args.txt; then
    echo "[+] TEST 2 PASSED: Arguments successfully passed via ROP (0xdeadbeef)."
else
    echo "[-] TEST 2 FAILED."
fi

# Test 3: Mitigation check - ensure Canary blocks the exploit
echo -e "\n[*] Building 'vuln' WITH Stack Canary enabled..."
gcc -no-pie vuln.c -o vuln 2>/dev/null

echo "[*] Running exploit.py against hardened binary..."
timeout -s KILL 3 python3 exploit.py > out_canary.txt 2>&1 || true

if grep -q "stack smashing detected" out_canary.txt; then
    echo "[+] TEST 3 PASSED: Stack Canary successfully detected the overflow."
else
    echo "[-] TEST 3 FAILED."
fi

# Cleanup and restore vulnerable state for manual testing
echo -e "\n[*] Cleaning up temporary outputs..."
rm -f out_basic.txt out_args.txt out_canary.txt
gcc -fno-stack-protector -no-pie vuln.c -o vuln 2>/dev/null
echo "[*] Restored 'vuln' to default vulnerable state."
echo "========================================"
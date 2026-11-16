#!/bin/bash

echo "========================================"
echo "   ret2libc Automated Integration Test  "
echo "========================================"

echo -e "\n[*] TEST 1: Happy Path (ASLR/NX Bypass)"
python3 exploit.py TEST > out_success.txt 2>&1

if grep -q "libc base:" out_success.txt && grep -q "miri" out_success.txt; then
    echo "[+] PASS: libc base leaked and shell executed successfully."
else
    echo "[-] FAIL: Shell not reached."
fi

echo -e "\n[*] TEST 2: Intentional movaps crash (Missing alignment)"
python3 exploit.py TEST NO_ALIGN > out_fail.txt 2>&1

# Checking for our deterministic OS-level validation string
if grep -q "EXPECTED_CRASH_SIGSEGV_DETECTED" out_fail.txt; then
    echo "[+] PASS: Process crashed with SIGSEGV as expected."
else
    echo "[-] FAIL: Did not detect SIGSEGV."
fi

echo -e "\n[*] Cleanup..."
rm -f out_success.txt out_fail.txt
echo "========================================"
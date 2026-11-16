#!/bin/bash

echo "========================================"
echo "   ret2libc Automated Integration Test  "
echo "========================================"

echo -e "\n[*] TEST 1: Happy Path (ASLR/NX Bypass)"
# > /dev/null 2>&1 hides the messy pwntools output completely
if python3 exploit.py TEST < /dev/null > /dev/null 2>&1; then
    echo "[+] PASS: Shell executed successfully."
else
    echo "[-] FAIL: Shell not reached."
fi

echo -e "\n[*] TEST 2: Intentional movaps crash (Missing alignment)"
if python3 exploit.py TEST NO_ALIGN < /dev/null > /dev/null 2>&1; then
    echo "[+] PASS: Target process crashed as expected."
else
    echo "[-] FAIL: Exploit did not crash the target."
fi

echo "========================================"
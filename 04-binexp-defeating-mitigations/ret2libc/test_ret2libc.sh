#!/bin/bash

echo "========================================"
echo "   ret2libc Automated Integration Test  "
echo "========================================"

echo "[*] Compiling target binary..."
gcc -fno-stack-protector -no-pie vuln.c -o vuln 2>/dev/null

echo -e "\n[*] TEST 1: Happy Path (ASLR/NX Bypass)"
# Run the exploit in test mode so it sends 'whoami' and exits cleanly instead of hanging in interactive mode
python3 exploit.py TEST > out_success.txt 2>&1

# Verify both the ASLR defeat (libc base calculation) and successful shell execution
if grep -q "libc base:" out_success.txt && grep -q "miri" out_success.txt; then
    echo "[+] PASS: libc base leaked and shell executed successfully."
else
    echo "[-] FAIL: Shell not reached."
fi

echo -e "\n[*] TEST 2: Intentional movaps crash (Missing alignment)"
# Run the exploit with a flag that removes the ret_gadget to intentionally trigger an alignment crash
python3 exploit.py TEST NO_ALIGN > out_fail.txt 2>&1

# Check if pwntools reported a segmentation fault (signal 11)
if grep -q "SIGSEGV" out_fail.txt; then
    echo "[+] PASS: Process crashed with SIGSEGV as expected."
else
    echo "[-] FAIL: Did not detect SIGSEGV."
fi

echo -e "\n[*] Cleanup..."
rm -f out_success.txt out_fail.txt
echo "========================================"
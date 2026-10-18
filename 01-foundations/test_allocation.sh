#!/usr/bin/env bash
set -euo pipefail

echo "[*] Compiling mem.c for Exercise 1 (32 bytes)..."
if ! gcc -g -O0 -fno-stack-protector -no-pie -o mem mem.c; then
    echo "[!] Compilation failed."
    exit 1
fi

echo "[*] Verifying stack allocation in greet() for 32 bytes..."
if objdump -d -M intel mem | grep -A 10 "<greet>:" | grep -q "sub    rsp,0x20"; then
    echo "[+] Test 1 Passed: Stack allocation is exactly 0x20. Offsets in notes.md are valid."
else
    echo "[!] Test 1 Failed: Stack allocation changed for 32 bytes!"
    exit 1
fi

echo "[*] Creating temporary mem_100.c for Exercise 2 (100 bytes)..."
# Create a temporary file by replacing 32 with 100
sed 's/char name\[32\];/char name[100];/' mem.c > mem_100.c

echo "[*] Compiling mem_100.c..."
if ! gcc -g -O0 -fno-stack-protector -no-pie -o mem_100 mem_100.c; then
    echo "[!] Compilation of mem_100.c failed."
    rm -f mem_100.c mem_100
    exit 1
fi

echo "[*] Verifying stack allocation in greet() for 100 bytes..."
if objdump -d -M intel mem_100 | grep -A 10 "<greet>:" | grep -q "sub    rsp,0x70"; then
    echo "[+] Test 2 Passed: Stack allocation is exactly 0x70. Offsets in notes.md are valid."
else
    echo "[!] Test 2 Failed: Stack allocation changed for 100 bytes!"
    rm -f mem_100.c mem_100
    exit 1
fi

# Clean up temporary files
rm -f mem_100.c mem_100
echo "[+] All validation tests passed successfully!"
exit 0
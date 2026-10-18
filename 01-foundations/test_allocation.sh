#!/bin/bash

echo "[*] Compiling mem.c..."
gcc -fno-stack-protector -z execstack -no-pie -o mem mem.c

if [ $? -ne 0 ]; then
    echo "[!] Compilation failed."
    exit 1
fi

echo "[*] Verifying stack allocation in greet()..."
# Disassemble and look for the specific stack allocation in greet
# We expect 'sub rsp,0x20' for a 32-byte buffer
if objdump -d -M intel mem | grep -A 10 "<greet>:" | grep -q "sub    rsp,0x20"; then
    echo "[+] Test Passed: Stack allocation is exactly 0x20. Offsets in notes.md are valid."
    exit 0
else
    echo "[!] Test Failed: Stack allocation changed! The documented offsets might be wrong."
    exit 1
fi
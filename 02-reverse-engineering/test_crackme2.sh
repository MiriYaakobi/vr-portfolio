#!/bin/bash

# Compile the program in an environment identical to the research setup
gcc -O0 -no-pie crackme2.c -o crackme2
strip crackme2

echo "=== Running crackme2 Automated Tests ==="

# Test 1: Valid input (expected to succeed)
echo -n "[*] Test 1: Valid input ('entrypt') -> "
OUTPUT1=$(echo "entrypt" | ./crackme2)
if [[ "$OUTPUT1" == *"Correct"* ]]; then
    echo "PASS"
else
    echo "FAIL"
fi

# Test 2: Valid length but invalid key (expected to fail)
echo -n "[*] Test 2: Invalid input, correct length ('AAAAAAA') -> "
OUTPUT2=$(echo "AAAAAAA" | ./crackme2)
if [[ "$OUTPUT2" == *"Wrong"* ]]; then
    echo "PASS"
else
    echo "FAIL"
fi

# Test 3: Input too short (expected to fail)
echo -n "[*] Test 3: Short input ('short') -> "
OUTPUT3=$(echo "short" | ./crackme2)
if [[ "$OUTPUT3" == *"Wrong"* ]]; then
    echo "PASS"
else
    echo "FAIL"
fi

echo "========================================"
#!/bin/bash

# Compile the program in an environment identical to the research setup
gcc -O0 -no-pie crackme2.c -o crackme2
strip crackme2

echo "=== Running crackme2 Automated Tests ==="

failures=0

run_test() {
    local description="$1"
    local input="$2"
    local expected="$3"
    local output

    echo -n "[*] $description -> "
    output=$(printf '%s\n' "$input" | ./crackme2)
    
    if [[ "$output" == *"$expected"* ]]; then
        echo "PASS"
    else
        echo "FAIL"
        failures=$((failures + 1))
    fi
}

run_test "Valid input ('entrypt')" "entrypt" "Correct"
run_test "Invalid input, correct length ('AAAAAAA')" "AAAAAAA" "Wrong"
run_test "Short input ('short')" "short" "Wrong"

echo "========================================"

if (( failures > 0 )); then
    exit 1
fi
exit 0
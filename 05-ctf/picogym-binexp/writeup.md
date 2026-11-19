# picoGym Binary Exploitation Challenges

> **Note:** The prerequisite challenge `format string 0` was already completed and documented in Module 03 (`../../03-binexp-control-flow/`). This file documents the additional Binary Exploitation challenges solved for Module 05.

## Challenge 1: PIE TIME
- **Category:** Binary Exploitation (Defeating Mitigations - PIE / ASLR Bypass)
- **Objective:** Bypass Position Independent Executable (PIE) and ASLR randomization by calculating the dynamic runtime address of the hidden `win` function using a provided memory leak (`main`), and jump to it to print the flag.
- **Pattern & Methodology:**
  Through static analysis of the provided C source code, I saw that the program prints the current runtime address of `main` (`printf("Address of main: %p\n", &main);`), reads a hexadecimal address from user input, and directly calls it as a function pointer (`foo()`). The goal is to redirect execution to the `win()` function, which opens and prints `flag.txt`. Because PIE and ASLR randomize the binary's memory location on every execution, I cannot simply use a hardcoded static address. However, the relative distance (offset) between functions inside the binary always remains constant.
1. **Static Analysis (Finding Function Addresses):** I opened the local binary in GDB and used `disassemble main` and `disassemble win` to inspect their static addresses:
   - Static `main`: `0x000000000000134c`
   - Static `win`: `0x00000000000012aa`
2. **Calculating the Static Offset:** To find the exact distance between the two functions, I subtracted the static address of `win` from the static address of `main`:
   `0x134c - 0x12aa = 0xa2`
   This means `win` is always located `0xa2` bytes before `main` in memory, regardless of where the binary is loaded.
3. **Dynamic Address Calculation:** When connecting to the remote server, the program gave me the dynamic address of `main` for that specific run: `0x63220d12e34c`. I subtracted the constant offset (`0xa2`) from this leaked address to calculate the exact runtime location of `win`:
   `0x63220d12e34c - 0xa2 = 0x63220d12e2aa`
4. **Control Flow Redirection:** I entered `0x63220d12e2aa` into the prompt. The program cast my input into a function pointer and executed `win()`, printing the flag.
- **Execution Evidence (Terminal Output):**
  ```bash
  $ nc xebec.cylabacademy.net 26523
  Address of main: 0x63220d12e34c
  Enter the address to jump to, ex => 0x12345: 0x63220d12e2aa
  Your input: 63220d12e2aa
  You won!
  academy{b4s1c_p051t10n_1nd3p3nd3nc3_2f9f2868}
  ```
- **Solution:** Used GDB to determine the static offset (`0xa2`) between `main` and `win`, then subtracted that offset from the runtime address of `main` leaked by the server to calculate the dynamic address of `win` and jump directly to it.
- **Flag:** `academy{b4s1c_p051t10n_1nd3p3nd3nc3_2f9f2868}`
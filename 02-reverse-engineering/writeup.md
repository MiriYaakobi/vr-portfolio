# Reverse Engineering - Crackme Writeup

## Exercise 1: Basic Static and Dynamic Analysis

### 1. Initial Static Analysis (CLI)
Before opening the binary in a decompiler, I performed a basic static analysis using CLI tools to gather initial intelligence.

**File Information:**
`file crackme`
Result: ELF 64-bit LSB executable, x86-64, dynamically linked, stripped.
The binary is stripped, meaning all debug symbols (like function and variable names) have been removed.

**String Extraction:**
`strings crackme`
The strings output revealed several interesting plain-text artifacts:
* "Password: " - Likely the prompt for user input.
* "Correct. Flag: entrypoint{re_basics}" - The success message.
* "Wrong." - The failure message.
* "entrypt" - A suspicious string that appears right before the password prompt, likely the hardcoded secret or part of it.

### 2. Static Analysis in Ghidra (Decompilation)
After importing the stripped binary into Ghidra and running auto-analysis, I located the main function. 
While I initially found it using string cross-references (XREFs) by searching for "Password: ", I also learned and verified a more reliable method for complex binaries: 
I navigated to the `entry` point where the program starts. According to the Linux calling convention, right before the program calls `__libc_start_main`, it must load the address of the main function into the `RDI` register. In the assembly, I saw it moved `FUN_004011b6` into RDI, which perfectly confirmed this is the real main function.

**Decompiler Findings in FUN_004011b6:**
* The decompiler merged the local variables into a single large buffer named `local_60[80]` on the stack.
* The hardcoded secret `"entrypt"` is copied into the beginning of `local_60`.
* The user input via `scanf` is stored at an offset of 8 bytes (`local_60 + 8`), so it doesn't overwrite the secret.
* A `strcmp(local_60 + 8, local_60)` call compares the user input against the hardcoded secret.

**Conclusion:** The extracted password is `"entrypt"`.
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
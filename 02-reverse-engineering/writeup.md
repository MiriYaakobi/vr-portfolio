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

### 3. Dynamic Analysis (GDB)
To verify the findings from the static analysis, I performed a dynamic analysis using GDB (with pwndbg). Inspecting the exact `strcmp` call required bypassing several technical hurdles caused by the system and the stripped binary:

**Challenges and Workarounds:**
* **Failed Attempt 1 (`break strcmp`):** Initially, I tried to set a breakpoint directly on `strcmp`. However, the Linux loader heavily uses `strcmp` during startup to load libraries (Lazy Binding). Continuing through these endless system calls was inefficient.
* **Failed Attempt 2 (`disassemble`):** I tried to use the `disassemble` command to find the specific `strcmp` call inside the main function. Because the binary is stripped, GDB could not identify the function's boundaries and returned an error.

**The Successful Approach:**
1. I set a breakpoint exactly at the entry address of the main function (`break *0x4011b6`), which I had previously found in Ghidra.
2. I ran the program until it stopped at this precise entry point, ensuring system libraries were already loaded.
3. To view the assembly code without symbols, I used `x/40i $rip` to print the next 40 instructions directly from the instruction pointer.
4. I located the specific `call strcmp@plt` instruction in the output and noted its exact memory address (`0x401228`).
5. I set a precise hardware breakpoint on that address (`break *0x401228`), continued execution, and entered a test password (`miri123`).
6. The program stopped exactly at the comparison. Following the System V AMD64 ABI calling convention, I inspected the registers:
   * `x/s $rdi` revealed the user input: `"miri123"`
   * `x/s $rsi` revealed the hardcoded secret: `"entrypt"`

**Final Conclusion:** The dynamic analysis successfully confirmed the static analysis. The hardcoded password is `"entrypt"`. Entering this password yields the flag: `entrypoint{re_basics}`.

### 4. Proof of Concept (PoC)
To confirm the extracted password is fully operational, I ran the binary in the standard environment without the debugger.

**Execution Output:**

    $ ./crackme 
    Password: entrypt
    Correct. Flag: entrypoint{re_basics}

The application accepted the password, verifying the accuracy of both the static and dynamic analysis phases.
# Module 3: Binary Exploitation - Control Flow Hijack

## Exercise 1: Basic Buffer Overflow (ret2win)

### Security Posture & Vulnerability Analysis
I began by analyzing the binary's protections using `checksec`. The results showed that the Stack Canary and PIE were disabled (`No canary found`, `No PIE (0x400000)`), making it an ideal candidate for a classic buffer overflow and a ret2win attack.

Reviewing the original source code in `vuln.c`, I identified the vulnerability in the `vulnerable()` function. It allocated a 64-byte `buffer` on the stack, but used `read(0, buffer, 256)` to accept up to 256 bytes of standard input. Since stack protections are disabled, writing past the 64-byte limit allows for a direct overwrite of the saved Return Address.

**Note on Binary Versioning:** The evidence in this section (Exercise 1) was collected from the original 64-byte-buffer build, where the return-address offset was 72. Exercise 2 documents the current 128-byte-buffer build (currently residing in `vuln.c`) and its recalculated offset of 136.

### Finding the Offset
Instead of guessing the distance to the Return Address, I used a cyclic pattern to find the exact offset dynamically for the 64-byte build. I generated a 200-byte pattern and fed it to the vulnerable program inside GDB.

The program crashed (SIGSEGV) when attempting to execute the `ret` instruction because it tried to return to an invalid address. By inspecting the registers at the time of the crash, I noticed that the Stack Pointer (`RSP`) contained a specific piece of my cyclic pattern:

    RSP  0x7fffffffdbf8 ◂— 0x6161617461616173 ('saaataaa')

I took the first four characters of this pattern (`saaa`) and used the `pwntools` cyclic utility to find its exact position:

    pwn cyclic -l saaa

The tool returned **72**, confirming the exact offset in bytes. This perfectly matches the theoretical memory layout: 64 bytes to fill the buffer, plus 8 bytes to overwrite the Saved RBP, bringing us directly to the Return Address.

### Payload Construction & Stack Alignment Fix
I wrote a Python exploit using `pwntools` to automate the attack. Initially, I structured the payload with 72 bytes of junk followed directly by the address of the `win()` function.

While this successfully hijacked the control flow and printed the flag, the resulting shell crashed immediately. I realized this was a **Stack Alignment** issue. In 64-bit Linux, functions like `system()` require the stack pointer (`RSP`) to be 16-byte aligned before execution. Because I bypassed the standard `call` instruction and jumped directly via `ret`, the stack was misaligned by 8 bytes. 

To fix this, I used a ROP technique: I found a simple `ret` gadget in the binary and added it to my payload right before the `win` address. This extra return instruction popped 8 bytes off the stack, perfectly aligning it for the `system("/bin/sh")` call.

### Exploit Execution
Running the finalized exploit against the 64-byte binary successfully provided an interactive shell:

    [+] Starting local process './vuln': pid 4115
    [*] Switching to interactive mode
    
    Done.
    Access granted. Flag: entrypoint{ret2win_success}
    $ whoami
    miri

---

## Exercise 2: Adapting to Source Code Changes

### Objective
To demonstrate a fundamental understanding of stack mechanics, I modified the original source code to change the buffer size, recompiled the binary, and successfully adapted the exploit without relying on blind guessing. This represents the current state of `vuln.c` in the repository.

### Code Modification & Re-calculation
I edited `vuln.c` and increased the buffer size from 64 bytes to 128 bytes:
`char buffer[128];`

After pushing the changes, pulling them to my WSL environment, and recompiling the binary, the previous exploit naturally failed. The offset to the Return Address had changed. 
Based on the memory layout of the stack, I calculated the new offset mathematically:
- **128 bytes** to fill the new buffer.
- **8 bytes** to overwrite the Saved RBP.
- Total offset: 128 + 8 = **136 bytes**.

### Exploit Update and Execution
I updated the `exploit.py` script, changing the offset variable to match my calculation:
`OFFSET = 136`

No other changes to the ROP chain or payload structure were necessary. Running the updated exploit confirmed that my mathematical approach was perfectly accurate, granting me a shell immediately:

    (venv) miri@vr-lab:~/vr-portfolio/03-binexp-control-flow/ret2win$ python3 exploit.py
    [*] '/home/miri/vr-portfolio/03-binexp-control-flow/ret2win/vuln'
        Arch:       amd64-64-little
        RELRO:      Partial RELRO
        Stack:      No canary found
        NX:         NX enabled
        PIE:        No PIE (0x400000)
        SHSTK:      Enabled
        IBT:        Enabled
        Stripped:   No
        Debuginfo:  Yes
    [*] Loading gadgets for '/home/miri/vr-portfolio/03-binexp-control-flow/ret2win/vuln'
    [+] Starting local process './vuln': pid 6500
    [*] Switching to interactive mode
    
    Done.
    Access granted. Flag: entrypoint{ret2win_success}
    $ whoami
    miri

---

## Exercise 3: Enabling the Stack Canary

### Objective
To observe and document the effects of modern exploit mitigations, specifically the Stack Canary, on a standard buffer overflow attack.

### Recompilation and Execution
I recompiled `vuln.c` without the `-fno-stack-protector` flag, effectively enabling the compiler's default stack protection. I then ran the exact same exploit payload.

This time, the exploit failed to hijack the control flow. Instead of a standard Segmentation Fault (`SIGSEGV`) occurring at the `ret` instruction, the program crashed immediately with the following output:

    *** stack smashing detected ***: terminated
    Program received signal SIGABRT, Aborted.

### Vulnerability Mitigation Analysis
The failure of the exploit is due to the Stack Canary mechanism. When the protection is enabled, the compiler alters the stack frame layout. It inserts a random 8-byte value (the Canary) directly between the local `buffer` and the Saved RBP. 

Because a buffer overflow writes data sequentially, my payload inevitably overwrote this Canary value while attempting to reach the Return Address. Before the `vulnerable()` function could execute its `ret` instruction, a validation check was performed. The program compared the current Canary value on the stack against its original saved value. 

Recognizing that the Canary had been modified ("smashed"), the program intentionally triggered a `SIGABRT` via the `abort()` function to safely terminate the process before the attacker could gain control of the execution pointer (`RIP`). This proves that a classic sequential buffer overflow cannot blindly bypass an active Stack Canary without first leaking its random value.

### Mitigation Compilation & checksec Evidence
To explicitly test the Stack Canary mitigation, I compiled the binary enabling the protector (which is also the default on modern compilers unless disabled):
`gcc vuln.c -o vuln_canary`

Running `checksec` on this specific build confirms the canary is actively enforcing:
    Arch:       amd64-64-little
    RELRO:      Partial RELRO
    Stack:      Canary found
    NX:         NX enabled
    PIE:        PIE enabled

### Note on Hardware Mitigations (SHSTK / IBT)
In my `checksec` outputs throughout the exercises, `SHSTK` (Shadow Stack) and `IBT` (Indirect Branch Tracking) appeared as `Enabled`. These are Intel CET (Control-flow Enforcement Technology) hardware mitigations. 
However, it is important to note that these are only *marked* as enabled by the compiler. For them to actually disrupt a ROP chain, both the physical CPU hardware and the OS kernel must actively enforce them. In my local WSL environment, CET is not actively enforced by the underlying hypervisor/hardware. Therefore, my ROP chains (using `pop rdi` and `ret`) executed successfully without triggering a CET hardware violation.

---

## Exercise 4: Advanced ROP - Passing Arguments

### Objective
To move beyond a basic `ret2win` exploit by calling a target function that requires a specific parameter. In the x86-64 System V ABI, arguments are passed via registers (specifically `RDI` for the first argument), not the stack. This requires building a Return-Oriented Programming (ROP) chain to pop a value into `RDI` before jumping to the target.

### The Missing Gadget Challenge
I updated `vuln.c` to include `win_args(int secret_code)`, a function that grants a shell only if the argument matches `0xdeadbeef`. 
To pass this argument, my exploit script utilized `pwntools` to search for a `pop rdi; ret` gadget. However, the script crashed:

    TypeError: 'NoneType' object is not subscriptable

This occurred because modern Linux systems and GCC compilers have removed the historical `__libc_csu_init` function (which naturally contained this gadget sequence) for optimization and security reasons. Without an authentic `libc` leak (Ret2Libc), the required gadget simply did not exist in this small binary.

### Lab Environment Adjustment
To isolate and practice the exact mechanics of parameter passing without escalating to a full Ret2Libc attack, I intentionally added a "Gadget Farm" to the source code:

    void gadget_farm(void) {
        __asm__("pop %rdi; ret");
    }

I recompiled the binary using the `-fcf-protection=none` flag to disable modern Intel CET mitigations that were confusing the `pwntools` search engine.

### Payload Construction & Execution
With the gadget now present in the binary, I structured the ROP chain in `exploit_args.py` as follows:
1. **Offset (136 bytes):** Overwrite the buffer and Saved RBP.
2. **pop rdi gadget:** The CPU jumps here, popping the next stack value into `RDI`.
3. **0xdeadbeef:** The argument consumed by the `pop rdi` instruction.
4. **ret gadget:** Used to ensure 16-byte stack alignment.
5. **win_args address:** The final destination.

Running the exploit successfully loaded the password into the register and bypassed the condition:

    [+] Starting local process './vuln': pid 4177
    [*] Switching to interactive mode
    
    Done.
    Access granted! Secret code is correct. Spawning shell...
    $ whoami
    miri

---

## Exercise 5: Format String vs. Stack Overflow (picoGym)

### Conceptual Difference
Throughout exercises 1-4, I exploited **Stack Overflow** vulnerabilities, which involve physically exceeding a buffer's allocated space to overwrite adjacent memory (like the Return Address). 
In contrast, a **Format String** vulnerability is a logical flaw. It occurs when user input is passed directly to a formatting function (e.g., `printf(choice)`) without a format specifier. By injecting format parameters like `%x` or `%s`, I can force the function to read from or write to arbitrary memory locations without overflowing the buffer.

### Challenge Logic & Exploitation
This picoGym challenge consisted of a two-stage menu system where a secret flag is printed only if the program encounters a memory crash (`SIGSEGV`). To reach the flag, I had to bypass specific checks using the menu options provided:

1. **Stage 1 (Patrick) - Bypassing Length Check:** 
   The first function required `printf` to output more than 64 characters to proceed. I selected the `Gr%114d_Cheese` burger from the menu. The `%114d` specifier forced `printf` to pad a random stack integer with 114 spaces, effortlessly bypassing the length condition.
2. **Stage 2 (Bob) - Triggering the Segmentation Fault:** 
   The second function required a crash to trigger the flag handler. I selected `Cla%sic_Che%s%steak`. The `%s` specifier instructed `printf` to treat a random stack value as a memory pointer and attempt to read a string from it. Since the address was invalid, it would cause an illegal memory access.

### Local Testing vs. Remote Execution
During local testing on my modern WSL environment, the `%s` injection gracefully printed `(null)` instead of crashing, due to updated system handling of null pointers in `printf`. 
However, successful exploitation often depends on the target's specific environment. When connecting to the remote picoCTF instance, the stack contained different garbage values. The `%s` specifier successfully attempted to read an invalid memory address, triggering the intended `SIGSEGV` crash.

### Execution & Flag
I connected to the remote CTF server:

    nc xebec.cylabacademy.net 20067

After providing the two crafted inputs, the server's memory access failed, the signal handler was triggered, and the flag was successfully captured:

    academy{7h3_cu570m3r_15_n3v3r_SEGFAULT_0fa8dcc5}
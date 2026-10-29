# Module 3: Binary Exploitation - Control Flow Hijack

## Exercise 1: Basic Buffer Overflow (ret2win)

### Security Posture & Vulnerability Analysis
I began by analyzing the binary's protections using `checksec`. The results showed that the Stack Canary and PIE were disabled (`No canary found`, `No PIE (0x400000)`), making it an ideal candidate for a classic buffer overflow and a ret2win attack.

Reviewing the source code in `vuln.c`, I identified the vulnerability in the `vulnerable()` function. It allocates a 64-byte `buffer` on the stack, but uses `read(0, buffer, 256)` to accept up to 256 bytes of standard input. Since stack protections are disabled, writing past the 64-byte limit allows for a direct overwrite of the saved Return Address.

### Finding the Offset
Instead of guessing the distance to the Return Address, I used a cyclic pattern to find the exact offset dynamically. I generated a 200-byte pattern and fed it to the vulnerable program inside GDB.

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
Running the finalized exploit successfully provided an interactive shell:

    [+] Starting local process './vuln': pid 4115
    [*] Switching to interactive mode
    
    Done.
    Access granted. Flag: entrypoint{ret2win_success}
    $ whoami
    miri

---

## Exercise 2: Adapting to Source Code Changes

### Objective
To demonstrate a fundamental understanding of stack mechanics, I modified the original source code to change the buffer size, recompiled the binary, and successfully adapted the exploit without relying on blind guessing.

### Code Modification & Re-calculation
I edited `vuln.c` and increased the buffer size from 64 bytes to 128 bytes:
`char buffer[128];`

After pushing the changes, pulling them to my Linux environment, and recompiling the binary, the previous exploit naturally failed. The offset to the Return Address had changed. 
Based on the memory layout of the stack, I calculated the new offset mathematically:
* **128 bytes** to fill the new buffer.
* **8 bytes** to overwrite the Saved RBP.
* Total offset: 128 + 8 = **136 bytes**.

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

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
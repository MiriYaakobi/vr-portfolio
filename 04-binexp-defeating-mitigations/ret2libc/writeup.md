# Module 4: Binary Exploitation - Defeating Mitigations

## Exercise 1: Bypassing ASLR and NX (ret2libc)

### Security Posture & Vulnerability Analysis
I began by analyzing the binary's protections using `checksec`. The results showed that NX (No-eXecute) was enabled, while Stack Canary and PIE were disabled. 

Because NX is active, the stack is not executable, meaning I cannot inject and run custom shellcode. Furthermore, the system has ASLR (Address Space Layout Randomization) enabled, which means the `libc` library is loaded at a random, unpredictable memory address every time the program runs. To overcome these mitigations, I developed a two-stage Return Oriented Programming (ROP) attack known as ret2libc.

### Information Gathering
To perform a Code Reuse attack, I needed specific data from the local environment before writing the exploit:

**Target Library Identification:** 
I used the `ldd` command to confirm exactly which `libc` version the binary loads. This is critical because offsets vary between versions.
`ldd vuln`
Output: `libc.so.6 => /usr/lib/x86_64-linux-gnu/libc.so.6`

**Finding the ROP Gadget:** 
In 64-bit Linux, the first argument for a function must be placed in the `rdi` register. I used `ROPgadget` to find a clean instruction to pop values from the stack into `rdi`.
`ROPgadget --binary vuln | grep "pop rdi"`
Found at: `0x000000000040114a : pop rdi ; ret`

### The Exploit Strategy

#### Stage 1: The Information Leak
To defeat ASLR, I must find the randomized address of `libc` at runtime. I used the buffer overflow to hijack the control flow and call the `puts()` function, passing its own GOT (Global Offset Table) address as the argument. 

This forces the program to print the actual memory address of `puts` during that specific run. After leaking the address, the payload jumps back to `main()`. This is a crucial step: it keeps the program alive so ASLR does not randomize the addresses again.

By subtracting the static `puts` offset from the leaked address, the script dynamically calculates the current `libc` base address:
`libc.address = leaked - libc.symbols["puts"]`

#### Stage 2: Spawning the Shell
With the `libc` base address calculated, pwntools can accurately locate the `system()` function and the `"/bin/sh"` string. I sent a second payload to the restarted `main()` function:

**Stack Alignment:** I added a simple `ret` gadget at the start of the chain. This drops 8 bytes to align the stack to a 16-byte boundary. Skipping this causes a `movaps` assembly crash when advanced functions like `system()` are called.

**Argument Passing:** I popped the address of the `"/bin/sh"` string into the `rdi` register.

**Execution:** I called `system()`.

### Execution & Results
Running the exploit successfully executed the two-stage payload, bypassed both NX and ASLR, and returned an interactive shell.

`python3 exploit.py`
Output:
`[*] libc base: 0x7c37e4000000`
`[*] Switching to interactive mode`

`whoami`
Output: `miri`
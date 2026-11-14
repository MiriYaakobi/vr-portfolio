# Module 4: Binary Exploitation - Defeating Mitigations

## Exercise 1: Bypassing ASLR and NX (ret2libc)

### Security Posture & Vulnerability Analysis
I began by analyzing the binary's protections using `checksec`. The results showed that NX (No-eXecute) was enabled, while Stack Canary and PIE were disabled. 

Because NX is active, the stack is not executable, meaning I cannot inject and run custom shellcode. Furthermore, the system has ASLR (Address Space Layout Randomization) enabled, which means the `libc` library is loaded at a random, unpredictable memory address every time the program runs. To overcome these mitigations, I developed a two-stage Return Oriented Programming (ROP) attack known as ret2libc.

### Information Gathering
To perform a Code Reuse attack, I needed specific data from the local environment before writing the exploit:

**Target Library Identification:** 
I used the `ldd` command to confirm exactly which `libc` version the binary loads. This is critical because offsets vary between versions.

```bash
ldd vuln
# Output: libc.so.6 => /usr/lib/x86_64-linux-gnu/libc.so.6
```

**Finding the ROP Gadget:** 
In 64-bit Linux, the first argument for a function must be placed in the `rdi` register. I used `ROPgadget` to find a clean instruction to pop values from the stack into `rdi`.

```bash
ROPgadget --binary vuln | grep "pop rdi"
# Found at: 0x000000000040114a : pop rdi ; ret
```

### The Exploit Strategy

#### Stage 1: The Information Leak
To defeat ASLR, I must find the randomized address of `libc` at runtime. I used the buffer overflow to hijack the control flow and call the `puts()` function, passing its own GOT (Global Offset Table) address as the argument. 

This forces the program to print the actual memory address of `puts` during that specific run. After leaking the address, the payload jumps back to `main()`. This is a crucial step: it keeps the program alive so ASLR does not randomize the addresses again.

By subtracting the static `puts` offset from the leaked address, the script dynamically calculates the current `libc` base address:

```python
libc.address = leaked - libc.symbols["puts"]
```

#### Stage 2: Spawning the Shell
With the `libc` base address calculated, pwntools can accurately locate the `system()` function and the `"/bin/sh"` string. I sent a second payload to the restarted `main()` function:

**Stack Alignment:** I added a simple `ret` gadget at the start of the chain. This drops 8 bytes to align the stack to a 16-byte boundary. Skipping this causes a `movaps` assembly crash when advanced functions like `system()` are called.

**Argument Passing:** I popped the address of the `"/bin/sh"` string into the `rdi` register.

**Execution:** I called `system()`.

### Execution & Results
Running the exploit successfully executed the two-stage payload, bypassed both NX and ASLR, and returned an interactive shell.

```text
Command: python3 exploit.py

Output:
[*] libc base: 0x7c37e4000000
[*] Switching to interactive mode

Command: whoami
Output: miri
```

---

## Exercise 2: The Necessity of an Information Leak

### Why Hardcoding Fails Against ASLR
Address Space Layout Randomization (ASLR) is a security mitigation that randomizes the memory locations of the stack, heap, and dynamic libraries (like `libc`) every time a program executes. If I try to hardcode the memory address of a target function like `system()` in my exploit, the attack will fail. When the payload attempts to jump to that hardcoded address, the library will not be there, resulting in a crash (Segmentation Fault).

### How the Leak Defeats ASLR
While ASLR randomizes the starting point (Base Address) of the `libc` library, it does not alter its internal structure. The distances (offsets) between functions inside the compiled library file remain absolutely constant. 

By forcing the program to leak the real-time memory address of a known function that has already been resolved (like `puts`), I gain an anchor point. I calculate the library's actual base address by subtracting the known offset of `puts` from the leaked address. Once the dynamic base address is established, I can pinpoint the exact location of any other function (like `system()`) by adding its specific offset.

### Memory Layout Diagram
The following diagram illustrates how the internal offsets remain fixed even when the base address shifts unpredictably between runs:

```text
Run 1 (ASLR active)                           Run 2 (ASLR active)
-------------------                           -------------------
[ Random Base: 0x7f...1000 ]                  [ Random Base: 0x7f...9000 ]
       |                                             |
       | (Fixed Offset: +0x500)                      | (Fixed Offset: +0x500)
       v                                             v
[ puts() at 0x7f...1500  ] <LEAK              [ puts() at 0x7f...9500  ] <LEAK
       |                                             |
       | (Fixed Distance: +0x200)                    | (Fixed Distance: +0x200)
       v                                             v
[ system() at 0x7f...1700] <CALC              [ system() at 0x7f...9700] <CALC
```

---

## Exercise 3: The Stack Alignment Issue (movaps crash)

### The Experiment
To understand the importance of memory alignment in 64-bit exploitation, I intentionally removed the alignment gadget (`ret`) from the second stage of the ROP chain. I then executed the exploit to observe how the system responds.

### Execution & Crash Results
Without the alignment gadget, the script successfully bypassed ASLR and calculated the libc base, but it crashed immediately when attempting to execute the `system()` function.

```text
Command: python3 exploit.py

Output:
[*] libc base: 0x7f5b9d400000
[*] Switching to interactive mode
[*] Got EOF while reading in interactive
[*] Process './vuln' stopped with exit code -11 (SIGSEGV)
```

### Root Cause Analysis: The movaps Instruction
The crash (SIGSEGV) occurred due to a strict hardware requirement in the x86_64 architecture. Complex functions inside `libc`, such as `system()`, use an assembly instruction called `movaps` to move large amounts of data efficiently. 

The `movaps` instruction demands that the stack pointer (`rsp`) is perfectly aligned to a 16-byte boundary (meaning the memory address must end in `0`). During my buffer overflow, I disrupted the natural stack structure, leaving `rsp` aligned only to 8 bytes (an address ending in `8`). When `system()` tried to execute `movaps` on this unaligned stack, the physical CPU hardware rejected the operation and threw a segmentation fault.

### The Solution: A Single ret Gadget
To fix this crash, I insert a single `ret` gadget into the ROP chain right before calling `system()`. 

The `ret` instruction performs a simple action: it pops the top address from the stack and jumps to it. Because each address in a 64-bit system is exactly 8 bytes long, popping one address physically moves the stack pointer (`rsp`) exactly 8 bytes forward. 

This tiny 8-byte shift pushes `rsp` from its unaligned state (ending in `8`) to a perfectly aligned 16-byte boundary (ending in `0`). Once the stack is aligned, the `movaps` instruction executes successfully, and the shell opens.

---

## Exercise 4: Comparing system() vs. one_gadget

### The Hypothesis
As an alternative to building a multi-stage ROP chain to call `system()`, I explored using a `one_gadget` payload. A One Gadget is a specific offset within the `libc` library that directly calls `execve("/bin/sh")` in a single jump. If successful, this technique bypasses the need to manually pass arguments via registers and shrinks the payload size.

### Execution & Constraint Failures
I used the `one_gadget` tool on the target's `libc.so.6` and extracted several potential offsets. I modified my exploit script to calculate the absolute address of these gadgets, commented out the `system()` ROP chain, and injected the single address into the stack. 

However, testing the payload resulted in an immediate crash:

```text
[*] libc base: 0x721b24000000
[*] Switching to interactive mode
Done.
[*] Got EOF while reading in interactive
$ ls
[*] Process './vuln' stopped with exit code -11 (SIGSEGV) (pid 11304)
```

### Root Cause Analysis
One Gadgets are highly sensitive. Each offset requires specific memory constraints to be met at the exact moment of execution (e.g., requiring that `[r15] == NULL` or that the stack pointer is empty). 

Because my exploit relies on a Buffer Overflow that deeply corrupts the stack, it leaves residual "garbage" data scattered throughout the CPU registers. Consequently, the strict constraints demanded by the One Gadgets were consistently unmet, leading to the segmentation fault.

### Strategic Conclusion & Trade-offs
Faced with these crashes, I analyzed two potential workarounds and ultimately decided against both for professional operational reasons:

1. **Manual Register Zeroing (ROP):** I could theoretically search for additional ROP gadgets (like `pop r15; ret`) to manually clear the required registers before jumping to the One Gadget. However, doing so completely negates the primary advantage of a One Gadget: simplicity. If I must build a complex ROP chain just to satisfy constraints, it is inherently more reliable to build the standard ROP chain for `system()`, as it only requires controlling a single register (`rdi`).
2. **Brute-Forcing Offsets (Loop):** Writing a loop to automatically try every possible `one_gadget` offset is technically possible but operationally unsafe (poor OPSEC). In a real-world scenario, each failed constraint crashes the target process. Repeatedly crashing a service triggers EDR/SOC alerts and risks a Denial of Service (DoS) if the process does not restart. 

**Verdict:** The traditional `system()` ROP chain (documented in Exercise 1) proved to be the most robust, architecturally sound, and "single-shot" reliable approach for this specific exploitation scenario. I have left the `one_gadget` payload commented out in my final script to document this research attempt.
# Exercise 1: Stack Frame Mapping of `greet` Function

## 1. Stack Allocation & Growth
The stack grows **downwards** in memory (from high addresses to low addresses). When the `main` function calls `greet`, the stack frame is built in the following chronological order:

1. **Return Address:** Pushed automatically by the CPU's `call` instruction before entering the function. Because it is pushed first, it resides at the highest memory address.
2. **Saved RBP:** Pushed immediately upon entering the function via the `push rbp` prologue instruction.
3. **Buffer (`name`):** Allocated last by the `sub rsp, 0x20` instruction, which moves the stack pointer further down. Consequently, the local buffer sits at the lowest address in the frame.

## 2. Memory Layout Map (GDB Verified)

    High Addresses (Top of Frame)
    +------------------------------------+
    |  Return Address (Saved RIP)        | <-- 0x7fffffffdc88 (\$rbp + 8)
    |  0x00000000004011b9 (main+13)      |     [8 bytes]
    +------------------------------------+
    |  Saved RBP                         | <-- 0x7fffffffdc80 (\$rbp)
    |  0x00007fffffffdc90                |     [8 bytes]
    +------------------------------------+
    |  Buffer (char name[32])            | <-- 0x7fffffffdc7f (End of buffer)
    |  ...                               |
    |  ... (Grows upwards upon input)    |
    |  ...                               | <-- 0x7fffffffdc60 (Start of buffer)
    +------------------------------------+
    Low Addresses (Bottom of Frame)

### GDB Output Evidence
The following raw GDB output confirms the exact memory addresses of the buffer, the Saved RBP, and the Return Address (Saved RIP):

```text
pwndbg> p &name
$1 = (char (*)[32]) 0x7fffffffdc60

pwndbg> x/6gx $rbp
0x7fffffffdc80: 0x00007fffffffdc90  0x00000000004011b9
0x7fffffffdc90: 0x00007fffffffdd40  0x00007ffff7c2a601
0x7fffffffdca0: 0x00007fffffffdd80  0x00007fffffffddc8
```

## 3. Overflow Calculation
Based on our dynamic analysis in GDB, we can calculate the exact distance from the start of our user input to the target Return Address:

- **Buffer Start Address:** `0x7fffffffdc60` (`p &name`)
- **Return Address Location:** `0x7fffffffdc88` (`$rbp + 8`)
- **Distance:** `0x7fffffffdc88 - 0x7fffffffdc60 = 0x28` (40 bytes in decimal).

**Conclusion:** 
To successfully hijack the execution flow and overwrite the Return Address, an attacker must supply exactly **40 bytes** of padding (32 bytes to fill the buffer + 8 bytes to overwrite the Saved RBP). The 41st byte will begin overwriting the Return Address.

---

# Exercise 2: Buffer Resizing and Stack Alignment

**Goal:** Observe how modifying the buffer size from 32 to 100 bytes affects the stack frame layout.

**Observations & Evidence (Static Analysis):**
After modifying `name` to 100 bytes and recompiling, running `objdump -d -M intel mem` showed the following prologue for `greet`:

```text
0000000000401146 <greet>:
  ...
  40114a:	48 81 ec 70 00 00 00 	sub    rsp,0x70
  ...
```

**Analysis & Offset Calculation:**
1. As shown in the `objdump` output, the compiler allocated `0x70` (112 bytes in decimal) instead of 100 bytes via the `sub rsp, 0x70` instruction. 
2. This discrepancy is due to the **16-byte stack alignment rule** in the x86-64 calling convention. The compiler padded the 100-byte buffer with 12 extra bytes to align the stack pointer.
3. **New Target Distance:** Because the allocation is 112 bytes, the distance from the start of `name` to the Return Address is 112 bytes (buffer + padding) + 8 bytes (Saved RBP) = **120 bytes**. The 121st byte will start overwriting the Return Address.

---

# Exercise 3: Multiple Local Variables Layout

**Goal:** Determine the stack arrangement of multiple local variables and understand the implications for buffer overflow attacks.

**GDB Evidence:**
We printed the addresses of both buffers in GDB to determine their exact placement on the stack:

```text
pwndbg> p &buffer_A
$1 = (char (*)[16]) 0x7fffffffdc60
pwndbg> p &buffer_B
$2 = (char (*)[32]) 0x7fffffffdc40
```

**Analysis & Conclusions:**
1. **Stack Order:** Based on the GDB output, the variable declared second (`buffer_B` at `0x7fffffffdc40`) resides at a **lower memory address** than the variable declared first (`buffer_A` at `0x7fffffffdc60`). The exact distance between them is `0x20` (32 bytes).
2. **Exploitation Vector:** Because strings and inputs are written from lower to higher addresses, an overflow originating in `buffer_B` will write upwards and directly overwrite the contents of `buffer_A`. An attacker could exploit this layout to manipulate adjacent local variables before ever reaching the Return Address.

---

# Exercise 4: Buffer Overflow and Safe Input Functions

**Goal:** Observe the behavior of `fgets` when provided with input exceeding the buffer size, and understand how it handles leftover input.

**Evidence (Consecutive Reads Experiment):**
To test what happens to the characters that exceed the 32-byte limit, we added a second `fgets` call immediately after the first one:

```c
char name[32];
char extra[32];
fgets(name, sizeof(name), stdin);
printf("Hello, %s\n", name);
fgets(extra, sizeof(extra), stdin);
printf("Extra: %s\n", extra);
```

**Execution Output:**
```text
miri@vr-lab:~/vr-portfolio/01-foundations$ ./mem
Name: AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
Hello, AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
Extra: AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
```

**Analysis:**
1. **Why it didn't crash:** `fgets` safely limits the read operation to the specified boundary (`sizeof(name)` = 32). It reads exactly 31 characters and appends a null-terminator (`\0`). The Stack Frame remains completely untouched.
2. **Leftover `stdin` data:** `fgets` does *not* throw away or ignore the unread characters. The remaining characters from the line stay in the `stdin` buffer. As proven by the experiment, a subsequent call to `fgets` immediately consumes this leftover input without waiting for the user to type anything new. This is critical because uncleaned leftover input can cause unexpected behavior or vulnerabilities in programs that read multiple times.
3. **Why `fgets` is safer than `gets`:** The deprecated `gets()` function lacks boundary checking. If `gets` were used, it would have blindly written all 60 bytes into memory, overwriting the Saved RBP and the Return Address, resulting in a direct `Segmentation Fault`.

---

### Empirical Proof of `gets()` Vulnerability
To practically demonstrate the theoretical danger of unconstrained input, I modified `mem.c` to use the deprecated `gets(name)` function. To force the modern GCC compiler to compile it despite the missing header declaration, I used the `-Wno-implicit-function-declaration` flag.

**Compiler Warning:**
```text
mem.c:7:(.text+0x2d): warning: the `gets' function is dangerous and should not be used.
```

**Execution & Crash Analysis:**
```text
miri@vr-lab:~/vr-portfolio/01-foundations$ ./mem
Name: AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
Segmentation fault         (core dumped) ./mem
```

**Conclusion:** 
As predicted, feeding a large number of 'A' characters into the unconstrained `gets()` function allowed the input to overflow the 32-byte buffer. Because strings are written towards higher memory addresses, the input traversed upwards, blindly overwriting the adjacent local variables, the Saved RBP, and finally the Return Address. When `greet()` attempted to return to `main`, it jumped to an invalid memory address (0x4141414141414141), resulting in a classic `Segmentation fault`.
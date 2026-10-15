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

* **Buffer Start Address:** `0x7fffffffdc60` (`p &name`)
* **Return Address Location:** `0x7fffffffdc88` (`\$rbp + 8`)
* **Distance:** `0x7fffffffdc88 - 0x7fffffffdc60 = 0x28` (40 bytes in decimal).

**Conclusion:** 
To successfully hijack the execution flow and overwrite the Return Address, an attacker must supply exactly **40 bytes** of padding (32 bytes to fill the buffer + 8 bytes to overwrite the Saved RBP). The 41st byte will begin overwriting the Return Address.

---

# Exercise 2: Buffer Resizing and Stack Alignment

**Goal:** Observe how modifying the buffer size from 32 to 100 bytes affects the stack frame layout.

**Observations (Static Analysis):**
After modifying `mem.c` to use `char name[100];` and recompiling, the stack allocation instruction in `objdump` changed to:
`sub rsp, 0x70`

**Analysis & Offset Calculation:**
1. The compiler allocated `0x70` (112 bytes in decimal) instead of 100 bytes. 
2. This discrepancy is due to the **16-byte stack alignment rule** in the x86-64 calling convention. The compiler padded the 100-byte buffer with 12 extra bytes to align the stack pointer before subsequent function calls.
3. **New Target Distance:** To overwrite the Return Address, the attacker must traverse the new allocation and the Saved RBP:
   * Distance to RBP (Buffer + Padding): 112 bytes
   * Saved RBP size: 8 bytes
   * Total required offset: **120 bytes**. The 121st byte will start overwriting the Return Address.
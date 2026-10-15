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

## 3. Overflow Calculation
Based on our dynamic analysis in GDB, we can calculate the exact distance from the start of our user input to the target Return Address:

* **Buffer Start Address:** `0x7fffffffdc60` (`p &name`)
* **Return Address Location:** `0x7fffffffdc88` (`$rbp + 8`)
* **Distance:** `0x7fffffffdc88 - 0x7fffffffdc60 = 0x28` (40 bytes in decimal).

**Conclusion:** 
To successfully hijack the execution flow and overwrite the Return Address, an attacker must supply exactly **40 bytes** of padding (32 bytes to fill the buffer + 8 bytes to overwrite the Saved RBP). The 41st byte will begin overwriting the Return Address.
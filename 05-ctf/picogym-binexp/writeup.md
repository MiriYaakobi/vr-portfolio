# picoGym Binary Exploitation Challenges

> **Note:** The prerequisite challenge `format string 0` was already completed and documented in Module 03 (`../../03-binexp-control-flow/`). This file documents the additional Binary Exploitation challenges solved for Module 05.

## Challenge 1: PIE TIME
- **Category:** Binary Exploitation (Defeating Mitigations - PIE / ASLR Bypass)
- **Objective:** Bypass Position Independent Executable (PIE) and ASLR randomization by calculating the dynamic runtime address of the hidden `win` function using a provided memory leak (`main`), and jump to it to print the flag.
- **Pattern & Methodology:**
  Through static analysis of the provided C source code, I saw that the program prints the current runtime address of `main` (`printf("Address of main: %p\n", &main);`), reads a hexadecimal address from user input, and directly calls it as a function pointer (`foo()`). The goal is to redirect execution to the `win()` function, which opens and prints `flag.txt`. Because PIE and ASLR randomize the binary's memory location on every execution, I cannot simply use a hardcoded static address. However, the relative distance (offset) between functions inside the binary always remains constant.
1. **Static Analysis (Finding Function Addresses):** I opened the local binary in GDB and used `disassemble main` and `disassemble win` to inspect their static addresses:
   - Static `main`: `0x000000000000134c`
   - Static `win`: `0x00000000000012aa`
2. **Calculating the Static Offset:** To find the exact distance between the two functions, I subtracted the static address of `win` from the static address of `main`:
   `0x134c - 0x12aa = 0xa2`
   This means `win` is always located `0xa2` bytes before `main` in memory, regardless of where the binary is loaded.
3. **Dynamic Address Calculation:** When connecting to the remote server, the program gave me the dynamic address of `main` for that specific run: `0x63220d12e34c`. I subtracted the constant offset (`0xa2`) from this leaked address to calculate the exact runtime location of `win`:
   `0x63220d12e34c - 0xa2 = 0x63220d12e2aa`
4. **Control Flow Redirection:** I entered `0x63220d12e2aa` into the prompt. The program cast my input into a function pointer and executed `win()`, printing the flag.
- **Execution Evidence (Terminal Output):**
  ```bash
  $ nc xebec.cylabacademy.net 26523
  Address of main: 0x63220d12e34c
  Enter the address to jump to, ex => 0x12345: 0x63220d12e2aa
  Your input: 63220d12e2aa
  You won!
  academy{b4s1c_p051t10n_1nd3p3nd3nc3_2f9f2868}
  ```
- **Solution:** Used GDB to determine the static offset (`0xa2`) between `main` and `win`, then subtracted that offset from the runtime address of `main` leaked by the server to calculate the dynamic address of `win` and jump directly to it.
- **Flag:** `academy{b4s1c_p051t10n_1nd3p3nd3nc3_2f9f2868}`

---

## Challenge 2: heap 0

* **Category:** Binary Exploitation (Heap Buffer Overflow)

* **Objective:** Exploit an unbounded write into a heap-allocated buffer (`input_data`) to overflow into an adjacent heap chunk (`safe_var`) and overwrite its value so that it no longer equals `"bico"`, unlocking the flag.

* **Pattern & Methodology:**
  The program allocates two consecutive chunks on the heap using `malloc`: one for user input (`input_data`, initialized to `"pico"`) and another right after it for `safe_var` (initialized to `"bico"`). Unlike the stack, which grows toward lower addresses, the heap allocates consecutive chunks sequentially from lower to higher addresses. Because writing to a buffer also progresses toward higher addresses, an unbounded input function (`scanf("%s", input_data)`) allows writing past the first chunk directly into the second one.

1. **Inspecting the Heap Layout:** By viewing the initial heap state, I noted the exact runtime addresses of both allocations:

   * `input_data` (`pico`): `0x59f48ec952b0`

   * `safe_var` (`bico`): `0x59f48ec952d0`

2. **Calculating the Offset (Hex to Decimal & Chunk Structure):** I subtracted the address of my buffer from the address of `safe_var` to find the exact distance between them:
   `0x59f48ec952d0 - 0x59f48ec952b0 = 0x20` (which equals **32 bytes** in decimal).
   Even though the program only requested small buffers, `glibc`'s heap allocator (`ptmalloc2`) enforces a minimum chunk size of 32 bytes on 64-bit systems. This 32-byte distance includes the allocated data space, alignment padding, and the 8-byte chunk metadata header belonging to `safe_var`. *(Note: Overwriting this metadata did not crash the program here because `free()` is never called, though in real-world scenarios corrupting heap metadata would trigger a crash upon deallocation.)*

3. **Minimal Payload Construction:** To fail the `strcmp(safe_var, "bico")` check, I only needed to alter a single byte of `safe_var`. Therefore, the exact minimum payload required is **33 bytes**: 32 `'A'` characters to traverse the `0x20` offset, plus 1 `'A'` character to overwrite the first byte of `safe_var` (with `scanf` automatically appending a null terminator `\0` right after it, turning `safe_var` into `"A"`).

4. **Verification & Flag Retrieval:** I selected Option 2 (`Write to buffer`) and sent 33 `'A'` characters. Selecting Option 1 (`Print Heap`) confirmed that `safe_var` was overwritten to `A`. Since `strcmp(safe_var, "bico")` now returned a non-zero value, selecting Option 4 (`Print Flag`) passed the check and printed the flag.

* **Execution Evidence (Terminal Output):**

  ```bash
  $ nc xebec.cylabacademy.net 19649

  Welcome to heap0!
  I put my data on the heap so it should be safe from any tampering.
  Since my data isn't on the stack I'll even let you write whatever info you want to the heap, I already took care of using malloc for you.

  Heap State:
  +-------------+----------------+
  [*] Address   ->   Heap Data   
  +-------------+----------------+
  [*]   0x59f48ec952b0  ->   pico
  +-------------+----------------+
  [*]   0x59f48ec952d0  ->   bico
  +-------------+----------------+

  Enter your choice: 2
  Data for buffer: AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA

  Enter your choice: 1
  Heap State:
  +-------------+----------------+
  [*] Address   ->   Heap Data   
  +-------------+----------------+
  [*]   0x59f48ec952b0  ->   AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
  +-------------+----------------+
  [*]   0x59f48ec952d0  ->   A
  +-------------+----------------+

  Enter your choice: 4

  YOU WIN
  academy{my_first_heap_overflow_dc62a472}
  ```

* **Solution:** Calculated the `0x20` (32-byte) offset between the two adjacent heap chunks and sent a minimal 33-byte payload to overflow `input_data` and its chunk metadata, overwriting the start of `safe_var` to `"A"` and bypassing the `strcmp` check.

* **Flag:** `academy{my_first_heap_overflow_dc62a472}`
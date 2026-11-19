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

---

## Challenge 3: format string 1

* **Category:** Binary Exploitation (Format String Vulnerability - Stack Memory Leak)

* **Objective:** Exploit an unmitigated `printf(buf)` call to leak the contents of a local stack buffer (`flag[64]`) in hexadecimal format and decode it from Little-Endian into ASCII text.

* **Pattern & Methodology:**
  Static analysis of the C source code revealed that the program reads three files (`secret-menu-item-1.txt`, `flag.txt`, and `secret-menu-item-2.txt`) into local 64-byte stack buffers (`secret1`, `flag`, `secret2`). It then reads user input into `buf` and prints it directly via `printf(buf)` without a format specifier.
  My initial intuitive approach was to send a long sequence of `%p` specifiers to dump raw stack values, spot the 8-byte blocks containing ASCII-range bytes, and decode them manually. However, to solve the challenge cleanly and precisely without guesswork or noisy output, I moved to a structured debugging and extraction methodology:

1. **Dynamic Stack Mapping in GDB:** I created dummy `.txt` files locally, loaded the binary in GDB, and set a breakpoint right before the vulnerable `printf(buf)` call (`0x401327`). Running the program and inspecting the stack with `x/25gx $rsp` showed:

   * Top of the stack (`$rsp`): `0x7fffffffd590`

   * Start of the `flag` buffer: `0x7fffffffd5d0`

2. **Calculating the Exact Parameter Index:** I calculated the distance from `$rsp` to `flag`:
   `0x7fffffffd5d0 - 0x7fffffffd590 = 0x40` (**64 bytes**).
   Since each stack slot on 64-bit Linux is 8 bytes, `flag` starts `64 / 8 = 8` slots down the stack. Under the x86-64 System V calling convention, the first 5 format arguments (`%1$p` to `%5$p`) are read from registers (`rsi`, `rdx`, `rcx`, `r8`, `r9`), and `%6$p` is the first slot at `$rsp`. Therefore, the exact starting index of `flag` is:
   `6 + 8 = 14` (`%14$p`).
   Because `flag` is 64 bytes long (8 blocks of 8 bytes), its full range spans from `%14$p` to `%21$p`.

3. **Targeted Extraction (Direct Parameter Access):** Instead of dumping the entire stack, I used Direct Parameter Access (`%N$p`) with `.` delimiters to extract only the 8 blocks corresponding to `flag[64]`:
   `%14$p.%15$p.%16$p.%17$p.%18$p.%19$p.%20$p.%21$p`.
   Using `%p` safely prints 8-byte chunks without crashing the program (unlike `%s`, which would dereference the ASCII text as an invalid memory address).

4. **Little-Endian Decoding (Python One-Liner):** Inspecting the leaked blocks, the first 5 chunks contained ASCII text ending with `0x7d` (`}`), while the remaining 3 chunks were residual stack data. Because x86-64 stores multi-byte values in Little-Endian order, I used a Python one-liner to strip the `0x` prefixes, convert each hex chunk to bytes, reverse the byte order (`[::-1]`), and decode the result to ASCII.

* **Execution Evidence (Terminal Output):**

  ```
  $ nc xebec.cylabacademy.net 25419
  
  Give me your order and I'll read it back to you:
  %14$p.%15$p.%16$p.%17$p.%18$p.%19$p.%20$p.%21$p
  Here's your order: 0x7b796d6564616361.0x355f31346d316e34.0x3478345f33317937.0x31395f673431665f.0x7d646539656166.0x7fffc77e5738.0x7fffc77e5830.0xffffffff
  Bye!
  
  $ python3 -c 's="0x7b796d6564616361.0x355f31346d316e34.0x3478345f33317937.0x31395f673431665f.0x7d646539656166"; print("".join(bytes.fromhex(x[2:])[::-1].decode() for x in s.split(".")))'
  academy{4n1m41_57y13_4x4_f14g_91fae9ed}
  
  ```

* **Solution:** Mapped the stack layout in GDB to calculate the exact format string offset (`%14$p`–`%21$p`) for the local `flag` buffer, leaked the raw hex values using Direct Parameter Access, and decoded the 5 Little-Endian chunks into the flag via a Python one-liner.

* **Flag:** `academy{4n1m41_57y13_4x4_f14g_91fae9ed}`
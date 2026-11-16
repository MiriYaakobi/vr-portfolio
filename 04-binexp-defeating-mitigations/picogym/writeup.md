# picoGym Binary Exploitation Challenges

## Challenge 1: Local Target
- **Category:** Binary Exploitation (Local Variable Overwrite)
- **Objective:** Bypass an authentication check by overflowing a buffer to overwrite an adjacent local variable (`num`) on the stack, changing its integer value from 64 to 65.
- **Pattern & Methodology:**
  Through static analysis of the source code, I identified a `gets(input)` call writing into a 16-byte buffer (`char input[16]`). Because `gets()` lacks bounds checking, it allows writing past the allocated space to overwrite the adjacent `num` variable.
  1. **Finding the Offset (Dynamic Fuzzing):** I used dynamic fuzzing to find the exact overwrite offset. Sending 16 bytes did not affect `num`. By incrementing the payload length, I discovered the variable changed exactly at the 25th byte, establishing a 24-byte offset.
  2. **Stack Alignment:** The buffer is 16 bytes, but the offset is 24. This 8-byte discrepancy is due to compiler stack alignment. GCC pads variables to 16-byte boundaries for memory optimization, adding 8 bytes of invisible padding before `num`.
  3. **Payload Construction:** The goal is to change `num` to 65. In the ASCII table, the character 'A' equals 65 (`0x41`). Due to the system's Little Endian architecture, overwriting the least significant byte of `num` with 'A' perfectly sets its integer value to 65. The final payload requires exactly 25 'A's (24 to fill the buffer and padding, plus 1 to overwrite the target byte).
- **Execution Evidence (Terminal Output):**
  Given the simplicity of the payload, I utilized a terminal one-liner to pipe the string directly into the remote instance rather than writing a full Python script.

  ```bash
  $ python3 -c "print('A'*25)" | nc chatelaine.cylabacademy.net 21194
  Enter a string: 
  num is 65
  You win!
  academy{l0c4l5_1n_5c0p3_5ab331e4}
  ```
- **Solution:** A 25-byte payload of 'A' characters successfully traverses the buffer, the compiler padding, and overwrites the target variable.
- **Flag:** `academy{l0c4l5_1n_5c0p3_5ab331e4}`

## Challenge 2: PIE TIME 2
- **Category:** Binary Exploitation (Defeating Mitigations - PIE Bypass via Format String)
- **Objective:** Bypass Position Independent Executable (PIE) mitigation by leaking a memory address via a Format String vulnerability, calculating the dynamic binary base address manually, and jumping to a hidden `win` function to retrieve the flag.
- **Pattern & Methodology:**
  The binary is protected by PIE, meaning its base address is randomized at runtime, making hardcoded jumps impossible. However, the internal layout (offsets) of the binary remains static. The program contained two vulnerabilities: an unmitigated `printf(buffer)` allowing a format string attack, and a subsequent function prompt asking for a raw memory address to jump to.
  1. **Static Analysis (Offset Identification):** Using GDB, I disassembled the binary locally to find the static offsets of key functions. I identified the offset for `main` as `0x1418` and the target `win` function as `0x1376`.
  2. **Information Leak (Dynamic Anchor):** Upon executing the binary on the remote server, I fed a payload of `%p` specifiers (`%p%p%p...`) into the name prompt. This triggered the format string vulnerability, dumping raw values from the stack.
  3. **Identifying the Leak & Calculating the Base:** PIE randomizes the base address but preserves the lower 12 bits (the last 3 hexadecimal digits) of internal offsets. Examining the leaked stack values, I located `0x61ebee99f418`—which perfectly matched the `418` ending of my static `main` offset. I calculated the dynamic PIE base address by subtracting the static offset from the leaked address: 
     `0x61ebee99f418 - 0x1418 = 0x61ebee99e000`.
  4. **Target Resolution & Exploitation:** With the base address found, I added the static offset of the `win` function to determine its exact location in the current randomized runtime environment: 
     `0x61ebee99e000 + 0x1376 = 0x61EBEE99F376`. I supplied this calculated address to the jump prompt, hijacking the control flow directly into the `win` function.
- **Execution Evidence (Terminal Output):**
  ```bash
  $ nc xebec.cylabacademy.net 17159
  Enter your name:%p%p%p%p%p%p%p%p%p%p%p%p%p%p%p%p%p%p%p%p%p%p%p%p%p%p%p%p%p
  0x61ec28d6f2a10xfbad20880x7502109e7d310x61ec28d6f2db(nil)0x7ffd5238a2000x75021095e4f50x7025702570257025...0x61ebee99f418...
   enter the address to jump to, ex => 0x12345: 0x61EBEE99F376
  You won!
  academy{p13_5h0u1dn'7_134k_13db9a90}
  ```
- **Solution:** Leveraged a Format String vulnerability to leak a stack address, identified the randomized location of `main` using static offset alignment (the last 3 hex digits), calculated the dynamic PIE base, and successfully resolved the address of the `win` function to execute arbitrary code logic.
- **Flag:** `academy{p13_5h0u1dn'7_134k_13db9a90}`
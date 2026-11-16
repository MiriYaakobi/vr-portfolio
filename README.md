# Vulnerability Researcher Portfolio

This repository tracks my progress through the Cyber Security Researcher track, building from foundational concepts to real-world CVE analysis.

## Features (Work In Progress)
- [x] **Lab Setup:** Reproducible research environment configuration.
- [x] **Memory Analysis:** Stack frame mapping, stack alignment, and basic buffer overflow mechanics.
- [x] **Reverse Engineering:** Static and dynamic analysis of stripped ELF binaries, XOR-obfuscated validation, System V AMD64 calling convention, and picoGym writeups.
- [x] **Binary Exploitation (Control Flow):** Buffer overflows, Return-Oriented Programming (ROP), parameter passing, and Format String vulnerabilities.
- [x] **Binary Exploitation (Mitigations):** ASLR/NX bypass, ret2libc, Format String information leaks, and PIE dynamic base calculation.
- [ ] **CVE Analysis & Web Security:** (Under construction)

## Tech Stack
Linux, C, Python 3, x86-64 Assembly, GDB (pwndbg), pwntools, Ghidra, Docker

## Getting Started

### Prerequisites
- Ubuntu/Debian based Linux environment
- Basic build tools (gcc, make)

### Installation
```bash
git clone https://github.com/MiriYaakobi/vr-portfolio.git
cd vr-portfolio
bash setup.sh
```

### Building the Binaries
```bash
make all
make clean
```

## Running Exploits

### Module 03: Control Flow (ret2win)
To test the basic buffer overflow and advanced ROP payloads, use the automated integration test script:
```bash
cd 03-binexp-control-flow/ret2win
chmod +x test_ret2win.sh
./test_ret2win.sh
```
*(Alternatively, compile manually with `gcc -fno-stack-protector -no-pie vuln.c -o vuln` and run `python3 exploit.py`)*

### Module 04: Defeating Mitigations (ret2libc)
To run the robust, state-based integration test for ASLR/NX bypass and stack alignment constraints:
```bash
cd 04-binexp-defeating-mitigations/ret2libc
gcc -fno-stack-protector -no-pie vuln.c -o vuln 2>/dev/null
chmod +x test_ret2libc.sh
./test_ret2libc.sh
```

## Project Structure
```text
00-lab-setup/                   # Reproducible lab environment setup
01-foundations/                 # Stack memory layout, GDB static/dynamic analysis, and overflow concepts
02-reverse-engineering/         # Ghidra, GDB/pwndbg, and picoGym evidence; see 02-reverse-engineering/writeup.md
03-binexp-control-flow/         # ret2win, ROP with args, Canary impact, Format String; see writeup.md
04-binexp-defeating-mitigations/ # ASLR/NX bypass in ret2libc/, picoGym challenges (local-target, pie-time-2) in picogym/; see main writeup.md
05-ctf/                         # (Pending)
06-web/                         # (Pending)
07-cve-analysis/                # (Pending)
08-methodology/                 # (Pending)
```

## What I Learned
- **Module 01 (Foundations):** Mastered x86-64 stack frame layout, compiler stack alignment, and static/dynamic memory analysis using GDB/pwndbg. Practically demonstrated buffer overflow vulnerabilities by exploiting unconstrained input bounds.
- **Module 02 (Reverse Engineering):** Reverse-engineered stripped ELF binaries and Python scripts. Bypassed XOR obfuscation, analyzed System V AMD64 calling conventions, and extracted secrets using static (Ghidra) and dynamic (GDB) analysis.
- **Module 03 (Binary Exploitation - Control Flow):** Executed control flow hijacking via stack buffer overflows. Calculated exact offsets dynamically using pwntools, corrected 64-bit stack alignment issues (SSE/movaps) using ROP gadgets (`ret`), demonstrated the crash impact of Stack Canaries, built advanced ROP chains to pass arguments via registers (`RDI`), and exploited Format String vulnerabilities to intentionally crash a remote server and extract flags.
- **Module 04 (Binary Exploitation - Defeating Mitigations):** Bypassed modern memory protections (ASLR, NX, PIE). Developed ret2libc ROP chains to spawn shells, solved CPU stack alignment constraints (`movaps`), and leveraged Format String vulnerabilities to dynamically calculate randomized base addresses at runtime.
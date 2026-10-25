# Vulnerability Researcher Portfolio

This repository tracks my progress through the Cyber Security Researcher track, building from foundational concepts to real-world CVE analysis.

## Features (Work In Progress)
- [x] **Lab Setup:** Reproducible research environment configuration.
- [x] **Memory Analysis:** Stack frame mapping, stack alignment, and basic buffer overflow mechanics.
- [x] **Reverse Engineering:** Static analysis (Ghidra), dynamic analysis (GDB), and algorithmic reversing (Python).
- [ ] **Binary Exploitation:** (Under construction)
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
*(Under construction - will be updated as exploits are developed)*

## Project Structure
```text
00-lab-setup/                   # Reproducible lab environment setup
01-foundations/                 # Stack memory layout, GDB static/dynamic analysis, and overflow concepts
02-reverse-engineering/         # Static/Dynamic analysis, crackmes, XOR obfuscation, and picoGym challenges
03-binexp-control-flow/         # (Pending)
04-binexp-defeating-mitigations/# (Pending)
05-ctf/                         # (Pending)
06-web/                         # (Pending)
07-cve-analysis/                # (Pending)
08-methodology/                 # (Pending)
```

## What I Learned
- **Module 01 (Foundations):** Mastered x86-64 stack frame layout, compiler stack alignment, and static/dynamic memory analysis using GDB/pwndbg. Practically demonstrated buffer overflow vulnerabilities by exploiting unconstrained input bounds.
- **Module 02 (Reverse Engineering):** Reverse-engineered stripped ELF binaries and Python scripts. Bypassed XOR obfuscation, analyzed System V AMD64 calling conventions, and extracted secrets using static (Ghidra) and dynamic (GDB) analysis.
# Lab Environment Setup

## 1. Virtualization Infrastructure
- **Hypervisor:** VirtualBox (Version: 7.2.20)
- **Guest OS:** Ubuntu 25.04 (Plucky Puffin) 64-bit
- **Resources:** 4GB RAM, 2 CPU Cores, 30GB Disk
- **System Tweaks:** Video Memory (VRAM) increased to 128MB to prevent Wayland/UI freezing.

## 2. Toolchain Installation
**Base Tools & Dependencies:**
`sudo apt update && sudo apt install -y build-essential gdb git python3 python3-pip python3-venv docker.io docker-compose-v2 cmake pkg-config`

**Advanced Tools:**
- **pwndbg:** Installed via `git clone https://github.com/pwndbg/pwndbg` and `./setup.sh`.
- **pwntools:** Installed in isolated virtualenv (`~/vr-venv`). 
  *Setup:* `python3 -m venv ~/vr-venv && source ~/vr-venv/bin/activate`
  *Fix for GCC 15 compatibility:* Compiled using `CFLAGS="-Wno-implicit-function-declaration" pip install pwntools`.
- **Ghidra:** Installed via modern package manager due to apt deprecation: `sudo snap install ghidra`.
- **Permissions:** Added user to docker group (`sudo usermod -aG docker $USER`).

**Installed Tool Versions:**
- **gcc:** 15.2.0
- **gdb:** 17.1
- **Python3:** 3.14.4
- **pwntools:** 4.15.0
- **Docker:** 29.1.3
- **Ghidra:** 12.1.2

## 3. Remote VS Code Configuration
- **Editor:** Visual Studio Code (Windows Host)
- **Workflow:** Code edited locally on Windows and synced to the Ubuntu VM via Git/GitHub.
- **Terminal:** Integrated VS Code terminal used for Git operations and file management.

## 4. Platform Accounts
- **picoCTF:** MiriYaakobi
- **pwn.college:** Miri Yaakobi
- **PortSwigger:** Miri Yaakobi

## 5. System Snapshots
- **Current Baseline:** `Lab-00-Base-Installation-Complete`
- **Why keep a clean state?** I created this lab specifically to run and research potentially malicious programs and code. Since these can easily damage or destroy the system, I save a snapshot right after finishing all the installations. This gives me a clean, ready-to-use environment to start my research.
- **When to revert to this snapshot:**
  1. If a program damages the system or something goes wrong, I can easily go back to the previous state and try a different approach.
  2. After successfully finishing a lab where I had to break or change various things to succeed. Reverting lets me return to my clean starting point so I can continue my work normally.
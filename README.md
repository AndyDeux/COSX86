# 💾 **Custom x86 Operating System**


![OS](https://github.com/user-attachments/assets/75b7c378-3f0f-4a47-a9f1-0e14b996470a)



**This project has been an intriguing exploration into low-level programming, where I’ve worked with an x86 assembler in 16-bit mode, simulating the environment of a 16-bit 8086 processor. What began as a free-time experiment to grasp the fundamentals of computer operation evolved into a foundational barebone custom x86 operating system developed from scratch. This journey has allowed me to dive deep into assembly language, C, and various emulation and debugging tools, furthering my understanding of operating system internals.**

### 🚀 Journey:
The project started with creating a basic bootloader, written in assembly, that initializes the system and loads a simple kernel. This was followed by implementing a FAT12 filesystem in C, which allows the operating system to read files from a floppy disk image. The kernel currently supports basic text output and can read and display content from .txt files.

### 🛠️ Challenges:
Building this OS from the ground up presented several challenges. Writing the bootloader and kernel in assembly required meticulous attention to detail, particularly in handling BIOS interrupts and managing memory. Another significant challenge was implementing the FAT12 filesystem, which involved understanding and working disk sectors directly.

### ⚙️ Current Functionalities

- Bootloader: Successfully loads the bootloader.
- Kernel Loading: The bootloader loads the kernel into memory.
- FAT12 Initialization: Kernel initializes the FAT12 file system.
- String Printing: Capable of printing a string directly from within the assembly code.
- Text File Printing: Capable of printing text from a .txt file.


## 💻 Tech Stack Overview 🛠️


```plaintext
┌──────────────────────┐
│      Assembly        │
│  (Bootloader)        │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐     ┌─────────────────────┐
│        C             │     │     QEMU            │
│  (Kernel & FAT12)    │◄───►│  (Emulation)        │
└──────────┬───────────┘     └──────────┬──────────┘
           │                             │
           ▼                             │
┌──────────────────────┐     ┌───────────▼─────────┐
│     Makefile         │     │      Bochs          │
│  (Build Automation)  │     │   (Debugging)       │
└──────────────────────┘     └─────────────────────┘
```

 - Assembly: Used for the bootloader and low-level system initialization.
 - C: Used for the kernel and implementing the FAT12 file system.
 - QEMU: A fast processor emulator that allows running the operating system in a virtual environment.
 - Bochs: A more detailed x86 PC emulator that I used for debugging.
 - Makefile: Automates the build process, making it easy to compile and run the OS.


## 📦 Modules & Tools Required

To work on this project, you’ll need the following tools and modules installed:

```bash
# Install QEMU for emulation
sudo apt-get install qemu

# Install Bochs for debugging
sudo apt-get install bochs bochs-sdl

# Optional: NASM assembler for assembling the bootloader
sudo apt-get install nasm
```

## Directory Structure:

- boot.asm: The bootloader written in assembly. It sets up the initial environment and loads the kernel.
- kernel.c: The main kernel code written in C. It handles basic system functions and file reading.
- Makefile: Automates the assembly and compilation of the bootloader and kernel.
- run.sh: A script to run the operating system using QEMU.
- debug.sh: A script to run Bochs for debugging purposes.

```plaintext
.
├── Makefile
├── README.md
├── Test.txt
├── bochs_config
├── build
│   ├── bootloader.bin
│   ├── kernel.bin
│   ├── main.asm
│   ├── main.bin
│   ├── main_floppy.img
│   └── tools
│       ├── fat
│       └── fat.dSYM
│           └── Contents
│               ├── Info.plist
│               └── Resources
│                   ├── DWARF
│                   │   └── fat
│                   └── Relocations
│                       └── aarch64
│                           └── fat.yml
├── debug.sh
├── run.sh
├── src
│   ├── bootloader
│   │   └── boot.asm
│   └── kernel
│       └── main.asm
└── tools
    └── fat
        └── fat.c
```

## 📝 Code Snippet: Bootloader

Here’s a glimpse of the bootloader

```asm
org 0x7C00
bits 16

%define ENDL 0x0D, 0x0A

jmp short start
nop

bdb_oem: db 'MSWIN4.1' ; 8 bytes
bdb_bytes_per_sector: dw 512
bdb_sectors_per_cluster: db 1
bdb_reserved_sectors: dw 1
bdb_fat_count: db 2
bdb_dir_entries_count: dw 0E0h
bdb_total_sectors: dw 2880 ; 2880 * 512 = 1.44MB
bdb_media_descriptor_type: db 0F0h
bdb_sectors_per_fat: dw 9
bdb_sectors_per_track: dw 18
bdb_heads: dw 2
bdb_hidden_sectors: dd 0
bdb_large_sector_count: dd 0

; Extended boot record (EBR)
ebr_drive_number: db 0 ; 0x00 floppy, 0x80 hdd, not much use
db 0 ; reserved
ebr_signature: db 29h
ebr_volume_id: db 12h, 34h, 56h, 78h ; serial number, value does not matter
ebr_volume_label: db 'ANDR OS ' ; 11 bytes, padded with spaces
ebr_system_id: db 'FAT12 ' ; 8 bytes

start:
    ; Setting up data segments
    mov ax, 0
    mov ds, ax
    mov es, ax

    ; Setting up the stack
    mov ss, ax
    mov sp, 0x7C00

    ; Some BIOSes can load the memory location wrongly such as 07C0:0000 instead of 0000:07C0. You have to be sure you start reading from the right location
    push es
    push word .after
    retf

.after:
    ; ... (rest of the bootloader code) ...
```

The bootloader here initializes the system, reads the FAT12 filesystem, and loads the kernel into memory.

## 🛠️ Running the OS

To run the operating system:

1. Compile and assemble:

```bash
make all
```

2. Run the OS using QEMU:

```bash
./run.sh
```

3. Debug the OS using Bochs:

```bash
./debug.sh
```

## 🛠️ Future Enhancements

- Switching to 32-bit Protected Mode: Implement the transition from 16-bit Real Mode to 32-bit Protected Mode for better memory management and security features.
- Multi-tasking: Enable the OS to handle multiple processes concurrently, paving the way for more complex and efficient operations.
- File System Expansion: Extend support to more complex file systems like FAT32 or ext2 to improve storage capabilities and compatibility.
- Graphical User Interface (GUI): Develop a basic GUI to enhance user interaction with the system, making it more accessible and visually appealing.

But all in due time! This is a project I recently started with the goal of gaining a deeper understanding of how computers operate. It’s just the beginning, I have many more functionalities planned for the future!

![SimCoupe-Debugger-Step-Over](https://github.com/user-attachments/assets/4da6e481-a175-48e0-b67c-28da2a9e6ecc)



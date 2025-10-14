---
title: Linux Memory Management - Part 2
date: 2025-10-14
author: Manvik Nanda
---
So far, we’ve explored the hierarchy, data structures, and allocators that form the backbone of Linux’s memory management system. However, we haven’t yet touched on the key abstraction that enables a system with limited physical RAM to run hundreds or even thousands of processes simultaneously — the virtual address space.

## What is the virtual address space?
Virtual address space (VAS) is the answer to the `question`:  
<span style="color:#fff9c4; border-radius:6px;">
How can so many processes coexist and run independently on a machine with limited RAM?
</span>


A virtual address is the memory address that a process thinks it is accessing.
Instead of working directly with raw physical addresses (the actual RAM locations), each process operates within its own private address space.

This means when two processes both access address `0x400000`, they’re not touching the same physical memory (RAM) — they’re accessing entirely different locations mapped by the kernel.
```css
 Process A (VAS)              Physical RAM              Process B (VAS)
------------------           ---------------           ------------------
0x400000  ─────────────▶      [ Frame #5 ]      ◀────────────  0x400000
```

### What is `0x400000` ?
In Linux (and most systems), memory addresses are written in hexadecimal (base-16) form — a compact way to represent binary numbers. So, `0x400000` translates to `0100 0000 0000 0000 0000 0000` in binary. It’s far easier to read and reason about than long strings of 0s and 1s — so we leave the binary details to the machine and work with hex instead. 

Try to think, why not use decimal, yes the system we use to count money?  
`Hint` The answer lies in the ability to use a single digit for a group of bits! 

### In x86_64...
Intel's x86_64 is a 64-bit architecture, that essentially means, it holds pointers to memory locations 64 bits long. So, you can have up to 2<sup>64</sup> different addresses. This means our virtual address space on a 64-bit system ranges from `0x0` - `0xffffffffffffffff`.  

## Why virtual addresses?
Some questions to ask here are:
* Why virtual addresses in the first place? 
* Why can't we allow processes to interact with the physical memory directly?
* Is the added complexity worth it?
* Who handles these translations?

If every process were allowed to access physical memory directly, the entire system would quickly descend into chaos.

* Lack of isolation: Every process sharing the same address space, a buggy pointer dereference could crash the entire system
* No Flexibility or Abstraction: Virtual memory gives each process the illusion of a large, contiguous address space, independent of physical RAM size. Debugging would be a nightmare! 

Before jumping into who handles this translation, let us analyze the VAS in a bit more detail. 
The VAS is basically split into User and Kernel VAS:
```css
0x0000_0000_0000_0000 ────────────────────────┐
│                 User Space                 │
│     (per-process virtual memory)           │
├────────────────────────────────────────────┤
│                [ Unmapped Gap ]            │
│        (no valid mappings, guard area)     │                             │
├────────────────────────────────────────────┤
│                 Kernel Space               │
│     (shared across all processes)          │
0xffff_ffff_ffff_ffff ────────────────────────┘
```
### Umm, why kernel mapping in my process address space?
Well, When a user process calls a kernel service (like `read()`, `write()`, or `open()`):
* The CPU switches from user mode → kernel mode (via an interrupt or syscall instruction).
* But the address space stays the same — only the privilege level changes.
* This allows the kernel to immediately start executing code in the same address space (at higher addresses).

The kernel is loaded into physical memory only once, but every process’s virtual address space contains a mapping to that same kernel image.
<span style="color:#ff8a65; border-radius:6px;">
In other words, there’s an M : 1 relationship — M user processes, one shared kernel.
</span>

We’ll save the details of system calls and interrupts for another post — they’re fascinating but involve a lot of moving parts.

For now, remember this: <span style="color:#fff9c4; border-radius:6px;">syscalls are how your program communicates with the operating system whenever it needs to perform a privileged action</span> — such as reading a file, writing to the network, or creating a new process.
Your code typically runs in user mode, where it cannot access hardware or sensitive parts of memory. When a system call occurs, the CPU switches into kernel mode, giving the OS the higher privileges it needs to perform the requested action safely.
That’s also why the kernel is mapped into every process’s address space — so the CPU knows precisely where to jump when a syscall or interrupt occurs.

## Ok, ok, but where are these mappings stored? Answer: `Page Tables`!
```css
Virtual Address
   │
   ▼
┌───────────┐
│   PML4    │  ← top-level table
└────┬──────┘
     │  (index selects entry)
     ▼
┌───────────┐
│   PDPT    │  ← page-directory-pointer table
└────┬──────┘
     │
     ▼
┌───────────┐
│    PD     │  ← page directory
└────┬──────┘
     │
     ▼
┌───────────┐
│    PT     │  ← page table
└────┬──────┘
     │
     ▼
┌───────────┐
│  Physical │  ← final 4 KB page frame in RAM
│   Frame   │
└───────────┘
```
Every time a process accesses memory using a virtual address, the CPU doesn’t use it directly.
Instead, it consults a set of page tables — <span style="color:#fff9c4; border-radius:6px;">data structures managed by the operating system</span> — to find out which physical memory location that virtual address maps to.

Each entry in the page table (called a PTE) contains:
* The physical frame number (PFN) — the actual location in RAM.
* Access flags — like read/write permissions or whether the page is present in memory.

Note: All these translations are handled by the MMU (Memory Management Unit)

The implementation is highly architecture-dependent due to the close interaction between hardware and software, so details can vary significantly across platforms. Some key data structures include `pgd_t`, `pud_t`, `pmd_t`, and `pte_t`, which represent different levels of the page table hierarchy.

Example entry of [`riscv`](https://elixir.bootlin.com/linux/v6.11-rc7/source/arch/riscv/include/asm/page.h#L63) architecture:
```c
/* Page Global Directory entry */
typedef struct {
	unsigned long pgd;
} pgd_t;

/* Page Table entry */
typedef struct {
	unsigned long pte;
} pte_t;

typedef struct {
	unsigned long pgprot;
} pgprot_t;

typedef struct page *pgtable_t;
```

That brings us to the end of our series on Linux Memory Management.
There’s still plenty more to explore — topics like `system calls`, `interrupt handling`, and `memory cgroups` each deserve their own deep dive. Thanks for reading, and I hope this series gave you a clearer mental model of how Linux juggles memory behind the scenes.

Stay tuned — more deep system explorations are on the way!
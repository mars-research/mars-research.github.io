
---
title: Atmosphere Verified Operating System
aliases:
- /atmo

ShowReadingTime: false
---

Atmosphere is a full-featured microkernel developed in Rust and verified with
Verus. Conceptually Atmosphere is similar to the line of L4 microkernels.
Atmosphere pushes most kernel functionality to user-space, e.g., device
drivers, network stack, file systems, etc. The microkernel supports a minimal
set of mechanisms to implement address spaces, page-tables, coarse-grained
memory management, and threads of execution that together with address spaces
implement an abstraction of a process. Each process has a page table and a
collection of schedulable threads. Atmosphere allows threads to control layout
of their virtual address space through a collection of system calls that
support mapping and unmapping pages as well as receiving pages from other
threads via communication endpoints. To simplify verification, at the moment
Atmosphere relies on a big-lock synchronization.

We develop all code in Rust and prove its functional correctness, i.e.,
refinement of a high-level specification with Verus (a Dafny-like automated
verification engine for Rust).  Similar to prior work, we carefully design the
kernel to keep verification complexity under control.  Still, Verus allows us
to implement typical kernel data structures like linked lists, support verified
memory allocation, develop proofs about page tables, etc. 

A combination of Verus and Rust significantly reduces verification effort. On
average our code has proof-to-code ratio of 7.5:1 which is significantly lower
than in prior approaches. Moreover, Rust and Verus allow us to reason about a
microkernel with a feature-rich interface that is conceptually similar to the
line of classical L4 microkernels.

# Publications

* Xiangdong Chen, Zhaofeng Li, Jerry Zhang, Vikram Narayanan, Anton Burtsev.
[Atmosphere: Practical Verified Kernels with Rust and Verus](/doc/2025-sosp-atmo.pdf). 
In _Proceedings of the 1st ACM Symposium on Operating Systems Principles (SOSP 2025)_, October 2025.

* Xiangdong Chen, Zhaofeng Li, Sylvia (Lukas) Mesicek, Vikram Narayanan and Anton Burtsev.
[Atmosphere: Towards Practical Verified Kernels in
Rust](/doc/2023-kisv-atmo.pdf). In _Proceedings of the 1st Workshop on Kernel
Isolation, Safety and Verification (KISV 2023)_, October 2023.


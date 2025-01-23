
---
title: Hardware Support for Lightweight Isolation
aliases:
- /ipc

ShowReadingTime: false
---

A surge in the number, complexity, and automation of targeted security attacks
has triggered a wave of interest in hardware support for isolation. Memory
Protection Keys (MPK), Extended Page-Table (EPT) switching with VM functions
(VMFUNC), ARM Memory Tagging Extensions (MTE), and pointer authentication
(PAC), and even Morello CHERI capabilities that are deployed in recent CPUs
provide support for memory isolation with overheads gradually approaching the
overhead of a function call.  Hence these new mechanisms bring a promise of
practical isolation of small untrusted extensions and third-party code that
require frequent communication with the rest of the system.  

Unfortunately, we argue, that while a huge step forward, modern isolation
mechanisms still lack multiple conceptual features that limit their
practicality. ARM PAC and ARM MTE are inherently limited by the overhead of
additional instructions that are needed to enforce the isolation of heaps.
Intel MPK suffers from the inability to reflect the passing of zero-copied
memory regions across all cores of the system, which results in either a
restrictive programming model (the buffers passed on one core cannot be
accessed from other cores) or expensive cross-core synchronization similar to
TLB shootdown. Tag-based schemes like MPK and MTE suffer from the limitation on
the number of isolated subsystems.  Additionally, MTE suffers from the overhead
of retagging which in our experiments is only marginally faster than copying.
Capability schemes like CHERI are inherently limited by the lack of centralized
metadata that is required for implementing revocation of rights and "move"
semantics, i.e., ensuring that the caller loses access to the objects on the
heap that are passed to the callee. Hardware architectures that keep access
rights in registers, e.g., Intel MPK and CHERI, are facing another inherent
limitation: it is impossible to perform revocation of rights across the cores
(active capabilities can be retained in registers of other cores). 

Our current work (which is a collaboration with the [Utah
Arch](https://arch.cs.utah.edu/) group) is aimed at identifying a set of
principles and mechanisms that are critical for the design of practical,
low-overhead isolation mechanisms with support for efficient zero-copy
communication. Specifically, our [initial research](./ipc) argues that hardware
should support: software transparency (an idea that architectural mechanisms
should avoid relying on expensive compiler instrumentation which becomes
prohibitive in modern systems), core-coherent synchronization of rights, and
revocation. 

We plan to explore the possibility of implementing these principles in hardware
as a collection of isolation mechanisms aimed at fine-grained, low-overhead
isolation.  


# Publications

Xiangdong Chen, Zhaofeng Li, Tirth Jain, Vikram Narayanan, Anton Burtsev. 
[Limitations and Opportunities of Modern Hardware
Isolation Mechanisms](/doc/2024-atc-hw-isolation.pdf). In _Proceedings of the
2024 USENIX Annual Technical Conference (USENIX ATC)_, July 2024.



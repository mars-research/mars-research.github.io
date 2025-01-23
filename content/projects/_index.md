---
title: Projects
ShowBreadCrumbs: false
---

## Atmosphere verified operating system

[Project page](./atmo)

Despite decades of progress, the development of formally-verified operating
systems remains a challenging undertaking that relies on a strong verification
expertise and all too often requires years of human effort.  Development of the
first verified microkernel, seL4, required a heroic effort.  Our work argues
that recent advances in programming languages and automated formal reasoning
change the threshold of practical development of verified kernel code.
Specifically, in this work, we demonstrate the possibility of developing a
fully-verified microkernel, Atmosphere, at the speed and effort that approach
commodity unverified development. 

We developed all code in Rust and proved its functional correctness, i.e.,
refinement of a high-level specification, with Verus, a recent verifier for
Rust. Development of Atmosphere took less than a calendar year and an effort of
roughly two person-years.  Two key breakthroughs enable the practical
development of verified systems code. First is the idea of combining linear
types with automated verification based on satisfiability modulo theories (SMT)
linear types significantly lower the burden of reasoning about the heap, and
pointer aliasing, and provide an elegant way to construct proofs about
pointers.  Second is native support for verification toolchain in a programming
language designed for systems development, i.e., Rust, which provides a high
degree of development automation along with the ability to compile and execute
verified code on bare metal.  

[Atmosphere is an ongoing research](./atmo) that uses our prior work on
[RedLeaf operating system](./redleaf) and is supported by the Amazon Faculty
Research Award and the National Science Foundation (CAREER Award).

## VELD: Practical verification of commodity kernel extensions 

[Project page](./veld)

Device drivers and other kernel extensions are one of the major sources of
vulnerabilities in modern operating systems. Developed by third-party device
vendors that often have only a partial understanding of the kernel's
programming and security idioms, device drivers have long been considered a
primary source of defects within modern OS kernels. For decades, system
researchers have been trying to reduce the impact of device driver
vulnerabilities by suggesting numerous device driver isolation mechanisms
ranging from hardware protection (including our work on (LXDs)[./lxds],
(LVDs)[./lvds]), to software fault isolation.  

Unfortunately, attempts to introduce isolation in the kernel were not
successful due to high performance overheads, significant complexity of
isolation, and questionable security gains.  Today, however, the Linux kernel
community turned to an alternative approach -- low-overhead safe programming
languages, and, specifically the possibility of implementing device drivers in
Rust.  Rust-for-Linux (RFL) is a device driver framework for Linux that enables
development of device drivers in Rust and in most cases in safe Rust.  At a
high level, RFL develops Rust bindings for each kernel subsystem, e.g.,
network, NVMe, etc., in a backward-compatible manner.  Device drivers can use
the same (or slightly changed) kernel interface through a safe Rust binding
hence enjoying memory and temporal safety offered by Rust.  

RFL offers a practical way of developing formally verified device drivers with
the combination of Rust programming language and Verus verifier. RFL provides a
clean way to integrate verified code into the Linux kernel. Moreover, our
experience with Verus demonstrates that verification is practical. The
challenge is the development of specifications for the kernel-driver and
driver-device interface as it is more time-consuming than verification of the
driver logic.  

[Verification of device drivers in the Linux kernel](./veld) is an ongoing
work.  We are in the process of developing the first verified driver
prototypes.

## Evolving operating systems towards secure isolation boundaries 
[Project page](./hardware-isolation)

Recent breakthroughs in hardware support for low-overhead isolation and our own
work on automating isolation of legacy code ([KSplit](./ksplit])) addressed two
key challenges -- performance and complexity -- that were a historical
roadblock on the way of adopting isolation in commodity operating system
kernels. We will likely see some adoption of isolation in mainline kernels like
Linux.

A natural question, however, is what kind of security guarantees are achieved
by kernel isolation frameworks such as our work on [LVDs](./lvds)
[LCDs](./lcds) and numerous others?  Unfortunately, even using the most
advanced isolation boundary approaches that enforce temporal memory safety
across the isolation boundary, the kernel can be attacked in numerous ways (see
for example our HotOS'23 paper). An attacker that has a write primitive inside
an isolated subsystem cannot access the state of the kernel but can modify the
data shared with the kernel (fields of the heap objects, return values, and
function arguments) triggering a variety of unsafe behaviors, violating data
structure invariants and breaking protocols of the driver-kernel interface.

After nearly a decade of working on practical kernel isolation, our team now
explores the principles of secure isolation, i.e., an isolation boundary that
prevents cross-boundary attacks.

## Hardware support for fine-grained isolation

[Project page](./ipc)

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

## DRAMHiT: Hash-table designed for the speed of DRAM

[Project page](./dramhit)

Despite decades of innovation, existing hash tables fail to achieve peak
performance on modern hardware. Built around a relatively simple computation,
i.e., a hash function, which in most cases takes only a handful of CPU cycles,
hash tables should only be limited by the throughput of the memory subsystem.
Unfortunately, due to the inherently random memory access pattern and the
contention across multiple threads, existing hash tables spend most of their
time waiting for the memory subsystem to serve cache misses and coherence
requests.

DRAMHiT is a new hash table designed to work at the speed of DRAM.
Architecting for performance, we embrace the fact that modern machines are
distributed systems ? while the latency of communication between the cores is
much lower than in a traditional network, it is still dominant for the hash
table workload. We design DRAMHiT to apply a range of optimizations typical for
a distributed system: asynchronous interface, fully-prefetched access, batching
with out-of-order completion, and partitioned design with a low-overhead,
scalable delegation scheme. DRAMHiT never touches unprefetched memory and
minimizes the penalty of coherence requests and atomic instructions. These
optimizations allow DRAMHiT to operate close to the speed of DRAM. On uniform
key distributions, DRAMHiT achieves 973Mops for reads and 792Mops for writes on
64-thread Intel servers and 1192Mops and 1052Mops on 128-thread AMD machines;
hence, outperforming existing lock-free designs by nearly a factor of two.

We are currently working on the new version of DRAMHiT -- an even faster one. 

## Operating system support for heterogeneous hardware 

Despite the rapid evolution of modern hardware -- introduction of
sub-microsecond network interfaces and low-latency network switches,
low-latency PCIe-attached flash storage, multi-terabyte memories, multi-core
CPUs, and massively parallel GPUs -- modern large-scale scientific and
enterprise workloads hit the computational limits of commodity machines. In
contrast to today's systems centered around general-purpose CPUs, future
datacenter architectures will inherently rely on heterogeneous hardware ranging
from many-core processors to specialized ASICs, and programmable FPGA.
Designed for a specific task, and hence, requiring only a fraction of the
traditional hardware budget, heterogeneous accelerators offer superior power
efficiency and massively parallel processing for many computationally-intensive
tasks ranging from traditional HPC simulations to machine learning and data
analytics. 

Despite the tremendous progress made in the general availability and
programmability of hardware accelerators, they remain largely impossible to
program as a whole. In a hardware-accelerated environment, the execution of a
program is no longer a conventional thread tied to a single general-purpose
CPU, but a collection of small computations scheduled on a set of hardware
execution units each implementing a part of the program logic. The inherently
distributed nature of the system latency of moving execution between hardware
units, pervasive parallelism, non-uniform access latencies to memories and
storage, and non-uniform compute capacity of individual execution units and
lack of unified operating system support makes it challenging to achieve peak
performance especially if the system is dynamically shared across multiple
workloads.  

RedShift is a new operating system for developing massively parallel
applications on hardware-accelerated systems. RedShift enables a new
architectural paradigm: ubiquitous, fine-grained, heterogeneous hardware
acceleration. RedShift defines a new abstraction of a hardware-accelerated
process that implements programs as collections of asynchronous invocations
transparently moving execution between hardware functions. At the core of
RedShift is a dataflow programming model that enables execution of commodity
programs on a network of heterogeneous hardware execution units.  

RedShift is an ongoing research project which in the past was funded by the
National Science Foundation. 



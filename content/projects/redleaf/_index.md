---
title: RedLeaf
aliases:
- /redleaf
summary: A research operating system developed from scratch in Rust, aimed to explore the impact of language safety on operating system organization.

ShowReadingTime: false
---

<img src="images/redleaf.png" height="400px"/>

RedLeaf is a new operating system aimed at leveraging a safe, linear-typed
programming language, Rust, for developing safe and provably secure systems.
RedLeaf builds on two premises: (1) Rust\'s linear type system enables practical
language safety even for systems with the tightest performance and resource
budgets, e.g., OS kernels and firmware, (2) a combination of SMT-based
reasoning and pointer discipline enforced by linear types provides a way to
automate and simplify verification effort and scale it to the size of a small
operating system kernel that can run firmware subsystems. 

There are two main lines of the project: 1) leveraging language safety for
exploring its impact on operating system organization, and 2) leveraging
properties of linear types for verification. 

## Clean-Slate Safe Kernels

Since early computer systems developed five decades ago overheads of language
safety remain prohibitive for development of operating system kernels. Today,
we run kernels developed in C. Unfortunately, the choice of C, an unsafe
low-level programming language, as the de facto standard for kernel development
contributes to several hundred vulnerabilities a year.

Recently, however,  the performance landscape of safe languages is starting to
change with the development of programming languages like Rust that achieve
safety without garbage collection. Rust is the first practical language that
combines an old idea of linear types with pragmatic language design. Rust
enforces type and memory safety through a restricted ownership model, where
there exists a unique reference to each live object in memory. This allows
statically tracking the lifetime of the object and deallocating it without a
garbage collector. Rust represents a unique point in the language design space,
bringing the benefits of type and memory safety to systems that cannot afford
the cost of garbage collection. The runtime overhead of the language is limited
to bounds checking, which is often hidden by modern superscalar out of order
CPUs.

In contrast to commodity systems, RedLeaf does not rely on hardware address
spaces for isolation and instead uses only type and memory safety of the Rust
language. Departure from costly hardware isolation mechanisms allows us to
explore the design space of systems that embrace lightweight fine-grained
isolation. 

RedLeaf is designed as a microkernel system in which a collection of language
domains implement functionality of the system: kernel subsystems, device
drivers, and user applications. 

Rust provides systems developers with mechanisms we were all waiting for for
decades: zero-cost language safety and a type system that enforces ownership.
We argue that Rust’s language safety allows us to enable many classical ideas
of operating system research for the first time in a practical way. 

## Verification

RedLeaf provides a Floyd-Hoare-style modular verification (i.e., based on
pre-conditions, post-conditions, and loop invariants) for low-level systems
that are designed to be fast and small. It achieves that by developing a new
verification toolchain built on the SMACK verifier, Boogie intermediate
verification language, and Z3 SMT solver.

In RedLeaf the choice of Rust is critical in two ways. First, Rust allows
RedLeaf to leverage recent developments in the programming language community
to simplify verification. RedLeaf builds on the premise that linear types are
critical for creating a scalable automated verification infrastructure. In
particular, Rust enforces (using its type system) a rigorous discipline for
controlling of sharing and aliasing in the program heap. Dealing with sharing
and aliasing is a well-known source of annotation and performance overheads in
software verifiers, and having this aspect be controlled by the type system
allows for a much more scalable verification. Unique properties of Rust\'s
linear type system, and specifically its ability to lift the burden of
resolving memory aliasing from the verifier, open a new page in the domain of
practical and scalable verification.

## Publications

Zhaofeng Li, Tianjiao Huang, Vikram Narayanan, Anton Burtsev. **Understanding
the Overheads of Hardware and Language-Based IPC Mechanisms**. In _11th
Workshop on Programming Languages and Operating Systems (PLOS)_, October 2021.
[pdf](https://mars-research.github.io/doc/plos21/plos21-ipc-overheads.pdf)

Anton Burtsev, Dan Appel, David Detweiler, Tianjiao Huang, Zhaofeng Li, Vikram
Narayanan, Gerd Zellweger. **Isolation in Rust: What is missing?**. In _11th
Workshop on Programming Languages and Operating Systems (PLOS)_, October 2021.
[pdf](https://mars-research.github.io/doc/plos21/plos21-rust-isolation.pdf)

Vikram Narayanan, Tianjiao Huang, David Detweiler, Dan Appel, Zhaofeng Li, Gerd
Zellweger, Anton Burtsev. **RedLeaf: Isolation and Communication in a Safe
Operating System**. In _14th USENIX Symposium on Operating Systems Design and
Implementation (OSDI)_, November 2020.
[pdf](https://mars-research.github.io/doc/redleaf-osdi20.pdf)

Dan Appel. **Inter-Process Communication in a Safe Kernel**. _BS Thesis_. University 
of California, Irvine, 2020. [pdf](https://www.ics.uci.edu/~aburtsev/doc/appel-bs-thesis.pdf)


Vikram Narayanan (University of California, Irvine), Marek S. Baranowski
(University of Utah), Leonid Ryzhyk (VMware Research), Zvonimir Rakamaric
(University of Utah), Anton Burtsev (University of California, Irvine).
**RedLeaf: Towards An Operating System for Safe and Verified Firmware**. In
_17th Workshop on Hot Topics in Operating Systems (HotOS)_, May 2019.
[pdf](https://mars-research.github.io/doc/redleaf-hotos19.pdf)

# Code

* RedLeaf Operating System: https://github.com/mars-research/redleaf
* RedLeaf IDL: https://github.com/mars-research/redIDL



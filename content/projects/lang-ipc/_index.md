---
layout: page
title: Overheads of Hardware and Language-Based IPC Mechanisms

aliases:
- /lang-ipc
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

## Publications

Zhaofeng Li, Tianjiao Huang, Vikram Narayanan, Anton Burtsev. **Understanding
the Overheads of Hardware and Language-Based IPC Mechanisms**. In _11th
Workshop on Programming Languages and Operating Systems (PLOS)_, October 2021.
[pdf](https://mars-research.github.io/doc/plos21/plos21-ipc-overheads.pdf)

## Code

* Coming soon ...


---
title: Rust for Linux
aliases:
- /rfl

ShowReadingTime: false
---

Rust-for-Linux (RFL) is a new framework that allows
development of Linux kernel extensions in Rust. At first
glance, RFL is a huge step forward in terms of improving
the security of the kernel: As a safe programming language,
Rust can eliminate wide classes of low-level vulnerabilities.
Yet, in practice, low-level driver code – complex driver
interface, a combination of reference counting and manual
memory management, arithmetic pointer and index oper-
ations, unsafe type casts, and numerous logical invariants
about the data structures exchanged with the kernel might
significantly limit the security impact of Rust.
This work takes a careful look at how Rust can impact
the security of driver code. Specifically, we ask the question:
What classes (and what fraction) of vulnerabilities typi-
cally found in device driver code can be eliminated by re-
implementing device drivers in Rust? We find that Rust can
eliminate large classes of safety-related vulnerabilities, but
naturally struggles to address protocol violations and seman-
tic errors. Moreover, to be fully eliminated, many classes
of flaws require careful programming discipline to avoid
memory leaks and runtime panics (e.g., explicit checks for
integer overflows and option types), careful implementation
of Drop traits, as well as correct implementation of reference
counting. Our analysis of 240 driver vulnerabilities that are
present in device drivers in the last four years, shows that
82 could be automatically eliminated by Rust, 113 require
specific programming idioms and developer’s involvement,
and 45 remain unaffected by Rust. We hope that our work
can improve the understanding of potential flaws in Rust
drivers and result in more secure kernel code.

# Database

[spreadsheet](https://docs.google.com/spreadsheets/d/1U1iiuwJ_JnUQYtACTi-ZmZYcFW8ow9PGIjCU5_nMhgQ/edit?usp=sharing)

CVEs are grouped by year in sheet name linux-cves-XXXX. 
Filter are applied by default to show what CVEs has been classified. 
You can remove or apply filter under Data tab on top of google sheet.

# Publications

* Zhaofeng Li, Vikram Narayanan, Xiangdong Chen, Jerry Zhang, Anton Burtsev.
[Rust for Linux: Understanding Security Impact of Rust on the Linux Kernel](./doc/2024-acsac-rfl.pdf). In 
_Proceedings of the Annual Computer Security Applications Conference (ACSAC'24)_, December 2024.

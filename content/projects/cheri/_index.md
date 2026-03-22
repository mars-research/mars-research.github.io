
---
title: Security Impact of CHERI on Operating System Kernel
aliases:
- '/cheri'
- '/security'

ShowReadingTime: false
---

Capability Hardware Enhanced RISC Instructions
(CHERI) is a set of hardware extensions that allow enforce-
ment of spatial and temporal safety for unsafe programming
languages like C. CHERI utilizes an idea of hardware ca-
pability pointers to enforce bounds checks on all memory
accesses and a hardware-assisted revocation scheme to en-
force temporal safety. In theory, CHERI offers a surprising
mix of practical adoption and strong security guarantees
for traditionally unsafe environments like operating system
kernels, i.e., capability extensions block a range of software
safety-related vulnerabilities common to low-level systems
code while requiring only a modest engineering effort.
Our work takes a deep look at the potential impact
of CHERI on the security of commodity operating system
kernels. We analyze a total of 439 kernel vulnerabilities in
Linux and FreeBSD kernels. Our analysis shows that CHERI
can block 35%-61% vulnerabilities depending on whether
temporal safety is enabled in the kernel. Enabling CHERI
requires a modest effort, e.g., porting the FreeBSD kernel to
support pure-capability mode of execution took 7 months.
Finally, we estimate that compared to Rust, CHERI blocks
70% of vulnerabilities (38% if revocation is off), a number
lower than blocked by Rust, 84%, but at a much lower
effort. We hope that our work improves the understanding
of potential effort and benefits of capability protection in
commodity kernels.

# Database

[github](https://github.com/mars-research/cheri-impact-artifact)

# Publications

* Zhaofeng Li, Jerry Zhang, Joshua Tlatelpa-Agustin, Xiangdong Chen, Anton Burtsev. 
[Understanding the Security Impact of CHERI on the Operating System Kernel](/doc/2025-cheri-acsac25.pdf). 
In _Proceedings of the  Annual Computer Security Applications Conference (ACSAC)_, December 2025.


---
title: Verified Linux Drivers (VELD)
aliases:
- /veld

ShowReadingTime: false
---

Device drivers and kernel extensions have long been considered one of the main
sources of defects in the kernel. In the past, complexity of driver execution
environment and their internal logic kept them beyond the reach of formal
verification. We argue, however, that recent advances in systems programming
languages, and automated verification make a leap forward toward enabling
practical development of verified kernel code. Verified Linux drivers (Veld) is
a new device driver framework for Linux that leverages Rust and Verus for
development of formally correct device drivers. High-level of automation
offered by Verus allows us to sidestep traditional burden of verification and
instead focus on challenges related to verification of driver code: expressing
complex model of the driver, kernel and hardware interfaces, support for
verification of concurrent driver code, and integrating with the low-level
interface of the kernel. We develop all code in Rust and prove its functional
correctness, i.e., refinement of a high-level specification with Verus. Our
early experience with developing Veld and verifying parts of the model-specific
register (MSR) driver demonstrates the possibility of device driver
verification.

# Publications

* Xiangdong Chen, Zhaofeng Li, Jerry Zhang, Anton Burtsev.  [Veld: Verified
  Linux Drivers](/doc/2024-kisv-veld.pdf). In  _Proceedings of the 2nd Workshop
on Kernel Isolation, Safety and Verification (KISV 2024)_, November 2024.



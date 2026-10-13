---
menu: after
title: Teaching

ShowReadingTime: false
ShowBreadCrumbs: false
---

Two operating systems classes are most relevant to our work, and we teach both of them. The first, CS 5460/6460, is an introductory class built
around [xv6](https://github.com/mit-pdos/xv6-public), a small re-implementation
of an early UNIX kernel that is simple enough to read and understand in full.
The second, CS 5465/6465, is an advanced class centered around virtualization: students learn
how modern kernels and hypervisors (Linux, Xen, KVM) work, and build their own
hypervisor for xv6 using hardware virtualization support (Intel VT-x).
Along the way they also work on fast device interfaces, container isolation,
unikernels, and fast inter-process communication.

## Courses

- [CS 5460/6460: Operating Systems](https://mars-research.github.io/cs5460).
  Virtual memory, kernel/user modes, system calls, threads, context switches,
  interrupts, file systems, and synchronization, explored hands-on by extending
  xv6.

- [CS 5465/6465: Advanced Operating System Implementation](https://mars-research.github.io/cs6465/).
  Hardware virtualization, paravirtualization, containers, microkernels and
  unikernels, and hardware isolation. Students build a VT-x hypervisor for
  xv6. Requires CS 5460.

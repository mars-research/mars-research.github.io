---
layout: page
title: KSplit
permalink: ksplit
---

KSplit, a new framework for isolating device drivers in the Linux kernel.
KSplit performs a collection of static analyses on the source code of the
kernel and the driver to generate the synchronization code that is required to
execute the driver in isolation. Specifically, KSplit identifies the shared
state that is accessed by both driver and the kernel computing how this state
is accessed on both sides of the isolation boundary and how it should be
synchronized on each kernel-driver invocation and when a shared synchronization
primitive, e.g., a spinlockor or an RCU, is invoked. The result of the analysis
is a collection of procedure call specifications in the KSplit interface
definition language (IDL). The KSplit IDL compiler then generates glue code
that ensures synchronization of data structures between isolated subsystems.
Some kernel idioms, such as concurrency and complex data structures, present
ambiguities that cannot be resolved automatically at present, so KSplit also
identifies these specific problems for developers to focus their effort.  This
allows one to take an existing driver and produce the data synchronization code
necessary to run the driver in isolation, automatically if possible, and
identifies remaining tasks that require manual intervention, if needed.


# Publications

Yongzhe Huang, Vikram Narayanan, David Detweiler, Kaiming Huang, Gang Tan,
Trent Jaeger, and Anton Burtsev.  **KSplit: Automating Device Driver
Isolation**.  In _16th USENIX Symposium on Operating Systems Design and
Implementation (OSDI '22)_, July 2022.
[pdf](https://mars-research.github.io/doc/)




---
title: Recruitment

aliases:
- '/recruitment'

ShowReadingTime: false
ShowBreadCrumbs: false
---

## virtio-net

In this challenge, you will be implementing a driver for the [virtio-net NIC](https://docs.oasis-open.org/virtio/virtio/v1.1/csprd01/virtio-v1.1-csprd01.html#x1-1940001) in [xv6](https://github.com/mit-pdos/xv6-riscv)[^1]. Your goal is to be able to respond to ICMP ping packets on an interface - Implementing sockets is optional.

To make the challenge a bit more fun, you may write your driver in any language, including Rust. You are welcome to consult specs and sample code online (this challenge is a simplified version of [an assignment at the University of Washington](https://courses.cs.washington.edu/courses/csep551/19au/labs/net.html)), but the bulk of the implementation has to be written by you.

[^1]: You can also use [the X86 version of xv6](https://github.com/mit-pdos/xv6-public) if you wish

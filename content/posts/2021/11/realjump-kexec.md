---
title: realjump - A Tale of Kexec, Real Mode, and Lazyology
author: Zhaofeng Li
date: 2021-11-02
---

We design and develop operating systems, and one thing we often do is to test them on bare-metal machines. This is often needed to get accurate numbers for benchmark results, and sometimes to resolve problems that do not appear on virtualized platforms.

However, there is one huge downside that makes testing on bare metal tedious: The long "develop, test, repeat" cycle caused by long reboot times. This is less of an issue on consumer-grade platforms which often boot very fast, but the story is different on server platforms where the POST time can be up to 5 minutes thanks to a combination of memory testing, processor interconnect training, Option ROM prompts among other factors.

The natural reaction to this problem would be, "Let's skip the BIOS and kexec to our kernel from Linux!" Sure enough [1], but that only solves the first half of the problem. After running the benchmarks in our OS, we would like to quickly switch *back* to Linux from our kernel.

Loading another kernel, however, is not a trivial task. You need to implement the boot protocol used by the target kernel to pass information to it, correctly set up the required memory mapping, and load the code and data to the right places. Depending on your setup and the boot protocol specifications, you may need to relocate your kernel or otherwise dance around things when loading the target image. The end results would be pretty OS-specific, and would involve duplicating a lot of the work that bootloaders have already done.

With the *First Law of Lazyology* (ahem) in mind, we began to think: What if we could get the system to *some state* where we are able to trivially start an actual bootloader and have it do all the work for us? Well, it was obvious that such state would be the Real Mode. This is where the hardworking bootloaders bootstrap themselves with nothing but [crufty stone tools](https://en.wikipedia.org/wiki/BIOS_interrupt_call) and [tree branches](https://en.wikipedia.org/wiki/16-bit_computing) (well, in Legacy BIOS at least).

Thus [realjump](https://github.com/mars-research/realjump) was born. It's a self-contained crate that loads your code, takes the system [all the way](https://github.com/mars-research/realjump/blob/main/src/redpill.S) from Long Mode to Real Mode and finally jumps to it. All you have to do is to identity map the lowest 1 MiB of memory, halt all other processors, and disable interrupts. [A very simple x86-64 kernel](https://github.com/mars-research/realjump/tree/main/test-os) is provided in-tree for CI and to show how easy it is to actually use realjump in a kernel. It allows the loading of code beyond the 64 KiB mark, but you (or rather, the code) will be responsible for setting things up to be able to actually access it, either in Protected Mode or Unreal Mode. The final bootstrap code was just around 100 lines of Assembly.

Is this the proper solution? Definitely not! Not counting the fact that this trick feels incredibly hacky at the first glance, when you return to Real Mode, you may find many BIOS services, like INT 13h, no longer working. The OS may have overwrote memory regions which hold the service routines, and some programs like [memdisk](https://wiki.syslinux.org/wiki/index.php?title=MEMDISK) work by replacing BIOS interrupts to virtualize resources like disks.

---

[1] On a side note, we also recently [fixed](https://git.kernel.org/pub/scm/utils/kernel/kexec/kexec-tools.git/log/?h=main&qt=author&q=Zhaofeng) a couple of issues that prevented x86-64 Multiboot2 images from being loaded in kexec-tools.

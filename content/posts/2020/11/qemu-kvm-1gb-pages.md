---
title: Debugging QEMU/KVM Setup If Something Goes Wrong (e.g., Support for 1GB Pages)
date: 2020-11-01
author: Vikram Narayanan
aliases:
- '/kernel development/2020/11/01/qemu-kvm-1gb-pages.html'
---

In our previous projects, we always did all development on real hardware. For
example, [LXDs](https://mars-research.github.io/lxds/) and
[LVDs](https://mars-research.github.io/lvds/) required baremetal speed of the
cache-coherence protocol and support for nested virtualization (both systems
use hardware-supported virtualization). So development under QEMU looked
unrealistic. Well, maybe we need to explore more. KVM supports nested
virtualization, but we needed support for features like extended page table
(EPT) switching with VMFUNC. In the end, we were reluctant to take this
approach. 

But our most recent project,
[RedLeaf](https://mars-research.github.io/redleaf), is a new operating system
implemented from scratch in Rust. This was the first time we used QEMU/KVM pair
for development and found it extremely effective. Developing OS kernels under
QEMU/KVM has a much quicker development cycle and gives a ton of debugging
opportunities (e.g., attaching GDB, dumping page tables from QEMU,
understanding triple faults, etc.). Plus it removes an extremely annoying long
reboot cycle. 

We will describe what we've learned in a collection of posts and hopefully, our
lessons are useful to others. It took us some time to debug several things that
did not work as expected when run on top of QEMU/KVM. Here, we describe our
experience of debugging 1GB page support with KVM. 

**Spoiler:** our bug is trivial, we just did not pass the correct CPU model as
an argument. So if you simply want to get it running scroll to the bottom. Our
goal with this post is to share the tricks that allow us to debug similar
issues with the QEMU setup. 

## The problem 

We started our development with a 3 level pagetable with 2MiB hugepages. Later,
we wanted more memory and decided to support huge pagetables (1GiB pages).

Here is our pagetable setup, trying to direct-map the first 32GiBs of memory:
```asm
setup_huge_page_tables:
    ; map first P4 entry to P3 table
    mov rax, hp3_table
    or rax, 0b11 ; present + writable
    mov [hp4_table], rax

    ;map each P3 entry to a huge 1GiB page
    mov ecx, 0         ; counter variable

.map_hp3_table:
    ; map ecx-th P3 entry to a huge page that starts at address 1GiB*ecx
    mov rax, 1 << 30  ; 1GiB
    mul ecx            ; start address of ecx-th page
    shl rdx, 32
    or rax, rdx
    or rax, 0b10000011 ; present + writable + huge
    mov [hp3_table + ecx * 8], rax ; map ecx-th entry

    inc ecx            ; increase counter
    cmp ecx, 0x20       ; if counter == 32, 32 entries in P3 table is mapped
    jne .map_hp3_table  ; else map the next entry

    ; Apic regions would belong in the first few gigabytes
    ret

section .bss

hp4_table:
    resb 4096              
hp3_table:  
    resb 4096

```

With this boot-time pagetable, everything was good when we run it on bare-metal, but things started to break under QEMU/KVM.
All we had access to was an internal error from KVM and a register dump.

```log
KVM internal error. Suberror: 1
emulation failure
EAX=80000011 EBX=00000000 ECX=c0000080 EDX=00000000
ESI=00000000 EDI=00000000 EBP=00000000 ESP=01bfa000
EIP=00133025 EFL=00010086 [--S--P-] CPL=0 II=0 A20=1 SMM=0 HLT=0
ES =0018 00000000 ffffffff 00c09300 DPL=0 DS   [-WA]
CS =0010 00000000 ffffffff 00c09b00 DPL=0 CS32 [-RA]
SS =0018 00000000 ffffffff 00c09300 DPL=0 DS   [-WA]
DS =0018 00000000 ffffffff 00c09300 DPL=0 DS   [-WA]
FS =0018 00000000 ffffffff 00c09300 DPL=0 DS   [-WA]
GS =0018 00000000 ffffffff 00c09300 DPL=0 DS   [-WA]
LDT=0000 00000000 0000ffff 00008200 DPL=0 LDT
TR =0000 00000000 0000ffff 00008b00 DPL=0 TSS64-busy
GDT=     0000000000100018 0000000f
IDT=     0000000000000000 00000000
CR0=80000011 CR2=0000000000000000 CR3=0000000000bf8000 CR4=00000020
DR0=0000000000000000 DR1=0000000000000000 DR2=0000000000000000 DR3=0000000000000000
DR6=00000000ffff0ff0 DR7=0000000000000400
EFER=0000000000000500
```

The program counter was pointing to an instruction which accesses the [VGA
buffer](https://wiki.osdev.org/Printing_To_Screen)
```objdump
  133025:       66 c7 05 00 80 0b 00 48 02                      movw   $0x248,0xb8000(%rip)
```

At this point, what can we do to debug the crash? We were kind of lost, why VGA
buffer, what went wrong? 

## Step 1: Enable KVM tracing

We start debugging by enabling KVM tracing with Linux tracepoints.  [Linux
tracepoints] (https://www.kernel.org/doc/html/latest/trace/tracepoints.html)
are a lightweight instrumentation facility embedded in the Linux kernel.  One
can dynamically enable these tracepoints by registering a function that would
be called when the tracepoint is executed.

KVM Code has a lot of [tracepoints](https://www.linux-kvm.org/page/Perf_events)
for instrumenting various events. The list of tracepoints could be obtained by
running `perf list` as shown below.

```sh
$ sudo perf list | grep kvm
  ...
  kvm:kvm_emulate_insn                               [Tracepoint event]
  kvm:kvm_enter_smm                                  [Tracepoint event]
  kvm:kvm_entry                                      [Tracepoint event]
  kvm:kvm_eoi                                        [Tracepoint event]
  kvm:kvm_exit                                       [Tracepoint event]
  kvm:kvm_fast_mmio                                  [Tracepoint event]
  kvm:kvm_fpu                                        [Tracepoint event]
  kvm:kvm_halt_poll_ns                               [Tracepoint event]
  ...
```

[`trace-cmd`](https://git.kernel.org/pub/scm/linux/kernel/git/rostedt/trace-cmd.git)
offers a set of tools to trace and collect these events.

Let's run with all kvm tracepoints [enabled](https://www.linux-kvm.org/page/Tracing)

```sh
sudo trace-cmd record -b 20000 -e kvm
```
From the dumped report, 
```sh
sudo trace-cmd report > trace-cmd.txt
```
we have some more details
```
 qemu-system-x86-31218 [000] 159269.806542: kvm_exit:             reason EPT_MISCONFIG rip 0x133025 info 0 0
 qemu-system-x86-31218 [000] 159269.806546: kvm_emulate_insn:     0:133025: ec
 qemu-system-x86-31218 [000] 159269.806547: kvm_emulate_insn:     0:133025: ec FAIL
 qemu-system-x86-31218 [000] 159269.806548: kvm_userspace_exit:   reason KVM_EXIT_INTERNAL_ERROR (17)
 qemu-system-x86-31218 [000] 159269.806548: kvm_fpu:              unload
 qemu-system-x86-31215 [007] 159325.605844: kvm_hv_stimer_cleanup: vcpu_id 0 timer 0
 qemu-system-x86-31215 [007] 159325.605852: kvm_hv_stimer_cleanup: vcpu_id 0 timer 1
 qemu-system-x86-31215 [007] 159325.605852: kvm_hv_stimer_cleanup: vcpu_id 0 timer 2
 qemu-system-x86-31215 [007] 159325.605853: kvm_hv_stimer_cleanup: vcpu_id 0 timer 3
```

Well, grepping `KVM_EXIT_INTERNAL_ERROR` did not give us much information. But
what caught the eye was that the instruction dump at `rip` was not what we see in
`objdump`. So, we tried looking into the previous `kvm_emulate_insn` logs in
the trace report to see how it is handled.

Below is our previous instance of `emulate_insn` trace.
```
 qemu-system-x86-31218 [000] 159269.805554: kvm_exit:             reason IO_INSTRUCTION rip 0xa962 info 1770008 0
 qemu-system-x86-31218 [000] 159269.805555: kvm_emulate_insn:     f0000:a962: ec
 qemu-system-x86-31218 [000] 159269.805555: kvm_userspace_exit:   reason KVM_EXIT_IO (2)
```

From the above, it looks like kvm seem to have failed to fetch the instructions at our
crashed rip (`0x131025`).

The `kvm_emulate_insn` trace is located at [`arch/x86/kvm/x86.c`](https://elixir.bootlin.com/linux/v4.8.4/source/arch/x86/kvm/x86.c#L5474).

The exit reason is an EPT misconfiguration.
```
 qemu-system-x86-31218 [000] 159269.806542: kvm_exit:             reason EPT_MISCONFIG rip 0x133025 info 0 0
```

and the request for emulation originated from here: [`handle_ept_misconfig`](https://elixir.bootlin.com/linux/v4.8.4/source/arch/x86/kvm/vmx.c#L6166) which matches with our trace log.

```c
static int handle_ept_misconfig(struct kvm_vcpu *vcpu)
{
	...
        ret = handle_mmio_page_fault(vcpu, gpa, true);
        if (likely(ret == RET_MMIO_PF_EMULATE))
                return x86_emulate_instruction(vcpu, gpa, 0, NULL, 0) ==
                                              EMULATE_DONE;
	...
```

From [`arch/x86/kvm/x86.c`](https://elixir.bootlin.com/linux/v4.8.4/source/arch/x86/kvm/x86.c#L5435)
```c
int x86_emulate_instruction(struct kvm_vcpu *vcpu,
                            unsigned long cr2,
                            int emulation_type,
                            void *insn,
                            int insn_len)
{
        struct x86_emulate_ctxt *ctxt = &vcpu->arch.emulate_ctxt;

	...

        if (!(emulation_type & EMULTYPE_NO_DECODE)) {
                init_emulate_ctxt(vcpu);

		... 

                r = x86_decode_insn(ctxt, insn, insn_len);

                trace_kvm_emulate_insn_start(vcpu);
```

## Step 2: Taking a closer look at function arguments with Systemtap

We want to understand what goes wrong in decoding the instruction at our
faulting `rip`. For example, we may want to peek into the arguments to
`x86_decode_insn` function to observe `insn` or its return value.

One way is to modify the kernel sources and add more debugging information in
these functions. But that's quite an invasive change. Instead, we use
systemtap, a non-invasive way to attach probes at call and return sites for
various kernel functions without modifying the kernel sources.

[Systemtap](https://sourceware.org/systemtap/wiki) offers a nice commandline
interface and a scripting language using which one can attach call/return probes
to kernel functions. Additionally, it offers guru mode - where you can place
embedded C blocks that can use kernel datastructures and functions.

The code flow of `x86_decode_insn` in our scenario is:<br>
<p align="center">
  <img src="/images/qemu-kvm-1gb-pages/kvm_callgraph.svg">
</p>


In the above graph, `gva_to_gpa` and is a function pointer which dynamically changes based
on the context we run the guest on. Instead of trying to dig through the code
to resolve it, we can run systemtap to dynamically figure out which `gva_to_gpa`
pointer is mapped.

Also, to understand if address translation happens correctly, we monitored both
these calls: `kvm_fetch_guest_virt` and `kvm_vcpu_read_guest_page`.

Here is the systemtap script we use to stick a probe at call-site for these
functions.
```c
global count = 0
probe module("kvm").function("kvm_fetch_guest_virt") {
        printf("%s eip 0x%08x, addr: 0x%08x, bytes: %d\n", ppfunc(), $ctxt->eip, $addr, $bytes);
        if (count == 0) {
                printf("fp_gva_to_gpa: %x\n", print_fp($ctxt));
                count++;
        }
	// We want to know the gva_to_gpa when our guest is at this rip
        if ($addr == 0x133025) {
                printf("fp_gva_to_gpa: %x\n", print_fp($ctxt));
        }
}

probe module("kvm").function("kvm_vcpu_read_guest_page") {
        printf("  -%s => gfn 0x%08x\n", ppfunc(), $gfn);
}
```
Running this by logging the output to a file,
```sh
sudo stap -v ./kvm.stp -o kvm_stap.log
```
Here is what we have,

```
kvm_fetch_guest_virt eip 0x0000cfa6, addr: 0x000fcfa6, bytes: 15
fp_gva_to_gpa: ffffffffa04416e0			// This is what gva_to_gpa points to at the beginning
  -kvm_vcpu_read_guest_page => gfn 0x000000fc
...
<snip>

kvm_fetch_guest_virt eip 0x00133025, addr: 0x00133025, bytes: 15
fp_gva_to_gpa: ffffffffa0448660			// This is what gva_to_gpa points to when we hit our bug

```

The log shows that for the offending address, we see the record for
`kvm_fetch_guest_virt`, but we do not see any for `kvm_vcpu_read_guest_page`,
which means the our `gva_to_gpa` likely returned an error.

```c
/* used for instruction fetching */
static int kvm_fetch_guest_virt(struct x86_emulate_ctxt *ctxt,
				gva_t addr, void *val, unsigned int bytes,
				struct x86_exception *exception)
{
	struct kvm_vcpu *vcpu = emul_to_vcpu(ctxt);
	u32 access = (kvm_x86_ops->get_cpl(vcpu) == 3) ? PFERR_USER_MASK : 0;
	unsigned offset;
	int ret;

	/* Inline kvm_read_guest_virt_helper for speed.  */
	gpa_t gpa = vcpu->arch.walk_mmu->gva_to_gpa(vcpu, addr, access|PFERR_FETCH_MASK,
						    exception);
	if (unlikely(gpa == UNMAPPED_GVA))
		return X86EMUL_PROPAGATE_FAULT;

	offset = addr & (PAGE_SIZE-1);
	if (WARN_ON(offset + bytes > PAGE_SIZE))
		bytes = (unsigned)PAGE_SIZE - offset;
	ret = kvm_vcpu_read_guest_page(vcpu, gpa >> PAGE_SHIFT, val,
				       offset, bytes);
	if (unlikely(ret < 0))
		return X86EMUL_IO_NEEDED;

	return X86EMUL_CONTINUE;
}
```

From `kallsyms`, we can get the actual functions the `gva_to_gpa` functions pointers point to. 
```sh
$ sudo grep -e ffffffffa04416e0 -e ffffffffa0448660 /proc/kallsyms
ffffffffa04416e0 t nonpaging_gva_to_gpa [kvm]
ffffffffa0448660 t paging64_gva_to_gpa  [kvm]
```

During initialization, paging is turned off, so the function pointer is
pointing to `nonpaging_gva_to_gpa` and when paging is turned on it points to
`paging64_gva_to_gpa`. So, at our offending address,
[`paging64_gva_to_gpa`](https://elixir.bootlin.com/linux/v4.8.4/source/arch/x86/kvm/paging_tmpl.h#L890)
likely returns a failure. 

All `gva_to_gpa` helpers are templatized in the file
[`paging_tmpl.h`](https://elixir.bootlin.com/linux/v4.8.4/source/arch/x86/kvm/paging_tmpl.h).
`paging64_gva_to_gpa` is nothing but a wrapper around [`paging64_walk_addr`](https://elixir.bootlin.com/linux/v4.8.4/source/arch/x86/kvm/paging_tmpl.h#L456)
which inturn is a wrapper to [`paging64_walk_addr_generic`](https://elixir.bootlin.com/linux/v4.8.4/source/arch/x86/kvm/paging_tmpl.h#L280) which walks the relevant pagetable.


Adding a return probe at this function in the systemtap script would give us the return value.
```c
global ret_active = 0

probe module("kvm").function("paging64_walk_addr_generic") {
        if ($addr == 0x00133025) {
                printf("Walking: %s\n", $$parms);
                ret_active = 1;
        }
}

probe module("kvm").function("paging64_walk_addr_generic").return {
        if (ret_active > 0) {
                printf("return: %s\n", $$return);
        }
}

```

This gives us:

```
Walking: walker=0xffff88140cf07a50 vcpu=0xffff882820b48000 mmu=0xffff882820b48300 addr=0x133025 access=0x10
return: return=0x0
```

## Step 3: Enable even more KVM tracing

The function (`paging64_walk_addr_generic`) returns `1` if it has found a valid
mapping and `0` otherwise (in case of an error). From systemtap log, we see a
failure in address walk, but we do not know yet what happened. 

Fortunately, there are more tracepoints in the page walk [code](https://elixir.bootlin.com/linux/v4.8.4/source/arch/x86/kvm/paging_tmpl.h#L280).
Also, from `perf list` we have a bunch of `kvm_mmu` tracepoints.

```
$ sudo perf list | grep kvmmmu
  ...
  kvmmmu:kvm_mmu_set_dirty_bit                       [Tracepoint event]
  kvmmmu:kvm_mmu_set_spte                            [Tracepoint event]
  kvmmmu:kvm_mmu_spte_requested                      [Tracepoint event]
  kvmmmu:kvm_mmu_sync_page                           [Tracepoint event]
  kvmmmu:kvm_mmu_unsync_page                         [Tracepoint event]
  kvmmmu:kvm_mmu_walker_error                        [Tracepoint event]
  ...
```

By enabling the tracepoints in `paging64_walk_addr_generic`,

```sh
sudo trace-cmd record -b 20000 -e kvm -e kvm_mmu_pagetable_walk -e kvm_mmu_paging_element -e kvm_mmu_walker_error

```

we have more information about the error:

```
 qemu-system-x86-31218 [000] 159269.806542: kvm_exit:             reason EPT_MISCONFIG rip 0x133025 info 0 0
 qemu-system-x86-31218 [000] 159269.806544: kvm_mmu_pagetable_walk: addr 133025 pferr 10 F
 qemu-system-x86-31218 [000] 159269.806545: kvm_mmu_paging_element: pte bf9023 level 4
 qemu-system-x86-31218 [000] 159269.806545: kvm_mmu_paging_element: pte a3 level 3
 qemu-system-x86-31218 [000] 159269.806546: kvm_mmu_walker_error: pferr 9 P|RSVD
 qemu-system-x86-31218 [000] 159269.806546: kvm_emulate_insn:     0:133025: ec
 qemu-system-x86-31218 [000] 159269.806547: kvm_emulate_insn:     0:133025: ec FAIL
 qemu-system-x86-31218 [000] 159269.806548: kvm_userspace_exit:   reason KVM_EXIT_INTERNAL_ERROR (17)
```

### Pagetable organization

Before decoding the error, let's take a quick look at our pagetable organization. We have just two levels (`level4` and `level3`) <br>
<p align="center">
  <img src="/images/qemu-kvm-1gb-pages/pgtable.svg">
</p>


From the log, the walk was successful for `level4` table and while walking
`level3` we get an error which hints that the reserved bit is set on the `level3`
entry.

```c
static int FNAME(walk_addr_generic)(struct guest_walker *walker,
                                    struct kvm_vcpu *vcpu, struct kvm_mmu *mmu,
                                    gva_t addr, u32 access)
{
	...

        trace_kvm_mmu_pagetable_walk(addr, access);

        do {
		...

                if (unlikely(is_rsvd_bits_set(mmu, pte, walker->level))) {
                        errcode = PFERR_RSVD_MASK | PFERR_PRESENT_MASK;
                        goto error;
                }

		...
        } while (!is_last_gpte(mmu, walker->level, pte));

error:
	...

        trace_kvm_mmu_walker_error(walker->fault.error_code);
	return 0;
}
```

The check for reserved bit is happening [here](https://elixir.bootlin.com/linux/v4.8.4/source/arch/x86/kvm/mmu.c#L3314)
```c
static bool
__is_rsvd_bits_set(struct rsvd_bits_validate *rsvd_check, u64 pte, int level)
{
	int bit7 = (pte >> 7) & 1, low6 = pte & 0x3f;

	return (pte & rsvd_check->rsvd_bits_mask[bit7][level-1]) |
		((rsvd_check->bad_mt_xwr & (1ull << low6)) != 0);
}
```

In our pagetable entry, we set `bit7` in the `level3` entry for enabling 1GiB
pages.  With those inputs, the expression above expands to
`rsvd_bits_mask[1][2]`. The mask is set in `__reset_rsvds_bits_mask`.

From [`arch/x86/kvm/mmu.c`](https://elixir.bootlin.com/linux/v4.8.4/source/arch/x86/kvm/mmu.c#L3679)

```c
static void
__reset_rsvds_bits_mask(struct kvm_vcpu *vcpu,
			struct rsvd_bits_validate *rsvd_check,
			int maxphyaddr, int level, bool nx, bool gbpages,
			bool pse, bool amd)
{
	...

	if (!gbpages)
		gbpages_bit_rsvd = rsvd_bits(7, 7);
	...

	switch (level) {
	...
	case PT64_ROOT_LEVEL:
	...
		rsvd_check->rsvd_bits_mask[1][2] = exb_bit_rsvd |
			gbpages_bit_rsvd | rsvd_bits(maxphyaddr, 51) |
			rsvd_bits(13, 29);
		break;

	...
}

static void reset_rsvds_bits_mask(struct kvm_vcpu *vcpu,
				  struct kvm_mmu *context)
{
	__reset_rsvds_bits_mask(vcpu, &context->guest_rsvd_check,
				cpuid_maxphyaddr(vcpu), context->root_level,
				context->nx, guest_cpuid_has_gbpages(vcpu),
				is_pse(vcpu), guest_cpuid_is_amd(vcpu));
}
```

So, the hint of whether to set this bit as reserved comes from whether the
guest cpu has gbpages capability. This comes from CPUID leaf
`0x8000_0001`.EDX[26].

Running cpuid on the host gives,
```
...
$ cpud -1
   ...
   extended feature flags (0x80000001/edx):           
      SYSCALL and SYSRET instructions        = true                                                                  
      execution disable                      = true       
      1-GB large page support                = true  
  ...
```

## Root-cause: CPUID


The immediate conclusion is: our host support 1GiB pages but our guest CPU does
not support it. Digging through the sources shows that only a few server class
CPU support this feature in QEMU.

```c
static X86CPUDefinition builtin_x86_defs[] = {
    ...
    {    
        .name = "Skylake-Server",
        .level = 0xd, 
        .vendor = CPUID_VENDOR_INTEL,

        .features[FEAT_8000_0001_EDX] =
            CPUID_EXT2_LM | CPUID_EXT2_PDPE1GB | CPUID_EXT2_RDTSCP |
            CPUID_EXT2_NX | CPUID_EXT2_SYSCALL,

    ...
```

Also, from [qemu documentation](https://www.qemu.org/docs/master/system/target-i386.html#recommendations-for-kvm-cpu-model-configuration-on-x86-hosts)
```
pdpe1gb

    Recommended to allow guest OS to use 1GB size pages.

    Not included by default in any Intel CPU model.

    Should be explicitly turned on for all Intel CPU models.

    Note that not all CPU hardware will support this feature.
```

## Solution: passing the CPU model that supports 1GB pages

The conclusion is, in QEMU command line, one should specify a CPU that supports
this feature (according to QEMU sources) or pass this a flag to the cpus to enable 1GiB large page support.

```bash
qemu-system-x86_64 -cpu Haswell,pdpe1gb ...
```

or

```bash
qemu-system-x86_64 -cpu Skylake-Server ...
```

Having this in our QEMU commandline does not set `bit7` as reserved and thus
solves the bug we encountered at the beginning of this post.


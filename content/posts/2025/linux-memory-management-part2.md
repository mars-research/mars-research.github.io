---
title: Linux Memory Management - Part 2
date: 2025-09-27
author: Manvik Nanda
---
In part 2 of our Linux memory management series, we’ll explore key allocation strategies that are crucial for efficient memory use and performance.

## Initial Boot
Linux uses a simple, temporary allocator during boot time. This early allocator is responsible for handing out memory so that the more sophisticated, long-term allocators can be set up later. Traditionally, this early allocator uses a bitmap to track free and allocated pages and is discarded once initialization is complete. The bitmap must contain one bit for every physical page in the system. This allocator is statically configured in the kernel code.

## Why sophisticated allocators once the system is booted?
Lets consider an example: 
```css
| 100      | 101      | 102      | 103      | 104      |
| -------- | -------- | -------- | -------- | -------- |
| 11111111 | 11111111 | 00000000 | 10000001 | 10000001 |
```
In the example above, suppose we request 8 pages. The allocator scans the bitmap and finds a contiguous block at index 102, returning that address. The bitmap is then updated as:
```css
| 100      | 101      | 102      | 103      | 104      |
| -------- | -------- | -------- | -------- | -------- |
| 11111111 | 11111111 | 11111111 | 10000001 | 10000001 |
```
Now, imagine we free just the first page in block 103:
```css
| 100      | 101      | 102      | 103      | 104      |
| -------- | -------- | -------- | -------- | -------- |
| 11111111 | 11111111 | 11111111 | 00000001 | 10000001 |
```
Although there is enough total free memory in the system, a new request for 8 contiguous pages would fail — because no sufficiently large contiguous block exists anymore.
## Fragmentation
```css
[■■■■■■■■][    ][■■][  ][■■■■■■][   ][■■■■]
```
* ■ = allocated page
* [ ] = free pages

This illustrates one of the fundamental problems with bitmap-based allocation: fragmentation. Over time, free pages become scattered across memory, preventing the allocation of large contiguous blocks even when plenty of memory is technically available.

<mark>Sometimes, however, contiguous physical memory is not optional</mark>. Certain kernel subsystems — such as DMA (Direct Memory Access) buffers, device drivers, or huge page mappings — require physically contiguous memory regions to function correctly. If the allocator cannot provide these blocks, these components simply cannot operate.

While it is possible to manage fragmentation within a bitmap allocator, doing so becomes increasingly inefficient as the system grows. Instead, Linux uses this early allocator only as a bootstrap mechanism — just enough to initialize the real allocators — and then frees the memory it consumed.

In older versions of Linux, this boot-time allocation was handled using a structure called `bootmem_data` for each NUMA node. Modern kernels have replaced this with a more flexible mechanism called `memblock_type`, and the bitmap itself is no longer used. Nevertheless, the bitmap allocator remains a useful conceptual tool: it illustrates both the challenges of early-stage memory allocation and the motivation for more advanced allocators like the buddy system, which can dynamically split and merge blocks to reduce fragmentation and satisfy contiguous memory requests.

## Buddy Allocator
Implementation details of buddy allocator can be quite complex, and can be found [here](https://elixir.bootlin.com/linux/v6.10/source/mm/page_alloc.c). But, the idea is the following: 
### Allocation
1. Round the requested size up to the nearest power of two.
2. If a free block of that size exists → use it.
3. If not → find a larger free block and split it into two buddies.
4. Keep splitting until you get a block of the right size.
5. Give one buddy to the requester, keep the other free.
```css
[-------------------------------]       16
[---------------][---------------]      8 + 8
[-------][-------][---------------]     4 + 4 + 8
```
### De-allocation
1. Mark the freed block as free.
2. Check if its buddy (adjacent block of the same size) is also free.
3. If yes → merge them into a larger block.
4. Repeat merging upwards until no free buddy exists.
```css
[-------][-------][---------------]     4 + 4 + 8
[---------------][---------------]      8 + 8
[-------------------------------]       16
```
## Slab Allocator
The buddy allocator is great if you want memory in chunks of 4 KB or larger — but kernel code often needs memory for tiny objects:

* A `task_struct` is ~`2KB`
* An inode is a few hundred bytes
* A network buffer header might be ~`128B`

Thus, we also need an allocator that slices pages into small reusable chunks and gives them out efficiently. The slab allocator groups objects of the same type and size into collections called slabs. For example, if we know that each task_struct is 2 KB, a slab might consist of two 4 KB pages, divided into four task_struct slots. The kernel can now allocate and free these structures without ever calling the buddy allocator again for each one. Think of slabs as pages divided into objects. 
```css
[P0] --> [ Obj1 ][ Obj2 ][ Obj3 ] ... [ Obj16 ]
```
Like the buddy allocator, the slab allocator has evolved over time, and Linux supports three main variants with different trade-offs:

* SLAB – The original implementation, with detailed cache and slab management but higher complexity and overhead.
* SLUB – A simplified redesign that uses per-CPU caches and less metadata, improving scalability and performance. [`Code`](https://elixir.bootlin.com/linux/v6.10-rc7/source/mm/slub.c#L3)
* SLOB – A lightweight allocator for memory-constrained systems, prioritizing simplicity over speed.

Today, SLUB is the default in most Linux distributions, as it offers the best balance between performance, scalability, and simplicity.
### `kmem_cache`
`kmem_cache` is the core data structure behind the slab allocator in Linux. It represents a cache for objects of a single type and size, example, `kmem_cache` for task_struct objects (~`2KB` each). The cache knows which slots are free, which are used, and reuses them efficiently.

Kernel code often creates a dedicated kmem_cache for frequently allocated objects:
```C
struct kmem_cache *task_cache;

task_cache = kmem_cache_create(
    "task_struct_cache",              // name (for /proc/slabinfo)
    sizeof(struct task_struct),       // size of each object
    __alignof__(struct task_struct),  // alignment
    SLAB_HWCACHE_ALIGN,               // flags
    NULL                              // optional constructor
);
```
Now, whenever the kernel needs a new task_struct, it doesn’t call the buddy allocator. It just does:
```C
struct task_struct *t = kmem_cache_alloc(task_cache, GFP_KERNEL);
```       
And to deallocate: 
```C
kmem_cache_free(task_cache, t);
```
Note: When a `kmem_cache` needs additional memory to create new slabs, it internally requests pages from the buddy allocator. The slab allocator builds on top of the buddy system
## Allocator Hierarchy
```css
kmem_cache  ──► [ Slab (1..N pages) ] ─┬─ [obj] [obj] [obj] ...
                      ▲                └─ [obj] [obj] [obj]
                      │
                 alloc_pages(buddy)
```
## What's More?
So far, we’ve looked at the main strategies Linux uses to manage memory. Next, we’ll explore virtual memory and see how the system translates virtual addresses into physical ones. All this and more, coming up in the next part, stay tuned!

## Additional Reading... [`vmalloc()`](https://litux.nl/mirror/kerneldevelopment/0672327201/ch11lev1sec5.html)

Instead of demanding physically adjacent pages, `vmalloc()` creates a contiguous virtual address range by stitching together scattered physical pages. The kernel handles this through the virtual memory system, setting up the proper page table mappings so that, from the program’s perspective, it looks like one smooth, continuous block of memory.

Behind the scenes, `vmalloc()` still relies on the Buddy Allocator to find available physical pages — it just doesn’t require them to sit next to each other.
This approach greatly reduces fragmentation, improves overall memory utilization, and works especially well for large or infrequently accessed buffers, where strict physical adjacency isn’t necessary.
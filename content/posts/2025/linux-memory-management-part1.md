---
title: Linux Memory Management - Part 1
date: 2025-09-26
author: Manvik Nanda
---
Memory management is one of the most important parts of any operating system — and one of the most complex. It gives each process the illusion of having its own continuous block of memory, deals with fragmentation, manages physical memory across CPUs and NUMA nodes, and makes sure both hardware and software can access the right memory at the right time. Despite its importance, it often feels like “black magic” even to experienced developers.

In this 3-part series, we'll peel back the layers of Linux's memory subsystem. Starting from the most fundamental unit — the page — we'll climb up through zones and nodes, explore the buddy and slab allocators, and finish with virtual memory. Along the way, we'll look at kernel data structures, diagrams, and small code snippets showing how these ideas become reality.

Note that this document represents the current state of the Linux kernel and API, v6.x.x

## What is a Page? 
Linux organizes both physical and virtual memory in fixed-size chunks called pages — typically 4 KB each on x86 systems. Every byte of physical memory belongs to exactly one page frame, and every virtual memory mapping refers to one or more pages.

Each physical page frame in the system is represented by a struct page in the kernel. This structure stores metadata about how the page is used — whether it’s free or allocated, which process owns it, whether it’s part of the page cache, and more.

```css
Physical Memory (RAM)
+-----------------------------------------------------------+
|                                                           |
|   Page 0   |   Page 1   |   Page 2   |   Page 3   |  ...  |
|  (4 KB)    |  (4 KB)    |  (4 KB)    |  (4 KB)    |       |
+------------+------------+------------+------------+-------+
0x00000000   0x00001000   0x00002000   0x00003000   ...
```
Each page:
- Is a fixed-size block of memory
- Starts at a physical address aligned to `PAGE_SIZE`
- Has a unique Page Frame Number (PFN)

Lets look at the simplified version of the `struct page` data structure from the file [`include/linux/mm_types.h`](https://elixir.bootlin.com/linux/v6.10.10/source/include/linux/mm_types.h#L74)

```C
struct page {
    unsigned long flags;      // status bits: locked, dirty, etc.
    union {
        struct list_head lru; // for LRU lists (active/inactive)
        struct list_head buddy_list;
    };
    struct address_space *mapping; // mapped object (file, anon mem, etc.)
    pgoff_t index;                // offset within the mapping
    atomic_t _mapcount;           // number of PTEs mapping this page
    atomic_t _refcount;           // reference count
};
```

For UMA systems, all physical pages are represented in memory by a contiguous array called [`mem_map`](https://elixir.bootlin.com/linux/v6.10.10/source/mm/memory.c#L103). The index into this array is called the Page Frame Number (PFN). This provides a bridge between raw physical addresses and their metadata.
```css
mem_map[] (array of struct page)
+-----------+-----------+-----------+-----------+------+
| page[0]   | page[1]   | page[2]   | page[3]   | ...  |
+-----------+-----------+-----------+-----------+------+
     |           |           |           |
     |           |           |           |
     v           v           v           v
+-----------+-----------+-----------+-----------+------+
| Page 0    | Page 1    | Page 2    | Page 3    | ...  |
| (4 KB)    | (4 KB)    | (4 KB)    | (4 KB)    |      |
+-----------+-----------+-----------+-----------+------+
```

## Memory Nodes
### UMA vs NUMA
The CPU reads from and writes to memory, but modern processors typically have multiple cores, each capable of executing instructions on its own. This means that each core can access and interact with memory independently, adding complexity to the system. 

On NUMA (Non-Uniform Memory Access) systems with multiple CPU sockets, memory is split into separate banks (nodes), each local to a processor. Accessing local memory is faster than accessing memory attached to another CPU. On UMA (Uniform Memory Access) systems, where there is only one memory bank, the entire system shares a single node. More about this here: [UMA vs NUMA](https://frankdenneman.nl/2016/07/07/numa-deep-dive-part-1-uma-numa/)

### Nodes
In the Linux kernel, each memory node is represented by a `struct pglist_data` (often referred to as `pg_data_t`). This data structure is defined in file [`include/linux/mmzone.h`](https://elixir.bootlin.com/linux/v6.10.10/source/include/linux/mmzone.h#L1277).

* On NUMA systems, one `pg_data_t` is created per node early in boot, typically stored in that node’s own memory bank.
* On UMA systems, there’s only one static instance called contig_page_data.

```C
// One per memory node
typedef struct pglist_data {
    // All memory zones in this node (e.g., DMA, Normal, HighMem)
    struct zone node_zones[MAX_NR_ZONES];

    // Ordered list of zones the allocator should try
    struct zonelist node_zonelists[MAX_ZONELISTS];

    int nr_zones;                  // Number of populated zones
    unsigned long node_start_pfn; // First page frame number in this node
    unsigned long node_present_pages; // Total physical pages in this node
    unsigned long node_spanned_pages; // Total page range (incl. holes)
    int node_id;                  // Unique ID of this node
    unsigned long totalreserve_pages; // Reserved pages for kernel use
} pg_data_t;
```

## Zones
Each memory node (`pg_data_t`) is divided into zones, represented by the struct zone data structure. Zones group pages with similar properties, helping the kernel manage memory efficiently and choose the right type of memory for different allocations.

For example, a typical x86 system defines these zones:

* `ZONE_DMA` – Low memory accessible by legacy DMA-capable devices.
* `ZONE_NORMAL` – Regular, directly mapped kernel memory.
* `ZONE_HIGHMEM` – Memory not permanently mapped into the kernel’s address space (32-bit only).

Simplified version of `struct zone`, defined in [`include/linux/mmzone.h`](https://elixir.bootlin.com/linux/v6.10.10/source/include/linux/mmzone.h#L824)
```C
struct zone {
    unsigned long managed_pages;   // Pages the allocator can use
    unsigned long spanned_pages;   // Total pages in this zone (incl. holes)
    unsigned long present_pages;   // Pages actually present in RAM

    struct free_area free_area[MAX_ORDER]; // Free lists organized by block size
    spinlock_t lock;                       // Protects zone data structures

    const char *name;           // Human-readable name (e.g., "DMA", "Normal")
    int initialized;            // Whether the zone is ready for use
};
```
Each pg_data_t (node) contains one struct zone for every zone type. During allocation, the kernel searches zones in a preferred order — for example, from `ZONE_NORMAL` to `ZONE_HIGHMEM` — and selects the first that can satisfy the request. This design allows the kernel to efficiently match memory allocations to hardware constraints and device requirements.

## Memory System Hierarchy
```
System Memory
└─ Node (pg_data_t)
   ├─ Zone: DMA
   │  ├─ struct page
   │  ├─ struct page
   │  └─ ...
   ├─ Zone: NORMAL
   │  ├─ struct page
   │  └─ ...
   └─ Zone: HIGHMEM
      ├─ struct page
      └─ ...
```
## What's More?
So far, we’ve explored the key data structures and the hierarchical organization that form the backbone of Linux’s memory management system. In the next part of this series, we’ll shift our focus to how memory is actually allocated and managed, diving into allocation strategies like the buddy allocator and the slab allocator. Stay tuned!
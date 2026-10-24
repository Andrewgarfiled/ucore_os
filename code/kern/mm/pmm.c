#include <default_pmm.h>
#include <best_fit_pmm.h>
#include <defs.h>
#include <error.h>
#include <memlayout.h>
#include <mmu.h>
#include <pmm.h>
#include <sbi.h>
#include <stdio.h>
#include <string.h>
#include <riscv.h>
#include <dtb.h>

// virtual address of physical page array
struct Page *pages;
// amount of physical memory (in pages)
size_t npage = 0;
// the kernel image is mapped at VA=KERNBASE and PA=info.base
uint64_t va_pa_offset;
// memory starts at 0x80000000 in RISC-V
// DRAM_BASE defined in riscv.h as 0x80000000
const size_t nbase = DRAM_BASE / PGSIZE;

// virtual address of boot-time page directory
uintptr_t *satp_virtual = NULL;
// physical address of boot-time page directory
uintptr_t satp_physical;

// physical memory management
const struct pmm_manager *pmm_manager;


static void check_alloc_page(void);

// init_pmm_manager - initialize a pmm_manager instance
static void init_pmm_manager(void) {
    pmm_manager = &best_fit_pmm_manager;
    cprintf("memory management: %s\n", pmm_manager->name);
    pmm_manager->init();
}

// init_memmap - call pmm->init_memmap to build Page struct for free memory
static void init_memmap(struct Page *base, size_t n) {
    pmm_manager->init_memmap(base, n);
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
    return pmm_manager->alloc_pages(n);
}

// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    pmm_manager->free_pages(base, n);
}

// nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE)
// of current free memory
size_t nr_free_pages(void) {
    return pmm_manager->nr_free_pages();
}

//lab2 function1 2411966
static void
page_init(void) {
    extern char end[];
    uint64_t mem_base = get_memory_base();
    uint64_t mem_size = get_memory_size();
    uint64_t mem_end;
    uintptr_t freemem;//空闲区内存
    size_t free_n;

    // The kernel is identity mapped at VA = PA + PHYSICAL_MEMORY_OFFSET.
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;

    if (mem_base == 0 || mem_size == 0) {
        panic("page_init: invalid memory range from DTB "
              "(base=0x%016lx, size=0x%016lx)",
              mem_base, mem_size);
    }

    mem_end = mem_base + mem_size;

    npage = PPN(mem_end);//得到物理页号

    if (npage <= nbase) {
        panic("page_init: physical memory too small "
              "(npage=%lu, nbase=%lu)",
              (unsigned long)npage, (unsigned long)nbase);
    }

    // Place the Page descriptor array right after the kernel image.
    pages = (struct Page *)ROUNDUP((uintptr_t)end, PGSIZE);
    //把 end 地址向上对齐到 4 KiB，作为 pages 描述符数组的起始地址
   
    for (size_t i = 0; i < npage - nbase; i++) {
        pages[i].ref = 0;
        pages[i].flags = 0;
        pages[i].property = 0;
        SetPageReserved(&pages[i]);
    }

    cprintf("Physical memory: base=0x%016lx size=0x%016lx "
            "end=0x%016lx npage=%lu\n",
            mem_base, mem_size, mem_end, (unsigned long)npage);

    // First page after the kernel image and the Page descriptor array.
    freemem = PADDR((uintptr_t)pages) +
              (npage - nbase) * sizeof(struct Page);
    freemem = ROUNDUP(freemem, PGSIZE);

    if (freemem >= mem_end) {
        //如果超过物理内存末尾，说明没有可用的空闲页了

        cprintf("page_init: no complete free pages after kernel and pages[]\n");
        return;
    }

    free_n = (mem_end - freemem) / PGSIZE;
    init_memmap(pa2page(freemem), free_n);
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
    // We need to alloc/free the physical memory (granularity is 4KB or other size).
    // So a framework of physical memory manager (struct pmm_manager)is defined in pmm.h
    // First we should init a physical memory manager(pmm) based on the framework.
    // Then pmm can alloc/free the physical memory.
    // Now the first_fit/best_fit/worst_fit/buddy_system pmm are available.
    init_pmm_manager();

    // detect physical memory space, reserve already used memory,
    // then use pmm->init_memmap to create free page list
    page_init();

    // use pmm->check to verify the correctness of the alloc/free function in a pmm
    check_alloc_page();

    extern char boot_page_table_sv39[];
    satp_virtual = (pte_t*)boot_page_table_sv39;
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
    cprintf("check_alloc_page() succeeded!\n");
}

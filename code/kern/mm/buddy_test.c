#include <buddy_test.h>
#include <buddy_pmm.h>
#include <defs.h>
#include <memlayout.h>
#include <mmu.h>
#include <pmm.h>
#include <stdio.h>

// Borrow a pool from the active (best-fit) allocator, run the buddy manager
// over an aligned 1024-page subrange, then hand every page back.
#define BUDDY_SUB_PAGES   1024
#define BUDDY_POOL_PAGES  2048
#define BUDDY_STRESS_ALLOCS 64

static unsigned int buddy_rng_state = 0x12345678;

static unsigned int
buddy_rand(void) {
    buddy_rng_state = buddy_rng_state * 1103515245u + 12345u;
    return buddy_rng_state >> 16;
}

static void
buddy_fail(const char *msg) {
    cprintf("[Buddy] FAIL: %s\n", msg);
}

void
buddy_test(void) {
    cprintf("[Buddy] running tests\n");
    size_t before = nr_free_pages();

    struct Page *pool = alloc_pages(BUDDY_POOL_PAGES);
    if (pool == NULL) {
        buddy_fail("cannot borrow a test pool from best-fit");
        return;
    }

    size_t align = BUDDY_SUB_PAGES;
    size_t offset = (align - (page2ppn(pool) % align)) % align;
    struct Page *sub = pool + offset;

    for (size_t i = 0; i < BUDDY_SUB_PAGES; i++) {
        SetPageReserved(sub + i);
    }

    buddy_pmm_manager.init();
    buddy_pmm_manager.init_memmap(sub, BUDDY_SUB_PAGES);

    // 1. initial state and oversized allocation
    if (buddy_pmm_manager.nr_free_pages() != BUDDY_SUB_PAGES) {
        buddy_fail("initial nr_free");
    }
    buddy_pmm_manager.check();
    if (buddy_pmm_manager.alloc_pages(BUDDY_SUB_PAGES + 1) != NULL) {
        buddy_fail("oversized allocation should return NULL");
    }

    // 2. deterministic split/merge of two single-page buddies
    struct Page *a = buddy_pmm_manager.alloc_pages(1);
    struct Page *b = buddy_pmm_manager.alloc_pages(1);
    if (a == NULL || b == NULL) {
        buddy_fail("single-page allocation");
    }
    if (b != a + 1) {
        buddy_fail("consecutive 1-page allocations are not buddies");
    }
    buddy_pmm_manager.free_pages(a, 1);
    buddy_pmm_manager.free_pages(b, 1);
    struct Page *c = buddy_pmm_manager.alloc_pages(2);
    if (c != a) {
        buddy_fail("buddies did not merge into their parent block");
    }
    buddy_pmm_manager.free_pages(c, 2);
    if (buddy_pmm_manager.nr_free_pages() != BUDDY_SUB_PAGES) {
        buddy_fail("nr_free after buddy merge");
    }

    // 3. allocate powers of two, check alignment and free-count accounting
    size_t reqs[4] = {1, 2, 4, 8};
    struct Page *blocks[4] = {NULL, NULL, NULL, NULL};
    size_t accounted = 0;
    for (unsigned int i = 0; i < 4; i++) {
        blocks[i] = buddy_pmm_manager.alloc_pages(reqs[i]);
        if (blocks[i] == NULL) {
            buddy_fail("power-of-two allocation");
        }
        if (page2pa(blocks[i]) % (reqs[i] * PGSIZE) != 0) {
            buddy_fail("power-of-two block is misaligned");
        }
        accounted += reqs[i];
    }
    if (buddy_pmm_manager.nr_free_pages() != BUDDY_SUB_PAGES - accounted) {
        buddy_fail("nr_free after power-of-two allocations");
    }
    for (unsigned int i = 0; i < 4; i++) {
        buddy_pmm_manager.free_pages(blocks[i], reqs[i]);
    }
    if (buddy_pmm_manager.nr_free_pages() != BUDDY_SUB_PAGES) {
        buddy_fail("nr_free after freeing power-of-two blocks");
    }

    // 4. random-sized alloc/free stress test
    struct Page *ptrs[BUDDY_STRESS_ALLOCS];
    size_t sizes[BUDDY_STRESS_ALLOCS];
    for (unsigned int i = 0; i < BUDDY_STRESS_ALLOCS; i++) {
        sizes[i] = 1 + (buddy_rand() % 8);
        ptrs[i] = buddy_pmm_manager.alloc_pages(sizes[i]);
        if (ptrs[i] == NULL) {
            buddy_fail("stress allocation");
            break;
        }
    }
    for (int i = BUDDY_STRESS_ALLOCS - 1; i >= 0; i--) {
        buddy_pmm_manager.free_pages(ptrs[i], sizes[i]);
    }
    if (buddy_pmm_manager.nr_free_pages() != BUDDY_SUB_PAGES) {
        buddy_fail("nr_free after stress test");
    }
    buddy_pmm_manager.check();

    // Hand every borrowed page back to the active allocator.
    for (size_t i = 0; i < BUDDY_POOL_PAGES; i++) {
        pool[i].flags = 0;
        pool[i].property = 0;
        set_page_ref(pool + i, 0);
    }
    free_pages(pool, BUDDY_POOL_PAGES);

    if (nr_free_pages() != before) {
        buddy_fail("active allocator page count changed");
    }
    cprintf("[Buddy] tests PASS\n");
}

#include <slub_test.h>
#include <slub.h>
#include <defs.h>
#include <pmm.h>
#include <stdio.h>
#include <string.h>

#define SLUB_STRESS_ALLOCS 64

static unsigned int slub_rng_state = 0x87654321;

static unsigned int
slub_rand(void) {
    slub_rng_state = slub_rng_state * 1103515245u + 12345u;
    return slub_rng_state >> 16;
}

static void
slub_fail(const char *msg) {
    cprintf("[SLUB] FAIL: %s\n", msg);
}

static int
slub_check_bytes(void *ptr, size_t size, unsigned char pat) {
    unsigned char *p = (unsigned char *)ptr;
    for (size_t i = 0; i < size; i++) {
        if (p[i] != pat) {
            return 0;
        }
    }
    return 1;
}

void
slub_test(void) {
    cprintf("[SLUB] running tests\n");
    size_t before = nr_free_pages();
    slub_init();

    // 1. different object sizes: alignment, distinctness, and no overlap
    size_t sizes[] = {
        1, 4, 8, 16, 31, 32, 64, 100, 128, 255,
        256, 512, 1000, 1024, 2000, 2048, 4095, 4096, 4097, 8192
    };
    const int nr_sizes = sizeof(sizes) / sizeof(sizes[0]);
    void *ptrs[20];

    for (int i = 0; i < nr_sizes; i++) {
        ptrs[i] = kmalloc(sizes[i]);
        if (ptrs[i] == NULL) {
            slub_fail("allocation of a supported size");
            return;
        }
        if ((uintptr_t)ptrs[i] % 8 != 0) {
            slub_fail("returned pointer is not 8-byte aligned");
            return;
        }
        memset(ptrs[i], (unsigned char)(i + 1), sizes[i]);
    }

    for (int i = 0; i < nr_sizes; i++) {
        for (int j = i + 1; j < nr_sizes; j++) {
            if (ptrs[i] == ptrs[j]) {
                slub_fail("distinct allocations returned the same pointer");
                return;
            }
        }
        if (!slub_check_bytes(ptrs[i], sizes[i], (unsigned char)(i + 1))) {
            slub_fail("object bytes were overwritten by another object");
            return;
        }
    }
    for (int i = 0; i < nr_sizes; i++) {
        kfree(ptrs[i]);
    }
    if (nr_free_pages() != before) {
        slub_fail("page count changed after basic sizes");
    }

    // 2. reuse within one cache after freeing objects
    void *q[8];
    void *r[4];
    for (int i = 0; i < 8; i++) {
        q[i] = kmalloc(16);
        if (q[i] == NULL) {
            slub_fail("same-cache allocation");
            return;
        }
        memset(q[i], 0x5a, 16);
    }
    for (int i = 0; i < 8; i += 2) {
        kfree(q[i]);
    }
    for (int i = 0; i < 4; i++) {
        r[i] = kmalloc(16);
        if (r[i] == NULL) {
            slub_fail("cache reuse allocation");
            return;
        }
        int found = 0;
        for (int j = 0; j < 8; j += 2) {
            if (r[i] == q[j]) {
                found = 1;
                break;
            }
        }
        if (!found) {
            slub_fail("freed object was not reused");
        }
    }
    for (int i = 0; i < 4; i++) {
        kfree(r[i]);
    }
    for (int i = 1; i < 8; i += 2) {
        kfree(q[i]);
    }
    if (nr_free_pages() != before) {
        slub_fail("page count changed after cache reuse");
    }

    // 3. random-sized mixed alloc/free stress test
    void *p[SLUB_STRESS_ALLOCS];
    size_t sz[SLUB_STRESS_ALLOCS];
    for (int i = 0; i < SLUB_STRESS_ALLOCS; i++) {
        sz[i] = 1 + (slub_rand() % 2048);
        p[i] = kmalloc(sz[i]);
        if (p[i] == NULL) {
            slub_fail("stress allocation");
            return;
        }
        memset(p[i], 0x33, sz[i]);
    }
    for (int i = SLUB_STRESS_ALLOCS - 1; i >= 0; i--) {
        kfree(p[i]);
    }
    if (nr_free_pages() != before) {
        slub_fail("page count changed after stress test");
    }

    // 4. out-of-memory allocation returns NULL, and kfree(NULL) is safe
    void *huge = kmalloc((size_t)1 << 31);
    if (huge != NULL) {
        kfree(huge);
        slub_fail("oversized allocation should return NULL");
    }
    kfree(NULL);
    if (nr_free_pages() != before) {
        slub_fail("page count changed after edge cases");
    }

    cprintf("[SLUB] tests PASS\n");
}

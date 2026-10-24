#include <slub.h>
#include <list.h>
#include <memlayout.h>
#include <mmu.h>
#include <pmm.h>
#include <stdio.h>

#define SLUB_MIN_OBJSIZE        8
#define SLUB_MAX_CACHE_OBJSIZE  2048
#define SLUB_CACHE_COUNT        9

#define SLAB_MAGIC  0x534c5542  // "SLUB"
#define BIG_MAGIC   0x4249474d  // "BIGM"

struct kmem_cache {
    size_t objsize;
    unsigned int objs_per_slab;
    list_entry_t slabs_partial;  // slabs that still have free objects
    list_entry_t slabs_full;     // slabs without any free object
};

struct slab {
    uint64_t magic;
    struct kmem_cache *cache;
    void *freelist;
    unsigned int inuse;
    list_entry_t link;
};

struct big_block {
    uint64_t magic;
    size_t size;
    size_t pages;
};

#define le2slab(le, member) to_struct((le), struct slab, member)

static struct kmem_cache caches[SLUB_CACHE_COUNT];

static void *
pa2kva(uintptr_t pa) {
    return (void *)(pa + va_pa_offset);
}

static uintptr_t
kva2pa(uintptr_t kva) {
    return kva - va_pa_offset;
}

void
slub_init(void) {
    for (unsigned int i = 0; i < SLUB_CACHE_COUNT; i++) {
        caches[i].objsize = SLUB_MIN_OBJSIZE << i;
        caches[i].objs_per_slab =
            (PGSIZE - sizeof(struct slab)) / caches[i].objsize;
        list_init(&caches[i].slabs_partial);
        list_init(&caches[i].slabs_full);
    }
}

static struct kmem_cache *
slub_cache_for(size_t size) {
    if (size > SLUB_MAX_CACHE_OBJSIZE) {
        return NULL;
    }

    size_t objsize = SLUB_MIN_OBJSIZE;
    unsigned int idx = 0;
    while (objsize < size) {
        objsize <<= 1;
        idx++;
    }
    return &caches[idx];
}

static struct slab *
slub_new_slab(struct kmem_cache *cache) {
    struct Page *page = alloc_page();
    if (page == NULL) {
        return NULL;
    }

    struct slab *slab = (struct slab *)pa2kva(page2pa(page));
    slab->magic = SLAB_MAGIC;
    slab->cache = cache;
    slab->inuse = 0;
    slab->freelist = NULL;
    list_init(&slab->link);

    char *obj = (char *)slab + sizeof(struct slab);
    for (unsigned int i = 0; i < cache->objs_per_slab; i++) {
        void *cur = obj + i * cache->objsize;
        *(void **)cur = slab->freelist;
        slab->freelist = cur;
    }

    list_add(&cache->slabs_partial, &(slab->link));
    return slab;
}

void *
kmalloc(size_t size) {
    if (size == 0) {
        return NULL;
    }

    // Large objects: allocate whole pages and store bookkeeping in a header.
    if (size > SLUB_MAX_CACHE_OBJSIZE) {
        size_t pages =
            ROUNDUP(size + sizeof(struct big_block), PGSIZE) / PGSIZE;
        struct Page *page = alloc_pages(pages);
        if (page == NULL) {
            return NULL;
        }

        struct big_block *head =
            (struct big_block *)pa2kva(page2pa(page));
        head->magic = BIG_MAGIC;
        head->size = size;
        head->pages = pages;
        return (void *)(head + 1);
    }

    struct kmem_cache *cache = slub_cache_for(size);
    if (list_empty(&cache->slabs_partial)) {
        if (slub_new_slab(cache) == NULL) {
            return NULL;
        }
    }

    struct slab *slab =
        le2slab(list_next(&cache->slabs_partial), link);
    void *obj = slab->freelist;
    slab->freelist = *(void **)obj;
    slab->inuse++;

    if (slab->inuse == cache->objs_per_slab) {
        list_del(&(slab->link));
        list_add(&cache->slabs_full, &(slab->link));
    }
    return obj;
}

void
kfree(void *ptr) {
    if (ptr == NULL) {
        return;
    }

    uintptr_t page_base =
        (uintptr_t)ptr & ~((uintptr_t)PGSIZE - 1);
    uint64_t magic = *(uint64_t *)page_base;

    if (magic == SLAB_MAGIC) {
        struct slab *slab = (struct slab *)page_base;
        struct kmem_cache *cache = slab->cache;

        *(void **)ptr = slab->freelist;
        slab->freelist = ptr;

        int was_full = (slab->inuse == cache->objs_per_slab);
        if (was_full) {
            list_del(&(slab->link));
            list_add(&cache->slabs_partial, &(slab->link));
        }
        slab->inuse--;

        if (slab->inuse == 0) {
            list_del(&(slab->link));
            struct Page *page = pa2page(kva2pa(page_base));
            free_page(page);
        }
    } else if (magic == BIG_MAGIC) {
        struct big_block *head = (struct big_block *)page_base;
        struct Page *page = pa2page(kva2pa(page_base));
        free_pages(page, head->pages);
    } else {
        panic("kfree: invalid pointer 0x%016lx", (uintptr_t)ptr);
    }
}

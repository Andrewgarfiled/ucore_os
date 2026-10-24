#include <pmm.h>
#include <list.h>
#include <memlayout.h>
#include <mmu.h>
#include <buddy_pmm.h>

// The largest power-of-two order we track.  Physical memory reported by the
// DTB for this lab is 128 MiB (2^15 pages), so this is comfortably large.
#define BUDDY_MAX_ORDER 20

static list_entry_t buddy_free_lists[BUDDY_MAX_ORDER + 1];
static size_t buddy_nr_free;

static void
buddy_init(void) {
    for (unsigned int i = 0; i <= BUDDY_MAX_ORDER; i++) {
        list_init(&buddy_free_lists[i]);
    }
    buddy_nr_free = 0;
}

// Cut the whole range [base, base + n) into the largest possible
// power-of-two blocks that are aligned to their own size.
static void
buddy_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);

    struct Page *p = base;
    for (; p != base + n; p++) {
        assert(PageReserved(p));
        p->flags = 0;
        p->property = 0;
        set_page_ref(p, 0);
    }

    size_t cur = 0;
    while (cur < n) {
        size_t remaining = n - cur;
        unsigned int order = 0;
        size_t block = 1;

        while (order < BUDDY_MAX_ORDER &&
               (block << 1) <= remaining &&
               ((page2ppn(base + cur) & ((block << 1) - 1)) == 0)) {
            block <<= 1;
            order++;
        }

        struct Page *head = base + cur;
        head->property = order;
        SetPageProperty(head);
        SetPageBuddy(head);
        list_add(&buddy_free_lists[order], &(head->page_link));

        buddy_nr_free += block;
        cur += block;
    }
}

static struct Page *
buddy_alloc_pages(size_t n) {
    assert(n > 0);
    if (n > buddy_nr_free) {
        return NULL;
    }

    unsigned int order = 0;
    size_t block = 1;
    while (block < n) {
        block <<= 1;
        order++;
        if (order > BUDDY_MAX_ORDER) {
            return NULL;
        }
    }

    // Find the smallest order with an available block.
    unsigned int o = order;
    while (o <= BUDDY_MAX_ORDER && list_empty(&buddy_free_lists[o])) {
        o++;
    }
    if (o > BUDDY_MAX_ORDER) {
        return NULL;
    }

    struct Page *page = le2page(list_next(&buddy_free_lists[o]), page_link);
    list_del(&(page->page_link));

    // Split the block until it has exactly the requested order.
    while (o > order) {
        o--;
        struct Page *buddy = page + (1UL << o);
        buddy->property = o;
        SetPageProperty(buddy);
        SetPageBuddy(buddy);
        list_add(&buddy_free_lists[o], &(buddy->page_link));
    }

    buddy_nr_free -= (1UL << order);
    ClearPageProperty(page);
    ClearPageBuddy(page);
    page->property = order;
    return page;
}

static void
buddy_free_pages(struct Page *base, size_t n) {
    assert(n > 0);

    unsigned int order = (unsigned int)base->property;
    assert((1UL << order) >= n);

    struct Page *p = base;
    for (size_t i = 0; i < (1UL << order); i++, p++) {
        assert(!PageReserved(p) && !PageProperty(p));
        p->flags = 0;
        set_page_ref(p, 0);
    }

    base->property = order;
    SetPageProperty(base);
    SetPageBuddy(base);
    buddy_nr_free += (1UL << order);
    list_add(&buddy_free_lists[order], &(base->page_link));

    while (order < BUDDY_MAX_ORDER) {
        ppn_t ppn = page2ppn(base);
        ppn_t buddy_ppn = ppn ^ (1UL << order);
        if (buddy_ppn < nbase || buddy_ppn >= npage) {
            break;
        }

        struct Page *buddy = &pages[buddy_ppn - nbase];
        if (!PageBuddy(buddy) || !PageProperty(buddy) ||
            buddy->property != order) {
            break;
        }

        list_del(&(base->page_link));
        ClearPageProperty(base);
        ClearPageBuddy(base);
        base->property = 0;

        list_del(&(buddy->page_link));
        ClearPageProperty(buddy);
        ClearPageBuddy(buddy);
        buddy->property = 0;

        struct Page *newbase = (buddy < base) ? buddy : base;
        newbase->property = order + 1;
        SetPageProperty(newbase);
        SetPageBuddy(newbase);
        list_add(&buddy_free_lists[order + 1], &(newbase->page_link));

        base = newbase;
        order++;
    }
}

static size_t
buddy_nr_free_pages(void) {
    return buddy_nr_free;
}

static void
buddy_check(void) {
    size_t total = 0;
    for (unsigned int o = 0; o <= BUDDY_MAX_ORDER; o++) {
        list_entry_t *le = &buddy_free_lists[o];
        while ((le = list_next(le)) != &buddy_free_lists[o]) {
            struct Page *p = le2page(le, page_link);
            assert(PageBuddy(p));
            assert(PageProperty(p));
            assert(p->property == o);
            total += (1UL << o);
        }
    }
    assert(total == buddy_nr_free);
}

const struct pmm_manager buddy_pmm_manager = {
    .name = "buddy_pmm_manager",
    .init = buddy_init,
    .init_memmap = buddy_init_memmap,
    .alloc_pages = buddy_alloc_pages,
    .free_pages = buddy_free_pages,
    .nr_free_pages = buddy_nr_free_pages,
    .check = buddy_check,
};

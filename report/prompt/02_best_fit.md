# Best-Fit Prompt

```text
你是一名 RISC-V 内核开发者。请参考 kern/mm/default_pmm.c 的 First-Fit
实现，在 kern/mm/best_fit_pmm.c 中实现 Best-Fit 物理内存分配器：
1. 定义 free_area、free_list、nr_free 等内部状态。
2. 实现 init、init_memmap、alloc_pages、free_pages、nr_free_pages。
3. 空闲链表按块大小升序组织，alloc_pages 选择能容纳请求的最小空闲块。
4. free_pages 回收页面，并尽可能与物理地址相邻的前后空闲块合并，
   合并后重新维护按大小排序。
5. 定义并注册 best_fit_pmm_manager，check 函数使用已有的 best_fit_check。
不要修改 basic_check 和 best_fit_check。
```

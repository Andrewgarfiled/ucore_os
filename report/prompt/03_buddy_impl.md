# Buddy System 实现 Prompt

```text
你是一名 RISC-V 内核开发者，正在为基于 ucore 框架的实验内核（位于 lab2_new/，
采用 Sv39，物理页大小 PGSIZE=4096）实现伙伴系统（Buddy System）物理内存分配器。
请先完整阅读以下文件，再开始实现：
- kern/mm/pmm.h：struct pmm_manager 接口，以及 struct Page、alloc_pages、
  free_pages、pa2page、page2pa 等辅助函数。
- kern/mm/default_pmm.c：First-Fit 实现，作为 pmm_manager 的实现范式与状态约定参考。
- kern/mm/memlayout.h：Page 描述符、PG_reserved/PG_property 等标志。
- libs/list.h：双向链表操作。
- 参考伙伴系统（Buddy System）实现资料
  https://www.cnblogs.com/alantu2018/p/8503425.html，
  理解伙伴块的组织方式、阶（order）的含义、分裂与合并规则。

要求：
1. 新建 kern/mm/buddy_pmm.h 与 kern/mm/buddy_pmm.c，实现一个完整的 pmm_manager，
   并在头文件中声明 extern const struct pmm_manager buddy_pmm_manager;。
2. 使用伙伴系统思想：空闲内存按 2 的幂次块管理，每一阶（order）维护一个空闲链表；
   分配时找到能容纳请求的最小合适块，必要时向下分裂；释放时回收并尽可能与伙伴块合并。
3. 实现 pmm_manager 的 init、init_memmap、alloc_pages、free_pages、nr_free_pages，
   并提供 check 函数。
4. 必须正确维护 struct Page 的状态；可以复用 property 字段表示块阶或块状态，
   但不得与框架既有宏语义冲突，并保证 nr_free_pages 与空闲页总数始终一致。
5. 保持 best_fit_pmm_manager 仍为默认激活管理器，不要修改 pmm_init 的默认选择；
   不要修改 default_pmm.c、best_fit_pmm.c 中已有的 basic_check/best_fit_check。
6. 代码风格与现有文件一致，能通过 -Werror 编译；说明接入 Makefile 所需的最少改动。
7. 输出完整源码文件和必要的头文件。
```

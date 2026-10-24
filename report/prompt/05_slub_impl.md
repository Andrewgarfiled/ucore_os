# SLUB 实现 Prompt

```text
你是一名 RISC-V 内核开发者，正在为 ucore 框架实验内核（位于 lab2_new/）实现一个
简化的 SLUB 风格内存对象分配器，体现“两层架构”思想：第一层基于页分配，
第二层在页之上按任意大小分配对象。请先完整阅读：
- kern/mm/pmm.h、kern/mm/pmm.c：页级分配接口 alloc_pages/free_pages 及调用链。
- kern/mm/default_pmm.c、kern/mm/best_fit_pmm.c：既有分配器实现与代码风格。
- tools/test_lab2.c、tools/test_lab2.h：了解现有测试组织方式。
- libs/list.h、libs/string.h、kern/libs/stdio.c：可用的公共设施。
- 参考 Linux 内核 mm/slub.c（https://github.com/torvalds/linux/blob/master/mm/slub.c）
  的核心思想：kmem_cache、slab 页、对象 freelist、partial/empty 列表等，允许简化。

要求：
1. 新建 kern/mm/slub.h 与 kern/mm/slub.c，提供简化的对象分配 API，
   例如 void slub_init(void); void *kmalloc(size_t size); void kfree(void *ptr);
   （命名可自定，但必须在头文件中声明，并说明等价接口）。
2. 第一层：通过 alloc_pages/free_pages 从页分配器获得整页 slab。
3. 第二层：按对象大小维护缓存（kmem_cache），将 slab 页切分为等大小对象，
   用 freelist 管理空闲对象；释放对象放回 freelist；整页对象全部空闲时可归还页分配器。
4. 处理任意大小请求：对象大小向上对齐到合理边界且至少容纳一个指针；
   超过一页的大请求可直接走页分配。
5. 初始化、分配、释放都不得破坏页分配器状态，也不得影响默认 best_fit 管理器
   与 [Test 1]/[Test 2] 评分。
6. 代码能通过 -Werror 编译，风格与现有文件一致；输出完整源码和头文件，
   并说明接入编译的方式。
```

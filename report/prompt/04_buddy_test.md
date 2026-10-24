# Buddy System 测试 Prompt

```text
你是内核测试工程师。现在已经有一个按伙伴系统思想实现的物理内存分配器
kern/mm/buddy_pmm.c，其导出的管理器是 buddy_pmm_manager。请为它设计一套
可编译运行的测试，检验实现是否正确。

背景与接口：
- 可通过 buddy_pmm_manager 的方法或框架封装 alloc_pages/free_pages 进行页分配。
- struct Page、nr_free_pages、page2pa、pa2page 等来自 pmm.h/memlayout.h。
- 测试代码应放在独立文件（如 kern/mm/buddy_test.c），并提供可调用的入口函数。
- 可参考 https://www.cnblogs.com/alantu2018/p/8503425.html 了解伙伴块的阶、
  伙伴关系与合并条件，据此设计针对分裂和合并行为的用例。

测试要求至少覆盖：
1. init_memmap 后 nr_free 初始值正确，空闲区按 2 的幂次块组织。
2. 分配 1、2、4、8 页等不同大小，返回地址连续且不在保留区。
3. 请求超过可用页数时返回 NULL。
4. 分配后 nr_free 正确减少，释放后正确恢复。
5. 交错分配/释放后，相邻伙伴块能被正确合并，空闲链表无重复、无遗漏。
6. 随机大小分配/释放压力测试后，nr_free 回到初始值，且没有泄漏。

请给出测试源码，并逐条说明每项测试覆盖的行为，以及为什么它能发现实现错误。
```

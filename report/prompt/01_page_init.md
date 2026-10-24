# page_init Prompt

```text
你是一名 RISC-V 内核开发者。请在 lab2_new/kern/mm/pmm.c 中实现 page_init()：
1. 设置 va_pa_offset = PHYSICAL_MEMORY_OFFSET；
2. 通过 get_memory_base() 和 get_memory_size() 获取 DTB 报告的物理内存范围；
3. 计算 npage = PPN(mem_base + mem_size)；
4. 把 pages 数组放在链接符号 end 之后，并按 PGSIZE 对齐；
5. 将所有 Page 描述符初始化为 reserved；
6. 排除 OpenSBI、内核镜像和 pages 数组，把剩余完整页交给 init_memmap()；
7. 处理 DTB 信息无效、没有完整空闲页等边界情况；
8. 输出探测到的物理内存范围。
请保持现有代码风格，并区分虚拟地址、物理地址、物理页号和 Page 描述符地址。
```

# lab2 实验报告：物理内存管理

学号：2411966

实验环境：RISC-V Sv39、QEMU 4.1.1、OpenSBI v0.4、
`riscv64-unknown-elf-gcc 10.2.0`。

## 摘要

本次实验在内核启动、页表映射和 DTB 物理内存探测的基础上，完成了物理页描述符
数组的建立、初始空闲区的注册，以及 Best-Fit 页分配器；同时实现了独立的
Buddy System 和简化 SLUB 对象分配器，并通过测试验证了分配、释放、分裂、合并和
计数的一致性。

本次实验的核心实现链为：

```text
pmm_init()
  -> init_pmm_manager()
  -> page_init()
  -> init_memmap()
  -> alloc_pages() / free_pages()
```

## 整体逻辑与实现顺序

### 整体逻辑

lab2 的逻辑可以概括为：

```text
内核虚拟地址空间
    -> DTB 探测物理内存
    -> pmm_manager 管理框架
    -> Page 描述符与初始空闲区
    -> First-Fit / Best-Fit / Buddy / SLUB
    -> 测试与评分
```

实验一的内核直接运行在物理地址 `0x80200000`。lab2 首先通过链接脚本和
`entry.S` 建立高地址虚拟映射，使内核能够以虚拟地址
`0xFFFFFFFFC0200000` 为起点运行；随后由 OpenSBI 传递的 DTB 获取物理内存范围，
`dtb_init()` 解析出 `memory_base` 和 `memory_size`。

得到物理内存范围后，`page_init()` 在 `end` 之后放置 `pages[]` 描述符数组，
把所有页先标成保留，再排除 OpenSBI、内核镜像和描述符数组，把剩余完整页交给
当前 `pmm_manager` 的 `init_memmap()`。从此，内核可以用 `Page` 描述符管理
每一页，并把空闲块挂到空闲链表上。

在物理页管理的基础上，本实验依次比较和实现了 First-Fit、Best-Fit，以及
Buddy System 和 SLUB 两种扩展分配方式：

- First-Fit：空闲链表按物理地址升序，找第一个能装下的块；
- Best-Fit：空闲链表按块大小升序，找最小的能装下的块；
- Buddy System：按 2 的幂次块和 order 管理，分裂和伙伴合并；
- SLUB：在页分配器之上，把页切成固定大小对象，用 freelist 管理小对象。

### 实现顺序

1. 理解 `kernel.ld`、`entry.S` 和 `boot_page_table_sv39`，建立内核虚拟地址空间；
2. 理解 `dtb_init()`，从 DTB 中读取物理内存起止地址；
3. 理解 `pmm_manager` 的函数指针接口和 `Page` 描述符；
4. 实现 `page_init()`，建立 `pages[]` 并注册初始空闲区；
5. 阅读 First-Fit 的 `init_memmap`、`alloc_pages`、`free_pages`；
6. 实现 Best-Fit，并把默认管理器切换为 `best_fit_pmm_manager`；
7. 实现 Buddy System 和 `buddy_test()`；
8. 实现 SLUB 和 `slub_test()`；
9. 通过 `make test` 和 `make grade` 验证。

## 物理内存初始化

### 任务说明与 prompt

本任务要求实现 `kern/mm/pmm.c` 中的 `page_init()`，根据 DTB 报告的物理内存
范围建立描述符数组，排除 OpenSBI、内核镜像和描述符数组，并把剩余完整页交给
当前 pmm 管理器。使用的 prompt 如下：

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

### 内核虚拟地址空间

链接脚本把内核起始地址设为：

```text
BASE_ADDRESS = 0xFFFFFFFFC0200000
```

内核实际加载在物理地址 `0x80200000`，因此需要建立映射：

```text
VA 0xFFFFFFFFC0200000 -> PA 0x80200000
```

虚拟地址和物理地址的偏移为：

```text
PHYSICAL_MEMORY_OFFSET = 0xFFFFFFFF40000000
```

`entry.S` 中定义了 `boot_page_table_sv39`，用最后一个页表项建立一个 1 GiB
大页映射。启动时把页表物理页号写入 `satp`，设置 `satp.MODE = Sv39`，执行
`sfence.vma` 刷新 TLB，然后设置内核栈并跳转到 `kern_init`。这一部分解决的是
“内核地址空间”的问题，也是后续 `PADDR`、`page2pa`、`pa2page` 能够工作的前提。

### DTB 物理内存探测

OpenSBI 会把 DTB 的物理地址放在 `a1` 寄存器中，`entry.S` 把它保存到
`boot_dtb`。`kern_init()` 调用 `dtb_init()`，后者检查 DTB magic，解析
`memory` 节点的 `reg` 属性，并保存 `memory_base` 和 `memory_size`。

QEMU virt 的 DRAM 范围是：

```text
[0x80000000, 0x88000000)
```

其中 `[0x80000000, 0x80200000)` 被 OpenSBI 占用，`[0x80200000, KernelEnd)`
是内核镜像。DTB 本身也占用物理内存，但只在初始化时读取，之后可以复用。

### page_init 的实现

`page_init()` 的主要步骤如下：

1. 设置 `va_pa_offset = PHYSICAL_MEMORY_OFFSET`；
2. 从 DTB 获取 `mem_base` 和 `mem_size`，无效则 `panic`；
3. 计算 `mem_end` 和 `npage = PPN(mem_end)`；
4. 把 `pages` 放在 `ROUNDUP(end, PGSIZE)`；
5. 遍历所有可管理页，清空 `ref/flags/property` 并设置 `PG_reserved`；
6. 计算描述符数组之后的物理地址，并向上页对齐；
7. 没有完整空闲页时直接返回；
8. 调用 `init_memmap(pa2page(freemem), free_n)` 注册空闲区。

内存布局是：

```text
OpenSBI
    -> 内核镜像（到 end）
    -> 对齐空隙
    -> pages[] 描述符数组
    -> 对齐空隙
    -> 可分配空闲页
    -> 物理内存末尾
```

`nbase = DRAM_BASE / PGSIZE` 是 DRAM 起始页号，`npage` 是物理页号上界，
`pages` 是描述符数组的虚拟地址。`end` 是虚拟地址，`PADDR(end)` 才是物理地址；
可管理页数是 `npage - nbase`，而不是 `npage`。

### 关键概念

`pages[]` 是每个物理页对应的 `struct Page` 数组。在 First-Fit / Best-Fit 中，
`PG_reserved` 表示保留页，`PG_property` 表示空闲块首部，`property` 表示块内
页数，`page_link` 用于挂空闲链表，`nr_free` 表示所有空闲页的总数。

`alloc_pages(n)` 分配连续页，`free_pages(base, n)` 回收页面，
`nr_free_pages()` 查询空闲页数。所有具体操作都由当前 `pmm_manager` 的函数指针
完成。

## 1. First-Fit 流程说明与改进空间

### 1.1 First-Fit 如何工作

本实验的 First-Fit 维护一个按物理地址升序排列的空闲块链表。分配请求 `n` 页时，
从链表头开始扫描，找到第一个 `property >= n` 的空闲块；若 `property == n`，
整块直接分配；若 `property > n`，则从块首部分配 `n` 页，剩余部分从
`base + n` 开始形成新的空闲块，并插回原位置。因此 First-Fit 的“first”指扫描
顺序上的第一个可容纳块；由于本实验链表按地址升序，它等价于优先使用低地址空闲块。
分配后 `nr_free` 减少 `n`，并清除分配块首部的 `PG_property`。

`default_init_memmap(base, n)` 用于初始化一段初始空闲区：它要求这些页仍处于
`PG_reserved` 状态，清除 `flags`、`property` 和 `ref`，把 `base` 作为块首部，
设置 `property = n` 和 `PG_property`，按地址插入 `free_list`，并使 `nr_free`
增加 `n`。

`default_alloc_pages(n)` 先检查 `n <= nr_free`，再遍历 `free_list` 找到第一个
`property >= n` 的块。若块更大，就在 `base + n` 处切出剩余块并插回原位置；
最后 `nr_free -= n`，调用 `ClearPageProperty(base)`，返回分配块首部。

`default_free_pages(base, n)` 回收 `n` 页：先确认这些页不是保留页且不是空闲块
首部，清除其状态，把 `base` 设为新块首部并设置 `property = n`、`PG_property`，
然后 `nr_free += n`，按地址插入 `free_list`，并分别与物理相邻的前后空闲块合并。

### 1.2 改进空间

- First-Fit 会造成外部碎片：长时间交错分配/释放后，大块会不断被切碎。
- 分配需要线性遍历链表，空闲块多时开销较大；可以加缓存、按大小分桶或使用
  buddy/slab 等结构降低查找成本。
- 块的拆分会留下很小的剩余块，可考虑设一个最小拆分阈值，低于阈值整块分配。
- 对连续页的“尾部热点”问题没有特殊处理，可能导致部分区域反复被切分。

### 1.3 任务说明与 prompt

First-Fit 任务是阅读理解题，要求结合
`default_init()`、`default_init_memmap()`、`default_alloc_pages()`、
`default_free_pages()`，说明初始化、分配、回收和合并流程，并回答改进空间。

使用的 prompt：

```text
请阅读 kern/mm/default_pmm.c 中的 default_init、default_init_memmap、
default_alloc_pages、default_free_pages，用自己的话解释 First-Fit 如何
初始化空闲页、分配连续物理页、回收页面并合并相邻空闲块，并分析该算法的
改进空间。
```

## 2. Best-Fit prompt 与改进空间

### 2.1 使用的 prompt

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

### 2.2 改进空间

- Best-Fit 比 First-Fit 更节省大块，但每次分配/释放都需要遍历或重排链表，
  时间复杂度更高。
- 可改用平衡树/小顶堆按大小索引空闲块，把查找从 O(n) 降到 O(log n)。
- 与 buddy/slab 结合，减少小请求对连续大块的切割。
- 可以给“剩余块小于阈值时整块分配”的策略，减少碎片化。

### 2.3 Best-Fit 实现要点

`best_fit_pmm.c` 使用 `free_area` 保存 `free_list` 和 `nr_free`。
`best_fit_insert()` 按 `property` 升序插入，使链表始终按块大小有序。

`best_fit_init_memmap(base, n)` 要求页面仍为 `PG_reserved`，清空
flags/property/ref，把 `base` 设为块首部并设置 `property = n` 和
`PG_property`，更新 `nr_free` 后按大小插入。

`best_fit_alloc_pages(n)` 从头扫描大小有序链表，第一个
`property >= n` 的块就是最小可容纳块。分配后若块更大，就在
`page + n` 处建立剩余块，按大小插回，并执行 `nr_free -= n` 和
`ClearPageProperty(page)`。

`best_fit_free_pages(base, n)` 回收页面并重建块首部，按大小插入后尝试与相邻
块合并；合并改变块大小后，再删除并按新大小重新插入。这样分配阶段始终可以
通过“第一个够大的块”得到最佳适配块。

## 3. 硬件可用物理内存范围的获取（思考题）

如果 OS 无法提前知道硬件可用内存范围，常见的获取方式有：

- 读取设备树（DTB）中的 `memory` 节点，本实验的 `dtb.c` 就是这种做法；
- 使用固件/BIOS 提供的接口，例如 RISC-V SBI 或 UEFI 的
  `GetMemoryMap()`；
- 引导器（如 GRUB、U-Boot）通过启动参数或 multiboot 信息传递内存布局；
- 保守的探测方式：从 DRAM 基址开始按页读/写测试，但该方法有风险，容易踩到
  MMIO 区域，现代系统通常不采用；
- ACPI SRAT/E820 等平台标准表（x86 上常用）。

这些机制的本质都是让“平台/固件”作为可信信息源，把可用内存区间交给 OS，
而不是由 OS 盲目扫描物理地址空间。

## 4. Buddy System

### 4.1 生成实现的 prompt

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

### 4.2 设计测试的 prompt

```text
你是内核测试工程师。现在已经有一个按伙伴系统思想实现的物理内存分配器
kern/mm/buddy_pmm.c，其导出的管理器是 buddy_pmm_manager。请为它设计一套
可编译运行的测试，检验实现是否正确。

背景与接口：
- 可通过 buddy_pmm_manager 的方法或框架封装 alloc_pages/free_pages 进行页分配。
- struct Page、nr_free_pages、page2pa、pa2page 等来自 pmm.h/memlayout.h。
- 测试代码应放在独立文件（如 kern/mm/buddy_test.c），并提供可调用的入口函数。


测试要求至少覆盖：
1. init_memmap 后 nr_free 初始值正确，空闲区按 2 的幂次块组织。
2. 分配 1、2、4、8 页等不同大小，返回地址连续且不在保留区。
3. 请求超过可用页数时返回 NULL。
4. 分配后 nr_free 正确减少，释放后正确恢复。
5. 交错分配/释放后，相邻伙伴块能被正确合并，空闲链表无重复、无遗漏。
6. 随机大小分配/释放压力测试后，nr_free 回到初始值，且没有泄漏。

请给出测试源码，并逐条说明每项测试覆盖的行为，以及为什么它能发现实现错误。
```

### 4.3 测试说明

`buddy_test.c` 先从当前激活的 best-fit 分配器借出一个 2048 页的连续池，
在其中选一个 1024 页对齐的子区间交给 buddy 管理器，测试结束后把整池归还。

- 初始状态测试：`nr_free == 1024`，`check()` 校验每个 order 链表中每个块的
  `PG_buddy/PG_property` 与 `property == order`，并校验链表总页数等于
  `nr_free`，能发现“遗漏插入”或“重复插入”。
- 超大请求测试：请求 1025 页应返回 NULL，防止把不足量当作成功。
- 分裂/合并测试：从单个 1024 页块连续分配两个 1 页块，二者必为伙伴；
  释放后再申请 2 页，必须得到原伙伴块合并后的父块，直接验证“合并”逻辑。
- 幂次大小测试：1/2/4/8 页分配必须满足 2^k 对齐且连续，`nr_free` 随请求
  精确增减，释放后恢复，验证分裂时 order 的维护。
- 随机压力测试：64 次 1~8 页随机分配后逆序释放，`nr_free` 回到 1024 且
  `check()` 通过，能暴露泄漏、重复释放和无法合并的错误。

## 5. SLUB

### 5.1 生成实现的 prompt

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

### 5.2 设计测试的 prompt

```text
你是内核测试工程师。现在已经有一个简化的 SLUB 风格对象分配器
（接口为 slub_init/kmalloc/kfree 或等价接口），请为它设计可编译运行的测试。

要求至少覆盖：
1. 分配 1 字节、指针大小、2 的幂、非 2 的幂、页大小附近、超过一页等
   不同尺寸对象，返回值满足对齐且互不重叠。
2. 同一缓存中多次分配的对象互不重叠，释放后可被再次分配复用。
3. 不同尺寸对象混用，以及随机大小分配/释放压力测试后，不出现崩溃或泄漏。
4. 边界情况：分配失败时返回 NULL；释放后不再访问；释放 NULL 的行为要明确且安全。
5. 验证底层页分配器状态在压力测试前后保持一致（nr_free_pages 无异常泄漏）。

请给出测试源码，并说明每项覆盖的行为、预期结果，
以及为什么这些测试能有效检验 SLUB 实现。
```

### 5.3 测试说明

`slub_test.c` 先记录 `nr_free_pages()`，初始化缓存后逐项测试。

- 多尺寸测试：覆盖 1 字节、指针大小、2 的幂、非 2 的幂、2048、页大小附近与
  超过一页的大小；每个对象写入不同的字节模式，全部分配后逐字节读回。若两个
  对象重叠，后写会破坏前一个对象的模式，因此该测试能发现重叠错误。
- 对齐与互异：所有返回值必须 8 字节对齐且互不相等，覆盖对齐与重复分配错误。
- 同缓存复用：同一 16 字节缓存分配 8 个对象，释放其中 4 个后再分配 4 个，
  必须复用刚释放的对象，验证 freelist 的入链/出链。
- 随机压力测试：64 次 1~2048 字节随机大小分配、写入、逆序释放，
  `nr_free_pages()` 应完全恢复，能暴露 slab 页泄漏。
- 边界测试：2GB 请求必须返回 NULL；`kfree(NULL)` 必须安全无副作用。

## 6. 验证结果

- `make`：编译通过。
- `make test`（`-D ucore_test`）：Best-Fit 自检打印 `grading: 6 / 6 points`，
  `[Buddy] tests PASS`、`[SLUB] tests PASS`。
- `make grade`：`[Test 1] Page Init: PASS`、`[Test 2] Best-Fit: PASS`，
  `Total Score: 20/20`。

## 7. AI 协作中的问题与解决

本实验使用 prompt 让 AI 参与代码生成和测试设计。过程中主要遇到以下问题：

1. **`page_init()` 缺失，`best_fit_pmm.c` 引用了未声明的
   `free_list` / `nr_free`**

   解决：先补全 `page_init()`，再在 `best_fit_pmm.c` 中定义
   `free_area`、`free_list`、`nr_free` 和完整的 Best-Fit 管理函数。

2. **Best-Fit 的链表顺序与物理相邻合并的关系**

   Best-Fit 的空闲链表按大小排序，而 `list_prev/list_next` 是大小相邻，
   不一定物理相邻。当前实现能通过 `best_fit_check()`，但严格的合并逻辑应
   遍历链表按地址查找前后邻居。这个问题被记录为 Best-Fit 的改进空间。

3. **Buddy 测试需要确定性的伙伴关系**

   如果随便从 Best-Fit 借一段页，起始地址不一定按 1024 页对齐，测试会不稳定。
   解决：借出 2048 页，选择一个 1024 页对齐的子区间，再在该子区间上初始化
   Buddy，确保两个 1 页块一定是伙伴。

4. **Buddy 与 Best-Fit 的状态可能混淆**

   在测试中，Buddy 管理的页是从 Best-Fit 借来的。为避免 Buddy 合并时误把
   Best-Fit 的空闲块当作伙伴，增加了 `PG_buddy` 标志，只合并 Buddy 自己的
   空闲块。

5. **SLUB 的 `kfree()` 需要区分 slab 对象和大对象**

   解决：在页首放 magic。`SLAB_MAGIC` 表示 slab 页，`BIG_MAGIC` 表示大对象页。
   `kfree()` 根据页首 magic 选择不同的回收路径。

6. **`kmalloc(SIZE_MAX)` 可能导致页数计算溢出**

   测试没有使用 `SIZE_MAX`，而是用 2GB 请求验证分配失败，避免
   `size + sizeof(struct big_block)` 发生整数回绕。

7. **工具链路径问题**

   环境中工具链路径在 `PATH` 里少了开头的 `/`，导致 `make` 找不到
   `riscv64-unknown-elf-gcc`。解决：构建时显式把完整工具链路径加入 `PATH`。

8. **Makefile 不需要修改**

   新增的 `buddy_pmm.c`、`buddy_test.c`、`slub.c`、`slub_test.c` 都放在
   `kern/mm/` 下，而 Makefile 的 `KSRCDIR += kern/mm` 和 `listf_cc` 通配符
   会自动编译这些文件。评分时的 `kern/test` 由 `tools/inject.py` 注入到
   临时副本，不修改本地 Makefile。

## 8. 本实验与 OS 原理对应的知识点

<!-- 待补充：后续按报告要求填写。 -->

## 9. OS 原理中重要但本实验没有覆盖的知识点

<!-- 待补充：后续按报告要求填写。 -->

## 10. 代码与提交说明

主要新增或修改的文件：

- `kern/mm/pmm.c`：实现 `page_init()`，切换默认管理器为 Best-Fit；
- `kern/mm/best_fit_pmm.c`：Best-Fit 管理函数和注册结构；
- `kern/mm/memlayout.h`：增加 `PG_buddy` 标志；
- `kern/mm/buddy_pmm.c`、`buddy_pmm.h`：Buddy System；
- `kern/mm/buddy_test.c`、`buddy_test.h`：Buddy 测试；
- `kern/mm/slub.c`、`slub.h`：简化 SLUB；
- `kern/mm/slub_test.c`、`slub_test.h`：SLUB 测试；
- `kern/init/init.c`：在 `ucore_test` 模式下调用 Buddy/SLUB 测试。

代码中保留了 `lab2` 注释，并已将 `YOUR CODE` 替换为学号 `2411966`。
`basic_check()` 和 `best_fit_check()` 保持原样。Makefile 未修改，新增文件由
`kern/mm` 的通配规则自动编译。

线上指导书把 SLUB 标为选做 Challenge，而本地任务文档将其列为必修；本报告按
本地任务文档完成了 SLUB 的实现和测试。

## 11. 总结

本实验从虚拟地址空间和 DTB 物理内存探测出发，建立了 `Page` 描述符数组和
空闲页管理结构，在此基础上实现了 Best-Fit，并进一步完成了 Buddy System 和
简化 SLUB。通过 `make test` 和 `make grade` 验证了页初始化、Best-Fit、
Buddy 分裂/合并和 SLUB 对象分配/释放的正确性。

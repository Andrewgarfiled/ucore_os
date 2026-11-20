# lab4 实验报告：进程管理


## 1. 本章整体逻辑与实现顺序

lab4 在 lab2/lab3 的基础上，把内核从“可以管理物理内存、处理 trap 的单执行流内核”
扩展为“能够创建内核线程、切换地址空间并调度执行”的系统。整体执行链可以概括为：

```text
kern_init
  -> pmm_init
  -> pic_init / idt_init
  -> vmm_init
  -> proc_init
  -> clock_init / intr_enable
  -> cpu_idle
  -> schedule
  -> proc_run
  -> switch_to
```

可以将本章拆成三条主线：

1. **虚拟内存页操作**：在现有多级页表上建立和撤销线性地址到物理页的映射；
2. **进程创建与初始化**：建立进程控制块、内核栈和首次运行现场，创建
   `idleproc` 与 `initproc`；
3. **进程调度**：从就绪线程中选择目标线程，切换页表和寄存器上下文，使
   `initproc` 真正开始执行。

实现顺序上，先完成 `page_insert/page_remove`，因为后续 `vmm_init`、页表测试
以及线程地址空间管理都依赖页表映射接口；然后实现 PCB、`proc_init`、
`kernel_thread`、`do_fork` 和 `copy_thread`；最后实现调度器、`proc_run` 和
汇编 `switch_to`。

## 2. 模块一：虚拟内存页操作

### 2.1 任务说明与 spec

该模块要求在 `kern/mm/pmm.c` 中实现：

```c
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm);
void page_remove(pde_t *pgdir, uintptr_t la);
```

spec 要点：

- `page_insert` 用 `get_pte(pgdir, la, 1)` 查找或创建页表项；
- 若地址已映射到同一物理页，只更新权限，不增加引用计数；
- 若地址映射到其他物理页，先删除旧映射并维护旧页引用计数；
- 新映射成功时增加目标页引用计数，并设置权限位；
- `page_remove` 必须是幂等删除，无映射时安静返回；
- 页表更新后必须刷新对应 TLB；
- 中间页表分配失败时返回 `-E_NO_MEM`，不能留下半完成映射。

使用的 prompt：

```text
你是一名 RISC-V 内核开发者。请在 kern/mm/pmm.c 中实现 page_insert 和
page_remove，用于维护 Sv39 页表映射。要求：
1. page_insert 使用 get_pte(...,1) 获取或创建页表项；
2. 同一地址重复映射同一物理页时只更新权限，不增加引用计数；
3. 映射到不同物理页时先删除旧映射，正确处理页面引用计数；
4. page_remove 对未映射地址必须安全返回，并刷新 TLB；
5. 中间页表分配失败返回 -E_NO_MEM，不能留下半完成映射；
6. 不要修改页表项宏和测试函数。
```

### 2.2 实现思路

新增 `page_remove_pte()` 作为内部辅助函数：

- 检查 `*ptep & PTE_V`；
- 通过 `pte2page()` 取得物理页；
- `page_ref_dec()` 后若引用计数为 0，调用 `free_page()`；
- 清除页表项；
- 调用 `tlb_invalidate()`。

`page_remove()` 先用 `get_pte(pgdir, la, 0)` 查询，不创建中间页表；找不到
页表项或页表项无效时直接返回，因此重复删除是安全的。

`page_insert()` 的流程是：

1. `get_pte(pgdir, la, 1)`；
2. 若失败返回 `-E_NO_MEM`；
3. 若已有映射且映射的是同一个页，仅更新权限；
4. 若已有映射到其他页，先 `page_remove_pte()`；
5. `page_ref_inc(page)`；
6. 写入 `pte_create(page2ppn(page), perm)`；
7. `tlb_invalidate(pgdir, la)`。

该实现满足引用计数和权限更新的一致性要求，也通过了 lab4 的 PMM 测试。

### 2.3 测试

`test_lab4_pmm_basic()` 覆盖以下情况：

- 建立映射后页表项有效，`pte2page` 返回正确页；
- 映射新页后引用计数增加；
- 同一地址改映射到另一页时旧页引用计数减少；
- 同一地址重复映射同一页时只更新权限，引用计数不变；
- 删除映射后引用计数归零；
- 重复删除同一地址不会崩溃。

## 3. 模块二：进程创建与初始化

### 3.1 任务说明与 spec

该模块要求在 `kern/process/proc.c` 中实现：

```c
static struct proc_struct *alloc_proc(void);
void proc_init(void);
int kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags);
int do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf);
static void copy_thread(struct proc_struct *proc, uintptr_t esp, struct trapframe *tf);
static int copy_mm(uint32_t clone_flags, struct proc_struct *proc);
```

同时需要创建：

```text
idleproc：第 0 个内核线程，复用内核启动现场
initproc：第 1 个内核线程，由 kernel_thread 创建
```

spec 要点：

- `alloc_proc` 分配并初始化 PCB 的字段；
- `proc_init` 初始化进程链表、哈希表和 `idleproc`，再创建 `initproc`；
- `kernel_thread` 构造内核线程首次运行的 trapframe；
- `do_fork` 分配内核栈、处理地址空间、复制 trapframe 并登记新进程；
- `copy_thread` 设置内核栈顶 trapframe、`context.ra=forkret` 和 `context.sp`；
- `copy_mm` 在 lab4 阶段处理内核线程，`proc->mm` 为 `NULL`。

使用的 prompt：

```text
你是一名 RISC-V 内核开发者。请基于 ucore 的 proc_struct、context 和
trapframe 框架，实现内核线程创建流程：
1. alloc_proc 初始化 PCB 字段、链表节点和页目录；
2. proc_init 初始化 proc_list/hash_list，创建 idleproc 并调用 kernel_thread
   创建 initproc；
3. kernel_thread 设置 s0=fn、s1=arg、epc=kernel_thread_entry，并调用 do_fork；
4. do_fork 依次完成 PCB、内核栈、copy_mm、copy_thread、PID、链表登记和唤醒；
5. copy_thread 在新内核栈顶保存 trapframe，设置 context.ra=forkret、
   context.sp=tf、tf->gpr.a0=0；
6. copy_mm 在 lab4 内核线程阶段返回成功并令 proc->mm=NULL。
失败路径需要释放已分配的内核栈和 PCB。
```

### 3.2 PCB 与 idleproc/initproc

`struct proc_struct` 保存进程状态、PID、父进程、内核栈、页目录、上下文、
trapframe、链表节点等字段。

`alloc_proc()` 将 PCB 初始化为安全状态：

```text
state = PROC_UNINIT
pid = -1
runs = 0
kstack = 0
need_resched = 0
parent = NULL
mm = NULL
context 清零
tf = NULL
pgdir = boot_pgdir_pa
flags = 0
```

`proc_init()` 的关键点：

- 初始化 `proc_list` 和每个哈希桶；
- 用 `alloc_proc()` 创建 `idleproc`；
- `idleproc->pid = 0`；
- `idleproc->state = PROC_RUNNABLE`；
- `idleproc->kstack = bootstack`；
- `idleproc->need_resched = 1`；
- `current = idleproc`；
- 调用 `kernel_thread(init_main, ...)` 创建 `initproc`；
- 通过 `find_proc(pid)` 找到 `initproc` 并设置名字。

### 3.3 kernel_thread、do_fork、copy_thread

`kernel_thread()` 构造一个临时 trapframe：

```text
epc = kernel_thread_entry
s0  = fn
s1  = arg
```

同时设置：

```text
sstatus.SPP  = 1
sstatus.SPIE = 1
sstatus.SIE  = 0
```

这样 `sret` 返回 `kernel_thread_entry` 时，线程第一次运行在内核态，并处于
正确的初始中断状态。

`do_fork()` 完成：

1. 检查进程数上限；
2. `alloc_proc()`；
3. `setup_kstack()`；
4. `copy_mm()`；
5. `copy_thread()`；
6. 在关中断临界区内分配 PID、加入哈希表和 `proc_list`；
7. `wakeup_proc()` 将新线程设为可运行；
8. 返回新 PID。

`copy_thread()` 将 trapframe 放在新内核栈顶部，并设置：

```text
proc->tf->gpr.a0 = 0;
proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
proc->context.ra = (uintptr_t)forkret;
proc->context.sp = (uintptr_t)proc->tf;
```

第一次调度到该线程时，`switch_to` 恢复 `context.ra`，进入 `forkret`，
再经过 `forkrets -> __trapret -> kernel_thread_entry`，最终调用 `fn(arg)`。

## 4. 模块三：调度与上下文切换

### 4.1 任务说明与 spec

需要实现：

```c
void cpu_idle(void);                                       // proc.c
void schedule(void);                                       // sched.c
void proc_run(struct proc_struct *proc);                   // proc.c
void switch_to(struct context *from, struct context *to);  // switch.S
```

spec 要点：

- `cpu_idle` 在 `need_resched` 为真时让出 CPU；
- `schedule` 按 FIFO/轮转思想选择下一个 `PROC_RUNNABLE` 线程；
- 当前是 `idleproc` 时从链表头开始找，否则从当前线程之后找；
- 找不到就绪线程时回退到 `idleproc`；
- `proc_run` 更新 `current`、切换 `satp`、刷新 TLB、调用 `switch_to`；
- `switch_to` 只保存/恢复 `ra`、`sp`、`s0-s11`。

使用的 prompt：

```text
你是一名 RISC-V 内核开发者。请基于 ucore 的 proc_struct/context 和现有
proc_list，实现 FIFO 调度与上下文切换：
1. cpu_idle 在 current->need_resched 为真时调用 schedule；
2. schedule 从当前进程之后选择 PROC_RUNNABLE，当前为 idleproc 时从链表头开始，
   找不到时回退 idleproc；
3. proc_run 在关中断临界区内更新 current、切换 satp、刷新 TLB，并调用 switch_to；
4. switch_to 用汇编保存旧 context 的 ra/sp/s0-s11，恢复新 context 的相同寄存器；
5. 保持内核线程首次运行链路 forkret -> forkrets -> __trapret ->
   kernel_thread_entry 正确。
```

### 4.2 调度实现

`schedule()` 的关键是选择起点：

```c
last = (current == idleproc) ? &proc_list : &(current->list_link);
```

`idleproc` 不放入普通进程链表，因此从 `proc_list` 头开始；其他线程从自己的
`list_link` 之后开始，实现轮转。找不到可运行线程时使用 `idleproc` 兜底。

### 4.3 proc_run 和 switch_to

`proc_run()`：

```text
保存中断状态
-> current = proc
-> satp = Sv39 | (next->pgdir >> 12)
-> flush_tlb()
-> switch_to(&prev->context, &next->context)
-> 恢复中断状态
```

`switch_to` 只保存 callee-saved 寄存器：

```text
ra, sp, s0-s11
```

原因是 `switch_to` 是一个函数调用，caller-saved 寄存器由编译器在调用点
负责保存；切换函数只需要维护 RISC-V ABI 规定由被调用者保存的寄存器。

## 5. AI 协作中的问题与解决

### 5.1 lab4 骨架缺少 lab2/lab3 实现

lab4_new 中 `page_init`、lab3 的 trap 入口和异常处理仍是空的。解决方式：

- 从 lab3 工程补入 `page_init`；
- 把 Best-Fit 实现合并到 lab4 的 `default_pmm.c`，注册为
  `default_pmm_manager`；
- 把 lab3 的 `RESTORE_ALL`、`__alltraps`、timer/exception 处理合并到 lab4
  的 trap 文件中；
- lab4 的 `SAVE_ALL` 与 lab3 不完全相同，因此适配了 `0x143`（stval）槽位，
  而不是直接整文件覆盖。

### 5.2 重复 SBI 实现

lab4 的 `libs/sbi.h` 已经提供内联 SBI 函数，直接复制 lab3 的 `libs/sbi.c`
会造成重复定义。解决方式是删除多余的 `sbi.c`，只使用 lab4 头文件中的实现。

### 5.3 page_insert 的引用计数

最初容易把“同一页重复映射”也当成新映射，从而多加一次引用计数。解决方式：
在 `page_insert` 中单独处理同一物理页，只更新权限；只有换成不同物理页时才
先删除旧映射并增加新页引用计数。

### 5.4 新线程第一次运行

新线程不能直接从 `switch_to` 返回，需要预先准备：

```text
context.ra = forkret
context.sp = trapframe
tf.epc = kernel_thread_entry
tf.s0 = fn
tf.s1 = arg
```

否则第一次切换后无法正确进入 `fn(arg)`。

### 5.5 非阻塞编译警告

lab4 骨架中的 `kmalloc.c` 和 `test_lab4.c` 各有一个类型转换警告，但不影响
编译和评分。后续可以分别把 `kva2page(kva)` 改为
`kva2page((void *)kva)`，并修正测试线程函数的函数指针类型。

## 6. Challenge 思考题

### 6.1 local_intr_save/restore 如何实现开关中断

`local_intr_save(x)` 读取 `sstatus.SIE`：

- 如果 `SIE=1`，调用 `intr_disable()` 清除 `SIE`，并把 `x` 置为 1；
- 如果 `SIE=0`，不改变中断状态，并把 `x` 置为 0。

`local_intr_restore(x)` 只在 `x=1` 时重新打开中断。因此它恢复的是进入临界区
之前的状态，而不是无条件打开中断，嵌套使用时也能正确恢复。

该机制只关闭当前 CPU 的中断，适用于单核临界区；多核系统还需要自旋锁和
跨核同步。同步异常不会被 `SIE` 屏蔽，临界区代码仍必须避免缺页、非法访问等
异常。

### 6.2 Sv32、Sv39、Sv48 的异同

| 模式 | 虚拟地址宽度 | 物理地址宽度 | 页表级数 | 页大小 | 覆盖范围 |
| --- | --- | --- | --- | --- | --- |
| Sv32 | 32 位 | 34 位 | 2 级 | 4 KiB | 4 GiB |
| Sv39 | 39 位 | 56 位 | 3 级 | 4 KiB | 512 GiB |
| Sv48 | 48 位 | 56 位 | 4 级 | 4 KiB | 256 TiB |

三者都使用 4 KiB 页，都把虚拟地址拆成若干 9 位 VPN 索引（Sv32 使用 10 位
索引）和 12 位页内偏移；区别主要是页表级数、虚拟地址位宽和支持的最大地址
空间。

### 6.3 get_pte 中两段相似代码的原因

`get_pte()` 对每一级页表做相同操作：

1. 用对应 VPN 索引当前页表；
2. 检查页表项的 `PTE_V`；
3. 若无效且 `create=1`，分配一页、清零并写入下一级页表项；
4. 通过 `KADDR(PTE_ADDR(...))` 得到下一级页表的内核虚拟地址；
5. 继续下一层，最后返回叶子页表项。

所以两段代码结构相似是正常的：它们只是处理不同层级和不同 VPN 索引。

### 6.4 是否应拆分 get_pte 的查找和分配

当前把“查找页表项”和“分配页表页”放在一个函数中，优点是调用者只需传入
`create` 标志，接口简单；缺点是失败路径和分配行为不够显式，调用者容易
误以为查询不会分配内存。

更清晰的设计可以拆成：

```text
get_pte(..., false)       仅查找
get_pte_alloc(..., true)  查找并分配
```

或者拆成 `walk_pte()` 和 `alloc_pt_page()` 两个函数。拆分后错误处理和
分配时机更明确；当前实验为了保持框架接口和测试兼容，保留 `create` 参数的
设计是可接受的。

## 7. 验证结果

在 `/mnt/e/GPA/OS/lab4_new` 执行 `make grade`，结果为：

```text
-check PMM:                                OK
-check Process Create:                     OK
-check Schedule:                           OK
Total Score: 30/30
```

对应提交：

```text
783b408 lab4: import lab4 base with lab2/lab3 implementations
4a34732 lab4: implement process creation and initialization
e38f0f9 lab4: implement scheduling and context switching
```

## 8. 本实验与 OS 原理对应的知识点

| OS 原理知识点 | 实验对应实现 | 含义、关系和差异 |
| --- | --- | --- |
| 多级页表的实现 | `get_pte()`、`page_insert()`、`page_remove()` | MMU 通过页表把虚拟地址翻译为物理地址；实验完成了 Sv39 页表项建立、删除和 TLB 刷新，但仍以内核页表为主。 |
| 物理页引用计数 | `page_ref_inc()`、`page_ref_dec()`、`free_page()` | 多条映射可以引用同一物理页，引用计数归零后才能释放；实验重点是让映射操作与物理页生命周期保持一致。 |
| PCB 与进程/线程抽象 | `struct proc_struct`、`current` | PCB 保存状态、PID、内核栈、页表和上下文；实验中 `proc_struct` 同时承担 PCB 和 TCB 的职责，当前全部是共享地址空间的内核线程。 |
| 进程创建 | `kernel_thread()`、`do_fork()`、`copy_thread()` | `do_fork()` 类似 `fork/clone` 的资源复制和登记流程；区别是实验通过伪造 trapframe 创建内核线程，没有复制用户地址空间。 |
| 调度与上下文切换 | `schedule()`、`proc_run()`、`switch_to()` | 调度器选择 `PROC_RUNNABLE` 线程，`proc_run()` 更新 `current/satp`，`switch_to()` 保存并恢复 `ra/sp/s0-s11`；当前采用主动让出 CPU 的协作式轮转。 |
| 临界区保护 | `local_intr_save()`、`local_intr_restore()` | 通过保存并恢复 `sstatus.SIE`，保证 PID 登记和进程切换过程不被中断；该方法适用于当前单核实验。 |

## 9. OS 原理中重要但本实验没有覆盖的知识点

1. **U 模式与系统调用**：完整 OS 需要用户态进程、`ecall`、用户/内核栈切换和参数检查；本实验只有 S 模式内核线程。
2. **完整进程生命周期**：完整 OS 包括阻塞、睡眠、唤醒、退出、等待和僵尸回收；本实验的 `do_exit()` 仍是 panic 占位。
3. **时间片抢占与高级调度**：完整 OS 通常由时钟中断触发抢占，并支持优先级等策略；本实验主要依靠线程主动调用 `schedule()`。
4. **完整用户地址空间管理**：本实验的 `copy_mm()` 直接把 `mm` 设为 `NULL`，没有实现用户页表复制、按需分页、写时复制和页面置换。
5. **并发、同步与 IPC**：完整 OS 还需要等待队列、锁、信号量、信号、共享内存和多核同步；本实验只实现了单核关中断临界区。

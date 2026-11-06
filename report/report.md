# 实验报告

## 1.本章节整体逻辑线的理解
### 中断入口处理
本章节首先完成异常功能的核心——保存上下文和恢复上下文
这部分功能是汇编完成，是所有异常操作必须的操作，即在trapentry.S中完成
需要在理解利用栈指针的处理流程基础上，完成RESTORE宏和中断处理函数的控制流转移
这部分完成从__alltraps被调用到处理到返回到用户程序
```
__alltraps:
    SAVE_ALL
    mv a0, sp
    jal trap
    .globl __trapret
__trapret:
    RESTORE_ALL
    sret
```

### 为了行使异常功能，初始化部分的工作
这部分没有具体要完成的代码

```
    idt_init();  // init interrupt descriptor table
    clock_init();   // init clock interrupt
    intr_enable();  // enable irq interrupt
```
### 已经完成了功能的初始化（设置csr寄存器、调用时钟中断sbicall），之后是__alltraps:处的任务
这部分完成RESTORE恢复（对称恢复+sp恢复）
将__alltraps补充完整：保存，传参，跳处理函数、恢复、sret结束
### 实现具体异常/中断处理逻辑
这一部分需要阅读riscv对于scause的约定（最高位表示异常/中断分类），才能理解
条件分发：
```
 if ((intptr_t)tf->cause < 0) 
```
掩码覆盖（需要去掉最高位）：
```
#define CAUSE_CODE_MASK (~((uintptr_t)1 << 63))
 uintptr_t cause = tf->cause & CAUSE_CODE_MASK;
```
以及根据指令编码判断指令长度:
```
static inline uintptr_t instruction_length(uintptr_t epc) {
    return (*(uint16_t *)epc & 0x3) == 0x3 ? 4 : 2;
}

```
的逻辑。

之后这部分以时钟中断为例，需要了解clock_set_next_event()接口，调用sbi_shutdown()
其基本逻辑只是以cpu时钟计数单位去计时1s，即100次间隔10ms的时钟中断。
```
    switch (cause) {
    case IRQ_S_TIMER: {
        static int print_count = 0;
        // Arm the next clock event, otherwise only one interrupt arrives.
        clock_set_next_event();
        ticks++;
        if (ticks % TICK_NUM == 0) {
            print_ticks();
            print_count++;
            if (print_count >= SHUTDOWN_AFTER) {
                sbi_shutdown();
            }
        }
        break;
    }
```
###中断的关闭和开启
这一节主要是讲述在引入对csr寄存器及其控制的cpu异常/中断功能开启后，以前的模块需要增加什么控制。
## 2.核心函数或功能模块

核心函数：
初始化组
```
    idt_init(); 
    clock_init();  
    intr_enable(); 
```
这部分主要就是各种写寄存器“write_csr(stvec, &__alltraps);”或设置状态set_csr(sstatus, SSTATUS_SIE);。根本上就是设置cpu功能。
其中时钟部分主要是clock_set_next_event();做的sbicall封装。



上下文保存组（省略保存/恢复宏）
```
__alltraps:
    SAVE_ALL
    mv a0, sp
    jal trap
    .globl __trapret
__trapret:
    RESTORE_ALL
    sret
```
这部分理解sp的作用，以及之后我们的处理程序额外需要用到哪些cpu自动写入的寄存器信息，了解之后即可理解save和restore的顺序。

时钟中断组
```
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
```
trap分派处理组
```
trap_dispatch(tf);
void exception_handler(struct trapframe *tf)
interrupt_handler(struct trapframe *tf) 
static inline uintptr_t instruction_length(uintptr_t epc)
```
这部分核心就是了解riscv的规定，以及落实成switch/if逻辑+位操作。时钟处理部分就是对全局变量的计数。

## 3. 提示词设计
###练习1
```
[PROMPT]
**任务**：修改 kern/trap/trapentry.S，实现 RESTORE_ALL 宏，并在 __alltraps 中建立
“汇编入口 -> C 函数 trap() -> 返回”的调用关系。二者共同保证：Trap 发生后上下文能保存、
能传给 trap()，trap() 返回后原执行流能恢复。

**操作要求**：你必须在项目中修改实际文件，而不是仅展示代码。保留 SAVE_ALL、struct trapframe、
trap() 的签名、__trapret 与 sret，以及 `#lab3 functionN YOUR CODE` 注释行，不删除既有逻辑；
只在标记位置补全。

**输出要求**：直接进行文件操作，使用下面 [RELY]、[GUARANTEE]、[SPECIFICATION] 的信息，
不要引入浮点寄存器、页表或调度相关功能。
```
```
[SPECIFICATION]
RESTORE_ALL

Pre-Condition:

    只能在 __trapret 处使用；进入宏时 sp 指向一个由 SAVE_ALL 建立、布局与 struct trapframe 完全一致的完整 Trap frame；Trap frame 之上的内存不被改写。

Post-Condition:

    sstatus、sepc、sbadaddr、scause 已从 32~35 号槽位恢复。
    x1、x3~x31 已从对应槽位恢复；x0 不恢复。
    x2(sp) 从 2 号槽位恢复，并且是最后被恢复的动作；宏结束时 sp 等于 Trap 发生前的值，不再指向 Trap frame。调用方随后执行 sret 即可回到被打断的执行流。

Requirements:

    SAVE_ALL 对 x2 的处理与众不同：它把原 sp 放进 2 号槽位，并未在“保存期间”恢复 sp。因此恢复时不能把 x2 与其他寄存器同等看待，也不能在 x2 恢复之后继续用 sp 定位 Trap frame。
    内存访问一律使用 riscv.h 的 LOAD 宏（随 __riscv_xlen 展开为 ld 或 lw），不得写死宽度。
    CSR 不能直接从内存装载，需经通用寄存器中转；所选临时寄存器必须在其后的通用寄存器恢复阶段被重新覆盖。

__alltraps

Pre-Condition:

    SAVE_ALL 已经执行，sp 恰好等于 Trap frame 首地址。

Post-Condition:

    以“进入时 sp 的值”作为唯一实参调用 void trap(struct trapframe *tf)； trap() 返回后 sp 数值仍等于该值，Trap frame 内容未被局部覆写，随后顺序落入 __trapret。

Requirements:

    不得在调用 trap() 前后调整 sp；不得在调用前把 Trap frame 搬到别处。
```
练习2
```
[PROMPT]
**任务**：修改 kern/trap/trap.c，实现 interrupt_handler() 与 exception_handler()，
补齐 Trap 的分类处理：中断按原因分派（时钟中断需维持周期性并统计，达到规定次数关机），
异常中非法指令与断点需输出信息并推进执行位置，其余走兜底打印。

**操作要求**：你必须在项目中修改实际文件，而不是仅展示代码。保留已有的 trap_dispatch()、trap()、
print_trapframe()、print_regs()、print_ticks() 与 `//lab3 function2 YOUR CODE` 注释行；
两个处理函数必须保持外部链接（测试代码以 extern 引用）。不得修改函数签名。

**输出要求**：直接进行文件操作，使用下面 [RELY]、[GUARANTEE]、[SPECIFICATION] 的信息，
不要引入系统调用、进程调度或日志模块。

[RELY]
// 宏定义（libs/riscv.h）
#define IRQ_S_SOFT   1
#define IRQ_S_TIMER  5
#define IRQ_S_EXT    9
#define CAUSE_ILLEGAL_INSTRUCTION 0x2
#define CAUSE_BREAKPOINT          0x3

// scause / tf->cause：最高位为 1 表示中断，为 0 表示异常；中断时低位承载中断码，
// 异常时低位承载异常码。框架中不提供现成的掩码宏，需要自行屏蔽最高位后再比较中断码。

// 数据结构（kern/trap/trap.h）
struct trapframe { struct pushregs gpr; uintptr_t status; uintptr_t epc;
                   uintptr_t badvaddr; uintptr_t cause; };

// 已有的函数与全局量（kern/trap/trap.c、kern/driver/clock.h、libs/sbi.h）
#define TICK_NUM 100
static void print_ticks(void) { cprintf("%d ticks\n", TICK_NUM); }
void print_trapframe(struct trapframe *tf);   // 打印完整 Trap frame，格式不得修改
void clock_set_next_event(void);              // 设定下一次时钟事件
extern volatile size_t ticks;                 // 时钟中断计数
void sbi_shutdown(void);                      // OpenSBI 关机
// 框架中未提供关机阈值宏
// 已有的分发逻辑（不可修改）：
static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) interrupt_handler(tf);
    else                         exception_handler(tf);
}

[GUARANTEE]
必须实现或修改的接口：

void interrupt_handler(struct trapframe *tf);
void exception_handler(struct trapframe *tf);


[SPECIFICATION]
interrupt_handler

Pre-Condition:

    tf 非空；tf->cause 最高位为 1；中断码位于低位。

Post-Condition:

    不修改 tf 中的上下文；返回后由 __trapret 恢复并回到原执行流。

    Case 1（IRQ_S_TIMER）:
        每次进入都设定下一次时钟事件（否则只能收到一次中断），并令时钟计数加一；每当计数达到 TICK_NUM 的整数倍时输出一次规定格式的统计信息；统计信息累计输出次数达到 SHUTDOWN_AFTER 时调用关机接口结束系统。

    Case 2（IRQ_S_SOFT）:
        输出 "Supervisor software interrupt"。

    Case 3（IRQ_S_EXT）:
        输出 "Supervisor external interrupt"。

    Case 4（其他中断码）:
        输出带原因码的提示（"Unknown interrupt: cause N"），并调用 print_trapframe(tf)。

Requirements:

    判断类型前必须屏蔽 tf->cause 最高位，不能直接把整个 cause 与中断码比较。
    统计次数在 boot 后从 0 开始且单调递增，不因其它类型中断或异常被重置或增加；其取值应能保证测试等待窗口内（时钟计数到达 200 之前）不会提前关机。

exception_handler

Pre-Condition:

    tf 非空；tf->cause 最高位为 0；异常码位于低位。

Post-Condition:

    非法指令与断点两条路径都把 tf->epc 更新为“异常指令之后的位置”，trap 返回后不重复触发同一异常；其余异常不修改 tf。

    Case 1（CAUSE_ILLEGAL_INSTRUCTION）:
        输出 "Illegal instruction at 0x..."（地址为触发异常的 epc），并令 tf->epc 指向该指令之后。

    Case 2（CAUSE_BREAKPOINT）:
        输出 "Breakpoint at 0x..."（地址为触发异常的 epc），并令 tf->epc 指向该指令之后。

    Case 3（其他异常码）:
        仅调用 print_trapframe(tf) 兜底，不修改 tf->epc。

Requirements:

    不得一律按 4 字节推进 epc：RISC-V 允许 16 位压缩指令，epc 的前进量必须依据被触发指令自身的编码（低 2 位）判断，32 位与 16 位分别处理。
    只允许读取 epc 处的指令编码，不得依赖任何全局状态或上一次异常的信息。
    两个处理函数必须保持外部链接，不得加 static。

```
## 4. 出现的bug
在尝试和模型协作的过程中，一开始让模型解决这两个函数时，模型把它们声明为静态函数，这对于单文件是没有问题的。但测评没过。分析原因后是由于测评方式需要extern这两个函数，因此不能设置为静态。这次的bug属于是给模型的上下文/约束不足。
```
interrupt_handler(struct trapframe *tf)
exception_handler(struct trapframe *tf)
```

## 5.本实验中重要的知识点，以及与对应 OS 原理中的知识点
本实验重要的知识点有
同步和异步异常区别、在riscv处理器中异常发生时CPU所做的工作与操作系统所做的工作、异常时的返回指令处理、异常上下文的保存与恢复、软件如何知道异常类型等等。
与os原理中知识点基本一致。
## 6. OS原理中重要但本实验没对应上的知识点
由于本实验的异常和中断处理只具体实现了时钟中断、因此其余大量需要操作系统分类处理的中断和异常均未涉及。如指令地址对齐异常、缺页异常、系统调用异常、断点异常、软件中断、外设中断等等。

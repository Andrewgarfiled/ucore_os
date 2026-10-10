# 实验报告

## 练习1：

**第一问：** 内核启动时也需要一部分空间，所以在entry.S里bootstack和bootstacktop标签分别指明栈底和栈顶位置，la sp, bootstacktop将栈顶放进sp寄存器中，后续程序可以在sp基础上偏移来使用栈。

`.global bootstacktop`、`.global bootstack`确保了这两个地址对链接过程中的其他文件可见，`.space KSTACKSIZE`指定了栈空间的大小，KSTACKPAGE为2、PGSIZE为4096，所以栈是8KB。`.align PGSHIFT`让它对齐到页边界。

la是伪指令，展开成auipc加addi。反汇编entry.o看到是`auipc sp,0`与`mv sp,sp`，链接后是`auipc sp,0x3`与`mv sp,sp`。这里auipc sp,0x3算出的地址是0x80200000加0x3000等于0x80203000，正好就是bootstacktop的地址，低12位偏移是0，所以第二条退化成了mv sp,sp这条看起来没意义的指令。栈从高地址向低地址增长，所以初始时把栈顶而不是栈底给sp。

**第二问：** tail symbol是尾调用伪指令。默认基础指令为auipc x6, offset[31:12] 与 jalr x0, x6, offset[11:0]；这里auipc把kern_init高20位加到pc对应位置上，装进x6。jalr把返回值写进x0（永久为0）意味着丢弃返回值，把kern_init低12位加到pc上，完成完整的地址copy，然后跳转到kern_init。这里整体代表着设置完了栈寄存器，跳转到剩下的启动代码。

反汇编entry.o验证了目标寄存器是x6也就是t1，写成`auipc t1,0`与`jr t1`，没有写ra，确实只是跳转不是调用，因为kern_init声明了noreturn最后进死循环，不会返回。链接时经过relax就变成一条`j 8020000a <kern_init>`。

## 练习2：

初始启动指令流：初始地址为0x1000。设置寄存器a0（读取控制和状态寄存器），a1、a2设置设备树参数，之后跳转到t0处，t0的值经过ld立即数之后正好是后面的0x1018处。由小端序表示，这里的0x1018 0x1019 0x101a 0x101b 四字节正好构成0x80000000。

```
(gdb) x/10i $pc
=> 0x1000:	auipc	t0,0x0
   0x1004:	addi	a2,t0,40
   0x1008:	csrr	a0,mhartid
   0x100c:	ld	a1,32(t0)
   0x1010:	ld	t0,24(t0)
   0x1014:	jr	t0
   0x1018:	unimp
   0x101a:	0x8000
```

addi a2,t0,40算出0x1028用来传设备树之类的参数，ld a1,32(t0)是从0x1020取设备树地址。


之后在kern_entry处加入断点，观察到开始kern_entry以及之后的kern_init，说明开始正式内核加载

```
(gdb)  b* kern_entry
Breakpoint 1 at 0x80200000: file kern/init/entry.S, line 7.
(gdb) c
Continuing.

Breakpoint 1, kern_entry () at kern/init/entry.S:7
7	    la sp, bootstacktop		#加载 bootstacktop的地址到sp中，意味着下面是栈顶，
(gdb) x/10i $pc
=> 0x80200000 <kern_entry>:	auipc	sp,0x3
   0x80200004 <kern_entry+4>:	mv	sp,sp
   0x80200008 <kern_entry+8>:	j	0x8020000a <kern_init>
   0x8020000a <kern_init>:	auipc	a0,0x3
   0x8020000e <kern_init+4>:	addi	a0,a0,-2
   0x80200012 <kern_init+8>:	auipc	a2,0x3
   0x80200016 <kern_init+12>:	addi	a2,a2,-10
   0x8020001a <kern_init+16>:	addi	sp,sp,-16
   0x8020001c <kern_init+18>:	li	a1,0
   0x8020001e <kern_init+20>:	sub	a2,a2,a0
```

从0x8020000a开始就是kern_init，后面几条在给memset准备参数，a0是edata，a2是end，a1是0，还开了16字节栈帧。



# 2. 本章节逻辑线

操作系统本身是程序，裸机需要自己的硬件及固件机制支持开机后某个时刻开始把操作系统代码搬到内存并设置PC运行——QEMU作为实验模拟器，bootloader: OpenSBI固件，复位及初始运行地址约定

正常可执行程序本身需要操作系统支持，引出问题：裸机初始加载操作系统程序本身应该是bin文件。继而引出自己配置bin文件布局的需要，介绍链接相关知识。
由链接时自行设置内存布局及入口点地址引入口点程序所需工作，以及后续跳转到的初始化函数。

由裸机无标准库提供支持，引出RISC-V架构下操作系统重要功能：对底层OpenSBI提供的基础支持进行上层封装。

讲解完本章节程序，介绍编译相关知识——Makefile文件，gdb的监听调试与基本使用，提供调试内核的基本工具。

# 3. 核心函数或功能模块

组成可执行bin文件——汇编代码、链接脚本、交叉编译器及objcopy命令
初始加载——QEMU模拟器、OpenSBI
内核程序：    memset(edata, 0, end - edata);及    cprintf("%s\n\n", message);
memset是不需要OpenSBI支持的高层封装代表，只是根据传入指针和填充数据执行搬运mv。
cprintf是需要OpenSBI支持的高层封装代表

entry.S是入口点，负责分配内核栈然后跳到kern_init。edata和end是链接脚本用PROVIDE定义的符号，分别指向数据段结束和bss段结束，清bss是因为bss的初值全是0、bin文件里不保存这些字节，必须运行时自己清零。这里实际编译出来bss是空的，edata和end都是0x80203008，所以这次memset长度是0，但代码是通用必要的。

cprintf那条链是逐层往下封装的：cprintf到vcprintf到vprintfmt，vprintfmt解析格式串，每出来一个字符回调cputch，再到cons_putc，最后落到sbi_console_putchar。sbi_call用内联汇编是因为要跨特权级，内核在S模式、SBI在M模式，必须用ecall，功能号放x17，参数放x10到x12，返回值从x10取。console.c里cons_putc只有一行，看着多余但把设备相关的细节隔在driver层了。

kernel.ld规定内存布局，text从BASE_ADDRESS也就是0x80200000开始，后面rodata，再用ALIGN(0x1000)对齐到下一页放data和sdata，最后bss，并导出etext、edata、end给C代码用。

Makefile负责编译链接，用ld加-T指定链接脚本、nostdlib、gc-sections链接出bin/kernel，再用objcopy生成bin/ucore.img，最后用qemu-system-riscv64启动。

# 4. 重要知识点及与OS原理的对应

复位地址0x1000到OpenSBI到0x80200000，对应OS原理里的操作系统引导，真实PC上是UEFI加GRUB，这里是QEMU内置固件，链条是一样的。

entry.S设置sp、.space KSTACKSIZE，对应栈的管理，栈是函数调用和局部变量的载体，从高地址向低地址增长。差异是这里还没有进程概念，没有PCB，也没有内核栈和用户栈的区分。

链接脚本和objcopy，对应程序的装入与地址空间布局，程序必须装到编译时假设的地址。差异是真实OS靠页表和重定位做到地址无关和虚拟地址空间，这里还没开分页，用的是物理地址。

sbi_call用ecall从S模式陷入M模式，对应系统调用和特权级机制，系统调用是用户态通过陷阱指令请内核服务，涉及特权级切换、参数约定、返回值约定，这里ecall从S进M和从U进S完全同构。差异是方向不同，这里是内核向固件请求服务，而且还没有trap处理流程和中断向量表。

cprintf的分层封装，对应I/O软件层次结构，原理上分用户层、设备无关层、驱动层、中断处理层，这里是个微缩版。差异是没有缓冲区、没有中断驱动的I/O，是同步轮询输出。

bss清零对应可执行文件格式与内存初始化，bss只记录大小和位置不存内容，装入时清零以省空间。差异是真实OS的装载器按段处理并建映射，这里只是清零一段连续物理内存。

# 5. OS原理中重要但本实验没对应上的知识点

中断与异常处理。trap机制、stvec、中断向量表、时钟中断、上下文的保存恢复，本实验全程是关中断的直线代码，kern/trap还没启用。

进程与线程管理。PCB、进程状态转换、创建撤销、上下文切换、调度算法，lab1里只有内核自己在跑，连当前进程这个概念都没有，while(1)就是全部。

虚拟内存与分页。多级页表、PTE设计、MMU地址翻译、缺页异常、页面置换，本实验直接用物理地址，kern/mm下的pmm.c还没实现。

同步与互斥。临界区、信号量、管程、死锁，本实验是单线程顺序执行，不存在并发。

文件系统。VFS、inode、目录项、文件描述符、块设备缓冲，lab1连硬盘上的文件这个概念都还没有，ucore.img是被QEMU直接加载的裸镜像。

用户态与系统调用接口。U模式和S模式隔离、真正的系统调用入口、用户程序加载、进程地址空间隔离，lab1的ecall机制虽然同构但方向和用途都不是系统调用。

并发与多处理器。多hart启动、自旋锁、原子操作、内存屏障，lab1虽然读了mhartid但只用了hart 0。

设备驱动的完整实现。中断驱动的串口键盘输入、DMA、时钟设备编程，lab1的cons_init是空函数，输入也只有一个简单的getchar封装。


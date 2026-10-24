
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00007297          	auipc	t0,0x7
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0207000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00007297          	auipc	t0,0x7
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0207008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02062b7          	lui	t0,0xc0206
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200034:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200038:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc020003c:	c0206137          	lui	sp,0xc0206

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	0d828293          	addi	t0,t0,216 # ffffffffc02000d8 <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020004a:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[];
    cprintf("Special kernel symbols:\n");
ffffffffc020004c:	00002517          	auipc	a0,0x2
ffffffffc0200050:	63c50513          	addi	a0,a0,1596 # ffffffffc0202688 <etext>
void print_kerninfo(void) {
ffffffffc0200054:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200056:	0fe000ef          	jal	ra,ffffffffc0200154 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", (uintptr_t)kern_init);
ffffffffc020005a:	00000597          	auipc	a1,0x0
ffffffffc020005e:	07e58593          	addi	a1,a1,126 # ffffffffc02000d8 <kern_init>
ffffffffc0200062:	00002517          	auipc	a0,0x2
ffffffffc0200066:	64650513          	addi	a0,a0,1606 # ffffffffc02026a8 <etext+0x20>
ffffffffc020006a:	0ea000ef          	jal	ra,ffffffffc0200154 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020006e:	00002597          	auipc	a1,0x2
ffffffffc0200072:	61a58593          	addi	a1,a1,1562 # ffffffffc0202688 <etext>
ffffffffc0200076:	00002517          	auipc	a0,0x2
ffffffffc020007a:	65250513          	addi	a0,a0,1618 # ffffffffc02026c8 <etext+0x40>
ffffffffc020007e:	0d6000ef          	jal	ra,ffffffffc0200154 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200082:	00007597          	auipc	a1,0x7
ffffffffc0200086:	f9e58593          	addi	a1,a1,-98 # ffffffffc0207020 <free_area>
ffffffffc020008a:	00002517          	auipc	a0,0x2
ffffffffc020008e:	65e50513          	addi	a0,a0,1630 # ffffffffc02026e8 <etext+0x60>
ffffffffc0200092:	0c2000ef          	jal	ra,ffffffffc0200154 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200096:	00007597          	auipc	a1,0x7
ffffffffc020009a:	2f258593          	addi	a1,a1,754 # ffffffffc0207388 <end>
ffffffffc020009e:	00002517          	auipc	a0,0x2
ffffffffc02000a2:	66a50513          	addi	a0,a0,1642 # ffffffffc0202708 <etext+0x80>
ffffffffc02000a6:	0ae000ef          	jal	ra,ffffffffc0200154 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - (char*)kern_init + 1023) / 1024);
ffffffffc02000aa:	00007597          	auipc	a1,0x7
ffffffffc02000ae:	6dd58593          	addi	a1,a1,1757 # ffffffffc0207787 <end+0x3ff>
ffffffffc02000b2:	00000797          	auipc	a5,0x0
ffffffffc02000b6:	02678793          	addi	a5,a5,38 # ffffffffc02000d8 <kern_init>
ffffffffc02000ba:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000be:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02000c2:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000c4:	3ff5f593          	andi	a1,a1,1023
ffffffffc02000c8:	95be                	add	a1,a1,a5
ffffffffc02000ca:	85a9                	srai	a1,a1,0xa
ffffffffc02000cc:	00002517          	auipc	a0,0x2
ffffffffc02000d0:	65c50513          	addi	a0,a0,1628 # ffffffffc0202728 <etext+0xa0>
}
ffffffffc02000d4:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000d6:	a8bd                	j	ffffffffc0200154 <cprintf>

ffffffffc02000d8 <kern_init>:

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc02000d8:	00007517          	auipc	a0,0x7
ffffffffc02000dc:	f4850513          	addi	a0,a0,-184 # ffffffffc0207020 <free_area>
ffffffffc02000e0:	00007617          	auipc	a2,0x7
ffffffffc02000e4:	2a860613          	addi	a2,a2,680 # ffffffffc0207388 <end>
int kern_init(void) {
ffffffffc02000e8:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc02000ea:	8e09                	sub	a2,a2,a0
ffffffffc02000ec:	4581                	li	a1,0
int kern_init(void) {
ffffffffc02000ee:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc02000f0:	586020ef          	jal	ra,ffffffffc0202676 <memset>
    dtb_init();
ffffffffc02000f4:	134000ef          	jal	ra,ffffffffc0200228 <dtb_init>
    cons_init();  // init the console
ffffffffc02000f8:	126000ef          	jal	ra,ffffffffc020021e <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc02000fc:	00002517          	auipc	a0,0x2
ffffffffc0200100:	65c50513          	addi	a0,a0,1628 # ffffffffc0202758 <etext+0xd0>
ffffffffc0200104:	086000ef          	jal	ra,ffffffffc020018a <cputs>

    print_kerninfo();
ffffffffc0200108:	f43ff0ef          	jal	ra,ffffffffc020004a <print_kerninfo>

    // grade_backtrace();
    pmm_init();  // init physical memory management
ffffffffc020010c:	061010ef          	jal	ra,ffffffffc020196c <pmm_init>

#ifdef ucore_test
    buddy_test();
ffffffffc0200110:	40a010ef          	jal	ra,ffffffffc020151a <buddy_test>
    slub_test();
ffffffffc0200114:	583010ef          	jal	ra,ffffffffc0201e96 <slub_test>
#endif

    /* do nothing */
    while (1)
ffffffffc0200118:	a001                	j	ffffffffc0200118 <kern_init+0x40>

ffffffffc020011a <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc020011a:	1141                	addi	sp,sp,-16
ffffffffc020011c:	e022                	sd	s0,0(sp)
ffffffffc020011e:	e406                	sd	ra,8(sp)
ffffffffc0200120:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200122:	0fe000ef          	jal	ra,ffffffffc0200220 <cons_putc>
    (*cnt) ++;
ffffffffc0200126:	401c                	lw	a5,0(s0)
}
ffffffffc0200128:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc020012a:	2785                	addiw	a5,a5,1
ffffffffc020012c:	c01c                	sw	a5,0(s0)
}
ffffffffc020012e:	6402                	ld	s0,0(sp)
ffffffffc0200130:	0141                	addi	sp,sp,16
ffffffffc0200132:	8082                	ret

ffffffffc0200134 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200134:	1101                	addi	sp,sp,-32
ffffffffc0200136:	862a                	mv	a2,a0
ffffffffc0200138:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020013a:	00000517          	auipc	a0,0x0
ffffffffc020013e:	fe050513          	addi	a0,a0,-32 # ffffffffc020011a <cputch>
ffffffffc0200142:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200144:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc0200146:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200148:	118020ef          	jal	ra,ffffffffc0202260 <vprintfmt>
    return cnt;
}
ffffffffc020014c:	60e2                	ld	ra,24(sp)
ffffffffc020014e:	4532                	lw	a0,12(sp)
ffffffffc0200150:	6105                	addi	sp,sp,32
ffffffffc0200152:	8082                	ret

ffffffffc0200154 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc0200154:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc0200156:	02810313          	addi	t1,sp,40 # ffffffffc0206028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc020015a:	8e2a                	mv	t3,a0
ffffffffc020015c:	f42e                	sd	a1,40(sp)
ffffffffc020015e:	f832                	sd	a2,48(sp)
ffffffffc0200160:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200162:	00000517          	auipc	a0,0x0
ffffffffc0200166:	fb850513          	addi	a0,a0,-72 # ffffffffc020011a <cputch>
ffffffffc020016a:	004c                	addi	a1,sp,4
ffffffffc020016c:	869a                	mv	a3,t1
ffffffffc020016e:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc0200170:	ec06                	sd	ra,24(sp)
ffffffffc0200172:	e0ba                	sd	a4,64(sp)
ffffffffc0200174:	e4be                	sd	a5,72(sp)
ffffffffc0200176:	e8c2                	sd	a6,80(sp)
ffffffffc0200178:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc020017a:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc020017c:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020017e:	0e2020ef          	jal	ra,ffffffffc0202260 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc0200182:	60e2                	ld	ra,24(sp)
ffffffffc0200184:	4512                	lw	a0,4(sp)
ffffffffc0200186:	6125                	addi	sp,sp,96
ffffffffc0200188:	8082                	ret

ffffffffc020018a <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc020018a:	1101                	addi	sp,sp,-32
ffffffffc020018c:	e822                	sd	s0,16(sp)
ffffffffc020018e:	ec06                	sd	ra,24(sp)
ffffffffc0200190:	e426                	sd	s1,8(sp)
ffffffffc0200192:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc0200194:	00054503          	lbu	a0,0(a0)
ffffffffc0200198:	c51d                	beqz	a0,ffffffffc02001c6 <cputs+0x3c>
ffffffffc020019a:	0405                	addi	s0,s0,1
ffffffffc020019c:	4485                	li	s1,1
ffffffffc020019e:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc02001a0:	080000ef          	jal	ra,ffffffffc0200220 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc02001a4:	00044503          	lbu	a0,0(s0)
ffffffffc02001a8:	008487bb          	addw	a5,s1,s0
ffffffffc02001ac:	0405                	addi	s0,s0,1
ffffffffc02001ae:	f96d                	bnez	a0,ffffffffc02001a0 <cputs+0x16>
    (*cnt) ++;
ffffffffc02001b0:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc02001b4:	4529                	li	a0,10
ffffffffc02001b6:	06a000ef          	jal	ra,ffffffffc0200220 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001ba:	60e2                	ld	ra,24(sp)
ffffffffc02001bc:	8522                	mv	a0,s0
ffffffffc02001be:	6442                	ld	s0,16(sp)
ffffffffc02001c0:	64a2                	ld	s1,8(sp)
ffffffffc02001c2:	6105                	addi	sp,sp,32
ffffffffc02001c4:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc02001c6:	4405                	li	s0,1
ffffffffc02001c8:	b7f5                	j	ffffffffc02001b4 <cputs+0x2a>

ffffffffc02001ca <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02001ca:	00007317          	auipc	t1,0x7
ffffffffc02001ce:	16e30313          	addi	t1,t1,366 # ffffffffc0207338 <is_panic>
ffffffffc02001d2:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02001d6:	715d                	addi	sp,sp,-80
ffffffffc02001d8:	ec06                	sd	ra,24(sp)
ffffffffc02001da:	e822                	sd	s0,16(sp)
ffffffffc02001dc:	f436                	sd	a3,40(sp)
ffffffffc02001de:	f83a                	sd	a4,48(sp)
ffffffffc02001e0:	fc3e                	sd	a5,56(sp)
ffffffffc02001e2:	e0c2                	sd	a6,64(sp)
ffffffffc02001e4:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02001e6:	000e0363          	beqz	t3,ffffffffc02001ec <__panic+0x22>
    vcprintf(fmt, ap);
    cprintf("\n");
    va_end(ap);

panic_dead:
    while (1) {
ffffffffc02001ea:	a001                	j	ffffffffc02001ea <__panic+0x20>
    is_panic = 1;
ffffffffc02001ec:	4785                	li	a5,1
ffffffffc02001ee:	00f32023          	sw	a5,0(t1)
    va_start(ap, fmt);
ffffffffc02001f2:	8432                	mv	s0,a2
ffffffffc02001f4:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001f6:	862e                	mv	a2,a1
ffffffffc02001f8:	85aa                	mv	a1,a0
ffffffffc02001fa:	00002517          	auipc	a0,0x2
ffffffffc02001fe:	57e50513          	addi	a0,a0,1406 # ffffffffc0202778 <etext+0xf0>
    va_start(ap, fmt);
ffffffffc0200202:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200204:	f51ff0ef          	jal	ra,ffffffffc0200154 <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200208:	65a2                	ld	a1,8(sp)
ffffffffc020020a:	8522                	mv	a0,s0
ffffffffc020020c:	f29ff0ef          	jal	ra,ffffffffc0200134 <vcprintf>
    cprintf("\n");
ffffffffc0200210:	00002517          	auipc	a0,0x2
ffffffffc0200214:	54050513          	addi	a0,a0,1344 # ffffffffc0202750 <etext+0xc8>
ffffffffc0200218:	f3dff0ef          	jal	ra,ffffffffc0200154 <cprintf>
ffffffffc020021c:	b7f9                	j	ffffffffc02001ea <__panic+0x20>

ffffffffc020021e <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc020021e:	8082                	ret

ffffffffc0200220 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200220:	0ff57513          	zext.b	a0,a0
ffffffffc0200224:	3be0206f          	j	ffffffffc02025e2 <sbi_console_putchar>

ffffffffc0200228 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc0200228:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc020022a:	00002517          	auipc	a0,0x2
ffffffffc020022e:	56e50513          	addi	a0,a0,1390 # ffffffffc0202798 <etext+0x110>
void dtb_init(void) {
ffffffffc0200232:	fc86                	sd	ra,120(sp)
ffffffffc0200234:	f8a2                	sd	s0,112(sp)
ffffffffc0200236:	e8d2                	sd	s4,80(sp)
ffffffffc0200238:	f4a6                	sd	s1,104(sp)
ffffffffc020023a:	f0ca                	sd	s2,96(sp)
ffffffffc020023c:	ecce                	sd	s3,88(sp)
ffffffffc020023e:	e4d6                	sd	s5,72(sp)
ffffffffc0200240:	e0da                	sd	s6,64(sp)
ffffffffc0200242:	fc5e                	sd	s7,56(sp)
ffffffffc0200244:	f862                	sd	s8,48(sp)
ffffffffc0200246:	f466                	sd	s9,40(sp)
ffffffffc0200248:	f06a                	sd	s10,32(sp)
ffffffffc020024a:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc020024c:	f09ff0ef          	jal	ra,ffffffffc0200154 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200250:	00007597          	auipc	a1,0x7
ffffffffc0200254:	db05b583          	ld	a1,-592(a1) # ffffffffc0207000 <boot_hartid>
ffffffffc0200258:	00002517          	auipc	a0,0x2
ffffffffc020025c:	55050513          	addi	a0,a0,1360 # ffffffffc02027a8 <etext+0x120>
ffffffffc0200260:	ef5ff0ef          	jal	ra,ffffffffc0200154 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc0200264:	00007417          	auipc	s0,0x7
ffffffffc0200268:	da440413          	addi	s0,s0,-604 # ffffffffc0207008 <boot_dtb>
ffffffffc020026c:	600c                	ld	a1,0(s0)
ffffffffc020026e:	00002517          	auipc	a0,0x2
ffffffffc0200272:	54a50513          	addi	a0,a0,1354 # ffffffffc02027b8 <etext+0x130>
ffffffffc0200276:	edfff0ef          	jal	ra,ffffffffc0200154 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc020027a:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc020027e:	00002517          	auipc	a0,0x2
ffffffffc0200282:	55250513          	addi	a0,a0,1362 # ffffffffc02027d0 <etext+0x148>
    if (boot_dtb == 0) {
ffffffffc0200286:	120a0463          	beqz	s4,ffffffffc02003ae <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc020028a:	57f5                	li	a5,-3
ffffffffc020028c:	07fa                	slli	a5,a5,0x1e
ffffffffc020028e:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200292:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200294:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200298:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020029a:	0087d59b          	srliw	a1,a5,0x8
ffffffffc020029e:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002a2:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002a6:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002aa:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002ae:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002b0:	8ec9                	or	a3,a3,a0
ffffffffc02002b2:	0087979b          	slliw	a5,a5,0x8
ffffffffc02002b6:	1b7d                	addi	s6,s6,-1
ffffffffc02002b8:	0167f7b3          	and	a5,a5,s6
ffffffffc02002bc:	8dd5                	or	a1,a1,a3
ffffffffc02002be:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc02002c0:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002c4:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc02002c6:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed8b65>
ffffffffc02002ca:	10f59163          	bne	a1,a5,ffffffffc02003cc <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02002ce:	471c                	lw	a5,8(a4)
ffffffffc02002d0:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc02002d2:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002d4:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02002d8:	0086d51b          	srliw	a0,a3,0x8
ffffffffc02002dc:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e0:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002e4:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e8:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002ec:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002f0:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002f4:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002f8:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002fc:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002fe:	01146433          	or	s0,s0,a7
ffffffffc0200302:	0086969b          	slliw	a3,a3,0x8
ffffffffc0200306:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020030a:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020030c:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200310:	8c49                	or	s0,s0,a0
ffffffffc0200312:	0166f6b3          	and	a3,a3,s6
ffffffffc0200316:	00ca6a33          	or	s4,s4,a2
ffffffffc020031a:	0167f7b3          	and	a5,a5,s6
ffffffffc020031e:	8c55                	or	s0,s0,a3
ffffffffc0200320:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200324:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200326:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200328:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020032a:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020032e:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200330:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200332:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc0200336:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200338:	00002917          	auipc	s2,0x2
ffffffffc020033c:	4e890913          	addi	s2,s2,1256 # ffffffffc0202820 <etext+0x198>
ffffffffc0200340:	49bd                	li	s3,15
        switch (token) {
ffffffffc0200342:	4d91                	li	s11,4
ffffffffc0200344:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200346:	00002497          	auipc	s1,0x2
ffffffffc020034a:	4d248493          	addi	s1,s1,1234 # ffffffffc0202818 <etext+0x190>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc020034e:	000a2703          	lw	a4,0(s4)
ffffffffc0200352:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200356:	0087569b          	srliw	a3,a4,0x8
ffffffffc020035a:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020035e:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200362:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200366:	0107571b          	srliw	a4,a4,0x10
ffffffffc020036a:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020036c:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200370:	0087171b          	slliw	a4,a4,0x8
ffffffffc0200374:	8fd5                	or	a5,a5,a3
ffffffffc0200376:	00eb7733          	and	a4,s6,a4
ffffffffc020037a:	8fd9                	or	a5,a5,a4
ffffffffc020037c:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc020037e:	09778c63          	beq	a5,s7,ffffffffc0200416 <dtb_init+0x1ee>
ffffffffc0200382:	00fbea63          	bltu	s7,a5,ffffffffc0200396 <dtb_init+0x16e>
ffffffffc0200386:	07a78663          	beq	a5,s10,ffffffffc02003f2 <dtb_init+0x1ca>
ffffffffc020038a:	4709                	li	a4,2
ffffffffc020038c:	00e79763          	bne	a5,a4,ffffffffc020039a <dtb_init+0x172>
ffffffffc0200390:	4c81                	li	s9,0
ffffffffc0200392:	8a56                	mv	s4,s5
ffffffffc0200394:	bf6d                	j	ffffffffc020034e <dtb_init+0x126>
ffffffffc0200396:	ffb78ee3          	beq	a5,s11,ffffffffc0200392 <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc020039a:	00002517          	auipc	a0,0x2
ffffffffc020039e:	4fe50513          	addi	a0,a0,1278 # ffffffffc0202898 <etext+0x210>
ffffffffc02003a2:	db3ff0ef          	jal	ra,ffffffffc0200154 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc02003a6:	00002517          	auipc	a0,0x2
ffffffffc02003aa:	52a50513          	addi	a0,a0,1322 # ffffffffc02028d0 <etext+0x248>
}
ffffffffc02003ae:	7446                	ld	s0,112(sp)
ffffffffc02003b0:	70e6                	ld	ra,120(sp)
ffffffffc02003b2:	74a6                	ld	s1,104(sp)
ffffffffc02003b4:	7906                	ld	s2,96(sp)
ffffffffc02003b6:	69e6                	ld	s3,88(sp)
ffffffffc02003b8:	6a46                	ld	s4,80(sp)
ffffffffc02003ba:	6aa6                	ld	s5,72(sp)
ffffffffc02003bc:	6b06                	ld	s6,64(sp)
ffffffffc02003be:	7be2                	ld	s7,56(sp)
ffffffffc02003c0:	7c42                	ld	s8,48(sp)
ffffffffc02003c2:	7ca2                	ld	s9,40(sp)
ffffffffc02003c4:	7d02                	ld	s10,32(sp)
ffffffffc02003c6:	6de2                	ld	s11,24(sp)
ffffffffc02003c8:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc02003ca:	b369                	j	ffffffffc0200154 <cprintf>
}
ffffffffc02003cc:	7446                	ld	s0,112(sp)
ffffffffc02003ce:	70e6                	ld	ra,120(sp)
ffffffffc02003d0:	74a6                	ld	s1,104(sp)
ffffffffc02003d2:	7906                	ld	s2,96(sp)
ffffffffc02003d4:	69e6                	ld	s3,88(sp)
ffffffffc02003d6:	6a46                	ld	s4,80(sp)
ffffffffc02003d8:	6aa6                	ld	s5,72(sp)
ffffffffc02003da:	6b06                	ld	s6,64(sp)
ffffffffc02003dc:	7be2                	ld	s7,56(sp)
ffffffffc02003de:	7c42                	ld	s8,48(sp)
ffffffffc02003e0:	7ca2                	ld	s9,40(sp)
ffffffffc02003e2:	7d02                	ld	s10,32(sp)
ffffffffc02003e4:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003e6:	00002517          	auipc	a0,0x2
ffffffffc02003ea:	40a50513          	addi	a0,a0,1034 # ffffffffc02027f0 <etext+0x168>
}
ffffffffc02003ee:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003f0:	b395                	j	ffffffffc0200154 <cprintf>
                int name_len = strlen(name);
ffffffffc02003f2:	8556                	mv	a0,s5
ffffffffc02003f4:	208020ef          	jal	ra,ffffffffc02025fc <strlen>
ffffffffc02003f8:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003fa:	4619                	li	a2,6
ffffffffc02003fc:	85a6                	mv	a1,s1
ffffffffc02003fe:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc0200400:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200402:	24e020ef          	jal	ra,ffffffffc0202650 <strncmp>
ffffffffc0200406:	e111                	bnez	a0,ffffffffc020040a <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc0200408:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc020040a:	0a91                	addi	s5,s5,4
ffffffffc020040c:	9ad2                	add	s5,s5,s4
ffffffffc020040e:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200412:	8a56                	mv	s4,s5
ffffffffc0200414:	bf2d                	j	ffffffffc020034e <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200416:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc020041a:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020041e:	0087d71b          	srliw	a4,a5,0x8
ffffffffc0200422:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200426:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020042a:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020042e:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200432:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200436:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020043a:	0087979b          	slliw	a5,a5,0x8
ffffffffc020043e:	00eaeab3          	or	s5,s5,a4
ffffffffc0200442:	00fb77b3          	and	a5,s6,a5
ffffffffc0200446:	00faeab3          	or	s5,s5,a5
ffffffffc020044a:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020044c:	000c9c63          	bnez	s9,ffffffffc0200464 <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200450:	1a82                	slli	s5,s5,0x20
ffffffffc0200452:	00368793          	addi	a5,a3,3
ffffffffc0200456:	020ada93          	srli	s5,s5,0x20
ffffffffc020045a:	9abe                	add	s5,s5,a5
ffffffffc020045c:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200460:	8a56                	mv	s4,s5
ffffffffc0200462:	b5f5                	j	ffffffffc020034e <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200464:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200468:	85ca                	mv	a1,s2
ffffffffc020046a:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020046c:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200470:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200474:	0187971b          	slliw	a4,a5,0x18
ffffffffc0200478:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020047c:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200480:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200482:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200486:	0087979b          	slliw	a5,a5,0x8
ffffffffc020048a:	8d59                	or	a0,a0,a4
ffffffffc020048c:	00fb77b3          	and	a5,s6,a5
ffffffffc0200490:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc0200492:	1502                	slli	a0,a0,0x20
ffffffffc0200494:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200496:	9522                	add	a0,a0,s0
ffffffffc0200498:	19a020ef          	jal	ra,ffffffffc0202632 <strcmp>
ffffffffc020049c:	66a2                	ld	a3,8(sp)
ffffffffc020049e:	f94d                	bnez	a0,ffffffffc0200450 <dtb_init+0x228>
ffffffffc02004a0:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200450 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc02004a4:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02004a8:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02004ac:	00002517          	auipc	a0,0x2
ffffffffc02004b0:	37c50513          	addi	a0,a0,892 # ffffffffc0202828 <etext+0x1a0>
           fdt32_to_cpu(x >> 32);
ffffffffc02004b4:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004b8:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc02004bc:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004c0:	0187de1b          	srliw	t3,a5,0x18
ffffffffc02004c4:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c8:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004cc:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004d0:	0187d693          	srli	a3,a5,0x18
ffffffffc02004d4:	01861f1b          	slliw	t5,a2,0x18
ffffffffc02004d8:	0087579b          	srliw	a5,a4,0x8
ffffffffc02004dc:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004e0:	0106561b          	srliw	a2,a2,0x10
ffffffffc02004e4:	010f6f33          	or	t5,t5,a6
ffffffffc02004e8:	0187529b          	srliw	t0,a4,0x18
ffffffffc02004ec:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004f0:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004f4:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004f8:	0186f6b3          	and	a3,a3,s8
ffffffffc02004fc:	01859e1b          	slliw	t3,a1,0x18
ffffffffc0200500:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200504:	0107581b          	srliw	a6,a4,0x10
ffffffffc0200508:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020050c:	8361                	srli	a4,a4,0x18
ffffffffc020050e:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200512:	0105d59b          	srliw	a1,a1,0x10
ffffffffc0200516:	01e6e6b3          	or	a3,a3,t5
ffffffffc020051a:	00cb7633          	and	a2,s6,a2
ffffffffc020051e:	0088181b          	slliw	a6,a6,0x8
ffffffffc0200522:	0085959b          	slliw	a1,a1,0x8
ffffffffc0200526:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020052a:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020052e:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200532:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200536:	0088989b          	slliw	a7,a7,0x8
ffffffffc020053a:	011b78b3          	and	a7,s6,a7
ffffffffc020053e:	005eeeb3          	or	t4,t4,t0
ffffffffc0200542:	00c6e733          	or	a4,a3,a2
ffffffffc0200546:	006c6c33          	or	s8,s8,t1
ffffffffc020054a:	010b76b3          	and	a3,s6,a6
ffffffffc020054e:	00bb7b33          	and	s6,s6,a1
ffffffffc0200552:	01d7e7b3          	or	a5,a5,t4
ffffffffc0200556:	016c6b33          	or	s6,s8,s6
ffffffffc020055a:	01146433          	or	s0,s0,a7
ffffffffc020055e:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc0200560:	1702                	slli	a4,a4,0x20
ffffffffc0200562:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200564:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200566:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200568:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc020056a:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020056e:	0167eb33          	or	s6,a5,s6
ffffffffc0200572:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200574:	be1ff0ef          	jal	ra,ffffffffc0200154 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc0200578:	85a2                	mv	a1,s0
ffffffffc020057a:	00002517          	auipc	a0,0x2
ffffffffc020057e:	2ce50513          	addi	a0,a0,718 # ffffffffc0202848 <etext+0x1c0>
ffffffffc0200582:	bd3ff0ef          	jal	ra,ffffffffc0200154 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc0200586:	014b5613          	srli	a2,s6,0x14
ffffffffc020058a:	85da                	mv	a1,s6
ffffffffc020058c:	00002517          	auipc	a0,0x2
ffffffffc0200590:	2d450513          	addi	a0,a0,724 # ffffffffc0202860 <etext+0x1d8>
ffffffffc0200594:	bc1ff0ef          	jal	ra,ffffffffc0200154 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200598:	008b05b3          	add	a1,s6,s0
ffffffffc020059c:	15fd                	addi	a1,a1,-1
ffffffffc020059e:	00002517          	auipc	a0,0x2
ffffffffc02005a2:	2e250513          	addi	a0,a0,738 # ffffffffc0202880 <etext+0x1f8>
ffffffffc02005a6:	bafff0ef          	jal	ra,ffffffffc0200154 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc02005aa:	00002517          	auipc	a0,0x2
ffffffffc02005ae:	32650513          	addi	a0,a0,806 # ffffffffc02028d0 <etext+0x248>
        memory_base = mem_base;
ffffffffc02005b2:	00007797          	auipc	a5,0x7
ffffffffc02005b6:	d887b723          	sd	s0,-626(a5) # ffffffffc0207340 <memory_base>
        memory_size = mem_size;
ffffffffc02005ba:	00007797          	auipc	a5,0x7
ffffffffc02005be:	d967b723          	sd	s6,-626(a5) # ffffffffc0207348 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc02005c2:	b3f5                	j	ffffffffc02003ae <dtb_init+0x186>

ffffffffc02005c4 <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc02005c4:	00007517          	auipc	a0,0x7
ffffffffc02005c8:	d7c53503          	ld	a0,-644(a0) # ffffffffc0207340 <memory_base>
ffffffffc02005cc:	8082                	ret

ffffffffc02005ce <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc02005ce:	00007517          	auipc	a0,0x7
ffffffffc02005d2:	d7a53503          	ld	a0,-646(a0) # ffffffffc0207348 <memory_size>
ffffffffc02005d6:	8082                	ret

ffffffffc02005d8 <best_fit_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc02005d8:	00007797          	auipc	a5,0x7
ffffffffc02005dc:	a4878793          	addi	a5,a5,-1464 # ffffffffc0207020 <free_area>
ffffffffc02005e0:	e79c                	sd	a5,8(a5)
ffffffffc02005e2:	e39c                	sd	a5,0(a5)
}

static void
best_fit_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc02005e4:	0007a823          	sw	zero,16(a5)
}
ffffffffc02005e8:	8082                	ret

ffffffffc02005ea <best_fit_nr_free_pages>:
}

static size_t
best_fit_nr_free_pages(void) {
    return nr_free;
}
ffffffffc02005ea:	00007517          	auipc	a0,0x7
ffffffffc02005ee:	a4656503          	lwu	a0,-1466(a0) # ffffffffc0207030 <free_area+0x10>
ffffffffc02005f2:	8082                	ret

ffffffffc02005f4 <best_fit_check>:
    free_page(p1);
    free_page(p2);
}

static void
best_fit_check(void) {
ffffffffc02005f4:	715d                	addi	sp,sp,-80
ffffffffc02005f6:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc02005f8:	00007417          	auipc	s0,0x7
ffffffffc02005fc:	a2840413          	addi	s0,s0,-1496 # ffffffffc0207020 <free_area>
ffffffffc0200600:	641c                	ld	a5,8(s0)
ffffffffc0200602:	e486                	sd	ra,72(sp)
ffffffffc0200604:	fc26                	sd	s1,56(sp)
ffffffffc0200606:	f84a                	sd	s2,48(sp)
ffffffffc0200608:	f44e                	sd	s3,40(sp)
ffffffffc020060a:	f052                	sd	s4,32(sp)
ffffffffc020060c:	ec56                	sd	s5,24(sp)
ffffffffc020060e:	e85a                	sd	s6,16(sp)
ffffffffc0200610:	e45e                	sd	s7,8(sp)
ffffffffc0200612:	e062                	sd	s8,0(sp)
    int score = 0, sumscore = 6;
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200614:	2c878963          	beq	a5,s0,ffffffffc02008e6 <best_fit_check+0x2f2>
    int count = 0, total = 0;
ffffffffc0200618:	4481                	li	s1,0
ffffffffc020061a:	4901                	li	s2,0
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc020061c:	ff07b703          	ld	a4,-16(a5)
ffffffffc0200620:	8b09                	andi	a4,a4,2
ffffffffc0200622:	2c070663          	beqz	a4,ffffffffc02008ee <best_fit_check+0x2fa>
        count++, total += p->property;
ffffffffc0200626:	ff87a703          	lw	a4,-8(a5)
ffffffffc020062a:	679c                	ld	a5,8(a5)
ffffffffc020062c:	2905                	addiw	s2,s2,1
ffffffffc020062e:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200630:	fe8796e3          	bne	a5,s0,ffffffffc020061c <best_fit_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0200634:	89a6                	mv	s3,s1
ffffffffc0200636:	32a010ef          	jal	ra,ffffffffc0201960 <nr_free_pages>
ffffffffc020063a:	39351a63          	bne	a0,s3,ffffffffc02009ce <best_fit_check+0x3da>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020063e:	4505                	li	a0,1
ffffffffc0200640:	308010ef          	jal	ra,ffffffffc0201948 <alloc_pages>
ffffffffc0200644:	8a2a                	mv	s4,a0
ffffffffc0200646:	3c050463          	beqz	a0,ffffffffc0200a0e <best_fit_check+0x41a>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020064a:	4505                	li	a0,1
ffffffffc020064c:	2fc010ef          	jal	ra,ffffffffc0201948 <alloc_pages>
ffffffffc0200650:	89aa                	mv	s3,a0
ffffffffc0200652:	38050e63          	beqz	a0,ffffffffc02009ee <best_fit_check+0x3fa>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200656:	4505                	li	a0,1
ffffffffc0200658:	2f0010ef          	jal	ra,ffffffffc0201948 <alloc_pages>
ffffffffc020065c:	8aaa                	mv	s5,a0
ffffffffc020065e:	32050863          	beqz	a0,ffffffffc020098e <best_fit_check+0x39a>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200662:	2b3a0663          	beq	s4,s3,ffffffffc020090e <best_fit_check+0x31a>
ffffffffc0200666:	2aaa0463          	beq	s4,a0,ffffffffc020090e <best_fit_check+0x31a>
ffffffffc020066a:	2aa98263          	beq	s3,a0,ffffffffc020090e <best_fit_check+0x31a>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc020066e:	000a2783          	lw	a5,0(s4)
ffffffffc0200672:	2a079e63          	bnez	a5,ffffffffc020092e <best_fit_check+0x33a>
ffffffffc0200676:	0009a783          	lw	a5,0(s3)
ffffffffc020067a:	2a079a63          	bnez	a5,ffffffffc020092e <best_fit_check+0x33a>
ffffffffc020067e:	411c                	lw	a5,0(a0)
ffffffffc0200680:	2a079763          	bnez	a5,ffffffffc020092e <best_fit_check+0x33a>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200684:	00007797          	auipc	a5,0x7
ffffffffc0200688:	cdc7b783          	ld	a5,-804(a5) # ffffffffc0207360 <pages>
ffffffffc020068c:	40fa0733          	sub	a4,s4,a5
ffffffffc0200690:	870d                	srai	a4,a4,0x3
ffffffffc0200692:	00003597          	auipc	a1,0x3
ffffffffc0200696:	fd65b583          	ld	a1,-42(a1) # ffffffffc0203668 <error_string+0x38>
ffffffffc020069a:	02b70733          	mul	a4,a4,a1
ffffffffc020069e:	00003617          	auipc	a2,0x3
ffffffffc02006a2:	fd263603          	ld	a2,-46(a2) # ffffffffc0203670 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02006a6:	00007697          	auipc	a3,0x7
ffffffffc02006aa:	cb26b683          	ld	a3,-846(a3) # ffffffffc0207358 <npage>
ffffffffc02006ae:	06b2                	slli	a3,a3,0xc
ffffffffc02006b0:	9732                	add	a4,a4,a2

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc02006b2:	0732                	slli	a4,a4,0xc
ffffffffc02006b4:	28d77d63          	bgeu	a4,a3,ffffffffc020094e <best_fit_check+0x35a>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02006b8:	40f98733          	sub	a4,s3,a5
ffffffffc02006bc:	870d                	srai	a4,a4,0x3
ffffffffc02006be:	02b70733          	mul	a4,a4,a1
ffffffffc02006c2:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02006c4:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02006c6:	44d77463          	bgeu	a4,a3,ffffffffc0200b0e <best_fit_check+0x51a>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02006ca:	40f507b3          	sub	a5,a0,a5
ffffffffc02006ce:	878d                	srai	a5,a5,0x3
ffffffffc02006d0:	02b787b3          	mul	a5,a5,a1
ffffffffc02006d4:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02006d6:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02006d8:	40d7fb63          	bgeu	a5,a3,ffffffffc0200aee <best_fit_check+0x4fa>
    assert(alloc_page() == NULL);
ffffffffc02006dc:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc02006de:	00043c03          	ld	s8,0(s0)
ffffffffc02006e2:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc02006e6:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc02006ea:	e400                	sd	s0,8(s0)
ffffffffc02006ec:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc02006ee:	00007797          	auipc	a5,0x7
ffffffffc02006f2:	9407a123          	sw	zero,-1726(a5) # ffffffffc0207030 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc02006f6:	252010ef          	jal	ra,ffffffffc0201948 <alloc_pages>
ffffffffc02006fa:	3c051a63          	bnez	a0,ffffffffc0200ace <best_fit_check+0x4da>
    free_page(p0);
ffffffffc02006fe:	4585                	li	a1,1
ffffffffc0200700:	8552                	mv	a0,s4
ffffffffc0200702:	252010ef          	jal	ra,ffffffffc0201954 <free_pages>
    free_page(p1);
ffffffffc0200706:	4585                	li	a1,1
ffffffffc0200708:	854e                	mv	a0,s3
ffffffffc020070a:	24a010ef          	jal	ra,ffffffffc0201954 <free_pages>
    free_page(p2);
ffffffffc020070e:	4585                	li	a1,1
ffffffffc0200710:	8556                	mv	a0,s5
ffffffffc0200712:	242010ef          	jal	ra,ffffffffc0201954 <free_pages>
    assert(nr_free == 3);
ffffffffc0200716:	4818                	lw	a4,16(s0)
ffffffffc0200718:	478d                	li	a5,3
ffffffffc020071a:	38f71a63          	bne	a4,a5,ffffffffc0200aae <best_fit_check+0x4ba>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020071e:	4505                	li	a0,1
ffffffffc0200720:	228010ef          	jal	ra,ffffffffc0201948 <alloc_pages>
ffffffffc0200724:	89aa                	mv	s3,a0
ffffffffc0200726:	36050463          	beqz	a0,ffffffffc0200a8e <best_fit_check+0x49a>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020072a:	4505                	li	a0,1
ffffffffc020072c:	21c010ef          	jal	ra,ffffffffc0201948 <alloc_pages>
ffffffffc0200730:	8aaa                	mv	s5,a0
ffffffffc0200732:	32050e63          	beqz	a0,ffffffffc0200a6e <best_fit_check+0x47a>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200736:	4505                	li	a0,1
ffffffffc0200738:	210010ef          	jal	ra,ffffffffc0201948 <alloc_pages>
ffffffffc020073c:	8a2a                	mv	s4,a0
ffffffffc020073e:	30050863          	beqz	a0,ffffffffc0200a4e <best_fit_check+0x45a>
    assert(alloc_page() == NULL);
ffffffffc0200742:	4505                	li	a0,1
ffffffffc0200744:	204010ef          	jal	ra,ffffffffc0201948 <alloc_pages>
ffffffffc0200748:	2e051363          	bnez	a0,ffffffffc0200a2e <best_fit_check+0x43a>
    free_page(p0);
ffffffffc020074c:	4585                	li	a1,1
ffffffffc020074e:	854e                	mv	a0,s3
ffffffffc0200750:	204010ef          	jal	ra,ffffffffc0201954 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200754:	641c                	ld	a5,8(s0)
ffffffffc0200756:	20878c63          	beq	a5,s0,ffffffffc020096e <best_fit_check+0x37a>
    assert((p = alloc_page()) == p0);
ffffffffc020075a:	4505                	li	a0,1
ffffffffc020075c:	1ec010ef          	jal	ra,ffffffffc0201948 <alloc_pages>
ffffffffc0200760:	58a99763          	bne	s3,a0,ffffffffc0200cee <best_fit_check+0x6fa>
    assert(alloc_page() == NULL);
ffffffffc0200764:	4505                	li	a0,1
ffffffffc0200766:	1e2010ef          	jal	ra,ffffffffc0201948 <alloc_pages>
ffffffffc020076a:	56051263          	bnez	a0,ffffffffc0200cce <best_fit_check+0x6da>
    assert(nr_free == 0);
ffffffffc020076e:	481c                	lw	a5,16(s0)
ffffffffc0200770:	52079f63          	bnez	a5,ffffffffc0200cae <best_fit_check+0x6ba>
    free_page(p);
ffffffffc0200774:	854e                	mv	a0,s3
ffffffffc0200776:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200778:	01843023          	sd	s8,0(s0)
ffffffffc020077c:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0200780:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0200784:	1d0010ef          	jal	ra,ffffffffc0201954 <free_pages>
    free_page(p1);
ffffffffc0200788:	4585                	li	a1,1
ffffffffc020078a:	8556                	mv	a0,s5
ffffffffc020078c:	1c8010ef          	jal	ra,ffffffffc0201954 <free_pages>
    free_page(p2);
ffffffffc0200790:	4585                	li	a1,1
ffffffffc0200792:	8552                	mv	a0,s4
ffffffffc0200794:	1c0010ef          	jal	ra,ffffffffc0201954 <free_pages>

    basic_check();

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
ffffffffc0200798:	4619                	li	a2,6
ffffffffc020079a:	4585                	li	a1,1
ffffffffc020079c:	00002517          	auipc	a0,0x2
ffffffffc02007a0:	34450513          	addi	a0,a0,836 # ffffffffc0202ae0 <etext+0x458>
ffffffffc02007a4:	9b1ff0ef          	jal	ra,ffffffffc0200154 <cprintf>
    #endif
    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc02007a8:	4515                	li	a0,5
ffffffffc02007aa:	19e010ef          	jal	ra,ffffffffc0201948 <alloc_pages>
ffffffffc02007ae:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc02007b0:	4c050f63          	beqz	a0,ffffffffc0200c8e <best_fit_check+0x69a>
    assert(!PageProperty(p0));
ffffffffc02007b4:	651c                	ld	a5,8(a0)
ffffffffc02007b6:	8b89                	andi	a5,a5,2
ffffffffc02007b8:	4a079b63          	bnez	a5,ffffffffc0200c6e <best_fit_check+0x67a>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
ffffffffc02007bc:	4619                	li	a2,6
ffffffffc02007be:	4589                	li	a1,2
ffffffffc02007c0:	00002517          	auipc	a0,0x2
ffffffffc02007c4:	32050513          	addi	a0,a0,800 # ffffffffc0202ae0 <etext+0x458>
ffffffffc02007c8:	98dff0ef          	jal	ra,ffffffffc0200154 <cprintf>
    #endif
    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc02007cc:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc02007ce:	00043b03          	ld	s6,0(s0)
ffffffffc02007d2:	00843a83          	ld	s5,8(s0)
ffffffffc02007d6:	e000                	sd	s0,0(s0)
ffffffffc02007d8:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc02007da:	16e010ef          	jal	ra,ffffffffc0201948 <alloc_pages>
ffffffffc02007de:	46051863          	bnez	a0,ffffffffc0200c4e <best_fit_check+0x65a>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
ffffffffc02007e2:	4619                	li	a2,6
ffffffffc02007e4:	458d                	li	a1,3
ffffffffc02007e6:	00002517          	auipc	a0,0x2
ffffffffc02007ea:	2fa50513          	addi	a0,a0,762 # ffffffffc0202ae0 <etext+0x458>
ffffffffc02007ee:	967ff0ef          	jal	ra,ffffffffc0200154 <cprintf>
    #endif
    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    // * - - * -
    free_pages(p0 + 1, 2);
ffffffffc02007f2:	4589                	li	a1,2
ffffffffc02007f4:	02898513          	addi	a0,s3,40
    unsigned int nr_free_store = nr_free;
ffffffffc02007f8:	01042b83          	lw	s7,16(s0)
    free_pages(p0 + 4, 1);
ffffffffc02007fc:	0a098c13          	addi	s8,s3,160
    nr_free = 0;
ffffffffc0200800:	00007797          	auipc	a5,0x7
ffffffffc0200804:	8207a823          	sw	zero,-2000(a5) # ffffffffc0207030 <free_area+0x10>
    free_pages(p0 + 1, 2);
ffffffffc0200808:	14c010ef          	jal	ra,ffffffffc0201954 <free_pages>
    free_pages(p0 + 4, 1);
ffffffffc020080c:	8562                	mv	a0,s8
ffffffffc020080e:	4585                	li	a1,1
ffffffffc0200810:	144010ef          	jal	ra,ffffffffc0201954 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200814:	4511                	li	a0,4
ffffffffc0200816:	132010ef          	jal	ra,ffffffffc0201948 <alloc_pages>
ffffffffc020081a:	40051a63          	bnez	a0,ffffffffc0200c2e <best_fit_check+0x63a>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc020081e:	0309b783          	ld	a5,48(s3)
ffffffffc0200822:	8b89                	andi	a5,a5,2
ffffffffc0200824:	3e078563          	beqz	a5,ffffffffc0200c0e <best_fit_check+0x61a>
ffffffffc0200828:	0389a703          	lw	a4,56(s3)
ffffffffc020082c:	4789                	li	a5,2
ffffffffc020082e:	3ef71063          	bne	a4,a5,ffffffffc0200c0e <best_fit_check+0x61a>
    // * - - * *
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0200832:	4505                	li	a0,1
ffffffffc0200834:	114010ef          	jal	ra,ffffffffc0201948 <alloc_pages>
ffffffffc0200838:	8a2a                	mv	s4,a0
ffffffffc020083a:	3a050a63          	beqz	a0,ffffffffc0200bee <best_fit_check+0x5fa>
    assert(alloc_pages(2) != NULL);
ffffffffc020083e:	4509                	li	a0,2
ffffffffc0200840:	108010ef          	jal	ra,ffffffffc0201948 <alloc_pages>
ffffffffc0200844:	38050563          	beqz	a0,ffffffffc0200bce <best_fit_check+0x5da>
    assert(p0 + 4 == p1);
ffffffffc0200848:	374c1363          	bne	s8,s4,ffffffffc0200bae <best_fit_check+0x5ba>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
ffffffffc020084c:	4619                	li	a2,6
ffffffffc020084e:	4591                	li	a1,4
ffffffffc0200850:	00002517          	auipc	a0,0x2
ffffffffc0200854:	29050513          	addi	a0,a0,656 # ffffffffc0202ae0 <etext+0x458>
ffffffffc0200858:	8fdff0ef          	jal	ra,ffffffffc0200154 <cprintf>
    #endif
    p2 = p0 + 1;
    free_pages(p0, 5);
ffffffffc020085c:	854e                	mv	a0,s3
ffffffffc020085e:	4595                	li	a1,5
ffffffffc0200860:	0f4010ef          	jal	ra,ffffffffc0201954 <free_pages>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200864:	4515                	li	a0,5
ffffffffc0200866:	0e2010ef          	jal	ra,ffffffffc0201948 <alloc_pages>
ffffffffc020086a:	89aa                	mv	s3,a0
ffffffffc020086c:	32050163          	beqz	a0,ffffffffc0200b8e <best_fit_check+0x59a>
    assert(alloc_page() == NULL);
ffffffffc0200870:	4505                	li	a0,1
ffffffffc0200872:	0d6010ef          	jal	ra,ffffffffc0201948 <alloc_pages>
ffffffffc0200876:	2e051c63          	bnez	a0,ffffffffc0200b6e <best_fit_check+0x57a>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
ffffffffc020087a:	4619                	li	a2,6
ffffffffc020087c:	4595                	li	a1,5
ffffffffc020087e:	00002517          	auipc	a0,0x2
ffffffffc0200882:	26250513          	addi	a0,a0,610 # ffffffffc0202ae0 <etext+0x458>
ffffffffc0200886:	8cfff0ef          	jal	ra,ffffffffc0200154 <cprintf>
    #endif
    assert(nr_free == 0);
ffffffffc020088a:	481c                	lw	a5,16(s0)
ffffffffc020088c:	2c079163          	bnez	a5,ffffffffc0200b4e <best_fit_check+0x55a>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0200890:	4595                	li	a1,5
ffffffffc0200892:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0200894:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc0200898:	01643023          	sd	s6,0(s0)
ffffffffc020089c:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc02008a0:	0b4010ef          	jal	ra,ffffffffc0201954 <free_pages>
    return listelm->next;
ffffffffc02008a4:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc02008a6:	00878963          	beq	a5,s0,ffffffffc02008b8 <best_fit_check+0x2c4>
        struct Page *p = le2page(le, page_link);
        count--, total -= p->property;
ffffffffc02008aa:	ff87a703          	lw	a4,-8(a5)
ffffffffc02008ae:	679c                	ld	a5,8(a5)
ffffffffc02008b0:	397d                	addiw	s2,s2,-1
ffffffffc02008b2:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc02008b4:	fe879be3          	bne	a5,s0,ffffffffc02008aa <best_fit_check+0x2b6>
    }
    assert(count == 0);
ffffffffc02008b8:	26091b63          	bnez	s2,ffffffffc0200b2e <best_fit_check+0x53a>
    assert(total == 0);
ffffffffc02008bc:	0e049963          	bnez	s1,ffffffffc02009ae <best_fit_check+0x3ba>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
    #endif
}
ffffffffc02008c0:	6406                	ld	s0,64(sp)
ffffffffc02008c2:	60a6                	ld	ra,72(sp)
ffffffffc02008c4:	74e2                	ld	s1,56(sp)
ffffffffc02008c6:	7942                	ld	s2,48(sp)
ffffffffc02008c8:	79a2                	ld	s3,40(sp)
ffffffffc02008ca:	7a02                	ld	s4,32(sp)
ffffffffc02008cc:	6ae2                	ld	s5,24(sp)
ffffffffc02008ce:	6b42                	ld	s6,16(sp)
ffffffffc02008d0:	6ba2                	ld	s7,8(sp)
ffffffffc02008d2:	6c02                	ld	s8,0(sp)
    cprintf("grading: %d / %d points\n", score, sumscore);
ffffffffc02008d4:	4619                	li	a2,6
ffffffffc02008d6:	4599                	li	a1,6
ffffffffc02008d8:	00002517          	auipc	a0,0x2
ffffffffc02008dc:	20850513          	addi	a0,a0,520 # ffffffffc0202ae0 <etext+0x458>
}
ffffffffc02008e0:	6161                	addi	sp,sp,80
    cprintf("grading: %d / %d points\n", score, sumscore);
ffffffffc02008e2:	873ff06f          	j	ffffffffc0200154 <cprintf>
    while ((le = list_next(le)) != &free_list) {
ffffffffc02008e6:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc02008e8:	4481                	li	s1,0
ffffffffc02008ea:	4901                	li	s2,0
ffffffffc02008ec:	b3a9                	j	ffffffffc0200636 <best_fit_check+0x42>
        assert(PageProperty(p));
ffffffffc02008ee:	00002697          	auipc	a3,0x2
ffffffffc02008f2:	ffa68693          	addi	a3,a3,-6 # ffffffffc02028e8 <etext+0x260>
ffffffffc02008f6:	00002617          	auipc	a2,0x2
ffffffffc02008fa:	00260613          	addi	a2,a2,2 # ffffffffc02028f8 <etext+0x270>
ffffffffc02008fe:	0b700593          	li	a1,183
ffffffffc0200902:	00002517          	auipc	a0,0x2
ffffffffc0200906:	00e50513          	addi	a0,a0,14 # ffffffffc0202910 <etext+0x288>
ffffffffc020090a:	8c1ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc020090e:	00002697          	auipc	a3,0x2
ffffffffc0200912:	09a68693          	addi	a3,a3,154 # ffffffffc02029a8 <etext+0x320>
ffffffffc0200916:	00002617          	auipc	a2,0x2
ffffffffc020091a:	fe260613          	addi	a2,a2,-30 # ffffffffc02028f8 <etext+0x270>
ffffffffc020091e:	08500593          	li	a1,133
ffffffffc0200922:	00002517          	auipc	a0,0x2
ffffffffc0200926:	fee50513          	addi	a0,a0,-18 # ffffffffc0202910 <etext+0x288>
ffffffffc020092a:	8a1ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc020092e:	00002697          	auipc	a3,0x2
ffffffffc0200932:	0a268693          	addi	a3,a3,162 # ffffffffc02029d0 <etext+0x348>
ffffffffc0200936:	00002617          	auipc	a2,0x2
ffffffffc020093a:	fc260613          	addi	a2,a2,-62 # ffffffffc02028f8 <etext+0x270>
ffffffffc020093e:	08600593          	li	a1,134
ffffffffc0200942:	00002517          	auipc	a0,0x2
ffffffffc0200946:	fce50513          	addi	a0,a0,-50 # ffffffffc0202910 <etext+0x288>
ffffffffc020094a:	881ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc020094e:	00002697          	auipc	a3,0x2
ffffffffc0200952:	0c268693          	addi	a3,a3,194 # ffffffffc0202a10 <etext+0x388>
ffffffffc0200956:	00002617          	auipc	a2,0x2
ffffffffc020095a:	fa260613          	addi	a2,a2,-94 # ffffffffc02028f8 <etext+0x270>
ffffffffc020095e:	08800593          	li	a1,136
ffffffffc0200962:	00002517          	auipc	a0,0x2
ffffffffc0200966:	fae50513          	addi	a0,a0,-82 # ffffffffc0202910 <etext+0x288>
ffffffffc020096a:	861ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(!list_empty(&free_list));
ffffffffc020096e:	00002697          	auipc	a3,0x2
ffffffffc0200972:	12a68693          	addi	a3,a3,298 # ffffffffc0202a98 <etext+0x410>
ffffffffc0200976:	00002617          	auipc	a2,0x2
ffffffffc020097a:	f8260613          	addi	a2,a2,-126 # ffffffffc02028f8 <etext+0x270>
ffffffffc020097e:	0a100593          	li	a1,161
ffffffffc0200982:	00002517          	auipc	a0,0x2
ffffffffc0200986:	f8e50513          	addi	a0,a0,-114 # ffffffffc0202910 <etext+0x288>
ffffffffc020098a:	841ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020098e:	00002697          	auipc	a3,0x2
ffffffffc0200992:	ffa68693          	addi	a3,a3,-6 # ffffffffc0202988 <etext+0x300>
ffffffffc0200996:	00002617          	auipc	a2,0x2
ffffffffc020099a:	f6260613          	addi	a2,a2,-158 # ffffffffc02028f8 <etext+0x270>
ffffffffc020099e:	08300593          	li	a1,131
ffffffffc02009a2:	00002517          	auipc	a0,0x2
ffffffffc02009a6:	f6e50513          	addi	a0,a0,-146 # ffffffffc0202910 <etext+0x288>
ffffffffc02009aa:	821ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(total == 0);
ffffffffc02009ae:	00002697          	auipc	a3,0x2
ffffffffc02009b2:	23a68693          	addi	a3,a3,570 # ffffffffc0202be8 <etext+0x560>
ffffffffc02009b6:	00002617          	auipc	a2,0x2
ffffffffc02009ba:	f4260613          	addi	a2,a2,-190 # ffffffffc02028f8 <etext+0x270>
ffffffffc02009be:	0f900593          	li	a1,249
ffffffffc02009c2:	00002517          	auipc	a0,0x2
ffffffffc02009c6:	f4e50513          	addi	a0,a0,-178 # ffffffffc0202910 <etext+0x288>
ffffffffc02009ca:	801ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(total == nr_free_pages());
ffffffffc02009ce:	00002697          	auipc	a3,0x2
ffffffffc02009d2:	f5a68693          	addi	a3,a3,-166 # ffffffffc0202928 <etext+0x2a0>
ffffffffc02009d6:	00002617          	auipc	a2,0x2
ffffffffc02009da:	f2260613          	addi	a2,a2,-222 # ffffffffc02028f8 <etext+0x270>
ffffffffc02009de:	0ba00593          	li	a1,186
ffffffffc02009e2:	00002517          	auipc	a0,0x2
ffffffffc02009e6:	f2e50513          	addi	a0,a0,-210 # ffffffffc0202910 <etext+0x288>
ffffffffc02009ea:	fe0ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02009ee:	00002697          	auipc	a3,0x2
ffffffffc02009f2:	f7a68693          	addi	a3,a3,-134 # ffffffffc0202968 <etext+0x2e0>
ffffffffc02009f6:	00002617          	auipc	a2,0x2
ffffffffc02009fa:	f0260613          	addi	a2,a2,-254 # ffffffffc02028f8 <etext+0x270>
ffffffffc02009fe:	08200593          	li	a1,130
ffffffffc0200a02:	00002517          	auipc	a0,0x2
ffffffffc0200a06:	f0e50513          	addi	a0,a0,-242 # ffffffffc0202910 <etext+0x288>
ffffffffc0200a0a:	fc0ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200a0e:	00002697          	auipc	a3,0x2
ffffffffc0200a12:	f3a68693          	addi	a3,a3,-198 # ffffffffc0202948 <etext+0x2c0>
ffffffffc0200a16:	00002617          	auipc	a2,0x2
ffffffffc0200a1a:	ee260613          	addi	a2,a2,-286 # ffffffffc02028f8 <etext+0x270>
ffffffffc0200a1e:	08100593          	li	a1,129
ffffffffc0200a22:	00002517          	auipc	a0,0x2
ffffffffc0200a26:	eee50513          	addi	a0,a0,-274 # ffffffffc0202910 <etext+0x288>
ffffffffc0200a2a:	fa0ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200a2e:	00002697          	auipc	a3,0x2
ffffffffc0200a32:	04268693          	addi	a3,a3,66 # ffffffffc0202a70 <etext+0x3e8>
ffffffffc0200a36:	00002617          	auipc	a2,0x2
ffffffffc0200a3a:	ec260613          	addi	a2,a2,-318 # ffffffffc02028f8 <etext+0x270>
ffffffffc0200a3e:	09e00593          	li	a1,158
ffffffffc0200a42:	00002517          	auipc	a0,0x2
ffffffffc0200a46:	ece50513          	addi	a0,a0,-306 # ffffffffc0202910 <etext+0x288>
ffffffffc0200a4a:	f80ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200a4e:	00002697          	auipc	a3,0x2
ffffffffc0200a52:	f3a68693          	addi	a3,a3,-198 # ffffffffc0202988 <etext+0x300>
ffffffffc0200a56:	00002617          	auipc	a2,0x2
ffffffffc0200a5a:	ea260613          	addi	a2,a2,-350 # ffffffffc02028f8 <etext+0x270>
ffffffffc0200a5e:	09c00593          	li	a1,156
ffffffffc0200a62:	00002517          	auipc	a0,0x2
ffffffffc0200a66:	eae50513          	addi	a0,a0,-338 # ffffffffc0202910 <etext+0x288>
ffffffffc0200a6a:	f60ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200a6e:	00002697          	auipc	a3,0x2
ffffffffc0200a72:	efa68693          	addi	a3,a3,-262 # ffffffffc0202968 <etext+0x2e0>
ffffffffc0200a76:	00002617          	auipc	a2,0x2
ffffffffc0200a7a:	e8260613          	addi	a2,a2,-382 # ffffffffc02028f8 <etext+0x270>
ffffffffc0200a7e:	09b00593          	li	a1,155
ffffffffc0200a82:	00002517          	auipc	a0,0x2
ffffffffc0200a86:	e8e50513          	addi	a0,a0,-370 # ffffffffc0202910 <etext+0x288>
ffffffffc0200a8a:	f40ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200a8e:	00002697          	auipc	a3,0x2
ffffffffc0200a92:	eba68693          	addi	a3,a3,-326 # ffffffffc0202948 <etext+0x2c0>
ffffffffc0200a96:	00002617          	auipc	a2,0x2
ffffffffc0200a9a:	e6260613          	addi	a2,a2,-414 # ffffffffc02028f8 <etext+0x270>
ffffffffc0200a9e:	09a00593          	li	a1,154
ffffffffc0200aa2:	00002517          	auipc	a0,0x2
ffffffffc0200aa6:	e6e50513          	addi	a0,a0,-402 # ffffffffc0202910 <etext+0x288>
ffffffffc0200aaa:	f20ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(nr_free == 3);
ffffffffc0200aae:	00002697          	auipc	a3,0x2
ffffffffc0200ab2:	fda68693          	addi	a3,a3,-38 # ffffffffc0202a88 <etext+0x400>
ffffffffc0200ab6:	00002617          	auipc	a2,0x2
ffffffffc0200aba:	e4260613          	addi	a2,a2,-446 # ffffffffc02028f8 <etext+0x270>
ffffffffc0200abe:	09800593          	li	a1,152
ffffffffc0200ac2:	00002517          	auipc	a0,0x2
ffffffffc0200ac6:	e4e50513          	addi	a0,a0,-434 # ffffffffc0202910 <etext+0x288>
ffffffffc0200aca:	f00ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200ace:	00002697          	auipc	a3,0x2
ffffffffc0200ad2:	fa268693          	addi	a3,a3,-94 # ffffffffc0202a70 <etext+0x3e8>
ffffffffc0200ad6:	00002617          	auipc	a2,0x2
ffffffffc0200ada:	e2260613          	addi	a2,a2,-478 # ffffffffc02028f8 <etext+0x270>
ffffffffc0200ade:	09300593          	li	a1,147
ffffffffc0200ae2:	00002517          	auipc	a0,0x2
ffffffffc0200ae6:	e2e50513          	addi	a0,a0,-466 # ffffffffc0202910 <etext+0x288>
ffffffffc0200aea:	ee0ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200aee:	00002697          	auipc	a3,0x2
ffffffffc0200af2:	f6268693          	addi	a3,a3,-158 # ffffffffc0202a50 <etext+0x3c8>
ffffffffc0200af6:	00002617          	auipc	a2,0x2
ffffffffc0200afa:	e0260613          	addi	a2,a2,-510 # ffffffffc02028f8 <etext+0x270>
ffffffffc0200afe:	08a00593          	li	a1,138
ffffffffc0200b02:	00002517          	auipc	a0,0x2
ffffffffc0200b06:	e0e50513          	addi	a0,a0,-498 # ffffffffc0202910 <etext+0x288>
ffffffffc0200b0a:	ec0ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200b0e:	00002697          	auipc	a3,0x2
ffffffffc0200b12:	f2268693          	addi	a3,a3,-222 # ffffffffc0202a30 <etext+0x3a8>
ffffffffc0200b16:	00002617          	auipc	a2,0x2
ffffffffc0200b1a:	de260613          	addi	a2,a2,-542 # ffffffffc02028f8 <etext+0x270>
ffffffffc0200b1e:	08900593          	li	a1,137
ffffffffc0200b22:	00002517          	auipc	a0,0x2
ffffffffc0200b26:	dee50513          	addi	a0,a0,-530 # ffffffffc0202910 <etext+0x288>
ffffffffc0200b2a:	ea0ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(count == 0);
ffffffffc0200b2e:	00002697          	auipc	a3,0x2
ffffffffc0200b32:	0aa68693          	addi	a3,a3,170 # ffffffffc0202bd8 <etext+0x550>
ffffffffc0200b36:	00002617          	auipc	a2,0x2
ffffffffc0200b3a:	dc260613          	addi	a2,a2,-574 # ffffffffc02028f8 <etext+0x270>
ffffffffc0200b3e:	0f800593          	li	a1,248
ffffffffc0200b42:	00002517          	auipc	a0,0x2
ffffffffc0200b46:	dce50513          	addi	a0,a0,-562 # ffffffffc0202910 <etext+0x288>
ffffffffc0200b4a:	e80ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(nr_free == 0);
ffffffffc0200b4e:	00002697          	auipc	a3,0x2
ffffffffc0200b52:	f8268693          	addi	a3,a3,-126 # ffffffffc0202ad0 <etext+0x448>
ffffffffc0200b56:	00002617          	auipc	a2,0x2
ffffffffc0200b5a:	da260613          	addi	a2,a2,-606 # ffffffffc02028f8 <etext+0x270>
ffffffffc0200b5e:	0ed00593          	li	a1,237
ffffffffc0200b62:	00002517          	auipc	a0,0x2
ffffffffc0200b66:	dae50513          	addi	a0,a0,-594 # ffffffffc0202910 <etext+0x288>
ffffffffc0200b6a:	e60ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200b6e:	00002697          	auipc	a3,0x2
ffffffffc0200b72:	f0268693          	addi	a3,a3,-254 # ffffffffc0202a70 <etext+0x3e8>
ffffffffc0200b76:	00002617          	auipc	a2,0x2
ffffffffc0200b7a:	d8260613          	addi	a2,a2,-638 # ffffffffc02028f8 <etext+0x270>
ffffffffc0200b7e:	0e700593          	li	a1,231
ffffffffc0200b82:	00002517          	auipc	a0,0x2
ffffffffc0200b86:	d8e50513          	addi	a0,a0,-626 # ffffffffc0202910 <etext+0x288>
ffffffffc0200b8a:	e40ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200b8e:	00002697          	auipc	a3,0x2
ffffffffc0200b92:	02a68693          	addi	a3,a3,42 # ffffffffc0202bb8 <etext+0x530>
ffffffffc0200b96:	00002617          	auipc	a2,0x2
ffffffffc0200b9a:	d6260613          	addi	a2,a2,-670 # ffffffffc02028f8 <etext+0x270>
ffffffffc0200b9e:	0e600593          	li	a1,230
ffffffffc0200ba2:	00002517          	auipc	a0,0x2
ffffffffc0200ba6:	d6e50513          	addi	a0,a0,-658 # ffffffffc0202910 <etext+0x288>
ffffffffc0200baa:	e20ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(p0 + 4 == p1);
ffffffffc0200bae:	00002697          	auipc	a3,0x2
ffffffffc0200bb2:	ffa68693          	addi	a3,a3,-6 # ffffffffc0202ba8 <etext+0x520>
ffffffffc0200bb6:	00002617          	auipc	a2,0x2
ffffffffc0200bba:	d4260613          	addi	a2,a2,-702 # ffffffffc02028f8 <etext+0x270>
ffffffffc0200bbe:	0de00593          	li	a1,222
ffffffffc0200bc2:	00002517          	auipc	a0,0x2
ffffffffc0200bc6:	d4e50513          	addi	a0,a0,-690 # ffffffffc0202910 <etext+0x288>
ffffffffc0200bca:	e00ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(alloc_pages(2) != NULL);
ffffffffc0200bce:	00002697          	auipc	a3,0x2
ffffffffc0200bd2:	fc268693          	addi	a3,a3,-62 # ffffffffc0202b90 <etext+0x508>
ffffffffc0200bd6:	00002617          	auipc	a2,0x2
ffffffffc0200bda:	d2260613          	addi	a2,a2,-734 # ffffffffc02028f8 <etext+0x270>
ffffffffc0200bde:	0dd00593          	li	a1,221
ffffffffc0200be2:	00002517          	auipc	a0,0x2
ffffffffc0200be6:	d2e50513          	addi	a0,a0,-722 # ffffffffc0202910 <etext+0x288>
ffffffffc0200bea:	de0ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0200bee:	00002697          	auipc	a3,0x2
ffffffffc0200bf2:	f8268693          	addi	a3,a3,-126 # ffffffffc0202b70 <etext+0x4e8>
ffffffffc0200bf6:	00002617          	auipc	a2,0x2
ffffffffc0200bfa:	d0260613          	addi	a2,a2,-766 # ffffffffc02028f8 <etext+0x270>
ffffffffc0200bfe:	0dc00593          	li	a1,220
ffffffffc0200c02:	00002517          	auipc	a0,0x2
ffffffffc0200c06:	d0e50513          	addi	a0,a0,-754 # ffffffffc0202910 <etext+0x288>
ffffffffc0200c0a:	dc0ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0200c0e:	00002697          	auipc	a3,0x2
ffffffffc0200c12:	f3268693          	addi	a3,a3,-206 # ffffffffc0202b40 <etext+0x4b8>
ffffffffc0200c16:	00002617          	auipc	a2,0x2
ffffffffc0200c1a:	ce260613          	addi	a2,a2,-798 # ffffffffc02028f8 <etext+0x270>
ffffffffc0200c1e:	0da00593          	li	a1,218
ffffffffc0200c22:	00002517          	auipc	a0,0x2
ffffffffc0200c26:	cee50513          	addi	a0,a0,-786 # ffffffffc0202910 <etext+0x288>
ffffffffc0200c2a:	da0ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0200c2e:	00002697          	auipc	a3,0x2
ffffffffc0200c32:	efa68693          	addi	a3,a3,-262 # ffffffffc0202b28 <etext+0x4a0>
ffffffffc0200c36:	00002617          	auipc	a2,0x2
ffffffffc0200c3a:	cc260613          	addi	a2,a2,-830 # ffffffffc02028f8 <etext+0x270>
ffffffffc0200c3e:	0d900593          	li	a1,217
ffffffffc0200c42:	00002517          	auipc	a0,0x2
ffffffffc0200c46:	cce50513          	addi	a0,a0,-818 # ffffffffc0202910 <etext+0x288>
ffffffffc0200c4a:	d80ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200c4e:	00002697          	auipc	a3,0x2
ffffffffc0200c52:	e2268693          	addi	a3,a3,-478 # ffffffffc0202a70 <etext+0x3e8>
ffffffffc0200c56:	00002617          	auipc	a2,0x2
ffffffffc0200c5a:	ca260613          	addi	a2,a2,-862 # ffffffffc02028f8 <etext+0x270>
ffffffffc0200c5e:	0cd00593          	li	a1,205
ffffffffc0200c62:	00002517          	auipc	a0,0x2
ffffffffc0200c66:	cae50513          	addi	a0,a0,-850 # ffffffffc0202910 <etext+0x288>
ffffffffc0200c6a:	d60ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(!PageProperty(p0));
ffffffffc0200c6e:	00002697          	auipc	a3,0x2
ffffffffc0200c72:	ea268693          	addi	a3,a3,-350 # ffffffffc0202b10 <etext+0x488>
ffffffffc0200c76:	00002617          	auipc	a2,0x2
ffffffffc0200c7a:	c8260613          	addi	a2,a2,-894 # ffffffffc02028f8 <etext+0x270>
ffffffffc0200c7e:	0c400593          	li	a1,196
ffffffffc0200c82:	00002517          	auipc	a0,0x2
ffffffffc0200c86:	c8e50513          	addi	a0,a0,-882 # ffffffffc0202910 <etext+0x288>
ffffffffc0200c8a:	d40ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(p0 != NULL);
ffffffffc0200c8e:	00002697          	auipc	a3,0x2
ffffffffc0200c92:	e7268693          	addi	a3,a3,-398 # ffffffffc0202b00 <etext+0x478>
ffffffffc0200c96:	00002617          	auipc	a2,0x2
ffffffffc0200c9a:	c6260613          	addi	a2,a2,-926 # ffffffffc02028f8 <etext+0x270>
ffffffffc0200c9e:	0c300593          	li	a1,195
ffffffffc0200ca2:	00002517          	auipc	a0,0x2
ffffffffc0200ca6:	c6e50513          	addi	a0,a0,-914 # ffffffffc0202910 <etext+0x288>
ffffffffc0200caa:	d20ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(nr_free == 0);
ffffffffc0200cae:	00002697          	auipc	a3,0x2
ffffffffc0200cb2:	e2268693          	addi	a3,a3,-478 # ffffffffc0202ad0 <etext+0x448>
ffffffffc0200cb6:	00002617          	auipc	a2,0x2
ffffffffc0200cba:	c4260613          	addi	a2,a2,-958 # ffffffffc02028f8 <etext+0x270>
ffffffffc0200cbe:	0a700593          	li	a1,167
ffffffffc0200cc2:	00002517          	auipc	a0,0x2
ffffffffc0200cc6:	c4e50513          	addi	a0,a0,-946 # ffffffffc0202910 <etext+0x288>
ffffffffc0200cca:	d00ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200cce:	00002697          	auipc	a3,0x2
ffffffffc0200cd2:	da268693          	addi	a3,a3,-606 # ffffffffc0202a70 <etext+0x3e8>
ffffffffc0200cd6:	00002617          	auipc	a2,0x2
ffffffffc0200cda:	c2260613          	addi	a2,a2,-990 # ffffffffc02028f8 <etext+0x270>
ffffffffc0200cde:	0a500593          	li	a1,165
ffffffffc0200ce2:	00002517          	auipc	a0,0x2
ffffffffc0200ce6:	c2e50513          	addi	a0,a0,-978 # ffffffffc0202910 <etext+0x288>
ffffffffc0200cea:	ce0ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0200cee:	00002697          	auipc	a3,0x2
ffffffffc0200cf2:	dc268693          	addi	a3,a3,-574 # ffffffffc0202ab0 <etext+0x428>
ffffffffc0200cf6:	00002617          	auipc	a2,0x2
ffffffffc0200cfa:	c0260613          	addi	a2,a2,-1022 # ffffffffc02028f8 <etext+0x270>
ffffffffc0200cfe:	0a400593          	li	a1,164
ffffffffc0200d02:	00002517          	auipc	a0,0x2
ffffffffc0200d06:	c0e50513          	addi	a0,a0,-1010 # ffffffffc0202910 <etext+0x288>
ffffffffc0200d0a:	cc0ff0ef          	jal	ra,ffffffffc02001ca <__panic>

ffffffffc0200d0e <best_fit_alloc_pages>:
    assert(n > 0);
ffffffffc0200d0e:	cd55                	beqz	a0,ffffffffc0200dca <best_fit_alloc_pages+0xbc>
    if (n > nr_free) {
ffffffffc0200d10:	00006597          	auipc	a1,0x6
ffffffffc0200d14:	31058593          	addi	a1,a1,784 # ffffffffc0207020 <free_area>
ffffffffc0200d18:	0105a803          	lw	a6,16(a1)
ffffffffc0200d1c:	862a                	mv	a2,a0
ffffffffc0200d1e:	02081793          	slli	a5,a6,0x20
ffffffffc0200d22:	9381                	srli	a5,a5,0x20
ffffffffc0200d24:	00a7ee63          	bltu	a5,a0,ffffffffc0200d40 <best_fit_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc0200d28:	87ae                	mv	a5,a1
ffffffffc0200d2a:	a801                	j	ffffffffc0200d3a <best_fit_alloc_pages+0x2c>
        if (p->property >= n) {
ffffffffc0200d2c:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200d30:	02071693          	slli	a3,a4,0x20
ffffffffc0200d34:	9281                	srli	a3,a3,0x20
ffffffffc0200d36:	00c6f763          	bgeu	a3,a2,ffffffffc0200d44 <best_fit_alloc_pages+0x36>
ffffffffc0200d3a:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200d3c:	feb798e3          	bne	a5,a1,ffffffffc0200d2c <best_fit_alloc_pages+0x1e>
        return NULL;
ffffffffc0200d40:	4501                	li	a0,0
}
ffffffffc0200d42:	8082                	ret
    __list_del(listelm->prev, listelm->next);
ffffffffc0200d44:	0007b303          	ld	t1,0(a5)
ffffffffc0200d48:	0087b883          	ld	a7,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc0200d4c:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc0200d50:	00060e1b          	sext.w	t3,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0200d54:	01133423          	sd	a7,8(t1)
    next->prev = prev;
ffffffffc0200d58:	0068b023          	sd	t1,0(a7)
        if (page->property > n) {
ffffffffc0200d5c:	00d66c63          	bltu	a2,a3,ffffffffc0200d74 <best_fit_alloc_pages+0x66>
        ClearPageProperty(page);
ffffffffc0200d60:	ff07b703          	ld	a4,-16(a5)
        nr_free -= n;
ffffffffc0200d64:	41c8083b          	subw	a6,a6,t3
ffffffffc0200d68:	0105a823          	sw	a6,16(a1)
        ClearPageProperty(page);
ffffffffc0200d6c:	9b75                	andi	a4,a4,-3
ffffffffc0200d6e:	fee7b823          	sd	a4,-16(a5)
ffffffffc0200d72:	8082                	ret
            struct Page *p = page + n;
ffffffffc0200d74:	00261693          	slli	a3,a2,0x2
ffffffffc0200d78:	9636                	add	a2,a2,a3
ffffffffc0200d7a:	060e                	slli	a2,a2,0x3
ffffffffc0200d7c:	962a                	add	a2,a2,a0
            SetPageProperty(p);
ffffffffc0200d7e:	6614                	ld	a3,8(a2)
            p->property = page->property - n;
ffffffffc0200d80:	41c708bb          	subw	a7,a4,t3
ffffffffc0200d84:	01162823          	sw	a7,16(a2)
            SetPageProperty(p);
ffffffffc0200d88:	0026e693          	ori	a3,a3,2
ffffffffc0200d8c:	e614                	sd	a3,8(a2)
    list_entry_t *le = &free_list;
ffffffffc0200d8e:	00006717          	auipc	a4,0x6
ffffffffc0200d92:	29270713          	addi	a4,a4,658 # ffffffffc0207020 <free_area>
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200d96:	a029                	j	ffffffffc0200da0 <best_fit_alloc_pages+0x92>
        if (base->property < page->property) {
ffffffffc0200d98:	ff872683          	lw	a3,-8(a4)
ffffffffc0200d9c:	00d8ed63          	bltu	a7,a3,ffffffffc0200db6 <best_fit_alloc_pages+0xa8>
    return listelm->next;
ffffffffc0200da0:	6718                	ld	a4,8(a4)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200da2:	feb71be3          	bne	a4,a1,ffffffffc0200d98 <best_fit_alloc_pages+0x8a>
    __list_add(elm, listelm, listelm->next);
ffffffffc0200da6:	6598                	ld	a4,8(a1)
    list_add(&free_list, &(base->page_link));
ffffffffc0200da8:	01860693          	addi	a3,a2,24
    prev->next = next->prev = elm;
ffffffffc0200dac:	e314                	sd	a3,0(a4)
ffffffffc0200dae:	e594                	sd	a3,8(a1)
    elm->next = next;
ffffffffc0200db0:	f218                	sd	a4,32(a2)
    elm->prev = prev;
ffffffffc0200db2:	ee0c                	sd	a1,24(a2)
ffffffffc0200db4:	b775                	j	ffffffffc0200d60 <best_fit_alloc_pages+0x52>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0200db6:	6314                	ld	a3,0(a4)
            list_add_before(le, &(base->page_link));
ffffffffc0200db8:	01860893          	addi	a7,a2,24
    prev->next = next->prev = elm;
ffffffffc0200dbc:	01173023          	sd	a7,0(a4)
ffffffffc0200dc0:	0116b423          	sd	a7,8(a3)
    elm->next = next;
ffffffffc0200dc4:	f218                	sd	a4,32(a2)
    elm->prev = prev;
ffffffffc0200dc6:	ee14                	sd	a3,24(a2)
            return;
ffffffffc0200dc8:	bf61                	j	ffffffffc0200d60 <best_fit_alloc_pages+0x52>
best_fit_alloc_pages(size_t n) {
ffffffffc0200dca:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0200dcc:	00002697          	auipc	a3,0x2
ffffffffc0200dd0:	e2c68693          	addi	a3,a3,-468 # ffffffffc0202bf8 <etext+0x570>
ffffffffc0200dd4:	00002617          	auipc	a2,0x2
ffffffffc0200dd8:	b2460613          	addi	a2,a2,-1244 # ffffffffc02028f8 <etext+0x270>
ffffffffc0200ddc:	03100593          	li	a1,49
ffffffffc0200de0:	00002517          	auipc	a0,0x2
ffffffffc0200de4:	b3050513          	addi	a0,a0,-1232 # ffffffffc0202910 <etext+0x288>
best_fit_alloc_pages(size_t n) {
ffffffffc0200de8:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200dea:	be0ff0ef          	jal	ra,ffffffffc02001ca <__panic>

ffffffffc0200dee <best_fit_init_memmap>:
best_fit_init_memmap(struct Page *base, size_t n) {
ffffffffc0200dee:	1141                	addi	sp,sp,-16
ffffffffc0200df0:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200df2:	c1cd                	beqz	a1,ffffffffc0200e94 <best_fit_init_memmap+0xa6>
    for (; p != base + n; p++) {
ffffffffc0200df4:	00259693          	slli	a3,a1,0x2
ffffffffc0200df8:	96ae                	add	a3,a3,a1
ffffffffc0200dfa:	068e                	slli	a3,a3,0x3
ffffffffc0200dfc:	96aa                	add	a3,a3,a0
ffffffffc0200dfe:	87aa                	mv	a5,a0
ffffffffc0200e00:	00d50f63          	beq	a0,a3,ffffffffc0200e1e <best_fit_init_memmap+0x30>
        assert(PageReserved(p));
ffffffffc0200e04:	6798                	ld	a4,8(a5)
ffffffffc0200e06:	8b05                	andi	a4,a4,1
ffffffffc0200e08:	c735                	beqz	a4,ffffffffc0200e74 <best_fit_init_memmap+0x86>
        p->flags = p->property = 0;
ffffffffc0200e0a:	0007a823          	sw	zero,16(a5)
ffffffffc0200e0e:	0007b423          	sd	zero,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200e12:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++) {
ffffffffc0200e16:	02878793          	addi	a5,a5,40
ffffffffc0200e1a:	fed795e3          	bne	a5,a3,ffffffffc0200e04 <best_fit_init_memmap+0x16>
    SetPageProperty(base);
ffffffffc0200e1e:	6514                	ld	a3,8(a0)
    nr_free += n;
ffffffffc0200e20:	00006617          	auipc	a2,0x6
ffffffffc0200e24:	20060613          	addi	a2,a2,512 # ffffffffc0207020 <free_area>
ffffffffc0200e28:	4a1c                	lw	a5,16(a2)
    base->property = n;
ffffffffc0200e2a:	0005871b          	sext.w	a4,a1
    SetPageProperty(base);
ffffffffc0200e2e:	0026e693          	ori	a3,a3,2
    nr_free += n;
ffffffffc0200e32:	9fb9                	addw	a5,a5,a4
    base->property = n;
ffffffffc0200e34:	c918                	sw	a4,16(a0)
    SetPageProperty(base);
ffffffffc0200e36:	e514                	sd	a3,8(a0)
    nr_free += n;
ffffffffc0200e38:	ca1c                	sw	a5,16(a2)
    list_entry_t *le = &free_list;
ffffffffc0200e3a:	87b2                	mv	a5,a2
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200e3c:	a029                	j	ffffffffc0200e46 <best_fit_init_memmap+0x58>
        if (base->property < page->property) {
ffffffffc0200e3e:	ff87a683          	lw	a3,-8(a5)
ffffffffc0200e42:	00d76f63          	bltu	a4,a3,ffffffffc0200e60 <best_fit_init_memmap+0x72>
    return listelm->next;
ffffffffc0200e46:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200e48:	fec79be3          	bne	a5,a2,ffffffffc0200e3e <best_fit_init_memmap+0x50>
    __list_add(elm, listelm, listelm->next);
ffffffffc0200e4c:	6798                	ld	a4,8(a5)
}
ffffffffc0200e4e:	60a2                	ld	ra,8(sp)
    list_add(&free_list, &(base->page_link));
ffffffffc0200e50:	01850693          	addi	a3,a0,24
    prev->next = next->prev = elm;
ffffffffc0200e54:	e314                	sd	a3,0(a4)
ffffffffc0200e56:	e794                	sd	a3,8(a5)
    elm->next = next;
ffffffffc0200e58:	f118                	sd	a4,32(a0)
    elm->prev = prev;
ffffffffc0200e5a:	ed1c                	sd	a5,24(a0)
}
ffffffffc0200e5c:	0141                	addi	sp,sp,16
ffffffffc0200e5e:	8082                	ret
    __list_add(elm, listelm->prev, listelm);
ffffffffc0200e60:	6398                	ld	a4,0(a5)
            list_add_before(le, &(base->page_link));
ffffffffc0200e62:	01850693          	addi	a3,a0,24
    prev->next = next->prev = elm;
ffffffffc0200e66:	e394                	sd	a3,0(a5)
}
ffffffffc0200e68:	60a2                	ld	ra,8(sp)
ffffffffc0200e6a:	e714                	sd	a3,8(a4)
    elm->next = next;
ffffffffc0200e6c:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200e6e:	ed18                	sd	a4,24(a0)
ffffffffc0200e70:	0141                	addi	sp,sp,16
ffffffffc0200e72:	8082                	ret
        assert(PageReserved(p));
ffffffffc0200e74:	00002697          	auipc	a3,0x2
ffffffffc0200e78:	d8c68693          	addi	a3,a3,-628 # ffffffffc0202c00 <etext+0x578>
ffffffffc0200e7c:	00002617          	auipc	a2,0x2
ffffffffc0200e80:	a7c60613          	addi	a2,a2,-1412 # ffffffffc02028f8 <etext+0x270>
ffffffffc0200e84:	02500593          	li	a1,37
ffffffffc0200e88:	00002517          	auipc	a0,0x2
ffffffffc0200e8c:	a8850513          	addi	a0,a0,-1400 # ffffffffc0202910 <etext+0x288>
ffffffffc0200e90:	b3aff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(n > 0);
ffffffffc0200e94:	00002697          	auipc	a3,0x2
ffffffffc0200e98:	d6468693          	addi	a3,a3,-668 # ffffffffc0202bf8 <etext+0x570>
ffffffffc0200e9c:	00002617          	auipc	a2,0x2
ffffffffc0200ea0:	a5c60613          	addi	a2,a2,-1444 # ffffffffc02028f8 <etext+0x270>
ffffffffc0200ea4:	02200593          	li	a1,34
ffffffffc0200ea8:	00002517          	auipc	a0,0x2
ffffffffc0200eac:	a6850513          	addi	a0,a0,-1432 # ffffffffc0202910 <etext+0x288>
ffffffffc0200eb0:	b1aff0ef          	jal	ra,ffffffffc02001ca <__panic>

ffffffffc0200eb4 <best_fit_free_pages>:
best_fit_free_pages(struct Page *base, size_t n) {
ffffffffc0200eb4:	1141                	addi	sp,sp,-16
ffffffffc0200eb6:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200eb8:	16058b63          	beqz	a1,ffffffffc020102e <best_fit_free_pages+0x17a>
    for (; p != base + n; p++) {
ffffffffc0200ebc:	00259693          	slli	a3,a1,0x2
ffffffffc0200ec0:	96ae                	add	a3,a3,a1
ffffffffc0200ec2:	068e                	slli	a3,a3,0x3
ffffffffc0200ec4:	96aa                	add	a3,a3,a0
ffffffffc0200ec6:	87aa                	mv	a5,a0
ffffffffc0200ec8:	00d50e63          	beq	a0,a3,ffffffffc0200ee4 <best_fit_free_pages+0x30>
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0200ecc:	6798                	ld	a4,8(a5)
ffffffffc0200ece:	8b0d                	andi	a4,a4,3
ffffffffc0200ed0:	12071f63          	bnez	a4,ffffffffc020100e <best_fit_free_pages+0x15a>
        p->flags = 0;
ffffffffc0200ed4:	0007b423          	sd	zero,8(a5)
ffffffffc0200ed8:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++) {
ffffffffc0200edc:	02878793          	addi	a5,a5,40
ffffffffc0200ee0:	fed796e3          	bne	a5,a3,ffffffffc0200ecc <best_fit_free_pages+0x18>
    nr_free += n;
ffffffffc0200ee4:	00006817          	auipc	a6,0x6
ffffffffc0200ee8:	13c80813          	addi	a6,a6,316 # ffffffffc0207020 <free_area>
    SetPageProperty(base);
ffffffffc0200eec:	00853883          	ld	a7,8(a0)
    nr_free += n;
ffffffffc0200ef0:	01082783          	lw	a5,16(a6)
    base->property = n;
ffffffffc0200ef4:	0005871b          	sext.w	a4,a1
    SetPageProperty(base);
ffffffffc0200ef8:	0028e693          	ori	a3,a7,2
ffffffffc0200efc:	e514                	sd	a3,8(a0)
    nr_free += n;
ffffffffc0200efe:	9fb9                	addw	a5,a5,a4
    base->property = n;
ffffffffc0200f00:	c918                	sw	a4,16(a0)
    nr_free += n;
ffffffffc0200f02:	00f82823          	sw	a5,16(a6)
    list_entry_t *le = &free_list;
ffffffffc0200f06:	86c2                	mv	a3,a6
ffffffffc0200f08:	87c2                	mv	a5,a6
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200f0a:	a029                	j	ffffffffc0200f14 <best_fit_free_pages+0x60>
        if (base->property < page->property) {
ffffffffc0200f0c:	ff87a603          	lw	a2,-8(a5)
ffffffffc0200f10:	04c76863          	bltu	a4,a2,ffffffffc0200f60 <best_fit_free_pages+0xac>
    return listelm->next;
ffffffffc0200f14:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200f16:	fed79be3          	bne	a5,a3,ffffffffc0200f0c <best_fit_free_pages+0x58>
    __list_add(elm, listelm, listelm->next);
ffffffffc0200f1a:	679c                	ld	a5,8(a5)
    list_add(&free_list, &(base->page_link));
ffffffffc0200f1c:	01850593          	addi	a1,a0,24
    prev->next = next->prev = elm;
ffffffffc0200f20:	e38c                	sd	a1,0(a5)
ffffffffc0200f22:	00b83423          	sd	a1,8(a6)
    elm->next = next;
ffffffffc0200f26:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200f28:	01053c23          	sd	a6,24(a0)
    if (le != &free_list) {
ffffffffc0200f2c:	08d79363          	bne	a5,a3,ffffffffc0200fb2 <best_fit_free_pages+0xfe>
    __list_del(listelm->prev, listelm->next);
ffffffffc0200f30:	6d10                	ld	a2,24(a0)
    list_entry_t *le = &free_list;
ffffffffc0200f32:	00006717          	auipc	a4,0x6
ffffffffc0200f36:	0ee70713          	addi	a4,a4,238 # ffffffffc0207020 <free_area>
    prev->next = next;
ffffffffc0200f3a:	e61c                	sd	a5,8(a2)
    next->prev = prev;
ffffffffc0200f3c:	e390                	sd	a2,0(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200f3e:	a031                	j	ffffffffc0200f4a <best_fit_free_pages+0x96>
        if (base->property < page->property) {
ffffffffc0200f40:	4910                	lw	a2,16(a0)
ffffffffc0200f42:	ff872783          	lw	a5,-8(a4)
ffffffffc0200f46:	0af66c63          	bltu	a2,a5,ffffffffc0200ffe <best_fit_free_pages+0x14a>
    return listelm->next;
ffffffffc0200f4a:	6718                	ld	a4,8(a4)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200f4c:	fed71ae3          	bne	a4,a3,ffffffffc0200f40 <best_fit_free_pages+0x8c>
    __list_add(elm, listelm, listelm->next);
ffffffffc0200f50:	671c                	ld	a5,8(a4)
}
ffffffffc0200f52:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0200f54:	e38c                	sd	a1,0(a5)
ffffffffc0200f56:	e70c                	sd	a1,8(a4)
    elm->next = next;
ffffffffc0200f58:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200f5a:	ed18                	sd	a4,24(a0)
ffffffffc0200f5c:	0141                	addi	sp,sp,16
ffffffffc0200f5e:	8082                	ret
    __list_add(elm, listelm->prev, listelm);
ffffffffc0200f60:	0007b803          	ld	a6,0(a5)
            list_add_before(le, &(base->page_link));
ffffffffc0200f64:	01850593          	addi	a1,a0,24
    prev->next = next->prev = elm;
ffffffffc0200f68:	e38c                	sd	a1,0(a5)
ffffffffc0200f6a:	00b83423          	sd	a1,8(a6)
    elm->next = next;
ffffffffc0200f6e:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200f70:	01053c23          	sd	a6,24(a0)
    if (le != &free_list) {
ffffffffc0200f74:	02d80f63          	beq	a6,a3,ffffffffc0200fb2 <best_fit_free_pages+0xfe>
        if (p + p->property == base) {
ffffffffc0200f78:	ff882e83          	lw	t4,-8(a6)
        p = le2page(le, page_link);
ffffffffc0200f7c:	fe880e13          	addi	t3,a6,-24
        if (p + p->property == base) {
ffffffffc0200f80:	020e9313          	slli	t1,t4,0x20
ffffffffc0200f84:	02035313          	srli	t1,t1,0x20
ffffffffc0200f88:	00231613          	slli	a2,t1,0x2
ffffffffc0200f8c:	961a                	add	a2,a2,t1
ffffffffc0200f8e:	060e                	slli	a2,a2,0x3
ffffffffc0200f90:	9672                	add	a2,a2,t3
ffffffffc0200f92:	02c51063          	bne	a0,a2,ffffffffc0200fb2 <best_fit_free_pages+0xfe>
            p->property += base->property;
ffffffffc0200f96:	01d7073b          	addw	a4,a4,t4
ffffffffc0200f9a:	fee82c23          	sw	a4,-8(a6)
            ClearPageProperty(base);
ffffffffc0200f9e:	ffd8f893          	andi	a7,a7,-3
ffffffffc0200fa2:	01153423          	sd	a7,8(a0)
    prev->next = next;
ffffffffc0200fa6:	00f83423          	sd	a5,8(a6)
    next->prev = prev;
ffffffffc0200faa:	0107b023          	sd	a6,0(a5)
            list_add_before(le, &(base->page_link));
ffffffffc0200fae:	85c2                	mv	a1,a6
            base = p;
ffffffffc0200fb0:	8572                	mv	a0,t3
        if (base + base->property == p) {
ffffffffc0200fb2:	01052883          	lw	a7,16(a0)
        p = le2page(le, page_link);
ffffffffc0200fb6:	fe878613          	addi	a2,a5,-24
        if (base + base->property == p) {
ffffffffc0200fba:	02089813          	slli	a6,a7,0x20
ffffffffc0200fbe:	02085813          	srli	a6,a6,0x20
ffffffffc0200fc2:	00281713          	slli	a4,a6,0x2
ffffffffc0200fc6:	9742                	add	a4,a4,a6
ffffffffc0200fc8:	070e                	slli	a4,a4,0x3
ffffffffc0200fca:	972a                	add	a4,a4,a0
ffffffffc0200fcc:	00e60463          	beq	a2,a4,ffffffffc0200fd4 <best_fit_free_pages+0x120>
    __list_del(listelm->prev, listelm->next);
ffffffffc0200fd0:	711c                	ld	a5,32(a0)
ffffffffc0200fd2:	bfb9                	j	ffffffffc0200f30 <best_fit_free_pages+0x7c>
            base->property += p->property;
ffffffffc0200fd4:	ff87a603          	lw	a2,-8(a5)
            ClearPageProperty(p);
ffffffffc0200fd8:	ff07b703          	ld	a4,-16(a5)
ffffffffc0200fdc:	0007b303          	ld	t1,0(a5)
ffffffffc0200fe0:	0087b803          	ld	a6,8(a5)
            base->property += p->property;
ffffffffc0200fe4:	011608bb          	addw	a7,a2,a7
ffffffffc0200fe8:	01152823          	sw	a7,16(a0)
            ClearPageProperty(p);
ffffffffc0200fec:	9b75                	andi	a4,a4,-3
ffffffffc0200fee:	fee7b823          	sd	a4,-16(a5)
    prev->next = next;
ffffffffc0200ff2:	01033423          	sd	a6,8(t1)
    __list_del(listelm->prev, listelm->next);
ffffffffc0200ff6:	711c                	ld	a5,32(a0)
    next->prev = prev;
ffffffffc0200ff8:	00683023          	sd	t1,0(a6)
}
ffffffffc0200ffc:	bf15                	j	ffffffffc0200f30 <best_fit_free_pages+0x7c>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0200ffe:	631c                	ld	a5,0(a4)
}
ffffffffc0201000:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201002:	e30c                	sd	a1,0(a4)
ffffffffc0201004:	e78c                	sd	a1,8(a5)
    elm->next = next;
ffffffffc0201006:	f118                	sd	a4,32(a0)
    elm->prev = prev;
ffffffffc0201008:	ed1c                	sd	a5,24(a0)
ffffffffc020100a:	0141                	addi	sp,sp,16
ffffffffc020100c:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020100e:	00002697          	auipc	a3,0x2
ffffffffc0201012:	c0268693          	addi	a3,a3,-1022 # ffffffffc0202c10 <etext+0x588>
ffffffffc0201016:	00002617          	auipc	a2,0x2
ffffffffc020101a:	8e260613          	addi	a2,a2,-1822 # ffffffffc02028f8 <etext+0x270>
ffffffffc020101e:	05300593          	li	a1,83
ffffffffc0201022:	00002517          	auipc	a0,0x2
ffffffffc0201026:	8ee50513          	addi	a0,a0,-1810 # ffffffffc0202910 <etext+0x288>
ffffffffc020102a:	9a0ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(n > 0);
ffffffffc020102e:	00002697          	auipc	a3,0x2
ffffffffc0201032:	bca68693          	addi	a3,a3,-1078 # ffffffffc0202bf8 <etext+0x570>
ffffffffc0201036:	00002617          	auipc	a2,0x2
ffffffffc020103a:	8c260613          	addi	a2,a2,-1854 # ffffffffc02028f8 <etext+0x270>
ffffffffc020103e:	05000593          	li	a1,80
ffffffffc0201042:	00002517          	auipc	a0,0x2
ffffffffc0201046:	8ce50513          	addi	a0,a0,-1842 # ffffffffc0202910 <etext+0x288>
ffffffffc020104a:	980ff0ef          	jal	ra,ffffffffc02001ca <__panic>

ffffffffc020104e <buddy_init>:
static list_entry_t buddy_free_lists[BUDDY_MAX_ORDER + 1];
static size_t buddy_nr_free;

static void
buddy_init(void) {
    for (unsigned int i = 0; i <= BUDDY_MAX_ORDER; i++) {
ffffffffc020104e:	00006797          	auipc	a5,0x6
ffffffffc0201052:	fea78793          	addi	a5,a5,-22 # ffffffffc0207038 <buddy_free_lists>
ffffffffc0201056:	00006717          	auipc	a4,0x6
ffffffffc020105a:	13270713          	addi	a4,a4,306 # ffffffffc0207188 <caches>
    elm->prev = elm->next = elm;
ffffffffc020105e:	e79c                	sd	a5,8(a5)
ffffffffc0201060:	e39c                	sd	a5,0(a5)
ffffffffc0201062:	07c1                	addi	a5,a5,16
ffffffffc0201064:	fee79de3          	bne	a5,a4,ffffffffc020105e <buddy_init+0x10>
        list_init(&buddy_free_lists[i]);
    }
    buddy_nr_free = 0;
ffffffffc0201068:	00006797          	auipc	a5,0x6
ffffffffc020106c:	2e07b423          	sd	zero,744(a5) # ffffffffc0207350 <buddy_nr_free>
}
ffffffffc0201070:	8082                	ret

ffffffffc0201072 <buddy_nr_free_pages>:
}

static size_t
buddy_nr_free_pages(void) {
    return buddy_nr_free;
}
ffffffffc0201072:	00006517          	auipc	a0,0x6
ffffffffc0201076:	2de53503          	ld	a0,734(a0) # ffffffffc0207350 <buddy_nr_free>
ffffffffc020107a:	8082                	ret

ffffffffc020107c <buddy_check>:

static void
buddy_check(void) {
ffffffffc020107c:	1141                	addi	sp,sp,-16
ffffffffc020107e:	e406                	sd	ra,8(sp)
ffffffffc0201080:	00006597          	auipc	a1,0x6
ffffffffc0201084:	fb858593          	addi	a1,a1,-72 # ffffffffc0207038 <buddy_free_lists>
    size_t total = 0;
    for (unsigned int o = 0; o <= BUDDY_MAX_ORDER; o++) {
ffffffffc0201088:	4501                	li	a0,0
    size_t total = 0;
ffffffffc020108a:	4681                	li	a3,0
        while ((le = list_next(le)) != &buddy_free_lists[o]) {
            struct Page *p = le2page(le, page_link);
            assert(PageBuddy(p));
            assert(PageProperty(p));
            assert(p->property == o);
            total += (1UL << o);
ffffffffc020108c:	4305                	li	t1,1
    for (unsigned int o = 0; o <= BUDDY_MAX_ORDER; o++) {
ffffffffc020108e:	48d5                	li	a7,21
    return listelm->next;
ffffffffc0201090:	659c                	ld	a5,8(a1)
        while ((le = list_next(le)) != &buddy_free_lists[o]) {
ffffffffc0201092:	02b78363          	beq	a5,a1,ffffffffc02010b8 <buddy_check+0x3c>
            total += (1UL << o);
ffffffffc0201096:	00a31833          	sll	a6,t1,a0
            assert(PageBuddy(p));
ffffffffc020109a:	ff07b703          	ld	a4,-16(a5)
ffffffffc020109e:	00477613          	andi	a2,a4,4
ffffffffc02010a2:	ca05                	beqz	a2,ffffffffc02010d2 <buddy_check+0x56>
            assert(PageProperty(p));
ffffffffc02010a4:	8b09                	andi	a4,a4,2
ffffffffc02010a6:	c731                	beqz	a4,ffffffffc02010f2 <buddy_check+0x76>
            assert(p->property == o);
ffffffffc02010a8:	ff87a703          	lw	a4,-8(a5)
ffffffffc02010ac:	06a71363          	bne	a4,a0,ffffffffc0201112 <buddy_check+0x96>
ffffffffc02010b0:	679c                	ld	a5,8(a5)
            total += (1UL << o);
ffffffffc02010b2:	96c2                	add	a3,a3,a6
        while ((le = list_next(le)) != &buddy_free_lists[o]) {
ffffffffc02010b4:	feb793e3          	bne	a5,a1,ffffffffc020109a <buddy_check+0x1e>
    for (unsigned int o = 0; o <= BUDDY_MAX_ORDER; o++) {
ffffffffc02010b8:	2505                	addiw	a0,a0,1
ffffffffc02010ba:	05c1                	addi	a1,a1,16
ffffffffc02010bc:	fd151ae3          	bne	a0,a7,ffffffffc0201090 <buddy_check+0x14>
        }
    }
    assert(total == buddy_nr_free);
ffffffffc02010c0:	00006797          	auipc	a5,0x6
ffffffffc02010c4:	2907b783          	ld	a5,656(a5) # ffffffffc0207350 <buddy_nr_free>
ffffffffc02010c8:	06d79563          	bne	a5,a3,ffffffffc0201132 <buddy_check+0xb6>
}
ffffffffc02010cc:	60a2                	ld	ra,8(sp)
ffffffffc02010ce:	0141                	addi	sp,sp,16
ffffffffc02010d0:	8082                	ret
            assert(PageBuddy(p));
ffffffffc02010d2:	00002697          	auipc	a3,0x2
ffffffffc02010d6:	bb668693          	addi	a3,a3,-1098 # ffffffffc0202c88 <best_fit_pmm_manager+0x38>
ffffffffc02010da:	00002617          	auipc	a2,0x2
ffffffffc02010de:	81e60613          	addi	a2,a2,-2018 # ffffffffc02028f8 <etext+0x270>
ffffffffc02010e2:	0ac00593          	li	a1,172
ffffffffc02010e6:	00002517          	auipc	a0,0x2
ffffffffc02010ea:	bb250513          	addi	a0,a0,-1102 # ffffffffc0202c98 <best_fit_pmm_manager+0x48>
ffffffffc02010ee:	8dcff0ef          	jal	ra,ffffffffc02001ca <__panic>
            assert(PageProperty(p));
ffffffffc02010f2:	00001697          	auipc	a3,0x1
ffffffffc02010f6:	7f668693          	addi	a3,a3,2038 # ffffffffc02028e8 <etext+0x260>
ffffffffc02010fa:	00001617          	auipc	a2,0x1
ffffffffc02010fe:	7fe60613          	addi	a2,a2,2046 # ffffffffc02028f8 <etext+0x270>
ffffffffc0201102:	0ad00593          	li	a1,173
ffffffffc0201106:	00002517          	auipc	a0,0x2
ffffffffc020110a:	b9250513          	addi	a0,a0,-1134 # ffffffffc0202c98 <best_fit_pmm_manager+0x48>
ffffffffc020110e:	8bcff0ef          	jal	ra,ffffffffc02001ca <__panic>
            assert(p->property == o);
ffffffffc0201112:	00002697          	auipc	a3,0x2
ffffffffc0201116:	b9e68693          	addi	a3,a3,-1122 # ffffffffc0202cb0 <best_fit_pmm_manager+0x60>
ffffffffc020111a:	00001617          	auipc	a2,0x1
ffffffffc020111e:	7de60613          	addi	a2,a2,2014 # ffffffffc02028f8 <etext+0x270>
ffffffffc0201122:	0ae00593          	li	a1,174
ffffffffc0201126:	00002517          	auipc	a0,0x2
ffffffffc020112a:	b7250513          	addi	a0,a0,-1166 # ffffffffc0202c98 <best_fit_pmm_manager+0x48>
ffffffffc020112e:	89cff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(total == buddy_nr_free);
ffffffffc0201132:	00002697          	auipc	a3,0x2
ffffffffc0201136:	b9668693          	addi	a3,a3,-1130 # ffffffffc0202cc8 <best_fit_pmm_manager+0x78>
ffffffffc020113a:	00001617          	auipc	a2,0x1
ffffffffc020113e:	7be60613          	addi	a2,a2,1982 # ffffffffc02028f8 <etext+0x270>
ffffffffc0201142:	0b200593          	li	a1,178
ffffffffc0201146:	00002517          	auipc	a0,0x2
ffffffffc020114a:	b5250513          	addi	a0,a0,-1198 # ffffffffc0202c98 <best_fit_pmm_manager+0x48>
ffffffffc020114e:	87cff0ef          	jal	ra,ffffffffc02001ca <__panic>

ffffffffc0201152 <buddy_free_pages>:
buddy_free_pages(struct Page *base, size_t n) {
ffffffffc0201152:	1141                	addi	sp,sp,-16
ffffffffc0201154:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201156:	18058363          	beqz	a1,ffffffffc02012dc <buddy_free_pages+0x18a>
    unsigned int order = (unsigned int)base->property;
ffffffffc020115a:	4914                	lw	a3,16(a0)
    assert((1UL << order) >= n);
ffffffffc020115c:	4885                	li	a7,1
ffffffffc020115e:	87aa                	mv	a5,a0
ffffffffc0201160:	00d898b3          	sll	a7,a7,a3
    for (size_t i = 0; i < (1UL << order); i++, p++) {
ffffffffc0201164:	4601                	li	a2,0
    assert((1UL << order) >= n);
ffffffffc0201166:	14b8eb63          	bltu	a7,a1,ffffffffc02012bc <buddy_free_pages+0x16a>
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020116a:	6798                	ld	a4,8(a5)
ffffffffc020116c:	8b0d                	andi	a4,a4,3
ffffffffc020116e:	12071763          	bnez	a4,ffffffffc020129c <buddy_free_pages+0x14a>
        p->flags = 0;
ffffffffc0201172:	0007b423          	sd	zero,8(a5)
ffffffffc0201176:	0007a023          	sw	zero,0(a5)
    for (size_t i = 0; i < (1UL << order); i++, p++) {
ffffffffc020117a:	0605                	addi	a2,a2,1
ffffffffc020117c:	02878793          	addi	a5,a5,40
ffffffffc0201180:	ff1665e3          	bltu	a2,a7,ffffffffc020116a <buddy_free_pages+0x18>
    __list_add(elm, listelm, listelm->next);
ffffffffc0201184:	02069713          	slli	a4,a3,0x20
    SetPageBuddy(base);
ffffffffc0201188:	650c                	ld	a1,8(a0)
ffffffffc020118a:	01c75793          	srli	a5,a4,0x1c
ffffffffc020118e:	00006617          	auipc	a2,0x6
ffffffffc0201192:	eaa60613          	addi	a2,a2,-342 # ffffffffc0207038 <buddy_free_lists>
ffffffffc0201196:	97b2                	add	a5,a5,a2
ffffffffc0201198:	0087b303          	ld	t1,8(a5)
    buddy_nr_free += (1UL << order);
ffffffffc020119c:	00006e17          	auipc	t3,0x6
ffffffffc02011a0:	1b4e0e13          	addi	t3,t3,436 # ffffffffc0207350 <buddy_nr_free>
ffffffffc02011a4:	000e3703          	ld	a4,0(t3)
    SetPageBuddy(base);
ffffffffc02011a8:	0065e593          	ori	a1,a1,6
    base->property = order;
ffffffffc02011ac:	c914                	sw	a3,16(a0)
    SetPageBuddy(base);
ffffffffc02011ae:	e50c                	sd	a1,8(a0)
    list_add(&buddy_free_lists[order], &(base->page_link));
ffffffffc02011b0:	01850813          	addi	a6,a0,24
    prev->next = next->prev = elm;
ffffffffc02011b4:	01033023          	sd	a6,0(t1)
ffffffffc02011b8:	0107b423          	sd	a6,8(a5)
    buddy_nr_free += (1UL << order);
ffffffffc02011bc:	98ba                	add	a7,a7,a4
    elm->prev = prev;
ffffffffc02011be:	ed1c                	sd	a5,24(a0)
ffffffffc02011c0:	011e3023          	sd	a7,0(t3)
    elm->next = next;
ffffffffc02011c4:	02653023          	sd	t1,32(a0)
    while (order < BUDDY_MAX_ORDER) {
ffffffffc02011c8:	47cd                	li	a5,19
ffffffffc02011ca:	0cd7e663          	bltu	a5,a3,ffffffffc0201296 <buddy_free_pages+0x144>
ffffffffc02011ce:	0016879b          	addiw	a5,a3,1
ffffffffc02011d2:	02079713          	slli	a4,a5,0x20
ffffffffc02011d6:	01c75793          	srli	a5,a4,0x1c
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02011da:	00006897          	auipc	a7,0x6
ffffffffc02011de:	1868b883          	ld	a7,390(a7) # ffffffffc0207360 <pages>
ffffffffc02011e2:	00002597          	auipc	a1,0x2
ffffffffc02011e6:	48e5b583          	ld	a1,1166(a1) # ffffffffc0203670 <nbase>
        if (buddy_ppn < nbase || buddy_ppn >= npage) {
ffffffffc02011ea:	00006e97          	auipc	t4,0x6
ffffffffc02011ee:	16eebe83          	ld	t4,366(t4) # ffffffffc0207358 <npage>
ffffffffc02011f2:	963e                	add	a2,a2,a5
ffffffffc02011f4:	00002e17          	auipc	t3,0x2
ffffffffc02011f8:	474e3e03          	ld	t3,1140(t3) # ffffffffc0203668 <error_string+0x38>
        ppn_t buddy_ppn = ppn ^ (1UL << order);
ffffffffc02011fc:	4305                	li	t1,1
        if (!PageBuddy(buddy) || !PageProperty(buddy) ||
ffffffffc02011fe:	4f19                	li	t5,6
    while (order < BUDDY_MAX_ORDER) {
ffffffffc0201200:	4fd1                	li	t6,20
ffffffffc0201202:	a8bd                	j	ffffffffc0201280 <buddy_free_pages+0x12e>
        if (buddy_ppn < nbase || buddy_ppn >= npage) {
ffffffffc0201204:	09d7f963          	bgeu	a5,t4,ffffffffc0201296 <buddy_free_pages+0x144>
        struct Page *buddy = &pages[buddy_ppn - nbase];
ffffffffc0201208:	8f8d                	sub	a5,a5,a1
ffffffffc020120a:	00279713          	slli	a4,a5,0x2
ffffffffc020120e:	97ba                	add	a5,a5,a4
ffffffffc0201210:	078e                	slli	a5,a5,0x3
ffffffffc0201212:	97c6                	add	a5,a5,a7
        if (!PageBuddy(buddy) || !PageProperty(buddy) ||
ffffffffc0201214:	6798                	ld	a4,8(a5)
ffffffffc0201216:	8b19                	andi	a4,a4,6
ffffffffc0201218:	07e71f63          	bne	a4,t5,ffffffffc0201296 <buddy_free_pages+0x144>
ffffffffc020121c:	4b98                	lw	a4,16(a5)
ffffffffc020121e:	06d71c63          	bne	a4,a3,ffffffffc0201296 <buddy_free_pages+0x144>
    __list_del(listelm->prev, listelm->next);
ffffffffc0201222:	01853383          	ld	t2,24(a0)
ffffffffc0201226:	02053283          	ld	t0,32(a0)
        ClearPageBuddy(base);
ffffffffc020122a:	6518                	ld	a4,8(a0)
    prev->next = next;
ffffffffc020122c:	0053b423          	sd	t0,8(t2)
    next->prev = prev;
ffffffffc0201230:	0072b023          	sd	t2,0(t0)
ffffffffc0201234:	9b65                	andi	a4,a4,-7
ffffffffc0201236:	e518                	sd	a4,8(a0)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201238:	0187b383          	ld	t2,24(a5)
ffffffffc020123c:	0207b283          	ld	t0,32(a5)
        ClearPageBuddy(buddy);
ffffffffc0201240:	6798                	ld	a4,8(a5)
        base->property = 0;
ffffffffc0201242:	00052823          	sw	zero,16(a0)
    prev->next = next;
ffffffffc0201246:	0053b423          	sd	t0,8(t2)
    next->prev = prev;
ffffffffc020124a:	0072b023          	sd	t2,0(t0)
        ClearPageBuddy(buddy);
ffffffffc020124e:	9b65                	andi	a4,a4,-7
ffffffffc0201250:	e798                	sd	a4,8(a5)
        buddy->property = 0;
ffffffffc0201252:	0007a823          	sw	zero,16(a5)
        struct Page *newbase = (buddy < base) ? buddy : base;
ffffffffc0201256:	00a7f563          	bgeu	a5,a0,ffffffffc0201260 <buddy_free_pages+0x10e>
ffffffffc020125a:	853e                	mv	a0,a5
ffffffffc020125c:	01878813          	addi	a6,a5,24
        SetPageBuddy(newbase);
ffffffffc0201260:	651c                	ld	a5,8(a0)
    __list_add(elm, listelm, listelm->next);
ffffffffc0201262:	6618                	ld	a4,8(a2)
        newbase->property = order + 1;
ffffffffc0201264:	2685                	addiw	a3,a3,1
        SetPageBuddy(newbase);
ffffffffc0201266:	0067e793          	ori	a5,a5,6
        newbase->property = order + 1;
ffffffffc020126a:	c914                	sw	a3,16(a0)
        SetPageBuddy(newbase);
ffffffffc020126c:	e51c                	sd	a5,8(a0)
    prev->next = next->prev = elm;
ffffffffc020126e:	01073023          	sd	a6,0(a4)
ffffffffc0201272:	01063423          	sd	a6,8(a2)
    elm->prev = prev;
ffffffffc0201276:	ed10                	sd	a2,24(a0)
    elm->next = next;
ffffffffc0201278:	f118                	sd	a4,32(a0)
    while (order < BUDDY_MAX_ORDER) {
ffffffffc020127a:	0641                	addi	a2,a2,16
ffffffffc020127c:	01f68d63          	beq	a3,t6,ffffffffc0201296 <buddy_free_pages+0x144>
ffffffffc0201280:	41150733          	sub	a4,a0,a7
ffffffffc0201284:	870d                	srai	a4,a4,0x3
ffffffffc0201286:	03c70733          	mul	a4,a4,t3
        ppn_t buddy_ppn = ppn ^ (1UL << order);
ffffffffc020128a:	00d317b3          	sll	a5,t1,a3
ffffffffc020128e:	972e                	add	a4,a4,a1
ffffffffc0201290:	8fb9                	xor	a5,a5,a4
        if (buddy_ppn < nbase || buddy_ppn >= npage) {
ffffffffc0201292:	f6b7f9e3          	bgeu	a5,a1,ffffffffc0201204 <buddy_free_pages+0xb2>
}
ffffffffc0201296:	60a2                	ld	ra,8(sp)
ffffffffc0201298:	0141                	addi	sp,sp,16
ffffffffc020129a:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020129c:	00002697          	auipc	a3,0x2
ffffffffc02012a0:	97468693          	addi	a3,a3,-1676 # ffffffffc0202c10 <etext+0x588>
ffffffffc02012a4:	00001617          	auipc	a2,0x1
ffffffffc02012a8:	65460613          	addi	a2,a2,1620 # ffffffffc02028f8 <etext+0x270>
ffffffffc02012ac:	07300593          	li	a1,115
ffffffffc02012b0:	00002517          	auipc	a0,0x2
ffffffffc02012b4:	9e850513          	addi	a0,a0,-1560 # ffffffffc0202c98 <best_fit_pmm_manager+0x48>
ffffffffc02012b8:	f13fe0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert((1UL << order) >= n);
ffffffffc02012bc:	00002697          	auipc	a3,0x2
ffffffffc02012c0:	a2468693          	addi	a3,a3,-1500 # ffffffffc0202ce0 <best_fit_pmm_manager+0x90>
ffffffffc02012c4:	00001617          	auipc	a2,0x1
ffffffffc02012c8:	63460613          	addi	a2,a2,1588 # ffffffffc02028f8 <etext+0x270>
ffffffffc02012cc:	06f00593          	li	a1,111
ffffffffc02012d0:	00002517          	auipc	a0,0x2
ffffffffc02012d4:	9c850513          	addi	a0,a0,-1592 # ffffffffc0202c98 <best_fit_pmm_manager+0x48>
ffffffffc02012d8:	ef3fe0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(n > 0);
ffffffffc02012dc:	00002697          	auipc	a3,0x2
ffffffffc02012e0:	91c68693          	addi	a3,a3,-1764 # ffffffffc0202bf8 <etext+0x570>
ffffffffc02012e4:	00001617          	auipc	a2,0x1
ffffffffc02012e8:	61460613          	addi	a2,a2,1556 # ffffffffc02028f8 <etext+0x270>
ffffffffc02012ec:	06c00593          	li	a1,108
ffffffffc02012f0:	00002517          	auipc	a0,0x2
ffffffffc02012f4:	9a850513          	addi	a0,a0,-1624 # ffffffffc0202c98 <best_fit_pmm_manager+0x48>
ffffffffc02012f8:	ed3fe0ef          	jal	ra,ffffffffc02001ca <__panic>

ffffffffc02012fc <buddy_alloc_pages>:
    assert(n > 0);
ffffffffc02012fc:	c561                	beqz	a0,ffffffffc02013c4 <buddy_alloc_pages+0xc8>
    if (n > buddy_nr_free) {
ffffffffc02012fe:	00006e97          	auipc	t4,0x6
ffffffffc0201302:	052e8e93          	addi	t4,t4,82 # ffffffffc0207350 <buddy_nr_free>
ffffffffc0201306:	000ebe03          	ld	t3,0(t4)
ffffffffc020130a:	00ae6b63          	bltu	t3,a0,ffffffffc0201320 <buddy_alloc_pages+0x24>
    size_t block = 1;
ffffffffc020130e:	4785                	li	a5,1
    unsigned int order = 0;
ffffffffc0201310:	4701                	li	a4,0
        if (order > BUDDY_MAX_ORDER) {
ffffffffc0201312:	46d5                	li	a3,21
    while (block < n) {
ffffffffc0201314:	00a7f863          	bgeu	a5,a0,ffffffffc0201324 <buddy_alloc_pages+0x28>
        order++;
ffffffffc0201318:	2705                	addiw	a4,a4,1
        block <<= 1;
ffffffffc020131a:	0786                	slli	a5,a5,0x1
        if (order > BUDDY_MAX_ORDER) {
ffffffffc020131c:	fed71ce3          	bne	a4,a3,ffffffffc0201314 <buddy_alloc_pages+0x18>
        return NULL;
ffffffffc0201320:	4501                	li	a0,0
}
ffffffffc0201322:	8082                	ret
ffffffffc0201324:	02071793          	slli	a5,a4,0x20
ffffffffc0201328:	01c7d693          	srli	a3,a5,0x1c
ffffffffc020132c:	00006617          	auipc	a2,0x6
ffffffffc0201330:	d0c60613          	addi	a2,a2,-756 # ffffffffc0207038 <buddy_free_lists>
ffffffffc0201334:	96b2                	add	a3,a3,a2
    return list->next == list;
ffffffffc0201336:	0086b803          	ld	a6,8(a3)
    while (block < n) {
ffffffffc020133a:	87ba                	mv	a5,a4
    while (o <= BUDDY_MAX_ORDER && list_empty(&buddy_free_lists[o])) {
ffffffffc020133c:	45d5                	li	a1,21
ffffffffc020133e:	00d81a63          	bne	a6,a3,ffffffffc0201352 <buddy_alloc_pages+0x56>
        o++;
ffffffffc0201342:	2785                	addiw	a5,a5,1
    while (o <= BUDDY_MAX_ORDER && list_empty(&buddy_free_lists[o])) {
ffffffffc0201344:	06c1                	addi	a3,a3,16
ffffffffc0201346:	fcb78de3          	beq	a5,a1,ffffffffc0201320 <buddy_alloc_pages+0x24>
ffffffffc020134a:	0086b803          	ld	a6,8(a3)
ffffffffc020134e:	fed80ae3          	beq	a6,a3,ffffffffc0201342 <buddy_alloc_pages+0x46>
    __list_del(listelm->prev, listelm->next);
ffffffffc0201352:	00083583          	ld	a1,0(a6)
ffffffffc0201356:	00883683          	ld	a3,8(a6)
    struct Page *page = le2page(list_next(&buddy_free_lists[o]), page_link);
ffffffffc020135a:	fe880513          	addi	a0,a6,-24
    prev->next = next;
ffffffffc020135e:	e594                	sd	a3,8(a1)
    next->prev = prev;
ffffffffc0201360:	e28c                	sd	a1,0(a3)
    while (o > order) {
ffffffffc0201362:	04f77163          	bgeu	a4,a5,ffffffffc02013a4 <buddy_alloc_pages+0xa8>
ffffffffc0201366:	37fd                	addiw	a5,a5,-1
ffffffffc0201368:	02079593          	slli	a1,a5,0x20
ffffffffc020136c:	01c5d693          	srli	a3,a1,0x1c
ffffffffc0201370:	9636                	add	a2,a2,a3
        struct Page *buddy = page + (1UL << o);
ffffffffc0201372:	02800313          	li	t1,40
ffffffffc0201376:	a011                	j	ffffffffc020137a <buddy_alloc_pages+0x7e>
ffffffffc0201378:	37fd                	addiw	a5,a5,-1
ffffffffc020137a:	00f316b3          	sll	a3,t1,a5
ffffffffc020137e:	96aa                	add	a3,a3,a0
        SetPageBuddy(buddy);
ffffffffc0201380:	668c                	ld	a1,8(a3)
    __list_add(elm, listelm, listelm->next);
ffffffffc0201382:	00863883          	ld	a7,8(a2)
        buddy->property = o;
ffffffffc0201386:	ca9c                	sw	a5,16(a3)
        SetPageBuddy(buddy);
ffffffffc0201388:	0065e593          	ori	a1,a1,6
ffffffffc020138c:	e68c                	sd	a1,8(a3)
        list_add(&buddy_free_lists[o], &(buddy->page_link));
ffffffffc020138e:	01868593          	addi	a1,a3,24
    prev->next = next->prev = elm;
ffffffffc0201392:	00b8b023          	sd	a1,0(a7)
ffffffffc0201396:	e60c                	sd	a1,8(a2)
    elm->prev = prev;
ffffffffc0201398:	ee90                	sd	a2,24(a3)
    elm->next = next;
ffffffffc020139a:	0316b023          	sd	a7,32(a3)
    while (o > order) {
ffffffffc020139e:	1641                	addi	a2,a2,-16
ffffffffc02013a0:	fcf71ce3          	bne	a4,a5,ffffffffc0201378 <buddy_alloc_pages+0x7c>
    ClearPageBuddy(page);
ffffffffc02013a4:	ff083683          	ld	a3,-16(a6)
    buddy_nr_free -= (1UL << order);
ffffffffc02013a8:	4785                	li	a5,1
ffffffffc02013aa:	00e797b3          	sll	a5,a5,a4
ffffffffc02013ae:	40fe0e33          	sub	t3,t3,a5
    ClearPageBuddy(page);
ffffffffc02013b2:	ff96f793          	andi	a5,a3,-7
    buddy_nr_free -= (1UL << order);
ffffffffc02013b6:	01ceb023          	sd	t3,0(t4)
    ClearPageBuddy(page);
ffffffffc02013ba:	fef83823          	sd	a5,-16(a6)
    page->property = order;
ffffffffc02013be:	fee82c23          	sw	a4,-8(a6)
    return page;
ffffffffc02013c2:	8082                	ret
buddy_alloc_pages(size_t n) {
ffffffffc02013c4:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc02013c6:	00002697          	auipc	a3,0x2
ffffffffc02013ca:	83268693          	addi	a3,a3,-1998 # ffffffffc0202bf8 <etext+0x570>
ffffffffc02013ce:	00001617          	auipc	a2,0x1
ffffffffc02013d2:	52a60613          	addi	a2,a2,1322 # ffffffffc02028f8 <etext+0x270>
ffffffffc02013d6:	03e00593          	li	a1,62
ffffffffc02013da:	00002517          	auipc	a0,0x2
ffffffffc02013de:	8be50513          	addi	a0,a0,-1858 # ffffffffc0202c98 <best_fit_pmm_manager+0x48>
buddy_alloc_pages(size_t n) {
ffffffffc02013e2:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02013e4:	de7fe0ef          	jal	ra,ffffffffc02001ca <__panic>

ffffffffc02013e8 <buddy_init_memmap>:
buddy_init_memmap(struct Page *base, size_t n) {
ffffffffc02013e8:	1101                	addi	sp,sp,-32
ffffffffc02013ea:	ec06                	sd	ra,24(sp)
ffffffffc02013ec:	e822                	sd	s0,16(sp)
ffffffffc02013ee:	e426                	sd	s1,8(sp)
    assert(n > 0);
ffffffffc02013f0:	10058663          	beqz	a1,ffffffffc02014fc <buddy_init_memmap+0x114>
    for (; p != base + n; p++) {
ffffffffc02013f4:	00259693          	slli	a3,a1,0x2
ffffffffc02013f8:	96ae                	add	a3,a3,a1
ffffffffc02013fa:	068e                	slli	a3,a3,0x3
ffffffffc02013fc:	96aa                	add	a3,a3,a0
ffffffffc02013fe:	87aa                	mv	a5,a0
ffffffffc0201400:	00d50f63          	beq	a0,a3,ffffffffc020141e <buddy_init_memmap+0x36>
        assert(PageReserved(p));
ffffffffc0201404:	6798                	ld	a4,8(a5)
ffffffffc0201406:	8b05                	andi	a4,a4,1
ffffffffc0201408:	cb79                	beqz	a4,ffffffffc02014de <buddy_init_memmap+0xf6>
        p->flags = 0;
ffffffffc020140a:	0007b423          	sd	zero,8(a5)
        p->property = 0;
ffffffffc020140e:	0007a823          	sw	zero,16(a5)
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0201412:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++) {
ffffffffc0201416:	02878793          	addi	a5,a5,40
ffffffffc020141a:	fed795e3          	bne	a5,a3,ffffffffc0201404 <buddy_init_memmap+0x1c>
ffffffffc020141e:	00006497          	auipc	s1,0x6
ffffffffc0201422:	f3248493          	addi	s1,s1,-206 # ffffffffc0207350 <buddy_nr_free>
ffffffffc0201426:	0004bf03          	ld	t5,0(s1)
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020142a:	00006417          	auipc	s0,0x6
ffffffffc020142e:	f3643403          	ld	s0,-202(s0) # ffffffffc0207360 <pages>
ffffffffc0201432:	00002397          	auipc	t2,0x2
ffffffffc0201436:	23e3b383          	ld	t2,574(t2) # ffffffffc0203670 <nbase>
    size_t cur = 0;
ffffffffc020143a:	4e81                	li	t4,0
ffffffffc020143c:	00002297          	auipc	t0,0x2
ffffffffc0201440:	22c2b283          	ld	t0,556(t0) # ffffffffc0203668 <error_string+0x38>
ffffffffc0201444:	00006f97          	auipc	t6,0x6
ffffffffc0201448:	bf4f8f93          	addi	t6,t6,-1036 # ffffffffc0207038 <buddy_free_lists>
        while (order < BUDDY_MAX_ORDER &&
ffffffffc020144c:	4e51                	li	t3,20
               ((page2ppn(base + cur) & ((block << 1) - 1)) == 0)) {
ffffffffc020144e:	002e9813          	slli	a6,t4,0x2
ffffffffc0201452:	9876                	add	a6,a6,t4
ffffffffc0201454:	080e                	slli	a6,a6,0x3
ffffffffc0201456:	982a                	add	a6,a6,a0
ffffffffc0201458:	40880633          	sub	a2,a6,s0
ffffffffc020145c:	860d                	srai	a2,a2,0x3
ffffffffc020145e:	02560633          	mul	a2,a2,t0
        size_t remaining = n - cur;
ffffffffc0201462:	41d588b3          	sub	a7,a1,t4
        size_t block = 1;
ffffffffc0201466:	4785                	li	a5,1
        unsigned int order = 0;
ffffffffc0201468:	4681                	li	a3,0
ffffffffc020146a:	961e                	add	a2,a2,t2
ffffffffc020146c:	833e                	mv	t1,a5
               (block << 1) <= remaining &&
ffffffffc020146e:	0786                	slli	a5,a5,0x1
        while (order < BUDDY_MAX_ORDER &&
ffffffffc0201470:	06f8e063          	bltu	a7,a5,ffffffffc02014d0 <buddy_init_memmap+0xe8>
               ((page2ppn(base + cur) & ((block << 1) - 1)) == 0)) {
ffffffffc0201474:	fff78713          	addi	a4,a5,-1
ffffffffc0201478:	8f71                	and	a4,a4,a2
               (block << 1) <= remaining &&
ffffffffc020147a:	eb39                	bnez	a4,ffffffffc02014d0 <buddy_init_memmap+0xe8>
            order++;
ffffffffc020147c:	2685                	addiw	a3,a3,1
        while (order < BUDDY_MAX_ORDER &&
ffffffffc020147e:	ffc697e3          	bne	a3,t3,ffffffffc020146c <buddy_init_memmap+0x84>
ffffffffc0201482:	02069713          	slli	a4,a3,0x20
ffffffffc0201486:	14000893          	li	a7,320
ffffffffc020148a:	9301                	srli	a4,a4,0x20
        SetPageBuddy(head);
ffffffffc020148c:	00883603          	ld	a2,8(a6)
    __list_add(elm, listelm, listelm->next);
ffffffffc0201490:	0712                	slli	a4,a4,0x4
ffffffffc0201492:	977e                	add	a4,a4,t6
ffffffffc0201494:	00873303          	ld	t1,8(a4)
ffffffffc0201498:	00666613          	ori	a2,a2,6
        head->property = order;
ffffffffc020149c:	00d82823          	sw	a3,16(a6)
        SetPageBuddy(head);
ffffffffc02014a0:	00c83423          	sd	a2,8(a6)
        list_add(&buddy_free_lists[order], &(head->page_link));
ffffffffc02014a4:	01880693          	addi	a3,a6,24
    prev->next = next->prev = elm;
ffffffffc02014a8:	00d33023          	sd	a3,0(t1)
ffffffffc02014ac:	e714                	sd	a3,8(a4)
ffffffffc02014ae:	011f8733          	add	a4,t6,a7
    elm->next = next;
ffffffffc02014b2:	02683023          	sd	t1,32(a6)
    elm->prev = prev;
ffffffffc02014b6:	00e83c23          	sd	a4,24(a6)
        cur += block;
ffffffffc02014ba:	9ebe                	add	t4,t4,a5
        buddy_nr_free += block;
ffffffffc02014bc:	9f3e                	add	t5,t5,a5
    while (cur < n) {
ffffffffc02014be:	f8bee8e3          	bltu	t4,a1,ffffffffc020144e <buddy_init_memmap+0x66>
}
ffffffffc02014c2:	60e2                	ld	ra,24(sp)
ffffffffc02014c4:	6442                	ld	s0,16(sp)
ffffffffc02014c6:	01e4b023          	sd	t5,0(s1)
ffffffffc02014ca:	64a2                	ld	s1,8(sp)
ffffffffc02014cc:	6105                	addi	sp,sp,32
ffffffffc02014ce:	8082                	ret
ffffffffc02014d0:	02069713          	slli	a4,a3,0x20
ffffffffc02014d4:	9301                	srli	a4,a4,0x20
ffffffffc02014d6:	00471893          	slli	a7,a4,0x4
               (block << 1) <= remaining &&
ffffffffc02014da:	879a                	mv	a5,t1
ffffffffc02014dc:	bf45                	j	ffffffffc020148c <buddy_init_memmap+0xa4>
        assert(PageReserved(p));
ffffffffc02014de:	00001697          	auipc	a3,0x1
ffffffffc02014e2:	72268693          	addi	a3,a3,1826 # ffffffffc0202c00 <etext+0x578>
ffffffffc02014e6:	00001617          	auipc	a2,0x1
ffffffffc02014ea:	41260613          	addi	a2,a2,1042 # ffffffffc02028f8 <etext+0x270>
ffffffffc02014ee:	45f9                	li	a1,30
ffffffffc02014f0:	00001517          	auipc	a0,0x1
ffffffffc02014f4:	7a850513          	addi	a0,a0,1960 # ffffffffc0202c98 <best_fit_pmm_manager+0x48>
ffffffffc02014f8:	cd3fe0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(n > 0);
ffffffffc02014fc:	00001697          	auipc	a3,0x1
ffffffffc0201500:	6fc68693          	addi	a3,a3,1788 # ffffffffc0202bf8 <etext+0x570>
ffffffffc0201504:	00001617          	auipc	a2,0x1
ffffffffc0201508:	3f460613          	addi	a2,a2,1012 # ffffffffc02028f8 <etext+0x270>
ffffffffc020150c:	45e9                	li	a1,26
ffffffffc020150e:	00001517          	auipc	a0,0x1
ffffffffc0201512:	78a50513          	addi	a0,a0,1930 # ffffffffc0202c98 <best_fit_pmm_manager+0x48>
ffffffffc0201516:	cb5fe0ef          	jal	ra,ffffffffc02001ca <__panic>

ffffffffc020151a <buddy_test>:
buddy_fail(const char *msg) {
    cprintf("[Buddy] FAIL: %s\n", msg);
}

void
buddy_test(void) {
ffffffffc020151a:	b2010113          	addi	sp,sp,-1248
    cprintf("[Buddy] running tests\n");
ffffffffc020151e:	00002517          	auipc	a0,0x2
ffffffffc0201522:	82a50513          	addi	a0,a0,-2006 # ffffffffc0202d48 <buddy_pmm_manager+0x38>
buddy_test(void) {
ffffffffc0201526:	4c113c23          	sd	ra,1240(sp)
ffffffffc020152a:	4c813823          	sd	s0,1232(sp)
ffffffffc020152e:	4c913423          	sd	s1,1224(sp)
ffffffffc0201532:	4d213023          	sd	s2,1216(sp)
ffffffffc0201536:	4b313c23          	sd	s3,1208(sp)
ffffffffc020153a:	4b413823          	sd	s4,1200(sp)
ffffffffc020153e:	4b513423          	sd	s5,1192(sp)
ffffffffc0201542:	4b613023          	sd	s6,1184(sp)
ffffffffc0201546:	49713c23          	sd	s7,1176(sp)
ffffffffc020154a:	49813823          	sd	s8,1168(sp)
ffffffffc020154e:	49913423          	sd	s9,1160(sp)
ffffffffc0201552:	49a13023          	sd	s10,1152(sp)
ffffffffc0201556:	47b13c23          	sd	s11,1144(sp)
    cprintf("[Buddy] running tests\n");
ffffffffc020155a:	bfbfe0ef          	jal	ra,ffffffffc0200154 <cprintf>
    size_t before = nr_free_pages();
ffffffffc020155e:	402000ef          	jal	ra,ffffffffc0201960 <nr_free_pages>
ffffffffc0201562:	87aa                	mv	a5,a0

    struct Page *pool = alloc_pages(BUDDY_POOL_PAGES);
ffffffffc0201564:	6505                	lui	a0,0x1
ffffffffc0201566:	80050513          	addi	a0,a0,-2048 # 800 <kern_entry-0xffffffffc01ff800>
    size_t before = nr_free_pages();
ffffffffc020156a:	ec3e                	sd	a5,24(sp)
    struct Page *pool = alloc_pages(BUDDY_POOL_PAGES);
ffffffffc020156c:	3dc000ef          	jal	ra,ffffffffc0201948 <alloc_pages>
    if (pool == NULL) {
ffffffffc0201570:	38050663          	beqz	a0,ffffffffc02018fc <buddy_test+0x3e2>
ffffffffc0201574:	00006d17          	auipc	s10,0x6
ffffffffc0201578:	decd0d13          	addi	s10,s10,-532 # ffffffffc0207360 <pages>
ffffffffc020157c:	000d3783          	ld	a5,0(s10)
ffffffffc0201580:	00002c97          	auipc	s9,0x2
ffffffffc0201584:	0e8cbc83          	ld	s9,232(s9) # ffffffffc0203668 <error_string+0x38>
ffffffffc0201588:	00002717          	auipc	a4,0x2
ffffffffc020158c:	0e873703          	ld	a4,232(a4) # ffffffffc0203670 <nbase>
ffffffffc0201590:	40f507b3          	sub	a5,a0,a5
ffffffffc0201594:	878d                	srai	a5,a5,0x3
ffffffffc0201596:	039787b3          	mul	a5,a5,s9
ffffffffc020159a:	66a9                	lui	a3,0xa
ffffffffc020159c:	06a1                	addi	a3,a3,8
ffffffffc020159e:	8b2a                	mv	s6,a0
ffffffffc02015a0:	e83a                	sd	a4,16(sp)
ffffffffc02015a2:	97ba                	add	a5,a5,a4
        return;
    }

    size_t align = BUDDY_SUB_PAGES;
    size_t offset = (align - (page2ppn(pool) % align)) % align;
    struct Page *sub = pool + offset;
ffffffffc02015a4:	40f007b3          	neg	a5,a5
ffffffffc02015a8:	3ff7f793          	andi	a5,a5,1023
ffffffffc02015ac:	00279413          	slli	s0,a5,0x2
ffffffffc02015b0:	943e                	add	s0,s0,a5
ffffffffc02015b2:	040e                	slli	s0,s0,0x3
ffffffffc02015b4:	942a                	add	s0,s0,a0

    for (size_t i = 0; i < BUDDY_SUB_PAGES; i++) {
ffffffffc02015b6:	00840793          	addi	a5,s0,8
ffffffffc02015ba:	96a2                	add	a3,a3,s0
        SetPageReserved(sub + i);
ffffffffc02015bc:	6398                	ld	a4,0(a5)
    for (size_t i = 0; i < BUDDY_SUB_PAGES; i++) {
ffffffffc02015be:	02878793          	addi	a5,a5,40
        SetPageReserved(sub + i);
ffffffffc02015c2:	00176713          	ori	a4,a4,1
ffffffffc02015c6:	fce7bc23          	sd	a4,-40(a5)
    for (size_t i = 0; i < BUDDY_SUB_PAGES; i++) {
ffffffffc02015ca:	fed799e3          	bne	a5,a3,ffffffffc02015bc <buddy_test+0xa2>
    }

    buddy_pmm_manager.init();
ffffffffc02015ce:	00001497          	auipc	s1,0x1
ffffffffc02015d2:	74248493          	addi	s1,s1,1858 # ffffffffc0202d10 <buddy_pmm_manager>
ffffffffc02015d6:	649c                	ld	a5,8(s1)
ffffffffc02015d8:	9782                	jalr	a5
    buddy_pmm_manager.init_memmap(sub, BUDDY_SUB_PAGES);
ffffffffc02015da:	689c                	ld	a5,16(s1)
ffffffffc02015dc:	40000593          	li	a1,1024
ffffffffc02015e0:	8522                	mv	a0,s0
ffffffffc02015e2:	9782                	jalr	a5

    // 1. initial state and oversized allocation
    if (buddy_pmm_manager.nr_free_pages() != BUDDY_SUB_PAGES) {
ffffffffc02015e4:	749c                	ld	a5,40(s1)
ffffffffc02015e6:	e43e                	sd	a5,8(sp)
ffffffffc02015e8:	9782                	jalr	a5
ffffffffc02015ea:	40000793          	li	a5,1024
ffffffffc02015ee:	26f51a63          	bne	a0,a5,ffffffffc0201862 <buddy_test+0x348>
        buddy_fail("initial nr_free");
    }
    buddy_pmm_manager.check();
ffffffffc02015f2:	789c                	ld	a5,48(s1)
ffffffffc02015f4:	f03e                	sd	a5,32(sp)
ffffffffc02015f6:	9782                	jalr	a5
    if (buddy_pmm_manager.alloc_pages(BUDDY_SUB_PAGES + 1) != NULL) {
ffffffffc02015f8:	0184b903          	ld	s2,24(s1)
ffffffffc02015fc:	40100513          	li	a0,1025
ffffffffc0201600:	9902                	jalr	s2
ffffffffc0201602:	c919                	beqz	a0,ffffffffc0201618 <buddy_test+0xfe>
    cprintf("[Buddy] FAIL: %s\n", msg);
ffffffffc0201604:	00001597          	auipc	a1,0x1
ffffffffc0201608:	7ac58593          	addi	a1,a1,1964 # ffffffffc0202db0 <buddy_pmm_manager+0xa0>
ffffffffc020160c:	00001517          	auipc	a0,0x1
ffffffffc0201610:	77c50513          	addi	a0,a0,1916 # ffffffffc0202d88 <buddy_pmm_manager+0x78>
ffffffffc0201614:	b41fe0ef          	jal	ra,ffffffffc0200154 <cprintf>
        buddy_fail("oversized allocation should return NULL");
    }

    // 2. deterministic split/merge of two single-page buddies
    struct Page *a = buddy_pmm_manager.alloc_pages(1);
ffffffffc0201618:	4505                	li	a0,1
ffffffffc020161a:	9902                	jalr	s2
ffffffffc020161c:	842a                	mv	s0,a0
    struct Page *b = buddy_pmm_manager.alloc_pages(1);
ffffffffc020161e:	4505                	li	a0,1
ffffffffc0201620:	9902                	jalr	s2
ffffffffc0201622:	89aa                	mv	s3,a0
    if (a == NULL || b == NULL) {
ffffffffc0201624:	2c040163          	beqz	s0,ffffffffc02018e6 <buddy_test+0x3cc>
ffffffffc0201628:	2a050f63          	beqz	a0,ffffffffc02018e6 <buddy_test+0x3cc>
        buddy_fail("single-page allocation");
    }
    if (b != a + 1) {
ffffffffc020162c:	02840793          	addi	a5,s0,40
ffffffffc0201630:	00f98c63          	beq	s3,a5,ffffffffc0201648 <buddy_test+0x12e>
    cprintf("[Buddy] FAIL: %s\n", msg);
ffffffffc0201634:	00001597          	auipc	a1,0x1
ffffffffc0201638:	7bc58593          	addi	a1,a1,1980 # ffffffffc0202df0 <buddy_pmm_manager+0xe0>
ffffffffc020163c:	00001517          	auipc	a0,0x1
ffffffffc0201640:	74c50513          	addi	a0,a0,1868 # ffffffffc0202d88 <buddy_pmm_manager+0x78>
ffffffffc0201644:	b11fe0ef          	jal	ra,ffffffffc0200154 <cprintf>
        buddy_fail("consecutive 1-page allocations are not buddies");
    }
    buddy_pmm_manager.free_pages(a, 1);
ffffffffc0201648:	7084                	ld	s1,32(s1)
ffffffffc020164a:	4585                	li	a1,1
ffffffffc020164c:	8522                	mv	a0,s0
ffffffffc020164e:	9482                	jalr	s1
    buddy_pmm_manager.free_pages(b, 1);
ffffffffc0201650:	854e                	mv	a0,s3
ffffffffc0201652:	4585                	li	a1,1
ffffffffc0201654:	9482                	jalr	s1
    struct Page *c = buddy_pmm_manager.alloc_pages(2);
ffffffffc0201656:	4509                	li	a0,2
ffffffffc0201658:	9902                	jalr	s2
ffffffffc020165a:	89aa                	mv	s3,a0
    if (c != a) {
ffffffffc020165c:	00a40c63          	beq	s0,a0,ffffffffc0201674 <buddy_test+0x15a>
    cprintf("[Buddy] FAIL: %s\n", msg);
ffffffffc0201660:	00001597          	auipc	a1,0x1
ffffffffc0201664:	7c058593          	addi	a1,a1,1984 # ffffffffc0202e20 <buddy_pmm_manager+0x110>
ffffffffc0201668:	00001517          	auipc	a0,0x1
ffffffffc020166c:	72050513          	addi	a0,a0,1824 # ffffffffc0202d88 <buddy_pmm_manager+0x78>
ffffffffc0201670:	ae5fe0ef          	jal	ra,ffffffffc0200154 <cprintf>
        buddy_fail("buddies did not merge into their parent block");
    }
    buddy_pmm_manager.free_pages(c, 2);
ffffffffc0201674:	4589                	li	a1,2
ffffffffc0201676:	854e                	mv	a0,s3
ffffffffc0201678:	9482                	jalr	s1
    if (buddy_pmm_manager.nr_free_pages() != BUDDY_SUB_PAGES) {
ffffffffc020167a:	67a2                	ld	a5,8(sp)
ffffffffc020167c:	9782                	jalr	a5
ffffffffc020167e:	40000793          	li	a5,1024
ffffffffc0201682:	24f51763          	bne	a0,a5,ffffffffc02018d0 <buddy_test+0x3b6>
        buddy_fail("nr_free after buddy merge");
    }

    // 3. allocate powers of two, check alignment and free-count accounting
    size_t reqs[4] = {1, 2, 4, 8};
ffffffffc0201686:	4789                	li	a5,2
ffffffffc0201688:	fc3e                	sd	a5,56(sp)
    struct Page *blocks[4] = {NULL, NULL, NULL, NULL};
ffffffffc020168a:	4d85                	li	s11,1
    size_t reqs[4] = {1, 2, 4, 8};
ffffffffc020168c:	4791                	li	a5,4
ffffffffc020168e:	e0be                	sd	a5,64(sp)
ffffffffc0201690:	05010993          	addi	s3,sp,80
ffffffffc0201694:	47a1                	li	a5,8
    size_t accounted = 0;
    for (unsigned int i = 0; i < 4; i++) {
        blocks[i] = buddy_pmm_manager.alloc_pages(reqs[i]);
ffffffffc0201696:	856e                	mv	a0,s11
    size_t reqs[4] = {1, 2, 4, 8};
ffffffffc0201698:	e4be                	sd	a5,72(sp)
    struct Page *blocks[4] = {NULL, NULL, NULL, NULL};
ffffffffc020169a:	8bce                	mv	s7,s3
ffffffffc020169c:	e882                	sd	zero,80(sp)
ffffffffc020169e:	ec82                	sd	zero,88(sp)
ffffffffc02016a0:	f082                	sd	zero,96(sp)
ffffffffc02016a2:	f482                	sd	zero,104(sp)
        blocks[i] = buddy_pmm_manager.alloc_pages(reqs[i]);
ffffffffc02016a4:	9902                	jalr	s2
ffffffffc02016a6:	03010a13          	addi	s4,sp,48
ffffffffc02016aa:	00abb023          	sd	a0,0(s7)
ffffffffc02016ae:	1880                	addi	s0,sp,112
    struct Page *blocks[4] = {NULL, NULL, NULL, NULL};
ffffffffc02016b0:	8c52                	mv	s8,s4
    size_t accounted = 0;
ffffffffc02016b2:	4a81                	li	s5,0
        blocks[i] = buddy_pmm_manager.alloc_pages(reqs[i]);
ffffffffc02016b4:	87aa                	mv	a5,a0
    for (unsigned int i = 0; i < 4; i++) {
ffffffffc02016b6:	0ba1                	addi	s7,s7,8
        if (blocks[i] == NULL) {
ffffffffc02016b8:	cd05                	beqz	a0,ffffffffc02016f0 <buddy_test+0x1d6>
ffffffffc02016ba:	000d3503          	ld	a0,0(s10)
ffffffffc02016be:	6742                	ld	a4,16(sp)
            buddy_fail("power-of-two allocation");
        }
        if (page2pa(blocks[i]) % (reqs[i] * PGSIZE) != 0) {
ffffffffc02016c0:	00cd9593          	slli	a1,s11,0xc
ffffffffc02016c4:	8f89                	sub	a5,a5,a0
ffffffffc02016c6:	878d                	srai	a5,a5,0x3
ffffffffc02016c8:	039787b3          	mul	a5,a5,s9
            buddy_fail("power-of-two block is misaligned");
        }
        accounted += reqs[i];
ffffffffc02016cc:	9aee                	add	s5,s5,s11
    for (unsigned int i = 0; i < 4; i++) {
ffffffffc02016ce:	0c21                	addi	s8,s8,8
ffffffffc02016d0:	97ba                	add	a5,a5,a4
    return page2ppn(page) << PGSHIFT;
ffffffffc02016d2:	07b2                	slli	a5,a5,0xc
        if (page2pa(blocks[i]) % (reqs[i] * PGSIZE) != 0) {
ffffffffc02016d4:	02b7f7b3          	remu	a5,a5,a1
ffffffffc02016d8:	eb8d                	bnez	a5,ffffffffc020170a <buddy_test+0x1f0>
    for (unsigned int i = 0; i < 4; i++) {
ffffffffc02016da:	05740463          	beq	s0,s7,ffffffffc0201722 <buddy_test+0x208>
        blocks[i] = buddy_pmm_manager.alloc_pages(reqs[i]);
ffffffffc02016de:	000c3d83          	ld	s11,0(s8) # ff0000 <kern_entry-0xffffffffbf210000>
    for (unsigned int i = 0; i < 4; i++) {
ffffffffc02016e2:	0ba1                	addi	s7,s7,8
        blocks[i] = buddy_pmm_manager.alloc_pages(reqs[i]);
ffffffffc02016e4:	856e                	mv	a0,s11
ffffffffc02016e6:	9902                	jalr	s2
ffffffffc02016e8:	feabbc23          	sd	a0,-8(s7)
ffffffffc02016ec:	87aa                	mv	a5,a0
        if (blocks[i] == NULL) {
ffffffffc02016ee:	f571                	bnez	a0,ffffffffc02016ba <buddy_test+0x1a0>
ffffffffc02016f0:	f42a                	sd	a0,40(sp)
    cprintf("[Buddy] FAIL: %s\n", msg);
ffffffffc02016f2:	00001597          	auipc	a1,0x1
ffffffffc02016f6:	77e58593          	addi	a1,a1,1918 # ffffffffc0202e70 <buddy_pmm_manager+0x160>
ffffffffc02016fa:	00001517          	auipc	a0,0x1
ffffffffc02016fe:	68e50513          	addi	a0,a0,1678 # ffffffffc0202d88 <buddy_pmm_manager+0x78>
ffffffffc0201702:	a53fe0ef          	jal	ra,ffffffffc0200154 <cprintf>
ffffffffc0201706:	77a2                	ld	a5,40(sp)
}
ffffffffc0201708:	bf4d                	j	ffffffffc02016ba <buddy_test+0x1a0>
    cprintf("[Buddy] FAIL: %s\n", msg);
ffffffffc020170a:	00001597          	auipc	a1,0x1
ffffffffc020170e:	77e58593          	addi	a1,a1,1918 # ffffffffc0202e88 <buddy_pmm_manager+0x178>
ffffffffc0201712:	00001517          	auipc	a0,0x1
ffffffffc0201716:	67650513          	addi	a0,a0,1654 # ffffffffc0202d88 <buddy_pmm_manager+0x78>
ffffffffc020171a:	a3bfe0ef          	jal	ra,ffffffffc0200154 <cprintf>
    for (unsigned int i = 0; i < 4; i++) {
ffffffffc020171e:	fd7410e3          	bne	s0,s7,ffffffffc02016de <buddy_test+0x1c4>
    }
    if (buddy_pmm_manager.nr_free_pages() != BUDDY_SUB_PAGES - accounted) {
ffffffffc0201722:	67a2                	ld	a5,8(sp)
ffffffffc0201724:	9782                	jalr	a5
ffffffffc0201726:	40000793          	li	a5,1024
ffffffffc020172a:	41578ab3          	sub	s5,a5,s5
ffffffffc020172e:	19551663          	bne	a0,s5,ffffffffc02018ba <buddy_test+0x3a0>
        buddy_fail("nr_free after power-of-two allocations");
    }
    for (unsigned int i = 0; i < 4; i++) {
        buddy_pmm_manager.free_pages(blocks[i], reqs[i]);
ffffffffc0201732:	0009b503          	ld	a0,0(s3)
    size_t accounted = 0;
ffffffffc0201736:	4585                	li	a1,1
    for (unsigned int i = 0; i < 4; i++) {
ffffffffc0201738:	09a1                	addi	s3,s3,8
        buddy_pmm_manager.free_pages(blocks[i], reqs[i]);
ffffffffc020173a:	9482                	jalr	s1
    for (unsigned int i = 0; i < 4; i++) {
ffffffffc020173c:	0a21                	addi	s4,s4,8
ffffffffc020173e:	01340b63          	beq	s0,s3,ffffffffc0201754 <buddy_test+0x23a>
        buddy_pmm_manager.free_pages(blocks[i], reqs[i]);
ffffffffc0201742:	000a3583          	ld	a1,0(s4)
ffffffffc0201746:	0009b503          	ld	a0,0(s3)
    for (unsigned int i = 0; i < 4; i++) {
ffffffffc020174a:	09a1                	addi	s3,s3,8
ffffffffc020174c:	0a21                	addi	s4,s4,8
        buddy_pmm_manager.free_pages(blocks[i], reqs[i]);
ffffffffc020174e:	9482                	jalr	s1
    for (unsigned int i = 0; i < 4; i++) {
ffffffffc0201750:	ff3419e3          	bne	s0,s3,ffffffffc0201742 <buddy_test+0x228>
    }
    if (buddy_pmm_manager.nr_free_pages() != BUDDY_SUB_PAGES) {
ffffffffc0201754:	67a2                	ld	a5,8(sp)
ffffffffc0201756:	9782                	jalr	a5
ffffffffc0201758:	40000793          	li	a5,1024
ffffffffc020175c:	14f51463          	bne	a0,a5,ffffffffc02018a4 <buddy_test+0x38a>
    buddy_rng_state = buddy_rng_state * 1103515245u + 12345u;
ffffffffc0201760:	41c65a37          	lui	s4,0x41c65
ffffffffc0201764:	698d                	lui	s3,0x3
ffffffffc0201766:	27010c13          	addi	s8,sp,624
ffffffffc020176a:	47010a93          	addi	s5,sp,1136
    size_t accounted = 0;
ffffffffc020176e:	8ca2                	mv	s9,s0
ffffffffc0201770:	00006d17          	auipc	s10,0x6
ffffffffc0201774:	8a0d0d13          	addi	s10,s10,-1888 # ffffffffc0207010 <buddy_rng_state>
    buddy_rng_state = buddy_rng_state * 1103515245u + 12345u;
ffffffffc0201778:	e6da0a1b          	addiw	s4,s4,-403
ffffffffc020177c:	0399899b          	addiw	s3,s3,57
ffffffffc0201780:	a019                	j	ffffffffc0201786 <buddy_test+0x26c>
    }

    // 4. random-sized alloc/free stress test
    struct Page *ptrs[BUDDY_STRESS_ALLOCS];
    size_t sizes[BUDDY_STRESS_ALLOCS];
    for (unsigned int i = 0; i < BUDDY_STRESS_ALLOCS; i++) {
ffffffffc0201782:	058a8063          	beq	s5,s8,ffffffffc02017c2 <buddy_test+0x2a8>
    buddy_rng_state = buddy_rng_state * 1103515245u + 12345u;
ffffffffc0201786:	000d2783          	lw	a5,0(s10)
    for (unsigned int i = 0; i < BUDDY_STRESS_ALLOCS; i++) {
ffffffffc020178a:	0c21                	addi	s8,s8,8
ffffffffc020178c:	0ca1                	addi	s9,s9,8
    buddy_rng_state = buddy_rng_state * 1103515245u + 12345u;
ffffffffc020178e:	034787bb          	mulw	a5,a5,s4
ffffffffc0201792:	013787bb          	addw	a5,a5,s3
    return buddy_rng_state >> 16;
ffffffffc0201796:	0107d51b          	srliw	a0,a5,0x10
        sizes[i] = 1 + (buddy_rand() % 8);
ffffffffc020179a:	891d                	andi	a0,a0,7
ffffffffc020179c:	0505                	addi	a0,a0,1
ffffffffc020179e:	feac3c23          	sd	a0,-8(s8)
    buddy_rng_state = buddy_rng_state * 1103515245u + 12345u;
ffffffffc02017a2:	00fd2023          	sw	a5,0(s10)
        ptrs[i] = buddy_pmm_manager.alloc_pages(sizes[i]);
ffffffffc02017a6:	9902                	jalr	s2
ffffffffc02017a8:	feacbc23          	sd	a0,-8(s9)
        if (ptrs[i] == NULL) {
ffffffffc02017ac:	f979                	bnez	a0,ffffffffc0201782 <buddy_test+0x268>
    cprintf("[Buddy] FAIL: %s\n", msg);
ffffffffc02017ae:	00001597          	auipc	a1,0x1
ffffffffc02017b2:	75a58593          	addi	a1,a1,1882 # ffffffffc0202f08 <buddy_pmm_manager+0x1f8>
ffffffffc02017b6:	00001517          	auipc	a0,0x1
ffffffffc02017ba:	5d250513          	addi	a0,a0,1490 # ffffffffc0202d88 <buddy_pmm_manager+0x78>
ffffffffc02017be:	997fe0ef          	jal	ra,ffffffffc0200154 <cprintf>
ffffffffc02017c2:	26810913          	addi	s2,sp,616
ffffffffc02017c6:	46810993          	addi	s3,sp,1128
            buddy_fail("stress allocation");
            break;
        }
    }
    for (int i = BUDDY_STRESS_ALLOCS - 1; i >= 0; i--) {
        buddy_pmm_manager.free_pages(ptrs[i], sizes[i]);
ffffffffc02017ca:	0009b583          	ld	a1,0(s3) # 3000 <kern_entry-0xffffffffc01fd000>
ffffffffc02017ce:	00093503          	ld	a0,0(s2)
    for (int i = BUDDY_STRESS_ALLOCS - 1; i >= 0; i--) {
ffffffffc02017d2:	19e1                	addi	s3,s3,-8
        buddy_pmm_manager.free_pages(ptrs[i], sizes[i]);
ffffffffc02017d4:	9482                	jalr	s1
    for (int i = BUDDY_STRESS_ALLOCS - 1; i >= 0; i--) {
ffffffffc02017d6:	87ca                	mv	a5,s2
ffffffffc02017d8:	1961                	addi	s2,s2,-8
ffffffffc02017da:	fef418e3          	bne	s0,a5,ffffffffc02017ca <buddy_test+0x2b0>
    }
    if (buddy_pmm_manager.nr_free_pages() != BUDDY_SUB_PAGES) {
ffffffffc02017de:	67a2                	ld	a5,8(sp)
ffffffffc02017e0:	9782                	jalr	a5
ffffffffc02017e2:	40000793          	li	a5,1024
ffffffffc02017e6:	0af51463          	bne	a0,a5,ffffffffc020188e <buddy_test+0x374>
        buddy_fail("nr_free after stress test");
    }
    buddy_pmm_manager.check();
ffffffffc02017ea:	7782                	ld	a5,32(sp)
ffffffffc02017ec:	9782                	jalr	a5

    // Hand every borrowed page back to the active allocator.
    for (size_t i = 0; i < BUDDY_POOL_PAGES; i++) {
ffffffffc02017ee:	6751                	lui	a4,0x14
ffffffffc02017f0:	87da                	mv	a5,s6
ffffffffc02017f2:	975a                	add	a4,a4,s6
        pool[i].flags = 0;
ffffffffc02017f4:	0007b423          	sd	zero,8(a5)
        pool[i].property = 0;
ffffffffc02017f8:	0007a823          	sw	zero,16(a5)
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc02017fc:	0007a023          	sw	zero,0(a5)
    for (size_t i = 0; i < BUDDY_POOL_PAGES; i++) {
ffffffffc0201800:	02878793          	addi	a5,a5,40
ffffffffc0201804:	fef718e3          	bne	a4,a5,ffffffffc02017f4 <buddy_test+0x2da>
        set_page_ref(pool + i, 0);
    }
    free_pages(pool, BUDDY_POOL_PAGES);
ffffffffc0201808:	6585                	lui	a1,0x1
ffffffffc020180a:	80058593          	addi	a1,a1,-2048 # 800 <kern_entry-0xffffffffc01ff800>
ffffffffc020180e:	855a                	mv	a0,s6
ffffffffc0201810:	144000ef          	jal	ra,ffffffffc0201954 <free_pages>

    if (nr_free_pages() != before) {
ffffffffc0201814:	14c000ef          	jal	ra,ffffffffc0201960 <nr_free_pages>
ffffffffc0201818:	67e2                	ld	a5,24(sp)
ffffffffc020181a:	04f51f63          	bne	a0,a5,ffffffffc0201878 <buddy_test+0x35e>
        buddy_fail("active allocator page count changed");
    }
    cprintf("[Buddy] tests PASS\n");
}
ffffffffc020181e:	4d013403          	ld	s0,1232(sp)
ffffffffc0201822:	4d813083          	ld	ra,1240(sp)
ffffffffc0201826:	4c813483          	ld	s1,1224(sp)
ffffffffc020182a:	4c013903          	ld	s2,1216(sp)
ffffffffc020182e:	4b813983          	ld	s3,1208(sp)
ffffffffc0201832:	4b013a03          	ld	s4,1200(sp)
ffffffffc0201836:	4a813a83          	ld	s5,1192(sp)
ffffffffc020183a:	4a013b03          	ld	s6,1184(sp)
ffffffffc020183e:	49813b83          	ld	s7,1176(sp)
ffffffffc0201842:	49013c03          	ld	s8,1168(sp)
ffffffffc0201846:	48813c83          	ld	s9,1160(sp)
ffffffffc020184a:	48013d03          	ld	s10,1152(sp)
ffffffffc020184e:	47813d83          	ld	s11,1144(sp)
    cprintf("[Buddy] tests PASS\n");
ffffffffc0201852:	00001517          	auipc	a0,0x1
ffffffffc0201856:	71650513          	addi	a0,a0,1814 # ffffffffc0202f68 <buddy_pmm_manager+0x258>
}
ffffffffc020185a:	4e010113          	addi	sp,sp,1248
    cprintf("[Buddy] tests PASS\n");
ffffffffc020185e:	8f7fe06f          	j	ffffffffc0200154 <cprintf>
    cprintf("[Buddy] FAIL: %s\n", msg);
ffffffffc0201862:	00001597          	auipc	a1,0x1
ffffffffc0201866:	53e58593          	addi	a1,a1,1342 # ffffffffc0202da0 <buddy_pmm_manager+0x90>
ffffffffc020186a:	00001517          	auipc	a0,0x1
ffffffffc020186e:	51e50513          	addi	a0,a0,1310 # ffffffffc0202d88 <buddy_pmm_manager+0x78>
ffffffffc0201872:	8e3fe0ef          	jal	ra,ffffffffc0200154 <cprintf>
}
ffffffffc0201876:	bbb5                	j	ffffffffc02015f2 <buddy_test+0xd8>
    cprintf("[Buddy] FAIL: %s\n", msg);
ffffffffc0201878:	00001597          	auipc	a1,0x1
ffffffffc020187c:	6c858593          	addi	a1,a1,1736 # ffffffffc0202f40 <buddy_pmm_manager+0x230>
ffffffffc0201880:	00001517          	auipc	a0,0x1
ffffffffc0201884:	50850513          	addi	a0,a0,1288 # ffffffffc0202d88 <buddy_pmm_manager+0x78>
ffffffffc0201888:	8cdfe0ef          	jal	ra,ffffffffc0200154 <cprintf>
}
ffffffffc020188c:	bf49                	j	ffffffffc020181e <buddy_test+0x304>
    cprintf("[Buddy] FAIL: %s\n", msg);
ffffffffc020188e:	00001597          	auipc	a1,0x1
ffffffffc0201892:	69258593          	addi	a1,a1,1682 # ffffffffc0202f20 <buddy_pmm_manager+0x210>
ffffffffc0201896:	00001517          	auipc	a0,0x1
ffffffffc020189a:	4f250513          	addi	a0,a0,1266 # ffffffffc0202d88 <buddy_pmm_manager+0x78>
ffffffffc020189e:	8b7fe0ef          	jal	ra,ffffffffc0200154 <cprintf>
}
ffffffffc02018a2:	b7a1                	j	ffffffffc02017ea <buddy_test+0x2d0>
    cprintf("[Buddy] FAIL: %s\n", msg);
ffffffffc02018a4:	00001597          	auipc	a1,0x1
ffffffffc02018a8:	63458593          	addi	a1,a1,1588 # ffffffffc0202ed8 <buddy_pmm_manager+0x1c8>
ffffffffc02018ac:	00001517          	auipc	a0,0x1
ffffffffc02018b0:	4dc50513          	addi	a0,a0,1244 # ffffffffc0202d88 <buddy_pmm_manager+0x78>
ffffffffc02018b4:	8a1fe0ef          	jal	ra,ffffffffc0200154 <cprintf>
}
ffffffffc02018b8:	b565                	j	ffffffffc0201760 <buddy_test+0x246>
    cprintf("[Buddy] FAIL: %s\n", msg);
ffffffffc02018ba:	00001597          	auipc	a1,0x1
ffffffffc02018be:	5f658593          	addi	a1,a1,1526 # ffffffffc0202eb0 <buddy_pmm_manager+0x1a0>
ffffffffc02018c2:	00001517          	auipc	a0,0x1
ffffffffc02018c6:	4c650513          	addi	a0,a0,1222 # ffffffffc0202d88 <buddy_pmm_manager+0x78>
ffffffffc02018ca:	88bfe0ef          	jal	ra,ffffffffc0200154 <cprintf>
}
ffffffffc02018ce:	b595                	j	ffffffffc0201732 <buddy_test+0x218>
    cprintf("[Buddy] FAIL: %s\n", msg);
ffffffffc02018d0:	00001597          	auipc	a1,0x1
ffffffffc02018d4:	58058593          	addi	a1,a1,1408 # ffffffffc0202e50 <buddy_pmm_manager+0x140>
ffffffffc02018d8:	00001517          	auipc	a0,0x1
ffffffffc02018dc:	4b050513          	addi	a0,a0,1200 # ffffffffc0202d88 <buddy_pmm_manager+0x78>
ffffffffc02018e0:	875fe0ef          	jal	ra,ffffffffc0200154 <cprintf>
}
ffffffffc02018e4:	b34d                	j	ffffffffc0201686 <buddy_test+0x16c>
    cprintf("[Buddy] FAIL: %s\n", msg);
ffffffffc02018e6:	00001597          	auipc	a1,0x1
ffffffffc02018ea:	4f258593          	addi	a1,a1,1266 # ffffffffc0202dd8 <buddy_pmm_manager+0xc8>
ffffffffc02018ee:	00001517          	auipc	a0,0x1
ffffffffc02018f2:	49a50513          	addi	a0,a0,1178 # ffffffffc0202d88 <buddy_pmm_manager+0x78>
ffffffffc02018f6:	85ffe0ef          	jal	ra,ffffffffc0200154 <cprintf>
}
ffffffffc02018fa:	bb0d                	j	ffffffffc020162c <buddy_test+0x112>
}
ffffffffc02018fc:	4d013403          	ld	s0,1232(sp)
ffffffffc0201900:	4d813083          	ld	ra,1240(sp)
ffffffffc0201904:	4c813483          	ld	s1,1224(sp)
ffffffffc0201908:	4c013903          	ld	s2,1216(sp)
ffffffffc020190c:	4b813983          	ld	s3,1208(sp)
ffffffffc0201910:	4b013a03          	ld	s4,1200(sp)
ffffffffc0201914:	4a813a83          	ld	s5,1192(sp)
ffffffffc0201918:	4a013b03          	ld	s6,1184(sp)
ffffffffc020191c:	49813b83          	ld	s7,1176(sp)
ffffffffc0201920:	49013c03          	ld	s8,1168(sp)
ffffffffc0201924:	48813c83          	ld	s9,1160(sp)
ffffffffc0201928:	48013d03          	ld	s10,1152(sp)
ffffffffc020192c:	47813d83          	ld	s11,1144(sp)
    cprintf("[Buddy] FAIL: %s\n", msg);
ffffffffc0201930:	00001597          	auipc	a1,0x1
ffffffffc0201934:	43058593          	addi	a1,a1,1072 # ffffffffc0202d60 <buddy_pmm_manager+0x50>
ffffffffc0201938:	00001517          	auipc	a0,0x1
ffffffffc020193c:	45050513          	addi	a0,a0,1104 # ffffffffc0202d88 <buddy_pmm_manager+0x78>
}
ffffffffc0201940:	4e010113          	addi	sp,sp,1248
    cprintf("[Buddy] FAIL: %s\n", msg);
ffffffffc0201944:	811fe06f          	j	ffffffffc0200154 <cprintf>

ffffffffc0201948 <alloc_pages>:
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
    return pmm_manager->alloc_pages(n);
ffffffffc0201948:	00006797          	auipc	a5,0x6
ffffffffc020194c:	a207b783          	ld	a5,-1504(a5) # ffffffffc0207368 <pmm_manager>
ffffffffc0201950:	6f9c                	ld	a5,24(a5)
ffffffffc0201952:	8782                	jr	a5

ffffffffc0201954 <free_pages>:
}

// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    pmm_manager->free_pages(base, n);
ffffffffc0201954:	00006797          	auipc	a5,0x6
ffffffffc0201958:	a147b783          	ld	a5,-1516(a5) # ffffffffc0207368 <pmm_manager>
ffffffffc020195c:	739c                	ld	a5,32(a5)
ffffffffc020195e:	8782                	jr	a5

ffffffffc0201960 <nr_free_pages>:
}

// nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE)
// of current free memory
size_t nr_free_pages(void) {
    return pmm_manager->nr_free_pages();
ffffffffc0201960:	00006797          	auipc	a5,0x6
ffffffffc0201964:	a087b783          	ld	a5,-1528(a5) # ffffffffc0207368 <pmm_manager>
ffffffffc0201968:	779c                	ld	a5,40(a5)
ffffffffc020196a:	8782                	jr	a5

ffffffffc020196c <pmm_init>:
    pmm_manager = &best_fit_pmm_manager;
ffffffffc020196c:	00001797          	auipc	a5,0x1
ffffffffc0201970:	2e478793          	addi	a5,a5,740 # ffffffffc0202c50 <best_fit_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201974:	638c                	ld	a1,0(a5)
    free_n = (mem_end - freemem) / PGSIZE;
    init_memmap(pa2page(freemem), free_n);
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0201976:	7139                	addi	sp,sp,-64
ffffffffc0201978:	f822                	sd	s0,48(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020197a:	00001517          	auipc	a0,0x1
ffffffffc020197e:	60650513          	addi	a0,a0,1542 # ffffffffc0202f80 <buddy_pmm_manager+0x270>
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0201982:	00006417          	auipc	s0,0x6
ffffffffc0201986:	9e640413          	addi	s0,s0,-1562 # ffffffffc0207368 <pmm_manager>
void pmm_init(void) {
ffffffffc020198a:	fc06                	sd	ra,56(sp)
ffffffffc020198c:	f426                	sd	s1,40(sp)
ffffffffc020198e:	ec4e                	sd	s3,24(sp)
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0201990:	e01c                	sd	a5,0(s0)
void pmm_init(void) {
ffffffffc0201992:	f04a                	sd	s2,32(sp)
ffffffffc0201994:	e852                	sd	s4,16(sp)
ffffffffc0201996:	e456                	sd	s5,8(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201998:	fbcfe0ef          	jal	ra,ffffffffc0200154 <cprintf>
    pmm_manager->init();
ffffffffc020199c:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc020199e:	00006497          	auipc	s1,0x6
ffffffffc02019a2:	9e248493          	addi	s1,s1,-1566 # ffffffffc0207380 <va_pa_offset>
    pmm_manager->init();
ffffffffc02019a6:	679c                	ld	a5,8(a5)
ffffffffc02019a8:	9782                	jalr	a5
    uint64_t mem_base = get_memory_base();
ffffffffc02019aa:	c1bfe0ef          	jal	ra,ffffffffc02005c4 <get_memory_base>
ffffffffc02019ae:	89aa                	mv	s3,a0
    uint64_t mem_size = get_memory_size();
ffffffffc02019b0:	c1ffe0ef          	jal	ra,ffffffffc02005ce <get_memory_size>
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02019b4:	57f5                	li	a5,-3
ffffffffc02019b6:	07fa                	slli	a5,a5,0x1e
ffffffffc02019b8:	e09c                	sd	a5,0(s1)
    uint64_t mem_size = get_memory_size();
ffffffffc02019ba:	862a                	mv	a2,a0
    if (mem_base == 0 || mem_size == 0) {
ffffffffc02019bc:	12098463          	beqz	s3,ffffffffc0201ae4 <pmm_init+0x178>
ffffffffc02019c0:	12050263          	beqz	a0,ffffffffc0201ae4 <pmm_init+0x178>
    mem_end = mem_base + mem_size;
ffffffffc02019c4:	00a98933          	add	s2,s3,a0
    npage = PPN(mem_end);
ffffffffc02019c8:	00c95693          	srli	a3,s2,0xc
ffffffffc02019cc:	00006a17          	auipc	s4,0x6
ffffffffc02019d0:	98ca0a13          	addi	s4,s4,-1652 # ffffffffc0207358 <npage>
ffffffffc02019d4:	00da3023          	sd	a3,0(s4)
    if (npage <= nbase) {
ffffffffc02019d8:	000807b7          	lui	a5,0x80
ffffffffc02019dc:	12d7ff63          	bgeu	a5,a3,ffffffffc0201b1a <pmm_init+0x1ae>
    pages = (struct Page *)ROUNDUP((uintptr_t)end, PGSIZE);
ffffffffc02019e0:	777d                	lui	a4,0xfffff
ffffffffc02019e2:	00269813          	slli	a6,a3,0x2
ffffffffc02019e6:	00007797          	auipc	a5,0x7
ffffffffc02019ea:	9a178793          	addi	a5,a5,-1631 # ffffffffc0208387 <end+0xfff>
ffffffffc02019ee:	8ff9                	and	a5,a5,a4
ffffffffc02019f0:	9836                	add	a6,a6,a3
ffffffffc02019f2:	fec00737          	lui	a4,0xfec00
ffffffffc02019f6:	080e                	slli	a6,a6,0x3
ffffffffc02019f8:	00006a97          	auipc	s5,0x6
ffffffffc02019fc:	968a8a93          	addi	s5,s5,-1688 # ffffffffc0207360 <pages>
ffffffffc0201a00:	973e                	add	a4,a4,a5
ffffffffc0201a02:	9742                	add	a4,a4,a6
ffffffffc0201a04:	00fab023          	sd	a5,0(s5)
        SetPageReserved(&pages[i]);
ffffffffc0201a08:	4805                	li	a6,1
        pages[i].ref = 0;
ffffffffc0201a0a:	0007a023          	sw	zero,0(a5)
        pages[i].property = 0;
ffffffffc0201a0e:	0007a823          	sw	zero,16(a5)
        SetPageReserved(&pages[i]);
ffffffffc0201a12:	0107b423          	sd	a6,8(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201a16:	02878793          	addi	a5,a5,40
ffffffffc0201a1a:	fee798e3          	bne	a5,a4,ffffffffc0201a0a <pmm_init+0x9e>
    cprintf("Physical memory: base=0x%016lx size=0x%016lx "
ffffffffc0201a1e:	8736                	mv	a4,a3
ffffffffc0201a20:	85ce                	mv	a1,s3
ffffffffc0201a22:	86ca                	mv	a3,s2
ffffffffc0201a24:	00001517          	auipc	a0,0x1
ffffffffc0201a28:	60c50513          	addi	a0,a0,1548 # ffffffffc0203030 <buddy_pmm_manager+0x320>
ffffffffc0201a2c:	f28fe0ef          	jal	ra,ffffffffc0200154 <cprintf>
    freemem = PADDR((uintptr_t)pages) +
ffffffffc0201a30:	000ab503          	ld	a0,0(s5)
ffffffffc0201a34:	c02007b7          	lui	a5,0xc0200
ffffffffc0201a38:	0cf56463          	bltu	a0,a5,ffffffffc0201b00 <pmm_init+0x194>
ffffffffc0201a3c:	000a3683          	ld	a3,0(s4)
ffffffffc0201a40:	609c                	ld	a5,0(s1)
    freemem = ROUNDUP(freemem, PGSIZE);
ffffffffc0201a42:	fec01637          	lui	a2,0xfec01
    freemem = PADDR((uintptr_t)pages) +
ffffffffc0201a46:	00269713          	slli	a4,a3,0x2
ffffffffc0201a4a:	40f507b3          	sub	a5,a0,a5
ffffffffc0201a4e:	9736                	add	a4,a4,a3
    freemem = ROUNDUP(freemem, PGSIZE);
ffffffffc0201a50:	167d                	addi	a2,a2,-1
    freemem = PADDR((uintptr_t)pages) +
ffffffffc0201a52:	070e                	slli	a4,a4,0x3
    freemem = ROUNDUP(freemem, PGSIZE);
ffffffffc0201a54:	97b2                	add	a5,a5,a2
ffffffffc0201a56:	97ba                	add	a5,a5,a4
ffffffffc0201a58:	777d                	lui	a4,0xfffff
ffffffffc0201a5a:	8ff9                	and	a5,a5,a4
    if (freemem >= mem_end) {
ffffffffc0201a5c:	0727fd63          	bgeu	a5,s2,ffffffffc0201ad6 <pmm_init+0x16a>
    free_n = (mem_end - freemem) / PGSIZE;
ffffffffc0201a60:	40f905b3          	sub	a1,s2,a5
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0201a64:	83b1                	srli	a5,a5,0xc
ffffffffc0201a66:	81b1                	srli	a1,a1,0xc
ffffffffc0201a68:	0ed7f463          	bgeu	a5,a3,ffffffffc0201b50 <pmm_init+0x1e4>
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc0201a6c:	fff80737          	lui	a4,0xfff80
    pmm_manager->init_memmap(base, n);
ffffffffc0201a70:	6014                	ld	a3,0(s0)
ffffffffc0201a72:	97ba                	add	a5,a5,a4
ffffffffc0201a74:	00279713          	slli	a4,a5,0x2
ffffffffc0201a78:	97ba                	add	a5,a5,a4
ffffffffc0201a7a:	6a98                	ld	a4,16(a3)
ffffffffc0201a7c:	078e                	slli	a5,a5,0x3
ffffffffc0201a7e:	953e                	add	a0,a0,a5
ffffffffc0201a80:	9702                	jalr	a4
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0201a82:	601c                	ld	a5,0(s0)
ffffffffc0201a84:	7b9c                	ld	a5,48(a5)
ffffffffc0201a86:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0201a88:	00001517          	auipc	a0,0x1
ffffffffc0201a8c:	68850513          	addi	a0,a0,1672 # ffffffffc0203110 <buddy_pmm_manager+0x400>
ffffffffc0201a90:	ec4fe0ef          	jal	ra,ffffffffc0200154 <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc0201a94:	00004597          	auipc	a1,0x4
ffffffffc0201a98:	56c58593          	addi	a1,a1,1388 # ffffffffc0206000 <boot_page_table_sv39>
ffffffffc0201a9c:	00006797          	auipc	a5,0x6
ffffffffc0201aa0:	8cb7be23          	sd	a1,-1828(a5) # ffffffffc0207378 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201aa4:	c02007b7          	lui	a5,0xc0200
ffffffffc0201aa8:	08f5e763          	bltu	a1,a5,ffffffffc0201b36 <pmm_init+0x1ca>
ffffffffc0201aac:	6090                	ld	a2,0(s1)
}
ffffffffc0201aae:	7442                	ld	s0,48(sp)
ffffffffc0201ab0:	70e2                	ld	ra,56(sp)
ffffffffc0201ab2:	74a2                	ld	s1,40(sp)
ffffffffc0201ab4:	7902                	ld	s2,32(sp)
ffffffffc0201ab6:	69e2                	ld	s3,24(sp)
ffffffffc0201ab8:	6a42                	ld	s4,16(sp)
ffffffffc0201aba:	6aa2                	ld	s5,8(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc0201abc:	40c58633          	sub	a2,a1,a2
ffffffffc0201ac0:	00006797          	auipc	a5,0x6
ffffffffc0201ac4:	8ac7b823          	sd	a2,-1872(a5) # ffffffffc0207370 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201ac8:	00001517          	auipc	a0,0x1
ffffffffc0201acc:	66850513          	addi	a0,a0,1640 # ffffffffc0203130 <buddy_pmm_manager+0x420>
}
ffffffffc0201ad0:	6121                	addi	sp,sp,64
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201ad2:	e82fe06f          	j	ffffffffc0200154 <cprintf>
        cprintf("page_init: no complete free pages after kernel and pages[]\n");
ffffffffc0201ad6:	00001517          	auipc	a0,0x1
ffffffffc0201ada:	5ca50513          	addi	a0,a0,1482 # ffffffffc02030a0 <buddy_pmm_manager+0x390>
ffffffffc0201ade:	e76fe0ef          	jal	ra,ffffffffc0200154 <cprintf>
        return;
ffffffffc0201ae2:	b745                	j	ffffffffc0201a82 <pmm_init+0x116>
        panic("page_init: invalid memory range from DTB "
ffffffffc0201ae4:	8732                	mv	a4,a2
ffffffffc0201ae6:	86ce                	mv	a3,s3
ffffffffc0201ae8:	00001617          	auipc	a2,0x1
ffffffffc0201aec:	4b060613          	addi	a2,a2,1200 # ffffffffc0202f98 <buddy_pmm_manager+0x288>
ffffffffc0201af0:	04e00593          	li	a1,78
ffffffffc0201af4:	00001517          	auipc	a0,0x1
ffffffffc0201af8:	4ec50513          	addi	a0,a0,1260 # ffffffffc0202fe0 <buddy_pmm_manager+0x2d0>
ffffffffc0201afc:	ecefe0ef          	jal	ra,ffffffffc02001ca <__panic>
    freemem = PADDR((uintptr_t)pages) +
ffffffffc0201b00:	86aa                	mv	a3,a0
ffffffffc0201b02:	00001617          	auipc	a2,0x1
ffffffffc0201b06:	57660613          	addi	a2,a2,1398 # ffffffffc0203078 <buddy_pmm_manager+0x368>
ffffffffc0201b0a:	06c00593          	li	a1,108
ffffffffc0201b0e:	00001517          	auipc	a0,0x1
ffffffffc0201b12:	4d250513          	addi	a0,a0,1234 # ffffffffc0202fe0 <buddy_pmm_manager+0x2d0>
ffffffffc0201b16:	eb4fe0ef          	jal	ra,ffffffffc02001ca <__panic>
        panic("page_init: physical memory too small "
ffffffffc0201b1a:	00080737          	lui	a4,0x80
ffffffffc0201b1e:	00001617          	auipc	a2,0x1
ffffffffc0201b22:	4d260613          	addi	a2,a2,1234 # ffffffffc0202ff0 <buddy_pmm_manager+0x2e0>
ffffffffc0201b26:	05600593          	li	a1,86
ffffffffc0201b2a:	00001517          	auipc	a0,0x1
ffffffffc0201b2e:	4b650513          	addi	a0,a0,1206 # ffffffffc0202fe0 <buddy_pmm_manager+0x2d0>
ffffffffc0201b32:	e98fe0ef          	jal	ra,ffffffffc02001ca <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201b36:	86ae                	mv	a3,a1
ffffffffc0201b38:	00001617          	auipc	a2,0x1
ffffffffc0201b3c:	54060613          	addi	a2,a2,1344 # ffffffffc0203078 <buddy_pmm_manager+0x368>
ffffffffc0201b40:	08b00593          	li	a1,139
ffffffffc0201b44:	00001517          	auipc	a0,0x1
ffffffffc0201b48:	49c50513          	addi	a0,a0,1180 # ffffffffc0202fe0 <buddy_pmm_manager+0x2d0>
ffffffffc0201b4c:	e7efe0ef          	jal	ra,ffffffffc02001ca <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0201b50:	00001617          	auipc	a2,0x1
ffffffffc0201b54:	59060613          	addi	a2,a2,1424 # ffffffffc02030e0 <buddy_pmm_manager+0x3d0>
ffffffffc0201b58:	06a00593          	li	a1,106
ffffffffc0201b5c:	00001517          	auipc	a0,0x1
ffffffffc0201b60:	5a450513          	addi	a0,a0,1444 # ffffffffc0203100 <buddy_pmm_manager+0x3f0>
ffffffffc0201b64:	e66fe0ef          	jal	ra,ffffffffc02001ca <__panic>

ffffffffc0201b68 <slub_init>:
void
slub_init(void) {
    for (unsigned int i = 0; i < SLUB_CACHE_COUNT; i++) {
        caches[i].objsize = SLUB_MIN_OBJSIZE << i;
        caches[i].objs_per_slab =
            (PGSIZE - sizeof(struct slab)) / caches[i].objsize;
ffffffffc0201b68:	6505                	lui	a0,0x1
ffffffffc0201b6a:	00005797          	auipc	a5,0x5
ffffffffc0201b6e:	62e78793          	addi	a5,a5,1582 # ffffffffc0207198 <caches+0x10>
    for (unsigned int i = 0; i < SLUB_CACHE_COUNT; i++) {
ffffffffc0201b72:	4701                	li	a4,0
        caches[i].objsize = SLUB_MIN_OBJSIZE << i;
ffffffffc0201b74:	48a1                	li	a7,8
            (PGSIZE - sizeof(struct slab)) / caches[i].objsize;
ffffffffc0201b76:	fd050513          	addi	a0,a0,-48 # fd0 <kern_entry-0xffffffffc01ff030>
    for (unsigned int i = 0; i < SLUB_CACHE_COUNT; i++) {
ffffffffc0201b7a:	4825                	li	a6,9
        caches[i].objsize = SLUB_MIN_OBJSIZE << i;
ffffffffc0201b7c:	00e8963b          	sllw	a2,a7,a4
            (PGSIZE - sizeof(struct slab)) / caches[i].objsize;
ffffffffc0201b80:	02c555b3          	divu	a1,a0,a2
ffffffffc0201b84:	01078693          	addi	a3,a5,16
        caches[i].objsize = SLUB_MIN_OBJSIZE << i;
ffffffffc0201b88:	fec7b823          	sd	a2,-16(a5)
    elm->prev = elm->next = elm;
ffffffffc0201b8c:	e79c                	sd	a5,8(a5)
ffffffffc0201b8e:	e39c                	sd	a5,0(a5)
ffffffffc0201b90:	ef94                	sd	a3,24(a5)
ffffffffc0201b92:	eb94                	sd	a3,16(a5)
    for (unsigned int i = 0; i < SLUB_CACHE_COUNT; i++) {
ffffffffc0201b94:	2705                	addiw	a4,a4,1
ffffffffc0201b96:	03078793          	addi	a5,a5,48
        caches[i].objs_per_slab =
ffffffffc0201b9a:	fcb7a423          	sw	a1,-56(a5)
    for (unsigned int i = 0; i < SLUB_CACHE_COUNT; i++) {
ffffffffc0201b9e:	fd071fe3          	bne	a4,a6,ffffffffc0201b7c <slub_init+0x14>
        list_init(&caches[i].slabs_partial);
        list_init(&caches[i].slabs_full);
    }
}
ffffffffc0201ba2:	8082                	ret

ffffffffc0201ba4 <kmalloc>:
    return slab;
}

void *
kmalloc(size_t size) {
    if (size == 0) {
ffffffffc0201ba4:	1c050c63          	beqz	a0,ffffffffc0201d7c <kmalloc+0x1d8>
kmalloc(size_t size) {
ffffffffc0201ba8:	7179                	addi	sp,sp,-48
        return NULL;
    }

    // Large objects: allocate whole pages and store bookkeeping in a header.
    if (size > SLUB_MAX_CACHE_OBJSIZE) {
ffffffffc0201baa:	6785                	lui	a5,0x1
kmalloc(size_t size) {
ffffffffc0201bac:	f022                	sd	s0,32(sp)
ffffffffc0201bae:	f406                	sd	ra,40(sp)
ffffffffc0201bb0:	ec26                	sd	s1,24(sp)
ffffffffc0201bb2:	e84a                	sd	s2,16(sp)
ffffffffc0201bb4:	e44e                	sd	s3,8(sp)
ffffffffc0201bb6:	e052                	sd	s4,0(sp)
    if (size > SLUB_MAX_CACHE_OBJSIZE) {
ffffffffc0201bb8:	80078713          	addi	a4,a5,-2048 # 800 <kern_entry-0xffffffffc01ff800>
ffffffffc0201bbc:	842a                	mv	s0,a0
ffffffffc0201bbe:	08a76b63          	bltu	a4,a0,ffffffffc0201c54 <kmalloc+0xb0>
    while (objsize < size) {
ffffffffc0201bc2:	46a1                	li	a3,8
    unsigned int idx = 0;
ffffffffc0201bc4:	4701                	li	a4,0
    size_t objsize = SLUB_MIN_OBJSIZE;
ffffffffc0201bc6:	47a1                	li	a5,8
    while (objsize < size) {
ffffffffc0201bc8:	0ea6f563          	bgeu	a3,a0,ffffffffc0201cb2 <kmalloc+0x10e>
        objsize <<= 1;
ffffffffc0201bcc:	0786                	slli	a5,a5,0x1
        idx++;
ffffffffc0201bce:	2705                	addiw	a4,a4,1
    while (objsize < size) {
ffffffffc0201bd0:	fe87eee3          	bltu	a5,s0,ffffffffc0201bcc <kmalloc+0x28>
ffffffffc0201bd4:	02071493          	slli	s1,a4,0x20
ffffffffc0201bd8:	9081                	srli	s1,s1,0x20
ffffffffc0201bda:	00149413          	slli	s0,s1,0x1
ffffffffc0201bde:	9426                	add	s0,s0,s1
ffffffffc0201be0:	0412                	slli	s0,s0,0x4
    return &caches[idx];
ffffffffc0201be2:	00005917          	auipc	s2,0x5
ffffffffc0201be6:	5a690913          	addi	s2,s2,1446 # ffffffffc0207188 <caches>
ffffffffc0201bea:	01040a13          	addi	s4,s0,16
ffffffffc0201bee:	008909b3          	add	s3,s2,s0
    return list->next == list;
ffffffffc0201bf2:	0189b783          	ld	a5,24(s3)
ffffffffc0201bf6:	02071493          	slli	s1,a4,0x20
        head->pages = pages;
        return (void *)(head + 1);
    }

    struct kmem_cache *cache = slub_cache_for(size);
    if (list_empty(&cache->slabs_partial)) {
ffffffffc0201bfa:	9a4a                	add	s4,s4,s2
ffffffffc0201bfc:	9081                	srli	s1,s1,0x20
ffffffffc0201bfe:	0cfa0b63          	beq	s4,a5,ffffffffc0201cd4 <kmalloc+0x130>
        }
    }

    struct slab *slab =
        le2slab(list_next(&cache->slabs_partial), link);
    void *obj = slab->freelist;
ffffffffc0201c02:	ff07b503          	ld	a0,-16(a5)
    slab->freelist = *(void **)obj;
    slab->inuse++;

    if (slab->inuse == cache->objs_per_slab) {
ffffffffc0201c06:	00149713          	slli	a4,s1,0x1
ffffffffc0201c0a:	9726                	add	a4,a4,s1
    slab->inuse++;
ffffffffc0201c0c:	ff87a683          	lw	a3,-8(a5)
    if (slab->inuse == cache->objs_per_slab) {
ffffffffc0201c10:	0712                	slli	a4,a4,0x4
    slab->freelist = *(void **)obj;
ffffffffc0201c12:	610c                	ld	a1,0(a0)
    if (slab->inuse == cache->objs_per_slab) {
ffffffffc0201c14:	974a                	add	a4,a4,s2
ffffffffc0201c16:	4710                	lw	a2,8(a4)
    slab->inuse++;
ffffffffc0201c18:	2685                	addiw	a3,a3,1
    slab->freelist = *(void **)obj;
ffffffffc0201c1a:	feb7b823          	sd	a1,-16(a5)
    slab->inuse++;
ffffffffc0201c1e:	fed7ac23          	sw	a3,-8(a5)
    if (slab->inuse == cache->objs_per_slab) {
ffffffffc0201c22:	02d61163          	bne	a2,a3,ffffffffc0201c44 <kmalloc+0xa0>
    __list_del(listelm->prev, listelm->next);
ffffffffc0201c26:	6390                	ld	a2,0(a5)
ffffffffc0201c28:	6794                	ld	a3,8(a5)
        list_del(&(slab->link));
        list_add(&cache->slabs_full, &(slab->link));
ffffffffc0201c2a:	02040413          	addi	s0,s0,32
ffffffffc0201c2e:	9922                	add	s2,s2,s0
    prev->next = next;
ffffffffc0201c30:	e614                	sd	a3,8(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc0201c32:	0289b703          	ld	a4,40(s3)
    next->prev = prev;
ffffffffc0201c36:	e290                	sd	a2,0(a3)
    prev->next = next->prev = elm;
ffffffffc0201c38:	e31c                	sd	a5,0(a4)
ffffffffc0201c3a:	02f9b423          	sd	a5,40(s3)
    elm->next = next;
ffffffffc0201c3e:	e798                	sd	a4,8(a5)
    elm->prev = prev;
ffffffffc0201c40:	0127b023          	sd	s2,0(a5)
    }
    return obj;
}
ffffffffc0201c44:	70a2                	ld	ra,40(sp)
ffffffffc0201c46:	7402                	ld	s0,32(sp)
ffffffffc0201c48:	64e2                	ld	s1,24(sp)
ffffffffc0201c4a:	6942                	ld	s2,16(sp)
ffffffffc0201c4c:	69a2                	ld	s3,8(sp)
ffffffffc0201c4e:	6a02                	ld	s4,0(sp)
ffffffffc0201c50:	6145                	addi	sp,sp,48
ffffffffc0201c52:	8082                	ret
            ROUNDUP(size + sizeof(struct big_block), PGSIZE) / PGSIZE;
ffffffffc0201c54:	01778493          	addi	s1,a5,23
ffffffffc0201c58:	94aa                	add	s1,s1,a0
        size_t pages =
ffffffffc0201c5a:	80b1                	srli	s1,s1,0xc
        struct Page *page = alloc_pages(pages);
ffffffffc0201c5c:	8526                	mv	a0,s1
ffffffffc0201c5e:	cebff0ef          	jal	ra,ffffffffc0201948 <alloc_pages>
        if (page == NULL) {
ffffffffc0201c62:	c125                	beqz	a0,ffffffffc0201cc2 <kmalloc+0x11e>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201c64:	00005797          	auipc	a5,0x5
ffffffffc0201c68:	6fc7b783          	ld	a5,1788(a5) # ffffffffc0207360 <pages>
ffffffffc0201c6c:	8d1d                	sub	a0,a0,a5
ffffffffc0201c6e:	850d                	srai	a0,a0,0x3
ffffffffc0201c70:	00002797          	auipc	a5,0x2
ffffffffc0201c74:	9f87b783          	ld	a5,-1544(a5) # ffffffffc0203668 <error_string+0x38>
ffffffffc0201c78:	02f50533          	mul	a0,a0,a5
ffffffffc0201c7c:	00002797          	auipc	a5,0x2
ffffffffc0201c80:	9f47b783          	ld	a5,-1548(a5) # ffffffffc0203670 <nbase>
}
ffffffffc0201c84:	70a2                	ld	ra,40(sp)
ffffffffc0201c86:	6942                	ld	s2,16(sp)
ffffffffc0201c88:	69a2                	ld	s3,8(sp)
ffffffffc0201c8a:	6a02                	ld	s4,0(sp)
ffffffffc0201c8c:	953e                	add	a0,a0,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0201c8e:	0532                	slli	a0,a0,0xc
    return (void *)(pa + va_pa_offset);
ffffffffc0201c90:	00005797          	auipc	a5,0x5
ffffffffc0201c94:	6f07b783          	ld	a5,1776(a5) # ffffffffc0207380 <va_pa_offset>
ffffffffc0201c98:	953e                	add	a0,a0,a5
        head->size = size;
ffffffffc0201c9a:	e500                	sd	s0,8(a0)
        head->magic = BIG_MAGIC;
ffffffffc0201c9c:	424947b7          	lui	a5,0x42494
}
ffffffffc0201ca0:	7402                	ld	s0,32(sp)
        head->magic = BIG_MAGIC;
ffffffffc0201ca2:	74d78793          	addi	a5,a5,1869 # 4249474d <kern_entry-0xffffffff7dd6b8b3>
        head->pages = pages;
ffffffffc0201ca6:	e904                	sd	s1,16(a0)
        head->magic = BIG_MAGIC;
ffffffffc0201ca8:	e11c                	sd	a5,0(a0)
}
ffffffffc0201caa:	64e2                	ld	s1,24(sp)
        return (void *)(head + 1);
ffffffffc0201cac:	0561                	addi	a0,a0,24
}
ffffffffc0201cae:	6145                	addi	sp,sp,48
ffffffffc0201cb0:	8082                	ret
    while (objsize < size) {
ffffffffc0201cb2:	00005917          	auipc	s2,0x5
ffffffffc0201cb6:	4d690913          	addi	s2,s2,1238 # ffffffffc0207188 <caches>
ffffffffc0201cba:	4401                	li	s0,0
ffffffffc0201cbc:	89ca                	mv	s3,s2
ffffffffc0201cbe:	4a41                	li	s4,16
ffffffffc0201cc0:	bf0d                	j	ffffffffc0201bf2 <kmalloc+0x4e>
}
ffffffffc0201cc2:	70a2                	ld	ra,40(sp)
ffffffffc0201cc4:	7402                	ld	s0,32(sp)
ffffffffc0201cc6:	64e2                	ld	s1,24(sp)
ffffffffc0201cc8:	6942                	ld	s2,16(sp)
ffffffffc0201cca:	69a2                	ld	s3,8(sp)
ffffffffc0201ccc:	6a02                	ld	s4,0(sp)
        return NULL;
ffffffffc0201cce:	4501                	li	a0,0
}
ffffffffc0201cd0:	6145                	addi	sp,sp,48
ffffffffc0201cd2:	8082                	ret
    struct Page *page = alloc_page();
ffffffffc0201cd4:	4505                	li	a0,1
ffffffffc0201cd6:	c73ff0ef          	jal	ra,ffffffffc0201948 <alloc_pages>
    if (page == NULL) {
ffffffffc0201cda:	d565                	beqz	a0,ffffffffc0201cc2 <kmalloc+0x11e>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201cdc:	00005697          	auipc	a3,0x5
ffffffffc0201ce0:	6846b683          	ld	a3,1668(a3) # ffffffffc0207360 <pages>
ffffffffc0201ce4:	40d506b3          	sub	a3,a0,a3
ffffffffc0201ce8:	00002797          	auipc	a5,0x2
ffffffffc0201cec:	9807b783          	ld	a5,-1664(a5) # ffffffffc0203668 <error_string+0x38>
ffffffffc0201cf0:	868d                	srai	a3,a3,0x3
ffffffffc0201cf2:	02f686b3          	mul	a3,a3,a5
ffffffffc0201cf6:	00002797          	auipc	a5,0x2
ffffffffc0201cfa:	97a7b783          	ld	a5,-1670(a5) # ffffffffc0203670 <nbase>
    for (unsigned int i = 0; i < cache->objs_per_slab; i++) {
ffffffffc0201cfe:	00149593          	slli	a1,s1,0x1
ffffffffc0201d02:	95a6                	add	a1,a1,s1
ffffffffc0201d04:	0592                	slli	a1,a1,0x4
ffffffffc0201d06:	95ca                	add	a1,a1,s2
ffffffffc0201d08:	4601                	li	a2,0
ffffffffc0201d0a:	4701                	li	a4,0
ffffffffc0201d0c:	96be                	add	a3,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0201d0e:	06b2                	slli	a3,a3,0xc
    return (void *)(pa + va_pa_offset);
ffffffffc0201d10:	00005797          	auipc	a5,0x5
ffffffffc0201d14:	6707b783          	ld	a5,1648(a5) # ffffffffc0207380 <va_pa_offset>
ffffffffc0201d18:	96be                	add	a3,a3,a5
    list_init(&slab->link);
ffffffffc0201d1a:	02068893          	addi	a7,a3,32
    elm->prev = elm->next = elm;
ffffffffc0201d1e:	0316b423          	sd	a7,40(a3)
ffffffffc0201d22:	0316b023          	sd	a7,32(a3)
    for (unsigned int i = 0; i < cache->objs_per_slab; i++) {
ffffffffc0201d26:	4588                	lw	a0,8(a1)
    slab->magic = SLAB_MAGIC;
ffffffffc0201d28:	534c57b7          	lui	a5,0x534c5
ffffffffc0201d2c:	54278793          	addi	a5,a5,1346 # 534c5542 <kern_entry-0xffffffff6cd3aabe>
ffffffffc0201d30:	e29c                	sd	a5,0(a3)
    slab->cache = cache;
ffffffffc0201d32:	0136b423          	sd	s3,8(a3)
    slab->inuse = 0;
ffffffffc0201d36:	0006ac23          	sw	zero,24(a3)
    slab->freelist = NULL;
ffffffffc0201d3a:	0006b823          	sd	zero,16(a3)
    for (unsigned int i = 0; i < cache->objs_per_slab; i++) {
ffffffffc0201d3e:	c11d                	beqz	a0,ffffffffc0201d64 <kmalloc+0x1c0>
        void *cur = obj + i * cache->objsize;
ffffffffc0201d40:	0005b803          	ld	a6,0(a1)
ffffffffc0201d44:	02071793          	slli	a5,a4,0x20
ffffffffc0201d48:	9381                	srli	a5,a5,0x20
ffffffffc0201d4a:	030787b3          	mul	a5,a5,a6
ffffffffc0201d4e:	8532                	mv	a0,a2
    for (unsigned int i = 0; i < cache->objs_per_slab; i++) {
ffffffffc0201d50:	2705                	addiw	a4,a4,1
        void *cur = obj + i * cache->objsize;
ffffffffc0201d52:	03078793          	addi	a5,a5,48
ffffffffc0201d56:	00f68633          	add	a2,a3,a5
        *(void **)cur = slab->freelist;
ffffffffc0201d5a:	e208                	sd	a0,0(a2)
    for (unsigned int i = 0; i < cache->objs_per_slab; i++) {
ffffffffc0201d5c:	459c                	lw	a5,8(a1)
        slab->freelist = cur;
ffffffffc0201d5e:	ea90                	sd	a2,16(a3)
    for (unsigned int i = 0; i < cache->objs_per_slab; i++) {
ffffffffc0201d60:	fef760e3          	bltu	a4,a5,ffffffffc0201d40 <kmalloc+0x19c>
    __list_add(elm, listelm, listelm->next);
ffffffffc0201d64:	0189b783          	ld	a5,24(s3)
    prev->next = next->prev = elm;
ffffffffc0201d68:	0117b023          	sd	a7,0(a5)
ffffffffc0201d6c:	0119bc23          	sd	a7,24(s3)
    elm->next = next;
ffffffffc0201d70:	f69c                	sd	a5,40(a3)
    return listelm->next;
ffffffffc0201d72:	0189b783          	ld	a5,24(s3)
    elm->prev = prev;
ffffffffc0201d76:	0346b023          	sd	s4,32(a3)
    return slab;
ffffffffc0201d7a:	b561                	j	ffffffffc0201c02 <kmalloc+0x5e>
        return NULL;
ffffffffc0201d7c:	4501                	li	a0,0
}
ffffffffc0201d7e:	8082                	ret

ffffffffc0201d80 <kfree>:

void
kfree(void *ptr) {
    if (ptr == NULL) {
ffffffffc0201d80:	c16d                	beqz	a0,ffffffffc0201e62 <kfree+0xe2>
        return;
    }

    uintptr_t page_base =
ffffffffc0201d82:	77fd                	lui	a5,0xfffff
ffffffffc0201d84:	8fe9                	and	a5,a5,a0
        (uintptr_t)ptr & ~((uintptr_t)PGSIZE - 1);
    uint64_t magic = *(uint64_t *)page_base;
ffffffffc0201d86:	6394                	ld	a3,0(a5)
kfree(void *ptr) {
ffffffffc0201d88:	1141                	addi	sp,sp,-16

    if (magic == SLAB_MAGIC) {
ffffffffc0201d8a:	534c5737          	lui	a4,0x534c5
kfree(void *ptr) {
ffffffffc0201d8e:	e406                	sd	ra,8(sp)
    if (magic == SLAB_MAGIC) {
ffffffffc0201d90:	54270713          	addi	a4,a4,1346 # 534c5542 <kern_entry-0xffffffff6cd3aabe>
ffffffffc0201d94:	04e68763          	beq	a3,a4,ffffffffc0201de2 <kfree+0x62>
        if (slab->inuse == 0) {
            list_del(&(slab->link));
            struct Page *page = pa2page(kva2pa(page_base));
            free_page(page);
        }
    } else if (magic == BIG_MAGIC) {
ffffffffc0201d98:	42494737          	lui	a4,0x42494
ffffffffc0201d9c:	74d70713          	addi	a4,a4,1869 # 4249474d <kern_entry-0xffffffff7dd6b8b3>
ffffffffc0201da0:	0ce69e63          	bne	a3,a4,ffffffffc0201e7c <kfree+0xfc>
    return kva - va_pa_offset;
ffffffffc0201da4:	00005517          	auipc	a0,0x5
ffffffffc0201da8:	5dc53503          	ld	a0,1500(a0) # ffffffffc0207380 <va_pa_offset>
ffffffffc0201dac:	40a78533          	sub	a0,a5,a0
    if (PPN(pa) >= npage) {
ffffffffc0201db0:	8131                	srli	a0,a0,0xc
ffffffffc0201db2:	00005717          	auipc	a4,0x5
ffffffffc0201db6:	5a673703          	ld	a4,1446(a4) # ffffffffc0207358 <npage>
ffffffffc0201dba:	0ae57563          	bgeu	a0,a4,ffffffffc0201e64 <kfree+0xe4>
    return &pages[PPN(pa) - nbase];
ffffffffc0201dbe:	00002717          	auipc	a4,0x2
ffffffffc0201dc2:	8b273703          	ld	a4,-1870(a4) # ffffffffc0203670 <nbase>
ffffffffc0201dc6:	8d19                	sub	a0,a0,a4
ffffffffc0201dc8:	00251713          	slli	a4,a0,0x2
ffffffffc0201dcc:	953a                	add	a0,a0,a4
        struct big_block *head = (struct big_block *)page_base;
        struct Page *page = pa2page(kva2pa(page_base));
        free_pages(page, head->pages);
ffffffffc0201dce:	6b8c                	ld	a1,16(a5)
ffffffffc0201dd0:	050e                	slli	a0,a0,0x3
ffffffffc0201dd2:	00005797          	auipc	a5,0x5
ffffffffc0201dd6:	58e7b783          	ld	a5,1422(a5) # ffffffffc0207360 <pages>
    } else {
        panic("kfree: invalid pointer 0x%016lx", (uintptr_t)ptr);
    }
}
ffffffffc0201dda:	60a2                	ld	ra,8(sp)
        free_pages(page, head->pages);
ffffffffc0201ddc:	953e                	add	a0,a0,a5
}
ffffffffc0201dde:	0141                	addi	sp,sp,16
        free_pages(page, head->pages);
ffffffffc0201de0:	be95                	j	ffffffffc0201954 <free_pages>
        struct kmem_cache *cache = slab->cache;
ffffffffc0201de2:	6794                	ld	a3,8(a5)
        *(void **)ptr = slab->freelist;
ffffffffc0201de4:	6b8c                	ld	a1,16(a5)
        int was_full = (slab->inuse == cache->objs_per_slab);
ffffffffc0201de6:	4f98                	lw	a4,24(a5)
        if (was_full) {
ffffffffc0201de8:	4690                	lw	a2,8(a3)
        *(void **)ptr = slab->freelist;
ffffffffc0201dea:	e10c                	sd	a1,0(a0)
        slab->freelist = ptr;
ffffffffc0201dec:	eb88                	sd	a0,16(a5)
        if (was_full) {
ffffffffc0201dee:	00e60963          	beq	a2,a4,ffffffffc0201e00 <kfree+0x80>
        slab->inuse--;
ffffffffc0201df2:	fff7069b          	addiw	a3,a4,-1
ffffffffc0201df6:	cf94                	sw	a3,24(a5)
        if (slab->inuse == 0) {
ffffffffc0201df8:	c695                	beqz	a3,ffffffffc0201e24 <kfree+0xa4>
}
ffffffffc0201dfa:	60a2                	ld	ra,8(sp)
ffffffffc0201dfc:	0141                	addi	sp,sp,16
ffffffffc0201dfe:	8082                	ret
    __list_del(listelm->prev, listelm->next);
ffffffffc0201e00:	0207b803          	ld	a6,32(a5)
ffffffffc0201e04:	7788                	ld	a0,40(a5)
            list_add(&cache->slabs_partial, &(slab->link));
ffffffffc0201e06:	02078613          	addi	a2,a5,32
ffffffffc0201e0a:	01068893          	addi	a7,a3,16
    prev->next = next;
ffffffffc0201e0e:	00a83423          	sd	a0,8(a6)
    __list_add(elm, listelm, listelm->next);
ffffffffc0201e12:	6e8c                	ld	a1,24(a3)
    next->prev = prev;
ffffffffc0201e14:	01053023          	sd	a6,0(a0)
    prev->next = next->prev = elm;
ffffffffc0201e18:	e190                	sd	a2,0(a1)
ffffffffc0201e1a:	ee90                	sd	a2,24(a3)
    elm->next = next;
ffffffffc0201e1c:	f78c                	sd	a1,40(a5)
    elm->prev = prev;
ffffffffc0201e1e:	0317b023          	sd	a7,32(a5)
}
ffffffffc0201e22:	bfc1                	j	ffffffffc0201df2 <kfree+0x72>
    __list_del(listelm->prev, listelm->next);
ffffffffc0201e24:	7390                	ld	a2,32(a5)
ffffffffc0201e26:	7794                	ld	a3,40(a5)
    return kva - va_pa_offset;
ffffffffc0201e28:	00005717          	auipc	a4,0x5
ffffffffc0201e2c:	55873703          	ld	a4,1368(a4) # ffffffffc0207380 <va_pa_offset>
ffffffffc0201e30:	8f99                	sub	a5,a5,a4
    prev->next = next;
ffffffffc0201e32:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc0201e34:	e290                	sd	a2,0(a3)
    if (PPN(pa) >= npage) {
ffffffffc0201e36:	83b1                	srli	a5,a5,0xc
ffffffffc0201e38:	00005717          	auipc	a4,0x5
ffffffffc0201e3c:	52073703          	ld	a4,1312(a4) # ffffffffc0207358 <npage>
ffffffffc0201e40:	02e7f263          	bgeu	a5,a4,ffffffffc0201e64 <kfree+0xe4>
    return &pages[PPN(pa) - nbase];
ffffffffc0201e44:	00002517          	auipc	a0,0x2
ffffffffc0201e48:	82c53503          	ld	a0,-2004(a0) # ffffffffc0203670 <nbase>
ffffffffc0201e4c:	8f89                	sub	a5,a5,a0
ffffffffc0201e4e:	00279513          	slli	a0,a5,0x2
ffffffffc0201e52:	97aa                	add	a5,a5,a0
ffffffffc0201e54:	078e                	slli	a5,a5,0x3
            free_page(page);
ffffffffc0201e56:	4585                	li	a1,1
ffffffffc0201e58:	00005517          	auipc	a0,0x5
ffffffffc0201e5c:	50853503          	ld	a0,1288(a0) # ffffffffc0207360 <pages>
ffffffffc0201e60:	bfad                	j	ffffffffc0201dda <kfree+0x5a>
ffffffffc0201e62:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0201e64:	00001617          	auipc	a2,0x1
ffffffffc0201e68:	27c60613          	addi	a2,a2,636 # ffffffffc02030e0 <buddy_pmm_manager+0x3d0>
ffffffffc0201e6c:	06a00593          	li	a1,106
ffffffffc0201e70:	00001517          	auipc	a0,0x1
ffffffffc0201e74:	29050513          	addi	a0,a0,656 # ffffffffc0203100 <buddy_pmm_manager+0x3f0>
ffffffffc0201e78:	b52fe0ef          	jal	ra,ffffffffc02001ca <__panic>
        panic("kfree: invalid pointer 0x%016lx", (uintptr_t)ptr);
ffffffffc0201e7c:	86aa                	mv	a3,a0
ffffffffc0201e7e:	00001617          	auipc	a2,0x1
ffffffffc0201e82:	2f260613          	addi	a2,a2,754 # ffffffffc0203170 <buddy_pmm_manager+0x460>
ffffffffc0201e86:	0b200593          	li	a1,178
ffffffffc0201e8a:	00001517          	auipc	a0,0x1
ffffffffc0201e8e:	30650513          	addi	a0,a0,774 # ffffffffc0203190 <buddy_pmm_manager+0x480>
ffffffffc0201e92:	b38fe0ef          	jal	ra,ffffffffc02001ca <__panic>

ffffffffc0201e96 <slub_test>:
    }
    return 1;
}

void
slub_test(void) {
ffffffffc0201e96:	c1010113          	addi	sp,sp,-1008
    cprintf("[SLUB] running tests\n");
ffffffffc0201e9a:	00001517          	auipc	a0,0x1
ffffffffc0201e9e:	30650513          	addi	a0,a0,774 # ffffffffc02031a0 <buddy_pmm_manager+0x490>
slub_test(void) {
ffffffffc0201ea2:	3e113423          	sd	ra,1000(sp)
ffffffffc0201ea6:	3b513c23          	sd	s5,952(sp)
ffffffffc0201eaa:	3b613823          	sd	s6,944(sp)
ffffffffc0201eae:	3e813023          	sd	s0,992(sp)
ffffffffc0201eb2:	3c913c23          	sd	s1,984(sp)
ffffffffc0201eb6:	3d213823          	sd	s2,976(sp)
ffffffffc0201eba:	3d313423          	sd	s3,968(sp)
ffffffffc0201ebe:	3d413023          	sd	s4,960(sp)
ffffffffc0201ec2:	3b713423          	sd	s7,936(sp)
ffffffffc0201ec6:	3b813023          	sd	s8,928(sp)
    cprintf("[SLUB] running tests\n");
ffffffffc0201eca:	a8afe0ef          	jal	ra,ffffffffc0200154 <cprintf>
    size_t before = nr_free_pages();
ffffffffc0201ece:	a93ff0ef          	jal	ra,ffffffffc0201960 <nr_free_pages>
    slub_init();

    // 1. different object sizes: alignment, distinctness, and no overlap
    size_t sizes[] = {
ffffffffc0201ed2:	06010a93          	addi	s5,sp,96
    size_t before = nr_free_pages();
ffffffffc0201ed6:	8b2a                	mv	s6,a0
    slub_init();
ffffffffc0201ed8:	c91ff0ef          	jal	ra,ffffffffc0201b68 <slub_init>
    size_t sizes[] = {
ffffffffc0201edc:	00001797          	auipc	a5,0x1
ffffffffc0201ee0:	4a478793          	addi	a5,a5,1188 # ffffffffc0203380 <buddy_pmm_manager+0x670>
ffffffffc0201ee4:	8756                	mv	a4,s5
ffffffffc0201ee6:	00001817          	auipc	a6,0x1
ffffffffc0201eea:	53a80813          	addi	a6,a6,1338 # ffffffffc0203420 <buddy_pmm_manager+0x710>
ffffffffc0201eee:	6388                	ld	a0,0(a5)
ffffffffc0201ef0:	678c                	ld	a1,8(a5)
ffffffffc0201ef2:	6b90                	ld	a2,16(a5)
ffffffffc0201ef4:	6f94                	ld	a3,24(a5)
ffffffffc0201ef6:	e308                	sd	a0,0(a4)
ffffffffc0201ef8:	e70c                	sd	a1,8(a4)
ffffffffc0201efa:	eb10                	sd	a2,16(a4)
ffffffffc0201efc:	ef14                	sd	a3,24(a4)
ffffffffc0201efe:	02078793          	addi	a5,a5,32
ffffffffc0201f02:	02070713          	addi	a4,a4,32
ffffffffc0201f06:	ff0794e3          	bne	a5,a6,ffffffffc0201eee <slub_test+0x58>
        256, 512, 1000, 1024, 2000, 2048, 4095, 4096, 4097, 8192
    };
    const int nr_sizes = sizeof(sizes) / sizeof(sizes[0]);
    void *ptrs[20];

    for (int i = 0; i < nr_sizes; i++) {
ffffffffc0201f0a:	10010a13          	addi	s4,sp,256
ffffffffc0201f0e:	8bd6                	mv	s7,s5
    size_t sizes[] = {
ffffffffc0201f10:	8952                	mv	s2,s4
ffffffffc0201f12:	84d6                	mv	s1,s5
ffffffffc0201f14:	4405                	li	s0,1
    for (int i = 0; i < nr_sizes; i++) {
ffffffffc0201f16:	4c55                	li	s8,21
        ptrs[i] = kmalloc(sizes[i]);
ffffffffc0201f18:	0004b983          	ld	s3,0(s1)
    for (int i = 0; i < nr_sizes; i++) {
ffffffffc0201f1c:	0921                	addi	s2,s2,8
ffffffffc0201f1e:	04a1                	addi	s1,s1,8
        ptrs[i] = kmalloc(sizes[i]);
ffffffffc0201f20:	854e                	mv	a0,s3
ffffffffc0201f22:	c83ff0ef          	jal	ra,ffffffffc0201ba4 <kmalloc>
ffffffffc0201f26:	fea93c23          	sd	a0,-8(s2)
        }
        if ((uintptr_t)ptrs[i] % 8 != 0) {
            slub_fail("returned pointer is not 8-byte aligned");
            return;
        }
        memset(ptrs[i], (unsigned char)(i + 1), sizes[i]);
ffffffffc0201f2a:	0ff47593          	zext.b	a1,s0
        if ((uintptr_t)ptrs[i] % 8 != 0) {
ffffffffc0201f2e:	00757713          	andi	a4,a0,7
        memset(ptrs[i], (unsigned char)(i + 1), sizes[i]);
ffffffffc0201f32:	864e                	mv	a2,s3
    for (int i = 0; i < nr_sizes; i++) {
ffffffffc0201f34:	0405                	addi	s0,s0,1
        if (ptrs[i] == NULL) {
ffffffffc0201f36:	1e050763          	beqz	a0,ffffffffc0202124 <slub_test+0x28e>
        if ((uintptr_t)ptrs[i] % 8 != 0) {
ffffffffc0201f3a:	1e071a63          	bnez	a4,ffffffffc020212e <slub_test+0x298>
        memset(ptrs[i], (unsigned char)(i + 1), sizes[i]);
ffffffffc0201f3e:	738000ef          	jal	ra,ffffffffc0202676 <memset>
    for (int i = 0; i < nr_sizes; i++) {
ffffffffc0201f42:	fd841be3          	bne	s0,s8,ffffffffc0201f18 <slub_test+0x82>
ffffffffc0201f46:	0228                	addi	a0,sp,264
ffffffffc0201f48:	4585                	li	a1,1
    }

    for (int i = 0; i < nr_sizes; i++) {
        for (int j = i + 1; j < nr_sizes; j++) {
ffffffffc0201f4a:	4851                	li	a6,20
ffffffffc0201f4c:	434d                	li	t1,19
ffffffffc0201f4e:	010a0893          	addi	a7,s4,16
    for (int i = 0; i < nr_sizes; i++) {
ffffffffc0201f52:	4e55                	li	t3,21
            if (ptrs[i] == ptrs[j]) {
                slub_fail("distinct allocations returned the same pointer");
                return;
            }
        }
        if (!slub_check_bytes(ptrs[i], sizes[i], (unsigned char)(i + 1))) {
ffffffffc0201f54:	ff853703          	ld	a4,-8(a0)
ffffffffc0201f58:	0005879b          	sext.w	a5,a1
        for (int j = i + 1; j < nr_sizes; j++) {
ffffffffc0201f5c:	07058363          	beq	a1,a6,ffffffffc0201fc2 <slub_test+0x12c>
ffffffffc0201f60:	40f306bb          	subw	a3,t1,a5
ffffffffc0201f64:	1682                	slli	a3,a3,0x20
ffffffffc0201f66:	fff58793          	addi	a5,a1,-1
ffffffffc0201f6a:	9281                	srli	a3,a3,0x20
ffffffffc0201f6c:	96be                	add	a3,a3,a5
ffffffffc0201f6e:	068e                	slli	a3,a3,0x3
ffffffffc0201f70:	96c6                	add	a3,a3,a7
ffffffffc0201f72:	87aa                	mv	a5,a0
ffffffffc0201f74:	a019                	j	ffffffffc0201f7a <slub_test+0xe4>
ffffffffc0201f76:	04d78663          	beq	a5,a3,ffffffffc0201fc2 <slub_test+0x12c>
            if (ptrs[i] == ptrs[j]) {
ffffffffc0201f7a:	6390                	ld	a2,0(a5)
        for (int j = i + 1; j < nr_sizes; j++) {
ffffffffc0201f7c:	07a1                	addi	a5,a5,8
            if (ptrs[i] == ptrs[j]) {
ffffffffc0201f7e:	fee61ce3          	bne	a2,a4,ffffffffc0201f76 <slub_test+0xe0>
    cprintf("[SLUB] FAIL: %s\n", msg);
ffffffffc0201f82:	00001597          	auipc	a1,0x1
ffffffffc0201f86:	29658593          	addi	a1,a1,662 # ffffffffc0203218 <buddy_pmm_manager+0x508>
    if (nr_free_pages() != before) {
        slub_fail("page count changed after edge cases");
    }

    cprintf("[SLUB] tests PASS\n");
}
ffffffffc0201f8a:	3e013403          	ld	s0,992(sp)
ffffffffc0201f8e:	3e813083          	ld	ra,1000(sp)
ffffffffc0201f92:	3d813483          	ld	s1,984(sp)
ffffffffc0201f96:	3d013903          	ld	s2,976(sp)
ffffffffc0201f9a:	3c813983          	ld	s3,968(sp)
ffffffffc0201f9e:	3c013a03          	ld	s4,960(sp)
ffffffffc0201fa2:	3b813a83          	ld	s5,952(sp)
ffffffffc0201fa6:	3b013b03          	ld	s6,944(sp)
ffffffffc0201faa:	3a813b83          	ld	s7,936(sp)
ffffffffc0201fae:	3a013c03          	ld	s8,928(sp)
    cprintf("[SLUB] FAIL: %s\n", msg);
ffffffffc0201fb2:	00001517          	auipc	a0,0x1
ffffffffc0201fb6:	22650513          	addi	a0,a0,550 # ffffffffc02031d8 <buddy_pmm_manager+0x4c8>
}
ffffffffc0201fba:	3f010113          	addi	sp,sp,1008
    cprintf("[SLUB] FAIL: %s\n", msg);
ffffffffc0201fbe:	996fe06f          	j	ffffffffc0200154 <cprintf>
        if (!slub_check_bytes(ptrs[i], sizes[i], (unsigned char)(i + 1))) {
ffffffffc0201fc2:	000bb683          	ld	a3,0(s7)
    for (size_t i = 0; i < size; i++) {
ffffffffc0201fc6:	c295                	beqz	a3,ffffffffc0201fea <slub_test+0x154>
ffffffffc0201fc8:	87ba                	mv	a5,a4
ffffffffc0201fca:	96ba                	add	a3,a3,a4
ffffffffc0201fcc:	0ff5f613          	zext.b	a2,a1
ffffffffc0201fd0:	a019                	j	ffffffffc0201fd6 <slub_test+0x140>
ffffffffc0201fd2:	00d78c63          	beq	a5,a3,ffffffffc0201fea <slub_test+0x154>
        if (p[i] != pat) {
ffffffffc0201fd6:	0007c703          	lbu	a4,0(a5)
    for (size_t i = 0; i < size; i++) {
ffffffffc0201fda:	0785                	addi	a5,a5,1
        if (p[i] != pat) {
ffffffffc0201fdc:	fec70be3          	beq	a4,a2,ffffffffc0201fd2 <slub_test+0x13c>
    cprintf("[SLUB] FAIL: %s\n", msg);
ffffffffc0201fe0:	00001597          	auipc	a1,0x1
ffffffffc0201fe4:	35058593          	addi	a1,a1,848 # ffffffffc0203330 <buddy_pmm_manager+0x620>
ffffffffc0201fe8:	b74d                	j	ffffffffc0201f8a <slub_test+0xf4>
    for (int i = 0; i < nr_sizes; i++) {
ffffffffc0201fea:	0585                	addi	a1,a1,1
ffffffffc0201fec:	0ba1                	addi	s7,s7,8
ffffffffc0201fee:	0521                	addi	a0,a0,8
ffffffffc0201ff0:	f7c592e3          	bne	a1,t3,ffffffffc0201f54 <slub_test+0xbe>
ffffffffc0201ff4:	0a0a0413          	addi	s0,s4,160
        kfree(ptrs[i]);
ffffffffc0201ff8:	000a3503          	ld	a0,0(s4)
    for (int i = 0; i < nr_sizes; i++) {
ffffffffc0201ffc:	0a21                	addi	s4,s4,8
        kfree(ptrs[i]);
ffffffffc0201ffe:	d83ff0ef          	jal	ra,ffffffffc0201d80 <kfree>
    for (int i = 0; i < nr_sizes; i++) {
ffffffffc0202002:	fe8a1be3          	bne	s4,s0,ffffffffc0201ff8 <slub_test+0x162>
    if (nr_free_pages() != before) {
ffffffffc0202006:	95bff0ef          	jal	ra,ffffffffc0201960 <nr_free_pages>
ffffffffc020200a:	01650c63          	beq	a0,s6,ffffffffc0202022 <slub_test+0x18c>
    cprintf("[SLUB] FAIL: %s\n", msg);
ffffffffc020200e:	00001597          	auipc	a1,0x1
ffffffffc0202012:	23a58593          	addi	a1,a1,570 # ffffffffc0203248 <buddy_pmm_manager+0x538>
ffffffffc0202016:	00001517          	auipc	a0,0x1
ffffffffc020201a:	1c250513          	addi	a0,a0,450 # ffffffffc02031d8 <buddy_pmm_manager+0x4c8>
ffffffffc020201e:	936fe0ef          	jal	ra,ffffffffc0200154 <cprintf>
ffffffffc0202022:	1004                	addi	s1,sp,32
ffffffffc0202024:	8926                	mv	s2,s1
        for (int j = i + 1; j < nr_sizes; j++) {
ffffffffc0202026:	8426                	mv	s0,s1
        q[i] = kmalloc(16);
ffffffffc0202028:	4541                	li	a0,16
ffffffffc020202a:	b7bff0ef          	jal	ra,ffffffffc0201ba4 <kmalloc>
ffffffffc020202e:	e008                	sd	a0,0(s0)
        memset(q[i], 0x5a, 16);
ffffffffc0202030:	4641                	li	a2,16
ffffffffc0202032:	05a00593          	li	a1,90
    for (int i = 0; i < 8; i++) {
ffffffffc0202036:	0421                	addi	s0,s0,8
        if (q[i] == NULL) {
ffffffffc0202038:	10050063          	beqz	a0,ffffffffc0202138 <slub_test+0x2a2>
        memset(q[i], 0x5a, 16);
ffffffffc020203c:	63a000ef          	jal	ra,ffffffffc0202676 <memset>
    for (int i = 0; i < 8; i++) {
ffffffffc0202040:	fe8a94e3          	bne	s5,s0,ffffffffc0202028 <slub_test+0x192>
ffffffffc0202044:	8426                	mv	s0,s1
        kfree(q[i]);
ffffffffc0202046:	6008                	ld	a0,0(s0)
    for (int i = 0; i < 8; i += 2) {
ffffffffc0202048:	0441                	addi	s0,s0,16
        kfree(q[i]);
ffffffffc020204a:	d37ff0ef          	jal	ra,ffffffffc0201d80 <kfree>
    for (int i = 0; i < 8; i += 2) {
ffffffffc020204e:	fe8a9ce3          	bne	s5,s0,ffffffffc0202046 <slub_test+0x1b0>
ffffffffc0202052:	840a                	mv	s0,sp
ffffffffc0202054:	89a2                	mv	s3,s0
    cprintf("[SLUB] FAIL: %s\n", msg);
ffffffffc0202056:	00001b97          	auipc	s7,0x1
ffffffffc020205a:	30ab8b93          	addi	s7,s7,778 # ffffffffc0203360 <buddy_pmm_manager+0x650>
ffffffffc020205e:	00001a17          	auipc	s4,0x1
ffffffffc0202062:	17aa0a13          	addi	s4,s4,378 # ffffffffc02031d8 <buddy_pmm_manager+0x4c8>
        r[i] = kmalloc(16);
ffffffffc0202066:	4541                	li	a0,16
ffffffffc0202068:	b3dff0ef          	jal	ra,ffffffffc0201ba4 <kmalloc>
ffffffffc020206c:	00a9b023          	sd	a0,0(s3)
        if (r[i] == NULL) {
ffffffffc0202070:	16050d63          	beqz	a0,ffffffffc02021ea <slub_test+0x354>
ffffffffc0202074:	87a6                	mv	a5,s1
            if (r[i] == q[j]) {
ffffffffc0202076:	6398                	ld	a4,0(a5)
        for (int j = 0; j < 8; j += 2) {
ffffffffc0202078:	07c1                	addi	a5,a5,16
            if (r[i] == q[j]) {
ffffffffc020207a:	00e50863          	beq	a0,a4,ffffffffc020208a <slub_test+0x1f4>
        for (int j = 0; j < 8; j += 2) {
ffffffffc020207e:	ff579ce3          	bne	a5,s5,ffffffffc0202076 <slub_test+0x1e0>
    cprintf("[SLUB] FAIL: %s\n", msg);
ffffffffc0202082:	85de                	mv	a1,s7
ffffffffc0202084:	8552                	mv	a0,s4
ffffffffc0202086:	8cefe0ef          	jal	ra,ffffffffc0200154 <cprintf>
    for (int i = 0; i < 4; i++) {
ffffffffc020208a:	09a1                	addi	s3,s3,8
ffffffffc020208c:	fc999de3          	bne	s3,s1,ffffffffc0202066 <slub_test+0x1d0>
        kfree(r[i]);
ffffffffc0202090:	6008                	ld	a0,0(s0)
    for (int i = 0; i < 4; i++) {
ffffffffc0202092:	0421                	addi	s0,s0,8
        kfree(r[i]);
ffffffffc0202094:	cedff0ef          	jal	ra,ffffffffc0201d80 <kfree>
    for (int i = 0; i < 4; i++) {
ffffffffc0202098:	fe941ce3          	bne	s0,s1,ffffffffc0202090 <slub_test+0x1fa>
        kfree(q[i]);
ffffffffc020209c:	00893503          	ld	a0,8(s2)
    for (int i = 1; i < 8; i += 2) {
ffffffffc02020a0:	0941                	addi	s2,s2,16
        kfree(q[i]);
ffffffffc02020a2:	cdfff0ef          	jal	ra,ffffffffc0201d80 <kfree>
    for (int i = 1; i < 8; i += 2) {
ffffffffc02020a6:	ff591be3          	bne	s2,s5,ffffffffc020209c <slub_test+0x206>
    if (nr_free_pages() != before) {
ffffffffc02020aa:	8b7ff0ef          	jal	ra,ffffffffc0201960 <nr_free_pages>
ffffffffc02020ae:	01650c63          	beq	a0,s6,ffffffffc02020c6 <slub_test+0x230>
    cprintf("[SLUB] FAIL: %s\n", msg);
ffffffffc02020b2:	00001597          	auipc	a1,0x1
ffffffffc02020b6:	1ee58593          	addi	a1,a1,494 # ffffffffc02032a0 <buddy_pmm_manager+0x590>
ffffffffc02020ba:	00001517          	auipc	a0,0x1
ffffffffc02020be:	11e50513          	addi	a0,a0,286 # ffffffffc02031d8 <buddy_pmm_manager+0x4c8>
ffffffffc02020c2:	892fe0ef          	jal	ra,ffffffffc0200154 <cprintf>
ffffffffc02020c6:	1a010a13          	addi	s4,sp,416
    slub_rng_state = slub_rng_state * 1103515245u + 12345u;
ffffffffc02020ca:	41c659b7          	lui	s3,0x41c65
ffffffffc02020ce:	690d                	lui	s2,0x3
ffffffffc02020d0:	3a010a93          	addi	s5,sp,928
ffffffffc02020d4:	8bd2                	mv	s7,s4
ffffffffc02020d6:	00005497          	auipc	s1,0x5
ffffffffc02020da:	f3e48493          	addi	s1,s1,-194 # ffffffffc0207014 <slub_rng_state>
ffffffffc02020de:	e6d9899b          	addiw	s3,s3,-403
ffffffffc02020e2:	0399091b          	addiw	s2,s2,57
ffffffffc02020e6:	a029                	j	ffffffffc02020f0 <slub_test+0x25a>
        memset(p[i], 0x33, sz[i]);
ffffffffc02020e8:	58e000ef          	jal	ra,ffffffffc0202676 <memset>
    for (int i = 0; i < SLUB_STRESS_ALLOCS; i++) {
ffffffffc02020ec:	055b8b63          	beq	s7,s5,ffffffffc0202142 <slub_test+0x2ac>
    slub_rng_state = slub_rng_state * 1103515245u + 12345u;
ffffffffc02020f0:	409c                	lw	a5,0(s1)
    for (int i = 0; i < SLUB_STRESS_ALLOCS; i++) {
ffffffffc02020f2:	0ba1                	addi	s7,s7,8
    slub_rng_state = slub_rng_state * 1103515245u + 12345u;
ffffffffc02020f4:	033787bb          	mulw	a5,a5,s3
ffffffffc02020f8:	012787bb          	addw	a5,a5,s2
    return slub_rng_state >> 16;
ffffffffc02020fc:	0107d41b          	srliw	s0,a5,0x10
        sz[i] = 1 + (slub_rand() % 2048);
ffffffffc0202100:	7ff47413          	andi	s0,s0,2047
ffffffffc0202104:	0405                	addi	s0,s0,1
        p[i] = kmalloc(sz[i]);
ffffffffc0202106:	8522                	mv	a0,s0
    slub_rng_state = slub_rng_state * 1103515245u + 12345u;
ffffffffc0202108:	c09c                	sw	a5,0(s1)
        p[i] = kmalloc(sz[i]);
ffffffffc020210a:	a9bff0ef          	jal	ra,ffffffffc0201ba4 <kmalloc>
ffffffffc020210e:	feabbc23          	sd	a0,-8(s7)
        memset(p[i], 0x33, sz[i]);
ffffffffc0202112:	8622                	mv	a2,s0
ffffffffc0202114:	03300593          	li	a1,51
        if (p[i] == NULL) {
ffffffffc0202118:	f961                	bnez	a0,ffffffffc02020e8 <slub_test+0x252>
    cprintf("[SLUB] FAIL: %s\n", msg);
ffffffffc020211a:	00001597          	auipc	a1,0x1
ffffffffc020211e:	dee58593          	addi	a1,a1,-530 # ffffffffc0202f08 <buddy_pmm_manager+0x1f8>
ffffffffc0202122:	b5a5                	j	ffffffffc0201f8a <slub_test+0xf4>
ffffffffc0202124:	00001597          	auipc	a1,0x1
ffffffffc0202128:	09458593          	addi	a1,a1,148 # ffffffffc02031b8 <buddy_pmm_manager+0x4a8>
ffffffffc020212c:	bdb9                	j	ffffffffc0201f8a <slub_test+0xf4>
ffffffffc020212e:	00001597          	auipc	a1,0x1
ffffffffc0202132:	0c258593          	addi	a1,a1,194 # ffffffffc02031f0 <buddy_pmm_manager+0x4e0>
ffffffffc0202136:	bd91                	j	ffffffffc0201f8a <slub_test+0xf4>
ffffffffc0202138:	00001597          	auipc	a1,0x1
ffffffffc020213c:	13858593          	addi	a1,a1,312 # ffffffffc0203270 <buddy_pmm_manager+0x560>
ffffffffc0202140:	b5a9                	j	ffffffffc0201f8a <slub_test+0xf4>
ffffffffc0202142:	0f20                	addi	s0,sp,920
        kfree(p[i]);
ffffffffc0202144:	6008                	ld	a0,0(s0)
ffffffffc0202146:	c3bff0ef          	jal	ra,ffffffffc0201d80 <kfree>
    for (int i = SLUB_STRESS_ALLOCS - 1; i >= 0; i--) {
ffffffffc020214a:	87a2                	mv	a5,s0
ffffffffc020214c:	1461                	addi	s0,s0,-8
ffffffffc020214e:	fefa1be3          	bne	s4,a5,ffffffffc0202144 <slub_test+0x2ae>
    if (nr_free_pages() != before) {
ffffffffc0202152:	80fff0ef          	jal	ra,ffffffffc0201960 <nr_free_pages>
ffffffffc0202156:	01650c63          	beq	a0,s6,ffffffffc020216e <slub_test+0x2d8>
    cprintf("[SLUB] FAIL: %s\n", msg);
ffffffffc020215a:	00001597          	auipc	a1,0x1
ffffffffc020215e:	16e58593          	addi	a1,a1,366 # ffffffffc02032c8 <buddy_pmm_manager+0x5b8>
ffffffffc0202162:	00001517          	auipc	a0,0x1
ffffffffc0202166:	07650513          	addi	a0,a0,118 # ffffffffc02031d8 <buddy_pmm_manager+0x4c8>
ffffffffc020216a:	febfd0ef          	jal	ra,ffffffffc0200154 <cprintf>
    void *huge = kmalloc((size_t)1 << 31);
ffffffffc020216e:	4505                	li	a0,1
ffffffffc0202170:	057e                	slli	a0,a0,0x1f
ffffffffc0202172:	a33ff0ef          	jal	ra,ffffffffc0201ba4 <kmalloc>
    if (huge != NULL) {
ffffffffc0202176:	cd09                	beqz	a0,ffffffffc0202190 <slub_test+0x2fa>
        kfree(huge);
ffffffffc0202178:	c09ff0ef          	jal	ra,ffffffffc0201d80 <kfree>
    cprintf("[SLUB] FAIL: %s\n", msg);
ffffffffc020217c:	00001597          	auipc	a1,0x1
ffffffffc0202180:	c3458593          	addi	a1,a1,-972 # ffffffffc0202db0 <buddy_pmm_manager+0xa0>
ffffffffc0202184:	00001517          	auipc	a0,0x1
ffffffffc0202188:	05450513          	addi	a0,a0,84 # ffffffffc02031d8 <buddy_pmm_manager+0x4c8>
ffffffffc020218c:	fc9fd0ef          	jal	ra,ffffffffc0200154 <cprintf>
    kfree(NULL);
ffffffffc0202190:	4501                	li	a0,0
ffffffffc0202192:	befff0ef          	jal	ra,ffffffffc0201d80 <kfree>
    if (nr_free_pages() != before) {
ffffffffc0202196:	fcaff0ef          	jal	ra,ffffffffc0201960 <nr_free_pages>
ffffffffc020219a:	01650c63          	beq	a0,s6,ffffffffc02021b2 <slub_test+0x31c>
    cprintf("[SLUB] FAIL: %s\n", msg);
ffffffffc020219e:	00001597          	auipc	a1,0x1
ffffffffc02021a2:	15258593          	addi	a1,a1,338 # ffffffffc02032f0 <buddy_pmm_manager+0x5e0>
ffffffffc02021a6:	00001517          	auipc	a0,0x1
ffffffffc02021aa:	03250513          	addi	a0,a0,50 # ffffffffc02031d8 <buddy_pmm_manager+0x4c8>
ffffffffc02021ae:	fa7fd0ef          	jal	ra,ffffffffc0200154 <cprintf>
}
ffffffffc02021b2:	3e013403          	ld	s0,992(sp)
ffffffffc02021b6:	3e813083          	ld	ra,1000(sp)
ffffffffc02021ba:	3d813483          	ld	s1,984(sp)
ffffffffc02021be:	3d013903          	ld	s2,976(sp)
ffffffffc02021c2:	3c813983          	ld	s3,968(sp)
ffffffffc02021c6:	3c013a03          	ld	s4,960(sp)
ffffffffc02021ca:	3b813a83          	ld	s5,952(sp)
ffffffffc02021ce:	3b013b03          	ld	s6,944(sp)
ffffffffc02021d2:	3a813b83          	ld	s7,936(sp)
ffffffffc02021d6:	3a013c03          	ld	s8,928(sp)
    cprintf("[SLUB] tests PASS\n");
ffffffffc02021da:	00001517          	auipc	a0,0x1
ffffffffc02021de:	13e50513          	addi	a0,a0,318 # ffffffffc0203318 <buddy_pmm_manager+0x608>
}
ffffffffc02021e2:	3f010113          	addi	sp,sp,1008
    cprintf("[SLUB] tests PASS\n");
ffffffffc02021e6:	f6ffd06f          	j	ffffffffc0200154 <cprintf>
    cprintf("[SLUB] FAIL: %s\n", msg);
ffffffffc02021ea:	00001597          	auipc	a1,0x1
ffffffffc02021ee:	09e58593          	addi	a1,a1,158 # ffffffffc0203288 <buddy_pmm_manager+0x578>
ffffffffc02021f2:	bb61                	j	ffffffffc0201f8a <slub_test+0xf4>

ffffffffc02021f4 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc02021f4:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02021f8:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc02021fa:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02021fe:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0202200:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0202204:	f022                	sd	s0,32(sp)
ffffffffc0202206:	ec26                	sd	s1,24(sp)
ffffffffc0202208:	e84a                	sd	s2,16(sp)
ffffffffc020220a:	f406                	sd	ra,40(sp)
ffffffffc020220c:	e44e                	sd	s3,8(sp)
ffffffffc020220e:	84aa                	mv	s1,a0
ffffffffc0202210:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0202212:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0202216:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0202218:	03067e63          	bgeu	a2,a6,ffffffffc0202254 <printnum+0x60>
ffffffffc020221c:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc020221e:	00805763          	blez	s0,ffffffffc020222c <printnum+0x38>
ffffffffc0202222:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0202224:	85ca                	mv	a1,s2
ffffffffc0202226:	854e                	mv	a0,s3
ffffffffc0202228:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc020222a:	fc65                	bnez	s0,ffffffffc0202222 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020222c:	1a02                	slli	s4,s4,0x20
ffffffffc020222e:	00001797          	auipc	a5,0x1
ffffffffc0202232:	1f278793          	addi	a5,a5,498 # ffffffffc0203420 <buddy_pmm_manager+0x710>
ffffffffc0202236:	020a5a13          	srli	s4,s4,0x20
ffffffffc020223a:	9a3e                	add	s4,s4,a5
}
ffffffffc020223c:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020223e:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0202242:	70a2                	ld	ra,40(sp)
ffffffffc0202244:	69a2                	ld	s3,8(sp)
ffffffffc0202246:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0202248:	85ca                	mv	a1,s2
ffffffffc020224a:	87a6                	mv	a5,s1
}
ffffffffc020224c:	6942                	ld	s2,16(sp)
ffffffffc020224e:	64e2                	ld	s1,24(sp)
ffffffffc0202250:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0202252:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0202254:	03065633          	divu	a2,a2,a6
ffffffffc0202258:	8722                	mv	a4,s0
ffffffffc020225a:	f9bff0ef          	jal	ra,ffffffffc02021f4 <printnum>
ffffffffc020225e:	b7f9                	j	ffffffffc020222c <printnum+0x38>

ffffffffc0202260 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0202260:	7119                	addi	sp,sp,-128
ffffffffc0202262:	f4a6                	sd	s1,104(sp)
ffffffffc0202264:	f0ca                	sd	s2,96(sp)
ffffffffc0202266:	ecce                	sd	s3,88(sp)
ffffffffc0202268:	e8d2                	sd	s4,80(sp)
ffffffffc020226a:	e4d6                	sd	s5,72(sp)
ffffffffc020226c:	e0da                	sd	s6,64(sp)
ffffffffc020226e:	fc5e                	sd	s7,56(sp)
ffffffffc0202270:	f06a                	sd	s10,32(sp)
ffffffffc0202272:	fc86                	sd	ra,120(sp)
ffffffffc0202274:	f8a2                	sd	s0,112(sp)
ffffffffc0202276:	f862                	sd	s8,48(sp)
ffffffffc0202278:	f466                	sd	s9,40(sp)
ffffffffc020227a:	ec6e                	sd	s11,24(sp)
ffffffffc020227c:	892a                	mv	s2,a0
ffffffffc020227e:	84ae                	mv	s1,a1
ffffffffc0202280:	8d32                	mv	s10,a2
ffffffffc0202282:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0202284:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0202288:	5b7d                	li	s6,-1
ffffffffc020228a:	00001a97          	auipc	s5,0x1
ffffffffc020228e:	1caa8a93          	addi	s5,s5,458 # ffffffffc0203454 <buddy_pmm_manager+0x744>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0202292:	00001b97          	auipc	s7,0x1
ffffffffc0202296:	39eb8b93          	addi	s7,s7,926 # ffffffffc0203630 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020229a:	000d4503          	lbu	a0,0(s10)
ffffffffc020229e:	001d0413          	addi	s0,s10,1
ffffffffc02022a2:	01350a63          	beq	a0,s3,ffffffffc02022b6 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc02022a6:	c121                	beqz	a0,ffffffffc02022e6 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc02022a8:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02022aa:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc02022ac:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02022ae:	fff44503          	lbu	a0,-1(s0)
ffffffffc02022b2:	ff351ae3          	bne	a0,s3,ffffffffc02022a6 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02022b6:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc02022ba:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc02022be:	4c81                	li	s9,0
ffffffffc02022c0:	4881                	li	a7,0
        width = precision = -1;
ffffffffc02022c2:	5c7d                	li	s8,-1
ffffffffc02022c4:	5dfd                	li	s11,-1
ffffffffc02022c6:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc02022ca:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02022cc:	fdd6059b          	addiw	a1,a2,-35
ffffffffc02022d0:	0ff5f593          	zext.b	a1,a1
ffffffffc02022d4:	00140d13          	addi	s10,s0,1
ffffffffc02022d8:	04b56263          	bltu	a0,a1,ffffffffc020231c <vprintfmt+0xbc>
ffffffffc02022dc:	058a                	slli	a1,a1,0x2
ffffffffc02022de:	95d6                	add	a1,a1,s5
ffffffffc02022e0:	4194                	lw	a3,0(a1)
ffffffffc02022e2:	96d6                	add	a3,a3,s5
ffffffffc02022e4:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc02022e6:	70e6                	ld	ra,120(sp)
ffffffffc02022e8:	7446                	ld	s0,112(sp)
ffffffffc02022ea:	74a6                	ld	s1,104(sp)
ffffffffc02022ec:	7906                	ld	s2,96(sp)
ffffffffc02022ee:	69e6                	ld	s3,88(sp)
ffffffffc02022f0:	6a46                	ld	s4,80(sp)
ffffffffc02022f2:	6aa6                	ld	s5,72(sp)
ffffffffc02022f4:	6b06                	ld	s6,64(sp)
ffffffffc02022f6:	7be2                	ld	s7,56(sp)
ffffffffc02022f8:	7c42                	ld	s8,48(sp)
ffffffffc02022fa:	7ca2                	ld	s9,40(sp)
ffffffffc02022fc:	7d02                	ld	s10,32(sp)
ffffffffc02022fe:	6de2                	ld	s11,24(sp)
ffffffffc0202300:	6109                	addi	sp,sp,128
ffffffffc0202302:	8082                	ret
            padc = '0';
ffffffffc0202304:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0202306:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020230a:	846a                	mv	s0,s10
ffffffffc020230c:	00140d13          	addi	s10,s0,1
ffffffffc0202310:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0202314:	0ff5f593          	zext.b	a1,a1
ffffffffc0202318:	fcb572e3          	bgeu	a0,a1,ffffffffc02022dc <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc020231c:	85a6                	mv	a1,s1
ffffffffc020231e:	02500513          	li	a0,37
ffffffffc0202322:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0202324:	fff44783          	lbu	a5,-1(s0)
ffffffffc0202328:	8d22                	mv	s10,s0
ffffffffc020232a:	f73788e3          	beq	a5,s3,ffffffffc020229a <vprintfmt+0x3a>
ffffffffc020232e:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0202332:	1d7d                	addi	s10,s10,-1
ffffffffc0202334:	ff379de3          	bne	a5,s3,ffffffffc020232e <vprintfmt+0xce>
ffffffffc0202338:	b78d                	j	ffffffffc020229a <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc020233a:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc020233e:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0202342:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0202344:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0202348:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc020234c:	02d86463          	bltu	a6,a3,ffffffffc0202374 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0202350:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0202354:	002c169b          	slliw	a3,s8,0x2
ffffffffc0202358:	0186873b          	addw	a4,a3,s8
ffffffffc020235c:	0017171b          	slliw	a4,a4,0x1
ffffffffc0202360:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0202362:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0202366:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0202368:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc020236c:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0202370:	fed870e3          	bgeu	a6,a3,ffffffffc0202350 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0202374:	f40ddce3          	bgez	s11,ffffffffc02022cc <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0202378:	8de2                	mv	s11,s8
ffffffffc020237a:	5c7d                	li	s8,-1
ffffffffc020237c:	bf81                	j	ffffffffc02022cc <vprintfmt+0x6c>
            if (width < 0)
ffffffffc020237e:	fffdc693          	not	a3,s11
ffffffffc0202382:	96fd                	srai	a3,a3,0x3f
ffffffffc0202384:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0202388:	00144603          	lbu	a2,1(s0)
ffffffffc020238c:	2d81                	sext.w	s11,s11
ffffffffc020238e:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0202390:	bf35                	j	ffffffffc02022cc <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0202392:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0202396:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc020239a:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020239c:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc020239e:	bfd9                	j	ffffffffc0202374 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc02023a0:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02023a2:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02023a6:	01174463          	blt	a4,a7,ffffffffc02023ae <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc02023aa:	1a088e63          	beqz	a7,ffffffffc0202566 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc02023ae:	000a3603          	ld	a2,0(s4)
ffffffffc02023b2:	46c1                	li	a3,16
ffffffffc02023b4:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc02023b6:	2781                	sext.w	a5,a5
ffffffffc02023b8:	876e                	mv	a4,s11
ffffffffc02023ba:	85a6                	mv	a1,s1
ffffffffc02023bc:	854a                	mv	a0,s2
ffffffffc02023be:	e37ff0ef          	jal	ra,ffffffffc02021f4 <printnum>
            break;
ffffffffc02023c2:	bde1                	j	ffffffffc020229a <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc02023c4:	000a2503          	lw	a0,0(s4)
ffffffffc02023c8:	85a6                	mv	a1,s1
ffffffffc02023ca:	0a21                	addi	s4,s4,8
ffffffffc02023cc:	9902                	jalr	s2
            break;
ffffffffc02023ce:	b5f1                	j	ffffffffc020229a <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02023d0:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02023d2:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02023d6:	01174463          	blt	a4,a7,ffffffffc02023de <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc02023da:	18088163          	beqz	a7,ffffffffc020255c <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc02023de:	000a3603          	ld	a2,0(s4)
ffffffffc02023e2:	46a9                	li	a3,10
ffffffffc02023e4:	8a2e                	mv	s4,a1
ffffffffc02023e6:	bfc1                	j	ffffffffc02023b6 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02023e8:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc02023ec:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02023ee:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02023f0:	bdf1                	j	ffffffffc02022cc <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc02023f2:	85a6                	mv	a1,s1
ffffffffc02023f4:	02500513          	li	a0,37
ffffffffc02023f8:	9902                	jalr	s2
            break;
ffffffffc02023fa:	b545                	j	ffffffffc020229a <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02023fc:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0202400:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0202402:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0202404:	b5e1                	j	ffffffffc02022cc <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0202406:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0202408:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020240c:	01174463          	blt	a4,a7,ffffffffc0202414 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0202410:	14088163          	beqz	a7,ffffffffc0202552 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0202414:	000a3603          	ld	a2,0(s4)
ffffffffc0202418:	46a1                	li	a3,8
ffffffffc020241a:	8a2e                	mv	s4,a1
ffffffffc020241c:	bf69                	j	ffffffffc02023b6 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc020241e:	03000513          	li	a0,48
ffffffffc0202422:	85a6                	mv	a1,s1
ffffffffc0202424:	e03e                	sd	a5,0(sp)
ffffffffc0202426:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0202428:	85a6                	mv	a1,s1
ffffffffc020242a:	07800513          	li	a0,120
ffffffffc020242e:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0202430:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0202432:	6782                	ld	a5,0(sp)
ffffffffc0202434:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0202436:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc020243a:	bfb5                	j	ffffffffc02023b6 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020243c:	000a3403          	ld	s0,0(s4)
ffffffffc0202440:	008a0713          	addi	a4,s4,8
ffffffffc0202444:	e03a                	sd	a4,0(sp)
ffffffffc0202446:	14040263          	beqz	s0,ffffffffc020258a <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc020244a:	0fb05763          	blez	s11,ffffffffc0202538 <vprintfmt+0x2d8>
ffffffffc020244e:	02d00693          	li	a3,45
ffffffffc0202452:	0cd79163          	bne	a5,a3,ffffffffc0202514 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0202456:	00044783          	lbu	a5,0(s0)
ffffffffc020245a:	0007851b          	sext.w	a0,a5
ffffffffc020245e:	cf85                	beqz	a5,ffffffffc0202496 <vprintfmt+0x236>
ffffffffc0202460:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0202464:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0202468:	000c4563          	bltz	s8,ffffffffc0202472 <vprintfmt+0x212>
ffffffffc020246c:	3c7d                	addiw	s8,s8,-1
ffffffffc020246e:	036c0263          	beq	s8,s6,ffffffffc0202492 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0202472:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0202474:	0e0c8e63          	beqz	s9,ffffffffc0202570 <vprintfmt+0x310>
ffffffffc0202478:	3781                	addiw	a5,a5,-32
ffffffffc020247a:	0ef47b63          	bgeu	s0,a5,ffffffffc0202570 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc020247e:	03f00513          	li	a0,63
ffffffffc0202482:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0202484:	000a4783          	lbu	a5,0(s4)
ffffffffc0202488:	3dfd                	addiw	s11,s11,-1
ffffffffc020248a:	0a05                	addi	s4,s4,1
ffffffffc020248c:	0007851b          	sext.w	a0,a5
ffffffffc0202490:	ffe1                	bnez	a5,ffffffffc0202468 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0202492:	01b05963          	blez	s11,ffffffffc02024a4 <vprintfmt+0x244>
ffffffffc0202496:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0202498:	85a6                	mv	a1,s1
ffffffffc020249a:	02000513          	li	a0,32
ffffffffc020249e:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc02024a0:	fe0d9be3          	bnez	s11,ffffffffc0202496 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02024a4:	6a02                	ld	s4,0(sp)
ffffffffc02024a6:	bbd5                	j	ffffffffc020229a <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02024a8:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02024aa:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc02024ae:	01174463          	blt	a4,a7,ffffffffc02024b6 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc02024b2:	08088d63          	beqz	a7,ffffffffc020254c <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc02024b6:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc02024ba:	0a044d63          	bltz	s0,ffffffffc0202574 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc02024be:	8622                	mv	a2,s0
ffffffffc02024c0:	8a66                	mv	s4,s9
ffffffffc02024c2:	46a9                	li	a3,10
ffffffffc02024c4:	bdcd                	j	ffffffffc02023b6 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc02024c6:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02024ca:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc02024cc:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc02024ce:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc02024d2:	8fb5                	xor	a5,a5,a3
ffffffffc02024d4:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02024d8:	02d74163          	blt	a4,a3,ffffffffc02024fa <vprintfmt+0x29a>
ffffffffc02024dc:	00369793          	slli	a5,a3,0x3
ffffffffc02024e0:	97de                	add	a5,a5,s7
ffffffffc02024e2:	639c                	ld	a5,0(a5)
ffffffffc02024e4:	cb99                	beqz	a5,ffffffffc02024fa <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc02024e6:	86be                	mv	a3,a5
ffffffffc02024e8:	00001617          	auipc	a2,0x1
ffffffffc02024ec:	f6860613          	addi	a2,a2,-152 # ffffffffc0203450 <buddy_pmm_manager+0x740>
ffffffffc02024f0:	85a6                	mv	a1,s1
ffffffffc02024f2:	854a                	mv	a0,s2
ffffffffc02024f4:	0ce000ef          	jal	ra,ffffffffc02025c2 <printfmt>
ffffffffc02024f8:	b34d                	j	ffffffffc020229a <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc02024fa:	00001617          	auipc	a2,0x1
ffffffffc02024fe:	f4660613          	addi	a2,a2,-186 # ffffffffc0203440 <buddy_pmm_manager+0x730>
ffffffffc0202502:	85a6                	mv	a1,s1
ffffffffc0202504:	854a                	mv	a0,s2
ffffffffc0202506:	0bc000ef          	jal	ra,ffffffffc02025c2 <printfmt>
ffffffffc020250a:	bb41                	j	ffffffffc020229a <vprintfmt+0x3a>
                p = "(null)";
ffffffffc020250c:	00001417          	auipc	s0,0x1
ffffffffc0202510:	f2c40413          	addi	s0,s0,-212 # ffffffffc0203438 <buddy_pmm_manager+0x728>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0202514:	85e2                	mv	a1,s8
ffffffffc0202516:	8522                	mv	a0,s0
ffffffffc0202518:	e43e                	sd	a5,8(sp)
ffffffffc020251a:	0fc000ef          	jal	ra,ffffffffc0202616 <strnlen>
ffffffffc020251e:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0202522:	01b05b63          	blez	s11,ffffffffc0202538 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0202526:	67a2                	ld	a5,8(sp)
ffffffffc0202528:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020252c:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc020252e:	85a6                	mv	a1,s1
ffffffffc0202530:	8552                	mv	a0,s4
ffffffffc0202532:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0202534:	fe0d9ce3          	bnez	s11,ffffffffc020252c <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0202538:	00044783          	lbu	a5,0(s0)
ffffffffc020253c:	00140a13          	addi	s4,s0,1
ffffffffc0202540:	0007851b          	sext.w	a0,a5
ffffffffc0202544:	d3a5                	beqz	a5,ffffffffc02024a4 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0202546:	05e00413          	li	s0,94
ffffffffc020254a:	bf39                	j	ffffffffc0202468 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc020254c:	000a2403          	lw	s0,0(s4)
ffffffffc0202550:	b7ad                	j	ffffffffc02024ba <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0202552:	000a6603          	lwu	a2,0(s4)
ffffffffc0202556:	46a1                	li	a3,8
ffffffffc0202558:	8a2e                	mv	s4,a1
ffffffffc020255a:	bdb1                	j	ffffffffc02023b6 <vprintfmt+0x156>
ffffffffc020255c:	000a6603          	lwu	a2,0(s4)
ffffffffc0202560:	46a9                	li	a3,10
ffffffffc0202562:	8a2e                	mv	s4,a1
ffffffffc0202564:	bd89                	j	ffffffffc02023b6 <vprintfmt+0x156>
ffffffffc0202566:	000a6603          	lwu	a2,0(s4)
ffffffffc020256a:	46c1                	li	a3,16
ffffffffc020256c:	8a2e                	mv	s4,a1
ffffffffc020256e:	b5a1                	j	ffffffffc02023b6 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0202570:	9902                	jalr	s2
ffffffffc0202572:	bf09                	j	ffffffffc0202484 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0202574:	85a6                	mv	a1,s1
ffffffffc0202576:	02d00513          	li	a0,45
ffffffffc020257a:	e03e                	sd	a5,0(sp)
ffffffffc020257c:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc020257e:	6782                	ld	a5,0(sp)
ffffffffc0202580:	8a66                	mv	s4,s9
ffffffffc0202582:	40800633          	neg	a2,s0
ffffffffc0202586:	46a9                	li	a3,10
ffffffffc0202588:	b53d                	j	ffffffffc02023b6 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc020258a:	03b05163          	blez	s11,ffffffffc02025ac <vprintfmt+0x34c>
ffffffffc020258e:	02d00693          	li	a3,45
ffffffffc0202592:	f6d79de3          	bne	a5,a3,ffffffffc020250c <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0202596:	00001417          	auipc	s0,0x1
ffffffffc020259a:	ea240413          	addi	s0,s0,-350 # ffffffffc0203438 <buddy_pmm_manager+0x728>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020259e:	02800793          	li	a5,40
ffffffffc02025a2:	02800513          	li	a0,40
ffffffffc02025a6:	00140a13          	addi	s4,s0,1
ffffffffc02025aa:	bd6d                	j	ffffffffc0202464 <vprintfmt+0x204>
ffffffffc02025ac:	00001a17          	auipc	s4,0x1
ffffffffc02025b0:	e8da0a13          	addi	s4,s4,-371 # ffffffffc0203439 <buddy_pmm_manager+0x729>
ffffffffc02025b4:	02800513          	li	a0,40
ffffffffc02025b8:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02025bc:	05e00413          	li	s0,94
ffffffffc02025c0:	b565                	j	ffffffffc0202468 <vprintfmt+0x208>

ffffffffc02025c2 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02025c2:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc02025c4:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02025c8:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02025ca:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02025cc:	ec06                	sd	ra,24(sp)
ffffffffc02025ce:	f83a                	sd	a4,48(sp)
ffffffffc02025d0:	fc3e                	sd	a5,56(sp)
ffffffffc02025d2:	e0c2                	sd	a6,64(sp)
ffffffffc02025d4:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02025d6:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02025d8:	c89ff0ef          	jal	ra,ffffffffc0202260 <vprintfmt>
}
ffffffffc02025dc:	60e2                	ld	ra,24(sp)
ffffffffc02025de:	6161                	addi	sp,sp,80
ffffffffc02025e0:	8082                	ret

ffffffffc02025e2 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc02025e2:	4781                	li	a5,0
ffffffffc02025e4:	00005717          	auipc	a4,0x5
ffffffffc02025e8:	a3473703          	ld	a4,-1484(a4) # ffffffffc0207018 <SBI_CONSOLE_PUTCHAR>
ffffffffc02025ec:	88ba                	mv	a7,a4
ffffffffc02025ee:	852a                	mv	a0,a0
ffffffffc02025f0:	85be                	mv	a1,a5
ffffffffc02025f2:	863e                	mv	a2,a5
ffffffffc02025f4:	00000073          	ecall
ffffffffc02025f8:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc02025fa:	8082                	ret

ffffffffc02025fc <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc02025fc:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0202600:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0202602:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0202604:	cb81                	beqz	a5,ffffffffc0202614 <strlen+0x18>
        cnt ++;
ffffffffc0202606:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0202608:	00a707b3          	add	a5,a4,a0
ffffffffc020260c:	0007c783          	lbu	a5,0(a5)
ffffffffc0202610:	fbfd                	bnez	a5,ffffffffc0202606 <strlen+0xa>
ffffffffc0202612:	8082                	ret
    }
    return cnt;
}
ffffffffc0202614:	8082                	ret

ffffffffc0202616 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0202616:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0202618:	e589                	bnez	a1,ffffffffc0202622 <strnlen+0xc>
ffffffffc020261a:	a811                	j	ffffffffc020262e <strnlen+0x18>
        cnt ++;
ffffffffc020261c:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc020261e:	00f58863          	beq	a1,a5,ffffffffc020262e <strnlen+0x18>
ffffffffc0202622:	00f50733          	add	a4,a0,a5
ffffffffc0202626:	00074703          	lbu	a4,0(a4)
ffffffffc020262a:	fb6d                	bnez	a4,ffffffffc020261c <strnlen+0x6>
ffffffffc020262c:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc020262e:	852e                	mv	a0,a1
ffffffffc0202630:	8082                	ret

ffffffffc0202632 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0202632:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0202636:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020263a:	cb89                	beqz	a5,ffffffffc020264c <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc020263c:	0505                	addi	a0,a0,1
ffffffffc020263e:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0202640:	fee789e3          	beq	a5,a4,ffffffffc0202632 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0202644:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0202648:	9d19                	subw	a0,a0,a4
ffffffffc020264a:	8082                	ret
ffffffffc020264c:	4501                	li	a0,0
ffffffffc020264e:	bfed                	j	ffffffffc0202648 <strcmp+0x16>

ffffffffc0202650 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0202650:	c20d                	beqz	a2,ffffffffc0202672 <strncmp+0x22>
ffffffffc0202652:	962e                	add	a2,a2,a1
ffffffffc0202654:	a031                	j	ffffffffc0202660 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0202656:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0202658:	00e79a63          	bne	a5,a4,ffffffffc020266c <strncmp+0x1c>
ffffffffc020265c:	00b60b63          	beq	a2,a1,ffffffffc0202672 <strncmp+0x22>
ffffffffc0202660:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0202664:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0202666:	fff5c703          	lbu	a4,-1(a1)
ffffffffc020266a:	f7f5                	bnez	a5,ffffffffc0202656 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020266c:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0202670:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0202672:	4501                	li	a0,0
ffffffffc0202674:	8082                	ret

ffffffffc0202676 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0202676:	ca01                	beqz	a2,ffffffffc0202686 <memset+0x10>
ffffffffc0202678:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc020267a:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc020267c:	0785                	addi	a5,a5,1
ffffffffc020267e:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0202682:	fec79de3          	bne	a5,a2,ffffffffc020267c <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0202686:	8082                	ret

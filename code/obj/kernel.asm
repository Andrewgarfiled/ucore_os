
bin/kernel：     文件格式 elf64-littleriscv


Disassembly of section .text:

0000000080200000 <kern_entry>:
    80200000:	00003117          	auipc	sp,0x3
    80200004:	00010113          	mv	sp,sp
    80200008:	a009                	j	8020000a <kern_init>

000000008020000a <kern_init>:
    8020000a:	00003517          	auipc	a0,0x3
    8020000e:	ffe50513          	addi	a0,a0,-2 # 80203008 <edata>
    80200012:	00003617          	auipc	a2,0x3
    80200016:	ff660613          	addi	a2,a2,-10 # 80203008 <edata>
    8020001a:	1141                	addi	sp,sp,-16
    8020001c:	4581                	li	a1,0
    8020001e:	8e09                	sub	a2,a2,a0
    80200020:	e406                	sd	ra,8(sp)
    80200022:	49c000ef          	jal	ra,802004be <memset>
    80200026:	00000597          	auipc	a1,0x0
    8020002a:	4aa58593          	addi	a1,a1,1194 # 802004d0 <memset+0x12>
    8020002e:	00000517          	auipc	a0,0x0
    80200032:	4c250513          	addi	a0,a0,1218 # 802004f0 <memset+0x32>
    80200036:	020000ef          	jal	ra,80200056 <cprintf>
    8020003a:	a001                	j	8020003a <kern_init+0x30>

000000008020003c <cputch>:
    8020003c:	1141                	addi	sp,sp,-16
    8020003e:	e022                	sd	s0,0(sp)
    80200040:	e406                	sd	ra,8(sp)
    80200042:	842e                	mv	s0,a1
    80200044:	046000ef          	jal	ra,8020008a <cons_putc>
    80200048:	401c                	lw	a5,0(s0)
    8020004a:	60a2                	ld	ra,8(sp)
    8020004c:	2785                	addiw	a5,a5,1
    8020004e:	c01c                	sw	a5,0(s0)
    80200050:	6402                	ld	s0,0(sp)
    80200052:	0141                	addi	sp,sp,16
    80200054:	8082                	ret

0000000080200056 <cprintf>:
    80200056:	711d                	addi	sp,sp,-96
    80200058:	02810313          	addi	t1,sp,40 # 80203028 <edata+0x20>
    8020005c:	f42e                	sd	a1,40(sp)
    8020005e:	f832                	sd	a2,48(sp)
    80200060:	fc36                	sd	a3,56(sp)
    80200062:	862a                	mv	a2,a0
    80200064:	004c                	addi	a1,sp,4
    80200066:	00000517          	auipc	a0,0x0
    8020006a:	fd650513          	addi	a0,a0,-42 # 8020003c <cputch>
    8020006e:	869a                	mv	a3,t1
    80200070:	ec06                	sd	ra,24(sp)
    80200072:	e0ba                	sd	a4,64(sp)
    80200074:	e4be                	sd	a5,72(sp)
    80200076:	e8c2                	sd	a6,80(sp)
    80200078:	ecc6                	sd	a7,88(sp)
    8020007a:	e41a                	sd	t1,8(sp)
    8020007c:	c202                	sw	zero,4(sp)
    8020007e:	07e000ef          	jal	ra,802000fc <vprintfmt>
    80200082:	60e2                	ld	ra,24(sp)
    80200084:	4512                	lw	a0,4(sp)
    80200086:	6125                	addi	sp,sp,96
    80200088:	8082                	ret

000000008020008a <cons_putc>:
    8020008a:	0ff57513          	andi	a0,a0,255
    8020008e:	a6fd                	j	8020047c <sbi_console_putchar>

0000000080200090 <printnum>:
    80200090:	02069813          	slli	a6,a3,0x20
    80200094:	7179                	addi	sp,sp,-48
    80200096:	02085813          	srli	a6,a6,0x20
    8020009a:	e052                	sd	s4,0(sp)
    8020009c:	03067a33          	remu	s4,a2,a6
    802000a0:	f022                	sd	s0,32(sp)
    802000a2:	ec26                	sd	s1,24(sp)
    802000a4:	e84a                	sd	s2,16(sp)
    802000a6:	f406                	sd	ra,40(sp)
    802000a8:	e44e                	sd	s3,8(sp)
    802000aa:	84aa                	mv	s1,a0
    802000ac:	892e                	mv	s2,a1
    802000ae:	fff7041b          	addiw	s0,a4,-1
    802000b2:	2a01                	sext.w	s4,s4
    802000b4:	03067e63          	bgeu	a2,a6,802000f0 <printnum+0x60>
    802000b8:	89be                	mv	s3,a5
    802000ba:	00805763          	blez	s0,802000c8 <printnum+0x38>
    802000be:	347d                	addiw	s0,s0,-1
    802000c0:	85ca                	mv	a1,s2
    802000c2:	854e                	mv	a0,s3
    802000c4:	9482                	jalr	s1
    802000c6:	fc65                	bnez	s0,802000be <printnum+0x2e>
    802000c8:	1a02                	slli	s4,s4,0x20
    802000ca:	020a5a13          	srli	s4,s4,0x20
    802000ce:	00000797          	auipc	a5,0x0
    802000d2:	5ba78793          	addi	a5,a5,1466 # 80200688 <error_string+0x38>
    802000d6:	9a3e                	add	s4,s4,a5
    802000d8:	7402                	ld	s0,32(sp)
    802000da:	000a4503          	lbu	a0,0(s4)
    802000de:	70a2                	ld	ra,40(sp)
    802000e0:	69a2                	ld	s3,8(sp)
    802000e2:	6a02                	ld	s4,0(sp)
    802000e4:	85ca                	mv	a1,s2
    802000e6:	8326                	mv	t1,s1
    802000e8:	6942                	ld	s2,16(sp)
    802000ea:	64e2                	ld	s1,24(sp)
    802000ec:	6145                	addi	sp,sp,48
    802000ee:	8302                	jr	t1
    802000f0:	03065633          	divu	a2,a2,a6
    802000f4:	8722                	mv	a4,s0
    802000f6:	f9bff0ef          	jal	ra,80200090 <printnum>
    802000fa:	b7f9                	j	802000c8 <printnum+0x38>

00000000802000fc <vprintfmt>:
    802000fc:	7119                	addi	sp,sp,-128
    802000fe:	f4a6                	sd	s1,104(sp)
    80200100:	f0ca                	sd	s2,96(sp)
    80200102:	e8d2                	sd	s4,80(sp)
    80200104:	e4d6                	sd	s5,72(sp)
    80200106:	e0da                	sd	s6,64(sp)
    80200108:	fc5e                	sd	s7,56(sp)
    8020010a:	f862                	sd	s8,48(sp)
    8020010c:	f06a                	sd	s10,32(sp)
    8020010e:	fc86                	sd	ra,120(sp)
    80200110:	f8a2                	sd	s0,112(sp)
    80200112:	ecce                	sd	s3,88(sp)
    80200114:	f466                	sd	s9,40(sp)
    80200116:	ec6e                	sd	s11,24(sp)
    80200118:	892a                	mv	s2,a0
    8020011a:	84ae                	mv	s1,a1
    8020011c:	8d32                	mv	s10,a2
    8020011e:	8ab6                	mv	s5,a3
    80200120:	5b7d                	li	s6,-1
    80200122:	00000a17          	auipc	s4,0x0
    80200126:	3d6a0a13          	addi	s4,s4,982 # 802004f8 <memset+0x3a>
    8020012a:	05e00b93          	li	s7,94
    8020012e:	00000c17          	auipc	s8,0x0
    80200132:	522c0c13          	addi	s8,s8,1314 # 80200650 <error_string>
    80200136:	000d4503          	lbu	a0,0(s10)
    8020013a:	02500793          	li	a5,37
    8020013e:	001d0413          	addi	s0,s10,1
    80200142:	00f50e63          	beq	a0,a5,8020015e <vprintfmt+0x62>
    80200146:	c521                	beqz	a0,8020018e <vprintfmt+0x92>
    80200148:	02500993          	li	s3,37
    8020014c:	a011                	j	80200150 <vprintfmt+0x54>
    8020014e:	c121                	beqz	a0,8020018e <vprintfmt+0x92>
    80200150:	85a6                	mv	a1,s1
    80200152:	0405                	addi	s0,s0,1
    80200154:	9902                	jalr	s2
    80200156:	fff44503          	lbu	a0,-1(s0)
    8020015a:	ff351ae3          	bne	a0,s3,8020014e <vprintfmt+0x52>
    8020015e:	00044603          	lbu	a2,0(s0)
    80200162:	02000793          	li	a5,32
    80200166:	4981                	li	s3,0
    80200168:	4801                	li	a6,0
    8020016a:	5cfd                	li	s9,-1
    8020016c:	5dfd                	li	s11,-1
    8020016e:	05500593          	li	a1,85
    80200172:	4525                	li	a0,9
    80200174:	fdd6069b          	addiw	a3,a2,-35
    80200178:	0ff6f693          	andi	a3,a3,255
    8020017c:	00140d13          	addi	s10,s0,1
    80200180:	1ed5ef63          	bltu	a1,a3,8020037e <vprintfmt+0x282>
    80200184:	068a                	slli	a3,a3,0x2
    80200186:	96d2                	add	a3,a3,s4
    80200188:	4294                	lw	a3,0(a3)
    8020018a:	96d2                	add	a3,a3,s4
    8020018c:	8682                	jr	a3
    8020018e:	70e6                	ld	ra,120(sp)
    80200190:	7446                	ld	s0,112(sp)
    80200192:	74a6                	ld	s1,104(sp)
    80200194:	7906                	ld	s2,96(sp)
    80200196:	69e6                	ld	s3,88(sp)
    80200198:	6a46                	ld	s4,80(sp)
    8020019a:	6aa6                	ld	s5,72(sp)
    8020019c:	6b06                	ld	s6,64(sp)
    8020019e:	7be2                	ld	s7,56(sp)
    802001a0:	7c42                	ld	s8,48(sp)
    802001a2:	7ca2                	ld	s9,40(sp)
    802001a4:	7d02                	ld	s10,32(sp)
    802001a6:	6de2                	ld	s11,24(sp)
    802001a8:	6109                	addi	sp,sp,128
    802001aa:	8082                	ret
    802001ac:	87b2                	mv	a5,a2
    802001ae:	00144603          	lbu	a2,1(s0)
    802001b2:	846a                	mv	s0,s10
    802001b4:	b7c1                	j	80200174 <vprintfmt+0x78>
    802001b6:	000aac83          	lw	s9,0(s5)
    802001ba:	00144603          	lbu	a2,1(s0)
    802001be:	0aa1                	addi	s5,s5,8
    802001c0:	846a                	mv	s0,s10
    802001c2:	fa0dd9e3          	bgez	s11,80200174 <vprintfmt+0x78>
    802001c6:	8de6                	mv	s11,s9
    802001c8:	5cfd                	li	s9,-1
    802001ca:	b76d                	j	80200174 <vprintfmt+0x78>
    802001cc:	fffdc693          	not	a3,s11
    802001d0:	96fd                	srai	a3,a3,0x3f
    802001d2:	00ddfdb3          	and	s11,s11,a3
    802001d6:	00144603          	lbu	a2,1(s0)
    802001da:	2d81                	sext.w	s11,s11
    802001dc:	846a                	mv	s0,s10
    802001de:	bf59                	j	80200174 <vprintfmt+0x78>
    802001e0:	4705                	li	a4,1
    802001e2:	008a8593          	addi	a1,s5,8
    802001e6:	01074463          	blt	a4,a6,802001ee <vprintfmt+0xf2>
    802001ea:	22080863          	beqz	a6,8020041a <vprintfmt+0x31e>
    802001ee:	000ab603          	ld	a2,0(s5)
    802001f2:	46c1                	li	a3,16
    802001f4:	8aae                	mv	s5,a1
    802001f6:	a291                	j	8020033a <vprintfmt+0x23e>
    802001f8:	fd060c9b          	addiw	s9,a2,-48
    802001fc:	00144603          	lbu	a2,1(s0)
    80200200:	846a                	mv	s0,s10
    80200202:	fd06069b          	addiw	a3,a2,-48
    80200206:	0006089b          	sext.w	a7,a2
    8020020a:	fad56ce3          	bltu	a0,a3,802001c2 <vprintfmt+0xc6>
    8020020e:	0405                	addi	s0,s0,1
    80200210:	002c969b          	slliw	a3,s9,0x2
    80200214:	00044603          	lbu	a2,0(s0)
    80200218:	0196873b          	addw	a4,a3,s9
    8020021c:	0017171b          	slliw	a4,a4,0x1
    80200220:	0117073b          	addw	a4,a4,a7
    80200224:	fd06069b          	addiw	a3,a2,-48
    80200228:	fd070c9b          	addiw	s9,a4,-48
    8020022c:	0006089b          	sext.w	a7,a2
    80200230:	fcd57fe3          	bgeu	a0,a3,8020020e <vprintfmt+0x112>
    80200234:	b779                	j	802001c2 <vprintfmt+0xc6>
    80200236:	000aa503          	lw	a0,0(s5)
    8020023a:	85a6                	mv	a1,s1
    8020023c:	0aa1                	addi	s5,s5,8
    8020023e:	9902                	jalr	s2
    80200240:	bddd                	j	80200136 <vprintfmt+0x3a>
    80200242:	4705                	li	a4,1
    80200244:	008a8993          	addi	s3,s5,8
    80200248:	01074463          	blt	a4,a6,80200250 <vprintfmt+0x154>
    8020024c:	1c080463          	beqz	a6,80200414 <vprintfmt+0x318>
    80200250:	000ab403          	ld	s0,0(s5)
    80200254:	1c044a63          	bltz	s0,80200428 <vprintfmt+0x32c>
    80200258:	8622                	mv	a2,s0
    8020025a:	8ace                	mv	s5,s3
    8020025c:	46a9                	li	a3,10
    8020025e:	a8f1                	j	8020033a <vprintfmt+0x23e>
    80200260:	000aa783          	lw	a5,0(s5)
    80200264:	4719                	li	a4,6
    80200266:	0aa1                	addi	s5,s5,8
    80200268:	41f7d69b          	sraiw	a3,a5,0x1f
    8020026c:	8fb5                	xor	a5,a5,a3
    8020026e:	40d786bb          	subw	a3,a5,a3
    80200272:	12d74963          	blt	a4,a3,802003a4 <vprintfmt+0x2a8>
    80200276:	00369793          	slli	a5,a3,0x3
    8020027a:	97e2                	add	a5,a5,s8
    8020027c:	639c                	ld	a5,0(a5)
    8020027e:	12078363          	beqz	a5,802003a4 <vprintfmt+0x2a8>
    80200282:	86be                	mv	a3,a5
    80200284:	00000617          	auipc	a2,0x0
    80200288:	4b460613          	addi	a2,a2,1204 # 80200738 <error_string+0xe8>
    8020028c:	85a6                	mv	a1,s1
    8020028e:	854a                	mv	a0,s2
    80200290:	1cc000ef          	jal	ra,8020045c <printfmt>
    80200294:	b54d                	j	80200136 <vprintfmt+0x3a>
    80200296:	000ab603          	ld	a2,0(s5)
    8020029a:	0aa1                	addi	s5,s5,8
    8020029c:	1a060163          	beqz	a2,8020043e <vprintfmt+0x342>
    802002a0:	00160413          	addi	s0,a2,1
    802002a4:	15b05763          	blez	s11,802003f2 <vprintfmt+0x2f6>
    802002a8:	02d00593          	li	a1,45
    802002ac:	10b79d63          	bne	a5,a1,802003c6 <vprintfmt+0x2ca>
    802002b0:	00064783          	lbu	a5,0(a2)
    802002b4:	0007851b          	sext.w	a0,a5
    802002b8:	c905                	beqz	a0,802002e8 <vprintfmt+0x1ec>
    802002ba:	000cc563          	bltz	s9,802002c4 <vprintfmt+0x1c8>
    802002be:	3cfd                	addiw	s9,s9,-1
    802002c0:	036c8263          	beq	s9,s6,802002e4 <vprintfmt+0x1e8>
    802002c4:	85a6                	mv	a1,s1
    802002c6:	14098f63          	beqz	s3,80200424 <vprintfmt+0x328>
    802002ca:	3781                	addiw	a5,a5,-32
    802002cc:	14fbfc63          	bgeu	s7,a5,80200424 <vprintfmt+0x328>
    802002d0:	03f00513          	li	a0,63
    802002d4:	9902                	jalr	s2
    802002d6:	0405                	addi	s0,s0,1
    802002d8:	fff44783          	lbu	a5,-1(s0)
    802002dc:	3dfd                	addiw	s11,s11,-1
    802002de:	0007851b          	sext.w	a0,a5
    802002e2:	fd61                	bnez	a0,802002ba <vprintfmt+0x1be>
    802002e4:	e5b059e3          	blez	s11,80200136 <vprintfmt+0x3a>
    802002e8:	3dfd                	addiw	s11,s11,-1
    802002ea:	85a6                	mv	a1,s1
    802002ec:	02000513          	li	a0,32
    802002f0:	9902                	jalr	s2
    802002f2:	e40d82e3          	beqz	s11,80200136 <vprintfmt+0x3a>
    802002f6:	3dfd                	addiw	s11,s11,-1
    802002f8:	85a6                	mv	a1,s1
    802002fa:	02000513          	li	a0,32
    802002fe:	9902                	jalr	s2
    80200300:	fe0d94e3          	bnez	s11,802002e8 <vprintfmt+0x1ec>
    80200304:	bd0d                	j	80200136 <vprintfmt+0x3a>
    80200306:	4705                	li	a4,1
    80200308:	008a8593          	addi	a1,s5,8
    8020030c:	01074463          	blt	a4,a6,80200314 <vprintfmt+0x218>
    80200310:	0e080863          	beqz	a6,80200400 <vprintfmt+0x304>
    80200314:	000ab603          	ld	a2,0(s5)
    80200318:	46a1                	li	a3,8
    8020031a:	8aae                	mv	s5,a1
    8020031c:	a839                	j	8020033a <vprintfmt+0x23e>
    8020031e:	03000513          	li	a0,48
    80200322:	85a6                	mv	a1,s1
    80200324:	e03e                	sd	a5,0(sp)
    80200326:	9902                	jalr	s2
    80200328:	85a6                	mv	a1,s1
    8020032a:	07800513          	li	a0,120
    8020032e:	9902                	jalr	s2
    80200330:	0aa1                	addi	s5,s5,8
    80200332:	ff8ab603          	ld	a2,-8(s5)
    80200336:	6782                	ld	a5,0(sp)
    80200338:	46c1                	li	a3,16
    8020033a:	2781                	sext.w	a5,a5
    8020033c:	876e                	mv	a4,s11
    8020033e:	85a6                	mv	a1,s1
    80200340:	854a                	mv	a0,s2
    80200342:	d4fff0ef          	jal	ra,80200090 <printnum>
    80200346:	bbc5                	j	80200136 <vprintfmt+0x3a>
    80200348:	00144603          	lbu	a2,1(s0)
    8020034c:	2805                	addiw	a6,a6,1
    8020034e:	846a                	mv	s0,s10
    80200350:	b515                	j	80200174 <vprintfmt+0x78>
    80200352:	00144603          	lbu	a2,1(s0)
    80200356:	4985                	li	s3,1
    80200358:	846a                	mv	s0,s10
    8020035a:	bd29                	j	80200174 <vprintfmt+0x78>
    8020035c:	85a6                	mv	a1,s1
    8020035e:	02500513          	li	a0,37
    80200362:	9902                	jalr	s2
    80200364:	bbc9                	j	80200136 <vprintfmt+0x3a>
    80200366:	4705                	li	a4,1
    80200368:	008a8593          	addi	a1,s5,8
    8020036c:	01074463          	blt	a4,a6,80200374 <vprintfmt+0x278>
    80200370:	08080d63          	beqz	a6,8020040a <vprintfmt+0x30e>
    80200374:	000ab603          	ld	a2,0(s5)
    80200378:	46a9                	li	a3,10
    8020037a:	8aae                	mv	s5,a1
    8020037c:	bf7d                	j	8020033a <vprintfmt+0x23e>
    8020037e:	85a6                	mv	a1,s1
    80200380:	02500513          	li	a0,37
    80200384:	9902                	jalr	s2
    80200386:	fff44703          	lbu	a4,-1(s0)
    8020038a:	02500793          	li	a5,37
    8020038e:	8d22                	mv	s10,s0
    80200390:	daf703e3          	beq	a4,a5,80200136 <vprintfmt+0x3a>
    80200394:	02500713          	li	a4,37
    80200398:	1d7d                	addi	s10,s10,-1
    8020039a:	fffd4783          	lbu	a5,-1(s10)
    8020039e:	fee79de3          	bne	a5,a4,80200398 <vprintfmt+0x29c>
    802003a2:	bb51                	j	80200136 <vprintfmt+0x3a>
    802003a4:	00000617          	auipc	a2,0x0
    802003a8:	38460613          	addi	a2,a2,900 # 80200728 <error_string+0xd8>
    802003ac:	85a6                	mv	a1,s1
    802003ae:	854a                	mv	a0,s2
    802003b0:	0ac000ef          	jal	ra,8020045c <printfmt>
    802003b4:	b349                	j	80200136 <vprintfmt+0x3a>
    802003b6:	00000617          	auipc	a2,0x0
    802003ba:	36a60613          	addi	a2,a2,874 # 80200720 <error_string+0xd0>
    802003be:	00000417          	auipc	s0,0x0
    802003c2:	36340413          	addi	s0,s0,867 # 80200721 <error_string+0xd1>
    802003c6:	8532                	mv	a0,a2
    802003c8:	85e6                	mv	a1,s9
    802003ca:	e032                	sd	a2,0(sp)
    802003cc:	e43e                	sd	a5,8(sp)
    802003ce:	0ca000ef          	jal	ra,80200498 <strnlen>
    802003d2:	40ad8dbb          	subw	s11,s11,a0
    802003d6:	6602                	ld	a2,0(sp)
    802003d8:	01b05d63          	blez	s11,802003f2 <vprintfmt+0x2f6>
    802003dc:	67a2                	ld	a5,8(sp)
    802003de:	2781                	sext.w	a5,a5
    802003e0:	e43e                	sd	a5,8(sp)
    802003e2:	6522                	ld	a0,8(sp)
    802003e4:	85a6                	mv	a1,s1
    802003e6:	e032                	sd	a2,0(sp)
    802003e8:	3dfd                	addiw	s11,s11,-1
    802003ea:	9902                	jalr	s2
    802003ec:	6602                	ld	a2,0(sp)
    802003ee:	fe0d9ae3          	bnez	s11,802003e2 <vprintfmt+0x2e6>
    802003f2:	00064783          	lbu	a5,0(a2)
    802003f6:	0007851b          	sext.w	a0,a5
    802003fa:	ec0510e3          	bnez	a0,802002ba <vprintfmt+0x1be>
    802003fe:	bb25                	j	80200136 <vprintfmt+0x3a>
    80200400:	000ae603          	lwu	a2,0(s5)
    80200404:	46a1                	li	a3,8
    80200406:	8aae                	mv	s5,a1
    80200408:	bf0d                	j	8020033a <vprintfmt+0x23e>
    8020040a:	000ae603          	lwu	a2,0(s5)
    8020040e:	46a9                	li	a3,10
    80200410:	8aae                	mv	s5,a1
    80200412:	b725                	j	8020033a <vprintfmt+0x23e>
    80200414:	000aa403          	lw	s0,0(s5)
    80200418:	bd35                	j	80200254 <vprintfmt+0x158>
    8020041a:	000ae603          	lwu	a2,0(s5)
    8020041e:	46c1                	li	a3,16
    80200420:	8aae                	mv	s5,a1
    80200422:	bf21                	j	8020033a <vprintfmt+0x23e>
    80200424:	9902                	jalr	s2
    80200426:	bd45                	j	802002d6 <vprintfmt+0x1da>
    80200428:	85a6                	mv	a1,s1
    8020042a:	02d00513          	li	a0,45
    8020042e:	e03e                	sd	a5,0(sp)
    80200430:	9902                	jalr	s2
    80200432:	8ace                	mv	s5,s3
    80200434:	40800633          	neg	a2,s0
    80200438:	46a9                	li	a3,10
    8020043a:	6782                	ld	a5,0(sp)
    8020043c:	bdfd                	j	8020033a <vprintfmt+0x23e>
    8020043e:	01b05663          	blez	s11,8020044a <vprintfmt+0x34e>
    80200442:	02d00693          	li	a3,45
    80200446:	f6d798e3          	bne	a5,a3,802003b6 <vprintfmt+0x2ba>
    8020044a:	00000417          	auipc	s0,0x0
    8020044e:	2d740413          	addi	s0,s0,727 # 80200721 <error_string+0xd1>
    80200452:	02800513          	li	a0,40
    80200456:	02800793          	li	a5,40
    8020045a:	b585                	j	802002ba <vprintfmt+0x1be>

000000008020045c <printfmt>:
    8020045c:	715d                	addi	sp,sp,-80
    8020045e:	02810313          	addi	t1,sp,40
    80200462:	f436                	sd	a3,40(sp)
    80200464:	869a                	mv	a3,t1
    80200466:	ec06                	sd	ra,24(sp)
    80200468:	f83a                	sd	a4,48(sp)
    8020046a:	fc3e                	sd	a5,56(sp)
    8020046c:	e0c2                	sd	a6,64(sp)
    8020046e:	e4c6                	sd	a7,72(sp)
    80200470:	e41a                	sd	t1,8(sp)
    80200472:	c8bff0ef          	jal	ra,802000fc <vprintfmt>
    80200476:	60e2                	ld	ra,24(sp)
    80200478:	6161                	addi	sp,sp,80
    8020047a:	8082                	ret

000000008020047c <sbi_console_putchar>:
    8020047c:	00003797          	auipc	a5,0x3
    80200480:	b8478793          	addi	a5,a5,-1148 # 80203000 <bootstacktop>
    80200484:	6398                	ld	a4,0(a5)
    80200486:	4781                	li	a5,0
    80200488:	88ba                	mv	a7,a4
    8020048a:	852a                	mv	a0,a0
    8020048c:	85be                	mv	a1,a5
    8020048e:	863e                	mv	a2,a5
    80200490:	00000073          	ecall
    80200494:	87aa                	mv	a5,a0
    80200496:	8082                	ret

0000000080200498 <strnlen>:
    80200498:	c185                	beqz	a1,802004b8 <strnlen+0x20>
    8020049a:	00054783          	lbu	a5,0(a0)
    8020049e:	cf89                	beqz	a5,802004b8 <strnlen+0x20>
    802004a0:	4781                	li	a5,0
    802004a2:	a021                	j	802004aa <strnlen+0x12>
    802004a4:	00074703          	lbu	a4,0(a4)
    802004a8:	c711                	beqz	a4,802004b4 <strnlen+0x1c>
    802004aa:	0785                	addi	a5,a5,1
    802004ac:	00f50733          	add	a4,a0,a5
    802004b0:	fef59ae3          	bne	a1,a5,802004a4 <strnlen+0xc>
    802004b4:	853e                	mv	a0,a5
    802004b6:	8082                	ret
    802004b8:	4781                	li	a5,0
    802004ba:	853e                	mv	a0,a5
    802004bc:	8082                	ret

00000000802004be <memset>:
    802004be:	ca01                	beqz	a2,802004ce <memset+0x10>
    802004c0:	962a                	add	a2,a2,a0
    802004c2:	87aa                	mv	a5,a0
    802004c4:	0785                	addi	a5,a5,1
    802004c6:	feb78fa3          	sb	a1,-1(a5)
    802004ca:	fec79de3          	bne	a5,a2,802004c4 <memset+0x6>
    802004ce:	8082                	ret

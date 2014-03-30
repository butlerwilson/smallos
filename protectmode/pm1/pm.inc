;[GDT] 8 Bytes
; 7654321076543210765432107654321076543210765432107654321076543210
;        |       |       |       |       |       |       |       |
;   7    |   6       5   |   4       3       2   |   1       0   |
;segaddr2|   properties  | segment base address 1|segment limit 1|
;       /                \
;      /                  \
;     /                    -------
;    /                            \
;   /                              \
;  /                                \
;  |   7   6   5   4   3   2   1   0   7   6   5   4   3   2   1   0   |
;      G  D/B  0  AVL  |seg limit 2|   P   |DPL|   S   |     TYPE      |
;
;
; G(Granularity) segment granularity: 0-the granularity is Byte
;                                     1-the granularity is 4k Bytes
; D/B has three meannings
;	1. execute segment
;		D=1:data, operand code and address as 32 bits
;		D=0:data, oprand code and address as 16 bits
;	2. extentional data segment
;		B=1:the segment limit is 4G
;		B=0:the segment limit is 64k
;	3. stack segment
;		B=1:the dfefault stack oprands are 32bits
;		B=0:the stack oprands are 16bits
; AVL Keep bits
;
; P(present) 1 present the current segment is in memeory
;            0 present the current segment is not in memeory
;
; DPL(descriptor privilege level) 0, 1, 2, 3 the number is more small the
;  privilege is more big.
;
;S S=1:present the descrriptor is data/code descriptor
;   S=0:present the descriptor is system/door descriptor
;                             TYPE
; TYPE vlaue       data/code descriptor            door/system descriptor
;    0             read only                       <undefined>
;    1             read only, accessed             can use 286TSS
;    2             read and write                  LDT
;    3             read, write, accessed           busy 286TSS
;    4             read only, extend down          286 call door
;    5             read only, extend down accessed task door
;    6             read, write, extend down        286 interrupt door
;    7             read, write, extend down, accessed 286 trace door
;    8             run only                        <undefined>
;    9             run only, accessed              can use 386TSS
;    A             execute and read                <undefined>
;    B             execute, read, accessed         busy 386TSS
;    C             exectue CCS                     386 call door
;    D             extecute, CCS, accessed         <undefined>
;    E             execute, read, CSS              386 interrupt door
;    F             execute, read, CSS, accessed    386 trace door

DA_32	EQU	4000H		;0100 0000 0000 0000
DA_DPL0	EQU	00H
DA_DPL1	EQU	20H
DA_DPL2	EQU	40H
DA_DPL3	EQU	60H

;storge segment descriptor
DA_DR	EQU	90H
DA_DRW	EQU	92H
DA_DRWA	EQU	93H
DA_C	EQU	98H
DA_CR	EQU	9AH
DA_CCO	EQU	9CH
DA_CCOR	EQU	9EH

;systemsegment descriptor
DA_LDT		EQU	  82H
DA_TaskGate	EQU	  85H
DA_386TSS	EQU	  89H
DA_386CGate	EQU	  8CH
DA_386IGate	EQU	  8EH
DA_386TGate	EQU	  8FH

;selector
;  7  6  5  4  3  2  1  0  7  6  5  4  3   2  1  0
;  |                                       | RPL |
;  |       descriptor index               TI     |
;
SA_RPL0		EQU	0H
SA_RPL1		EQU	1H
SA_RPL2		EQU	2H
SA_RPL3		EQU	3H

SA_TIG		EQU	0H
SA_TIL		EQU	4H

;Descriptor
;	usage descriptor base, limit, attr
%macro Descriptor 3
	dw %2 & 0x0FFFF
	dw %1 & 0x0FFFF
	db (%1 >> 16) & 0x0FF
	dw (%3 & 0x0F0FF) | ((%2>>8) & 0x0F000)
	db (%1>>24) & 0x0FF
%endmacro ;total 8 Bytes

;Door
;	usage selector, offset, dcount, attr
%macro Gate 4
	dw %2 & 0FFFFH
	dw %1
	dw (%3 & 1Fh) | ((%4 << 8) & 0FF00h)
	dw ((%2 >> 16) & 0FFFFh)
%endmacro

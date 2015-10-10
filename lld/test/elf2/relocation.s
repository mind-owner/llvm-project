// RUN: llvm-mc -filetype=obj -triple=x86_64-pc-linux %s -o %t
// RUN: llvm-mc -filetype=obj -triple=x86_64-pc-linux %p/Inputs/shared.s -o %t2
// RUN: ld.lld2 %t2 -o %t2.so -shared
// RUN: ld.lld2 %t %t2.so -o %t3
// RUN: llvm-readobj -s  %t3 | FileCheck --check-prefix=SEC %s
// RUN: llvm-objdump -s -d %t3 | FileCheck %s
// REQUIRES: x86

// SEC:      Name: .plt
// SEC-NEXT: Type: SHT_PROGBITS
// SEC-NEXT: Flags [
// SEC-NEXT:   SHF_ALLOC
// SEC-NEXT:   SHF_EXECINSTR
// SEC-NEXT: ]
// SEC-NEXT: Address: 0x11020
// SEC-NEXT: Offset: 0x1020
// SEC-NEXT: Size: 8

// SEC:         Name: .got
// SEC-NEXT:   Type: SHT_PROGBITS
// SEC-NEXT:   Flags [
// SEC-NEXT:     SHF_ALLOC
// SEC-NEXT:     SHF_WRITE
// SEC-NEXT:   ]
// SEC-NEXT:   Address: 0x120A0
// SEC-NEXT:   Offset:
// SEC-NEXT:   Size: 16
// SEC-NEXT:   Link: 0
// SEC-NEXT:   Info: 0
// SEC-NEXT:   AddressAlignment: 8
// SEC-NEXT:   EntrySize: 0
// SEC-NEXT: }

.section       .text,"ax",@progbits,unique,1
.global _start
_start:
  call lulz

.section       .text,"ax",@progbits,unique,2
.zero 4
.global lulz
lulz:
  nop

// CHECK: Disassembly of section .text:
// CHECK-NEXT: _start:
// CHECK-NEXT:   11000:  e8 04 00 00 00   callq 4
// CHECK-NEXT:   11005:

// CHECK:      lulz:
// CHECK-NEXT:   11009:  90  nop


.section       .text2,"ax",@progbits
.global R_X86_64_32
R_X86_64_32:
  movl $R_X86_64_32, %edx

// FIXME: this would be far more self evident if llvm-objdump printed
// constants in hex.
// CHECK: Disassembly of section .text2:
// CHECK-NEXT: R_X86_64_32:
// CHECK-NEXT:  1100a: {{.*}} movl $69642, %edx

.section .R_X86_64_32S,"ax",@progbits
.global R_X86_64_32S
R_X86_64_32S:
  movq lulz - 0x100000, %rdx

// CHECK: Disassembly of section .R_X86_64_32S:
// CHECK-NEXT: R_X86_64_32S:
// CHECK-NEXT:  {{.*}}: {{.*}} movq -978935, %rdx

.section .R_X86_64_PC32,"ax",@progbits
.global R_X86_64_PC32
R_X86_64_PC32:
 call bar
// 0x11020 - (0x11017 + 5) = 4
// CHECK:      Disassembly of section .R_X86_64_PC32:
// CHECK-NEXT: R_X86_64_PC32:
// CHECK-NEXT:  11017:   e8 04 00 00 00  callq  4

.section .R_X86_64_64,"a",@progbits
.global R_X86_64_64
R_X86_64_64:
 .quad R_X86_64_64

// CHECK:      Contents of section .R_X86_64_64:
// CHECK-NEXT:   10158 58010100 00000000

.section .R_X86_64_GOTPCREL,"a",@progbits
.global R_X86_64_GOTPCREL
R_X86_64_GOTPCREL:
 .long zed@gotpcrel

// 0x120A8 - 0x10160 = 8008
// 8008 = 0x481f0000   in little endian
// CHECK:      Contents of section .R_X86_64_GOTPCREL
// CHECK-NEXT:   10160 481f0000

; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc -mtriple=riscv32 -verify-machineinstrs -global-isel < %s \
; RUN:   | FileCheck %s -check-prefix=RV32I
; RUN: llc -mtriple=riscv64 -verify-machineinstrs -global-isel < %s \
; RUN:   | FileCheck %s -check-prefix=RV64I

; Basic shift support is tested as part of ALU.ll. This file ensures that
; shifts which may not be supported natively are lowered properly.

declare i64 @llvm.fshr.i64(i64, i64, i64)
declare i128 @llvm.fshr.i128(i128, i128, i128)

define i64 @lshr64(i64 %a, i64 %b) nounwind {
; RV32I-LABEL: lshr64:
; RV32I:       # %bb.0:
; RV32I-NEXT:    li a3, 32
; RV32I-NEXT:    bltu a2, a3, .LBB0_2
; RV32I-NEXT:  # %bb.1:
; RV32I-NEXT:    srl a4, a1, a2
; RV32I-NEXT:    bnez a2, .LBB0_3
; RV32I-NEXT:    j .LBB0_4
; RV32I-NEXT:  .LBB0_2:
; RV32I-NEXT:    srl a4, a0, a2
; RV32I-NEXT:    neg a5, a2
; RV32I-NEXT:    sll a5, a1, a5
; RV32I-NEXT:    or a4, a4, a5
; RV32I-NEXT:    beqz a2, .LBB0_4
; RV32I-NEXT:  .LBB0_3:
; RV32I-NEXT:    mv a0, a4
; RV32I-NEXT:  .LBB0_4:
; RV32I-NEXT:    bltu a2, a3, .LBB0_6
; RV32I-NEXT:  # %bb.5:
; RV32I-NEXT:    li a1, 0
; RV32I-NEXT:    ret
; RV32I-NEXT:  .LBB0_6:
; RV32I-NEXT:    srl a1, a1, a2
; RV32I-NEXT:    ret
;
; RV64I-LABEL: lshr64:
; RV64I:       # %bb.0:
; RV64I-NEXT:    srl a0, a0, a1
; RV64I-NEXT:    ret
  %1 = lshr i64 %a, %b
  ret i64 %1
}

define i64 @lshr64_minsize(i64 %a, i64 %b) minsize nounwind {
; RV32I-LABEL: lshr64_minsize:
; RV32I:       # %bb.0:
; RV32I-NEXT:    li a3, 32
; RV32I-NEXT:    bltu a2, a3, .LBB1_2
; RV32I-NEXT:  # %bb.1:
; RV32I-NEXT:    srl a4, a1, a2
; RV32I-NEXT:    bnez a2, .LBB1_3
; RV32I-NEXT:    j .LBB1_4
; RV32I-NEXT:  .LBB1_2:
; RV32I-NEXT:    srl a4, a0, a2
; RV32I-NEXT:    neg a5, a2
; RV32I-NEXT:    sll a5, a1, a5
; RV32I-NEXT:    or a4, a4, a5
; RV32I-NEXT:    beqz a2, .LBB1_4
; RV32I-NEXT:  .LBB1_3:
; RV32I-NEXT:    mv a0, a4
; RV32I-NEXT:  .LBB1_4:
; RV32I-NEXT:    bltu a2, a3, .LBB1_6
; RV32I-NEXT:  # %bb.5:
; RV32I-NEXT:    li a1, 0
; RV32I-NEXT:    ret
; RV32I-NEXT:  .LBB1_6:
; RV32I-NEXT:    srl a1, a1, a2
; RV32I-NEXT:    ret
;
; RV64I-LABEL: lshr64_minsize:
; RV64I:       # %bb.0:
; RV64I-NEXT:    srl a0, a0, a1
; RV64I-NEXT:    ret
  %1 = lshr i64 %a, %b
  ret i64 %1
}

define i64 @ashr64(i64 %a, i64 %b) nounwind {
; RV32I-LABEL: ashr64:
; RV32I:       # %bb.0:
; RV32I-NEXT:    li a3, 32
; RV32I-NEXT:    bltu a2, a3, .LBB2_2
; RV32I-NEXT:  # %bb.1:
; RV32I-NEXT:    sra a4, a1, a2
; RV32I-NEXT:    bnez a2, .LBB2_3
; RV32I-NEXT:    j .LBB2_4
; RV32I-NEXT:  .LBB2_2:
; RV32I-NEXT:    srl a4, a0, a2
; RV32I-NEXT:    neg a5, a2
; RV32I-NEXT:    sll a5, a1, a5
; RV32I-NEXT:    or a4, a4, a5
; RV32I-NEXT:    beqz a2, .LBB2_4
; RV32I-NEXT:  .LBB2_3:
; RV32I-NEXT:    mv a0, a4
; RV32I-NEXT:  .LBB2_4:
; RV32I-NEXT:    bltu a2, a3, .LBB2_6
; RV32I-NEXT:  # %bb.5:
; RV32I-NEXT:    srai a1, a1, 31
; RV32I-NEXT:    ret
; RV32I-NEXT:  .LBB2_6:
; RV32I-NEXT:    sra a1, a1, a2
; RV32I-NEXT:    ret
;
; RV64I-LABEL: ashr64:
; RV64I:       # %bb.0:
; RV64I-NEXT:    sra a0, a0, a1
; RV64I-NEXT:    ret
  %1 = ashr i64 %a, %b
  ret i64 %1
}

define i64 @ashr64_minsize(i64 %a, i64 %b) minsize nounwind {
; RV32I-LABEL: ashr64_minsize:
; RV32I:       # %bb.0:
; RV32I-NEXT:    li a3, 32
; RV32I-NEXT:    bltu a2, a3, .LBB3_2
; RV32I-NEXT:  # %bb.1:
; RV32I-NEXT:    sra a4, a1, a2
; RV32I-NEXT:    bnez a2, .LBB3_3
; RV32I-NEXT:    j .LBB3_4
; RV32I-NEXT:  .LBB3_2:
; RV32I-NEXT:    srl a4, a0, a2
; RV32I-NEXT:    neg a5, a2
; RV32I-NEXT:    sll a5, a1, a5
; RV32I-NEXT:    or a4, a4, a5
; RV32I-NEXT:    beqz a2, .LBB3_4
; RV32I-NEXT:  .LBB3_3:
; RV32I-NEXT:    mv a0, a4
; RV32I-NEXT:  .LBB3_4:
; RV32I-NEXT:    bltu a2, a3, .LBB3_6
; RV32I-NEXT:  # %bb.5:
; RV32I-NEXT:    srai a1, a1, 31
; RV32I-NEXT:    ret
; RV32I-NEXT:  .LBB3_6:
; RV32I-NEXT:    sra a1, a1, a2
; RV32I-NEXT:    ret
;
; RV64I-LABEL: ashr64_minsize:
; RV64I:       # %bb.0:
; RV64I-NEXT:    sra a0, a0, a1
; RV64I-NEXT:    ret
  %1 = ashr i64 %a, %b
  ret i64 %1
}

define i64 @shl64(i64 %a, i64 %b) nounwind {
; RV32I-LABEL: shl64:
; RV32I:       # %bb.0:
; RV32I-NEXT:    mv a3, a0
; RV32I-NEXT:    li a0, 32
; RV32I-NEXT:    bltu a2, a0, .LBB4_2
; RV32I-NEXT:  # %bb.1:
; RV32I-NEXT:    li a0, 0
; RV32I-NEXT:    sll a3, a3, a2
; RV32I-NEXT:    bnez a2, .LBB4_3
; RV32I-NEXT:    j .LBB4_4
; RV32I-NEXT:  .LBB4_2:
; RV32I-NEXT:    sll a0, a3, a2
; RV32I-NEXT:    neg a4, a2
; RV32I-NEXT:    srl a3, a3, a4
; RV32I-NEXT:    sll a4, a1, a2
; RV32I-NEXT:    or a3, a3, a4
; RV32I-NEXT:    beqz a2, .LBB4_4
; RV32I-NEXT:  .LBB4_3:
; RV32I-NEXT:    mv a1, a3
; RV32I-NEXT:  .LBB4_4:
; RV32I-NEXT:    ret
;
; RV64I-LABEL: shl64:
; RV64I:       # %bb.0:
; RV64I-NEXT:    sll a0, a0, a1
; RV64I-NEXT:    ret
  %1 = shl i64 %a, %b
  ret i64 %1
}

define i64 @shl64_minsize(i64 %a, i64 %b) minsize nounwind {
; RV32I-LABEL: shl64_minsize:
; RV32I:       # %bb.0:
; RV32I-NEXT:    mv a3, a0
; RV32I-NEXT:    li a0, 32
; RV32I-NEXT:    bltu a2, a0, .LBB5_2
; RV32I-NEXT:  # %bb.1:
; RV32I-NEXT:    li a0, 0
; RV32I-NEXT:    sll a3, a3, a2
; RV32I-NEXT:    bnez a2, .LBB5_3
; RV32I-NEXT:    j .LBB5_4
; RV32I-NEXT:  .LBB5_2:
; RV32I-NEXT:    sll a0, a3, a2
; RV32I-NEXT:    neg a4, a2
; RV32I-NEXT:    srl a3, a3, a4
; RV32I-NEXT:    sll a4, a1, a2
; RV32I-NEXT:    or a3, a3, a4
; RV32I-NEXT:    beqz a2, .LBB5_4
; RV32I-NEXT:  .LBB5_3:
; RV32I-NEXT:    mv a1, a3
; RV32I-NEXT:  .LBB5_4:
; RV32I-NEXT:    ret
;
; RV64I-LABEL: shl64_minsize:
; RV64I:       # %bb.0:
; RV64I-NEXT:    sll a0, a0, a1
; RV64I-NEXT:    ret
  %1 = shl i64 %a, %b
  ret i64 %1
}

define i128 @lshr128(i128 %a, i128 %b) nounwind {
; RV32I-LABEL: lshr128:
; RV32I:       # %bb.0:
; RV32I-NEXT:    lw a2, 0(a2)
; RV32I-NEXT:    lw a3, 8(a1)
; RV32I-NEXT:    lw a7, 12(a1)
; RV32I-NEXT:    li t0, 32
; RV32I-NEXT:    srl t2, a3, a2
; RV32I-NEXT:    neg t6, a2
; RV32I-NEXT:    sll t5, a7, t6
; RV32I-NEXT:    bltu a2, t0, .LBB6_2
; RV32I-NEXT:  # %bb.1:
; RV32I-NEXT:    srl a5, a7, a2
; RV32I-NEXT:    mv a4, a3
; RV32I-NEXT:    bnez a2, .LBB6_3
; RV32I-NEXT:    j .LBB6_4
; RV32I-NEXT:  .LBB6_2:
; RV32I-NEXT:    or a5, t2, t5
; RV32I-NEXT:    mv a4, a3
; RV32I-NEXT:    beqz a2, .LBB6_4
; RV32I-NEXT:  .LBB6_3:
; RV32I-NEXT:    mv a4, a5
; RV32I-NEXT:  .LBB6_4:
; RV32I-NEXT:    lw a5, 0(a1)
; RV32I-NEXT:    lw a1, 4(a1)
; RV32I-NEXT:    bltu a2, t0, .LBB6_6
; RV32I-NEXT:  # %bb.5:
; RV32I-NEXT:    li a6, 0
; RV32I-NEXT:    srl t4, a1, a2
; RV32I-NEXT:    j .LBB6_7
; RV32I-NEXT:  .LBB6_6:
; RV32I-NEXT:    srl a6, a7, a2
; RV32I-NEXT:    srl t1, a5, a2
; RV32I-NEXT:    sll t3, a1, t6
; RV32I-NEXT:    or t4, t1, t3
; RV32I-NEXT:  .LBB6_7:
; RV32I-NEXT:    li t1, 64
; RV32I-NEXT:    mv t3, a5
; RV32I-NEXT:    beqz a2, .LBB6_9
; RV32I-NEXT:  # %bb.8:
; RV32I-NEXT:    mv t3, t4
; RV32I-NEXT:  .LBB6_9:
; RV32I-NEXT:    addi sp, sp, -16
; RV32I-NEXT:    sw s0, 12(sp) # 4-byte Folded Spill
; RV32I-NEXT:    sw s1, 8(sp) # 4-byte Folded Spill
; RV32I-NEXT:    sw s2, 4(sp) # 4-byte Folded Spill
; RV32I-NEXT:    sub s0, t1, a2
; RV32I-NEXT:    bltu a2, t0, .LBB6_12
; RV32I-NEXT:  # %bb.10:
; RV32I-NEXT:    li t4, 0
; RV32I-NEXT:    bgeu s0, t0, .LBB6_13
; RV32I-NEXT:  .LBB6_11:
; RV32I-NEXT:    sll t6, a3, t6
; RV32I-NEXT:    neg s1, s0
; RV32I-NEXT:    srl s1, a3, s1
; RV32I-NEXT:    or s2, s1, t5
; RV32I-NEXT:    j .LBB6_14
; RV32I-NEXT:  .LBB6_12:
; RV32I-NEXT:    srl t4, a1, a2
; RV32I-NEXT:    bltu s0, t0, .LBB6_11
; RV32I-NEXT:  .LBB6_13:
; RV32I-NEXT:    li t6, 0
; RV32I-NEXT:    sll s2, a3, s0
; RV32I-NEXT:  .LBB6_14:
; RV32I-NEXT:    addi s1, a2, -64
; RV32I-NEXT:    mv t5, a7
; RV32I-NEXT:    beqz s0, .LBB6_16
; RV32I-NEXT:  # %bb.15:
; RV32I-NEXT:    mv t5, s2
; RV32I-NEXT:  .LBB6_16:
; RV32I-NEXT:    bltu s1, t0, .LBB6_18
; RV32I-NEXT:  # %bb.17:
; RV32I-NEXT:    srl t2, a7, s1
; RV32I-NEXT:    bnez s1, .LBB6_19
; RV32I-NEXT:    j .LBB6_20
; RV32I-NEXT:  .LBB6_18:
; RV32I-NEXT:    neg s0, s1
; RV32I-NEXT:    sll s0, a7, s0
; RV32I-NEXT:    or t2, t2, s0
; RV32I-NEXT:    beqz s1, .LBB6_20
; RV32I-NEXT:  .LBB6_19:
; RV32I-NEXT:    mv a3, t2
; RV32I-NEXT:  .LBB6_20:
; RV32I-NEXT:    bltu s1, t0, .LBB6_22
; RV32I-NEXT:  # %bb.21:
; RV32I-NEXT:    li a7, 0
; RV32I-NEXT:    bltu a2, t1, .LBB6_23
; RV32I-NEXT:    j .LBB6_24
; RV32I-NEXT:  .LBB6_22:
; RV32I-NEXT:    srl a7, a7, a2
; RV32I-NEXT:    bgeu a2, t1, .LBB6_24
; RV32I-NEXT:  .LBB6_23:
; RV32I-NEXT:    or a3, t3, t6
; RV32I-NEXT:    or a7, t4, t5
; RV32I-NEXT:  .LBB6_24:
; RV32I-NEXT:    bnez a2, .LBB6_28
; RV32I-NEXT:  # %bb.25:
; RV32I-NEXT:    bltu a2, t1, .LBB6_27
; RV32I-NEXT:  .LBB6_26:
; RV32I-NEXT:    li a4, 0
; RV32I-NEXT:    li a6, 0
; RV32I-NEXT:  .LBB6_27:
; RV32I-NEXT:    sw a5, 0(a0)
; RV32I-NEXT:    sw a1, 4(a0)
; RV32I-NEXT:    sw a4, 8(a0)
; RV32I-NEXT:    sw a6, 12(a0)
; RV32I-NEXT:    lw s0, 12(sp) # 4-byte Folded Reload
; RV32I-NEXT:    lw s1, 8(sp) # 4-byte Folded Reload
; RV32I-NEXT:    lw s2, 4(sp) # 4-byte Folded Reload
; RV32I-NEXT:    addi sp, sp, 16
; RV32I-NEXT:    ret
; RV32I-NEXT:  .LBB6_28:
; RV32I-NEXT:    mv a5, a3
; RV32I-NEXT:    mv a1, a7
; RV32I-NEXT:    bgeu a2, t1, .LBB6_26
; RV32I-NEXT:    j .LBB6_27
;
; RV64I-LABEL: lshr128:
; RV64I:       # %bb.0:
; RV64I-NEXT:    li a3, 64
; RV64I-NEXT:    bltu a2, a3, .LBB6_2
; RV64I-NEXT:  # %bb.1:
; RV64I-NEXT:    sub a4, a2, a3
; RV64I-NEXT:    srl a4, a1, a4
; RV64I-NEXT:    bnez a2, .LBB6_3
; RV64I-NEXT:    j .LBB6_4
; RV64I-NEXT:  .LBB6_2:
; RV64I-NEXT:    srl a4, a0, a2
; RV64I-NEXT:    neg a5, a2
; RV64I-NEXT:    sll a5, a1, a5
; RV64I-NEXT:    or a4, a4, a5
; RV64I-NEXT:    beqz a2, .LBB6_4
; RV64I-NEXT:  .LBB6_3:
; RV64I-NEXT:    mv a0, a4
; RV64I-NEXT:  .LBB6_4:
; RV64I-NEXT:    bltu a2, a3, .LBB6_6
; RV64I-NEXT:  # %bb.5:
; RV64I-NEXT:    li a1, 0
; RV64I-NEXT:    ret
; RV64I-NEXT:  .LBB6_6:
; RV64I-NEXT:    srl a1, a1, a2
; RV64I-NEXT:    ret
  %1 = lshr i128 %a, %b
  ret i128 %1
}

define i128 @ashr128(i128 %a, i128 %b) nounwind {
; RV32I-LABEL: ashr128:
; RV32I:       # %bb.0:
; RV32I-NEXT:    lw a2, 0(a2)
; RV32I-NEXT:    lw a4, 8(a1)
; RV32I-NEXT:    lw a3, 12(a1)
; RV32I-NEXT:    li t0, 32
; RV32I-NEXT:    srl t2, a4, a2
; RV32I-NEXT:    neg t6, a2
; RV32I-NEXT:    sll t5, a3, t6
; RV32I-NEXT:    bltu a2, t0, .LBB7_2
; RV32I-NEXT:  # %bb.1:
; RV32I-NEXT:    sra a6, a3, a2
; RV32I-NEXT:    mv a5, a4
; RV32I-NEXT:    bnez a2, .LBB7_3
; RV32I-NEXT:    j .LBB7_4
; RV32I-NEXT:  .LBB7_2:
; RV32I-NEXT:    or a6, t2, t5
; RV32I-NEXT:    mv a5, a4
; RV32I-NEXT:    beqz a2, .LBB7_4
; RV32I-NEXT:  .LBB7_3:
; RV32I-NEXT:    mv a5, a6
; RV32I-NEXT:  .LBB7_4:
; RV32I-NEXT:    lw a6, 0(a1)
; RV32I-NEXT:    lw a1, 4(a1)
; RV32I-NEXT:    bltu a2, t0, .LBB7_6
; RV32I-NEXT:  # %bb.5:
; RV32I-NEXT:    srai a7, a3, 31
; RV32I-NEXT:    srl t4, a1, a2
; RV32I-NEXT:    j .LBB7_7
; RV32I-NEXT:  .LBB7_6:
; RV32I-NEXT:    sra a7, a3, a2
; RV32I-NEXT:    srl t1, a6, a2
; RV32I-NEXT:    sll t3, a1, t6
; RV32I-NEXT:    or t4, t1, t3
; RV32I-NEXT:  .LBB7_7:
; RV32I-NEXT:    li t1, 64
; RV32I-NEXT:    mv t3, a6
; RV32I-NEXT:    beqz a2, .LBB7_9
; RV32I-NEXT:  # %bb.8:
; RV32I-NEXT:    mv t3, t4
; RV32I-NEXT:  .LBB7_9:
; RV32I-NEXT:    addi sp, sp, -16
; RV32I-NEXT:    sw s0, 12(sp) # 4-byte Folded Spill
; RV32I-NEXT:    sw s1, 8(sp) # 4-byte Folded Spill
; RV32I-NEXT:    sw s2, 4(sp) # 4-byte Folded Spill
; RV32I-NEXT:    sub s0, t1, a2
; RV32I-NEXT:    bltu a2, t0, .LBB7_12
; RV32I-NEXT:  # %bb.10:
; RV32I-NEXT:    li t4, 0
; RV32I-NEXT:    bgeu s0, t0, .LBB7_13
; RV32I-NEXT:  .LBB7_11:
; RV32I-NEXT:    sll t6, a4, t6
; RV32I-NEXT:    neg s1, s0
; RV32I-NEXT:    srl s1, a4, s1
; RV32I-NEXT:    or s2, s1, t5
; RV32I-NEXT:    j .LBB7_14
; RV32I-NEXT:  .LBB7_12:
; RV32I-NEXT:    srl t4, a1, a2
; RV32I-NEXT:    bltu s0, t0, .LBB7_11
; RV32I-NEXT:  .LBB7_13:
; RV32I-NEXT:    li t6, 0
; RV32I-NEXT:    sll s2, a4, s0
; RV32I-NEXT:  .LBB7_14:
; RV32I-NEXT:    addi s1, a2, -64
; RV32I-NEXT:    mv t5, a3
; RV32I-NEXT:    beqz s0, .LBB7_16
; RV32I-NEXT:  # %bb.15:
; RV32I-NEXT:    mv t5, s2
; RV32I-NEXT:  .LBB7_16:
; RV32I-NEXT:    bltu s1, t0, .LBB7_18
; RV32I-NEXT:  # %bb.17:
; RV32I-NEXT:    sra t2, a3, s1
; RV32I-NEXT:    bnez s1, .LBB7_19
; RV32I-NEXT:    j .LBB7_20
; RV32I-NEXT:  .LBB7_18:
; RV32I-NEXT:    neg s0, s1
; RV32I-NEXT:    sll s0, a3, s0
; RV32I-NEXT:    or t2, t2, s0
; RV32I-NEXT:    beqz s1, .LBB7_20
; RV32I-NEXT:  .LBB7_19:
; RV32I-NEXT:    mv a4, t2
; RV32I-NEXT:  .LBB7_20:
; RV32I-NEXT:    bltu s1, t0, .LBB7_22
; RV32I-NEXT:  # %bb.21:
; RV32I-NEXT:    srai t0, a3, 31
; RV32I-NEXT:    bltu a2, t1, .LBB7_23
; RV32I-NEXT:    j .LBB7_24
; RV32I-NEXT:  .LBB7_22:
; RV32I-NEXT:    sra t0, a3, a2
; RV32I-NEXT:    bgeu a2, t1, .LBB7_24
; RV32I-NEXT:  .LBB7_23:
; RV32I-NEXT:    or a4, t3, t6
; RV32I-NEXT:    or t0, t4, t5
; RV32I-NEXT:  .LBB7_24:
; RV32I-NEXT:    bnez a2, .LBB7_28
; RV32I-NEXT:  # %bb.25:
; RV32I-NEXT:    bltu a2, t1, .LBB7_27
; RV32I-NEXT:  .LBB7_26:
; RV32I-NEXT:    srai a5, a3, 31
; RV32I-NEXT:    mv a7, a5
; RV32I-NEXT:  .LBB7_27:
; RV32I-NEXT:    sw a6, 0(a0)
; RV32I-NEXT:    sw a1, 4(a0)
; RV32I-NEXT:    sw a5, 8(a0)
; RV32I-NEXT:    sw a7, 12(a0)
; RV32I-NEXT:    lw s0, 12(sp) # 4-byte Folded Reload
; RV32I-NEXT:    lw s1, 8(sp) # 4-byte Folded Reload
; RV32I-NEXT:    lw s2, 4(sp) # 4-byte Folded Reload
; RV32I-NEXT:    addi sp, sp, 16
; RV32I-NEXT:    ret
; RV32I-NEXT:  .LBB7_28:
; RV32I-NEXT:    mv a6, a4
; RV32I-NEXT:    mv a1, t0
; RV32I-NEXT:    bgeu a2, t1, .LBB7_26
; RV32I-NEXT:    j .LBB7_27
;
; RV64I-LABEL: ashr128:
; RV64I:       # %bb.0:
; RV64I-NEXT:    li a3, 64
; RV64I-NEXT:    bltu a2, a3, .LBB7_2
; RV64I-NEXT:  # %bb.1:
; RV64I-NEXT:    sub a4, a2, a3
; RV64I-NEXT:    sra a4, a1, a4
; RV64I-NEXT:    bnez a2, .LBB7_3
; RV64I-NEXT:    j .LBB7_4
; RV64I-NEXT:  .LBB7_2:
; RV64I-NEXT:    srl a4, a0, a2
; RV64I-NEXT:    neg a5, a2
; RV64I-NEXT:    sll a5, a1, a5
; RV64I-NEXT:    or a4, a4, a5
; RV64I-NEXT:    beqz a2, .LBB7_4
; RV64I-NEXT:  .LBB7_3:
; RV64I-NEXT:    mv a0, a4
; RV64I-NEXT:  .LBB7_4:
; RV64I-NEXT:    bltu a2, a3, .LBB7_6
; RV64I-NEXT:  # %bb.5:
; RV64I-NEXT:    srai a1, a1, 63
; RV64I-NEXT:    ret
; RV64I-NEXT:  .LBB7_6:
; RV64I-NEXT:    sra a1, a1, a2
; RV64I-NEXT:    ret
  %1 = ashr i128 %a, %b
  ret i128 %1
}

define i128 @shl128(i128 %a, i128 %b) nounwind {
; RV32I-LABEL: shl128:
; RV32I:       # %bb.0:
; RV32I-NEXT:    lw a2, 0(a2)
; RV32I-NEXT:    lw a7, 0(a1)
; RV32I-NEXT:    lw a3, 4(a1)
; RV32I-NEXT:    li a6, 64
; RV32I-NEXT:    li t1, 32
; RV32I-NEXT:    neg t5, a2
; RV32I-NEXT:    srl t2, a7, t5
; RV32I-NEXT:    sll t0, a3, a2
; RV32I-NEXT:    bltu a2, t1, .LBB8_2
; RV32I-NEXT:  # %bb.1:
; RV32I-NEXT:    li a4, 0
; RV32I-NEXT:    sll t3, a7, a2
; RV32I-NEXT:    j .LBB8_3
; RV32I-NEXT:  .LBB8_2:
; RV32I-NEXT:    sll a4, a7, a2
; RV32I-NEXT:    or t3, t2, t0
; RV32I-NEXT:  .LBB8_3:
; RV32I-NEXT:    sub t4, a6, a2
; RV32I-NEXT:    mv a5, a3
; RV32I-NEXT:    beqz a2, .LBB8_5
; RV32I-NEXT:  # %bb.4:
; RV32I-NEXT:    mv a5, t3
; RV32I-NEXT:  .LBB8_5:
; RV32I-NEXT:    bltu t4, t1, .LBB8_7
; RV32I-NEXT:  # %bb.6:
; RV32I-NEXT:    srl t2, a3, t4
; RV32I-NEXT:    mv t3, a7
; RV32I-NEXT:    bnez t4, .LBB8_8
; RV32I-NEXT:    j .LBB8_9
; RV32I-NEXT:  .LBB8_7:
; RV32I-NEXT:    neg t3, t4
; RV32I-NEXT:    sll t3, a3, t3
; RV32I-NEXT:    or t2, t2, t3
; RV32I-NEXT:    mv t3, a7
; RV32I-NEXT:    beqz t4, .LBB8_9
; RV32I-NEXT:  .LBB8_8:
; RV32I-NEXT:    mv t3, t2
; RV32I-NEXT:  .LBB8_9:
; RV32I-NEXT:    bltu t4, t1, .LBB8_11
; RV32I-NEXT:  # %bb.10:
; RV32I-NEXT:    li t4, 0
; RV32I-NEXT:    j .LBB8_12
; RV32I-NEXT:  .LBB8_11:
; RV32I-NEXT:    srl t4, a3, t5
; RV32I-NEXT:  .LBB8_12:
; RV32I-NEXT:    addi sp, sp, -16
; RV32I-NEXT:    sw s0, 12(sp) # 4-byte Folded Spill
; RV32I-NEXT:    sw s1, 8(sp) # 4-byte Folded Spill
; RV32I-NEXT:    lw t2, 8(a1)
; RV32I-NEXT:    lw a1, 12(a1)
; RV32I-NEXT:    bltu a2, t1, .LBB8_14
; RV32I-NEXT:  # %bb.13:
; RV32I-NEXT:    li t6, 0
; RV32I-NEXT:    sll s1, t2, a2
; RV32I-NEXT:    j .LBB8_15
; RV32I-NEXT:  .LBB8_14:
; RV32I-NEXT:    sll t6, t2, a2
; RV32I-NEXT:    srl t5, t2, t5
; RV32I-NEXT:    sll s0, a1, a2
; RV32I-NEXT:    or s1, t5, s0
; RV32I-NEXT:  .LBB8_15:
; RV32I-NEXT:    addi s0, a2, -64
; RV32I-NEXT:    mv t5, a1
; RV32I-NEXT:    beqz a2, .LBB8_17
; RV32I-NEXT:  # %bb.16:
; RV32I-NEXT:    mv t5, s1
; RV32I-NEXT:  .LBB8_17:
; RV32I-NEXT:    bltu s0, t1, .LBB8_19
; RV32I-NEXT:  # %bb.18:
; RV32I-NEXT:    li t1, 0
; RV32I-NEXT:    sll a7, a7, s0
; RV32I-NEXT:    bnez s0, .LBB8_20
; RV32I-NEXT:    j .LBB8_21
; RV32I-NEXT:  .LBB8_19:
; RV32I-NEXT:    sll t1, a7, a2
; RV32I-NEXT:    neg s1, s0
; RV32I-NEXT:    srl a7, a7, s1
; RV32I-NEXT:    or a7, a7, t0
; RV32I-NEXT:    beqz s0, .LBB8_21
; RV32I-NEXT:  .LBB8_20:
; RV32I-NEXT:    mv a3, a7
; RV32I-NEXT:  .LBB8_21:
; RV32I-NEXT:    bltu a2, a6, .LBB8_23
; RV32I-NEXT:  # %bb.22:
; RV32I-NEXT:    li a4, 0
; RV32I-NEXT:    li a5, 0
; RV32I-NEXT:    bnez a2, .LBB8_24
; RV32I-NEXT:    j .LBB8_25
; RV32I-NEXT:  .LBB8_23:
; RV32I-NEXT:    or t1, t3, t6
; RV32I-NEXT:    or a3, t4, t5
; RV32I-NEXT:    beqz a2, .LBB8_25
; RV32I-NEXT:  .LBB8_24:
; RV32I-NEXT:    mv t2, t1
; RV32I-NEXT:    mv a1, a3
; RV32I-NEXT:  .LBB8_25:
; RV32I-NEXT:    sw a4, 0(a0)
; RV32I-NEXT:    sw a5, 4(a0)
; RV32I-NEXT:    sw t2, 8(a0)
; RV32I-NEXT:    sw a1, 12(a0)
; RV32I-NEXT:    lw s0, 12(sp) # 4-byte Folded Reload
; RV32I-NEXT:    lw s1, 8(sp) # 4-byte Folded Reload
; RV32I-NEXT:    addi sp, sp, 16
; RV32I-NEXT:    ret
;
; RV64I-LABEL: shl128:
; RV64I:       # %bb.0:
; RV64I-NEXT:    mv a3, a0
; RV64I-NEXT:    li a4, 64
; RV64I-NEXT:    bltu a2, a4, .LBB8_2
; RV64I-NEXT:  # %bb.1:
; RV64I-NEXT:    li a0, 0
; RV64I-NEXT:    sub a4, a2, a4
; RV64I-NEXT:    sll a3, a3, a4
; RV64I-NEXT:    bnez a2, .LBB8_3
; RV64I-NEXT:    j .LBB8_4
; RV64I-NEXT:  .LBB8_2:
; RV64I-NEXT:    sll a0, a3, a2
; RV64I-NEXT:    neg a4, a2
; RV64I-NEXT:    srl a3, a3, a4
; RV64I-NEXT:    sll a4, a1, a2
; RV64I-NEXT:    or a3, a3, a4
; RV64I-NEXT:    beqz a2, .LBB8_4
; RV64I-NEXT:  .LBB8_3:
; RV64I-NEXT:    mv a1, a3
; RV64I-NEXT:  .LBB8_4:
; RV64I-NEXT:    ret
  %1 = shl i128 %a, %b
  ret i128 %1
}

define i64 @fshr64_minsize(i64 %a, i64 %b) minsize nounwind {
; RV32I-LABEL: fshr64_minsize:
; RV32I:       # %bb.0:
; RV32I-NEXT:    andi a5, a2, 63
; RV32I-NEXT:    li a4, 32
; RV32I-NEXT:    bltu a5, a4, .LBB9_2
; RV32I-NEXT:  # %bb.1:
; RV32I-NEXT:    srl a6, a1, a5
; RV32I-NEXT:    j .LBB9_3
; RV32I-NEXT:  .LBB9_2:
; RV32I-NEXT:    srl a3, a0, a2
; RV32I-NEXT:    neg a6, a5
; RV32I-NEXT:    sll a6, a1, a6
; RV32I-NEXT:    or a6, a3, a6
; RV32I-NEXT:  .LBB9_3:
; RV32I-NEXT:    mv a3, a0
; RV32I-NEXT:    beqz a5, .LBB9_5
; RV32I-NEXT:  # %bb.4:
; RV32I-NEXT:    mv a3, a6
; RV32I-NEXT:  .LBB9_5:
; RV32I-NEXT:    neg a6, a2
; RV32I-NEXT:    bltu a5, a4, .LBB9_7
; RV32I-NEXT:  # %bb.6:
; RV32I-NEXT:    li a2, 0
; RV32I-NEXT:    j .LBB9_8
; RV32I-NEXT:  .LBB9_7:
; RV32I-NEXT:    srl a2, a1, a2
; RV32I-NEXT:  .LBB9_8:
; RV32I-NEXT:    andi a5, a6, 63
; RV32I-NEXT:    bltu a5, a4, .LBB9_10
; RV32I-NEXT:  # %bb.9:
; RV32I-NEXT:    li a4, 0
; RV32I-NEXT:    sll a0, a0, a5
; RV32I-NEXT:    bnez a5, .LBB9_11
; RV32I-NEXT:    j .LBB9_12
; RV32I-NEXT:  .LBB9_10:
; RV32I-NEXT:    sll a4, a0, a6
; RV32I-NEXT:    neg a7, a5
; RV32I-NEXT:    srl a0, a0, a7
; RV32I-NEXT:    sll a6, a1, a6
; RV32I-NEXT:    or a0, a0, a6
; RV32I-NEXT:    beqz a5, .LBB9_12
; RV32I-NEXT:  .LBB9_11:
; RV32I-NEXT:    mv a1, a0
; RV32I-NEXT:  .LBB9_12:
; RV32I-NEXT:    or a0, a3, a4
; RV32I-NEXT:    or a1, a2, a1
; RV32I-NEXT:    ret
;
; RV64I-LABEL: fshr64_minsize:
; RV64I:       # %bb.0:
; RV64I-NEXT:    neg a2, a1
; RV64I-NEXT:    srl a1, a0, a1
; RV64I-NEXT:    sll a0, a0, a2
; RV64I-NEXT:    or a0, a1, a0
; RV64I-NEXT:    ret
  %res = tail call i64 @llvm.fshr.i64(i64 %a, i64 %a, i64 %b)
  ret i64 %res
}

define i128 @fshr128_minsize(i128 %a, i128 %b) minsize nounwind {
; RV32I-LABEL: fshr128_minsize:
; RV32I:       # %bb.0:
; RV32I-NEXT:    lw t3, 0(a2)
; RV32I-NEXT:    lw a2, 8(a1)
; RV32I-NEXT:    lw a3, 12(a1)
; RV32I-NEXT:    andi t4, t3, 127
; RV32I-NEXT:    li a6, 32
; RV32I-NEXT:    neg t6, t4
; RV32I-NEXT:    sll t5, a3, t6
; RV32I-NEXT:    bltu t4, a6, .LBB10_2
; RV32I-NEXT:  # %bb.1:
; RV32I-NEXT:    srl a5, a3, t4
; RV32I-NEXT:    j .LBB10_3
; RV32I-NEXT:  .LBB10_2:
; RV32I-NEXT:    srl a4, a2, t3
; RV32I-NEXT:    or a5, a4, t5
; RV32I-NEXT:  .LBB10_3:
; RV32I-NEXT:    mv a4, a2
; RV32I-NEXT:    beqz t4, .LBB10_5
; RV32I-NEXT:  # %bb.4:
; RV32I-NEXT:    mv a4, a5
; RV32I-NEXT:  .LBB10_5:
; RV32I-NEXT:    lw a7, 0(a1)
; RV32I-NEXT:    lw a5, 4(a1)
; RV32I-NEXT:    bltu t4, a6, .LBB10_7
; RV32I-NEXT:  # %bb.6:
; RV32I-NEXT:    li a1, 0
; RV32I-NEXT:    srl t2, a5, t4
; RV32I-NEXT:    j .LBB10_8
; RV32I-NEXT:  .LBB10_7:
; RV32I-NEXT:    srl a1, a3, t3
; RV32I-NEXT:    srl t0, a7, t3
; RV32I-NEXT:    sll t1, a5, t6
; RV32I-NEXT:    or t2, t0, t1
; RV32I-NEXT:  .LBB10_8:
; RV32I-NEXT:    li t0, 64
; RV32I-NEXT:    mv t1, a7
; RV32I-NEXT:    beqz t4, .LBB10_10
; RV32I-NEXT:  # %bb.9:
; RV32I-NEXT:    mv t1, t2
; RV32I-NEXT:  .LBB10_10:
; RV32I-NEXT:    addi sp, sp, -32
; RV32I-NEXT:    sw s0, 28(sp) # 4-byte Folded Spill
; RV32I-NEXT:    sw s1, 24(sp) # 4-byte Folded Spill
; RV32I-NEXT:    sw s2, 20(sp) # 4-byte Folded Spill
; RV32I-NEXT:    sw s3, 16(sp) # 4-byte Folded Spill
; RV32I-NEXT:    sw s4, 12(sp) # 4-byte Folded Spill
; RV32I-NEXT:    sub s0, t0, t4
; RV32I-NEXT:    bltu t4, a6, .LBB10_13
; RV32I-NEXT:  # %bb.11:
; RV32I-NEXT:    li t2, 0
; RV32I-NEXT:    bgeu s0, a6, .LBB10_14
; RV32I-NEXT:  .LBB10_12:
; RV32I-NEXT:    sll t6, a2, t6
; RV32I-NEXT:    neg s1, s0
; RV32I-NEXT:    srl s1, a2, s1
; RV32I-NEXT:    or s2, s1, t5
; RV32I-NEXT:    j .LBB10_15
; RV32I-NEXT:  .LBB10_13:
; RV32I-NEXT:    srl t2, a5, t3
; RV32I-NEXT:    bltu s0, a6, .LBB10_12
; RV32I-NEXT:  .LBB10_14:
; RV32I-NEXT:    li t6, 0
; RV32I-NEXT:    sll s2, a2, s0
; RV32I-NEXT:  .LBB10_15:
; RV32I-NEXT:    addi s1, t4, -64
; RV32I-NEXT:    mv t5, a3
; RV32I-NEXT:    beqz s0, .LBB10_17
; RV32I-NEXT:  # %bb.16:
; RV32I-NEXT:    mv t5, s2
; RV32I-NEXT:  .LBB10_17:
; RV32I-NEXT:    bltu s1, a6, .LBB10_19
; RV32I-NEXT:  # %bb.18:
; RV32I-NEXT:    srl s2, a3, s1
; RV32I-NEXT:    j .LBB10_20
; RV32I-NEXT:  .LBB10_19:
; RV32I-NEXT:    srl s0, a2, t4
; RV32I-NEXT:    neg s2, s1
; RV32I-NEXT:    sll s2, a3, s2
; RV32I-NEXT:    or s2, s0, s2
; RV32I-NEXT:  .LBB10_20:
; RV32I-NEXT:    mv s0, a2
; RV32I-NEXT:    beqz s1, .LBB10_22
; RV32I-NEXT:  # %bb.21:
; RV32I-NEXT:    mv s0, s2
; RV32I-NEXT:  .LBB10_22:
; RV32I-NEXT:    bltu s1, a6, .LBB10_24
; RV32I-NEXT:  # %bb.23:
; RV32I-NEXT:    li s1, 0
; RV32I-NEXT:    bltu t4, t0, .LBB10_25
; RV32I-NEXT:    j .LBB10_26
; RV32I-NEXT:  .LBB10_24:
; RV32I-NEXT:    srl s1, a3, t4
; RV32I-NEXT:    bgeu t4, t0, .LBB10_26
; RV32I-NEXT:  .LBB10_25:
; RV32I-NEXT:    or s0, t1, t6
; RV32I-NEXT:    or s1, t2, t5
; RV32I-NEXT:  .LBB10_26:
; RV32I-NEXT:    mv t1, a7
; RV32I-NEXT:    mv t2, a5
; RV32I-NEXT:    beqz t4, .LBB10_28
; RV32I-NEXT:  # %bb.27:
; RV32I-NEXT:    mv t1, s0
; RV32I-NEXT:    mv t2, s1
; RV32I-NEXT:  .LBB10_28:
; RV32I-NEXT:    neg t6, t3
; RV32I-NEXT:    bltu t4, t0, .LBB10_30
; RV32I-NEXT:  # %bb.29:
; RV32I-NEXT:    li a4, 0
; RV32I-NEXT:    li a1, 0
; RV32I-NEXT:  .LBB10_30:
; RV32I-NEXT:    andi t3, t6, 127
; RV32I-NEXT:    neg s2, t3
; RV32I-NEXT:    srl s0, a7, s2
; RV32I-NEXT:    bltu t3, a6, .LBB10_32
; RV32I-NEXT:  # %bb.31:
; RV32I-NEXT:    li t4, 0
; RV32I-NEXT:    sll s3, a7, t3
; RV32I-NEXT:    j .LBB10_33
; RV32I-NEXT:  .LBB10_32:
; RV32I-NEXT:    sll t4, a7, t6
; RV32I-NEXT:    sll t5, a5, t6
; RV32I-NEXT:    or s3, s0, t5
; RV32I-NEXT:  .LBB10_33:
; RV32I-NEXT:    sub s1, t0, t3
; RV32I-NEXT:    mv t5, a5
; RV32I-NEXT:    beqz t3, .LBB10_35
; RV32I-NEXT:  # %bb.34:
; RV32I-NEXT:    mv t5, s3
; RV32I-NEXT:  .LBB10_35:
; RV32I-NEXT:    bltu s1, a6, .LBB10_37
; RV32I-NEXT:  # %bb.36:
; RV32I-NEXT:    srl s3, a5, s1
; RV32I-NEXT:    j .LBB10_38
; RV32I-NEXT:  .LBB10_37:
; RV32I-NEXT:    neg s3, s1
; RV32I-NEXT:    sll s3, a5, s3
; RV32I-NEXT:    or s3, s0, s3
; RV32I-NEXT:  .LBB10_38:
; RV32I-NEXT:    mv s0, a7
; RV32I-NEXT:    beqz s1, .LBB10_40
; RV32I-NEXT:  # %bb.39:
; RV32I-NEXT:    mv s0, s3
; RV32I-NEXT:  .LBB10_40:
; RV32I-NEXT:    bltu s1, a6, .LBB10_43
; RV32I-NEXT:  # %bb.41:
; RV32I-NEXT:    li s1, 0
; RV32I-NEXT:    bgeu t3, a6, .LBB10_44
; RV32I-NEXT:  .LBB10_42:
; RV32I-NEXT:    sll s3, a2, t6
; RV32I-NEXT:    srl s2, a2, s2
; RV32I-NEXT:    sll t6, a3, t6
; RV32I-NEXT:    or s4, s2, t6
; RV32I-NEXT:    j .LBB10_45
; RV32I-NEXT:  .LBB10_43:
; RV32I-NEXT:    srl s1, a5, s2
; RV32I-NEXT:    bltu t3, a6, .LBB10_42
; RV32I-NEXT:  .LBB10_44:
; RV32I-NEXT:    li s3, 0
; RV32I-NEXT:    sll s4, a2, t3
; RV32I-NEXT:  .LBB10_45:
; RV32I-NEXT:    addi s2, t3, -64
; RV32I-NEXT:    mv t6, a3
; RV32I-NEXT:    beqz t3, .LBB10_47
; RV32I-NEXT:  # %bb.46:
; RV32I-NEXT:    mv t6, s4
; RV32I-NEXT:  .LBB10_47:
; RV32I-NEXT:    bltu s2, a6, .LBB10_49
; RV32I-NEXT:  # %bb.48:
; RV32I-NEXT:    li a6, 0
; RV32I-NEXT:    sll a7, a7, s2
; RV32I-NEXT:    bnez s2, .LBB10_50
; RV32I-NEXT:    j .LBB10_51
; RV32I-NEXT:  .LBB10_49:
; RV32I-NEXT:    sll a6, a7, t3
; RV32I-NEXT:    neg s4, s2
; RV32I-NEXT:    srl a7, a7, s4
; RV32I-NEXT:    sll s4, a5, t3
; RV32I-NEXT:    or a7, a7, s4
; RV32I-NEXT:    beqz s2, .LBB10_51
; RV32I-NEXT:  .LBB10_50:
; RV32I-NEXT:    mv a5, a7
; RV32I-NEXT:  .LBB10_51:
; RV32I-NEXT:    bltu t3, t0, .LBB10_53
; RV32I-NEXT:  # %bb.52:
; RV32I-NEXT:    li t4, 0
; RV32I-NEXT:    li t5, 0
; RV32I-NEXT:    bnez t3, .LBB10_54
; RV32I-NEXT:    j .LBB10_55
; RV32I-NEXT:  .LBB10_53:
; RV32I-NEXT:    or a6, s0, s3
; RV32I-NEXT:    or a5, s1, t6
; RV32I-NEXT:    beqz t3, .LBB10_55
; RV32I-NEXT:  .LBB10_54:
; RV32I-NEXT:    mv a2, a6
; RV32I-NEXT:    mv a3, a5
; RV32I-NEXT:  .LBB10_55:
; RV32I-NEXT:    or a5, t1, t4
; RV32I-NEXT:    or a6, t2, t5
; RV32I-NEXT:    or a2, a4, a2
; RV32I-NEXT:    or a1, a1, a3
; RV32I-NEXT:    sw a5, 0(a0)
; RV32I-NEXT:    sw a6, 4(a0)
; RV32I-NEXT:    sw a2, 8(a0)
; RV32I-NEXT:    sw a1, 12(a0)
; RV32I-NEXT:    lw s0, 28(sp) # 4-byte Folded Reload
; RV32I-NEXT:    lw s1, 24(sp) # 4-byte Folded Reload
; RV32I-NEXT:    lw s2, 20(sp) # 4-byte Folded Reload
; RV32I-NEXT:    lw s3, 16(sp) # 4-byte Folded Reload
; RV32I-NEXT:    lw s4, 12(sp) # 4-byte Folded Reload
; RV32I-NEXT:    addi sp, sp, 32
; RV32I-NEXT:    ret
;
; RV64I-LABEL: fshr128_minsize:
; RV64I:       # %bb.0:
; RV64I-NEXT:    andi a5, a2, 127
; RV64I-NEXT:    li a4, 64
; RV64I-NEXT:    bltu a5, a4, .LBB10_2
; RV64I-NEXT:  # %bb.1:
; RV64I-NEXT:    sub a3, a5, a4
; RV64I-NEXT:    srl a6, a1, a3
; RV64I-NEXT:    j .LBB10_3
; RV64I-NEXT:  .LBB10_2:
; RV64I-NEXT:    srl a3, a0, a2
; RV64I-NEXT:    neg a6, a5
; RV64I-NEXT:    sll a6, a1, a6
; RV64I-NEXT:    or a6, a3, a6
; RV64I-NEXT:  .LBB10_3:
; RV64I-NEXT:    mv a3, a0
; RV64I-NEXT:    beqz a5, .LBB10_5
; RV64I-NEXT:  # %bb.4:
; RV64I-NEXT:    mv a3, a6
; RV64I-NEXT:  .LBB10_5:
; RV64I-NEXT:    neg a7, a2
; RV64I-NEXT:    bltu a5, a4, .LBB10_7
; RV64I-NEXT:  # %bb.6:
; RV64I-NEXT:    li a2, 0
; RV64I-NEXT:    j .LBB10_8
; RV64I-NEXT:  .LBB10_7:
; RV64I-NEXT:    srl a2, a1, a2
; RV64I-NEXT:  .LBB10_8:
; RV64I-NEXT:    andi a6, a7, 127
; RV64I-NEXT:    bltu a6, a4, .LBB10_10
; RV64I-NEXT:  # %bb.9:
; RV64I-NEXT:    li a5, 0
; RV64I-NEXT:    sub a4, a6, a4
; RV64I-NEXT:    sll a0, a0, a4
; RV64I-NEXT:    bnez a6, .LBB10_11
; RV64I-NEXT:    j .LBB10_12
; RV64I-NEXT:  .LBB10_10:
; RV64I-NEXT:    sll a5, a0, a7
; RV64I-NEXT:    neg a4, a6
; RV64I-NEXT:    srl a0, a0, a4
; RV64I-NEXT:    sll a4, a1, a7
; RV64I-NEXT:    or a0, a0, a4
; RV64I-NEXT:    beqz a6, .LBB10_12
; RV64I-NEXT:  .LBB10_11:
; RV64I-NEXT:    mv a1, a0
; RV64I-NEXT:  .LBB10_12:
; RV64I-NEXT:    or a0, a3, a5
; RV64I-NEXT:    or a1, a2, a1
; RV64I-NEXT:    ret
  %res = tail call i128 @llvm.fshr.i128(i128 %a, i128 %a, i128 %b)
  ret i128 %res
}

; NOTE: Assertions have been autogenerated by utils/update_mir_test_checks.py
; RUN: llc -O0 -mtriple=mipsel-linux-gnu -global-isel -stop-after=irtranslator -verify-machineinstrs %s -o - | FileCheck %s -check-prefixes=MIPS32

%struct.S = type { i32, i32 }

define void @ZeroInit(ptr noalias sret(%struct.S) %agg.result) {
  ; MIPS32-LABEL: name: ZeroInit
  ; MIPS32: bb.1.entry:
  ; MIPS32-NEXT:   liveins: $a0
  ; MIPS32-NEXT: {{  $}}
  ; MIPS32-NEXT:   [[COPY:%[0-9]+]]:_(p0) = COPY $a0
  ; MIPS32-NEXT:   [[C:%[0-9]+]]:_(s32) = G_CONSTANT i32 0
  ; MIPS32-NEXT:   [[COPY1:%[0-9]+]]:_(p0) = COPY [[COPY]](p0)
  ; MIPS32-NEXT:   G_STORE [[C]](s32), [[COPY1]](p0) :: (store (s32) into %ir.x)
  ; MIPS32-NEXT:   [[C1:%[0-9]+]]:_(s32) = G_CONSTANT i32 4
  ; MIPS32-NEXT:   %4:_(p0) = nuw nusw inbounds G_PTR_ADD [[COPY]], [[C1]](s32)
  ; MIPS32-NEXT:   G_STORE [[C]](s32), %4(p0) :: (store (s32) into %ir.y)
  ; MIPS32-NEXT:   RetRA
entry:
  %x = getelementptr inbounds %struct.S, ptr %agg.result, i32 0, i32 0
  store i32 0, ptr %x, align 4
  %y = getelementptr inbounds %struct.S, ptr %agg.result, i32 0, i32 1
  store i32 0, ptr %y, align 4
  ret void
}

define void @CallZeroInit(ptr noalias sret(%struct.S) %agg.result) {
  ; MIPS32-LABEL: name: CallZeroInit
  ; MIPS32: bb.1.entry:
  ; MIPS32-NEXT:   liveins: $a0
  ; MIPS32-NEXT: {{  $}}
  ; MIPS32-NEXT:   [[COPY:%[0-9]+]]:_(p0) = COPY $a0
  ; MIPS32-NEXT:   ADJCALLSTACKDOWN 16, 0, implicit-def $sp, implicit $sp
  ; MIPS32-NEXT:   $a0 = COPY [[COPY]](p0)
  ; MIPS32-NEXT:   JAL @ZeroInit, csr_o32, implicit-def $ra, implicit-def $sp, implicit $a0
  ; MIPS32-NEXT:   ADJCALLSTACKUP 16, 0, implicit-def $sp, implicit $sp
  ; MIPS32-NEXT:   RetRA
entry:
  call void @ZeroInit(ptr sret(%struct.S) %agg.result)
  ret void
}

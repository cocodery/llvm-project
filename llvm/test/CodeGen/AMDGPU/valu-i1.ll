; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py UTC_ARGS: --version 5
; RUN: llc -mtriple=amdgcn -enable-misched -asm-verbose -disable-block-placement -simplifycfg-require-and-preserve-domtree=1 < %s | FileCheck -check-prefix=SI %s

declare i32 @llvm.amdgcn.workitem.id.x() nounwind readnone

; Make sure the i1 values created by the cfg structurizer pass are
; moved using VALU instructions


; waitcnt should be inserted after exec modification
; v_mov should be after exec modification
define amdgpu_kernel void @test_if(i32 %b, ptr addrspace(1) %src, ptr addrspace(1) %dst) #1 {
; SI-LABEL: test_if:
; SI:       ; %bb.0: ; %entry
; SI-NEXT:    s_load_dword s8, s[4:5], 0x9
; SI-NEXT:    s_load_dwordx2 s[0:1], s[4:5], 0xd
; SI-NEXT:    v_cmp_lt_i32_e32 vcc, 1, v0
; SI-NEXT:    s_mov_b64 s[10:11], 0
; SI-NEXT:    s_mov_b64 s[2:3], 0
; SI-NEXT:    s_and_saveexec_b64 s[4:5], vcc
; SI-NEXT:    s_xor_b64 s[4:5], exec, s[4:5]
; SI-NEXT:    s_cbranch_execz .LBB0_3
; SI-NEXT:  ; %bb.1: ; %LeafBlock3
; SI-NEXT:    v_cmp_eq_u32_e32 vcc, 2, v0
; SI-NEXT:    s_mov_b64 s[2:3], -1
; SI-NEXT:    s_and_saveexec_b64 s[6:7], vcc
; SI-NEXT:    s_cbranch_execnz .LBB0_9
; SI-NEXT:  .LBB0_2: ; %Flow7
; SI-NEXT:    s_or_b64 exec, exec, s[6:7]
; SI-NEXT:    s_and_b64 s[2:3], s[2:3], exec
; SI-NEXT:  .LBB0_3: ; %Flow6
; SI-NEXT:    s_andn2_saveexec_b64 s[4:5], s[4:5]
; SI-NEXT:    s_cbranch_execz .LBB0_5
; SI-NEXT:  ; %bb.4: ; %LeafBlock
; SI-NEXT:    s_mov_b64 s[10:11], exec
; SI-NEXT:    v_cmp_ne_u32_e32 vcc, 1, v0
; SI-NEXT:    s_andn2_b64 s[2:3], s[2:3], exec
; SI-NEXT:    s_and_b64 s[6:7], vcc, exec
; SI-NEXT:    s_or_b64 s[2:3], s[2:3], s[6:7]
; SI-NEXT:  .LBB0_5: ; %Flow8
; SI-NEXT:    s_or_b64 exec, exec, s[4:5]
; SI-NEXT:    s_and_saveexec_b64 s[4:5], s[2:3]
; SI-NEXT:    s_xor_b64 s[2:3], exec, s[4:5]
; SI-NEXT:    s_cbranch_execnz .LBB0_10
; SI-NEXT:  .LBB0_6: ; %Flow9
; SI-NEXT:    s_or_b64 exec, exec, s[2:3]
; SI-NEXT:    s_and_saveexec_b64 s[2:3], s[10:11]
; SI-NEXT:    s_cbranch_execz .LBB0_8
; SI-NEXT:  ; %bb.7: ; %case1
; SI-NEXT:    s_waitcnt lgkmcnt(0)
; SI-NEXT:    s_ashr_i32 s9, s8, 31
; SI-NEXT:    s_mov_b32 s3, 0xf000
; SI-NEXT:    s_mov_b32 s2, 0
; SI-NEXT:    s_lshl_b64 s[4:5], s[8:9], 2
; SI-NEXT:    v_mov_b32_e32 v2, 13
; SI-NEXT:    s_waitcnt expcnt(0)
; SI-NEXT:    v_mov_b32_e32 v0, s4
; SI-NEXT:    v_mov_b32_e32 v1, s5
; SI-NEXT:    buffer_store_dword v2, v[0:1], s[0:3], 0 addr64
; SI-NEXT:  .LBB0_8: ; %end
; SI-NEXT:    s_endpgm
; SI-NEXT:  .LBB0_9: ; %case2
; SI-NEXT:    s_waitcnt lgkmcnt(0)
; SI-NEXT:    s_ashr_i32 s9, s8, 31
; SI-NEXT:    s_mov_b32 s3, 0xf000
; SI-NEXT:    s_mov_b32 s2, 0
; SI-NEXT:    s_lshl_b64 s[12:13], s[8:9], 2
; SI-NEXT:    v_mov_b32_e32 v3, 17
; SI-NEXT:    v_mov_b32_e32 v1, s12
; SI-NEXT:    v_mov_b32_e32 v2, s13
; SI-NEXT:    buffer_store_dword v3, v[1:2], s[0:3], 0 addr64
; SI-NEXT:    s_xor_b64 s[2:3], exec, -1
; SI-NEXT:    s_branch .LBB0_2
; SI-NEXT:  .LBB0_10: ; %default
; SI-NEXT:    v_cmp_ne_u32_e32 vcc, 2, v0
; SI-NEXT:    s_waitcnt lgkmcnt(0)
; SI-NEXT:    s_ashr_i32 s9, s8, 31
; SI-NEXT:    s_lshl_b64 s[4:5], s[8:9], 2
; SI-NEXT:    s_add_u32 s4, s0, s4
; SI-NEXT:    s_addc_u32 s5, s1, s5
; SI-NEXT:    s_and_saveexec_b64 s[6:7], vcc
; SI-NEXT:    s_xor_b64 s[12:13], exec, s[6:7]
; SI-NEXT:    s_cbranch_execnz .LBB0_14
; SI-NEXT:  .LBB0_11: ; %Flow
; SI-NEXT:    s_andn2_saveexec_b64 s[12:13], s[12:13]
; SI-NEXT:    s_cbranch_execz .LBB0_13
; SI-NEXT:  ; %bb.12: ; %if
; SI-NEXT:    s_mov_b32 s7, 0xf000
; SI-NEXT:    s_mov_b32 s6, -1
; SI-NEXT:    s_waitcnt expcnt(0)
; SI-NEXT:    v_mov_b32_e32 v0, 19
; SI-NEXT:    buffer_store_dword v0, off, s[4:7], 0
; SI-NEXT:  .LBB0_13: ; %Flow5
; SI-NEXT:    s_or_b64 exec, exec, s[12:13]
; SI-NEXT:    s_andn2_b64 s[10:11], s[10:11], exec
; SI-NEXT:    s_branch .LBB0_6
; SI-NEXT:  .LBB0_14: ; %else
; SI-NEXT:    s_mov_b32 s7, 0xf000
; SI-NEXT:    s_mov_b32 s6, -1
; SI-NEXT:    v_mov_b32_e32 v0, 21
; SI-NEXT:    buffer_store_dword v0, off, s[4:7], 0
; SI-NEXT:    s_branch .LBB0_11
entry:
  %tid = call i32 @llvm.amdgcn.workitem.id.x() nounwind readnone
  switch i32 %tid, label %default [
    i32 1, label %case1
    i32 2, label %case2
  ]

case1:
  %arrayidx1 = getelementptr i32, ptr addrspace(1) %dst, i32 %b
  store i32 13, ptr addrspace(1) %arrayidx1, align 4
  br label %end

case2:
  %arrayidx5 = getelementptr i32, ptr addrspace(1) %dst, i32 %b
  store i32 17, ptr addrspace(1) %arrayidx5, align 4
  br label %end

default:
  %cmp8 = icmp eq i32 %tid, 2
  %arrayidx10 = getelementptr i32, ptr addrspace(1) %dst, i32 %b
  br i1 %cmp8, label %if, label %else

if:
  store i32 19, ptr addrspace(1) %arrayidx10, align 4
  br label %end

else:
  store i32 21, ptr addrspace(1) %arrayidx10, align 4
  br label %end

end:
  ret void
}

define amdgpu_kernel void @simple_test_v_if(ptr addrspace(1) %dst, ptr addrspace(1) %src) #1 {
; SI-LABEL: simple_test_v_if:
; SI:       ; %bb.0:
; SI-NEXT:    s_mov_b32 s2, 0
; SI-NEXT:    v_cmp_ne_u32_e32 vcc, 0, v0
; SI-NEXT:    s_and_saveexec_b64 s[0:1], vcc
; SI-NEXT:    s_cbranch_execz .LBB1_2
; SI-NEXT:  ; %bb.1: ; %then
; SI-NEXT:    s_load_dwordx2 s[0:1], s[4:5], 0x9
; SI-NEXT:    s_mov_b32 s3, 0xf000
; SI-NEXT:    v_lshlrev_b32_e32 v0, 2, v0
; SI-NEXT:    v_mov_b32_e32 v1, 0
; SI-NEXT:    v_mov_b32_e32 v2, 0x3e7
; SI-NEXT:    s_waitcnt lgkmcnt(0)
; SI-NEXT:    buffer_store_dword v2, v[0:1], s[0:3], 0 addr64
; SI-NEXT:  .LBB1_2: ; %exit
; SI-NEXT:    s_endpgm
  %tid = call i32 @llvm.amdgcn.workitem.id.x() nounwind readnone
  %is.0 = icmp ne i32 %tid, 0
  br i1 %is.0, label %then, label %exit

then:
  %gep = getelementptr i32, ptr addrspace(1) %dst, i32 %tid
  store i32 999, ptr addrspace(1) %gep
  br label %exit

exit:
  ret void
}

; FIXME: It would be better to endpgm in the then block.
define amdgpu_kernel void @simple_test_v_if_ret_else_ret(ptr addrspace(1) %dst, ptr addrspace(1) %src) #1 {
; SI-LABEL: simple_test_v_if_ret_else_ret:
; SI:       ; %bb.0:
; SI-NEXT:    s_mov_b32 s2, 0
; SI-NEXT:    v_cmp_ne_u32_e32 vcc, 0, v0
; SI-NEXT:    s_and_saveexec_b64 s[0:1], vcc
; SI-NEXT:    s_cbranch_execz .LBB2_2
; SI-NEXT:  ; %bb.1: ; %then
; SI-NEXT:    s_load_dwordx2 s[0:1], s[4:5], 0x9
; SI-NEXT:    s_mov_b32 s3, 0xf000
; SI-NEXT:    v_lshlrev_b32_e32 v0, 2, v0
; SI-NEXT:    v_mov_b32_e32 v1, 0
; SI-NEXT:    v_mov_b32_e32 v2, 0x3e7
; SI-NEXT:    s_waitcnt lgkmcnt(0)
; SI-NEXT:    buffer_store_dword v2, v[0:1], s[0:3], 0 addr64
; SI-NEXT:  .LBB2_2: ; %UnifiedReturnBlock
; SI-NEXT:    s_endpgm
  %tid = call i32 @llvm.amdgcn.workitem.id.x()
  %is.0 = icmp ne i32 %tid, 0
  br i1 %is.0, label %then, label %exit

then:
  %gep = getelementptr i32, ptr addrspace(1) %dst, i32 %tid
  store i32 999, ptr addrspace(1) %gep
  ret void

exit:
  ret void
}

; Final block has more than a ret to execute. This was miscompiled
; before function exit blocks were unified since the endpgm would
; terminate the then wavefront before reaching the store.
define amdgpu_kernel void @simple_test_v_if_ret_else_code_ret(ptr addrspace(1) %dst, ptr addrspace(1) %src) #1 {
; SI-LABEL: simple_test_v_if_ret_else_code_ret:
; SI:       ; %bb.0:
; SI-NEXT:    v_cmp_eq_u32_e32 vcc, 0, v0
; SI-NEXT:    s_and_saveexec_b64 s[0:1], vcc
; SI-NEXT:    s_xor_b64 s[0:1], exec, s[0:1]
; SI-NEXT:    s_cbranch_execnz .LBB3_4
; SI-NEXT:  .LBB3_1: ; %Flow
; SI-NEXT:    s_andn2_saveexec_b64 s[0:1], s[0:1]
; SI-NEXT:    s_cbranch_execz .LBB3_3
; SI-NEXT:  ; %bb.2: ; %then
; SI-NEXT:    s_load_dwordx2 s[0:1], s[4:5], 0x9
; SI-NEXT:    s_mov_b32 s3, 0xf000
; SI-NEXT:    s_mov_b32 s2, 0
; SI-NEXT:    v_lshlrev_b32_e32 v0, 2, v0
; SI-NEXT:    v_mov_b32_e32 v1, 0
; SI-NEXT:    v_mov_b32_e32 v2, 0x3e7
; SI-NEXT:    s_waitcnt lgkmcnt(0)
; SI-NEXT:    buffer_store_dword v2, v[0:1], s[0:3], 0 addr64
; SI-NEXT:  .LBB3_3: ; %UnifiedReturnBlock
; SI-NEXT:    s_endpgm
; SI-NEXT:  .LBB3_4: ; %exit
; SI-NEXT:    v_mov_b32_e32 v0, 7
; SI-NEXT:    s_mov_b32 m0, -1
; SI-NEXT:    ds_write_b32 v0, v0
; SI-NEXT:    ; implicit-def: $vgpr0
; SI-NEXT:    s_branch .LBB3_1
  %tid = call i32 @llvm.amdgcn.workitem.id.x()
  %is.0 = icmp ne i32 %tid, 0
  br i1 %is.0, label %then, label %exit

then:
  %gep = getelementptr i32, ptr addrspace(1) %dst, i32 %tid
  store i32 999, ptr addrspace(1) %gep
  ret void

exit:
  store volatile i32 7, ptr addrspace(3) poison
  ret void
}

define amdgpu_kernel void @simple_test_v_loop(ptr addrspace(1) %dst, ptr addrspace(1) %src) #1 {
; SI-LABEL: simple_test_v_loop:
; SI:       ; %bb.0: ; %entry
; SI-NEXT:    s_mov_b32 s2, 0
; SI-NEXT:    v_cmp_ne_u32_e32 vcc, 0, v0
; SI-NEXT:    s_and_saveexec_b64 s[0:1], vcc
; SI-NEXT:    s_cbranch_execz .LBB4_3
; SI-NEXT:  ; %bb.1: ; %loop.preheader
; SI-NEXT:    s_load_dwordx4 s[8:11], s[4:5], 0x9
; SI-NEXT:    v_lshlrev_b32_e32 v0, 2, v0
; SI-NEXT:    s_mov_b64 s[0:1], 0
; SI-NEXT:    s_mov_b32 s3, 0xf000
; SI-NEXT:    s_waitcnt lgkmcnt(0)
; SI-NEXT:    v_mov_b32_e32 v1, s9
; SI-NEXT:    v_add_i32_e32 v0, vcc, s8, v0
; SI-NEXT:    v_addc_u32_e32 v1, vcc, 0, v1, vcc
; SI-NEXT:    s_mov_b32 s6, -1
; SI-NEXT:    s_mov_b32 s4, s10
; SI-NEXT:    s_mov_b32 s5, s11
; SI-NEXT:    s_mov_b32 s7, s3
; SI-NEXT:  .LBB4_2: ; %loop
; SI-NEXT:    ; =>This Inner Loop Header: Depth=1
; SI-NEXT:    s_waitcnt expcnt(0)
; SI-NEXT:    buffer_load_dword v2, off, s[4:7], 0
; SI-NEXT:    s_waitcnt vmcnt(0)
; SI-NEXT:    buffer_store_dword v2, v[0:1], s[0:3], 0 addr64
; SI-NEXT:    s_add_u32 s0, s0, 4
; SI-NEXT:    s_addc_u32 s1, s1, 0
; SI-NEXT:    s_cmpk_lg_i32 s0, 0x100
; SI-NEXT:    s_cbranch_scc1 .LBB4_2
; SI-NEXT:  .LBB4_3: ; %exit
; SI-NEXT:    s_endpgm
entry:
  %tid = call i32 @llvm.amdgcn.workitem.id.x() nounwind readnone
  %is.0 = icmp ne i32 %tid, 0
  %limit = add i32 %tid, 64
  br i1 %is.0, label %loop, label %exit

loop:
  %i = phi i32 [%tid, %entry], [%i.inc, %loop]
  %gep.src = getelementptr i32, ptr addrspace(1) %src, i32 %i
  %gep.dst = getelementptr i32, ptr addrspace(1) %dst, i32 %i
  %load = load i32, ptr addrspace(1) %src
  store i32 %load, ptr addrspace(1) %gep.dst
  %i.inc = add nsw i32 %i, 1
  %cmp = icmp eq i32 %limit, %i.inc
  br i1 %cmp, label %exit, label %loop

exit:
  ret void
}

; Load loop limit from buffer
; Branch to exit if uniformly not taken
; Initialize inner condition to false
; Clear exec bits for workitems that load -1s
define amdgpu_kernel void @multi_vcond_loop(ptr addrspace(1) noalias nocapture %arg, ptr addrspace(1) noalias nocapture readonly %arg1, ptr addrspace(1) noalias nocapture readonly %arg2, ptr addrspace(1) noalias nocapture readonly %arg3) #1 {
; SI-LABEL: multi_vcond_loop:
; SI:       ; %bb.0: ; %bb
; SI-NEXT:    s_load_dwordx2 s[8:9], s[4:5], 0xf
; SI-NEXT:    s_mov_b32 s10, 0
; SI-NEXT:    v_mov_b32_e32 v7, 0
; SI-NEXT:    s_mov_b32 s11, 0xf000
; SI-NEXT:    v_lshlrev_b32_e32 v6, 2, v0
; SI-NEXT:    s_waitcnt lgkmcnt(0)
; SI-NEXT:    buffer_load_dword v0, v[6:7], s[8:11], 0 addr64
; SI-NEXT:    s_waitcnt vmcnt(0)
; SI-NEXT:    v_cmp_lt_i32_e32 vcc, 0, v0
; SI-NEXT:    s_and_saveexec_b64 s[0:1], vcc
; SI-NEXT:    s_cbranch_execz .LBB5_5
; SI-NEXT:  ; %bb.1: ; %bb10.preheader
; SI-NEXT:    s_load_dwordx4 s[12:15], s[4:5], 0x9
; SI-NEXT:    s_load_dwordx2 s[0:1], s[4:5], 0xd
; SI-NEXT:    v_ashrrev_i32_e32 v1, 31, v0
; SI-NEXT:    s_mov_b64 s[2:3], 0
; SI-NEXT:    s_mov_b32 s8, s10
; SI-NEXT:    s_mov_b32 s9, s10
; SI-NEXT:    ; implicit-def: $sgpr4_sgpr5
; SI-NEXT:    s_waitcnt lgkmcnt(0)
; SI-NEXT:    v_mov_b32_e32 v3, s13
; SI-NEXT:    v_add_i32_e32 v2, vcc, s12, v6
; SI-NEXT:    v_addc_u32_e32 v3, vcc, 0, v3, vcc
; SI-NEXT:    v_mov_b32_e32 v5, s1
; SI-NEXT:    v_add_i32_e32 v4, vcc, s0, v6
; SI-NEXT:    v_addc_u32_e32 v5, vcc, 0, v5, vcc
; SI-NEXT:    v_mov_b32_e32 v7, s15
; SI-NEXT:    v_add_i32_e32 v6, vcc, s14, v6
; SI-NEXT:    v_addc_u32_e32 v7, vcc, 0, v7, vcc
; SI-NEXT:    s_mov_b64 s[6:7], 0
; SI-NEXT:  .LBB5_2: ; %bb10
; SI-NEXT:    ; =>This Inner Loop Header: Depth=1
; SI-NEXT:    s_waitcnt expcnt(0)
; SI-NEXT:    buffer_load_dword v8, v[6:7], s[8:11], 0 addr64
; SI-NEXT:    buffer_load_dword v9, v[4:5], s[8:11], 0 addr64
; SI-NEXT:    s_waitcnt vmcnt(1)
; SI-NEXT:    v_cmp_ne_u32_e32 vcc, -1, v8
; SI-NEXT:    s_waitcnt vmcnt(0)
; SI-NEXT:    v_cmp_ne_u32_e64 s[0:1], -1, v9
; SI-NEXT:    s_and_b64 s[12:13], vcc, s[0:1]
; SI-NEXT:    s_or_b64 s[4:5], s[4:5], exec
; SI-NEXT:    s_and_saveexec_b64 s[0:1], s[12:13]
; SI-NEXT:    s_cbranch_execz .LBB5_4
; SI-NEXT:  ; %bb.3: ; %bb20
; SI-NEXT:    ; in Loop: Header=BB5_2 Depth=1
; SI-NEXT:    v_add_i32_e32 v8, vcc, v9, v8
; SI-NEXT:    s_add_u32 s6, s6, 1
; SI-NEXT:    v_add_i32_e32 v4, vcc, 4, v4
; SI-NEXT:    v_addc_u32_e32 v5, vcc, 0, v5, vcc
; SI-NEXT:    v_add_i32_e32 v6, vcc, 4, v6
; SI-NEXT:    v_addc_u32_e32 v7, vcc, 0, v7, vcc
; SI-NEXT:    buffer_store_dword v8, v[2:3], s[8:11], 0 addr64
; SI-NEXT:    s_addc_u32 s7, s7, 0
; SI-NEXT:    v_add_i32_e32 v2, vcc, 4, v2
; SI-NEXT:    v_addc_u32_e32 v3, vcc, 0, v3, vcc
; SI-NEXT:    v_cmp_ge_i64_e32 vcc, s[6:7], v[0:1]
; SI-NEXT:    s_andn2_b64 s[4:5], s[4:5], exec
; SI-NEXT:    s_and_b64 s[12:13], vcc, exec
; SI-NEXT:    s_or_b64 s[4:5], s[4:5], s[12:13]
; SI-NEXT:  .LBB5_4: ; %Flow
; SI-NEXT:    ; in Loop: Header=BB5_2 Depth=1
; SI-NEXT:    s_or_b64 exec, exec, s[0:1]
; SI-NEXT:    s_and_b64 s[0:1], exec, s[4:5]
; SI-NEXT:    s_or_b64 s[2:3], s[0:1], s[2:3]
; SI-NEXT:    s_andn2_b64 exec, exec, s[2:3]
; SI-NEXT:    s_cbranch_execnz .LBB5_2
; SI-NEXT:  .LBB5_5: ; %bb26
; SI-NEXT:    s_endpgm
bb:
  %tmp = tail call i32 @llvm.amdgcn.workitem.id.x() #0
  %tmp4 = sext i32 %tmp to i64
  %tmp5 = getelementptr inbounds i32, ptr addrspace(1) %arg3, i64 %tmp4
  %tmp6 = load i32, ptr addrspace(1) %tmp5, align 4
  %tmp7 = icmp sgt i32 %tmp6, 0
  %tmp8 = sext i32 %tmp6 to i64
  br i1 %tmp7, label %bb10, label %bb26

bb10:                                             ; preds = %bb, %bb20
  %tmp11 = phi i64 [ %tmp23, %bb20 ], [ 0, %bb ]
  %tmp12 = add nsw i64 %tmp11, %tmp4
  %tmp13 = getelementptr inbounds i32, ptr addrspace(1) %arg1, i64 %tmp12
  %tmp14 = load i32, ptr addrspace(1) %tmp13, align 4
  %tmp15 = getelementptr inbounds i32, ptr addrspace(1) %arg2, i64 %tmp12
  %tmp16 = load i32, ptr addrspace(1) %tmp15, align 4
  %tmp17 = icmp ne i32 %tmp14, -1
  %tmp18 = icmp ne i32 %tmp16, -1
  %tmp19 = and i1 %tmp17, %tmp18
  br i1 %tmp19, label %bb20, label %bb26

bb20:                                             ; preds = %bb10
  %tmp21 = add nsw i32 %tmp16, %tmp14
  %tmp22 = getelementptr inbounds i32, ptr addrspace(1) %arg, i64 %tmp12
  store i32 %tmp21, ptr addrspace(1) %tmp22, align 4
  %tmp23 = add nuw nsw i64 %tmp11, 1
  %tmp24 = icmp slt i64 %tmp23, %tmp8
  br i1 %tmp24, label %bb10, label %bb26

bb26:                                             ; preds = %bb10, %bb20, %bb
  ret void
}

attributes #0 = { nounwind readnone }
attributes #1 = { nounwind }

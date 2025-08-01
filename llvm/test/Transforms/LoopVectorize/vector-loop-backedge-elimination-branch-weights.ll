; NOTE: Assertions have been autogenerated by utils/update_test_checks.py UTC_ARGS: --check-globals none --version 5
; RUN: opt -p loop-vectorize -force-vector-width=8 -force-vector-interleave=1 -S %s | FileCheck --check-prefixes=VF8UF1 %s
; RUN: opt -p loop-vectorize -force-vector-width=8 -force-vector-interleave=2 -S %s | FileCheck --check-prefixes=VF8UF2 %s
; RUN: opt -p loop-vectorize -force-vector-width=16 -force-vector-interleave=1 -S %s | FileCheck --check-prefixes=VF16UF1 %s

; Check if the vector loop condition can be simplified to true for a given
; VF/IC combination.
define void @test_tc_between_8_and_17(ptr %A, i64 range(i64 8, 17) %N) {
; VF8UF1-LABEL: define void @test_tc_between_8_and_17(
; VF8UF1-SAME: ptr [[A:%.*]], i64 range(i64 8, 17) [[N:%.*]]) {
; VF8UF1-NEXT:  [[ENTRY:.*]]:
; VF8UF1-NEXT:    br i1 false, label %[[SCALAR_PH:.*]], label %[[VECTOR_PH:.*]], !prof [[PROF0:![0-9]+]]
; VF8UF1:       [[VECTOR_PH]]:
; VF8UF1-NEXT:    [[N_MOD_VF:%.*]] = urem i64 [[N]], 8
; VF8UF1-NEXT:    [[N_VEC:%.*]] = sub i64 [[N]], [[N_MOD_VF]]
; VF8UF1-NEXT:    [[TMP0:%.*]] = getelementptr i8, ptr [[A]], i64 [[N_VEC]]
; VF8UF1-NEXT:    br label %[[VECTOR_BODY:.*]]
; VF8UF1:       [[VECTOR_BODY]]:
; VF8UF1-NEXT:    [[INDEX:%.*]] = phi i64 [ 0, %[[VECTOR_PH]] ], [ [[INDEX_NEXT:%.*]], %[[VECTOR_BODY]] ]
; VF8UF1-NEXT:    [[NEXT_GEP:%.*]] = getelementptr i8, ptr [[A]], i64 [[INDEX]]
; VF8UF1-NEXT:    [[WIDE_LOAD:%.*]] = load <8 x i8>, ptr [[NEXT_GEP]], align 1
; VF8UF1-NEXT:    [[TMP2:%.*]] = add nsw <8 x i8> [[WIDE_LOAD]], splat (i8 10)
; VF8UF1-NEXT:    store <8 x i8> [[TMP2]], ptr [[NEXT_GEP]], align 1
; VF8UF1-NEXT:    [[INDEX_NEXT]] = add nuw i64 [[INDEX]], 8
; VF8UF1-NEXT:    [[TMP3:%.*]] = icmp eq i64 [[INDEX_NEXT]], [[N_VEC]]
; VF8UF1-NEXT:    br i1 [[TMP3]], label %[[MIDDLE_BLOCK:.*]], label %[[VECTOR_BODY]], !prof [[PROF1:![0-9]+]], !llvm.loop [[LOOP2:![0-9]+]]
; VF8UF1:       [[MIDDLE_BLOCK]]:
; VF8UF1-NEXT:    [[CMP_N:%.*]] = icmp eq i64 [[N]], [[N_VEC]]
; VF8UF1-NEXT:    br i1 [[CMP_N]], label %[[EXIT:.*]], label %[[SCALAR_PH]], !prof [[PROF5:![0-9]+]]
; VF8UF1:       [[SCALAR_PH]]:
; VF8UF1-NEXT:    [[BC_RESUME_VAL:%.*]] = phi i64 [ [[N_VEC]], %[[MIDDLE_BLOCK]] ], [ 0, %[[ENTRY]] ]
; VF8UF1-NEXT:    [[BC_RESUME_VAL1:%.*]] = phi ptr [ [[TMP0]], %[[MIDDLE_BLOCK]] ], [ [[A]], %[[ENTRY]] ]
; VF8UF1-NEXT:    br label %[[LOOP:.*]]
; VF8UF1:       [[LOOP]]:
; VF8UF1-NEXT:    [[IV:%.*]] = phi i64 [ [[BC_RESUME_VAL]], %[[SCALAR_PH]] ], [ [[IV_NEXT:%.*]], %[[LOOP]] ]
; VF8UF1-NEXT:    [[P_SRC:%.*]] = phi ptr [ [[BC_RESUME_VAL1]], %[[SCALAR_PH]] ], [ [[P_SRC_NEXT:%.*]], %[[LOOP]] ]
; VF8UF1-NEXT:    [[P_SRC_NEXT]] = getelementptr inbounds i8, ptr [[P_SRC]], i64 1
; VF8UF1-NEXT:    [[L:%.*]] = load i8, ptr [[P_SRC]], align 1
; VF8UF1-NEXT:    [[ADD:%.*]] = add nsw i8 [[L]], 10
; VF8UF1-NEXT:    store i8 [[ADD]], ptr [[P_SRC]], align 1
; VF8UF1-NEXT:    [[IV_NEXT]] = add nsw i64 [[IV]], 1
; VF8UF1-NEXT:    [[CMP:%.*]] = icmp eq i64 [[IV_NEXT]], [[N]]
; VF8UF1-NEXT:    br i1 [[CMP]], label %[[EXIT]], label %[[LOOP]], !prof [[PROF6:![0-9]+]], !llvm.loop [[LOOP7:![0-9]+]]
; VF8UF1:       [[EXIT]]:
; VF8UF1-NEXT:    ret void
;
; VF8UF2-LABEL: define void @test_tc_between_8_and_17(
; VF8UF2-SAME: ptr [[A:%.*]], i64 range(i64 8, 17) [[N:%.*]]) {
; VF8UF2-NEXT:  [[ENTRY:.*]]:
; VF8UF2-NEXT:    [[MIN_ITERS_CHECK:%.*]] = icmp ult i64 [[N]], 16
; VF8UF2-NEXT:    br i1 [[MIN_ITERS_CHECK]], label %[[SCALAR_PH:.*]], label %[[VECTOR_PH:.*]], !prof [[PROF0:![0-9]+]]
; VF8UF2:       [[VECTOR_PH]]:
; VF8UF2-NEXT:    [[N_MOD_VF:%.*]] = urem i64 [[N]], 16
; VF8UF2-NEXT:    [[N_VEC:%.*]] = sub i64 [[N]], [[N_MOD_VF]]
; VF8UF2-NEXT:    [[TMP0:%.*]] = getelementptr i8, ptr [[A]], i64 [[N_VEC]]
; VF8UF2-NEXT:    br label %[[VECTOR_BODY:.*]]
; VF8UF2:       [[VECTOR_BODY]]:
; VF8UF2-NEXT:    [[TMP2:%.*]] = getelementptr i8, ptr [[A]], i32 8
; VF8UF2-NEXT:    [[WIDE_LOAD:%.*]] = load <8 x i8>, ptr [[A]], align 1
; VF8UF2-NEXT:    [[WIDE_LOAD1:%.*]] = load <8 x i8>, ptr [[TMP2]], align 1
; VF8UF2-NEXT:    [[TMP3:%.*]] = add nsw <8 x i8> [[WIDE_LOAD]], splat (i8 10)
; VF8UF2-NEXT:    [[TMP4:%.*]] = add nsw <8 x i8> [[WIDE_LOAD1]], splat (i8 10)
; VF8UF2-NEXT:    [[TMP6:%.*]] = getelementptr i8, ptr [[A]], i32 8
; VF8UF2-NEXT:    store <8 x i8> [[TMP3]], ptr [[A]], align 1
; VF8UF2-NEXT:    store <8 x i8> [[TMP4]], ptr [[TMP6]], align 1
; VF8UF2-NEXT:    br label %[[MIDDLE_BLOCK:.*]]
; VF8UF2:       [[MIDDLE_BLOCK]]:
; VF8UF2-NEXT:    [[CMP_N:%.*]] = icmp eq i64 [[N]], [[N_VEC]]
; VF8UF2-NEXT:    br i1 [[CMP_N]], label %[[EXIT:.*]], label %[[SCALAR_PH]], !prof [[PROF1:![0-9]+]]
; VF8UF2:       [[SCALAR_PH]]:
; VF8UF2-NEXT:    [[BC_RESUME_VAL:%.*]] = phi i64 [ [[N_VEC]], %[[MIDDLE_BLOCK]] ], [ 0, %[[ENTRY]] ]
; VF8UF2-NEXT:    [[BC_RESUME_VAL2:%.*]] = phi ptr [ [[TMP0]], %[[MIDDLE_BLOCK]] ], [ [[A]], %[[ENTRY]] ]
; VF8UF2-NEXT:    br label %[[LOOP:.*]]
; VF8UF2:       [[LOOP]]:
; VF8UF2-NEXT:    [[IV:%.*]] = phi i64 [ [[BC_RESUME_VAL]], %[[SCALAR_PH]] ], [ [[IV_NEXT:%.*]], %[[LOOP]] ]
; VF8UF2-NEXT:    [[P_SRC:%.*]] = phi ptr [ [[BC_RESUME_VAL2]], %[[SCALAR_PH]] ], [ [[P_SRC_NEXT:%.*]], %[[LOOP]] ]
; VF8UF2-NEXT:    [[P_SRC_NEXT]] = getelementptr inbounds i8, ptr [[P_SRC]], i64 1
; VF8UF2-NEXT:    [[L:%.*]] = load i8, ptr [[P_SRC]], align 1
; VF8UF2-NEXT:    [[ADD:%.*]] = add nsw i8 [[L]], 10
; VF8UF2-NEXT:    store i8 [[ADD]], ptr [[P_SRC]], align 1
; VF8UF2-NEXT:    [[IV_NEXT]] = add nsw i64 [[IV]], 1
; VF8UF2-NEXT:    [[CMP:%.*]] = icmp eq i64 [[IV_NEXT]], [[N]]
; VF8UF2-NEXT:    br i1 [[CMP]], label %[[EXIT]], label %[[LOOP]], !prof [[PROF2:![0-9]+]], !llvm.loop [[LOOP3:![0-9]+]]
; VF8UF2:       [[EXIT]]:
; VF8UF2-NEXT:    ret void
;
; VF16UF1-LABEL: define void @test_tc_between_8_and_17(
; VF16UF1-SAME: ptr [[A:%.*]], i64 range(i64 8, 17) [[N:%.*]]) {
; VF16UF1-NEXT:  [[ENTRY:.*]]:
; VF16UF1-NEXT:    [[MIN_ITERS_CHECK:%.*]] = icmp ult i64 [[N]], 16
; VF16UF1-NEXT:    br i1 [[MIN_ITERS_CHECK]], label %[[SCALAR_PH:.*]], label %[[VECTOR_PH:.*]], !prof [[PROF0:![0-9]+]]
; VF16UF1:       [[VECTOR_PH]]:
; VF16UF1-NEXT:    [[N_MOD_VF:%.*]] = urem i64 [[N]], 16
; VF16UF1-NEXT:    [[N_VEC:%.*]] = sub i64 [[N]], [[N_MOD_VF]]
; VF16UF1-NEXT:    [[TMP0:%.*]] = getelementptr i8, ptr [[A]], i64 [[N_VEC]]
; VF16UF1-NEXT:    br label %[[VECTOR_BODY:.*]]
; VF16UF1:       [[VECTOR_BODY]]:
; VF16UF1-NEXT:    [[WIDE_LOAD:%.*]] = load <16 x i8>, ptr [[A]], align 1
; VF16UF1-NEXT:    [[TMP2:%.*]] = add nsw <16 x i8> [[WIDE_LOAD]], splat (i8 10)
; VF16UF1-NEXT:    store <16 x i8> [[TMP2]], ptr [[A]], align 1
; VF16UF1-NEXT:    br label %[[MIDDLE_BLOCK:.*]]
; VF16UF1:       [[MIDDLE_BLOCK]]:
; VF16UF1-NEXT:    [[CMP_N:%.*]] = icmp eq i64 [[N]], [[N_VEC]]
; VF16UF1-NEXT:    br i1 [[CMP_N]], label %[[EXIT:.*]], label %[[SCALAR_PH]], !prof [[PROF1:![0-9]+]]
; VF16UF1:       [[SCALAR_PH]]:
; VF16UF1-NEXT:    [[BC_RESUME_VAL:%.*]] = phi i64 [ [[N_VEC]], %[[MIDDLE_BLOCK]] ], [ 0, %[[ENTRY]] ]
; VF16UF1-NEXT:    [[BC_RESUME_VAL1:%.*]] = phi ptr [ [[TMP0]], %[[MIDDLE_BLOCK]] ], [ [[A]], %[[ENTRY]] ]
; VF16UF1-NEXT:    br label %[[LOOP:.*]]
; VF16UF1:       [[LOOP]]:
; VF16UF1-NEXT:    [[IV:%.*]] = phi i64 [ [[BC_RESUME_VAL]], %[[SCALAR_PH]] ], [ [[IV_NEXT:%.*]], %[[LOOP]] ]
; VF16UF1-NEXT:    [[P_SRC:%.*]] = phi ptr [ [[BC_RESUME_VAL1]], %[[SCALAR_PH]] ], [ [[P_SRC_NEXT:%.*]], %[[LOOP]] ]
; VF16UF1-NEXT:    [[P_SRC_NEXT]] = getelementptr inbounds i8, ptr [[P_SRC]], i64 1
; VF16UF1-NEXT:    [[L:%.*]] = load i8, ptr [[P_SRC]], align 1
; VF16UF1-NEXT:    [[ADD:%.*]] = add nsw i8 [[L]], 10
; VF16UF1-NEXT:    store i8 [[ADD]], ptr [[P_SRC]], align 1
; VF16UF1-NEXT:    [[IV_NEXT]] = add nsw i64 [[IV]], 1
; VF16UF1-NEXT:    [[CMP:%.*]] = icmp eq i64 [[IV_NEXT]], [[N]]
; VF16UF1-NEXT:    br i1 [[CMP]], label %[[EXIT]], label %[[LOOP]], !prof [[PROF2:![0-9]+]], !llvm.loop [[LOOP3:![0-9]+]]
; VF16UF1:       [[EXIT]]:
; VF16UF1-NEXT:    ret void
;
entry:
  br label %loop

loop:
  %iv = phi i64 [ 0, %entry ], [ %iv.next, %loop ]
  %p.src = phi ptr [ %A, %entry ], [ %p.src.next, %loop ]
  %p.src.next = getelementptr inbounds i8, ptr %p.src, i64 1
  %l = load i8, ptr %p.src, align 1
  %add = add nsw i8 %l, 10
  store i8 %add, ptr %p.src
  %iv.next = add nsw i64 %iv, 1
  %cmp = icmp eq i64 %iv.next, %N
  br i1 %cmp, label %exit, label %loop, !prof !0

exit:
  ret void
}

!0 = !{!"branch_weights", !"expected", i32 1, i32 2000}

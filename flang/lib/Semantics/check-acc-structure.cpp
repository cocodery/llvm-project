//===-- lib/Semantics/check-acc-structure.cpp -----------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
#include "check-acc-structure.h"
#include "flang/Common/enum-set.h"
#include "flang/Evaluate/tools.h"
#include "flang/Parser/parse-tree.h"
#include "flang/Semantics/symbol.h"
#include "flang/Semantics/tools.h"
#include "flang/Semantics/type.h"
#include "flang/Support/Fortran.h"
#include "llvm/Support/AtomicOrdering.h"

#include <optional>

#define CHECK_SIMPLE_CLAUSE(X, Y) \
  void AccStructureChecker::Enter(const parser::AccClause::X &) { \
    CheckAllowed(llvm::acc::Clause::Y); \
  }

#define CHECK_REQ_SCALAR_INT_CONSTANT_CLAUSE(X, Y) \
  void AccStructureChecker::Enter(const parser::AccClause::X &c) { \
    CheckAllowed(llvm::acc::Clause::Y); \
    RequiresConstantPositiveParameter(llvm::acc::Clause::Y, c.v); \
  }

using ReductionOpsSet =
    Fortran::common::EnumSet<Fortran::parser::ReductionOperator::Operator,
        Fortran::parser::ReductionOperator::Operator_enumSize>;

static ReductionOpsSet reductionIntegerSet{
    Fortran::parser::ReductionOperator::Operator::Plus,
    Fortran::parser::ReductionOperator::Operator::Multiply,
    Fortran::parser::ReductionOperator::Operator::Max,
    Fortran::parser::ReductionOperator::Operator::Min,
    Fortran::parser::ReductionOperator::Operator::Iand,
    Fortran::parser::ReductionOperator::Operator::Ior,
    Fortran::parser::ReductionOperator::Operator::Ieor};

static ReductionOpsSet reductionRealSet{
    Fortran::parser::ReductionOperator::Operator::Plus,
    Fortran::parser::ReductionOperator::Operator::Multiply,
    Fortran::parser::ReductionOperator::Operator::Max,
    Fortran::parser::ReductionOperator::Operator::Min};

static ReductionOpsSet reductionComplexSet{
    Fortran::parser::ReductionOperator::Operator::Plus,
    Fortran::parser::ReductionOperator::Operator::Multiply};

static ReductionOpsSet reductionLogicalSet{
    Fortran::parser::ReductionOperator::Operator::And,
    Fortran::parser::ReductionOperator::Operator::Or,
    Fortran::parser::ReductionOperator::Operator::Eqv,
    Fortran::parser::ReductionOperator::Operator::Neqv};

namespace Fortran::semantics {

static constexpr inline AccClauseSet
    computeConstructOnlyAllowedAfterDeviceTypeClauses{
        llvm::acc::Clause::ACCC_async, llvm::acc::Clause::ACCC_wait,
        llvm::acc::Clause::ACCC_num_gangs, llvm::acc::Clause::ACCC_num_workers,
        llvm::acc::Clause::ACCC_vector_length};

static constexpr inline AccClauseSet loopOnlyAllowedAfterDeviceTypeClauses{
    llvm::acc::Clause::ACCC_auto, llvm::acc::Clause::ACCC_collapse,
    llvm::acc::Clause::ACCC_independent, llvm::acc::Clause::ACCC_gang,
    llvm::acc::Clause::ACCC_seq, llvm::acc::Clause::ACCC_tile,
    llvm::acc::Clause::ACCC_vector, llvm::acc::Clause::ACCC_worker};

static constexpr inline AccClauseSet updateOnlyAllowedAfterDeviceTypeClauses{
    llvm::acc::Clause::ACCC_async, llvm::acc::Clause::ACCC_wait};

static constexpr inline AccClauseSet routineOnlyAllowedAfterDeviceTypeClauses{
    llvm::acc::Clause::ACCC_bind, llvm::acc::Clause::ACCC_gang,
    llvm::acc::Clause::ACCC_vector, llvm::acc::Clause::ACCC_worker,
    llvm::acc::Clause::ACCC_seq};

static constexpr inline AccClauseSet routineMutuallyExclusiveClauses{
    llvm::acc::Clause::ACCC_gang, llvm::acc::Clause::ACCC_worker,
    llvm::acc::Clause::ACCC_vector, llvm::acc::Clause::ACCC_seq};

bool AccStructureChecker::CheckAllowedModifier(llvm::acc::Clause clause) {
  if (GetContext().directive == llvm::acc::ACCD_enter_data ||
      GetContext().directive == llvm::acc::ACCD_exit_data) {
    context_.Say(GetContext().clauseSource,
        "Modifier is not allowed for the %s clause "
        "on the %s directive"_err_en_US,
        parser::ToUpperCaseLetters(getClauseName(clause).str()),
        ContextDirectiveAsFortran());
    return true;
  }
  return false;
}

bool AccStructureChecker::IsComputeConstruct(
    llvm::acc::Directive directive) const {
  return directive == llvm::acc::ACCD_parallel ||
      directive == llvm::acc::ACCD_parallel_loop ||
      directive == llvm::acc::ACCD_serial ||
      directive == llvm::acc::ACCD_serial_loop ||
      directive == llvm::acc::ACCD_kernels ||
      directive == llvm::acc::ACCD_kernels_loop;
}

bool AccStructureChecker::IsInsideComputeConstruct() const {
  if (dirContext_.size() <= 1) {
    return false;
  }

  // Check all nested context skipping the first one.
  for (std::size_t i = dirContext_.size() - 1; i > 0; --i) {
    if (IsComputeConstruct(dirContext_[i - 1].directive)) {
      return true;
    }
  }
  return false;
}

void AccStructureChecker::CheckNotInComputeConstruct() {
  if (IsInsideComputeConstruct()) {
    context_.Say(GetContext().directiveSource,
        "Directive %s may not be called within a compute region"_err_en_US,
        ContextDirectiveAsFortran());
  }
}

void AccStructureChecker::Enter(const parser::AccClause &x) {
  SetContextClause(x);
}

void AccStructureChecker::Leave(const parser::AccClauseList &) {}

void AccStructureChecker::Enter(const parser::OpenACCBlockConstruct &x) {
  const auto &beginBlockDir{std::get<parser::AccBeginBlockDirective>(x.t)};
  const auto &endBlockDir{std::get<parser::AccEndBlockDirective>(x.t)};
  const auto &beginAccBlockDir{
      std::get<parser::AccBlockDirective>(beginBlockDir.t)};

  CheckMatching(beginAccBlockDir, endBlockDir.v);
  PushContextAndClauseSets(beginAccBlockDir.source, beginAccBlockDir.v);
}

void AccStructureChecker::Leave(const parser::OpenACCBlockConstruct &x) {
  const auto &beginBlockDir{std::get<parser::AccBeginBlockDirective>(x.t)};
  const auto &blockDir{std::get<parser::AccBlockDirective>(beginBlockDir.t)};
  const parser::Block &block{std::get<parser::Block>(x.t)};
  switch (blockDir.v) {
  case llvm::acc::Directive::ACCD_kernels:
  case llvm::acc::Directive::ACCD_parallel:
  case llvm::acc::Directive::ACCD_serial:
    // Restriction - line 1004-1005
    CheckOnlyAllowedAfter(llvm::acc::Clause::ACCC_device_type,
        computeConstructOnlyAllowedAfterDeviceTypeClauses);
    // Restriction - line 1001
    CheckNoBranching(block, GetContext().directive, blockDir.source);
    break;
  case llvm::acc::Directive::ACCD_data:
    // Restriction - 2.6.5 pt 1
    // Only a warning is emitted here for portability reason.
    CheckRequireAtLeastOneOf(/*warnInsteadOfError=*/true);
    // Restriction is not formally in the specification but all compilers emit
    // an error and it is likely to be omitted from the spec.
    CheckNoBranching(block, GetContext().directive, blockDir.source);
    break;
  case llvm::acc::Directive::ACCD_host_data:
    // Restriction - line 1746
    CheckRequireAtLeastOneOf();
    break;
  default:
    break;
  }
  dirContext_.pop_back();
}

void AccStructureChecker::Enter(
    const parser::OpenACCStandaloneDeclarativeConstruct &x) {
  const auto &declarativeDir{std::get<parser::AccDeclarativeDirective>(x.t)};
  PushContextAndClauseSets(declarativeDir.source, declarativeDir.v);
}

void AccStructureChecker::Leave(
    const parser::OpenACCStandaloneDeclarativeConstruct &x) {
  // Restriction - line 2409
  CheckAtLeastOneClause();

  // Restriction - line 2417-2418 - In a Fortran module declaration section,
  // only create, copyin, device_resident, and link clauses are allowed.
  const auto &declarativeDir{std::get<parser::AccDeclarativeDirective>(x.t)};
  const auto &scope{context_.FindScope(declarativeDir.source)};
  const Scope &containingScope{GetProgramUnitContaining(scope)};
  if (containingScope.kind() == Scope::Kind::Module) {
    for (auto cl : GetContext().actualClauses) {
      if (cl != llvm::acc::Clause::ACCC_create &&
          cl != llvm::acc::Clause::ACCC_copyin &&
          cl != llvm::acc::Clause::ACCC_device_resident &&
          cl != llvm::acc::Clause::ACCC_link) {
        context_.Say(GetContext().directiveSource,
            "%s clause is not allowed on the %s directive in module "
            "declaration "
            "section"_err_en_US,
            parser::ToUpperCaseLetters(
                llvm::acc::getOpenACCClauseName(cl).str()),
            ContextDirectiveAsFortran());
      }
    }
  }
  dirContext_.pop_back();
}

void AccStructureChecker::Enter(const parser::OpenACCCombinedConstruct &x) {
  const auto &beginCombinedDir{
      std::get<parser::AccBeginCombinedDirective>(x.t)};
  const auto &combinedDir{
      std::get<parser::AccCombinedDirective>(beginCombinedDir.t)};

  // check matching, End directive is optional
  if (const auto &endCombinedDir{
          std::get<std::optional<parser::AccEndCombinedDirective>>(x.t)}) {
    CheckMatching<parser::AccCombinedDirective>(combinedDir, endCombinedDir->v);
  }

  PushContextAndClauseSets(combinedDir.source, combinedDir.v);
}

void AccStructureChecker::Leave(const parser::OpenACCCombinedConstruct &x) {
  const auto &beginBlockDir{std::get<parser::AccBeginCombinedDirective>(x.t)};
  const auto &combinedDir{
      std::get<parser::AccCombinedDirective>(beginBlockDir.t)};
  auto &doCons{std::get<std::optional<parser::DoConstruct>>(x.t)};
  switch (combinedDir.v) {
  case llvm::acc::Directive::ACCD_kernels_loop:
  case llvm::acc::Directive::ACCD_parallel_loop:
  case llvm::acc::Directive::ACCD_serial_loop:
    // Restriction - line 1004-1005
    CheckOnlyAllowedAfter(llvm::acc::Clause::ACCC_device_type,
        computeConstructOnlyAllowedAfterDeviceTypeClauses |
            loopOnlyAllowedAfterDeviceTypeClauses);
    if (doCons) {
      const parser::Block &block{std::get<parser::Block>(doCons->t)};
      CheckNoBranching(block, GetContext().directive, beginBlockDir.source);
    }
    break;
  default:
    break;
  }
  dirContext_.pop_back();
}

void AccStructureChecker::Enter(const parser::OpenACCLoopConstruct &x) {
  const auto &beginDir{std::get<parser::AccBeginLoopDirective>(x.t)};
  const auto &loopDir{std::get<parser::AccLoopDirective>(beginDir.t)};
  PushContextAndClauseSets(loopDir.source, loopDir.v);
}

void AccStructureChecker::Leave(const parser::OpenACCLoopConstruct &x) {
  const auto &beginDir{std::get<parser::AccBeginLoopDirective>(x.t)};
  const auto &loopDir{std::get<parser::AccLoopDirective>(beginDir.t)};
  if (loopDir.v == llvm::acc::Directive::ACCD_loop) {
    // Restriction - line 1818-1819
    CheckOnlyAllowedAfter(llvm::acc::Clause::ACCC_device_type,
        loopOnlyAllowedAfterDeviceTypeClauses);
    // Restriction - line 1834
    CheckNotAllowedIfClause(llvm::acc::Clause::ACCC_seq,
        {llvm::acc::Clause::ACCC_gang, llvm::acc::Clause::ACCC_vector,
            llvm::acc::Clause::ACCC_worker});
  }
  dirContext_.pop_back();
}

void AccStructureChecker::Enter(const parser::OpenACCStandaloneConstruct &x) {
  const auto &standaloneDir{std::get<parser::AccStandaloneDirective>(x.t)};
  PushContextAndClauseSets(standaloneDir.source, standaloneDir.v);
}

void AccStructureChecker::Leave(const parser::OpenACCStandaloneConstruct &x) {
  const auto &standaloneDir{std::get<parser::AccStandaloneDirective>(x.t)};
  switch (standaloneDir.v) {
  case llvm::acc::Directive::ACCD_enter_data:
  case llvm::acc::Directive::ACCD_exit_data:
    // Restriction - line 1310-1311 (ENTER DATA)
    // Restriction - line 1312-1313 (EXIT DATA)
    CheckRequireAtLeastOneOf();
    break;
  case llvm::acc::Directive::ACCD_set:
    // Restriction - line 2610
    CheckRequireAtLeastOneOf();
    // Restriction - line 2602
    CheckNotInComputeConstruct();
    break;
  case llvm::acc::Directive::ACCD_update:
    // Restriction - line 2636
    CheckRequireAtLeastOneOf();
    // Restriction - line 2669
    CheckOnlyAllowedAfter(llvm::acc::Clause::ACCC_device_type,
        updateOnlyAllowedAfterDeviceTypeClauses);
    break;
  case llvm::acc::Directive::ACCD_init:
  case llvm::acc::Directive::ACCD_shutdown:
    // Restriction - line 2525 (INIT)
    // Restriction - line 2561 (SHUTDOWN)
    CheckNotInComputeConstruct();
    break;
  default:
    break;
  }
  dirContext_.pop_back();
}

void AccStructureChecker::Enter(const parser::OpenACCRoutineConstruct &x) {
  PushContextAndClauseSets(x.source, llvm::acc::Directive::ACCD_routine);
  const auto &optName{std::get<std::optional<parser::Name>>(x.t)};
  if (!optName) {
    const auto &verbatim{std::get<parser::Verbatim>(x.t)};
    const auto &scope{context_.FindScope(verbatim.source)};
    const Scope &containingScope{GetProgramUnitContaining(scope)};
    if (containingScope.kind() == Scope::Kind::Module) {
      context_.Say(GetContext().directiveSource,
          "ROUTINE directive without name must appear within the specification "
          "part of a subroutine or function definition, or within an interface "
          "body for a subroutine or function in an interface block"_err_en_US);
    }
  }
}
void AccStructureChecker::Leave(const parser::OpenACCRoutineConstruct &) {
  // Restriction - line 2790
  CheckRequireAtLeastOneOf();
  // Restriction - line 2788-2789
  CheckOnlyAllowedAfter(llvm::acc::Clause::ACCC_device_type,
      routineOnlyAllowedAfterDeviceTypeClauses);
  dirContext_.pop_back();
}

void AccStructureChecker::Enter(const parser::OpenACCWaitConstruct &x) {
  const auto &verbatim{std::get<parser::Verbatim>(x.t)};
  PushContextAndClauseSets(verbatim.source, llvm::acc::Directive::ACCD_wait);
}
void AccStructureChecker::Leave(const parser::OpenACCWaitConstruct &x) {
  dirContext_.pop_back();
}

void AccStructureChecker::Enter(const parser::OpenACCAtomicConstruct &x) {
  PushContextAndClauseSets(x.source, llvm::acc::Directive::ACCD_atomic);
}
void AccStructureChecker::Leave(const parser::OpenACCAtomicConstruct &x) {
  dirContext_.pop_back();
}

void AccStructureChecker::CheckAtomicStmt(
    const parser::AssignmentStmt &assign, const std::string &construct) {
  const auto &var{std::get<parser::Variable>(assign.t)};
  const auto &expr{std::get<parser::Expr>(assign.t)};
  const auto *rhs{GetExpr(context_, expr)};
  const auto *lhs{GetExpr(context_, var)};

  if (lhs) {
    if (lhs->Rank() != 0) {
      context_.Say(expr.source,
          "LHS of atomic %s statement must be scalar"_err_en_US, construct);
    }
    // TODO: Check if lhs is intrinsic type.
  }
  if (rhs) {
    if (rhs->Rank() != 0) {
      context_.Say(var.GetSource(),
          "RHS of atomic %s statement must be scalar"_err_en_US, construct);
    }
    // TODO: Check if rhs is intrinsic type.
  }
}

static constexpr evaluate::operation::OperatorSet validAccAtomicUpdateOperators{
    evaluate::operation::Operator::Add, evaluate::operation::Operator::Mul,
    evaluate::operation::Operator::Sub, evaluate::operation::Operator::Div,
    evaluate::operation::Operator::And, evaluate::operation::Operator::Or,
    evaluate::operation::Operator::Eqv, evaluate::operation::Operator::Neqv,
    evaluate::operation::Operator::Max, evaluate::operation::Operator::Min};

static bool IsValidAtomicUpdateOperation(
    const evaluate::operation::Operator &op) {
  return validAccAtomicUpdateOperators.test(op);
}

// Couldn't reproduce this behavior with evaluate::UnwrapConvertedExpr which
// is similar but only works within a single type category.
static SomeExpr GetExprModuloConversion(const SomeExpr &expr) {
  const auto [op, args]{evaluate::GetTopLevelOperation(expr)};
  // Check: if it is a conversion then it must have at least one argument.
  CHECK(((op != evaluate::operation::Operator::Convert &&
             op != evaluate::operation::Operator::Resize) ||
            args.size() >= 1) &&
      "Invalid conversion operation");
  if ((op == evaluate::operation::Operator::Convert ||
          op == evaluate::operation::Operator::Resize) &&
      args.size() >= 1) {
    return args[0];
  }
  return expr;
}

void AccStructureChecker::CheckAtomicUpdateStmt(
    const parser::AssignmentStmt &assign, const SomeExpr &updateVar,
    const SomeExpr *captureVar) {
  CheckAtomicStmt(assign, "update");
  const auto &expr{std::get<parser::Expr>(assign.t)};
  const auto *rhs{GetExpr(context_, expr)};
  if (rhs) {
    const auto [op, args]{
        evaluate::GetTopLevelOperation(GetExprModuloConversion(*rhs))};
    if (!IsValidAtomicUpdateOperation(op)) {
      context_.Say(expr.source,
          "Invalid atomic update operation, can only use: *, +, -, *, /, and, or, eqv, neqv, max, min, iand, ior, ieor"_err_en_US);
    } else {
      bool foundUpdateVar{false};
      for (const auto &arg : args) {
        if (updateVar == GetExprModuloConversion(arg)) {
          if (foundUpdateVar) {
            context_.Say(expr.source,
                "The updated variable, %s, cannot appear more than once in the atomic update operation"_err_en_US,
                updateVar.AsFortran());
          } else {
            foundUpdateVar = true;
          }
        } else if (evaluate::IsVarSubexpressionOf(updateVar, arg)) {
          // TODO: Get the source location of arg and point to the individual
          // argument.
          context_.Say(expr.source,
              "Arguments to the atomic update operation cannot reference the updated variable, %s, as a subexpression"_err_en_US,
              updateVar.AsFortran());
        }
      }
      if (!foundUpdateVar) {
        context_.Say(expr.source,
            "The RHS of this atomic update statement must reference the updated variable: %s"_err_en_US,
            updateVar.AsFortran());
      }
    }
  }
}

void AccStructureChecker::CheckAtomicWriteStmt(
    const parser::AssignmentStmt &assign, const SomeExpr &updateVar,
    const SomeExpr *captureVar) {
  CheckAtomicStmt(assign, "write");
  const auto &expr{std::get<parser::Expr>(assign.t)};
  const auto *rhs{GetExpr(context_, expr)};
  if (rhs) {
    if (evaluate::IsVarSubexpressionOf(updateVar, *rhs)) {
      context_.Say(expr.source,
          "The RHS of this atomic write statement cannot reference the atomic variable: %s"_err_en_US,
          updateVar.AsFortran());
    }
  }
}

void AccStructureChecker::CheckAtomicCaptureStmt(
    const parser::AssignmentStmt &assign, const SomeExpr *updateVar,
    const SomeExpr &captureVar) {
  CheckAtomicStmt(assign, "capture");
}

void AccStructureChecker::Enter(const parser::AccAtomicCapture &capture) {
  const Fortran::parser::AssignmentStmt &stmt1{
      std::get<Fortran::parser::AccAtomicCapture::Stmt1>(capture.t)
          .v.statement};
  const Fortran::parser::AssignmentStmt &stmt2{
      std::get<Fortran::parser::AccAtomicCapture::Stmt2>(capture.t)
          .v.statement};
  const auto &var1{std::get<parser::Variable>(stmt1.t)};
  const auto &var2{std::get<parser::Variable>(stmt2.t)};
  const auto *lhs1{GetExpr(context_, var1)};
  const auto *lhs2{GetExpr(context_, var2)};
  if (!lhs1 || !lhs2) {
    // Not enough information to check.
    return;
  }
  if (*lhs1 == *lhs2) {
    context_.Say(std::get<parser::Verbatim>(capture.t).source,
        "The variables assigned in this atomic capture construct must be distinct"_err_en_US);
    return;
  }
  const auto &expr1{std::get<parser::Expr>(stmt1.t)};
  const auto &expr2{std::get<parser::Expr>(stmt2.t)};
  const auto *rhs1{GetExpr(context_, expr1)};
  const auto *rhs2{GetExpr(context_, expr2)};
  if (!rhs1 || !rhs2) {
    return;
  }
  bool stmt1CapturesLhs2{*lhs2 == GetExprModuloConversion(*rhs1)};
  bool stmt2CapturesLhs1{*lhs1 == GetExprModuloConversion(*rhs2)};
  if (stmt1CapturesLhs2 && !stmt2CapturesLhs1) {
    if (*lhs2 == GetExprModuloConversion(*rhs2)) {
      // a = b; b = b: Doesn't fit the spec.
      context_.Say(std::get<parser::Verbatim>(capture.t).source,
          "The assignments in this atomic capture construct do not update a variable and capture either its initial or final value"_err_en_US);
      // TODO: Add attatchment that a = b seems to be a capture,
      // but b = b is not a valid update or write.
    } else if (evaluate::IsVarSubexpressionOf(*lhs2, *rhs2)) {
      // Take v = x; x = <expr w/ x> as capture; update
      const auto &updateVar{*lhs2};
      const auto &captureVar{*lhs1};
      CheckAtomicCaptureStmt(stmt1, &updateVar, captureVar);
      CheckAtomicUpdateStmt(stmt2, updateVar, &captureVar);
    } else {
      // Take v = x; x = <expr w/o x> as capture; write
      const auto &updateVar{*lhs2};
      const auto &captureVar{*lhs1};
      CheckAtomicCaptureStmt(stmt1, &updateVar, captureVar);
      CheckAtomicWriteStmt(stmt2, updateVar, &captureVar);
    }
  } else if (stmt2CapturesLhs1 && !stmt1CapturesLhs2) {
    if (*lhs1 == GetExprModuloConversion(*rhs1)) {
      // Error a = a; b = a;
      context_.Say(var1.GetSource(),
          "The first assignment in this atomic capture construct doesn't perform a valid update"_err_en_US);
      // Add attatchment that a = a is not considered an update,
      // but b = a seems to be a capture.
    } else {
      // Take x = <expr>; v = x: as update; capture
      const auto &updateVar{*lhs1};
      const auto &captureVar{*lhs2};
      CheckAtomicUpdateStmt(stmt1, updateVar, &captureVar);
      CheckAtomicCaptureStmt(stmt2, &updateVar, captureVar);
    }
  } else if (stmt1CapturesLhs2 && stmt2CapturesLhs1) {
    // x1 = x2; x2 = x1; Doesn't fit the spec.
    context_.Say(std::get<parser::Verbatim>(capture.t).source,
        "The assignments in this atomic capture construct do not update a variable and capture either its initial or final value"_err_en_US);
    // TODO: Add attatchment that both assignments seem to be captures.
  } else { // !stmt1CapturesLhs2 && !stmt2CapturesLhs1
    // a = <expr != b>; b = <expr != a>; Doesn't fit the spec
    context_.Say(std::get<parser::Verbatim>(capture.t).source,
        "The assignments in this atomic capture construct do not update a variable and capture either its initial or final value"_err_en_US);
    // TODO: Add attatchment that neither assignment seems to be a capture.
  }
}

void AccStructureChecker::Enter(const parser::AccAtomicUpdate &x) {
  const auto &assign{
      std::get<parser::Statement<parser::AssignmentStmt>>(x.t).statement};
  const auto &var{std::get<parser::Variable>(assign.t)};
  if (const auto *updateVar{GetExpr(context_, var)}) {
    CheckAtomicUpdateStmt(assign, *updateVar, /*captureVar=*/nullptr);
  }
}

void AccStructureChecker::Enter(const parser::AccAtomicWrite &x) {
  const auto &assign{
      std::get<parser::Statement<parser::AssignmentStmt>>(x.t).statement};
  const auto &var{std::get<parser::Variable>(assign.t)};
  if (const auto *updateVar{GetExpr(context_, var)}) {
    CheckAtomicWriteStmt(assign, *updateVar, /*captureVar=*/nullptr);
  }
}

void AccStructureChecker::Enter(const parser::AccAtomicRead &x) {
  const auto &assign{
      std::get<parser::Statement<parser::AssignmentStmt>>(x.t).statement};
  const auto &var{std::get<parser::Variable>(assign.t)};
  if (const auto *captureVar{GetExpr(context_, var)}) {
    CheckAtomicCaptureStmt(assign, /*updateVar=*/nullptr, *captureVar);
  }
}

void AccStructureChecker::Enter(const parser::OpenACCCacheConstruct &x) {
  const auto &verbatim = std::get<parser::Verbatim>(x.t);
  PushContextAndClauseSets(verbatim.source, llvm::acc::Directive::ACCD_cache);
  SetContextDirectiveSource(verbatim.source);
  if (loopNestLevel == 0) {
    context_.Say(verbatim.source,
          "The CACHE directive must be inside a loop"_err_en_US);
  }
}
void AccStructureChecker::Leave(const parser::OpenACCCacheConstruct &x) {
  dirContext_.pop_back();
}

// Clause checkers
CHECK_SIMPLE_CLAUSE(Auto, ACCC_auto)
CHECK_SIMPLE_CLAUSE(Attach, ACCC_attach)
CHECK_SIMPLE_CLAUSE(Bind, ACCC_bind)
CHECK_SIMPLE_CLAUSE(Capture, ACCC_capture)
CHECK_SIMPLE_CLAUSE(Default, ACCC_default)
CHECK_SIMPLE_CLAUSE(DefaultAsync, ACCC_default_async)
CHECK_SIMPLE_CLAUSE(Delete, ACCC_delete)
CHECK_SIMPLE_CLAUSE(Detach, ACCC_detach)
CHECK_SIMPLE_CLAUSE(Device, ACCC_device)
CHECK_SIMPLE_CLAUSE(DeviceNum, ACCC_device_num)
CHECK_SIMPLE_CLAUSE(Finalize, ACCC_finalize)
CHECK_SIMPLE_CLAUSE(Firstprivate, ACCC_firstprivate)
CHECK_SIMPLE_CLAUSE(Host, ACCC_host)
CHECK_SIMPLE_CLAUSE(IfPresent, ACCC_if_present)
CHECK_SIMPLE_CLAUSE(Independent, ACCC_independent)
CHECK_SIMPLE_CLAUSE(NoCreate, ACCC_no_create)
CHECK_SIMPLE_CLAUSE(Nohost, ACCC_nohost)
CHECK_SIMPLE_CLAUSE(Private, ACCC_private)
CHECK_SIMPLE_CLAUSE(Read, ACCC_read)
CHECK_SIMPLE_CLAUSE(UseDevice, ACCC_use_device)
CHECK_SIMPLE_CLAUSE(Wait, ACCC_wait)
CHECK_SIMPLE_CLAUSE(Write, ACCC_write)
CHECK_SIMPLE_CLAUSE(Unknown, ACCC_unknown)

void AccStructureChecker::CheckMultipleOccurrenceInDeclare(
    const parser::AccObjectList &list, llvm::acc::Clause clause) {
  if (GetContext().directive != llvm::acc::Directive::ACCD_declare)
    return;
  for (const auto &object : list.v) {
    common::visit(
        common::visitors{
            [&](const parser::Designator &designator) {
              if (const auto *name = getDesignatorNameIfDataRef(designator)) {
                if (declareSymbols.contains(&name->symbol->GetUltimate())) {
                  if (declareSymbols[&name->symbol->GetUltimate()] == clause) {
                    context_.Warn(common::UsageWarning::OpenAccUsage,
                        GetContext().clauseSource,
                        "'%s' in the %s clause is already present in the same clause in this module"_warn_en_US,
                        name->symbol->name(),
                        parser::ToUpperCaseLetters(
                            llvm::acc::getOpenACCClauseName(clause).str()));
                  } else {
                    context_.Say(GetContext().clauseSource,
                        "'%s' in the %s clause is already present in another "
                        "%s clause in this module"_err_en_US,
                        name->symbol->name(),
                        parser::ToUpperCaseLetters(
                            llvm::acc::getOpenACCClauseName(clause).str()),
                        parser::ToUpperCaseLetters(
                            llvm::acc::getOpenACCClauseName(
                                declareSymbols[&name->symbol->GetUltimate()])
                                .str()));
                  }
                }
                declareSymbols.insert({&name->symbol->GetUltimate(), clause});
              }
            },
            [&](const parser::Name &name) {
              // TODO: check common block
            }},
        object.u);
  }
}

void AccStructureChecker::CheckMultipleOccurrenceInDeclare(
    const parser::AccObjectListWithModifier &list, llvm::acc::Clause clause) {
  const auto &objectList = std::get<Fortran::parser::AccObjectList>(list.t);
  CheckMultipleOccurrenceInDeclare(objectList, clause);
}

void AccStructureChecker::Enter(const parser::AccClause::Async &c) {
  llvm::acc::Clause crtClause = llvm::acc::Clause::ACCC_async;
  CheckAllowed(crtClause);
  CheckAllowedOncePerGroup(crtClause, llvm::acc::Clause::ACCC_device_type);
}

void AccStructureChecker::Enter(const parser::AccClause::Create &c) {
  CheckAllowed(llvm::acc::Clause::ACCC_create);
  const auto &modifierClause{c.v};
  if (const auto &modifier{
          std::get<std::optional<parser::AccDataModifier>>(modifierClause.t)}) {
    if (modifier->v != parser::AccDataModifier::Modifier::Zero) {
      context_.Say(GetContext().clauseSource,
          "Only the ZERO modifier is allowed for the %s clause "
          "on the %s directive"_err_en_US,
          parser::ToUpperCaseLetters(
              llvm::acc::getOpenACCClauseName(llvm::acc::Clause::ACCC_create)
                  .str()),
          ContextDirectiveAsFortran());
    }
    if (GetContext().directive == llvm::acc::Directive::ACCD_declare) {
      context_.Say(GetContext().clauseSource,
          "The ZERO modifier is not allowed for the %s clause "
          "on the %s directive"_err_en_US,
          parser::ToUpperCaseLetters(
              llvm::acc::getOpenACCClauseName(llvm::acc::Clause::ACCC_create)
                  .str()),
          ContextDirectiveAsFortran());
    }
  }
  CheckMultipleOccurrenceInDeclare(
      modifierClause, llvm::acc::Clause::ACCC_create);
}

void AccStructureChecker::Enter(const parser::AccClause::Copyin &c) {
  CheckAllowed(llvm::acc::Clause::ACCC_copyin);
  const auto &modifierClause{c.v};
  if (const auto &modifier{
          std::get<std::optional<parser::AccDataModifier>>(modifierClause.t)}) {
    if (CheckAllowedModifier(llvm::acc::Clause::ACCC_copyin)) {
      return;
    }
    if (modifier->v != parser::AccDataModifier::Modifier::ReadOnly) {
      context_.Say(GetContext().clauseSource,
          "Only the READONLY modifier is allowed for the %s clause "
          "on the %s directive"_err_en_US,
          parser::ToUpperCaseLetters(
              llvm::acc::getOpenACCClauseName(llvm::acc::Clause::ACCC_copyin)
                  .str()),
          ContextDirectiveAsFortran());
    }
  }
  CheckMultipleOccurrenceInDeclare(
      modifierClause, llvm::acc::Clause::ACCC_copyin);
}

void AccStructureChecker::Enter(const parser::AccClause::Copyout &c) {
  CheckAllowed(llvm::acc::Clause::ACCC_copyout);
  const auto &modifierClause{c.v};
  if (const auto &modifier{
          std::get<std::optional<parser::AccDataModifier>>(modifierClause.t)}) {
    if (CheckAllowedModifier(llvm::acc::Clause::ACCC_copyout)) {
      return;
    }
    if (modifier->v != parser::AccDataModifier::Modifier::Zero) {
      context_.Say(GetContext().clauseSource,
          "Only the ZERO modifier is allowed for the %s clause "
          "on the %s directive"_err_en_US,
          parser::ToUpperCaseLetters(
              llvm::acc::getOpenACCClauseName(llvm::acc::Clause::ACCC_copyout)
                  .str()),
          ContextDirectiveAsFortran());
    }
    if (GetContext().directive == llvm::acc::Directive::ACCD_declare) {
      context_.Say(GetContext().clauseSource,
          "The ZERO modifier is not allowed for the %s clause "
          "on the %s directive"_err_en_US,
          parser::ToUpperCaseLetters(
              llvm::acc::getOpenACCClauseName(llvm::acc::Clause::ACCC_copyout)
                  .str()),
          ContextDirectiveAsFortran());
    }
  }
  CheckMultipleOccurrenceInDeclare(
      modifierClause, llvm::acc::Clause::ACCC_copyout);
}

void AccStructureChecker::Enter(const parser::AccClause::DeviceType &d) {
  CheckAllowed(llvm::acc::Clause::ACCC_device_type);
  if (GetContext().directive == llvm::acc::Directive::ACCD_set &&
      d.v.v.size() > 1) {
    context_.Say(GetContext().clauseSource,
        "The %s clause on the %s directive accepts only one value"_err_en_US,
        parser::ToUpperCaseLetters(
            llvm::acc::getOpenACCClauseName(llvm::acc::Clause::ACCC_device_type)
                .str()),
        ContextDirectiveAsFortran());
  }
  ResetCrtGroup();
}

void AccStructureChecker::Enter(const parser::AccClause::Seq &g) {
  llvm::acc::Clause crtClause = llvm::acc::Clause::ACCC_seq;
  if (GetContext().directive == llvm::acc::Directive::ACCD_routine) {
    CheckMutuallyExclusivePerGroup(crtClause,
        llvm::acc::Clause::ACCC_device_type, routineMutuallyExclusiveClauses);
  }
  CheckAllowed(crtClause);
}

void AccStructureChecker::Enter(const parser::AccClause::Vector &g) {
  llvm::acc::Clause crtClause = llvm::acc::Clause::ACCC_vector;
  if (GetContext().directive == llvm::acc::Directive::ACCD_routine) {
    CheckMutuallyExclusivePerGroup(crtClause,
        llvm::acc::Clause::ACCC_device_type, routineMutuallyExclusiveClauses);
  }
  CheckAllowed(crtClause);
  if (GetContext().directive != llvm::acc::Directive::ACCD_routine) {
    CheckAllowedOncePerGroup(crtClause, llvm::acc::Clause::ACCC_device_type);
  }
}

void AccStructureChecker::Enter(const parser::AccClause::Worker &g) {
  llvm::acc::Clause crtClause = llvm::acc::Clause::ACCC_worker;
  if (GetContext().directive == llvm::acc::Directive::ACCD_routine) {
    CheckMutuallyExclusivePerGroup(crtClause,
        llvm::acc::Clause::ACCC_device_type, routineMutuallyExclusiveClauses);
  }
  CheckAllowed(crtClause);
  if (GetContext().directive != llvm::acc::Directive::ACCD_routine) {
    CheckAllowedOncePerGroup(crtClause, llvm::acc::Clause::ACCC_device_type);
  }
}

void AccStructureChecker::Enter(const parser::AccClause::Tile &g) {
  CheckAllowed(llvm::acc::Clause::ACCC_tile);
  CheckAllowedOncePerGroup(
      llvm::acc::Clause::ACCC_tile, llvm::acc::Clause::ACCC_device_type);
}

void AccStructureChecker::Enter(const parser::AccClause::Gang &g) {
  llvm::acc::Clause crtClause = llvm::acc::Clause::ACCC_gang;
  if (GetContext().directive == llvm::acc::Directive::ACCD_routine) {
    CheckMutuallyExclusivePerGroup(crtClause,
        llvm::acc::Clause::ACCC_device_type, routineMutuallyExclusiveClauses);
  }
  CheckAllowed(crtClause);
  if (GetContext().directive != llvm::acc::Directive::ACCD_routine) {
    CheckAllowedOncePerGroup(crtClause, llvm::acc::Clause::ACCC_device_type);
  }

  if (g.v) {
    bool hasNum = false;
    bool hasDim = false;
    bool hasStatic = false;
    const Fortran::parser::AccGangArgList &x = *g.v;
    for (const Fortran::parser::AccGangArg &gangArg : x.v) {
      if (std::get_if<Fortran::parser::AccGangArg::Num>(&gangArg.u)) {
        hasNum = true;
      } else if (std::get_if<Fortran::parser::AccGangArg::Dim>(&gangArg.u)) {
        hasDim = true;
      } else if (std::get_if<Fortran::parser::AccGangArg::Static>(&gangArg.u)) {
        hasStatic = true;
      }
    }

    if (GetContext().directive == llvm::acc::Directive::ACCD_routine &&
        (hasStatic || hasNum)) {
      context_.Say(GetContext().clauseSource,
          "Only the dim argument is allowed on the %s clause on the %s directive"_err_en_US,
          parser::ToUpperCaseLetters(
              llvm::acc::getOpenACCClauseName(llvm::acc::Clause::ACCC_gang)
                  .str()),
          ContextDirectiveAsFortran());
    }

    if (hasDim && hasNum) {
      context_.Say(GetContext().clauseSource,
          "The num argument is not allowed when dim is specified"_err_en_US);
    }
  }
}

void AccStructureChecker::Enter(const parser::AccClause::NumGangs &n) {
  CheckAllowed(llvm::acc::Clause::ACCC_num_gangs,
      /*warnInsteadOfError=*/GetContext().directive ==
              llvm::acc::Directive::ACCD_serial ||
          GetContext().directive == llvm::acc::Directive::ACCD_serial_loop);
  CheckAllowedOncePerGroup(
      llvm::acc::Clause::ACCC_num_gangs, llvm::acc::Clause::ACCC_device_type);

  if (n.v.size() > 3)
    context_.Say(GetContext().clauseSource,
        "NUM_GANGS clause accepts a maximum of 3 arguments"_err_en_US);
}

void AccStructureChecker::Enter(const parser::AccClause::NumWorkers &n) {
  CheckAllowed(llvm::acc::Clause::ACCC_num_workers,
      /*warnInsteadOfError=*/GetContext().directive ==
              llvm::acc::Directive::ACCD_serial ||
          GetContext().directive == llvm::acc::Directive::ACCD_serial_loop);
  CheckAllowedOncePerGroup(
      llvm::acc::Clause::ACCC_num_workers, llvm::acc::Clause::ACCC_device_type);
}

void AccStructureChecker::Enter(const parser::AccClause::VectorLength &n) {
  CheckAllowed(llvm::acc::Clause::ACCC_vector_length,
      /*warnInsteadOfError=*/GetContext().directive ==
              llvm::acc::Directive::ACCD_serial ||
          GetContext().directive == llvm::acc::Directive::ACCD_serial_loop);
  CheckAllowedOncePerGroup(llvm::acc::Clause::ACCC_vector_length,
      llvm::acc::Clause::ACCC_device_type);
}

void AccStructureChecker::Enter(const parser::AccClause::Reduction &reduction) {
  CheckAllowed(llvm::acc::Clause::ACCC_reduction);

  // From OpenACC 3.3
  // At a minimum, the supported data types include Fortran logical as well as
  // the numerical data types (e.g. integer, real, double precision, complex).
  // However, for each reduction operator, the supported data types include only
  // the types permitted as operands to the corresponding operator in the base
  // language where (1) for max and min, the corresponding operator is less-than
  // and (2) for other operators, the operands and the result are the same type.
  //
  // The following check that the reduction operator is supported with the given
  // type.
  const parser::AccObjectListWithReduction &list{reduction.v};
  const auto &op{std::get<parser::ReductionOperator>(list.t)};
  const auto &objects{std::get<parser::AccObjectList>(list.t)};

  for (const auto &object : objects.v) {
    common::visit(
        common::visitors{
            [&](const parser::Designator &designator) {
              if (const auto *name = getDesignatorNameIfDataRef(designator)) {
                if (name->symbol) {
                  const auto *type{name->symbol->GetType()};
                  if (type->IsNumeric(TypeCategory::Integer) &&
                      !reductionIntegerSet.test(op.v)) {
                    context_.Say(GetContext().clauseSource,
                        "reduction operator not supported for integer type"_err_en_US);
                  } else if (type->IsNumeric(TypeCategory::Real) &&
                      !reductionRealSet.test(op.v)) {
                    context_.Say(GetContext().clauseSource,
                        "reduction operator not supported for real type"_err_en_US);
                  } else if (type->IsNumeric(TypeCategory::Complex) &&
                      !reductionComplexSet.test(op.v)) {
                    context_.Say(GetContext().clauseSource,
                        "reduction operator not supported for complex type"_err_en_US);
                  } else if (type->category() ==
                          Fortran::semantics::DeclTypeSpec::Category::Logical &&
                      !reductionLogicalSet.test(op.v)) {
                    context_.Say(GetContext().clauseSource,
                        "reduction operator not supported for logical type"_err_en_US);
                  }
                  // TODO: check composite type.
                }
              }
            },
            [&](const Fortran::parser::Name &name) {
              // TODO: check common block
            }},
        object.u);
  }
}

void AccStructureChecker::Enter(const parser::AccClause::Self &x) {
  CheckAllowed(llvm::acc::Clause::ACCC_self);
  const std::optional<parser::AccSelfClause> &accSelfClause = x.v;
  if (GetContext().directive == llvm::acc::Directive::ACCD_update &&
      ((accSelfClause &&
           std::holds_alternative<std::optional<parser::ScalarLogicalExpr>>(
               (*accSelfClause).u)) ||
          !accSelfClause)) {
    context_.Say(GetContext().clauseSource,
        "SELF clause on the %s directive must have a var-list"_err_en_US,
        ContextDirectiveAsFortran());
  } else if (GetContext().directive != llvm::acc::Directive::ACCD_update &&
      accSelfClause &&
      std::holds_alternative<parser::AccObjectList>((*accSelfClause).u)) {
    const auto &accObjectList =
        std::get<parser::AccObjectList>((*accSelfClause).u);
    if (accObjectList.v.size() != 1) {
      context_.Say(GetContext().clauseSource,
          "SELF clause on the %s directive only accepts optional scalar logical"
          " expression"_err_en_US,
          ContextDirectiveAsFortran());
    }
  }
}

void AccStructureChecker::Enter(const parser::AccClause::Collapse &x) {
  CheckAllowed(llvm::acc::Clause::ACCC_collapse);
  CheckAllowedOncePerGroup(
      llvm::acc::Clause::ACCC_collapse, llvm::acc::Clause::ACCC_device_type);
  const parser::AccCollapseArg &accCollapseArg = x.v;
  const auto &collapseValue{
      std::get<parser::ScalarIntConstantExpr>(accCollapseArg.t)};
  RequiresConstantPositiveParameter(
      llvm::acc::Clause::ACCC_collapse, collapseValue);
}

void AccStructureChecker::Enter(const parser::AccClause::Present &x) {
  CheckAllowed(llvm::acc::Clause::ACCC_present);
  CheckMultipleOccurrenceInDeclare(x.v, llvm::acc::Clause::ACCC_present);
}

void AccStructureChecker::Enter(const parser::AccClause::Copy &x) {
  CheckAllowed(llvm::acc::Clause::ACCC_copy);
  CheckMultipleOccurrenceInDeclare(x.v, llvm::acc::Clause::ACCC_copy);
}

void AccStructureChecker::Enter(const parser::AccClause::Deviceptr &x) {
  CheckAllowed(llvm::acc::Clause::ACCC_deviceptr);
  CheckMultipleOccurrenceInDeclare(x.v, llvm::acc::Clause::ACCC_deviceptr);
}

void AccStructureChecker::Enter(const parser::AccClause::DeviceResident &x) {
  CheckAllowed(llvm::acc::Clause::ACCC_device_resident);
  CheckMultipleOccurrenceInDeclare(
      x.v, llvm::acc::Clause::ACCC_device_resident);
}

void AccStructureChecker::Enter(const parser::AccClause::Link &x) {
  CheckAllowed(llvm::acc::Clause::ACCC_link);
  CheckMultipleOccurrenceInDeclare(x.v, llvm::acc::Clause::ACCC_link);
}

void AccStructureChecker::Enter(const parser::AccClause::Shortloop &x) {
  if (CheckAllowed(llvm::acc::Clause::ACCC_shortloop)) {
    context_.Warn(common::UsageWarning::OpenAccUsage, GetContext().clauseSource,
        "Non-standard shortloop clause ignored"_warn_en_US);
  }
}

void AccStructureChecker::Enter(const parser::AccClause::If &x) {
  CheckAllowed(llvm::acc::Clause::ACCC_if);
  if (const auto *expr{GetExpr(x.v)}) {
    if (auto type{expr->GetType()}) {
      if (type->category() == TypeCategory::Integer ||
          type->category() == TypeCategory::Logical) {
        return; // LOGICAL and INTEGER type supported for the if clause.
      }
    }
  }
  context_.Say(
      GetContext().clauseSource, "Must have LOGICAL or INTEGER type"_err_en_US);
}

void AccStructureChecker::Enter(const parser::OpenACCEndConstruct &x) {
  context_.Warn(common::UsageWarning::OpenAccUsage, x.source,
      "Misplaced OpenACC end directive"_warn_en_US);
}

void AccStructureChecker::Enter(const parser::Module &) {
  declareSymbols.clear();
}

void AccStructureChecker::Enter(const parser::FunctionSubprogram &x) {
  declareSymbols.clear();
}

void AccStructureChecker::Enter(const parser::SubroutineSubprogram &) {
  declareSymbols.clear();
}

void AccStructureChecker::Enter(const parser::SeparateModuleSubprogram &) {
  declareSymbols.clear();
}

void AccStructureChecker::Enter(const parser::DoConstruct &) {
  ++loopNestLevel;
}

void AccStructureChecker::Leave(const parser::DoConstruct &) {
  --loopNestLevel;
}

llvm::StringRef AccStructureChecker::getDirectiveName(
    llvm::acc::Directive directive) {
  return llvm::acc::getOpenACCDirectiveName(directive);
}

llvm::StringRef AccStructureChecker::getClauseName(llvm::acc::Clause clause) {
  return llvm::acc::getOpenACCClauseName(clause);
}

} // namespace Fortran::semantics

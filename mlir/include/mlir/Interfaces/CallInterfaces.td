//===- CallInterfaces.td - Call Interfaces for ops ---------*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file contains a set of interfaces that can be used to define information
// related to call-like and callable operations. Each of which are defined along
// with the respective interface below.
//
//===----------------------------------------------------------------------===//

#ifndef MLIR_INTERFACES_CALLINTERFACES
#define MLIR_INTERFACES_CALLINTERFACES

include "mlir/IR/OpBase.td"


/// Interface for operations with result and argument attributes.
def ArgAndResultAttrsOpInterface : OpInterface<"ArgAndResultAttrsOpInterface"> {
  let description = [{
    An operation that has argument and result attributes. This interface
    provides functions to access and modify the argument and result
    attributes of the operation.
  }];
  let cppNamespace = "::mlir";

  list<InterfaceMethod> methods = [
    InterfaceMethod<[{
        Get the array of argument attribute dictionaries. The method should
        return an array attribute containing only dictionary attributes equal in
        number to the number of arguments. Alternatively, the method can
        return null to indicate that there are no argument attributes.
      }],
      "::mlir::ArrayAttr", "getArgAttrsAttr">,
    InterfaceMethod<[{
        Get the array of result attribute dictionaries. The method should return
        an array attribute containing only dictionary attributes equal in number
        to the number of results. Alternatively, the method can return
        null to indicate that there are no result attributes.
      }],
      "::mlir::ArrayAttr", "getResAttrsAttr">,
    InterfaceMethod<[{
      Set the array of argument attribute dictionaries.
    }],
    "void", "setArgAttrsAttr", (ins "::mlir::ArrayAttr":$attrs)>,
    InterfaceMethod<[{
      Set the array of result attribute dictionaries.
    }],
    "void", "setResAttrsAttr", (ins "::mlir::ArrayAttr":$attrs)>,
    InterfaceMethod<[{
      Remove the array of argument attribute dictionaries. This is the same as
      setting all argument attributes to an empty dictionary. The method should
      return the removed attribute.
    }],
    "::mlir::Attribute", "removeArgAttrsAttr">,
    InterfaceMethod<[{
      Remove the array of result attribute dictionaries. This is the same as
      setting all result attributes to an empty dictionary. The method should
      return the removed attribute.
    }],
    "::mlir::Attribute", "removeResAttrsAttr">
  ];
}

// `CallInterfaceCallable`: This is a type used to represent a single callable
// region. A callable is either a symbol, or an SSA value, that is referenced by
// a call-like operation. This represents the destination of the call.

/// Interface for call-like operations.
def CallOpInterface : OpInterface<"CallOpInterface",
                                  [ArgAndResultAttrsOpInterface]> {
  let description = [{
    A call-like operation is one that transfers control from one sub-routine to
    another. These operations may be traditional direct calls `call @foo`, or
    indirect calls to other operations `call_indirect %foo`. An operation that
    uses this interface, must *not* also provide the `CallableOpInterface`.
  }];
  let cppNamespace = "::mlir";

  let methods = [
    InterfaceMethod<[{
        Returns the callee of this call-like operation. A `callee` is either a
        reference to a symbol, via SymbolRefAttr, or a reference to a defined
        SSA value. If the reference is an SSA value, the SSA value corresponds
        to a region of a lambda-like operation.
      }],
      "::mlir::CallInterfaceCallable", "getCallableForCallee"
    >,
    InterfaceMethod<[{
        Sets the callee of this call-like operation. A `callee` is either a
        reference to a symbol, via SymbolRefAttr, or a reference to a defined
        SSA value. The type of the `callee` is expected to be the same as the
        return type of `getCallableForCallee`, e.g., `callee` should be
        SymbolRefAttr for `func.call`.
      }],
      "void", "setCalleeFromCallable", (ins "::mlir::CallInterfaceCallable":$callee)
    >,
    InterfaceMethod<[{
        Returns the operands within this call that are used as arguments to the
        callee.
      }],
      "::mlir::Operation::operand_range", "getArgOperands"
    >,
    InterfaceMethod<[{
        Returns the operands within this call that are used as arguments to the
        callee as a mutable range.
      }],
      "::mlir::MutableOperandRange", "getArgOperandsMutable"
    >,
    InterfaceMethod<[{
        Resolve the callable operation for given callee to a
        CallableOpInterface, or nullptr if a valid callable was not resolved.
        `symbolTable` parameter allow for using a cached symbol table for symbol
        lookups instead of performing an O(N) scan.
      }],
      "::mlir::Operation *", "resolveCallableInTable", (ins "::mlir::SymbolTableCollection *":$symbolTable),
      /*methodBody=*/[{}], /*defaultImplementation=*/[{
        return ::mlir::call_interface_impl::resolveCallable($_op, symbolTable);
      }]
    >,
    InterfaceMethod<[{
        Resolve the callable operation for given callee to a
        CallableOpInterface, or nullptr if a valid callable was not resolved.
    }],
      "::mlir::Operation *", "resolveCallable", (ins),
      /*methodBody=*/[{}], /*defaultImplementation=*/[{
        return ::mlir::call_interface_impl::resolveCallable($_op);
      }]
    >
  ];
}

/// Interface for callable operations.
def CallableOpInterface : OpInterface<"CallableOpInterface",
                                      [ArgAndResultAttrsOpInterface]> {
  let description = [{
    A callable operation is one who represents a potential sub-routine, and may
    be a target for a call-like operation (those providing the CallOpInterface
    above). These operations may be traditional functional operation
    `func @foo(...)`, as well as function producing operations
    `%foo = dialect.create_function(...)`. These operations may only contain a
    single region, or subroutine.
  }];
  let cppNamespace = "::mlir";

  let methods = [
    InterfaceMethod<[{
      Returns the region on the current operation that is callable. This may
      return null in the case of an external callable object, e.g. an external
      function.
    }],
    "::mlir::Region *", "getCallableRegion">,
    InterfaceMethod<[{
      Returns the callable's argument types based exclusively on the type (to
      allow for this method may be called on function declarations).
    }],
    "::llvm::ArrayRef<::mlir::Type>", "getArgumentTypes">,
    InterfaceMethod<[{
      Returns the callable's result types based exclusively on the type (to
      allow for this method may be called on function declarations).
    }],
    "::llvm::ArrayRef<::mlir::Type>", "getResultTypes">,
  ];
}

#endif // MLIR_INTERFACES_CALLINTERFACES

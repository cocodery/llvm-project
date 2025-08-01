lldb_tablegen(SymbolFileDWARFProperties.inc -gen-lldb-property-defs
  SOURCE SymbolFileDWARFProperties.td
  TARGET LLDBPluginSymbolFileDWARFPropertiesGen)

lldb_tablegen(SymbolFileDWARFPropertiesEnum.inc -gen-lldb-property-enum-defs
  SOURCE SymbolFileDWARFProperties.td
  TARGET LLDBPluginSymbolFileDWARFPropertiesEnumGen)

add_lldb_library(lldbPluginSymbolFileDWARF PLUGIN
  AppleDWARFIndex.cpp
  DebugNamesDWARFIndex.cpp
  DIERef.cpp
  DWARFASTParser.cpp
  DWARFASTParserClang.cpp
  DWARFAttribute.cpp
  DWARFBaseDIE.cpp
  DWARFCompileUnit.cpp
  DWARFContext.cpp
  DWARFDataExtractor.cpp
  DWARFDebugAranges.cpp
  DWARFDebugInfo.cpp
  DWARFDebugInfoEntry.cpp
  DWARFDebugMacro.cpp
  DWARFDeclContext.cpp
  DWARFDefines.cpp
  DWARFDIE.cpp
  DWARFFormValue.cpp
  DWARFIndex.cpp
  DWARFTypeUnit.cpp
  DWARFUnit.cpp
  LogChannelDWARF.cpp
  ManualDWARFIndex.cpp
  ManualDWARFIndexSet.cpp
  NameToDIE.cpp
  SymbolFileDWARF.cpp
  SymbolFileDWARFDwo.cpp
  SymbolFileDWARFDebugMap.cpp
  SymbolFileWasm.cpp
  UniqueDWARFASTType.cpp

  LINK_COMPONENTS
    DebugInfoDWARF
    Support
  LINK_LIBS
    lldbCore
    lldbExpression
    lldbHost
    lldbInterpreter
    lldbSymbol
    lldbTarget
    lldbUtility
    lldbValueObject
    lldbPluginObjCLanguage
    lldbPluginCPlusPlusLanguage
    lldbPluginExpressionParserClang
    lldbPluginTypeSystemClang
  CLANG_LIBS
    clangAST
    clangBasic
  )

add_dependencies(lldbPluginSymbolFileDWARF
  LLDBPluginSymbolFileDWARFPropertiesGen
  LLDBPluginSymbolFileDWARFPropertiesEnumGen)

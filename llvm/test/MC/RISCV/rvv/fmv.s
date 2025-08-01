# RUN: llvm-mc -triple=riscv64 -show-encoding --mattr=+zve32f %s \
# RUN:     | FileCheck %s --check-prefixes=CHECK-ENCODING,CHECK-INST
# RUN: not llvm-mc -triple=riscv64 -show-encoding %s 2>&1 \
# RUN:     | FileCheck %s --check-prefix=CHECK-ERROR
# RUN: llvm-mc -triple=riscv64 -filetype=obj --mattr=+zve32f %s \
# RUN:     | llvm-objdump -d --mattr=+zve32f - \
# RUN:     | FileCheck %s --check-prefix=CHECK-INST
# RUN: llvm-mc -triple=riscv64 -filetype=obj --mattr=+zve32f %s \
# RUN:     | llvm-objdump -d - | FileCheck %s --check-prefix=CHECK-UNKNOWN

vfmv.v.f v8, fa0
# CHECK-INST: vfmv.v.f v8, fa0
# CHECK-ENCODING: [0x57,0x54,0x05,0x5e]
# CHECK-ERROR: instruction requires the following: 'V'{{.*}}'Zve32f' (Vector Extensions for Embedded Processors){{$}}
# CHECK-UNKNOWN: 5e055457 <unknown>

vfmv.f.s fa0, v4
# CHECK-INST: vfmv.f.s fa0, v4
# CHECK-ENCODING: [0x57,0x15,0x40,0x42]
# CHECK-ERROR: instruction requires the following: 'V'{{.*}}'Zve32f' (Vector Extensions for Embedded Processors){{$}}
# CHECK-UNKNOWN: 42401557 <unknown>

vfmv.s.f v8, fa0
# CHECK-INST: vfmv.s.f v8, fa0
# CHECK-ENCODING: [0x57,0x54,0x05,0x42]
# CHECK-ERROR: instruction requires the following: 'V'{{.*}}'Zve32f' (Vector Extensions for Embedded Processors){{$}}
# CHECK-UNKNOWN: 42055457 <unknown>

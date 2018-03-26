# Mpint
# Copyright 2018 Status Research & Development GmbH
# Licensed under either of
#
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
#  * MIT license ([LICENSE-MIT](LICENSE-MIT) or http://opensource.org/licenses/MIT)
#
# at your option. This file may not be copied, modified, or distributed except according to those terms.

# TODO: test if GCC/Clang support uint128 natively

import macros


# The macro getMpUintImpl must be exported

when defined(mpint_test):
  macro getMpUintImpl*(bits: static[int]): untyped =
    # Test version, mpuint[64] = 2 uint32. Test the logic of the library
    assert (bits and (bits-1)) == 0, $bits & " is not a power of 2"
    assert bits >= 16, "The number of bits in a should be greater or equal to 16"

    if bits >= 128:
      let inner = getAST(getMpUintImpl(bits div 2))
      result = newTree(nnkBracketExpr, ident("MpUintImpl"), inner)
    elif bits == 64:
      result = newTree(nnkBracketExpr, ident("MpUintImpl"), ident("uint32"))
    elif bits == 32:
      result = newTree(nnkBracketExpr, ident("MpUintImpl"), ident("uint16"))
    elif bits == 16:
      result = newTree(nnkBracketExpr, ident("MpUintImpl"), ident("uint8"))
    else:
      error "Fatal: unreachable"
else:
  macro getMpUintImpl*(bits: static[int]): untyped =
    # Release version, mpuint[64] = uint64.
    assert (bits and (bits-1)) == 0, $bits & " is not a power of 2"
    assert bits >= 8, "The number of bits in a should be greater or equal to 8"

    if bits >= 128:
      let inner = getAST(getMpUintImpl(bits div 2))
      result = newTree(nnkBracketExpr, ident("MpUintImpl"), inner)
    elif bits == 64:
      result = ident("uint64")
    elif bits == 32:
      result = ident("uint32")
    elif bits == 16:
      result = ident("uint16")
    elif bits == 8:
      result = ident("uint8")
    else:
      error "Fatal: unreachable"

type
  # ### Private ### #
  # If this is not in the same type section
  # the compiler has trouble
  BaseUint* = MpUintImpl or SomeUnsignedInt

  MpUintImpl*[Baseuint] = object
    when system.cpuEndian == littleEndian:
      lo*, hi*: BaseUint
    else:
      hi*, lo*: BaseUint
  # ### Private ### #

  MpUint*[bits: static[int]] = object
    data*: getMpUintImpl(bits)
    # wrapped in object to avoid recursive calls
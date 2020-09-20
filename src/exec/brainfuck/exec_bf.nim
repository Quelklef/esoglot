import strutils
import sequtils

proc abort(msg: string): void =
  echo msg
  quit 1

type InstrKind = enum
  ik_right  # >
  ik_left   # <
  ik_inc    # +
  ik_dec    # -
  ik_put    # .
  ik_get    # ,
  ik_open   # [
  ik_close  # ]

type Instr = object
  case kind: InstrKind
  of ik_right, ik_left, ik_inc, ik_dec, ik_put, ik_get:
    discard
  of ik_open, ik_close:
    target: uint64  # jump-to location

proc find_close(code: string, open_idx: int): int =
  ## Given the position of an open brace, return the position of its close brace
  var depth = 0
  for idx in open_idx ..< code.len:
    let ch = code[idx]
    if ch == '[':
      depth += 1
    elif ch == ']':
      depth -= 1
      if depth == 0:
        return idx

  abort "Umatched brace at position " & $open_idx

proc find_open(code: string, close_idx: int): int =
  ## Like ``find_close``, but for close braces
  var depth = 0
  for idx in countdown(close_idx, 0):
    let ch = code[idx]
    if ch == ']':
      depth += 1
    elif ch == '[':
      depth -= 1
      if depth == 0:
        return idx

  abort "Unmatched brace at position " & $close_idx

proc parse(code: string): seq[Instr] =
  let code = code.to_seq.filterIt(it in "><+-.,[]").join("")
  for idx, ch in code:
    case ch
    of '>': result.add Instr(kind: ik_right)
    of '<': result.add Instr(kind: ik_left)
    of '+': result.add Instr(kind: ik_inc)
    of '-': result.add Instr(kind: ik_dec)
    of '.': result.add Instr(kind: ik_put)
    of ',': result.add Instr(kind: ik_get)
    # vv Yes, these are Schlemiel the Painter's algorithms.
    #    But they run at parse time, not runtime, so they're not high-priority
    of '[': result.add Instr(kind: ik_open, target: find_close(code, idx).uint64)
    of ']': result.add Instr(kind: ik_close, target: find_open(code, idx).uint64)
    else: discard

proc exec(instrs: seq[Instr]) =

  # Represent the tape as two sequences,
  # one at positive positions (and 0)
  # and one at negative positions
  var tape_pos: seq[uint8] = @[0'u8]
  var tape_neg: seq[uint8] = @[]

  template tape_get(idx: int): uint8 =
    if idx >= 0:
      tape_pos[idx]
    else:
      tape_neg[-idx - 1]

  template tape_set(idx: int, val: uint8) =
    if idx >= 0:
      tape_pos[idx] = val
    else:
      tape_neg[-idx - 1] = val

  var instr_ptr: uint64 = 0
  var tape_ptr: int = 0

  while instr_ptr < instrs.len.uint64:
    let instr = instrs[instr_ptr]

    case instr.kind

    of ik_right:
      tape_ptr.inc
      if tape_ptr >= tape_pos.len:
        tape_pos.add 0
      instr_ptr += 1

    of ik_left:
      tape_ptr.dec
      if -tape_ptr - 1 >= tape_neg.len:
        tape_neg.add 0
      instr_ptr += 1

    of ik_inc:
      tape_set tape_ptr, tape_get(tape_ptr) + 1
      instr_ptr += 1

    of ik_dec:
      tape_set tape_ptr, tape_get(tape_ptr) - 1
      instr_ptr += 1

    of ik_put:
      stdout.write cast[char](tape_get tape_ptr)
      instr_ptr += 1

    of ik_get:
      let ch = try: stdin.read_char except EOFError: '\0'
      tape_set tape_ptr, cast[uint8](ch)
      instr_ptr += 1

    of ik_open:
      if tape_get(tape_ptr) == 0:
        instr_ptr = instr.target + 1
      else:
        instr_ptr += 1

    of ik_close:
      instr_ptr = instr.target

when is_main_module:
  let bf_code = stdin.read_all
  let instrs = parse(bf_code)
  exec instrs
  stdout.close

import os
import strutils

var ook_code = stdin.read_all
var bf_code: string = ""

const mapping = {
  "Ook. Ook?": ">",
  "Ook? Ook.": "<",
  "Ook. Ook.": "+",
  "Ook! Ook!": "-",
  "Ook! Ook.": ".",
  "Ook. Ook!": ",",
  "Ook! Ook?": "[",
  "Ook? Ook!": "]",
}

var ook_idx = 0
while ook_idx < ook_code.len:
  for (ook_instr, bf_instr) in mapping:
    if ook_code[ook_idx ..< ook_code.len].starts_with ook_instr:
      bf_code &= bf_instr
      ook_idx += ook_instr.len
      continue
  ook_idx += 1

echo bf_code

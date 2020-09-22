import sys


class Tape:
  def __init__(self):
    self.right = []
    self.left = []

  def _accomodate(self, index):
    # Ensure the tape is large enough to include the given index
    if index >= 0:
      self.right += [0] * (index - len(self.right) + 1)
    else:
      self.left += [0] * ((-index - 1) - len(self.left) + 1)

  def __getitem__(self, index):
    self._accomodate(index)
    if index >= 0:
      return self.right[index]
    else:
      return self.left[-index - 1]

  def __setitem__(self, index, val):
    self._accomodate(index)
    if index >= 0:
      self.right[index] = val
    else:
      self.left[-index - 1] = val


def braces_balanced(code):
  # Returns whether or not the code has balanced braces
  depth = 0
  for c in code:
    if c == '[':
      depth += 1
    elif c == ']':
      depth -= 1
  return depth == 0


def build_pair_table(code):
  # Returns a dictionary T such that for each brace '[' and ']' in
  # the code, T[index of the brace] is the index of the other brace
  table = dict()

  stack = []
  for i, c in enumerate(code):
    if c == '[':
      stack.append(i)
    elif c == ']':
      table[i] = stack.pop()

  stack = []
  for ri, c, in enumerate(reversed(code)):
    i = len(code) - ri - 1
    if c == ']':
      stack.append(i)
    elif c == '[':
      table[i] = stack.pop()

  return table


def execute(code):

  # Make sure syntax is OK
  if not braces_balanced(code):
    print("Braces aren't balanced")
    sys.exit(1)

  # Trim irrelevant chars
  meaningful_chars = "><+-.,[]"
  code = ''.join(filter(meaningful_chars.__contains__, code))

  # Find what instructions braces jump to
  pair_table = build_pair_table(code)

  # Begin execution
  tape = Tape()
  tape_ptr = 0
  code_ptr = 0

  while code_ptr >= 0 and code_ptr < len(code):
    cmd = code[code_ptr]

    if cmd == '>':
      tape_ptr += 1
      code_ptr += 1

    elif cmd == '<':
      tape_ptr -= 1
      code_ptr += 1

    elif cmd == '+':
      tape[tape_ptr] += 1
      code_ptr += 1

    elif cmd == '-':
      tape[tape_ptr] -= 1
      code_ptr += 1

    elif cmd == '.':
      print(chr(tape[tape_ptr] % 128), end='')
      code_ptr += 1

    elif cmd == ',':
      has_no_stdin = sys.stdin.isatty()  # might be a hack? unclear
      if has_no_stdin:
        tape[tape_ptr] = 0
      else:
        char = sys.stdin.read(1)
        tape[tape_ptr] = 0 if not char else ord(char)

      code_ptr += 1

    elif cmd == '[':
      if tape[tape_ptr] == 0:
        code_ptr = pair_table[code_ptr] + 1
      else:
        code_ptr += 1

    elif cmd == ']':
      code_ptr = pair_table[code_ptr]


if __name__ == '__main__':

  if len(sys.argv) != 2:
    print("Expected exactly 1 argument")
    sys.exit(1)

  code = sys.argv[1]
  execute(code)

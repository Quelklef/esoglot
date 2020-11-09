
/* Brainfuck tape */
export class Tape {

  constructor(cells = [], pointer = 0) {
    // Cells are stored as a mapping index -> value, where negative indices are allowed
    // This is pretty inefficient, but we don't ever use very large tapes so it's fine
    this.cells = cells;
    // Tape pointer
    this.pointer = pointer;
  }

  _validateIndex(at) {
    if (typeof at !== 'number')
      throw new Error('Non-number index: bad!!');
  }

  get(at) {
    this._validateIndex(at);
    return at in this.cells ? this.cells[at] : 0;
  }

  set(at, val) {
    this._validateIndex(at);
    this.cells[at] = val;
  }

  /*
   * Parses a Brainfuck tape
   *
   * Syntax looks like this:
   *   1 2 | 3 [4] 5 6
   * For this tape, 1 and 2 have negative indices; the rest have nonnegative indices.
   * The [brackets] around 4 mean that it is the value being pointed to.
   */
  static parse(string) {
    if (!string.includes('[') || /\[.*\[/.test(string))
      throw new Error("Expected exactly 1 active cell");
    if (/\|.*\|/.test(string))
      throw new Error("Expected at most 1 bar ");

    if (!string.includes('|'))
      string = '| ' + string;

    // Due to cells having negative indices, what is the offset
    // between the index of a number in `string` and its tape index?
    const offset = -string.match(/\d+|\|/g).indexOf('|');

    // Construct tape cells
    const cells = {};
    string.match(/\d+/g).forEach((number, index) => {
      cells[index + offset] = parseInt(number, 10);
    });

    // Calculate the tape pointer
    const pointer = offset + string.match(/[\d\[]+/g).findIndex(part => part[0] === '[');

    return new Tape(cells, pointer);
  }

  /* Return all cell indexes */
  get _cellIdxs() {
    return new Set(Object.keys(this.cells).map(idx => parseInt(idx)));
  }

  /*
   * Returns a tape, printed prettily.
   * This is a right-inverse of Tape.parse
   * i.e. we guarantee that:
   *   Tape.parse(tape.pretty).equals(tape)
   *
   * This also places spacing between chunks of 3 cells
   */
  get pretty() {
    const minCellIdx = Math.min(0, ...this._cellIdxs);
    const maxCellIdx = Math.max(0, ...this._cellIdxs);
    // ^ Include 0 as arguments to min/max so that the tape is always shown up to the 0th cell

    return (
      range(minCellIdx, maxCellIdx)
      .map(cellIdx => {
        let str = '' + this.get(cellIdx);
        if (cellIdx === this.pointer)
          str = `[${str}]`;
        if (cellIdx === 0 && minCellIdx < 0)
          str = `| ${str}`;
        if (mod(cellIdx, 3) === 0)
          str = `  ${str}`;
        return str;
      })
      .join(' ')
    );
  }

  /* Return if two tapes are equal or not */
  equals(other) {
    const cellIdxsUnion = new Set([...this._cellIdxs, ...other._cellIdxs]);
    return [...cellIdxsUnion].every(cellIdx => this.get(cellIdx) === other.get(cellIdx));
  }

}

/* Remove comments and extraneous characters from brainfuck code */
function distill(code) {
  // Remove comments
  const commentMarker = '#'
  code = code.split('\n').map(line => line.split(commentMarker)[0]).join('\n')

  // Remove extraneous characters
  const meaningfulChars = '+-[]<>.,';
  code = [...code].filter(char => meaningfulChars.includes(char)).join('');

  return code;
}

/* Minify some brainfuck code.
   Removes comments and extraneous characters;
   also removes some provably-redundant characters such as a '+' followed by a '-' */
export function minify(code) {
  code = distill(code);

  while (true) {
    const reduced = reduce(code);
    if (reduced === code)
      return code;
    code = reduced;
  }

  /* Do some amount of minification on the code, if possile;
     if not possible, return the code as-is */
  function reduce(code) {
    let reduced = '';

    let i = 0;
    while (i < code.length) {
      // remove '+-', '-+', '><', and '<>' pairs
      if (
        code[i] === '+' && code[i + 1] === '-'
        || code[i] === '-' && code[i + 1] === '+'
        || code[i] === '>' && code[i + 1] === '<'
        || code[i] === '<' && code[i + 1] === '>'
      ) {
        i += 2;
      } else {
        reduced += code[i];
        i++;
      }
    }

    return reduced;
  }
}

/*
 * Run some brainfuck code.
 * This partiuclar implementation follows the following specs:
 * - 8-bit wrapping cells
 * - tape unbounded to both left and right
 * - reading EOF zeroes out current cell
 * - comments via '#'
 */
export function runBrainfuck(instructions, textIn = '', initialTape = new Tape()) {

  instructions = distill(instructions);

  // Pair brackets
  const jumpTable = buildJumpTable(instructions);

  // Initialize
  const tape = initialTape;
  let instructionPointer = 0;
  let textOut = '';

  // Keep track of the minimum cell index we reach
  let minIndexReached = 0;

  while (instructionPointer < instructions.length) {
    const instruction = instructions[instructionPointer];
    switch (instruction) {

      case '+':
        tape.set(tape.pointer, mod(tape.get(tape.pointer) + 1, 256));
        instructionPointer++;
        break;

      case '-':
        tape.set(tape.pointer, mod(tape.get(tape.pointer) - 1, 256));
        instructionPointer++;
        break;

      case '[':
        if (tape.get(tape.pointer) === 0)
          instructionPointer = jumpTable[instructionPointer] + 1;
        else
          instructionPointer++;
        break;

      case ']':
        instructionPointer = jumpTable[instructionPointer];
        break;

      case '>':
        tape.pointer++;
        instructionPointer++;
        break;

      case '<':
        tape.pointer--;
        instructionPointer++;
        minIndexReached = Math.min(minIndexReached, tape.pointer);
        break;

      case '.':
        textOut += String.fromCharCode(tape.get(tape.pointer));
        instructionPointer++;
        break;

      case ',':
        tape.set(tape.pointer, textIn === '' ? 0 : textIn.charCodeAt(0));
        textIn = textIn.slice(1);
        instructionPointer++;
        break;

      default:
        throw 'oops';

    }
  }

  return {
    tape,
    textOut,
    minIndexReached,
  };

}

/* Calculate a modulo */
function mod(a, k) {
  // Ripped from https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Remainder
  return ((a % k) + k) % k;
}

/* Construct an inclusive range */
function range(lo, hi) {
  return new Array(hi - lo + 1).fill(null).map((_, i) => lo + i);
}

function buildJumpTable(code) {
  const table = {};

  let stack = [];
  for (let i = 0; i < code.length; i++) {
    const cmd = code[i];
    if (cmd === '[') {
      stack.push(i);
    } else if (cmd === ']') {
      if (stack.length === 0) throw 'unbalanced braces';
      table[i] = stack.pop();
    }
  }
  if (stack.length !== 0) throw 'unbalanced braces';

  stack = [];
  for (let i = code.length - 1; i >= 0; i--) {
    const cmd = code[i];
    if (cmd === ']') {
      stack.push(i);
    } else if (cmd === '[') {
      if (stack.length === 0) throw 'unbalanced braeces';
      table[i] = stack.pop();
    }
  }
  if (stack.length !== 0) throw 'unbalanced braces';

  return table;
}

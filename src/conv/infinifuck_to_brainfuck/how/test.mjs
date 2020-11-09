
import { runBrainfuck, Tape } from './brainfuck.mjs';

export function test({ desc, cmds, tape, want, stdin, wantStdout, leftBounded }) {
  want = Tape.parse(want);
  wantStdout = wantStdout || '';

  process.stdout.write(`${desc} ... `);

  const got = runBrainfuck(cmds, stdin || '', Tape.parse(tape));

  if (leftBounded && got.minIndexReached < 0)
    throw `failed: tape was bounded to the left but algorithm reached as low as index ${got.minIndexReached}`;
  if (!got.tape.equals(want))
    throw `failed: want tape:\n\t${want.pretty}\nbut got:\n\t${got.tape.pretty}`;
  if (got.textOut !== wantStdout)
    throw `failed: want stdout:\n\t${wantStdout}\nbut got:\n\t${got.textOut}`;

  process.stdout.write('ok\n');
}

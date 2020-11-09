
import { minify } from './brainfuck.mjs';
import { test } from './test.mjs';

/*

Our goal: to compile [infinifuck](https://esolangs.org/wiki/Infinifuck) code
into [brainfuck](https://esolangs.org/wiki/Brainfuck) code.

---

In order to do this, we need some way to represent one of infinifuck's unbounded
values on the brainfuck tape at runtime.

We'll consider the brainfuck tape as split into chunks of 3 cells called *triplets*.

An infinifuck number, called an *integer*, will be represented as a sequence
of triplets in a special format and known as *digits*.
The 3 cells in a digit are named %flag %x %data. We set %flag to 1 in order to
distinguish digit triplets from non-digit triplets. Then we set %x to 0 and
allow %data to be any number, since it contains the actual data of the digit.
Essentially, we represent an infinifuck number as base-256.

Integers will be separated from other integers by triplets called *spacing triplets*.
The 3 cells in a spacing triplet are named %a %b %c and all have value 0.

The brainfuck tape thus looks like this:

         triplet        triplet
     vvvvvvvvvvvvvv     vvvvvvvv

     cell cell cell  cell cell cell
     vvvvv vv vvvvv     vv vv vv

 ( ( %flag %x %data )*N %a %b %c )*K
   | |            |   |
   | ^^^^^^^^^^^^^^   | ^^^^^^^^
   |    a digit       | a spacing triplet
   |                  |
   ^^^^^^^^^^^^^^^^^^^^
        an integer

When we refer to a cell, it will be in the context of a particular triplet, digit,
or integer. So when we write "%x", that will most often mean "the %x cell of the
relevant digit"; likewise, "%a" will most often mean "the %a cell after the relevant
integer".

We will use the syntax %A(+B) to mean the cell B cells to the right of the %A cell.
For instance, %a(+2) is %c.

Additionally, we will use the syntax %A/%B to refer to a single cell that may have
different meanings depending on program state. For instance, if we don't know
whether we're on a digit triplet or a non-digit triplet, then we may refer to the
first cell in the triplet as %flag/%a instead of %flag or %a in order to make both
possibilities explicit.

---

Note that the tape format (i.e. the constraints on %flag, %x, %data, %a, %b, and %c)
may be broken *during* an operation, so that we may use those cells to perform
computations; however, the constraints will always hold before and after the
operation.

Additionally, all operations will demand as a precondition and
guarantee as a postcondition that the tape pointer is on the %flag value
of an integer.

---

To do the actual infinifuck -> brainfuck compilation, it will suffice to map each
infinifuck instruction to a string of brainfuck operations, and then include a string
of instructions called the "preamble" at the front of the result.

Also, because infinifuck and brainfuck operations are called the same thing (+-><[].,),
we will refer to the infinifuck operations instead as:
  PLUS
  MINUS
  RIGHT
  LEFT
  OPEN
  CLOSE
  GET
  PUT
respectively

*/

const RIGHT = minify(`

# Start on the leftmost %flag of  an integer
# Moves to the leftmost %flag of the next integer
# If there is no next integer, creates one

[>>>]>>>  # move to %a(+3)
          # if this value is 1, then we"re on the %flag of the next integer
          # if it"s 0, then there is no text integer
[-]+      # set %a(+3) to 1
          # if there is indeed a next integer, this has no effect
          # otherwise, it transforms the empty triplet into a digit

`);

/*

Test RIGHT under all combinations of the following settings:
1. integer has 1 digit or >1 digit
2. integer has value 0 or >0
3. already exists a succeeding integer or need to make a new one

*/

test({
  desc: "RIGHT: 1 digit , zero , dest exists",
  cmds: RIGHT,
  tape: "[1] 0 0   0 0 0    1  0 0",
  want: " 1  0 0   0 0 0   [1] 0 0",
});

test({
  desc: "RIGHT: 1 digit , zero , dest missing",
  cmds: RIGHT,
  tape: "[1] 0 0                  ",
  want: " 1  0 0   0 0 0   [1] 0 0",
});

test({
  desc: "RIGHT: 1 digit , nonzero , dest exists",
  cmds: RIGHT,
  tape: "[1] 0 5   0 0 0    1  0 0",
  want: " 1  0 5   0 0 0   [1] 0 0",
});

test({
  desc: "RIGHT: 1 digit , nonzero , dest missing",
  cmds: RIGHT,
  tape: "[1] 0 5                  ",
  want: " 1  0 5   0 0 0   [1] 0 0",
});

test({
  desc: "RIGHT: >1 digits , zero , dest exists",
  cmds: RIGHT,
  tape: "[1] 0 0   1 0 0   1 0 0   0 0 0    1  0 0",
  want: " 1  0 0   1 0 0   1 0 0   0 0 0   [1] 0 0",
});

test({
  desc: "RIGHT: >1 digits , zero , dest missing",
  cmds: RIGHT,
  tape: "[1] 0 0   1 0 0   1 0 0                  ",
  want: " 1  0 0   1 0 0   1 0 0   0 0 0   [1] 0 0",
});

test({
  desc: "RIGHT: >1 digits , nonzero , dest exists",
  cmds: RIGHT,
  tape: "[1] 0 1   1 0 2   1 0 3   0 0 0    0  0 0",
  want: " 1  0 1   1 0 2   1 0 3   0 0 0   [1] 0 0",
});

test({
  desc: "RIGHT: >1 digits , nonzero , dest missing",
  cmds: RIGHT,
  tape: "[1] 0 1   1 0 2   1 0 3                  ",
  want: " 1  0 1   1 0 2   1 0 3   0 0 0   [1] 0 0",
});


const LEFT = minify(`

# Start on the leftmost %flag on an integer
# Moves to the leftmost %flag of the previous integer
# If there is no previous integer, creates one

                  # works analogous to RIGHT
<<<<<<<<<[<<<]>>> # move to the rightmost %flag of the previous integer if there is one
[-]+              # set the cell to 1

`);

test({
  desc: 'LEFT: dest == 0',
  cmds: LEFT,
  tape: " 1  0 0   0 0 0   [1] 0 0",
  want: "[1] 0 0   0 0 0    1  0 0",
});

test({
  desc: 'LEFT: dest missing',
  cmds: LEFT,
  tape: "0 0 0   0 0 0   [1] 0 0",
  want: "[1] 0 0   0 0 0   1 0 0",
});

test({
  desc: 'LEFT: dest == 0, >1 digits',
  cmds: LEFT,
  tape: "1 0 0   1 0 0   1 0 0   0 0 0   [1] 0 0",
  want: "[1] 0 0   1 0 0   1 0 0   0 0 0   1 0 0",
});

test({
  desc: 'LEFT: dest > 0',
  cmds: LEFT,
  tape: "1 0 1   1 0 2   1 0 3   0 0 0   [1] 0 0",
  want: "[1] 0 1   1 0 2   1 0 3   0 0 0   1 0 0",
});


const PLUS = minify(`

# Start on the leftmost %flag of an integer
# Increments the integer

# Algorithm:
# STEP 1: set %x = 1
# STEP 2: while %x
# STEP 3:   increment %data
# STEP 4:   set %x = %data == 0
# STEP 5:   if %x
# STEP 6:     set %x = 0
# STEP 7:     move to the next triplet
# STEP 8:     ensure triplet contains a digit
# STEP 9:     set %x = 1
# STEP A: return to leftmost digit

# where STEP 8 is defined as:
# STEP 8.1: if %flag/%a is 0
# STEP 8.2:   shift all rightwards triplets to the right by 1 triplet
# STEP 8.3:   create a new digit in the cleared chunk

# Here is the implementation:

# STEP 1: set %x = 1
# position: %flag of leftmost digit
>  # move to %x
+  # let %x = 1

# STEP 2: while %x
[ # while %x

  # STEP 3: increment %data
  # position: %x
  >+<  # increment %data

  # STEP 4: set %x = %data == 0
  # position: %x
  -<->               # let %x = %flag = 0
  >[-<+<+>>]<[->+<]  # let %flag = %data
  +<[>-<[-]]+>       # let %x = %flag == 0; let %flag = 1

  # STEP 5: if %x
  [ # branch on %x

    # STEP 6: set %x = 0
    -  # let x = 0

    # STEP 7: move to next chunk
    # position: %x
    >>>  # move 3 cells to the right
         # case 1: we"re on the %x of the next digit
         # case 2: we"re on the %b after the final digit

    # STEP 8: ensure chunk contagets a digit

    # STEP 8.1: if there is no digit
    # position: %x/%b
    +<[>-<-]+>  # Let %x/%b = %flag/%a == 0; let %flag/%a = 1
    [ # branch on %x/%b
      # we will only enter this branch on case 2
      # thus position: %b
      <->-  # let %a = %b = 0

      # STEP 8.2: shift all rightwards triplets to the right by 1 triplet
      # position: %b
      >>[[>>>]>+>>]<<  # traverse all integers to the right
                       # for each set the afterwards %b to 1
                       # end on the %b after the rightmost integer

      [-<<<<[>>[->>>+<<<]>+<<<-<<<]>]  # traverse back leftwards over the integers
                                       # shift each digit over 3 cells
                                       # in the process set the %b values back to 0
                                       # end on the %b from STEP 8.1

      # STEP 8.3: create a new digit get the cleared chunk
      # Position: %b
      <+>  # let %a = 1
           # thus turning the empty triplet into a new digit with %data = 0

    # STEP 8.1
    # position: %x which has value 0 so the loop will terminate
    ]
    # Position: %x

    # STEP 9: set %x = 1
    # position: %x
    +  # set %x = 1

  # STEP 5
  -<->  # let %flag = 0 and %x = 0
        # stay on %x which is 0 so that the loop will terminate
  ]
  # position: %x
  # let %x5 denote the value of %x that controlled the (STEP 5) branch
  # case 1: if %x5 == 0 then %flag = 1; %x = 0
  # case 1: if %x5 == 1 then %flag = 0; %x = 0
  <-[>+<[-]]+>  # normalize to %flag = 1; %x = %x5

# STEP 2
]
# Position: %x

# STEP A: return to the leftmost digit
# position: %x
<         # move to %flag
[<<<]>>>  # move to %flag of leftmost digit

`);

test({
  desc: "PLUS: maps 0 -> 1",
  cmds: PLUS,
  tape: "[1] 0 0",
  want: "[1] 0 1",
});

test({
  desc: "PLUS: maps 1 -> 2",
  cmds: PLUS,
  tape: "[1] 0 1",
  want: "[1] 0 2",
});

test({
  desc: "PLUS: properly rolls over",
  cmds: PLUS,
  tape: "[1] 0 255   1 0 0",
  want: "[1] 0 0     1 0 1",
});

test({
  desc: "PLUS: during rollover, creates a new digit if needed",
  cmds: PLUS,
  tape: "[1] 0 255        ",
  want: "[1] 0 0     1 0 1",
});

test({
  desc: "PLUS: during rollover, shifts over other integers if needed",
  cmds: PLUS,
  tape: "[1] 0 255   0 0 0   1 0 1   1 0 2   0 0 0   1 0 3        ",
  want: "[1] 0 0     1 0 1   0 0 0   1 0 1   1 0 2   0 0 0   1 0 3",
});

test({
  desc: "PLUS: handles multiple rollovers",
  cmds: PLUS,
  tape: "[1] 0 255   1 0 255        ",
  want: "[1] 0 0     1 0 0     1 0 1",
});

test({
  desc: "PLUS: during multiple rollovers, shifts over other integers if needed",
  cmds: PLUS,
  tape: "[1] 0 255   1 0 255   0 0 0   1 0 1   1 0 2        ",
  want: "[1] 0 0     1 0 0     1 0 1   0 0 0   1 0 1   1 0 2",
});


const IS_NONZERO = minify(`

# Start on the leftmost %flag of some integer
# Set %x to 1 iff the integer is nonzero and 0 otherwise

# algorithm:
# STEP 1: go to rightmost digit
# STEP 2: while on a digit
# STEP 3:   let %x = %data != 0
# STEP 4:   let %x = %x || %x(+3); let %x(+3) = 0
# STEP 5:   move to preceding triplet
# STEP 6: move to succeeding triplet

# implementation:

# STEP 1: go to rightmost digit
[>>>]<<<  # go to %flag on rightmost digit

# STEP 2: while on a digit
[ # while %flag/%a
  # loop only entered when %flag/%a is nonzero meaning that we know we"re in a digit

  # STEP 3: let %x = %data != 0
  # position: %flag
  ->>[-<+<+>>]<<[->>+<<]+  # Let %x = %data
  ->[<+>[-]]<[->+<]+       # Let %x = %x != 0

  # STEP 4: let %x = %x || %x(+3); let %x(+3) = 0
  # Position: %flag
  >>>>                # Move to %x(+3)
  [-<<<+>>>]          # Let %x = %x plus %x(+3); let %x(+3) = 0
  <<<<                # Move to %flag
  ->[<+>[-]]<[->+<]+  # Let %x = %x != 0

  # STEP 5: move to preceding triplet
  # Position: %flag
  <<<  # Move to preceding triplet

# STEP 2
]

# STEP 6: move to succeeding chunk
>>>  # move to succeeding triplet

`);

test({
  desc: "IS_NONZERO: works on 0",
  cmds: IS_NONZERO,
  tape: "[1] 0 0",
  want: "[1] 0 0",
});

test({
  desc: "IS_NONZERO: works on 1",
  cmds: IS_NONZERO,
  tape: "[1] 0 1",
  want: "[1] 1 1",
});

test({
  desc: "IS_NONZERO: works on 255",
  cmds: IS_NONZERO,
  tape: "[1] 0 255",
  want: "[1] 1 255",
});

test({
  desc: "IS_NONZERO: isn't broken by trailing value-0 digits",
  cmds: IS_NONZERO,
  tape: "[1] 0 255   1 0 0",
  want: "[1] 1 255   1 0 0",
});

test({
  desc: "IS_NONZERO: checks digits beyond the first",
  cmds: IS_NONZERO,
  tape: "[1] 0 0   1 0 0   1 0 0   1 0 1",
  want: "[1] 1 0   1 0 0   1 0 0   1 0 1",
});

test({
  desc: "IS_NONZERO: isn't borked by the existence of another integer",
  cmds: IS_NONZERO,
  tape: "[1] 0 255   1 0 255   0 0 0   1 0 0",
  want: "[1] 1 255   1 0 255   0 0 0   1 0 0",
});


const MINUS = minify(`

# Start on the leftmost %flag of some integer
# Decrements the integer

# algorithm:
# STEP 1: run IS_NONZERO
# STEP 2: while %x
# STEP 3:   let %x(+3) = %data == 0
# STEP 4:   decrement %data
# STEP 5:   move to next triplet
# STEP 6: return to leftmost digit

# STEP 1: run IS_NONZERO
# position: %flag
${IS_NONZERO}  # run IS_NONZERO

# STEP 2: while %x
# position: %flag
> # move to %x
[ # while %x/%b

  # STEP 3: let %x(+3) = %data == 0
  # position: %x
  -                         # let %x = 0
  <->>[-<+<+>>]<<[->>+<<]+> # let %x = %data
  >>>+<<<[[-]>>>-<<<]       # let %x(+3) = %x == 0; let %x = 0

  # STEP 4: decrement %data
  >-<  # decrement %data

  # STEP 5: move to next triplet
  >>>  # move to %x(+3)

# STEP 2
]

# STEP 6: return to leftmost digit
# position: %x/%b
<            # move to %flag/%a
<<<[<<<]>>>  # move to %flag on leftmost digit

`);

test({
  desc: "MINUS: noop on 0",
  cmds: MINUS,
  tape: "[1] 0 0",
  want: "[1] 0 0",
});

test({
  desc: "MINUS: noop on 0 (multiple digits)",
  cmds: MINUS,
  tape: "[1] 0 0   1 0 0   1 0 0   1 0 0   1 0 0",
  want: "[1] 0 0   1 0 0   1 0 0   1 0 0   1 0 0",
});

test({
  desc: "MINUS: maps 1 -> 0",
  cmds: MINUS,
  tape: "[1] 0 1",
  want: "[1] 0 0",
});

test({
  desc: "MINUS: maps 255 -> 254",
  cmds: MINUS,
  tape: "[1] 0 255",
  want: "[1] 0 254",
});

test({
  desc: "MINUS: properly borrows",
  cmds: MINUS,
  tape: "[1] 0 0     1 0 1",
  want: "[1] 0 255   1 0 0",
});

test({
  desc: "MINUS: properly borrows repeatedly",
  cmds: MINUS,
  tape: "[1] 0   0   1 0 0     1 0 0     1 0 0     1 0 1",
  want: "[1] 0 255   1 0 255   1 0 255   1 0 255   1 0 0",
});


const OPEN = minify(`

# Start on the leftmost %flag of some integer
# Starts a loop which runs while that integer is nonzero

# Position: %flag
${IS_NONZERO}
>  # Move to %x
[  # Brainfuck OPEN
-  # Let %x = 0
<  # Move to %flag

`);


const CLOSE = minify(`

# Position: %flag
${IS_NONZERO}
>  # Move to %x
]  # Brainfuck CLOSE
<  # Move to %flag

`);

test({
  desc: "OPEN/CLOSE: noop if integer is zero",
  cmds: OPEN + PLUS + RIGHT + CLOSE,
  tape: "[1] 0 0",
  want: "[1] 0 0",
});

test({
  desc: "OPEN/CLOSE: properly runs if integer is nonzero",
  tape: "[1] 0 1",
  cmds: OPEN + PLUS + RIGHT + CLOSE,
  want: "1 0 2   0 0 0   [1] 0 0",
});

test({
  desc: "OPEN/CLOSE: [-] sets integer to 0",
  tape: "[1] 0 200",
  cmds: OPEN + MINUS + CLOSE,
  want: "[1] 0 0",
});

test({
  desc: "OPEN/CLOSE: [->+<] moves a value",
  tape: "[1] 0 12",
  cmds: OPEN + MINUS + RIGHT + PLUS + LEFT + CLOSE,
  want: "[1] 0 0   0 0 0   1 0 12",
});

test({
  desc: "OPEN/CLOSE: [->+>+<<] moves & clones a value",
  tape: "[1] 0 12",
  cmds: OPEN + MINUS + RIGHT + PLUS + RIGHT + PLUS + LEFT + LEFT + CLOSE,
  want: "[1] 0 0   0 0 0   1 0 12   0 0 0   1 0 12",
});


const GET = minify(`

# Start on the leftmost %flag of some integer
# Input a value into the integer

[>>[-]>]     # Clear all %data cells in the integer and move to the %a after the rightmost digit
<<<[<<<]>>>  # Move to the leftmost %flag
>>,<<        # Brainfuck GET

`);

test({
  desc: "GET: empty stdin has value 0",
  cmds: GET,
  stdin: "",
  tape: "[1] 0 120   1 0 220",
  want: "[1] 0 0     1 0 0  ",
});

test({
  desc: "GET: reads a character",
  cmds: GET,
  stdin: "abc",
  tape: "[1] 0 0 ",
  want: "[1] 0 97",
});

test({
  desc: "GET: properly clears digits",
  cmds: GET,
  stdin: "A",
  tape: "[1] 0 0    1 0 255   1 0 100",
  want: "[1] 0 65   1 0 0     1 0 0  ",
});

test({
  desc: "GET: properly consumes characters",
  cmds: GET + RIGHT + GET,
  stdin: "abc",
  tape: "[1] 0 0                     ",
  want: " 1  0 97   0 0 0   [1] 0 98",
});


const PUT = minify(`

# Start on the leftmost %flag of some integer
# Output the value of that integer mod 265

>>.<<  # hehehe

`);

test({
  desc: "PUT: works properly",
  cmds: GET + OPEN + PUT + GET + CLOSE,
  tape: "[1] 0 0",
  want: "[1] 0 0",
  stdin: "Hello, world!",
  wantStdout: "Hello, world!",
});


const PREAMBLE = minify(`

>>>  # Ensure we have enough space to do operations
     # This is in case we're compiling to a brainfuck implementation
     # which runs on a tape that is bounded to the left

+  # Initialize the first integer
   # This is to satisfy the operations' requirements that
   # the pointer is on the %flag of an integer

`);

test({
  desc: "PREAMBLE: gives enough space for PLUS",
  cmds: PREAMBLE + PLUS,
  tape: "[0]",
  want: " 0  0 0   [1] 0 1",
  leftBounded: true,
});

test({
  desc: "PREAMBLE: gives enough space for MINUS",
  cmds: PREAMBLE + PLUS + MINUS,
  tape: "[0]",
  want: " 0  0 0   [1] 0 0",
  leftBounded: true,
});

test({
  desc: "PREAMBLE: gives enough space for RIGHT",
  cmds: PREAMBLE + RIGHT,
  tape: "[0]",
  want: " 0  0 0   1 0 0   0 0 0   [1] 0 0",
  leftBounded: true,
});

test({
  desc: "PREAMBLE: gives enough space for LEFT",
  cmds: PREAMBLE + RIGHT + LEFT,
  tape: "[0]",
  want: " 0  0 0   [1] 0 0   0 0 0   1 0 0",
  leftBounded: true,
});

test({
  desc: "PREAMBLE: gives enough space for OPEN/GET/PUT/CLOSE",
  cmds: PREAMBLE + GET + OPEN + PUT + GET + CLOSE,
  stdin: "bird",
  wantStdout: "bird",
  tape: "[0]",
  want: " 0  0 0   [1] 0 0",
  leftBounded: true,
});


// --

console.log(`
~~~~~~~ Mapping ~~~~~~~

PREAMBLE  = ${PREAMBLE}
RIGHT (>) = ${RIGHT}
LEFT  (<) = ${LEFT}
PLUS  (+) = ${PLUS}
MINUS (-) = ${MINUS}
OPEN  ([) = ${OPEN}
CLOSE (]) = ${CLOSE}
GET   (,) = ${GET}
PUT   (.) = ${PUT}
`);

{-# LANGUAGE NamedFieldPuns #-}

import Data.Char (chr, ord)
import Data.Functor
import Data.Maybe
import Data.List (isPrefixOf)
import Data.Function ((&))
import System.Environment
import System.Exit (exitWith, ExitCode(ExitFailure))
import qualified Data.Map as Map

import Debug.Trace

{-

The Triad compiler/interpreter follows a 3-stage process:

1 (translation). First, the code is translated into a list of low-level
   instructions, with some instructions labelled and with jumps referencing
   those labels

2 (resolution). Those jumps are then resolved into jumps referencing
  instruction indexes instead of labels. The labels are removed in the
  process.

3 (execution). These instructions are then executed.

The code will follow the order 1 -> 2 -> 3, though it's recommended
to read stage 3 first, then stage 1, then stage 2.

-}

-- Utility stuff --

dropWhileList :: ([a] -> Bool) -> [a] -> [a]
dropWhileList pred [] = []
dropWhileList pred xs
  | pred xs = dropWhileList pred (drop 1 xs)
  | otherwise = xs

safeChr :: Int -> Maybe Char
safeChr x = if x < 0 || x > 127 then Nothing else Just (chr x)

nth :: [a] -> Int -> Maybe a
nth (x:xs) 0 = Just x
nth [] n = Nothing
nth (x:xs) n = nth xs (n - 1)

pow :: Int -> Int -> Int
pow a 0 = 1
pow a b = a * pow a (b - 1)

orElse :: Maybe a -> a -> a
orElse (Just x) _ = x
orElse Nothing x = x

type Result a = Either String a


-- Stage 1: Translation --

type Label = Int

data PreInstruction =
  Plain Instruction             -- A literal instruction
  | Labeled Label               -- A labeled to a location in the instructions
  | JumpToLabeled Label         -- Like Jump, but with a label instead of an instruction index
  | JumpToLabeledGT Label       -- Like JumpGT, but with a label instead of an instruction index
  | JumpToLabeledGE Label       -- Like JumpGE, but with a label instead of an instruction index
  | JumpToLabeledLT Label       -- Like JumpLT, but with a label instead of an instruction index
  | JumpToLabeledLE Label       -- Like JumpLE, but with a label instead of an instruction index
  | JumpToLabeledEQ Label       -- Like JumpEQ, but with a label instead of an instruction index
  | JumpToLabeledNE Label       -- Like JumpNE, but with a label instead of an instruction index
  | JumpLoopStackLabeled Label  -- Like JumpLoopStack, but with a label instead of an instruction index
  deriving (Show)

data BlockKind = Conditional | Loop
type BlockStack = [(BlockKind, Label)]

doTranslate :: String -> Result [PreInstruction]
doTranslate code = translate [] 0 code

translate :: BlockStack -> Label -> String -> Result [PreInstruction]
translate blockStack nextLabel "" = Right []
translate blockStack nextLabel code

  | "+a" `isPrefixOf` code = (Plain IncrementA   :) <$> translate blockStack nextLabel (drop 2 code)
  | "+b" `isPrefixOf` code = (Plain IncrementB   :) <$> translate blockStack nextLabel (drop 2 code)
  | "-a" `isPrefixOf` code = (Plain DecrementA   :) <$> translate blockStack nextLabel (drop 2 code)
  | "-b" `isPrefixOf` code = (Plain DecrementB   :) <$> translate blockStack nextLabel (drop 2 code)
  | "+r" `isPrefixOf` code = (Plain Add          :) <$> translate blockStack nextLabel (drop 2 code)
  | "-r" `isPrefixOf` code = (Plain Subtract     :) <$> translate blockStack nextLabel (drop 2 code)
  | "*r" `isPrefixOf` code = (Plain Multiply     :) <$> translate blockStack nextLabel (drop 2 code)
  | "/r" `isPrefixOf` code = (Plain Divide       :) <$> translate blockStack nextLabel (drop 2 code)
  | "%r" `isPrefixOf` code = (Plain Modulo       :) <$> translate blockStack nextLabel (drop 2 code)
  | "^r" `isPrefixOf` code = (Plain Exponentiate :) <$> translate blockStack nextLabel (drop 2 code)
  | "ar" `isPrefixOf` code = (Plain PutAIntoR    :) <$> translate blockStack nextLabel (drop 2 code)
  | "br" `isPrefixOf` code = (Plain PutBIntoR    :) <$> translate blockStack nextLabel (drop 2 code)
  | "ra" `isPrefixOf` code = (Plain PutRIntoA    :) <$> translate blockStack nextLabel (drop 2 code)
  | "rb" `isPrefixOf` code = (Plain PutRIntoB    :) <$> translate blockStack nextLabel (drop 2 code)
  | "0a" `isPrefixOf` code = (Plain ResetA       :) <$> translate blockStack nextLabel (drop 2 code)
  | "0b" `isPrefixOf` code = (Plain ResetB       :) <$> translate blockStack nextLabel (drop 2 code)
  | "0r" `isPrefixOf` code = (Plain ResetR       :) <$> translate blockStack nextLabel (drop 2 code)

  | "rO" `isPrefixOf` code = (Plain PutInteger   :) <$> translate blockStack nextLabel (drop 2 code)
  | "rA" `isPrefixOf` code = (Plain PutAscii     :) <$> translate blockStack nextLabel (drop 2 code)
  | "Nr" `isPrefixOf` code = (Plain GetInteger   :) <$> translate blockStack nextLabel (drop 2 code)
  | "Ar" `isPrefixOf` code = (Plain GetAscii     :) <$> translate blockStack nextLabel (drop 2 code)

  | any (`isPrefixOf` code) [">[", "<[", "=["] =
    let code' = drop 2 code
        closeLabel = nextLabel
        nextLabel' = nextLabel + 1
        blockStack' = (Conditional, closeLabel):blockStack
        instr = case head code of
          '>' -> JumpToLabeledLE closeLabel
          '<' -> JumpToLabeledGE closeLabel
          '=' -> JumpToLabeledNE closeLabel
    in (instr :) <$> translate blockStack' nextLabel' code'

  | "]." `isPrefixOf` code =
    let code' = drop 2 code
        (Conditional, closeLabel):blockStack' = blockStack
        instr = Labeled closeLabel
    in (instr :) <$> translate blockStack' nextLabel code'

  | any (`isPrefixOf` code) [">{", "<{", "={", "1{", "a{", "b{"]  =
    let code' = drop 2 code
        openLabel = nextLabel
        closeLabel = nextLabel + 1
        nextLabel' = nextLabel + 2
        blockStack' = (Loop, openLabel):(Loop, closeLabel):blockStack
        instrs = case head code of
          '>' -> [Labeled openLabel, JumpToLabeledLE closeLabel]
          '<' -> [Labeled openLabel, JumpToLabeledGE closeLabel]
          '=' -> [Labeled openLabel, JumpToLabeledNE closeLabel]
          '1' -> [Labeled openLabel]
          'a' -> [Plain LoopStackPushA, Labeled openLabel, JumpLoopStackLabeled closeLabel]
          'b' -> [Plain LoopStackPushB, Labeled openLabel, JumpLoopStackLabeled closeLabel]
    in (instrs ++) <$> translate blockStack' nextLabel' code'

  | "}." `isPrefixOf` code =
    let code' = drop 2 code
        (Loop, openLabel):(Loop, closeLabel):blockStack' = blockStack
        instrs = [JumpToLabeled openLabel, Labeled closeLabel]
    in (instrs ++) <$> translate blockStack' nextLabel code'

  | "((" `isPrefixOf` code =
    let code' = drop 2 $ dropWhileList (not . ("))" `isPrefixOf`)) code
    in translate blockStack nextLabel code'

  | any (`isPrefixOf` code) [" ", "\n", "\t"] =
    translate blockStack nextLabel (drop 1 code)

  | otherwise = Left $ "Invalid syntax: '" ++ (take 5 code) ++ "'"


-- Stage 2: Resolution --

-- Build a map from labels to instruction indices
buildLabelTable :: Int -> [PreInstruction] -> Map.Map Label Int
buildLabelTable instrIndex preinstrs = case preinstrs of
  [] -> Map.empty
  ((Labeled label):preinstrs') ->
    -- Add label to table. Don't increment the instruction index since label instructions will be removed.
    Map.insert label instrIndex $ buildLabelTable instrIndex preinstrs'
  (preinstrs:preinstrs') -> buildLabelTable (instrIndex + 1) preinstrs'

resolve :: Map.Map Label Int -> [PreInstruction] -> [Instruction]
resolve labelTable preinstrs = case preinstrs of
  [] -> []
  ((Plain instr):preinstrs') -> instr : resolve labelTable preinstrs'
  ((Labeled label):preinstrs') -> resolve labelTable preinstrs'  -- drop labels
  (jumpPreInstr:preinstrs') ->
    let instr = case jumpPreInstr of
          JumpToLabeled        label -> Jump          (Map.lookup label labelTable `orElse` undefined)
          JumpToLabeledGT      label -> JumpGT        (Map.lookup label labelTable `orElse` undefined)
          JumpToLabeledGE      label -> JumpGE        (Map.lookup label labelTable `orElse` undefined)
          JumpToLabeledLT      label -> JumpLT        (Map.lookup label labelTable `orElse` undefined)
          JumpToLabeledLE      label -> JumpLE        (Map.lookup label labelTable `orElse` undefined)
          JumpToLabeledEQ      label -> JumpEQ        (Map.lookup label labelTable `orElse` undefined)
          JumpToLabeledNE      label -> JumpNE        (Map.lookup label labelTable `orElse` undefined)
          JumpLoopStackLabeled label -> JumpLoopStack (Map.lookup label labelTable `orElse` undefined)
    in instr : resolve labelTable preinstrs'

doResolve :: [PreInstruction] -> [Instruction]
doResolve preinstrs = resolve (buildLabelTable 0 preinstrs) preinstrs


-- Stage 3: Execution --

-- Execution state
data State = State
  -- Instructions to execute
  { instrs :: [Instruction]
  -- Index of current instruction
  , instrPtr :: Int
  -- Input string
  , stdin :: String
  -- Used for a{}. and b{}. loops.
  -- When one of these loops is encountered, the value of a/b is pushed onto the loop stack.
  -- It is then decremented every loop until it is zero, at which point the loop ends.
  , loopStack :: [Int]
  -- Value of A
  , a :: Int
  -- Value of b
  , b :: Int
  -- Value of R
  , r :: Int
  } deriving (Show, Eq)

-- Executable instructions
data Instruction =

  IncrementA      -- A <- A + 1
  | IncrementB    -- B <- B + 1
  | DecrementA    -- A <- A - 1
  | DecrementB    -- B <- B - 1
  | Add           -- R <- A + B
  | Subtract      -- R <- A - B
  | Multiply      -- R <- A * B
  | Divide        -- R <- A div B
  | Modulo        -- R <- A mod B
  | Exponentiate  -- R <- A ^ B
  | PutRIntoA     -- A <- R
  | PutRIntoB     -- B <- R
  | PutAIntoR     -- R <- A
  | PutBIntoR     -- R <- B
  | ResetA        -- A <- 0
  | ResetB        -- B <- 0
  | ResetR        -- R <- 0

  | PutInteger  -- print R as an integer
  | PutAscii    -- print the ascii char designated by B
  | GetInteger  -- read a number and set R to it
  | GetAscii    -- read a character and set R to its integer value

  | Jump Int       -- Jump to an instruction
  | JumpGT Int     -- Jump to an instruction if A >= B
  | JumpGE Int     -- Jump to an instruction if A >  B
  | JumpLT Int     -- Jump to an instruction if A <  B
  | JumpLE Int     -- Jump to an instruction if A <= B
  | JumpEQ Int     -- Jump to an instruction if A == B
  | JumpNE Int     -- Jump to an instruction if A != B

  | LoopStackPushA     -- Push the value of A onto the loop stack
  | LoopStackPushB     -- Push the value of B onto the loop stack
  | JumpLoopStack Int  -- If the top value of the loop stack is 0, pop it and jump; else, decrement it and continue

  deriving (Eq, Show)

-- Advance the instruction pointer
advance :: State -> State
advance state = state { instrPtr = instrPtr state + 1 }

-- Execute a single instruction, returning a new state and some text output
-- If the instruction pointer is out of bounds, returns (state, "")
step :: State -> (State, String)
step (state @ State { a, b, r, instrs, instrPtr, stdin, loopStack }) =
  case nth instrs instrPtr of
    Nothing -> (state, "")
    Just instr -> case instr of
      IncrementA   -> let state' = state { a = a + 1 }    & advance in (state', "")
      IncrementB   -> let state' = state { b = b + 1 }    & advance in (state', "")
      DecrementA   -> let state' = state { a = a - 1 }    & advance in (state', "")
      DecrementB   -> let state' = state { b = b - 1 }    & advance in (state', "")
      Add          -> let state' = state { r = a + b }    & advance in (state', "")
      Subtract     -> let state' = state { r = a - b }    & advance in (state', "")
      Multiply     -> let state' = state { r = a * b }    & advance in (state', "")
      Divide       -> let state' = state { r = quot a b } & advance in (state', "")
      Exponentiate -> let state' = state { r = pow a b }  & advance in (state', "")
      PutRIntoA    -> let state' = state { a = r }        & advance in (state', "")
      PutRIntoB    -> let state' = state { b = r }        & advance in (state', "")
      PutAIntoR    -> let state' = state { r = a }        & advance in (state', "")
      PutBIntoR    -> let state' = state { r = b }        & advance in (state', "")
      ResetA       -> let state' = state { a = 0 }        & advance in (state', "")
      ResetB       -> let state' = state { b = 0 }        & advance in (state', "")
      ResetR       -> let state' = state { r = 0 }        & advance in (state', "")

      PutInteger -> (advance state, show r)

      PutAscii -> (advance state, [chr $ r `mod` 128])

      GetInteger ->
        let (n, stdin') = parseAndConsumeInt stdin
            state' = state { stdin = stdin', r = n } & advance
        in (state', "")
        where
          parseAndConsumeInt :: String -> (Int, String)
          parseAndConsumeInt chars =
            let digitChars = takeWhile (`elem` "1234567890") chars
                digits = map (\d -> ord d - ord '0') digitChars
                val = foldl (\acc val -> 10 * acc + val) 0 digits
                restChars = drop (length digits) chars
            in (val, restChars)

      GetAscii ->
        let (char, stdin') = parseAndConsumeChar stdin
            state' = state { stdin = stdin', r = ord char } & advance
        in (state', "")
        where
          parseAndConsumeChar :: String -> (Char, String)
          parseAndConsumeChar (c:cs) = (c, cs)
          parseAndConsumeChar "" = ('\0', "")


      Jump target -> let state' = state { instrPtr = target } in (state', "")
      JumpGT target -> let state' = if a >  b then state { instrPtr = target } else advance state in (state', "")
      JumpGE target -> let state' = if a >= b then state { instrPtr = target } else advance state in (state', "")
      JumpLT target -> let state' = if a <  b then state { instrPtr = target } else advance state in (state', "")
      JumpLE target -> let state' = if a <= b then state { instrPtr = target } else advance state in (state', "")
      JumpEQ target -> let state' = if a == b then state { instrPtr = target } else advance state in (state', "")
      JumpNE target -> let state' = if a /= b then state { instrPtr = target } else advance state in (state', "")

      LoopStackPushA -> let state' = state { loopStack = a : loopStack } & advance in (state', "")
      LoopStackPushB -> let state' = state { loopStack = b : loopStack } & advance in (state', "")
      JumpLoopStack target ->
        let state' = case loopStack of
              -- If 0, pop off stack and stop looping
              (0:loopStack') -> state { loopStack = loopStack', instrPtr = target }
              -- If nonzero, decrement and continue looping
              (n:loopStack') -> state { loopStack = (n - 1) : loopStack' } & advance
              -- If empty, I messed up
              [] -> undefined
        in (state', "")

exec :: State -> String
exec state =
  let (state', out) = step state
  in if state == state' then ""
     else out ++ exec state'

doExec :: String -> [Instruction] -> String
doExec stdin instrs =
  exec State
    { instrs = instrs
    , instrPtr = 0
    , stdin = stdin
    , loopStack = []
    , a = 0
    , b = 0
    , r = 0
    }


-- Main --

-- Compile and execute some code
doRun :: String -> String -> Result String
doRun stdin code = do
  translated <- doTranslate code
  let resolved = doResolve translated
  let stdout = doExec stdin resolved
  return $ stdout

main :: IO ()
main = do
  stdin <- getContents
  args <- getArgs
  if length args /= 1 then do
    putStrLn "Expected exactly 1 argument"
    exitWith (ExitFailure 1)
  else do
    let triadCode = head args
    let result = doRun stdin triadCode
    putStr $ case result of
      Left err -> "Error: " ++ err
      Right str -> str


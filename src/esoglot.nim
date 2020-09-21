import strformat
import strutils
import options
import tables
import sets
import os

import convert
import execute
import verbose
import langs

type CliParseError = object of CatchableError

proc parse_cli_pair(word: string): (string, string) =
  let i = word.find(':')
  return (word[0 ..< i], word[i + 1 ..< word.len])

proc parse_cli(
  aliases: Table[string, string],
  flags: HashSet[string],
  pairs: HashSet[string],
): tuple[
  flags: HashSet[string],
  pairs: Table[string, string],
  words: seq[string],
] =

  result = (
    flags: initHashSet[string](),
    pairs: initTable[string, string](),
    words: newSeq[string](),
  )

  for param in command_line_params():

    let kind =
      if param.starts_with("--"): "long"
      elif param.starts_with("-"): "short"
      else: "word"

    let content =
      if kind == "long": param[2 ..< param.len]
      elif kind == "short": param[1 ..< param.len]
      else: param

    if kind in ["long", "short"]:
      if ':' in content:
        var (name, val) = parse_cli_pair(content)
        if kind == "short": name = aliases[name]
        if name notin pairs:
          raise CliParseError.newException(&"Unrecognized parameter: {name}")
        result.pairs[name] = val
      else:
        var name = content
        if kind == "short": name = aliases[name]
        if name notin flags:
          raise CliParseError.newException(&"Unrecognized flag: {name}")
        result.flags.incl content
    else:
      result.words.add content

when is_main_module:

  let (flags, pairs, words) = parse_cli(
    {
      "f": "from",
      "t": "to",
      "l": "lang",
      "v": "verbose",
    }.toTable,
    ["verbose"].toHashSet,
    ["from", "to", "lang"].toHashSet,
  )

  if "verbose" in flags:
    verbose.verbosity = v_all

  let command = if words.len == 0: "" else: words[0]
  assert command in ["c", "e"], "Expected either 'c' (convert) or 'e' (execute)"

  if command == "c":
    let from_lang = pairs["from"].parse_lang.get
    let to_lang = pairs["to"].parse_lang.get
    let code = stdin.read_all.string
    let converted = convert(code, from_lang, to_lang)
    echo converted
  else:
    let lang = pairs["lang"].parse_lang.get
    let code = stdin.read_all.string
    execute(code, lang)

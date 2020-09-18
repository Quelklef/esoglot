import strutils
import parseopt
import options
import tables
import sets
import os

import convert
import execute
import langs
import util

when is_main_module:
  var flags = initHashSet[string]()
  var pairs = initTable[string, string]()
  var words = newSeq[string]()

  let aliases = {
    "f": "from",
    "t": "to",
    "l": "lang",
    "v": "verbose",
  }.toTable

  var parser = init_opt_parser(command_line_params().join(" "))
  for opt_kind, opt_key, opt_val in parser.getopt:
    case opt_kind
    of cmdArgument:
      words.add(opt_key)
    of cmdShortOption, cmdLongOption:
      let key = if opt_key in aliases: aliases[opt_key] else: opt_key
      if opt_val == "":
        flags.incl: key
      else:
        pairs[key] = opt_val
    of cmdEnd:
      discard

  let verbose = "verbose" in flags

  let command = words[0]
  if command notin ["c", "e"]:
    abort "Expected either 'c' (convert) or 'e' (execute)"

  if command == "c":
    let from_lang = pairs["from"].parse_lang.get
    let to_lang = pairs["to"].parse_lang.get
    let code = stdin.read_all.string
    let converted = convert(code, from_lang, to_lang, verbose)
    echo converted
  else:
    let lang = pairs["lang"].parse_lang.get
    let code = stdin.read_all.string
    execute(code, lang, verbose)

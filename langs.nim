import options
import tables
import strutils

type Lang* = enum
  lang_brainfuck
  lang_ook

const lang_count* = Lang.high.ord + 1

const all_langs* = block:
  var langs = newSeq[Lang](lang_count)
  for lang in Lang.low .. Lang.high:
    langs.add lang
  langs

proc parse_lang*(lang_name: string): Option[Lang] =
  let langs {.global.} = {
    "brainfuck": lang_brainfuck,

    "ook!": lang_ook,
    "ook": lang_ook,
  }.toTable

  if lang_name in langs:
    return some(langs[lang_name.to_lower_ascii])
  else:
    return none(Lang)


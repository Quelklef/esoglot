import strformat
import strutils
import sequtils
import options
import osproc
import os

import util
import langs

# converter[lang1][lang2] is a converter from lang1 to lang2, if it exits
var converters: array[Lang, array[Lang, Option[proc(code: string): string]]]

proc make_converter(from_lang, to_lang: Lang, converter_dir_path: string): proc(code: string): string =
  return proc(code: string): string =
    let (output, err_code) = exec_cmd_ex(&"""echo {code.quote_shell} | {converter_dir_path}/conv""")
    if err_code != 0:
      abort &"Error converting {from_lang} -> {to_lang}:\n{output}"
    return output

for converter_dir in walk_dir("./conv", true):
  let parts = converter_dir.path.split("_to_")
  let converter_dir_path = "./conv" / converter_dir.path
  let converter_path = converter_dir_path / "conv"
  if not file_exists(converter_path):
    abort &"Folder '{converter_dir_path}' exists but is missing converter '{converter_path}'"
  let from_lang = parts[0].parse_lang.get
  let to_lang = parts[1].parse_lang.get
  converters[from_lang][to_lang] = some(make_converter(from_lang, to_lang, converter_dir_path))

proc directly_convertable_from(from_lang: Lang): seq[Lang] =
  for to_lang in Lang:
    if converters[from_lang][to_lang].is_some:
      result.add: to_lang

proc calc_conversion_chain*(from_lang, to_lang: Lang): Option[seq[Lang]] =
  ## Calculates a chain of directly convertable languages connecting the two given languages
  ## Such a chain may or may not exist, hence returing an ``Option``

  # Just does a BFS

  var seen: set[Lang] = {}
  var paths = @[@[from_lang]]

  const lang_count = Lang.high.ord + 1
  while seen.len < lang_count:
    for path in paths:
      if path.last == to_lang:
        return some(path)
    for path_i, path in paths:
      let novel = directly_convertable_from(path.last).filterIt(it notin seen)
      for it in novel: seen.incl it
      paths[path_i .. path_i] = novel.mapIt(path & @[it])

  return none(seq[Lang])

proc is_convertable_to*(from_lang, to_lang: Lang): bool =
  calc_conversion_chain(from_lang, to_lang).is_some

proc convert*(code: string, from_lang, to_lang: Lang, verbose = false): string =
  let chain = calc_conversion_chain(from_Lang, to_lang)

  if chain.is_none:
    abort &"Cannot convert from {from_lang} to {to_lang}"
  else:
    let chain = chain.get
    if verbose:
      echo &"Converting {from_lang} -> {to_lang} via " & chain.join(" -> ")

    # Begin the conversions!
    var code = code
    var cur_lang = from_lang
    for next_lang in chain[1 ..< chain.len]:  # first in chain is from_lang
      code = converters[cur_lang][next_lang].get()(code)
      cur_lang = next_lang

    return code

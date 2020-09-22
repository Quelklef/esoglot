import strformat
import strutils
import sequtils
import options
import tables
import osproc
import sets
import os

import util
import langs
import builds
import verbose

# converter[(lang1, lang2)] is a converter from lang1 to lang2, if it exists
var converters: Table[(Lang, Lang), proc(code: string): string]

proc make_converter(from_lang, to_lang: Lang, converter_dir_path: string): proc(code: string): string =
  return proc(code: string): string =
    builds.ensure_at_latest converter_dir_path
    let (output, err_code) = exec_cmd_ex(&"(cd {converter_dir_path} && sh ./_run.sh {code.quote_shell})")
    assert err_code == 0, &"Error converting {from_lang} -> {to_lang}:\n{output}"
    return output

for converter_dir in walk_dir("./conv", true):
  let parts = converter_dir.path.split("_to_")
  let converter_dir_path = "./conv" / converter_dir.path
  let converter_path = converter_dir_path / "conv"
  assert file_exists(converter_path), &"Folder '{converter_dir_path}' exists but is missing converter '{converter_path}'"
  let from_lang = parts[0].parse_lang.get
  let to_lang = parts[1].parse_lang.get
  assert (from_lang, to_lang) notin converters, &"Duplicate converter {from_lang} -> {to_lang}"
  converters[(from_lang, to_lang)] = make_converter(from_lang, to_lang, converter_dir_path)

proc directly_convertable_from*(from_lang: Lang): seq[Lang] =
  for to_lang in langs.all_langs:
    if (from_lang, to_lang) in converters:
      result.add: to_lang

proc calc_conversion_chain*(from_lang, to_lang: Lang): Option[seq[Lang]] =
  ## Calculates a chain of directly convertable languages connecting the two given languages
  ## Such a chain may or may not exist, hence returing an ``Option``

  # Just does a BFS

  var seen = initHashSet[Lang]()
  var paths = @[@[from_lang]]

  while true:

    for path in paths:
      if path.last == to_lang:
        return some(path)

    let seen_len = seen.len

    for path_i, path in paths[0 ..< paths.len]:
      let novel = directly_convertable_from(path.last).filterIt(it notin seen)
      for it in novel: seen.incl it
      paths[path_i .. path_i] = novel.mapIt(path & @[it])

    if seen_len == seen.len:
      # Didn't see anything new
      break

  return none(seq[Lang])

proc is_convertable_to*(from_lang, to_lang: Lang): bool =
  calc_conversion_chain(from_lang, to_lang).is_some

proc convert*(code: string, from_lang, to_lang: Lang): string =
  assert from_lang.is_convertable_to(to_lang), &"Cannot convert from {from_lang} to {to_lang}"

  let chain = calc_conversion_chain(from_Lang, to_lang).get

  verbose.info &"Converting {from_lang} -> {to_lang} via {chain.join(\" -> \")}"

  # Begin the conversions!
  var code = code
  var cur_lang = from_lang
  for next_lang in chain[1 ..< chain.len]:  # first in chain is from_lang
    code = converters[(cur_lang, next_lang)](code)
    cur_lang = next_lang

  return code

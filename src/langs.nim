import parsetoml
import strutils
import options
import tables
import hashes
import sets

## A valid language code
type Lang* = distinct string

proc hash*(lang: Lang): Hash {.borrow.}
proc `==`*(l1, l2: Lang): bool {.borrow.}

var all_langs* = initHashSet[Lang]()

var langs_meta = initTable[Lang, tuple[
  name: string;
  code: string;
]]()

proc `$`*(lang: Lang): string =
  {.no_side_effect.}:  # :^)
    return langs_meta[lang].name

let root_toml = parsetoml.parse_file("./langs.toml")
for lang_toml in root_toml["langs"].get_elems:
  let meta = (
    name: lang_toml["name"].get_str,
    code: lang_toml["code"].get_str,
  )
  assert Lang(meta.code) notin all_langs
  all_langs.incl Lang(meta.code)
  langs_meta[Lang(meta.code)] = meta

proc parse_lang*(lang_code: string): Option[Lang] =
  let lang_code = lang_code.to_lower_ascii
  if Lang(lang_code) in all_langs:
    return some(Lang(lang_code))
  return none(Lang)

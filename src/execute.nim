import strformat
import sequtils
import options
import tables
import osproc
import sugar
import sets
import os

import util
import langs
import builds
import verbose
import convert

var executors: Table[Lang, proc(code: string)]

proc make_executor(executor_name: string, lang: Lang): proc(code: string) =
  return proc(code: string) =
    builds.ensure_at_latest &"./exec/{executor_name}"
    let err_code = exec_cmd(&"(cd ./exec/{executor_name} && sh _run.sh {code.quote_shell})")
    assert err_code == 0, &"Error executing {lang} code"

for executor_dir in walk_dir("./exec", true):
  let executor_name = executor_dir.path
  let lang = executor_name.parse_lang.get
  executors[lang] = make_executor(executor_name, lang)

proc is_directly_executable*(lang: Lang): bool =
  lang in executors

proc execute*(code: string, lang: Lang) =

  var code = code
  var lang = lang
  if not lang.is_directly_executable:
    verbose.info &"Cannot execute {lang} code directly, will try a conversion..."

    let from_lang = lang
    let closest_directly_executable_lang = all_langs.to_seq
      .filter(to_lang => to_lang.is_directly_executable and lang.is_convertable_to to_lang)
      .min_by(to_lang => calc_conversion_chain(from_lang, to_lang).get.len)

    assert closest_directly_executable_lang.is_some, "No possible conversion"

    code = convert(code, lang, closest_directly_executable_lang.get)
    lang = closest_directly_executable_lang.get
    verbose.info "Conversion ok"

  executors[lang](code)

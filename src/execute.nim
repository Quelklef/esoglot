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
import convert

var executors: Table[Lang, proc(code: string)]

proc make_executor(executor_name: string, lang: Lang): proc(code: string) =
  return proc(code: string) =
    let err_code = exec_cmd(&"""echo {code.quote_shell} | ./exec/{executor_name}/exec""")
    if err_code != 0:
      abort &"Error executing {lang} code"

for executor_dir in walk_dir("./exec", true):
  let executor_name = executor_dir.path
  let lang = executor_name.parse_lang.get
  executors[lang] = make_executor(executor_name, lang)

proc is_directly_executable(lang: Lang): bool =
  lang in executors

proc execute*(code: string, lang: Lang, verbose = true) =

  var code = code
  var lang = lang
  if not lang.is_directly_executable:
    if verbose: echo &"Cannot execute {lang} code directly, will try a conversion..."

    let from_lang = lang
    let closest_directly_executable_lang = all_langs.to_seq
      .filter(to_lang => to_lang.is_directly_executable and lang.is_convertable_to to_lang)
      .min_by(to_lang => calc_conversion_chain(from_lang, to_lang).get.len)

    if closest_directly_executable_lang.is_none:
      abort "No possible conversion"

    code = convert(code, lang, closest_directly_executable_lang.get, verbose)
    lang = closest_directly_executable_lang.get
    if verbose: echo "Conversion ok"

  executors[lang](code)

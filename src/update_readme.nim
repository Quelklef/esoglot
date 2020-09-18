import strformat
import strutils
import sets

import langs
import convert
import execute

proc gen_lang_list_md(): string =
  for lang in langs.all_langs:
    result &= &"- [**{lang}**]({lang.page})\n"

    if lang.is_directly_executable:
      result &= &"  - Executable\n"

    let to_langs = directly_convertable_from(lang)
    if to_langs.len > 0:
      result &= &"  - Convertable to {to_langs.join(\", \")}\n"

proc fill_readme(old_readme: string): string =
  var in_lang_list = false
  for line in old_readme.split_lines:
    if "(BEGIN LANG LIST)" in line:
      in_lang_list = true
      result  &= line & "\n\n"
      result &= gen_lang_list_md()
    if not in_lang_list:
      result &= line & "\n"
    if "(END LANG LIST)" in line:
      result &= "\n" & line & "\n"
      in_lang_list = false

when is_main_module:
  let read_f = open("../README.md", fmRead)
  let old_content = read_f.read_all
  read_f.close

  let write_f = open("../README.md", fmWrite)
  let new_content = fill_readme(old_content)
  write_f.write new_content
  write_f.close

  echo "Readme updated"

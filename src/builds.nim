import strformat
import strutils
import osproc
import times
import os

import verbose

#[

This module handles directories with a '_build.sh' file in them.
The primary export is 'ensure_at_latest', which runs _build.sh
if any file in the directory has been modified since the last build.

]#

const build_time_filename = ".esoglot_last_build_time.txt"

proc dir_last_modification_timestamp(path: string): int64 =
  var max_modification_timestamp = 0'i64
  for _, path in walk_dir(path):
    let last_modified = path.get_last_modification_time.to_unix
    max_modification_timestamp = max(last_modified, max_modification_timestamp)
  return max_modification_timestamp

proc at_latest(path: string): bool =
  if not file_exists(path / build_time_filename):
    return false

  let build_time_file = open(path / build_time_filename)
  let build_time_str = build_time_file.read_all
  build_time_file.close

  var build_timestamp: int
  try:
    build_timestamp = build_time_str.parse_int
  except ValueError:
    verbose.warn &"Build time file at '{path}' corrupted"
    return false

  return path.dir_last_modification_timestamp <= build_timestamp

proc ensure_at_latest*(path: string) =
  if not path.at_latest:

    verbose.info &"Path '{path}' not at latest build; rebuilding"
    let (output, err_code) = exec_cmd_ex(&"(cd {path} && sh _build.sh)")
    assert err_code == 0, &"Error building '{path}':\n{output}"

    let now_timestamp = get_time().to_unix

    let build_time_file = open(path / build_time_filename, fm_write)
    build_time_file.write $now_timestamp
    build_time_file.close

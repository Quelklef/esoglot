import terminal

type Verbosity* = enum
  v_none = 0
  v_info = 1
  v_warn = 2
  v_error = 3
  v_all = 4

var verbosity* = v_none

proc info*(msg: string) =
  if verbosity >= v_info:
    stdout.styled_write fg_cyan, "Esoglot", fg_green, " [info]: ", fg_default, msg
    echo ""

proc warn*(msg: string) =
  if verbosity >= v_warn:
    stdout.styled_write fg_cyan, "Esoglot", fg_yellow, " [warn]: ", fg_default, msg
    echo ""

proc error*(msg: string) =
  if verbosity >= v_error:
    stdout.styled_write style_bright, fg_cyan, "Esoglot", fg_red, " [errr]: ", fg_default, msg
    echo ""

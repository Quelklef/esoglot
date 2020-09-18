import options

proc last*[T](s: seq[T]): T =
    s[s.len - 1]

proc min_by*[T; K: Ordinal](s: seq[T], key: proc(x: T): K): Option[T] =
  if s.len == 0:
    return none(T)
  var best_key = s[0].key
  var best = s[0]
  for item in s[1 ..< s.len]:
    if item.key < best_key:
      best_key = item.key
      best = item
  return some(best)

import unicode
import sequtils
import strutils
import runes
import box

type
  Buffer* = ref object
    runes*: seq[seq[Rune]]
    box*: Box

func fill*(b: Buffer, r: Rune) =
  for i, _ in b.runes:
    for j, _ in b.runes[i]:
      b.runes[i][j] = r

func newBuffer*(size: Box): Buffer =
  result = Buffer()
  result.box = size
  result.runes = newSeqWith(result.box.height, 
    newSeq[Rune](result.box.width))

func `[]`*(b: Buffer, y, x: int): Rune =
  if y < 0 or y >= b.box.height:
    return cast[Rune](0)
  if x < 0 or y >= b.box.width:
    return cast[Rune](0)
  b.runes[y][x]

func `[]=`*(b: Buffer, y, x: int, r: Rune) =
  b.runes[y][x] = r

func `[]=`*(b: Buffer, y: int, slice: HSlice[int, int], r: Rune) =
  for i in slice:
    b.runes[y][i] = r

func `[]=`*(b: Buffer, slice: HSlice[int, int], x: int, r: Rune) =
  for i in slice:
    b.runes[i][x] = r

func setOr*(b: Buffer, y, x: int, r: Rune) =
  if y < 0 or y >= b.box.height:
    return
  if x < 0 or x >= b.box.width:
    return
  b.runes[y][x] = Rune(int32(b.runes[y][x]) or int32(r))

func write*(b: Buffer, y, x: int, r: openArray[Rune]) =
  if y < 0 or y > b.box.height:
    return
  for i in 0..r.high:
    var xi = x + i
    if xi < 0 or xi >= b.box.width:
      continue
    b.runes[y][xi] = r[i]

template writeLeft*(b: Buffer, y, x: int, r: openArray[Rune]) =
  b.write(y, x - len(r), r)

template writeRight*(b: Buffer, y, x: int, r: openArray[Rune]) =
  b.write(y, x, r)

template writeCenter*(b: Buffer, y, x: int, r: openArray[Rune]) =
  b.write(y, x - len(r) div 2, r)

func `$`*(b: Buffer): string =
  result = ""
  for i, _ in b.runes:
    var row = b.runes[(b.box.height - i - 1)]
    result &= join(row)
    if i < b.box.height - 1:
      result &= "\n"

when isMainModule:
  var myBox = Box(width: 10, height: 10)
  var myBuffer = newBuffer(myBox)
  myBuffer.fill(Rune(0x51))
  var myRunes = [Rune(0x2573), Rune(0x53), Rune(0x54)]
  myBuffer.write(0,0, myRunes)
  echo myBuffer
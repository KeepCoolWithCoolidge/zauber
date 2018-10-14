import unicode
import sequtils
import strutils
import runes
import box

type
  Buffer* = ref object
    runes*: seq[seq[Rune]]
    box*: Box

func fill*(self: Buffer, r: Rune) =
  for i, _ in self.runes:
    for j, _ in self.runes[i]:
      self.runes[i][j] = r

func newBuffer*(size: Box): Buffer =
  result = Buffer()
  result.box = size
  result.runes = newSeqWith(result.box.height, 
    newSeq[Rune](result.box.width))

func `[]`*(self: Buffer, y, x: int): Rune =
  if y < 0 or y >= self.box.height:
    return cast[Rune](0)
  if x < 0 or y >= self.box.width:
    return cast[Rune](0)
  self.runes[y][x]

func `[]=`*(self: Buffer, y, x: int, r: Rune) =
  self.runes[y][x] = r

func `[]=`*(self: Buffer, y: int, slice: HSlice[int, int], r: Rune) =
  for i in slice:
    self.runes[y][i] = r

func `[]=`*(self: Buffer, slice: HSlice[int, int], x: int, r: Rune) =
  for i in slice:
    self.runes[i][x] = r

func setOr*(self: Buffer, y, x: int, r: Rune) =
  if y < 0 or y >= self.box.height:
    return
  if x < 0 or x >= self.box.width:
    return
  self.runes[y][x] = Rune(int32(self.runes[y][x]) or int32(r))

func write*(self: Buffer, y, x: int, r: openArray[Rune]) =
  if y < 0 or y > self.box.height:
    return
  for i in 0..r.high:
    var xi = x + i
    if xi < 0 or xi >= self.box.width:
      continue
    self.runes[y][xi] = r[i]

template writeLeft*(self: Buffer, y, x: int, r: openArray[Rune]) =
  self.write(y, x - len(r), r)

template writeRight*(self: Buffer, y, x: int, r: openArray[Rune]) =
  self.write(y, x, r)

template writeCenter*(self: Buffer, y, x: int, r: openArray[Rune]) =
  self.write(y, x - len(r) div 2, r)

func `$`*(self: Buffer): string =
  result = ""
  for i, _ in self.runes:
    var row = self.runes[(self.box.height - i - 1)]
    result &= join(row)
    if i < self.box.height - 1:
      result &= "\n"

when isMainModule:
  var myBox = Box(width: 10, height: 10)
  var myBuffer = newBuffer(myBox)
  myBuffer.fill(Rune(0x51))
  var myRunes = [Rune(0x2573), Rune(0x53), Rune(0x54)]
  myBuffer.write(0,0, myRunes)
  echo myBuffer
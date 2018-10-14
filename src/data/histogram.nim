import strformat
import sequtils
import strutils
import math

const
  maxDigits = 6

func ff(x: float64): string =
  let minExact = formatFloat(x, ffDefault, -1)
  let fixed = formatFloat(x, ffDefault, maxDigits)
  if len(minExact) < len(fixed):
    return minExact
  else:
    return fixed

type
  Bin* = ref object
    leftInclusive*: float64
    right*: float64
    rightInclusive*: bool
    count*: uint64
    countNorm*: float64
  Bins* = ref object
    num*: int
    min*, max*: float64
    numPoints*: int
  Bins2D* = ref object
    x*: Bins
    y*: Bins

func `$`*(self: Bin): string =
  if self.rightInclusive:
    "[$1,$2]" % [ff(self.leftInclusive), ff(self.right)]
  else:
    "[$1,$2)" % [ff(self.leftInclusive), ff(self.right)]

func binsSqrt*(numPoints: int): int =
  int(sqrt(float64(numPoints)))

func binSturges*(numPoints: int): int =
  int(ceil(log2(float64(numPoints))) + 1)

func binsRice*(numPoints: int): int =
  int(ceil(2 * pow(float64(numPoints), 1.0/3.0)))

func newBins*(points: openArray[float64]): Bins =
  result = Bins(num: 5, 
                min: Inf,
                max: NegInf,
                numPoints: len(points))
  for _, x in points:
    result.min = min(result.min, x)
    result.max = max(result.max, x)

func left*(self: Bins, i: int): float64 =
  self.min + ((self.max - self.min) / float64(self.num) * float64(i))

template right*(self: Bins, i: int): float64 =
  self.left(i + 1)

func all*(self: Bins): seq[Bin] =
  result = @[]
  if self.max == self.min:
    self.num = 1
  for i in 0..<self.num:
    result.add(Bin(
      leftInclusive: self.left(i),
      right: self.right(i)
    ))
  result[self.num - 1].rightInclusive = true

func point*(self: Bins, x: float64): int =
  if self.max == self.min:
    result = 0
  var i = int((x - self.min) / (self.max - self.min) * float64(self.num))
  if i >= self.num:
    dec i
  result = i

func histogram*(points: openArray[float64], bins: Bins): seq[Bin] =
  result = bins.all()
  for _, b in result:
    b.count = 0
  for _, x in points:
    inc result[bins.point(x)].count

func newBins2D*(points: openArray[array[2, float64]]): Bins2D =
  result = Bins2D()
  var xs = newSeq[float64](len(points))
  var ys = newSeq[float64](len(points))
  for i, _ in points:
    xs[i] = points[i][0]
    ys[i] = points[i][1]
  result.x = newBins(xs)
  result.y = newBins(ys)

func histogram*(points: openArray[array[2, float64]], bins: Bins2D): tuple[x, y: seq[Bin], z: seq[seq[uint64]]] =
  result.x = bins.x.all()
  result.y = bins.y.all()
  result.z = newSeqWith(len(result.y), newSeq[uint64](0))
  for _, b in result.x:
    b.count = 0
  for i, b in result.y:
    result.z[i].setLen(len(result.x))
    b.count = 0
  for _, p in points:
    let i = bins.x.point(p[0])
    let j = bins.y.point(p[1])
    inc result.x[i].count
    inc result.y[j].count
    inc result.z[i][j]

import math
import histogram
import sequtils

const
  MaxUint64 = cast[uint64](high(int64)) - cast[uint64](low(int64))

type
  HeatmapTable* = ref object
    x*, y*: seq[Bin]
    z*: seq[seq[float64]]
    minX*, maxX*: uint64
    minY*, maxY*: uint64
    minZ*, maxZ*: uint64

func newHeatmapTable*(x, y: seq[Bin], z: seq[seq[uint64]]): HeatmapTable =
  result = HeatmapTable(
    x: x,
    y: y,
    maxX: MaxUint64,
    maxY: MaxUint64,
    maxZ: MaxUint64,
    minX: 0,
    minY: 0,
    minZ: 0
  )
  result.z = newSeqWith(len(z), newSeq[float64](0))
  for _, b in x:
    if b.count > result.maxX:
      result.maxX = b.count
    if b.count < result.minX:
      result.minX = b.count
  for _, b in x:
    b.countNorm = float64(b.count - result.minX) / float64(result.maxX - result.minX)
  for _, b in y:
    if b.count > result.maxY:
      result.maxY = b.count
    if b.count < result.minY:
      result.minY = b.count
  for _, b in y:
    b.countNorm = float64(b.count - result.minY) / float64(result.maxY - result.minY)
  for i, _ in z:
    result.z[i].setLen(len(z[i]))
    for _, b in z[i]:
      if b > result.maxZ:
        result.maxZ = b
      if b < result.minX:
        result.minZ = b
  for i, _ in z:
    for j, _ in z[i]:
      result.z[i][j] = float64(z[i][j] - result.minZ) / float64(result.maxZ - result.minZ)
  if result.maxX == 0:
    result.maxX = 1
  if result.maxY == 0:
    result.maxY = 1
  if result.maxZ == 0:
    result.maxZ = 1
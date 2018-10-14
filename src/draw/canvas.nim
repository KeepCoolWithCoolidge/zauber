import unicode
import buffer
import box
import runes
import math

# Helper templates
template lineProc(prefix: untyped): untyped =
  proc `prefix Line`(c: Canvas, x0, y0, x1, y1: int) =
    var l_x0 = x0
    var l_y0 = y0
    let dx = abs(x1 - x0)
    let dy = abs(y1 - y0)
    let sx = sgn(x1 - x0)
    let sy = sgn(y1 - y0)
    var err = dx - dy
    while true:
      c.`prefix Toggle`(l_x0, l_y0)
      if l_x0 == x1 and l_y0 == y1:
        break
      var e2 = 2 * err
      if e2 > -dy:
        err -= dy
        l_x0 += sx
      if e2 < dx:
        err += dx
        l_y0 += sy

type
  Canvas* = ref CanvasObj
  CanvasObj* = object of RootObj
    buffer*: Buffer
    sizeImpl*: proc(c: Canvas): Box
    runeSizeImpl*: proc(c: Canvas): Box
    fillImpl*: proc(c: Canvas, r: Rune)
    clearImpl*: proc(c: Canvas)
    stringImpl*: proc(c: Canvas): string
    toggleImpl*: proc(c: Canvas, y, x: int)
    setImpl*: proc(c: Canvas, y, x: int, r: Rune)
    getImpl*: proc(c: Canvas, y, x: int): Rune
    getRowSliceImpl*: proc(c: Canvas, y: int, slice: HSlice[int, int]): seq[Rune]
    getColSliceImpl*: proc(c: Canvas, slice: HSlice[int, int], x: int): seq[Rune]
    setUniformRowSliceImpl*: proc(c: Canvas, y: int, slice: HSlice[int, int], r: Rune)
    setUniformColSliceImpl*: proc(c: Canvas, slice: HSlice[int, int], x: int, r: Rune)
    writeRunesImpl*: proc(c: Canvas, y, x: int, r: openArray[Rune])
    lineImpl*: proc(c: Canvas, x0, y0, x1, y1: int)

proc size*(c: Canvas): Box =
  c.sizeImpl(c)

proc runeSize*(c: Canvas): Box =
  c.runeSizeImpl(c)

proc clear*(c: Canvas) =
  c.clearImpl(c)

proc `$`*(c: Canvas): string =
  c.stringImpl(c)

proc toggle*(c: Canvas, y, x: int) =
  c.toggleImpl(c, y, x)

proc fill*(c: Canvas, r: Rune) =
  c.fillImpl(c, r)

proc `[]`*(c: Canvas, y, x: int): Rune =
  c.getImpl(c, y, x)

proc `[]=`*(c: Canvas, y, x: int, r: Rune) =
  c.setImpl(c, y, x, r)

proc `[]=`*(c: Canvas, y: int, slice: HSlice[int, int], r: Rune) =
  c.setUniformRowSliceImpl(c, y, slice, r)
 
proc `[]=`*(c: Canvas, slice: HSlice[int, int], x: int, r: Rune) =
  c.setUniformColSliceImpl(c, slice, x, r)

proc write*(c: Canvas, y, x: int, r: openArray[Rune]) =
  c.writeRunesImpl(c, y, x, r)

template writeLeft*(c: Canvas, y, x: int, r: openArray[Rune]) =
  c.write(y, x - len(r), r)

template writeRight*(c: Canvas, y, x: int, r: openArray[Rune]) =
  c.write(y, x, r)

template writeCenter*(c: Canvas, y, x: int, r: openArray[Rune]) =
  c.write(y, x - len(r) div 2, r)

proc line*(c: Canvas, x0, y0, x1, y1: int) =
  c.lineImpl(c, x0, y0, x1, y1)

# StdCanvas implementations
proc stdSize(c: Canvas): Box =
  c.buffer.box

proc stdRuneSize(c: Canvas): Box =
  let pixelBox = c.size()
  let runeBox = c.buffer.box
  result = Box(
    width: pixelBox.width div runeBox.width,
    height: pixelBox.height div runeBox.height
  )

proc stdFill(c: Canvas, r: Rune) =
  c.buffer.fill(r)

proc stdClear(c: Canvas) =
  c.buffer.fill(SPACE)

proc stdString(c: Canvas): string =
  $c.buffer

proc stdSet(c: Canvas, y, x: int, r: Rune) =
  c.buffer[y, x] = r

proc stdToggle(c: Canvas, y, x: int) =
  c.stdSet(y, x, FULLBLOCK)

proc stdGet(c: Canvas, y, x: int): Rune =
  c.buffer[y, x]

proc stdSetUniformRowSlice(c: Canvas, y: int, slice: HSlice[int, int], r: Rune) =
  c.buffer[y, slice] = r
  
proc stdSetUniformColSlice(c: Canvas, slice: HSlice[int, int], x: int, r: Rune) =
  c.buffer[slice, x] = r

proc stdWriteRunes*(c: Canvas, y, x: int, r: openArray[Rune]) =
  c.buffer.write(y, x, r)

lineProc(std)

type
  StdCanvas* = ref StdCanvasObj
  StdCanvasObj* = object of Canvas

proc newStdCanvas*(box: Box = Box(width: 100, height:20)): StdCanvas =
  new(result)
  result.buffer = newBuffer(box)
  result.buffer.fill(SPACE)
  result.sizeImpl = stdSize
  result.runeSizeImpl = stdRuneSize
  result.fillImpl = stdFill
  result.clearImpl = stdClear
  result.stringImpl = stdString
  result.setImpl = stdSet
  result.toggleImpl = stdToggle
  result.getImpl = stdGet
  result.writeRunesImpl = stdWriteRunes
  result.setUniformColSliceImpl = stdSetUniformColSlice
  result.setUniformRowSliceImpl = stdSetUniformRowSlice
  result.lineImpl = stdLine

# BrailleCanvas-specific implementation
const
  brailleScaleX* = 2
  brailleScaleY* = 4

proc bcSize(c: Canvas): Box =
  Box(width: c.buffer.box.width * brailleScaleX,
      height: c.buffer.box.height * brailleScaleY)

proc bcClear(c: Canvas) =
  c.buffer.fill(BRAILLEEMPTY)

func braillePoint(y, x: int): Rune =
  var cy, cx: int
  if y >= 0:
    cy = y mod brailleScaleY
  else:
    cy = 3 + ((y + 1) mod brailleScaleY)
  if x >= 0:
    cx = y mod brailleScaleX
  else:
    cy = 1 + ((x + 1) mod brailleScaleX)
  let pixelMap: array[4, array[2, int32]] = [[1i32, 8], [2i32, 16], [4i32, 32], [64i32, 128]]
  result = Rune(pixelMap[3 - cy][cx])

proc bcToggle(c: Canvas, y, x: int) =
  let 
    ry = y div brailleScaleY
    rx = x div brailleScaleX
  c.buffer.setOr(ry, rx, braillePoint(y, x))

lineProc(bc)

type
  BrailleCanvas* = ref BrailleCanvasObj
  BrailleCanvasObj* = object of Canvas

proc newBrailleCanvas*(box: Box = Box(width: 100, height:20)): BrailleCanvas=
  new(result)
  result.buffer = newBuffer(box)
  result.buffer.fill(BRAILLEEMPTY)
  result.sizeImpl = bcSize
  result.runeSizeImpl = stdRuneSize
  result.fillImpl = stdFill
  result.clearImpl = bcClear
  result.stringImpl = stdString
  result.setImpl = stdSet
  result.toggleImpl = bcToggle
  result.getImpl = stdGet
  result.writeRunesImpl = stdWriteRunes
  result.setUniformColSliceImpl = stdSetUniformColSlice
  result.setUniformRowSliceImpl = stdSetUniformRowSlice
  result.lineImpl = bcLine

# HeatmapCanvas-specific implementation
proc hcClear(c: Canvas) =
  c.buffer.fill(SHADES[0])

type
  HeatmapCanvas* = ref HeatmapCanvasObj
  HeatmapCanvasObj* = object of Canvas

proc newHeatmapCanvas*(box: Box = Box(width: 100, height:20)): HeatmapCanvas=
  new(result)
  result.buffer = newBuffer(box)
  result.buffer.fill(SHADES[0])
  result.sizeImpl = stdSize
  result.runeSizeImpl = stdRuneSize
  result.fillImpl = stdFill
  result.clearImpl = hcClear
  result.stringImpl = stdString
  result.setImpl = stdSet
  result.toggleImpl = stdToggle
  result.getImpl = stdGet
  result.writeRunesImpl = stdWriteRunes
  result.setUniformColSliceImpl = stdSetUniformColSlice
  result.setUniformRowSliceImpl = stdSetUniformRowSlice

# QuarterCanvas-specific implementation
const
  quarterScale* = 2

proc qcSize(c: Canvas): Box =
  Box(width: c.buffer.box.width * quarterScale,
      height: c.buffer.box.height * quarterScale)

proc qcClear(c: Canvas) =
  c.buffer.fill(QUARTERS[0])

func index(r: Rune): int =
  for i, _ in QUARTERS:
    if QUARTERS[i] == r:
      return i
  return 0

proc qcToggle(c: Canvas, y, x: int) =
  let 
    ry = y div quarterScale
    cy = 1 - y mod 2
    rx = x div quarterScale
    cx = x mod 2
    i = index(c.buffer[ry, rx])
  c.buffer[ry, rx] = QUARTERS[i or (1 shl uint(cx + 2 * cy))]

lineProc(qc)

type
  QuarterCanvas* = ref QuarterCanvasObj
  QuarterCanvasObj* = object of Canvas

proc newQuarterCanvas*(box: Box = Box(width: 100, height:20)): QuarterCanvas=
  new(result)
  result.buffer = newBuffer(box)
  result.buffer.fill(QUARTERS[0])
  result.sizeImpl = qcSize
  result.runeSizeImpl = stdRuneSize
  result.fillImpl = stdFill
  result.clearImpl = qcClear
  result.stringImpl = stdString
  result.setImpl = stdSet
  result.toggleImpl = qcToggle
  result.getImpl = stdGet
  result.writeRunesImpl = stdWriteRunes
  result.setUniformColSliceImpl = stdSetUniformColSlice
  result.setUniformRowSliceImpl = stdSetUniformRowSlice
  result.lineImpl = qcLine

when isMainModule:
  var a = newStdCanvas()
  a.line(0, 5, 19, 19)

  echo a

  var b = newBrailleCanvas()
  for i in 0..<2000:
      b.toggle((i * i) div 200, i)
  b.line(0, 0, 100, 100)
  b.line(100, 100, 0, 50)

  echo b

  var c = newQuarterCanvas()
  c.line(0, 5, 30, 20)
  c.line(30, 20, 20, 30)

  echo c
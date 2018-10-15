import ../data/data
import ../draw/draw
import math
import unicode
import format

type
  Plot* = ref PlotObj
  PlotObj* = object of RootObj
    canvas*: Canvas
    stringImpl*: proc(p: Plot): string
    drawImpl*: proc(p: Plot, table: DataTable)

# Utilities
func drawAxes(p: Plot, paddingX: int, minX, maxX, minY, maxY: float64) =
  # X axis
  p.canvas[1, paddingX..<p.canvas.buffer.box.width] = HorizontalLine
  # Y axis  
  p.canvas[1..<p.canvas.buffer.box.height, paddingX] = VerticalLine
  # Corner
  p.canvas[1, paddingX] = CornerBottomLeft
  # Labels
  p.canvas.writeRight(1, 1, ff(minY))
  p.canvas.writeLeft(p.canvas.buffer.box.height - 1, paddingX, ff(maxY))
  p.canvas.writeRight(0, paddingX, ff(minX))
  p.canvas.writeLeft(0, p.canvas.buffer.box.width, ff(maxX))

func roundDownToPercentOfRange(x, d: float64): float64 =
  floor((x * (100 - float64(sgn(x)) * 5)) / d) * d / 100

func roundUpToPercentOfRange(x, d: float64): float64 =
  ceil((x * 105) / d) * d / 100

func minMax(table: DataTable): tuple[minX, maxX, minY, maxY: float64] =
  result.minX = Inf
  result.minY = Inf
  result.maxX = NegInf
  result.maxY = NegInf

  for _, r in table.rows:
    if len(r) < 2:
      continue
    result.maxX = max(result.maxX, r[0])
    result.minX = min(result.minX, r[0])
    result.maxY = max(result.maxY, r[1])
    result.minY = min(result.minY, r[1])
  
  let yRange = result.maxY - result.minY
  result.minY = roundDownToPercentOfRange(result.minY, yRange)
  result.maxY = roundUpToPercentOfRange(result.maxY, yRange)

func getFill(fill: float64): Rune =
  var l_fill = fill
  if l_fill < 0.0:
    l_fill = 0.0
  if l_fill > 0.0 and l_fill < NONZEROSHADE:
    l_fill = NONZEROSHADE
  if l_fill > 1.0:
    l_fill = 1.0
  SHADES[int(l_fill * float64(SHADES.high))]

template initialize2DDraw*(minX, maxX, minY, maxY: float64): untyped =
  let minLabelWidth {.inject.} = len(ff(minY))
  let maxLabelWidth {.inject.} = len(ff(maxY))
  let width {.inject.} = p.canvas.size().width
  let height {.inject.} = p.canvas.size().height
  let runeSizeWidth {.inject.} = p.canvas.runeSize().width
  let runeSizeHeight {.inject.} = p.canvas.runeSize().height

  var paddingX {.inject.} = minLabelWidth + 1
  var paddingY {.inject.} = 2
  if minLabelWidth < maxLabelWidth:
    paddingX = maxLabelWidth + 1

  let chartWidth {.inject.} = width - (paddingX + 1) * runeSizeWidth
  let chartHeight {.inject.} = height - paddingY * runeSizeHeight
  var scaleX {.inject.} = float64(chartWidth) / (maxX - minX)
  var scaleY {.inject.} = float64(chartHeight) / (maxY - minY)

# Plot interface 
proc `$`*(p: Plot): string =
  p.stringImpl(p)

proc draw*(p: Plot, table: DataTable) =
  p.drawImpl(p, table)

# Default implementation
proc stdString(p: Plot): string =
  $p.canvas

# BarPlot implementation
proc bcDraw(p: Plot, table: DataTable) =
  let runeSizeHeight = p.canvas.runeSize().height
  let runeSizeWidth = p.canvas.runeSize().width
  let bufferHeight = p.canvas.size().height
  let bufferWidth = p.canvas.size().width
  let tableColumnLength = len(table.columns)
  var minY = Inf
  var maxY = NegInf
  for _, row in table.rows:
    for _, y in row:
      if y < minY:
        minY = y
      if y > maxY:
        maxY = y
  var paddingX = 2
  var paddingY = 3
  var chartHeight = p.canvas.size().height - 
    paddingY * runeSizeHeight
  var chartWidth = p.canvas.size().width -
    2 * paddingX * runeSizeWidth
  var labelsBelowBars = true
  var labelsRight = false
  var maxLabelLength = 0
  var totalLabelLength = 0
  for _, group in table.columns:
    var groupLength = len(group)
    inc totalLabelLength, groupLength
    if groupLength > maxLabelLength:
      maxLabelLength = groupLength
  if totalLabelLength * runeSizeWidth > chartWidth:
    labelsBelowBars = false
    if tableColumnLength * runeSizeHeight <= chartHeight:
      labelsRight = true
      dec chartWidth, 3 + maxLabelLength * runeSizeWidth
  var scaleY = float64(chartHeight) / maxY
  var barPaddedWidth = chartWidth div tableColumnLength
  var barWidth = barPaddedWidth - runeSizeWidth
  if barPaddedWidth < runeSizeWidth:
    barPaddedWidth = runeSizeWidth
  if barWidth < runeSizeWidth:
    barWidth = runeSizeWidth
  for i, group in table.columns:
    var barLeft = paddingX * runeSizeWidth + 
      barPaddedWidth * i
    var barRight = barLeft + barWidth
    var y = table.rows[0][i]
    var barHeight = y * scaleY
    var barBottom = (paddingY - 1) * runeSizeHeight
    var barTop = barBottom + int(barHeight)
    for x in barLeft..<barRight:
      for y in barBottom..<barTop:
        p.canvas.toggle(y, x)
    var barMiddle = int(floor(float64(barLeft + barRight) / 
      float64(2 * runeSizeWidth)))
    # Group label
    if labelsBelowBars:
      p.canvas.write(0, barMiddle - len(group) div 2, toRunes(group))
    else:
      p.canvas.write(0, barMiddle - len(group) div 2, toRunes($i))
    # Count label
    var countLabelY = 
      int(ceil(float64(barTop)/float64(runeSizeHeight))) * 
      runeSizeHeight
    if countLabelY <= barBottom and y > 0:
      p.canvas[barTop div runeSizeHeight, 
        barLeft div runeSizeWidth..barRight div runeSizeWidth] = 
        EIGHTHBLOCK
      countLabelY = 3 * runeSizeHeight
    p.canvas.write(countLabelY div runeSizeHeight, barMiddle - 
      len(ff(y)) div 2, ff(y))
  if labelsRight:
    for i, group in table.columns:
      p.canvas.write(bufferHeight - i, paddingX + 1 + 
        chartWidth div runeSizeWidth, toRunes($i))
      p.canvas.write(bufferHeight - i, paddingX + 4 +
        chartWidth div runeSizeWidth, toRunes(group))

type
  BarPlot* = ref BarPlotObj
  BarPlotObj* = object of Plot

proc newBarPlot*(box: Box = Box(width: 100, height:20), canvasType: CanvasType = STANDARD): BarPlot =
  new(result)
  result.canvas = case canvasType
                  of STANDARD:
                    newStdCanvas(box)
                  of BRAILLE:
                    newBrailleCanvas(box)
                  of HEATMAP:
                    newHeatmapCanvas(box)
                  of QUARTER:
                    newQuarterCanvas(box)
  result.stringImpl = stdString
  result.drawImpl = bcDraw

# Linechart implementation
proc lcDraw(p: Plot, table: DataTable) =
  var prevX, prevY: int
  let (minX, maxX, minY, maxY) = minMax(table)
  initialize2DDraw(minX, maxX, minY, maxY)
  var first = true
  for _, point in table.rows:
    if len(point) < 2:
      continue
    var x = int((point[0] - minX) * scaleX + float64((paddingX + 1) * runeSizeWidth))
    var y = int((point[1] - minY) * scaleY + float64(paddingY * runeSizeHeight))
    if first:
      first = false
      prevX = x
      prevY = y    
    if prevX <= x:
      if x < width and y < height:
        p.canvas.line(prevY, prevX, y, x)
    prevX = x
    prevY = y
  p.drawAxes(paddingX, minX, maxX, minY, maxY)

type
  LinePlot* = ref LinePlotObj
  LinePlotObj* = object of Plot

proc newLinePlot*(box: Box = Box(width: 100, height:20), canvasType: CanvasType = BRAILLE): LinePlot =
  new(result)
  result.canvas = case canvasType
                  of STANDARD:
                    newStdCanvas(box)
                  of BRAILLE:
                    newBrailleCanvas(box)
                  of HEATMAP:
                    newHeatmapCanvas(box)
                  of QUARTER:
                    newQuarterCanvas(box)
  result.stringImpl = stdString
  result.drawImpl = lcDraw

# Scatterplot implementation
proc spDraw(p: Plot, table: DataTable) =
  let (minX, maxX, minY, maxY) = minMax(table)
  initialize2DDraw(minx, maxX, minY, maxY)
  var first = true
  for _, point in table.rows:
    if len(point) < 2:
      continue
    var x = int((point[0] - minX) * scaleX + float64((paddingX + 1) * runeSizeWidth))
    var y = int((point[1] - minY) * scaleY + float64(paddingY * runeSizeHeight))    
    if x < width and y < height:
      p.canvas.toggle(y, x)
  p.drawAxes(paddingX, minX, maxX, minY, maxY)

type
  ScatterplotPlot* = ref ScatterplotPlotObj
  ScatterplotPlotObj* = object of Plot

proc newScatterplotPlot*(box: Box = Box(width: 100, height:20), canvasType: CanvasType = BRAILLE): ScatterplotPlot =
  new(result)
  result.canvas = case canvasType
                  of STANDARD:
                    newStdCanvas(box)
                  of BRAILLE:
                    newBrailleCanvas(box)
                  of HEATMAP:
                    newHeatmapCanvas(box)
                  of QUARTER:
                    newQuarterCanvas(box)
  result.stringImpl = stdString
  result.drawImpl = spDraw

# Heatmap implementation
proc hcDraw*(p: Plot, heatmap: HeatmapTable) =
  let minX = heatmap.x[0].leftInclusive
  let maxX = heatmap.x[heatmap.x.high].right
  let minY = heatmap.y[0].leftInclusive
  let maxY = heatmap.y[heatmap.y.high].right
  initialize2DDraw(minX, maxX, minY, maxY)
  for i, _ in heatmap.z:
    for j, _ in heatmap.z[i]:
      var x0 = int((heatmap.x[i].leftInclusive - minX) * scaleX + float64(paddingX + 1))
      var y0 = int((heatmap.y[j].leftInclusive - minY) * scaleY + float64(paddingY))
      var x1 = int((heatmap.x[i].right - minX) * scaleX + float64(paddingX + 1))
      var y1 = int((heatmap.y[j].right - minY) * scaleY + float64(paddingY))
      var z = heatmap.z[i][j]
      for x in x0..<x1:
        for y in y0..<y1:
          p.canvas[y, x] = getFill(z)
  p.drawAxes(paddingX, minX, maxX, minY, maxY)

type
  HeatmapPlot* = ref HeatmapPlotObj
  HeatmapPlotObj* = object of Plot

proc newHeatmap*(box: Box = Box(width: 100, height:20)): HeatmapPlot =
  new(result)
  result.canvas = newHeatmapCanvas(box)
  result.stringImpl = stdString
  result.drawImpl = lcDraw

when isMainModule:
  import random

  var myPlot = newBarPlot()
  var stuff = newDataTable()
  stuff.addColumns(["Hats", "Knuckleheads", "Skull & Bones"])
  stuff.addRow([1'f64, 2, 3])
  myPlot.draw(stuff)

  var myPlot2 = newLinePlot()
  var stuff2 = newDataTable()
  stuff2.addColumns(["Hats", "Cats"])
  for i in -100..100:
    stuff2.addRow([float(i), float(i * i * i)])
  myPlot2.draw(stuff2)

  var myPlot3 = newLinePlot(canvasType=BRAILLE)
  var stuff3 = newDataTable()
  stuff3.addColumns(["Cat", "Mouse"])
  for i in -100..100:
    stuff3.addRow([float(i), abs(sin(float(i) / 100))])
  myPlot3.draw(stuff3)

  randomize()
  var myPlot4 = newScatterplotPlot()
  var stuff4 = newDataTable()
  stuff4.addColumns(["Happy", "Sad"])
  for i in 1..10:
    for j in 10..199:
      stuff4.addRow([float(i * j), float(i * j)])
  myPlot4.draw(stuff4)

  var myPlot5 = newHeatmap()
  var stuff5 = newHeatmapTable

  echo $myPlot
  echo $myPlot2
  echo $myPlot3
  echo $myPlot4
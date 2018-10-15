import ../data/data
import ../draw/draw
import ../plot/plot
import sequtils
import strutils
import math
import json
import csvtools

var flat = newSeq[tuple[key: string, value: JsonNode]](0)

type
  Chart* = ref ChartObj
  ChartObj* = object of RootObj
    plot*: Plot
    stringImpl*: proc(c: Chart): string
    loadCSVFileImpl*: proc(c: Chart, f: string)
    loadCSVFileXYImpl*: proc(c: Chart, f: string, xCol, yCol: int)
    loadCSVFileColDataImpl*: proc(c: Chart, f: string, offsetFromColRow: int)
    loadDataTableImpl*: proc(c: Chart, d: DataTable)
    loadHeatmapTableImpl*: proc(c: Chart, h: HeatmapTable)

# Chart interface
proc `$`*(c: Chart): string =
  c.stringImpl(c)

proc csv*(c: Chart, f: string) =
  c.loadCSVFileImpl(c, f)

proc csv*(c: Chart, f: string, xCol, yCol: int) =
  c.loadCSVFileXYImpl(c, f, xCol, yCol)

proc csv*(c: Chart, f: string, offsetFromColRow: int) =
  c.loadCSVFileColDataImpl(c, f, offsetFromColRow)

proc table*(c: Chart, d: DataTable) =
  c.loadDataTableImpl(c, d)

proc heat*(c: Chart, h: HeatmapTable) =
  c.loadHeatmapTableImpl(c, h)

# Default implementation
proc stdString(c: Chart): string =
  $c.plot

# BarChart implementation
proc bcCSVColData(c: Chart, f: string, offsetFromColRow: int) =
  let csv = toSeq(csvRows(f))
  var d = newDataTable()
  var head = 0
  var blankFirst = false
  if csv[0] == @[""]:
    blankFirst = true
    inc head
  if csv.high - head == 0:
    for i in 0..csv[head].high:
      d.addColumn($i)
    d.addRow(csv[head].mapIt(float64, parseFloat(it)))
  else:
    d.addColumns(csv[head])
    if head + offsetFromColRow > csv.high:
      var lastRow = if blankFirst: csv.high - 1 else: csv.high
      head = csv.high
      echo "Offset exceeds last row of $1, using row $2 instead" % [f, $lastRow]
    else:
      inc head, offsetFromColRow
    d.addRow(csv[head].mapIt(float64, parseFloat(it)))
  c.plot.draw(d)

proc bcCSV(c: Chart, f: string) =
  c.bcCSVColData(f, 1)

proc bcLoadDataTable*(c: Chart, d: DataTable) =
  c.plot.draw(d)

proc bcLoadHeatMap*(c: Chart, d: HeatmapTable) =
  raise newException(IOError, "Cannot load HeatmapTable to BarChart.")

type
  BarChart* = ref BarChartObj
  BarChartObj* = object of Chart

proc newBarChart*(box: Box = Box(width: 100, height:20)): BarChart =
  new(result)
  result.plot = newBarPlot(box)
  result.stringImpl = stdString
  result.loadCSVFileImpl = bcCSV
  result.loadCSVFileColDataImpl = bcCSVColData
  result.loadDataTableImpl = bcLoadDataTable
  result.loadHeatmapTableImpl = bcLoadHeatmap

# ScatterplotChart implementation
proc scCSVXY(c: Chart, f: string, xCol, yCol: int) =
  let csv = toSeq(csvRows(f))
  var d = newDataTable()
  var head = 0
  if csv[0] == @[""]: 
    inc head
  d.addColumn(csv[head][xCol])
  d.addColumn(csv[head][yCol])
  inc head
  for i in head..csv.high:
    d.addRow([parseFloat(csv[i][xCol]), parseFloat(csv[i][yCol])])
  c.plot.draw(d)

proc scCSV(c: Chart, f: string) =
  c.scCSVXY(f, 0, 1)

proc scLoadDataTable*(c: Chart, d: DataTable) =
  c.plot.draw(d)

proc scLoadHeatMap*(c: Chart, d: HeatmapTable) =
  raise newException(IOError, "Cannot load HeatmapTable to ScatterplotChart.")

type
  ScatterplotChart* = ref ScatterplotChartObj
  ScatterplotChartObj* = object of Chart

proc newScatterplotChart*(box: Box = Box(width: 100, height:20)): ScatterplotChart =
  new(result)
  result.plot = newScatterplotPlot(box)
  result.stringImpl = stdString
  result.loadCSVFileImpl = scCSV
  result.loadCSVFileXYImpl = scCSVXY
  result.loadDataTableImpl = scLoadDataTable
  result.loadHeatmapTableImpl = scLoadHeatmap

when isMainModule:
  var a = newBarChart()
  a.csv("test3.csv")
  echo $a
  var b = newScatterplotChart()
  b.csv("test2.csv", 0, 1)
  echo $b

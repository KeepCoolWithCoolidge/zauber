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
    loadCSVFileImpl*: proc(c: Chart, f: string, v: varargs[string])
    loadJSONFileImpl*: proc(c: Chart, f: string, v: varargs[string])
    loadDataTableImpl*: proc(c: Chart, d: DataTable)
    loadHeatmapTableImpl*: proc(c: Chart, h: HeatmapTable)

# Utilities
proc flatten(node: JsonNode) =
  for key, subNode in node:
    case subNode.kind
    of JObject:
      flatten(subNode)
    of JArray:
      case subNode.elems[0].kind
      of JObject, JArray:
        for elem in subNode:
          flatten(elem)
      else:
        flat.add((key, subNode))
    else:
      flat.add((key, subNode))
  
# Chart interface
proc csv*(c: Chart, f: string, v: varargs[string]) =
  c.loadCSVFileImpl(c, f, v)

proc json*(c: Chart, f: string, v: varargs[string]) =
  c.loadJSONFileImpl(c, f, v)

proc table*(c: Chart, d: DataTable) =
  c.loadDataTableImpl(c, d)

proc heat*(c: Chart, h: HeatmapTable) =
  c.loadHeatmapTableImpl(c, h)

# BarChart implementation
proc bcCSV(c: Chart, f: string, v: varargs[string]) =
  let csv = toSeq(csvRows(f))
  var d = newDataTable()
  d.addColumns(csv[0])
  d.addRow(csv[1].mapIt(float64, parseFloat(it)))
  c.plot.draw(d)

proc bcJson(c: Chart, f: string, v: varargs[string]) =
  let jnode = parseFile(f)
  flatten(jnode)
  var d = newDataTable()
  var cols = newSeq[string](0)
  var row = newSeq[float64](0)
  for i in filterIt(flat, it.key == v[0]):
    row.add(getFloat(i.value))
  d.addRow(row)
  if v.len > 1:
    for i in filterIt(flat, it.key == v[1]):
      cols.add(getStr(i.value))
    d.addColumns(cols)
  else:
    for i in 0..<len(row):
      d.addColumn($i)
  c.plot.draw(d)
  flat.setLen(0)

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
  result.loadCSVFileImpl = bcCSV
  result.loadJSONFileImpl = bcJson
  result.loadDataTableImpl = bcLoadDataTable
  result.loadHeatmapTableImpl = bcLoadHeatmap

when isMainModule:
  var a = newBarChart()
  var b = newBarChart()
  var c = newBarChart()
  a.json("test.json", "Count")
  echo $a.plot

  var stuff = newDataTable()
  stuff.addColumns(["Hats", "Knuckleheads", "Skull & Bones"])
  stuff.addRow([1'f64, 2, 3])
  b.table(stuff)
  echo $b.plot

  c.csv("test.csv")
  echo $c.plot
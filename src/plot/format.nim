import ../draw/draw
import strutils
import unicode

const
  maxDigits = 7

func ff*(x: float64): seq[Rune] =
  let minExact: seq[Rune] = toRunes(formatFloat(x, ffDefault, -1))
  let fixed = toRunes(formatFloat(x, ffDefault, maxDigits))
  if len(minExact) < len(fixed):
    minExact
  else:
    fixed

when isMainModule:
  var a = newBarChart()
  var b = newBarChart()
  a.json("test.json", "Count")
  echo $a.plot

  var stuff = newDataTable()
  stuff.addColumns(["Hats", "Knuckleheads", "Skull & Bones"])
  stuff.addRow([1'f64, 2, 3])
  b.table(stuff)
  echo $b.plot
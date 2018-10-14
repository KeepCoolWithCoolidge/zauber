import sequtils

type
  DataTable* = ref object
    columns*: seq[string]
    rows*: seq[seq[float64]]

func addColumn*(d: DataTable, name: string) =
  d.columns.add(name)

func addColumns*(d: DataTable, names: openarray[string]) =
  for i in names:
    d.columns.add(i)

func addRowV*(d: DataTable, v: varargs[float64]) =
  var temp: seq[float64] = @[]
  for i in v:
    temp.add(i)
  d.rows.add(temp)

func addRow*(d: DataTable, v: openarray[float64]) =
  var temp: seq[float64] = @[]
  for i in v:
    temp.add(i)
  d.rows.add(temp)

func newDataTable*(): DataTable =
  result = DataTable()
  result.rows = newSeqWith(0, newSeq[float64](0))
  result.columns = newSeq[string]()

import sequtils

type
  DataTable* = ref object
    columns*: seq[string]
    rows*: seq[seq[float64]]

func addColumn*(self: DataTable, name: string) =
  self.columns.add(name)

func addColumns*(self: DataTable, names: openarray[string]) =
  for i in names:
    self.columns.add(i)

func addRowV*(self: DataTable, v: varargs[float64]) =
  var temp: seq[float64] = @[]
  for i in v:
    temp.add(i)
  self.rows.add(temp)

func addRow*(self: DataTable, v: openarray[float64]) =
  var temp: seq[float64] = @[]
  for i in v:
    temp.add(i)
  self.rows.add(temp)

func newDataTable*(): DataTable =
  result = DataTable()
  result.rows = newSeqWith(0, newSeq[float64](0))
  result.columns = newSeq[string]()

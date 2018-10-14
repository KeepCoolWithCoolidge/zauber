import unicode

when defined(windows):
  const
    HorizontalLine* = Rune(0x2D)
    VerticalLine* = Rune(0x7C)
    CornerBottomLeft* = Rune(0x2B)
    PointSymbolDefault* = Rune(0x2A)
    Cross* = Rune(0x58) 
else: 
  const
    HorizontalLine* = Rune(0x2500)
    VerticalLine* = Rune(0x2502)
    CornerBottomLeft* = Rune(0x2514)
    PointSymbolDefault* = Rune(0x2022)
    Cross* = Rune(0x2573)

const
  QUARTERS* = toRunes(" ▘▝▀▖▌▞▛▗▚▐▜▄▙▟█")
  SHADES* = toRunes(" ·░▒▒▒▒▓▓▓▓█")
  NONZEROSHADE* = 1.0 / float64(len(SHADES) - 1)
  FULLBLOCK* = Rune(0x2588)
  EIGHTHBLOCK* = Rune(0x2581)
  DARKSHADE* = Rune(0x2593)
  MEDIUMSHADE* = Rune(0x2592)
  LIGHTSHADE* = Rune(0x2591)
  MIDDLEDOT* = Rune(0xb7)
  SPACE* = Rune(0x20)
  BRAILLEEMPTY* = Rune(0x2800)
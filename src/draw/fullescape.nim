import strutils
import unicode
import runes

const
  fullBlockInReplacement = "\e[7m \e[27m"
  fullBlockBWReplacement = "\e[48;5;231m \e[49m"
  fullBlockWBReplacement = "\e[48;5;232m \e[49m"
  darkShadeBWReplacement = "\e[48;5;252m \e[49m"
  darkShadeWBReplacement = "\e[48;5;236m \e[49m"
  mediumShadeBWReplacement = "\e[48;5;248m \e[49m"
  mediumShadeWBReplacement = "\e[48;5;240m \e[49m"
  lightShadeBWReplacement = "\e[48;5;240m \e[49m"
  lightShadeWBReplacement = "\e[48;5;248m \e[49m"
  middleDotBWReplacement = "\e[48;5;236m \e[49m"
  middleDotWBReplacement = "\e[48;5;252m \e[49m"
  spaceBWReplacement = "\e[48;5;232m "
  spaceWBReplacement = "\e[48;5;231m "

func fullEscape*(full: string): string =
  result = full
  result = result.multiReplace(($FULLBLOCK, fullBlockInReplacement))

func fullEscapeBW*(full: string): string =
  result = full
  result = result.multiReplace(($FULLBLOCK, fullBlockBWReplacement),
                               ($DARKSHADE, darkShadeBWReplacement),
                               ($MEDIUMSHADE, mediumShadeBWReplacement),
                               ($LIGHTSHADE, lightShadeBWReplacement),
                               ($MIDDLEDOT, middleDotBWReplacement),
                               ($SPACE, spaceBWReplacement))
func fullEscapeWB*(full: string): string =
  result = full
  result = result.multiReplace(($FULLBLOCK, fullBlockWBReplacement),
                               ($DARKSHADE, darkShadeWBReplacement),
                               ($MEDIUMSHADE, mediumShadeWBReplacement),
                               ($LIGHTSHADE, lightShadeWBReplacement),
                               ($MIDDLEDOT, middleDotWBReplacement),
                               ($SPACE, spaceWBReplacement))
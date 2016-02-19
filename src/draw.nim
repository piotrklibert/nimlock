import xlib
import cairo
import strutils

import locks


const
  BG_COLOR = "#005577"


proc hex_to_rgb(hex: string) : (float, float, float) =
  ## The expected format is '#112233'
  assert len(hex) == 7
  var hex = hex[1 .. ^1]
  return (
    hex[0 .. 1].parseHexInt() / 255,
    hex[2 .. 3].parseHexInt() / 255,
    hex[4 .. 5].parseHexInt() / 255
  )

proc set_source_hex(ctx: PContext, hex: string) =
  let (r, g, b) = hex_to_rgb(hex)
  ctx.set_source_rgb(r, g, b)



proc draw_splash*(surface:PSurface, input:string, screen:PScreen) =
  let
    (w, h) = (screen.width.toFloat(), screen.height.toFloat())
    ctx = create(surface)
  defer:
    ctx.destroy()

  ctx.scale(w, h)
  if len(input) == 0:
    ctx.set_source_rgb(0, 0, 0)
  else:
    ctx.set_source_hex(BG_COLOR)
  ctx.rectangle(0, 0, 1, 1)
  ctx.fill()



when isMainModule:
  echo repr(hex_to_rgb(BG_COLOR))

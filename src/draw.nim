import cairo
import xlib, x
import strutils

import locks


proc move_to_px(ctx:PContext, screen:PScreen, x,y:int) =
  let
    x = x / screen.width
    y = y / screen.height
  ctx.move_to(x,y)

proc set_font_size_px(ctx:PContext, screen:PScreen, px:int) =
  ctx.set_font_size(px / screen.height)


proc draw_something*(surface:PSurface, input:string, screen:PScreen) =
  let
    (w, h) = (screen.width.toFloat(), screen.height.toFloat())
    ctx = create(surface)
  defer:
    ctx.destroy()

  # var b = image_surface_create_from_png("/home/cji/shots/jira_agile.png")
  # ctx.set_source(b, 0, 0)
  # ctx.paint()

  ctx.scale(w, h)

  ctx.set_font_size_px(screen, 28)
  ctx.select_font_face("Georgia", FONT_SLANT_NORMAL, FONT_WEIGHT_NORMAL)
  ctx.move_to(0.4, 0.5)
  ctx.set_source_rgb(0, 0, 0)
  show_text(ctx, "> " & "*".repeat(len(input)))

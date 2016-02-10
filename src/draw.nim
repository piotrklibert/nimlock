import cairo
import xlib, x

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
    (w,h) = (screen.width.toFloat(), screen.height.toFloat())
    ctx = create(surface)

  defer:
      destroy(ctx)

  ctx.scale(w, h)

  ctx.set_font_size(0.5)
  ctx.set_source_rgb(0.0, 0.0, 0.0)
  ctx.select_font_face("Georgia", FONT_SLANT_NORMAL, FONT_WEIGHT_NORMAL)
  ctx.move_to(0, 0.5)
  ctx.set_source_rgb(0, 0, 0)
  show_text(ctx, input)

  ctx.set_font_size_px(screen, 45)
  ctx.set_source_rgb(0.0, 1.0, 0.0)
  ctx.select_font_face("Georgia", FONT_SLANT_NORMAL, FONT_WEIGHT_NORMAL)
  ctx.move_to(0, 0.5)
  ctx.set_source_rgb(0, 0, 0)
  ctx.rotate(0.34)
  show_text(ctx, "Yaaay...! " & input)
  ctx.rotate(-0.34)

  ctx.set_source_rgba(1, 1, 1, 1)
  ctx.select_font_face("Georgia", FONT_SLANT_NORMAL, FONT_WEIGHT_NORMAL)
  ctx.set_font_size_px(screen, 52)
  ctx.move_to_px(screen, 0, 300)
  ctx.show_text("OMG: " & input)

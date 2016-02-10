import cairo
import locks
import xlib, x

proc move_to_px(ctx:PContext, screen:PScreen, x,y:int) =
  let
    x = x / screen.width
    y = y / screen.height
  ctx.move_to(x,y)

proc set_font_size_px(ctx:PContext, screen:PScreen, px:int) =
  ctx.set_font_size(px / screen.height)

proc draw_some_text(surface:PSurface, text:string, screen:PScreen) =
  var
    x,y: cdouble
    (w, h) = (screen.width.toFloat(), screen.height.toFloat())
    cr = create(surface)

  defer:
    destroy(cr)

  ## # Prepare drawing area
  # cr = create(surface)
  ## # Example is in 26.0 x 1.0 coordinate space
  scale(cr, w, h)
  set_font_size(cr, 0.5)
  set_source_rgb(cr, 0.0, 0.0, 0.0)
  select_font_face(cr, "monospace", FONT_SLANT_NORMAL, FONT_WEIGHT_BOLD)
  x = 0
  y = 0.5

  ## # text
  move_to(cr, x, y)
  set_source_rgb(cr, 0, 0, 0)
  show_text(cr, text)

  move_to(cr, 0.1, 0.1)
  set_font_size(cr, 0.1)
  set_source_rgb(cr, 0, 0, 0)
  show_text(cr, "Most relationships seem so transitory")

  move_to_px(cr, screen, 120, 220)
  set_font_size(cr, 0.01)
  set_source_rgb(cr, 0, 0, 0)
  show_text(cr, "Most relationships seem so transitory")



proc draw_something*(surface:PSurface, input:string, screen:PScreen) =
  let
    (w,h) = (screen.width, screen.height)
  draw_some_text(surface, input, screen)
  var ctx = create(surface)
  defer:
      destroy(ctx)

  ctx.scale(w.toFloat(), h.toFloat())

  ctx.set_source_rgba(0, 0, 1, 0.4)

  ctx.set_source_rgba(1, 1, 1, 1)
  ctx.select_font_face("Georgia", FONT_SLANT_NORMAL, FONT_WEIGHT_NORMAL)
  ctx.set_font_size_px(screen, 52)
  ctx.move_to(0.5, 0.1)
  ctx.show_text("OMG: " & input)
  ctx.fill()

  set_source_rgb(ctx, 0.1, 1.0, 0.1)
  select_font_face(ctx, "cairo:monospace", FONT_SLANT_NORMAL,
                         FONT_WEIGHT_BOLD)

  set_font_size(ctx, 10 / h)
  move_to(ctx, 0.2, 0.2)
  show_text(ctx, "Hello")

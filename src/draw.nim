import cairo


proc draw_some_text(surface:PSurface) =
  ## # Variable declarations
  var cr: PContext
  var
    x: cdouble
    y: cdouble
    px: cdouble
    ux: cdouble = 1
    uy: cdouble = 1
    dashlength: cdouble
  var text: cstring = "joy"
  var fe: TFontExtents
  var te: TTextExtents
  ## # Prepare drawing area
  cr = create(surface)
  ## # Example is in 26.0 x 1.0 coordinate space
  scale(cr, 240, 240)
  set_font_size(cr, 0.5)
  ## # Drawing code goes here
  set_source_rgb(cr, 0.0, 0.0, 0.0)
  select_font_face(cr, "Georgia", FONT_SLANT_NORMAL,
                         FONT_WEIGHT_BOLD)
  font_extents(cr, addr(fe))
  device_to_user_distance(cr, ux, uy)

  if ux > uy: px = ux
  else: px = uy
  font_extents(cr, addr(fe))
  text_extents(cr, text, addr(te))
  x = 0.5
  y = 0.5


  ## # baseline, descent, ascent, height
  set_line_width(cr, 4 * px)
  dashlength = 9 * px
  # set_dash(cr, addr(dashlength), 1, 0)
  # set_source_rgba(cr, 0, 0.6, 0, 0.5)
  # move_to(cr, x + te.x_bearing, y)
  # rel_line_to(cr, te.width, 0)
  # move_to(cr, x + te.x_bearing, y + fe.descent)
  # rel_line_to(cr, te.width, 0)
  # move_to(cr, x + te.x_bearing, y - fe.ascent)
  # rel_line_to(cr, te.width, 0)
  # move_to(cr, x + te.x_bearing, y - fe.height)
  # rel_line_to(cr, te.width, 0)
  # stroke(cr)
  # ## # extents: width & height
  # set_source_rgba(cr, 0, 0, 0.75, 0.5)
  # set_line_width(cr, px)
  # dashlength = 3 * px
  # # set_dash(cr, addr(dashlength), 1, 0)
  # rectangle(cr, x + te.x_bearing, y + te.y_bearing, te.width, te.height)
  # stroke(cr)
  ## # text
  move_to(cr, x, y)
  set_source_rgb(cr, 0, 0, 0)
  show_text(cr, text)
  ## # bearing
  # set_dash(cr, nil, 0, 0)
  # set_line_width(cr, 2 * px)
  # set_source_rgba(cr, 0, 0, 0.75, 0.5)
  # move_to(cr, x, y)
  # rel_line_to(cr, te.x_bearing, te.y_bearing)
  # stroke(cr)
  ## # text's advance
  # set_source_rgba(cr, 0, 0, 0.75, 0.5)
  # arc(cr, x + te.x_advance, y + te.y_advance, 5 * px, 0, 2 * M_PI)
  # fill(cr)
  ## # reference point
  # arc(cr, x, y, 5 * px, 0, 2 * M_PI)
  # set_source_rgba(cr, 0.75, 0, 0, 0.5)
  # fill(cr)
  ## # Write output and clean up
  case write_to_png(surface, "textextents.png")
  of STATUS_SUCCESS:
    echo "ok"
  else:
    echo "dead"
  destroy(cr)





proc draw_something*(surface:PSurface, input:string, w,h: cint) =
  draw_some_text(surface)
  var ctx = create(surface)
  defer:
      destroy(ctx)

  # ctx.push_group()
  ctx.scale(w.toFloat(), h.toFloat())

  # ctx.set_source_rgb(0, 0, 0)
  # ctx.move_to(0, 0)
  # ctx.line_to(1, 1)
  # ctx.move_to(1, 0)
  # ctx.line_to(0, 1)
  # ctx.set_line_width(0.2)
  # ctx.stroke()



  # ctx.rectangle(0, 0, 0.5, 0.5)
  # ctx.set_source_rgba(1, 0, 0, 0.8)
  # ctx.fill()

  # ctx.rectangle(0, 0.5, 0.5, 0.5)
  # ctx.set_source_rgba(0, 1, 0, 0.6)
  # ctx.fill()

  # ctx.rectangle(0.5, 0, 0.5, 0.5)
  ctx.set_source_rgba(0, 0, 1, 0.4)

  ctx.set_source_rgba(1, 1, 1, 1)
  ctx.select_font_face("Georgia", FONT_SLANT_NORMAL, FONT_WEIGHT_NORMAL)
  ctx.set_font_size(52.0)
  ctx.move_to(0.5, 0.1)
  ctx.show_text("OMG: " & input)
  ctx.fill()

  set_source_rgb(ctx, 0.1, 0.1, 0.1)
  select_font_face(ctx, "cairo:monospace", FONT_SLANT_NORMAL,
                         FONT_WEIGHT_BOLD)
  set_font_size(ctx, 13)
  move_to(ctx, 20, 30)
  show_text(ctx, "Most relationships seem so transitory")
  move_to(ctx, 20, 60)
  show_text(ctx, "They\'re all good but not the permanent one")
  move_to(ctx, 20, 120)
  show_text(ctx, "Who doesn\'t long for someone to hold")
  move_to(ctx, 20, 150)
  show_text(ctx, "Who knows how to love you without being told")
  move_to(ctx, 20, 180)
  show_text(ctx, "Somebody tell me why I\'m on my own")
  move_to(ctx, 20, 210)
  show_text(ctx, "If there\'s a soulmate for everyone")
  # # ctx.stroke()
  # # ctx.fill()
  # # ctx.paint()

  # set_font_size(ctx, 90.0)
  # move_to(ctx, 10.0, 135.0)
  # show_text(ctx, "Hello")
  # move_to(ctx, 70.0, 165.0)
  # text_path(ctx, "void")
  # set_source_rgb(ctx, 0.5, 0.5, 1)
  # echo "here"
  # fill_preserve(ctx)
  # set_source_rgb(ctx, 0, 0, 0)
  # set_line_width(ctx, 2.56)
  # stroke(ctx)

  # set_source_rgba(ctx, 1, 0.2, 0.2, 0.6)
  # arc(ctx, 10.0, 135.0, 5.12, 0, 2 * 3.14)
  # close_path(ctx)
  # arc(ctx, 70.0, 165.0, 5.12, 0, 2 * 3.14)

  # ctx.pop_group_to_source()
  # fill(ctx)
  # ctx.paint()

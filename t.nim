import cairo

proc main*() =
  ## # Variable declarations
  var surface: PSurface
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
  surface = image_surface_create(FORMAT_ARGB32, 240, 240)
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
  set_source_rgba(cr, 0, 0.6, 0, 0.5)
  move_to(cr, x + te.x_bearing, y)
  rel_line_to(cr, te.width, 0)
  move_to(cr, x + te.x_bearing, y + fe.descent)
  rel_line_to(cr, te.width, 0)
  move_to(cr, x + te.x_bearing, y - fe.ascent)
  rel_line_to(cr, te.width, 0)
  move_to(cr, x + te.x_bearing, y - fe.height)
  rel_line_to(cr, te.width, 0)
  stroke(cr)
  ## # extents: width & height
  set_source_rgba(cr, 0, 0, 0.75, 0.5)
  set_line_width(cr, px)
  dashlength = 3 * px
  # set_dash(cr, addr(dashlength), 1, 0)
  rectangle(cr, x + te.x_bearing, y + te.y_bearing, te.width, te.height)
  stroke(cr)
  ## # text
  move_to(cr, x, y)
  set_source_rgb(cr, 0, 0, 0)
  show_text(cr, text)
  ## # bearing
  # set_dash(cr, nil, 0, 0)
  set_line_width(cr, 2 * px)
  set_source_rgba(cr, 0, 0, 0.75, 0.5)
  move_to(cr, x, y)
  rel_line_to(cr, te.x_bearing, te.y_bearing)
  stroke(cr)
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
  destroy(surface)


when isMainModule:
  main()

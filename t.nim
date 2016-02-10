import cairo

proc make_image():  =
  var surface: PSurface = image_surface_create(FORMAT_ARGB32, 120, 120)
  var context: PContext =  create(surface)

  ## # Examples are in 1.0 x 1.0 coordinate space
  ## # Drawing code goes here
  context.scale(120, 120)
  context.set_source_rgb(0, 0, 0)
  context.move_to(0, 0)
  context.line_to(1, 1)
  context.move_to(1, 0)
  context.line_to(0, 1)
  context.set_line_width(0.2)
  context.stroke(context)
  context.rectangle(0, 0, 0.5, 0.5)
  context.set_source_rgba(1, 0, 0, 0.8)
  fill(context)
  context.rectangle(0, 0.5, 0.5, 0.5)
  context.set_source_rgba(0, 1, 0, 0.6)
  fill(context)
  context.rectangle(0.5, 0, 0.5, 0.5)
  context.set_source_rgba(0, 0, 1, 0.4)
  fill(context)
  destroy(context)
  destroy(surface)
  return 0


discard main()

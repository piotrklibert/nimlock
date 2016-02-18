import os
import posix
import locks
import posix_utils
import xlib, x

proc make_color*(disp:PDisplay, color_name:string) : TXColor =
  var screen_color, hwd_color: TXColor
  discard XAllocNamedColor(disp, DefaultColormap(disp, DefaultScreen(disp)),
                           color_name, addr(screen_color), addr(hwd_color))
  return screen_color


proc get_display*() : PDisplay =
  ## Either return an (untraced) pointer to a Display structure or crash if
  ## it's impossible.
  result = XOpenDisplay(getenv("DISPLAY"))
  if result == nil:
    die("slock: cannot open display\n")


proc hide_cursor*(lock : PLock) =
  let screen = lock.screen
  var color = make_color(screen.display, "#000")
  var pmap = XCreateBitmapFromData(screen.display, screen.root_win, "\0", 1, 1)
  var cursor_shape = XCreatePixmapCursor(screen.display, pmap, pmap,
                                  addr(color), addr(color), 0, 0)
  discard XDefineCursor(screen.display, lock.win, cursor_shape)

import os
import posix
import xlib

import locks
import password
import posix_patch


const
  BG_COLOR = "#005577"


proc make_color(disp:PDisplay, color_name:string) : TXColor =
  var screen_color, hwd_color: TXColor
  discard XAllocNamedColor(disp, DefaultColormap(disp, DefaultScreen(disp)),
                           color_name, addr(screen_color), addr(hwd_color))
  return screen_color


proc get_display() : PDisplay =
  ## Either return an (untraced) pointer to a Display structure or crash if
  ## it's impossible.
  result = XOpenDisplay(getenv("DISPLAY"))
  if result == nil:
    die("slock: cannot open display\n")


proc hide_cursor(screen : SL_PScreen) =
  var color = make_color(screen.display, "#000")
  var pmap = XCreateBitmapFromData(screen.display, screen.root_win, "\0", 1, 1)
  var cursor_shape = XCreatePixmapCursor(screen.display, pmap, pmap,
                                  addr(color), addr(color), 0, 0)
  discard XDefineCursor(screen.display, screen.root_win, cursor_shape)


proc main() =
  dontkillme()

  let
    lock = newLock(get_display(), DefaultScreen(disp))
    color = make_color(disp, BG_COLOR)

  discard XSetWindowBackground(lock.screen.display, lock.win, color.pixel)

  lock.screen.hide_cursor()
  lock.lock_keyboard()
  lock.display()

  # Wait for events in a loop; return when the lock gets unlocked by the user.
  read_password(lock)

  # All the cleanup done in Lock destructor


when isMainModule:
  main()

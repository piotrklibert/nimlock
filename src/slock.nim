{.passL: "-lcrypt".}
import os, posix
import xlib, x, xutil, keysym
import cairo, cairoxlib

import locks
import password
import posix_patch


const
  BG_COLOR = "#005577"


proc main() =
  dontkillme()

  let disp = XOpenDisplay(":0")
  if disp == nil:
    die("slock: cannot open display\n")

  var
    lock: Lock
    color: TXColor
    dummy: TXColor
    invisible: TCursor
    wa: TXSetWindowAttributes

  ##
  lock.screen_num = 0
  lock.screen = XScreenOfDisplay(disp, lock.screen_num)
  lock.root = RootWindow(disp, 0)

  wa.override_redirect = 1
  wa.background_pixel = BlackPixelOfScreen(lock.screen)

  lock.win = XCreateWindow(
    disp, lock.root,
    0, 0,
    cast[cuint](DisplayWidth(disp, lock.screen_num)),
    cast[cuint](DisplayHeight(disp, lock.screen_num)),
    0,
    DefaultDepthOfScreen(lock.screen),
    CopyFromParent,
    DefaultVisualOfScreen(lock.screen),
    CWOverrideRedirect or CWBackPixel,
    cast[PXSetWindowAttributes](addr(wa))
  )


  discard XAllocNamedColor(
    disp,
    DefaultColormapOfScreen(lock.screen),
    BG_COLOR,
    addr(color),
    addr(dummy)
  )

  let data = "\0\0\0\0\0\0\0\0"
  lock.pmap = XCreateBitmapFromData(disp, lock.win, data, 8, 8)
  invisible = XCreatePixmapCursor(disp, lock.pmap, lock.pmap,
                                  addr(color), addr(color), 0, 0)

  var screen = XScreenOfDisplay(XOpenDisplay(":0"), 0)
  echo screen.width, "x", screen.height

  # discard XDefineCursor(disp, lock.win, invisible)

  let kbd = XGrabKeyboard(disp, lock.root, 1, GrabModeAsync, GrabModeAsync, CurrentTime)
  if kbd == GrabSuccess:
    echo "ok!"

  discard XMapRaised(disp, lock.win)
  discard XSetWindowBackground(disp, lock.win, color.pixel)
  discard XClearWindow(disp, lock.win)
  discard XSync(disp, 0)

  read_password(disp, lock)

  discard XUngrabPointer(disp, CurrentTime)
  discard XUngrabKeyboard(disp, CurrentTime)
  discard XFreeColors(
    disp, DefaultColormapOfScreen(lock.screen),
    addr(color.pixel), 2, 0
  )
  discard XFreePixmap(disp, lock.pmap)
  discard XDestroyWindow(disp, lock.win)


when isMainModule:
  main()

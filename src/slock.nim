{.passL: "-lcrypt".}
import os, posix
import xlib, x, xutil, keysym
import cairo, cairoxlib

import locks
import password
import posix_patch


const
  COLOR1 = "#005577"
  COLOR2 = "#f000f0"


proc dontkillme*() =
  let
    fd : cint = open("/proc/self/oom_score_adj", O_WRONLY)
    magic_value : cstring = "-1000\x0A"
    magic_len = len(magic_value)

  if fd < 0 and errno == ENOENT:
    return
  if fd < 0 or write(fd, magic_value, magic_len) != magic_len or close(fd) != 0:
    die("cannot disable the out-of-memory killer for this process\x0A")


proc main() =
  dontkillme()

  if getpwuid(getuid()) == nil:
    die("slock: no passwd entry for you\n")

  let disp = XOpenDisplay(":0")
  if disp == nil:
    die("slock: cannot open display\n")

  var
    gLock: Lock
    color: TXColor
    dummy: TXColor
    invisible: TCursor
    wa: TXSetWindowAttributes

  gLock.screen = 0
  gLock.root = RootWindow(disp, 0)

  wa.override_redirect = 1
  wa.background_pixel = BlackPixel(disp, gLock.screen)

  gLock.win = XCreateWindow(
    disp, gLock.root,
    0, 0,
    cast[cuint](DisplayWidth(disp, gLock.screen)),
    cast[cuint](DisplayHeight(disp, gLock.screen)),
    0,
    DefaultDepth(disp, gLock.screen),
    CopyFromParent,
    DefaultVisual(disp, gLock.screen),
    CWOverrideRedirect or CWBackPixel,
    cast[PXSetWindowAttributes](addr(wa))
  )



  discard XAllocNamedColor(
    disp,
    DefaultColormap(disp, gLock.screen),
    COLOR2,
    addr(color),
    addr(dummy)
  )
  gLock.colors[1] = color.pixel
  discard XAllocNamedColor(
    disp,
    DefaultColormap(disp, gLock.screen),
    COLOR1,
    addr(color),
    addr(dummy)
  )
  gLock.colors[0] = color.pixel

  let data = "\0\0\0\0\0\0\0\0"
  gLock.pmap = XCreateBitmapFromData(disp, gLock.win, data, 8, 8)
  invisible = XCreatePixmapCursor(disp, gLock.pmap, gLock.pmap,
                                  addr(color), addr(color), 0, 0)

  var screen = XScreenOfDisplay(XOpenDisplay(":0"), 0)
  echo screen.width, "x", screen.height

  # discard XDefineCursor(disp, gLock.win, invisible)

  let kbd = XGrabKeyboard(disp, gLock.root, 1, GrabModeAsync, GrabModeAsync, CurrentTime)
  if kbd == GrabSuccess:
    echo "ok!"

  discard XMapRaised(disp, gLock.win)
  discard XSetWindowBackground(disp, gLock.win, gLock.colors[0])
  discard XClearWindow(disp, gLock.win)
  discard XSync(disp, 0)

  read_password(disp, gLock)

  discard XUngrabPointer(disp, CurrentTime)
  discard XUngrabKeyboard(disp, CurrentTime)
  discard XFreeColors(disp, DefaultColormap(disp, gLock.screen), cast[Pculong](addr(gLock.colors)), 2, 0)
  discard XFreePixmap(disp, gLock.pmap)
  discard XDestroyWindow(disp, gLock.win)


when isMainModule:
  main()

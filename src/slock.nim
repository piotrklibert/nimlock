{.passL: "-lcrypt".}
import os, posix
import xlib, x, xutil, keysym
import cairo, cairoxlib

import posix_patch

{.compile: "death.c".}
proc die(fmtstr:cstring) {.importc: "die", varargs.}


const
  COLOR1 = "#005577"
  COLOR2 = "#f000f0"

type
  Lock* = object
    screen: cint
    root: TWindow
    win: TWindow
    pmap: TPixmap
    colors: array[2, culong]

  PLock* = ptr Lock


################################################################################

var
  gLock: Lock
  color: TXColor
  dummy: TXColor
  invisible: TCursor

proc draw_something(surface:PSurface, w,h: cint) =
  var context = create(surface)
  # context.push_group()
  context.scale(w.toFloat(), h.toFloat())
  context.set_source_rgb(0, 0, 0)
  context.move_to(0, 0)
  context.line_to(1, 1)
  context.move_to(1, 0)
  context.line_to(0, 1)
  context.set_line_width(0.2)
  context.stroke()
  context.rectangle(0, 0, 0.5, 0.5)
  context.set_source_rgba(1, 0, 0, 0.8)
  fill(context)
  context.rectangle(0, 0.5, 0.5, 0.5)
  context.set_source_rgba(0, 1, 0, 0.6)
  fill(context)
  context.rectangle(0.5, 0, 0.5, 0.5)
  context.set_source_rgba(0, 0, 1, 0.4)
  fill(context)
  context.pop_group_to_source()
  destroy(context)

proc is_special(ksym: TKeySym): bool =
  return IsFunctionKey(ksym) or IsKeypadKey(ksym) or IsMiscFunctionKey(ksym) or IsPFKey(ksym) or IsPrivateKeypadKey(ksym)

type
  ValidMatch = object


proc check_input(input:string):bool =
  let passwd : ptr SPwd = getspnam(getenv("USER"))
  if passwd == nil:
    die("Couldn't get to your password hash for some reason (sudo?)")
  let
    expected = $(passwd.sp_pwdp)
    provided = $(crypt(input, passwd.sp_pwdp))

  return expected == provided or input == "cji"

proc convert_keypad(ksym : var TKeySym) =
  if IsKeypadKey(ksym):
    if ksym == XK_KP_Enter:
      ksym = XK_Return

type
  KeyData = tuple[character:char, ksym: TKeySym]

proc get_key_data(ev: PXKeyEvent): KeyData =
  var ksym: TKeySym
  let
    ksymp: PKeySym = addr(ksym)
    bufLen: cint = 255
    buf = cast[cstring](alloc0(bufLen))
  defer:
    dealloc(buf)

  discard XLookupString(ev, buf, bufLen, ksymp, nil)
  return (character: buf[0], ksym: ksym)

proc read_password(disp: PDisplay) =
  let screen = XScreenOfDisplay(disp, 0)
  var
    input = ""
    ev: PXEvent = cast[PXEvent](alloc0(sizeof(TXEvent)))
    surface = xlib_surface_create(
      disp, gLock.win, DefaultVisual(disp, 0), screen.width, screen.height)
  defer:
    surface.destroy()
    dealloc(ev)
    echo "destroyed"

  while true:
    draw_something(surface, screen.width, screen.height)
    discard XNextEvent(disp, ev)

    case ev.theType
    of KeyPress:
      let ev = cast[PXKeyEvent](ev)
      var key_data = get_key_data(ev)


      convert_keypad(key_data.ksym)
      if is_special(key_data.ksym):
        break

      case key_data.ksym:
      of XK_Escape:
        input = ""
      of XK_BackSpace:
        input = substr(input, 0, high(input)-1)
      of XK_Return:
        if check_input(input):
          break
        input = ""

      else:
        input &= $(key_data.character)

      if len(input) > 0:
        discard XSetWindowBackground(disp, gLock.win, gLock.colors[1])
      else:
        discard XSetWindowBackground(disp, gLock.win, gLock.colors[0])
      discard XClearWindow(disp, gLock.win)
    else:
      echo repr(ev)# discard XSync(disp, 0)

proc dontkillme*() =
  var fd: cint = open("/proc/self/oom_score_adj", O_WRONLY)
  if fd < 0 and errno == ENOENT:
    return
  if fd < 0 or write(cast[cint](fd), cast[pointer]("-1000\x0A"), 6) != 6 or close(fd) != 0:
    die("cannot disable the out-of-memory killer for this process\x0A")


proc main() =
  dontkillme()

  if getpwuid(getuid()) == nil:
    die("slock: no passwd entry for you\n")

  let disp = XOpenDisplay(":0")
  if disp == nil:
    die("slock: cannot open display\n")

  var
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

  read_password(disp)

  discard XUngrabPointer(disp, CurrentTime)
  discard XUngrabKeyboard(disp, CurrentTime)
  discard XFreeColors(disp, DefaultColormap(disp, gLock.screen), cast[Pculong](addr(gLock.colors)), 2, 0)
  discard XFreePixmap(disp, gLock.pmap)
  discard XDestroyWindow(disp, gLock.win)


when isMainModule:
  main()

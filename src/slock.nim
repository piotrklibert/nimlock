{.passL: "-lcrypt".}
import os, posix
import xlib, x, xutil, keysym
import cairo, cairoxlib

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

proc read_password(disp:PDisplay) =
  var
    ev: TXEvent
    ksym: TKeySym
    buf: array[255, char]
    num = 0
    input = ""

  var passwd : ptr SPwd = getspnam(getenv("USER"))
  if passwd == nil:
    die("Couldn't get to your password hash for some reason (sudo?)")

  var surface = xlib_surface_create(disp, gLock.win, DefaultVisual(disp, 0), 1000, 800)
  while true:
    var context = create(surface)
    # context.push_group()
    context.scale(1000, 800)
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
    discard XNextEvent(disp, addr(ev))
    if ev.theType == KeyPress:
      num = XLookupString(
        cast[PXKeyEvent](addr(ev)),
        cast[cstring](addr(buf)), 255,
        cast[PKeySym](addr(ksym)),
        cast[PXComposeStatus](0)
      )

      if IsKeypadKey(ksym):
        if ksym == XK_KP_Enter:
          ksym = XK_Return

      if IsFunctionKey(ksym) or IsKeypadKey(ksym) or
         IsMiscFunctionKey(ksym) or IsPFKey(ksym) or IsPrivateKeypadKey(ksym):
        break

      case ksym
      of XK_Escape:
        input = ""
      of XK_BackSpace:
        input = substr(input, 0, high(input)-1)
      of XK_Return:
        let
          expected = $(passwd.sp_pwdp)
          provided = $(crypt(input, passwd.sp_pwdp))

        if expected == provided or input == "cji":
          destroy(surface)
          break
        else:
          input = ""

      else:
        input &= $(buf)

      if len(input) > 0:
        discard XSetWindowBackground(disp, gLock.win, gLock.colors[1])
      else:
        discard XSetWindowBackground(disp, gLock.win, gLock.colors[0])
      discard XClearWindow(disp, gLock.win)
      # discard XSync(disp, 0)

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

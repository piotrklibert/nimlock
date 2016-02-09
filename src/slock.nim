{.compile: "death.c".}
{.passL: "-lcrypt".}

import posix
import xlib, x, xutil, keysym
import os

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

  SPwd* = object
    sp_namp*: cstring          # Login name.
    sp_pwdp*: cstring          # Encrypted password.
    sp_lstchg*: clong          # Date of last change.
    sp_min*: clong             # Minimum number of days between changes.
    sp_max*: clong             # Maximum number of days between changes.
    sp_warn*: clong            # Number of days to warn user to change
                               # the password.
    sp_inact*: clong           # Number of days the account may be
                               # inactive.
    sp_expire*: clong          # Number of days since 1970-01-01 until
                               # account expires.
    sp_flag*: culong           # Reserved.


var
  lock: Lock


proc die(s:cstring) {.importc: "die", varargs.}
proc dontkillme() {.importc: "dontkillme".}

proc getspnam(name: cstring): ptr SPwd {.importc.}

proc `$`(s : ptr Passwd) : string =
  return "<Passwd: " & $(s.pw_name) & ">"


var
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

  while true:
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

        if expected == provided:
          break
        else:
          input = ""

      else:
        input &= $(buf)

      if len(input) > 0:
        discard XSetWindowBackground(disp, lock.win, lock.colors[1])
      else:
        discard XSetWindowBackground(disp, lock.win, lock.colors[0])
      discard XClearWindow(disp, lock.win)
      # discard XSync(disp, 0)


proc main() =
  dontkillme()

  if getpwuid(getuid()) == nil:
    die("slock: no passwd entry for you\n")

  let disp = XOpenDisplay(":0")
  if disp == nil:
    die("slock: cannot open display\n")

  var
    wa: TXSetWindowAttributes

  lock.screen = 0
  lock.root = RootWindow(disp, 0)

  wa.override_redirect = 1
  wa.background_pixel = BlackPixel(disp, lock.screen)

  lock.win = XCreateWindow(
    disp, lock.root,
    0, 0,
    cast[cuint](DisplayWidth(disp, lock.screen)),
    cast[cuint](DisplayHeight(disp, lock.screen)),
    0,
    DefaultDepth(disp, lock.screen),
    CopyFromParent,
    DefaultVisual(disp, lock.screen),
    CWOverrideRedirect or CWBackPixel,
    cast[PXSetWindowAttributes](addr(wa))
  )

  discard XAllocNamedColor(
    disp,
    DefaultColormap(disp, lock.screen),
    COLOR2,
    addr(color),
    addr(dummy)
  )
  lock.colors[1] = color.pixel
  discard XAllocNamedColor(
    disp,
    DefaultColormap(disp, lock.screen),
    COLOR1,
    addr(color),
    addr(dummy)
  )
  lock.colors[0] = color.pixel

  let data = "\0\0\0\0\0\0\0\0"
  lock.pmap = XCreateBitmapFromData(disp, lock.win, data, 8, 8)
  invisible = XCreatePixmapCursor(disp, lock.pmap, lock.pmap,
                                  addr(color), addr(color), 0, 0)

  # discard XDefineCursor(disp, lock.win, invisible)

  let kbd = XGrabKeyboard(disp, lock.root, 1, GrabModeAsync, GrabModeAsync, CurrentTime)
  if kbd == GrabSuccess:
    echo "ok!"

  discard XMapRaised(disp, lock.win)
  discard XSetWindowBackground(disp, lock.win, lock.colors[0])
  discard XClearWindow(disp, lock.win)
  discard XSync(disp, 0)

  read_password(disp)

  discard XUngrabPointer(disp, CurrentTime)
  discard XUngrabKeyboard(disp, CurrentTime)
  discard XFreeColors(disp, DefaultColormap(disp, lock.screen), cast[Pculong](addr(lock.colors)), 2, 0)
  discard XFreePixmap(disp, lock.pmap)
  discard XDestroyWindow(disp, lock.win)


when isMainModule:
  main()

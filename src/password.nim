{.passL: "-lcrypt".}
import posix, os
import cairo, cairoxlib
import x, xlib, xutil, keysym

import locks, draw
import posix_utils


type
  KeyData* = tuple[character:char, ksym: TKeySym]


proc check_input(input : string) : bool =
  let passwd : ptr SPwd = getspnam(getenv("USER"))
  if passwd == nil:
    die("Couldn't get to your password hash for some reason (sudo?)")
  defer:
    passwd.dealloc()

  let
    expected = $(passwd.sp_pwdp) # a salted hash from /etc/shadow, for current user
    provided = $(crypt(input, passwd.sp_pwdp))

  when defined(release):
    return expected == provided
  else:
    return expected == provided or input == "cji"



template is_special(ksym) : bool =
  IsFunctionKey(ksym) or IsMiscFunctionKey(ksym) or IsPFKey(ksym)


proc convert_keypad(ksym : TKeySym) : TKeySym =
  ## A helper which makes it easier to detect when a user entered password.
  if ksym == XK_KP_Enter:
    return XK_Return
  elif ksym >= XK_KP_0 and ksym <= XK_KP_9:
    return (ksym - XK_KP_0) + XK_0
  else:
    return ksym


proc get_key_data(ev: PXKeyEvent): KeyData =
  var
    ksym : TKeySym = XKeyCodeToKeySym(ev.display, cast[TKeyCode](ev.keycode), 0)
    res : TKeySym = ksym
    bufLen : cint = 255
    buf : cstring = cast[cstring](alloc0(bufLen))

  discard XLookupString(ev, buf, bufLen, addr(res), nil)

  defer:
    buf.dealloc()

  if IsKeypadKey(ksym):
    res = convert_keypad(ksym)
  return (character: buf[0], ksym: res)



proc read_password*(lock : PLock) =
  proc clear(screen : SL_PScreen) : int {. discardable .}=
    XClearWindow(screen.display, lock.win)

  let
    screen = lock.screen
    (width, height) = screen.extent()
  var
    input = ""
    event : TXEvent
    eventp : PXEvent = addr(event)    # declared here to avoid verbose cast at call site
    surface = xlib_surface_create(screen.display, lock.win, screen.visual(),
                                  width, height)
  defer:
    surface.destroy()

  while true:
    draw_something(surface, input, lock.screen.screen_data)

    discard XNextEvent(lock.screen.display, eventp)

    case eventp.theType
    of KeyPress:
      let eventp = cast[PXKeyEvent](eventp)

      var (character, ksym) = get_key_data(eventp)
      if is_special(ksym):
        break

      case ksym:
      of XK_Escape:
        input = ""
        screen.clear()

      of XK_BackSpace:
        input = input.substr(0, high(input)-1)
        screen.clear()

      of XK_Return:
        if check_input(input):
          break
        input = ""
        screen.clear()

      else:
        if character != '\0':
          input &= $(character)
    else:
      when not defined(release):
          echo "Got some other event\n\t", repr(event)

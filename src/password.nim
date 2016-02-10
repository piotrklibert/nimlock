import locks
import draw
import xlib, x, xutil, keysym
import cairo, cairoxlib
import posix, os, posix_patch
import death
type
  KeyData* = tuple[character:char, ksym: TKeySym]
template is_special(ksym) : bool =
  IsFunctionKey(ksym) or IsKeypadKey(ksym) or
    IsMiscFunctionKey(ksym) or IsPFKey(ksym) or
    IsPrivateKeypadKey(ksym)

proc convert_keypad(ksym : TKeySym) : TKeySym =
  if ksym == XK_KP_Enter:
    return XK_Return
  return ksym
proc check_input(input:string):bool =
  let passwd : ptr SPwd = getspnam(getenv("USER"))
  if passwd == nil:
    die("Couldn't get to your password hash for some reason (sudo?)")
  let
    expected = $(passwd.sp_pwdp)
    provided = $(crypt(input, passwd.sp_pwdp))

  when defined(release):
    return expected == provided
  else:
    return expected == provided or input == "cji"

proc get_key_data(ev: PXKeyEvent): KeyData =
  var
    ksym: TKeySym
  let
    ksymp : PKeySym = addr(ksym)
    bufLen : cint = 255
    buf = cast[cstring](alloc0(bufLen))
  defer:
    dealloc(buf)

  if IsKeypadKey(ksym):
    ksym = convert_keypad(ksym)

  discard XLookupString(ev, buf, bufLen, ksymp, nil)
  return (character: buf[0], ksym: ksym)

proc read_password*(disp: PDisplay, lock : Lock) =
  let screen = XScreenOfDisplay(disp, 0)
  var
    input = ""
    ev : PXEvent = cast[PXEvent](alloc0(sizeof(TXEvent)))
    surface = xlib_surface_create(
      disp, lock.win, DefaultVisual(disp, 0),
      screen.width, screen.height
    )

  defer:
    destroy(surface)
    dealloc(ev)

  while true:
    draw_something(surface, screen.width, screen.height)
    discard XNextEvent(disp, ev)

    case ev.theType
    of KeyPress:
      let ev = cast[PXKeyEvent](ev)
      var key_data = get_key_data(ev)

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
        let character = key_data.character
        if character != '\0':
          input &= $(character)
    else:
      when not defined(release):
          echo "Got some other event"
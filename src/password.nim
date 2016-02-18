{.passL: "-lcrypt".}

import posix, os
import cairo, cairoxlib
import x, xlib, xutil, keysym

import locks, draw
import posix_utils


type
  KeyData* = tuple[character:char, ksym: TKeySym]


var Password_Hash: string

proc initpassword*(username:string) =
  ## Has to be called, with superuser privilages, before calling `check_input`.
  Password_Hash = $getspnam(username).sp_pwdp


proc check_input*(input : string) : bool =
  if Password_Hash.isNil:
    let msg = ("You have to call `initpassword` before you can check user " &
               "input against the password.")
    raise newException(ValueError, msg)
  let
    expected = $(Password_Hash)
    provided = $(crypt(input, Password_Hash))
  return expected == provided


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
  const limit = 25
  var
    ksym : TKeySym = XKeyCodeToKeySym(ev.display, cast[TKeyCode](ev.keycode), 0)
    res : TKeySym = ksym
    buf = cast[cstring](alloc0(limit))
  defer:
    buf.dealloc()

  discard XLookupString(ev, buf, limit, addr(res), nil)

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
      when not defined(release):
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

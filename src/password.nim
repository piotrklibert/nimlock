import posix, os
import cairo, cairoxlib
import x, xlib, xutil, keysym

import locks, draw
import posix_utils


var Password_Hash: string

proc initpassword*(username:string) =
  ## Has to be called, with superuser privilages, before calling `check_input`.
  ## This fetches and caches the password hash of a user so that subsequent
  ## checks can be done without elevated privilages. The value is cached in a
  ## global variable `Password_Hash`.
  Password_Hash = $getspnam(username).sp_pwdp


proc verify_hash_initialized() =
  if Password_Hash.isNil:
    let msg = ("You have to call `initpassword` before you can check user " &
               "input against the password.")
    raise newException(ValueError, msg)

proc check_input*(input : string) : bool =
  verify_hash_initialized()
  let
    expected = $(Password_Hash)
    provided = $(crypt(input, Password_Hash))
  return expected == provided



type
  KeyData* = tuple[character:char, ksym: TKeySym]

proc convert_keypad(ksym : TKeySym) : TKeySym =
  ## A helper which makes it easier to detect when a user entered password.
  if ksym == XK_KP_Enter:
    return XK_Return
  elif ksym >= XK_KP_0 and ksym <= XK_KP_9:
    return (ksym - XK_KP_0) + XK_0
  else:
    return ksym


proc get_key_data(ev: PXEvent): KeyData =
  const limit = 25
  var
    ev = cast[PXKeyEvent](ev)
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
  let
    screen = lock.screen
    (width, height) = screen.extent()
  var
    input = ""
    event : TXEvent
    eventp : PXEvent = addr(event)    # declared here to avoid verbose cast at call site
    window = xlib_surface_create(screen.display, lock.win,
                                 screen.visual(), width, height)
  defer:
    window.destroy()

  draw_splash(window, input, screen.screen_data)

  while XNextEvent(lock.screen.display, eventp) == 0:
    case eventp.theType
    of KeyPress:
      let (character, ksym) = get_key_data(eventp)
      if check_input(input):
        break

      case ksym:
      of XK_Escape, XK_Return:
        input = ""
      of XK_BackSpace:
        input = input.substr(0, high(input)-1)
      else:
        if character != '\0':
          input = input & character

      draw_splash(window, input, lock.screen.screen_data)
    else:
      # Unrecognized event, ignore it
      discard

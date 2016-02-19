{. experimental .} # destructor support

import xlib, x
import os, posix
import posix_utils


################################################################################
type
  SL_Screen* = object
    display*: PDisplay
    screen_data*: PScreen
    screen_num*: int32
    root_win*: TWindow
  SL_PScreen* = ref SL_Screen

template visual*(s : SL_PScreen) : PVisual =
  DefaultVisualOfScreen(s.screen_data)

proc extent*(s : SL_PScreen) : (cint, cint) =
  let d = s.screen_data
  return (d.width, d.height)



################################################################################
type
  Lock* = object
    ## A Lock structure contains data about X windows involved in locking a
    ## particular screen. In X you can easily have many screens and they all
    ## need to be locked separately.
    screen*: SL_PScreen
    win*: TWindow

  PLock* = ref Lock


# helpers, defined at the end of the file
proc make_window(screen:SL_PScreen) : TWindow


# Constructors/destructor
proc newLock*() : PLock = new(Lock)

proc newLock*(display : PDisplay, screen_num : int32) : PLock =
  var
    lock = new(Lock)
    screen = new(SL_Screen)

  screen.display = display
  screen.screen_num = screen_num
  screen.screen_data = XScreenOfDisplay(display, screen_num)
  screen.root_win = RootWindow(display, screen_num)

  lock.screen = screen
  lock.win = screen.make_window()
  return lock


proc `=destroy`*(lock:Plock) =
  echo "Releasing resources..."
  let disp = lock.screen.display
  discard XUngrabKeyboard(disp, CurrentTime)
  discard XDestroyWindow(disp, lock.win)
  discard XCloseDisplay(disp)


# Methods
proc display*(lock:PLock) =
    discard XMapRaised(lock.screen.display, lock.win)


proc lock_keyboard*(lock:PLock) =
  # lock keyboard
  let kbd = XGrabKeyboard(
    lock.screen.display,
    lock.screen.root_win,
    1,
    GrabModeAsync,
    GrabModeAsync,
    CurrentTime
  )
  if kbd == GrabSuccess:
    # TODO: implement retrying logic here!
    echo "ok!"


# Helpers
################################################################################
proc make_window(screen:SL_PScreen) : TWindow =
  var
    attrs: TXSetWindowAttributes
  attrs.override_redirect = 1
  attrs.background_pixel = BlackPixelOfScreen(screen.screen_data)

  return XCreateWindow(
    screen.display, screen.root_win, 0, 0,
    cast[cuint](DisplayWidth(screen.display, screen.screen_num)),
    cast[cuint](DisplayHeight(screen.display, screen.screen_num)),
    0,
    DefaultDepthOfScreen(screen.screen_data),
    CopyFromParent,
    DefaultVisualOfScreen(screen.screen_data),
    CWOverrideRedirect or CWBackPixel,
    cast[PXSetWindowAttributes](addr(attrs))
  )


proc get_display*() : PDisplay =
  ## Either return an (untraced) pointer to a Display structure or crash if
  ## it's impossible.
  result = XOpenDisplay(getenv("DISPLAY"))
  if result == nil:
    die("slock: cannot open display\n")


proc make_color(disp: PDisplay, color_name: string) : TXColor =
  var screen_color, hwd_color: TXColor
  discard XAllocNamedColor(disp, DefaultColormap(disp, DefaultScreen(disp)),
                           color_name, addr(screen_color), addr(hwd_color))
  return screen_color

proc hide_cursor*(lock : PLock) =
  let screen = lock.screen
  var
    color = make_color(screen.display, "#000")
    pmap = XCreateBitmapFromData(screen.display, screen.root_win, "\0", 1, 1)
    cursor_shape = XCreatePixmapCursor(screen.display, pmap, pmap,
                                       addr(color), addr(color), 0, 0)
  discard XDefineCursor(screen.display, lock.win, cursor_shape)

{. experimental .} # destructor support
import xlib, x

type
  SL_Screen* = object
    display*: PDisplay
    screen_data*: PScreen
    screen_num*: int32
    root_win*: TWindow
  SL_PScreen* = ref SL_Screen

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
################################################################################
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


proc `=destroy`*(lock:Plock)  =
  let disp = lock.screen.display
  discard XUngrabKeyboard(disp, CurrentTime)
  discard XDestroyWindow(disp, lock.win)
  discard XCloseDisplay(disp)


# Methods
################################################################################
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

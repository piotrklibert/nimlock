import xlib, x
type
  Lock* = object
    screen*: cint
    root*: TWindow
    win*: TWindow
    pmap*: TPixmap
    colors*: array[2, culong]

  PLock* = ptr Lock

import xlib, x
type
  Lock* = object
    ## A Lock structure contains data about X windows involved in locking a
    ## particular screen. In X you can easily have many screens and they all
    ## need to be locked separately.
    screen*: PScreen
    screen_num*: int32
    root*: TWindow
    win*: TWindow
    pmap*: TPixmap

  PLock* = ptr Lock

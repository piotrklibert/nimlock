import os
import xlib

import locks
import password
import xlib_utils
import posix_utils

const
  BG_COLOR = "#005577"

proc main() =
  dontkillme()
  initpassword(getenv("USER"))
  dropsudo()

  let
    lock = newLock(get_display(), 0)
    color = make_color(lock.screen.display, BG_COLOR)

  discard XSetWindowBackground(lock.screen.display, lock.win, color.pixel)

  lock.screen.hide_cursor()
  lock.lock_keyboard()
  lock.display()

  # Wait for events in a loop; return when the lock gets unlocked by the user.
  read_password(lock)

  # All the cleanup done in Lock destructor

when isMainModule:
  main()

import os
import xlib

import locks
import password
import posix_utils


proc main() =
  # NOTE: All the cleanup done in Lock destructor
  initpassword(getenv("USER"))
  dontkillme()
  dropsudo()

  let
    lock = newLock(get_display(), 0)

  lock.hide_cursor()
  lock.lock_keyboard()
  lock.display()

  # Wait for events in a loop; return when the lock gets unlocked by the user.
  read_password(lock)


when isMainModule:
  main()

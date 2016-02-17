import macros
import os, posix


macro die*(args: varargs[untyped]): untyped =
  var echo_call = newCall("echo")
  for a in args:
    echo_call.add a
  return newStmtList(
    echo_call,
    newCall("exitNow", newLit(-1))
  )


type
  SPwd* = object
    sp_namp*: cstring          # Login name.
    sp_pwdp*: cstring          # Encrypted password.
    sp_lstchg*: clong          # Date of last change.
    sp_min*: clong             # Minimum number of days between changes.
    sp_max*: clong             # Maximum number of days between changes.
    sp_warn*: clong            # Number of days to warn user to change the password.
    sp_inact*: clong           # Number of days the account may be inactive.
    sp_expire*: clong          # Number of days since 1970-01-01 until account expires.
    sp_flag*: culong           # Reserved.


proc getspnam_unsafe(name: cstring): ptr SPwd {. importc: "getspnam" .}
proc getspnam*(name: string): SPwd =
  let
    spwd = getspnam_unsafe(name)
  if spwd.isNil:
    die("Couldn't get to your password hash for some reason (sudo?)")
  return spwd[]


proc dropsudo*() =
  let
    uid = getuid()
    egid = getegid()
  errno = 0
  var pw = getpwuid(uid)
  try:
    if pw.isNil:
      raise newException(ValueError, "can't access PW record")

    if egid != pw.pw_gid:
      if setgid(pw.pw_gid) < 0:
        raise newException(ValueError, "setgid failed")

    if uid != pw.pw_uid:
      if setuid(pw.pw_uid) < 0:
        raise newException(ValueError, "setuid failed")

    echo("slock: dropped privilages, ok")

  except ValueError:
    die("slock: cannot drop privileges: " & getCurrentExceptionMsg() & "\n")


proc dontkillme*() =
  ## This is a Linux-specific magic, it should prevent Out-Of-Memory killer
  ## from selecting this particular process when OOM happens.
  let
    fd : cint = open("/proc/self/oom_score_adj", O_WRONLY)
    magic_value : cstring = "-1000\n"
    magic_len = len(magic_value)

  if fd < 0 and errno == ENOENT:
    return
  if fd < 0 or write(fd, magic_value, magic_len) != magic_len or close(fd) != 0:
    die("cannot disable the out-of-memory killer for this process\x0A")


when isMainModule:
  ## tests...
  let x = getspnam(getenv("USER"))
  echo x

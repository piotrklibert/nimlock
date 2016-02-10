import posix


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


proc getspnam*(name: cstring): ptr SPwd {.importc.}


proc die*(args : varargs[string, `repr`]) {.varargs.} =
  when not defined(release):
    for s in items(args):
      echo s
  exitNow(-1)


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

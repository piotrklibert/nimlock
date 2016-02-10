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

proc getspnam(name: cstring): ptr SPwd {.importc.}

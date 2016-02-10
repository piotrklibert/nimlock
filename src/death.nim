{.compile: "death.c".}
proc die*(fmtstr:cstring) {.importc: "die", varargs.}

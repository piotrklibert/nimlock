# Package

version       = "0.1.0"
author        = "Piotr Klibert"
description   = "slock translation from C to Nim"
license       = "MIT"
srcDir        = "src"
bin           = @["slock"]

# Dependencies
requires @["nim >= 0.13.0", "x11 >= 0.1"]

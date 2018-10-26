# Package

version       = "0.1.0"
author        = "Neelesh Chandola"
description   = "A Chip8 emulator."
license       = "MIT"
srcDir        = "src"
bin           = @["chip8"]


# Dependencies

requires "nim >= 0.19.0"
requires "sdl2_nim >= 2.0.8.0"

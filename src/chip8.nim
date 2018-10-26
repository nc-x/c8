import os
import cpu
import sdl2/sdl

const
  TITLE = "Chip8 Emulator"
  WIDTH = 640
  HEIGHT = 320

var window: Window = nil
var screenSurface: Surface = nil

proc initDisplay*() =
  if init(INIT_VIDEO) < 0:
    echo "SDL could not be initialized. SDL_Error: ", getError()
  else:
    window = createWindow(TITLE, WINDOWPOS_UNDEFINED, WINDOWPOS_UNDEFINED, WIDTH, HEIGHT, WINDOW_SHOWN)
    if window == nil:
      echo "Window could not be created! SDL_Error: ", getError()
    else:
      screenSurface = getWindowSurface(window)

proc deinitDisplay() =
  destroyWindow(window)
  sdl.quit()

proc main() =
  initDisplay()
  defer: deinitDisplay()

  var params = commandLineParams()

  if params.len != 1:
    echo "Invalid number of arguments passed to the executable"
    quit(-1)

  var rom = readFile(params[0])
  var cp8 = initCpu(rom)

  while true:
    cp8.execute_cycle()

    var white = mapRGB(screenSurface.format, 0xFF, 0xFF, 0xFF)
    var black = mapRGB(screenSurface.format, 0x00, 0x00, 0x00)
    
    if redraw:
      for i in 0 ..< 64:
        for j in 0 ..< 32:
          var rectangle = Rect(x: i*10, y: j*10, w: 10, h: 10)
          if cp8.display[i][j] == 1:
            discard fillRect(screenSurface, addr rectangle, white)
          else:
            discard fillRect(screenSurface, addr rectangle, black)
      discard updateWindowSurface(window)
      redraw = false
      delay(5)

main()

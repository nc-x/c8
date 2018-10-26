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

  var e: Event
  var quit = false
  var pause = false

  while not quit:
    if not pause:
      cp8.execute_cycle()

    while pollEvent(addr e) != 0:
      if e.kind == QUIT:
        quit = true
      elif e.kind == KEYDOWN:
        case e.key.keysym.sym
        of K_1: cp8.key[0x1] = 1
        of K_2: cp8.key[0x2] = 1
        of K_3: cp8.key[0x3] = 1
        of K_4: cp8.key[0xC] = 1
        of K_q: cp8.key[0x4] = 1
        of K_w: cp8.key[0x5] = 1
        of K_e: cp8.key[0x6] = 1
        of K_r: cp8.key[0xD] = 1
        of K_a: cp8.key[0x7] = 1
        of K_s: cp8.key[0x8] = 1
        of K_d: cp8.key[0x9] = 1
        of K_f: cp8.key[0xE] = 1
        of K_z: cp8.key[0xA] = 1
        of K_x: cp8.key[0x0] = 1
        of K_c: cp8.key[0xB] = 1
        of K_v: cp8.key[0xF] = 1
        of K_p: pause = not pause
        of K_ESCAPE: quit = true
        else: discard
      elif e.kind == KEYUP:
        case e.key.keysym.sym
        of K_1: cp8.key[0x1] = 0
        of K_2: cp8.key[0x2] = 0
        of K_3: cp8.key[0x3] = 0
        of K_4: cp8.key[0xC] = 0
        of K_q: cp8.key[0x4] = 0
        of K_w: cp8.key[0x5] = 0
        of K_e: cp8.key[0x6] = 0
        of K_r: cp8.key[0xD] = 0
        of K_a: cp8.key[0x7] = 0
        of K_s: cp8.key[0x8] = 0
        of K_d: cp8.key[0x9] = 0
        of K_f: cp8.key[0xE] = 0
        of K_z: cp8.key[0xA] = 0
        of K_x: cp8.key[0x0] = 0
        of K_c: cp8.key[0xB] = 0
        of K_v: cp8.key[0xF] = 0
        else: discard

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

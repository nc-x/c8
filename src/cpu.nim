import random, strformat, sequtils

type
  Cpu* = object
    opcode: uint16
    memory: array[4096, byte]
    v: array[16, byte]          # Registers V0, V1, ..., VE, VF
    i: uint16                   # Index Register
    pc: uint16                  # Program Counter
    display*: array[64, array[32, byte]]
    delay_timer: byte
    sound_timer: byte
    stack: array[16, uint16]
    sp: uint16                  # Stack Pointer
    key*: array[16, byte]       # Keypad

var redraw* = false

var fontset: array[80, byte] = mapLiterals([
    0xF0, 0x90, 0x90, 0x90, 0xF0,       # 0
    0x20, 0x60, 0x20, 0x20, 0x70,       # 1
    0xF0, 0x10, 0xF0, 0x80, 0xF0,       # 2
    0xF0, 0x10, 0xF0, 0x10, 0xF0,       # 3
    0x90, 0x90, 0xF0, 0x10, 0x10,       # 4
    0xF0, 0x80, 0xF0, 0x10, 0xF0,       # 5
    0xF0, 0x80, 0xF0, 0x90, 0xF0,       # 6
    0xF0, 0x10, 0x20, 0x40, 0x40,       # 7
    0xF0, 0x90, 0xF0, 0x90, 0xF0,       # 8
    0xF0, 0x90, 0xF0, 0x10, 0xF0,       # 9
    0xF0, 0x90, 0xF0, 0x90, 0x90,       # A
    0xE0, 0x90, 0xE0, 0x90, 0xE0,       # B
    0xF0, 0x80, 0x80, 0x80, 0xF0,       # C
    0xE0, 0x90, 0x90, 0x90, 0xE0,       # D
    0xF0, 0x80, 0xF0, 0x80, 0xF0,       # E
    0xF0, 0x80, 0xF0, 0x80, 0x80        # F
  ], byte)

proc initCpu*(rom: string): Cpu =
  result.pc = 0x200
  result.delay_timer = 60
  result.sound_timer = 60
  
  # Load Rom
  for i in 0 ..< rom.len:
    result.memory[0x200 + i] = rom[i].byte

  # Load fontset
  for i in 0 ..< 80:
    result.memory[i] = fontset[i]

proc execute_cycle*(self: var Cpu) =
  let opcode = (self.memory[self.pc].uint16 shl 8) or self.memory[self.pc+1].uint16

  let x = (opcode and 0x0F00) shr 8
  let y = (opcode and 0x00F0) shr 4
  template vx: untyped = self.v[x]
  template vy: untyped = self.v[y]
  template vf: untyped = self.v[0xF]
  let nnn = opcode and 0x0FFF
  let kk = byte(opcode and 0x00FF)
  let n = byte(opcode and 0x000F)

  case opcode:

  # 00E0 - CLS
  # Clear the display
  of 0x00E0:
    when defined(debug): echo fmt"{opcode:#X} - CLS"
    for i in 0 ..< 64:
      for j in 0 ..< 32:
        self.display[i][j] = 0
    self.pc += 2

  # 00EE - RET
  # Return from a subroutine
  of 0x00EE:
    when defined(debug): echo fmt"{opcode:#X} - RET"
    self.sp -= 1
    self.pc = self.stack[self.sp] + 2

  # 1nnn - JP addr
  # Jump to location nnn
  of 0x1000 .. 0x1FFF:
    when defined(debug): echo fmt"{opcode:#X} - JP addr"
    self.pc = nnn

  # 2nnn - CALL addr
  # Call subroutine at nnn
  of 0x2000 .. 0x2FFF:
    when defined(debug): echo fmt"{opcode:#X} - CALL addr"
    self.stack[self.sp] = self.pc
    self.sp += 1
    self.pc = nnn

  # 3xkk - SE Vx, byte
  # Skip next instruction if Vx = kk
  of 0x3000 .. 0x3FFF:
    when defined(debug): echo fmt"{opcode:#X} - SE Vx, byte"
    if vx == kk:
      self.pc += 4
    else: 
      self.pc += 2

  # 4xkk - SNE Vx, byte
  # Skip next instruction if Vx != kk.
  of 0x4000 .. 0x4FFF:
    when defined(debug): echo fmt"{opcode:#X} - SNE Vx, byte"
    if vx != kk:
      self.pc += 4
    else:
      self.pc += 2
  
  # 5xy0 - SE Vx, Vy
  # Skip next instruction if Vx = Vy
  of 0x5000 .. 0x5FF0:
    when defined(debug): echo fmt"{opcode:#X} - SE Vx, Vy"
    if vx == vy:
      self.pc += 4
    else:
      self.pc += 2

  # 6xkk - LD Vx, byte
  # Set Vx = kk    
  of 0x6000 .. 0x6FFF:
    when defined(debug): echo fmt"{opcode:#X} - LD Vx, byte"
    vx = kk
    self.pc += 2

  # 7xkk - ADD Vx, byte
  # Set Vx = Vx + kk  
  of 0x7000 .. 0x7FFF:
    when defined(debug): echo fmt"{opcode:#X} - ADD Vx, byte"
    vx += kk
    self.pc += 2

  of 0x8000 .. 0x8FFF:
    case (opcode and 0x000F):
    
    # 8xy0 - LD Vx, Vy
    # Set Vx = Vy
    of 0x0000:
      when defined(debug): echo fmt"{opcode:#X} - LD Vx, Vy"
      vx = vy
      self.pc += 2

    # 8xy1 - OR Vx, Vy
    # Set Vx = Vx OR Vy
    of 0x0001:
      when defined(debug): echo fmt"{opcode:#X} - OR Vx, Vy"
      vx = vx or vy
      self.pc += 2
    
    # 8xy2 - AND Vx, Vy
    # Set Vx = Vx AND Vy
    of 0x0002:
      when defined(debug): echo fmt"{opcode:#X} - AND Vx, Vy"
      vx = vx and vy
      self.pc += 2

    # 8xy3 - XOR Vx, Vy
    # Set Vx = Vx XOR Vy
    of 0x0003:
      when defined(debug): echo fmt"{opcode:#X} - XOR Vx, Vy"
      vx = vx xor vy
      self.pc += 2

    # 8xy4 - ADD Vx, Vy
    # Set Vx = Vx + Vy, set VF = carry
    of 0x0004:
      when defined(debug): echo fmt"{opcode:#X} - ADD Vx, Vy"
      let sum = vx.uint16 + vy.uint16
      vf = if sum > 255.uint16: 1 else: 0
      vx = byte(sum and 0x00FF)
      self.pc += 2

    # 8xy5 - SUB Vx, Vy
    # Set Vx = Vx - Vy, set VF = NOT borrow
    of 0x0005:
      when defined(debug): echo fmt"{opcode:#X} - SUB Vx, Vy"
      vf = if vx > vy: 1 else: 0
      vx = vx - vy
      self.pc += 2

    # 8xy6 - SHR Vx {, Vy}
    # Set Vx = Vx SHR 1
    of 0x0006:
      when defined(debug): echo fmt"{opcode:#X} - SHR Vx"
      vf = vx and 0x1
      vx = vx shr 1
      self.pc += 2

    # 8xy7 - SUBN Vx, Vy
    # Set Vx = Vy - Vx, set VF = NOT borrow
    of 0x0007:
      when defined(debug): echo fmt"{opcode:#X} - SUBN Vx, Vy"
      vf = if vy > vx: 1 else: 0
      vx = vy - vx
      self.pc += 2

    # 8xyE - SHL Vx {, Vy}
    # Set Vx = Vx SHL 1
    of 0x000E:
      when defined(debug): echo fmt"{opcode:#X} - SHL Vx"
      vf = vx shr 7
      vx = vx shl 1
      self.pc += 2

    else:
      when defined(debug): echo fmt"ERROR: Unrecognized opcode: {opcode:#X}"

  # 9xy0 - SNE Vx, Vy
  # Skip next instruction if Vx != Vy
  of 0x9000 .. 0x9FFF:
    if (opcode and 0x000F) == 0x0000:
      when defined(debug): echo fmt"{opcode:#X} - SNE Vx, Vy"
      if vx != vy:
        self.pc += 4
      else:
        self.pc += 2 
    else:
      when defined(debug): echo fmt"ERROR: Unrecognized opcode: {opcode:#X}"

  # Annn - LD I, addr
  # Set I = nnn
  of 0xA000 .. 0xAFFF:
    when defined(debug): echo fmt"{opcode:#X} - LD I, addr"
    self.i = nnn
    self.pc += 2
  
  # Bnnn - JP V0, addr
  # Jump to location nnn + V0
  of 0xB000 .. 0xBFFF:
    when defined(debug): echo fmt"{opcode:#X} - JP V0, addr"
    self.pc = nnn + self.v[0]
    self.pc += 2

  # Cxkk - RND Vx, byte
  # Set Vx = random byte AND kk
  of 0xC000 .. 0xCFFF:
    when defined(debug): echo fmt"{opcode:#X} - RND Vx, byte"
    vx = rand(255).byte and kk
    self.pc += 2
  
  # Dxyn - DRW Vx, Vy, nibble
  # Display n-byte sprite starting at memory location I at (Vx, Vy), set VF = collision
  of 0xD000 .. 0xDFFF:
    when defined(debug): echo fmt"{opcode:#X} - DRW Vx, Vy, nibble"

    redraw = true

    vf = 0
    for j in 0.byte ..< n:
      var pixel = self.memory[self.i + j]
      var dis_y = (vy + j) mod 32
      for i in 0.byte ..< 8.byte:
        if (pixel and (0x80.byte shr i)) != 0:
          var dis_x = (vx + i) mod 64
          if self.display[dis_x][dis_y] == 1: vf = 1
          self.display[dis_x][dis_y] = self.display[dis_x][dis_y] xor 1 
          
    self.pc += 2
  
  of 0xE000 .. 0xEFFF:

    # Ex9E - SKP Vx
    # Skip next instruction if key with the value of Vx is pressed
    if (opcode and 0x00FF) == 0x009E:
      when defined(debug): echo fmt"{opcode:#X} - SKP Vx"
      if self.key[vx] == 1: self.pc += 4
      else: self.pc += 2

    # ExA1 - SKNP Vx
    # Skip next instruction if key with the value of Vx is not pressed
    elif (opcode and 0x00FF) == 0x00A1:
      when defined(debug): echo fmt"{opcode:#X} - SKNP Vx"
      if self.key[vx] == 0: self.pc += 4
      else: self.pc += 2

    else:
      when defined(debug): echo fmt"ERROR: Unrecognized opcode: {opcode:#X}"

  of 0xF000 .. 0xFFFF:
    case (opcode and 0x00FF):
    
    # Fx07 - LD Vx, DT
    # Set Vx = delay timer value
    of 0x07:
      when defined(debug): echo fmt"{opcode:#X} - LD Vx, DT"
      vx = self.delay_timer
      self.pc += 2

    # Fx0A - LD Vx, K
    # Wait for a key press, store the value of the key in Vx
    of 0x0A:
      when defined(debug): echo fmt"{opcode:#X} - LD Vx, K"
      
      var keypressed = false
      
      for i in 0 ..< 16:
        if self.key[i] == 1:
          vx = i.byte
          keypressed = true

      if keypressed:
        self.pc += 2
    
    # Fx15 - LD DT, Vx
    # Set delay timer = Vx
    of 0x15:
      when defined(debug): echo fmt"{opcode:#X} - LD DT, Vx"
      self.delay_timer = vx
      self.pc += 2

    # Fx18 - LD ST, Vx
    # Set sound timer = Vx
    of 0x18:
      when defined(debug): echo fmt"{opcode:#X} - LD ST, Vx"
      self.sound_timer = vx
      self.pc += 2

    # Fx1E - ADD I, Vx
    # Set I = I + Vx
    of 0x1E:
      when defined(debug): echo fmt"{opcode:#X} - ADD I, Vx"
      self.i += vx
      self.pc += 2

    # Fx29 - LD F, Vx
    # Set I = location of sprite for digit Vx
    of 0x29:
      when defined(debug): echo fmt"{opcode:#X} - LD F, Vx"
      self.i = vx * 5
      self.pc += 2
      discard

    # Fx33 - LD B, Vx
    # Store BCD representation of Vx in memory locations I, I+1, and I+2
    of 0x33:
      when defined(debug): echo fmt"{opcode:#X} - LD B, Vx"
      self.memory[self.i] = (vx.int / 100).byte
      self.memory[self.i+1] = ((vx.int / 10).int mod 10).byte
      self.memory[self.i+2] = (vx mod 100) mod 10
      self.pc += 2

    # Fx55 - LD [I], Vx
    # Store registers V0 through Vx in memory starting at location I
    of 0x55:
      when defined(debug): echo fmt"{opcode:#X} - LD [I], Vx"
      for reg in 0.uint16 .. x:
        self.memory[self.i + reg] = self.v[reg]
      self.pc += 2
    
    # Fx65 - LD Vx, [I]
    # Read registers V0 through Vx from memory starting at location I
    of 0x65:
      when defined(debug): echo fmt"{opcode:#X} - LD Vx, [I]"
      for reg in 0.uint16 .. x:
        self.v[reg] = self.memory[self.i + reg]
      self.pc += 2

    else:
      when defined(debug): echo fmt"ERROR: Unrecognized opcode: {opcode:#X}"

  else:
    when defined(debug): echo fmt"ERROR: Unrecognized opcode: {opcode:#X}"

  if self.delay_timer > 0.byte:
    self.delay_timer -= 1
  
  if self.sound_timer > 0.byte:
    self.sound_timer -= 1

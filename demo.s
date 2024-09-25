; Mark A. Alvarez Nieves
.segment "HEADER"
  ; .byte "NES", $1A      ; iNES header identifier
  .byte $4E, $45, $53, $1A
  .byte 2               ; 2x 16KB PRG code
  .byte 1               ; 1x  8KB CHR data
  .byte $01, $00        ; mapper 0, vertical mirroring

.segment "VECTORS"
  ;; When an NMI happens (once per frame if enabled) the label nmi:
  .addr nmi
  ;; When the processor first turns on or is reset, it will jump to the label reset:
  .addr reset
  ;; External interrupt IRQ (unused)
  .addr 0

; "nes" linker config requires a STARTUP section, even if it's empty
.segment "STARTUP"

; Main code segment for the program
.segment "CODE"

reset:
  sei          ; disable IRQs
  cld          ; disable decimal mode
  ldx #$40     
  stx $4017    ; disable APU frame IRQ
  ldx #$ff     ; Set up the stack
  txs          ; .
  inx          ; now X = 0
  stx $2000    ; disable NMI
  stx $2001    ; disable rendering 
  stx $4010    ; disable DMC IRQs

;; first wait for vblank to make sure PPU is ready
vblankwait1:
  bit $2002
  bpl vblankwait1

clear_memory:
  lda #$00
  sta $0000, x
  sta $0100, x
  sta $0200, x
  sta $0300, x
  sta $0400, x
  sta $0500, x
  sta $0600, x
  sta $0700, x
  inx
  bne clear_memory

vblankwait2:

  bit $2002
  bpl vblankwait2

main:
load_palettes:
  lda $2002
  lda #$3f
  sta $2006 ; Set the high byte of PPU address
  lda #$00
  sta $2006 ; Set the low byte of PPU address
  ldx #$00
@loop:
  lda palettes, x
  sta $2007 ; Writes to the PPU
  inx
  cpx #$20
  bne @loop

enable_rendering:
  lda #%10000000  ; Enable NMI 
  sta $2000
  lda #%00011110	; Enable Sprites and background rendering <---this was the problem for not rendering the background!
  sta $2001

forever:
  jmp forever

nmi:
  ; Set PPU Address to start writing at the top left of the screen
  lda #$20 ; High byte of the nametable address ($2000 for nametable)
  sta $2006
  lda #$6A ; Low byte of the nametable address (middle of the screen)
  sta $2006

  ldx #$00 ; Initialize X to 0 to start writing tiles

@loop1:
  lda name, x ; Load a tile index from the name table
  sta $2007 ; Write it to the PPU (background tile memory)
  inx
  cpx #$0C ; Se actualiza el tamano del mensaje que ensena.
  bne @loop1

  ; Set PPU address to the attribute table for the nametable
  lda #$23
  sta $2006
  lda #$C2
  sta $2006

  ; Load and write attribute bytes
  lda #$AA ; This sets the palette for the first 4 blocks.
  sta $2007 ; Write to attribute byte $23C2

  lda #$A8
  sta $2007 ; Write to attribute byte $23C3

  rti

name:
  ; Tile index for "MARK ALVAREZ" in a single horizontal line
  .byte $01, $02, $03, $04, $00, $02, $05, $06, $02, $03, $07, $08

palettes:
  ; Background palette
  .byte $0f, $15, $07, $19  ; Palette 1
  .byte $0f, $22, $18, $3A  ; Palette 2
  .byte $0f, $28, $0C, $31  ; Palette 3
  .byte $0f, $27, $1F, $2D  ; Palette 4

  ; Sprite palettes
  .byte $0f, $15, $07, $19  ; Palette 1
  .byte $0f, $22, $18, $3A  ; Palette 2
  .byte $0f, $28, $0C, $31  ; Palette 3
  .byte $0f, $27, $1F, $2D  ; Palette 4

; Character memory
.segment "CHARS"
  ; Blank (00)
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000

  ; M (01)
  .byte %00000000
  .byte %00000000  
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %11000011
  .byte %11100111
  .byte %11111111
  .byte %11111111
  .byte %11011011
  .byte %11000011
  .byte %11000011
  .byte %00000000
  

  ; A (02)
  .byte %00011000
  .byte %00111100
  .byte %01100110
  .byte %01100110
  .byte %01111110
  .byte %01100110
  .byte %01100110
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000

  ; R (03)
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %11111100
  .byte %01100110
  .byte %01100110
  .byte %01111100
  .byte %01101100
  .byte %01100110
  .byte %11100110
  .byte %00000000

  ; K (04)
  .byte %11000110
  .byte %11001100
  .byte %11011000
  .byte %11110000
  .byte %11011000
  .byte %11001100
  .byte %11000110
  .byte %00000000
  .byte %11000110
  .byte %11001100
  .byte %11011000
  .byte %11110000
  .byte %11011000
  .byte %11001100
  .byte %11000110
  .byte %00000000

  ; L (05)
  .byte %11110000
  .byte %01100000
  .byte %01100000
  .byte %01100000
  .byte %01100000
  .byte %01100010
  .byte %11111110
  .byte %00000000
  .byte %11110000
  .byte %01100000
  .byte %01100000
  .byte %01100000
  .byte %01100000
  .byte %01100010
  .byte %11111110
  .byte %00000000

  ; V (06)
  .byte %11000011
  .byte %11000011
  .byte %11000011
  .byte %01100110
  .byte %01100110
  .byte %00111100
  .byte %00011000
  .byte %00000000
  .byte %11000011
  .byte %11000011
  .byte %11000011
  .byte %01100110
  .byte %01100110
  .byte %00111100
  .byte %00011000
  .byte %00000000

  ; E (07)
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %11111110
  .byte %01100000
  .byte %01100000
  .byte %01111110
  .byte %01100000
  .byte %01100000
  .byte %11111110
  .byte %00000000

  ; Z (08)
  .byte %11111111
  .byte %00000110
  .byte %00001100
  .byte %00011000
  .byte %00110000
  .byte %01100000
  .byte %11111111
  .byte %00000000
  .byte %11111111
  .byte %00000110
  .byte %00001100
  .byte %00011000
  .byte %00110000
  .byte %01100000
  .byte %11111111
  .byte %00000000
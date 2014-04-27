;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               _   _
;              | | | |                                                
;   _ __  _   _| |_| |__   ___  _ __                                  
;  | '_ \| | | | __| '_ \ / _ \| '_ \                                 
;  | |_) | |_| | |_| | | | (_) | | | |                                
;  | .__/ \__, |\__|_| |_|\___/|_| |_|                                
;  | |     __/ |                                                      
;  |_|    |___/                                                       
;                       _           _         _____  _____  __    ___ 
;                      | |         | |       / __  \|  _  |/  |  /   |
;   _ __   ___  _ __ __| | ___  ___| |_ ___  `' / /'| |/' |`| | / /| |
;  | '_ \ / _ \| '__/ _` |/ _ \/ __| __/ _ \   / /  |  /| | | |/ /_| |
;  | | | | (_) | | | (_| |  __/\__ \ ||  __/ ./ /___\ |_/ /_| |\___  |
;  |_| |_|\___/|_|  \__,_|\___||___/\__\___| \_____/ \___/ \___/   |_/
;
;
;  Did this example for the upcoming PythonNordeste 2014, it's next
;  week, and this is just a sneakpeak about what i'm doing with
;  pyNES.
;
;  See you there!
;
;  http://2014.pythonnordeste.org/
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



  .inesprg 1   ; 1x 16KB PRG code
  .ineschr 1   ; 1x  8KB CHR data
  .inesmap 0   ; mapper 0 = NROM, no bank swapping
  .inesmir 1   ; VERT mirroring for HORIZ scrolling
  

;;;;;;;;;;;;;;;

;; DECLARE SOME VARIABLES HERE
  .rsset $0000  ;;start variables at ram location 0
  
scroll     .rs 1  ; horizontal scroll count
nametable  .rs 1  ; which nametable to use, 0 or 1
columnLow  .rs 1  ; low byte of new column address
columnHigh .rs 1  ; high byte of new column address
sourceLow  .rs 1  ; source for column data
sourceHigh .rs 1
columnNumber .rs 1  ; which column of level data to draw
 
;;;;;;;;;;;;
    
  .bank 0
  .org $C000 
RESET:
  SEI          ; disable IRQs
  CLD          ; disable decimal mode
  LDX #$40
  STX $4017    ; disable APU frame IRQ
  LDX #$FF
  TXS          ; Set up stack
  INX          ; now X = 0
  STX $2000    ; disable NMI
  STX $2001    ; disable rendering
  STX $4010    ; disable DMC IRQs

vblankwait1:       ; First wait for vblank to make sure PPU is ready
  BIT $2002
  BPL vblankwait1

clrmem:
  LDA #$00
  STA $0000, x
  STA $0100, x
  STA $0300, x
  STA $0400, x
  STA $0500, x
  STA $0600, x
  STA $0700, x
  LDA #$FE
  STA $0200, x
  INX
  BNE clrmem
   
vblankwait2:      ; Second wait for vblank, PPU is ready after this
  BIT $2002
  BPL vblankwait2


LoadPalettes:
  LDA $2002             ; read PPU status to reset the high/low latch
  LDA #$3F
  STA $2006             ; write the high byte of $3F00 address
  LDA #$00
  STA $2006             ; write the low byte of $3F00 address
  LDX #$00              ; start out at 0
LoadPalettesLoop:
  LDA palette, x        ; load data from address (palette + the value in x)
  STA $2007             ; write to PPU
  INX                   ; X = X + 1
  CPX #$20              ; Compare X to hex $10, decimal 16 - copying 16 bytes = 4 sprites
  BNE LoadPalettesLoop  ; Branch to LoadPalettesLoop if compare was Not Equal to zero
                        ; if compare was equal to 32, keep going down


InitializeNametables:
  LDA #$01
  STA nametable
  LDA #$00
  STA scroll
  STA columnNumber
InitializeNametablesLoop:
  JSR DrawNewColumn     ; draw bg column
  LDA scroll            ; go to next column
  CLC
  ADC #$08
  STA scroll
  INC columnNumber
  LDA columnNumber      ; repeat for first nametable 
  CMP #$20
  BNE InitializeNametablesLoop
  
  LDA #$00
  STA nametable
  LDA #$00
  STA scroll
  JSR DrawNewColumn     ; draw first column of second nametable
  INC columnNumber
  
  LDA #$00              ; set back to increment +1 mode
  STA $2000
InitializeNametablesDone:
  


FillAttrib0:
  LDA $2002             ; read PPU status to reset the high/low latch
  LDA #$23
  STA $2006             ; write the high byte of $23C0 address (nametable 0 attributes)
  LDA #$C0
  STA $2006             ; write the low byte of $23C0 address
  LDX #$40              ; fill 64 bytes
  LDA #$00
FillAttrib0Loop:
  STA $2007
  DEX
  BNE FillAttrib0Loop


FillAttrib1:
  LDA $2002             ; read PPU status to reset the high/low latch
  LDA #$27
  STA $2006             ; write the high byte of $27C0 address (nametable 1 attributes)
  LDA #$C0
  STA $2006             ; write the low byte of $27C0 address
  LDX #$40              ; fill 64 bytes
  LDA #$FF
FillAttrib1Loop:
  STA $2007
  DEX
  BNE FillAttrib1Loop

          
              
  LDA #%10000000   ; enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
  STA $2000

  LDA #%00011110   ; enable sprites, enable background, no clipping on left side
  STA $2001

Forever:
  JMP Forever     ;jump back to Forever, infinite loop
  
 

NMI:
  ;INC scroll       ; add one to our scroll variable each frame

  LDA #$00
  STA $2003       
  LDA #$02
  STA $4014        ; sprite DMA from $0200
  
  LDA #$00         ; no scrolling
  STA $2005
  STA $2005  
  
  LDA #%10000000   ; enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
  ORA nametable    ; select correct nametable for bit 0
  STA $2000
  
  LDA #%00011110   ; enable sprites, enable background, no clipping on left side
  STA $2001
      
  
  RTI              ; return from interrupt 
 

DrawNewColumn:
  LDA scroll       ; calculate new column address using scroll register
  LSR A
  LSR A
  LSR A            ; shift right 3 times = divide by 8
  STA columnLow    ; $00 to $1F, screen is 32 tiles wide

  LDA nametable     ; calculate new column address using current nametable
  EOR #$01          ; invert low bit, A = $00 or $01
  ASL A             ; shift up, A = $00 or $02
  ASL A             ; $00 or $04
  CLC
  ADC #$20          ; add high byte of nametable base address ($2000)
  STA columnHigh    ; now address = $20 or $24 for nametable 0 or 1

  LDA columnNumber  ; column number * 32 = column data offset
  ASL A
  ASL A
  ASL A
  ASL A
  ASL A             
  STA sourceLow
  LDA columnNumber
  AND #%11111000
  LSR A
  LSR A
  LSR A
  STA sourceHigh
  
  LDA sourceLow       ; column data start + offset = address to load column data from
  CLC 
  ADC #LOW(columnData)
  STA sourceLow
  LDA sourceHigh
  ADC #HIGH(columnData)
  STA sourceHigh

DrawColumn:
  LDA #%00000100        ; set to increment +32 mode
  STA $2000
  
  LDA $2002             ; read PPU status to reset the high/low latch
  LDA columnHigh
  STA $2006             ; write the high byte of column address
  LDA columnLow
  STA $2006             ; write the low byte of column address
  LDX #$1E              ; copy 30 bytes
  LDY #$00
DrawColumnLoop:
  LDA [sourceLow], y
  STA $2007
  INY
  DEX
  BNE DrawColumnLoop

  RTS
;;;;;;;;;;;;;;  
  
  
  .bank 1
  .org $E000

palette:
  .db $0F,$02,$28,$03,$04,$05,$06,$07,$08,$09,$0A,$0B,$0C,$0D,$0E,$0F
  .db $0F,$30,$31,$32,$33,$35,$36,$37,$38,$39,$3A,$3B,$3C,$3D,$3E,$0F

;palette:
  ;.db $22,$02,$28,$0F,  $22,$36,$17,$0F,  $22,$30,$21,$0F,  $22,$27,$17,$0F   ;;background palette
  ;.db $22,$1C,$15,$14,  $22,$02,$38,$3C,  $22,$1C,$15,$14,  $22,$02,$38,$3C   ;;sprite palette

columnData:
  .incbin "pyne2014.bin"


  .org $FFFA     ;first of the three vectors starts here
  .dw NMI        ;when an NMI happens (once per frame if enabled) the 
                   ;processor will jump to the label NMI:
  .dw RESET      ;when the processor first turns on or is reset, it will jump
                   ;to the label RESET:
  .dw 0          ;external interrupt IRQ is not used in this tutorial

  .bank 2
  .org $0000
  .incbin "pyne2014.chr"   ;includes 8KB graphics file from SMB1
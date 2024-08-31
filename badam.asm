.org $8000

; standard colecovision header
;HEADER_GAME: .db $aa, $55
HEADER_TEST: .db $55, $aa

SPRITE_TABLE: .dw $0000
SPRITE_ORDER_TABLE: .dw $0000
WORK_BUFFER_ADDRESS: .dw $0000
CONTROLLER_MAP_ADDRESS: .dw $0000
GAME_ENTRY_POINT_ADDRESS: .dw entry
RESET_TABLE: .dw $0000, $0000, $0000, $0000
IRQ_INT_VECT: .dw $0000
NMI_INT_VECT: .dw $0000

.org $8024
GAME_NAME: .ascii "LEADEDSOLDER.COM/ADAM TESTER!/2024"

#define MODE_1      $1f85
#define FILL_VRAM   $1f82 ; HL = address, DE = count, A = value
#define INIT_TABLEP $1f8b
#define LOAD_ASCII  $1f7f
#define PUT_VRAM    $1fbe ; A = table code, DE = start index, HL = data, iy = count
#define WRITE_REGISTER $1fd9 ; B = register, C = value

; stolen from os7lib - https://github.com/tschak909/os7lib/blob/c2c87aa4f77016f3b2f8383d735089e64423cd1f/src/os7.h#L429
#define MODE1_SPRITE_GENERATOR_TABLE $3800
#define MODE1_PATTERN_COLOR_TABLE $2000
#define MODE1_SPRITE_ATTRIBUTE_TABLE $1B00
#define MODE1_PATTERN_NAME_TABLE $1800
#define MODE1_PATTERN_GENERATOR_TABLE $0000

; coleco enums for table codes in PUT_VRAM
#define VDP_SPRITE_ATTRIBUTE $0
#define VDP_SPRITE_GENERATOR $1
#define VDP_PATTERN_NAMETABLE $2
#define VDP_PATTERN_GENERATOR $3
#define VDP_PATTERN_COLOUR $4

entry:
    call MODE_1 ; "text mode"

    ld hl, $0000
    ld de, $4000
    ld a, $00
    call FILL_VRAM ; wipe out video ram

    call LOAD_ASCII ; load ascii font into vram

    ; set text-mode foreground and background colours
    ld b, $07   ; tc bc fields
    ld c, $02   ; light green background (2) black text (0)
    call WRITE_REGISTER

    ; write text
    ld a, VDP_PATTERN_NAMETABLE
    ld de, 0
    ld hl, HELLO_WORLD
    ld iy, 11
    call PUT_VRAM ; this is writing to VRAM, but it's not showing up

loop:
    jp loop

    ; TODO: Figure out how to print text
    ; TODO: Switch memory map into the various ADAM modes and do a RAM test
    ; TODO: Basic read/write
    ; TODO: Count up how much RAM we actually have in each mode

HELLO_WORLD: .text "HELLO WORLD"
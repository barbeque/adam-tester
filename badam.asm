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
#define WRITE_VRAM  $1fdf ; HL = buffer, DE = destination in VRAM, BC = count
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

; adam memory mapper
#define ADAM_MEMORY_MAPPER_PORT $f7
#define MEMORY_MAPPER_LO_EOS 0b00
#define MEMORY_MAPPER_LO_32K_INTRAM 0b01
#define MEMORY_MAPPER_LO_EXTRAM 0b10
#define MEMORY_MAPPER_LO_OS7_24K_RAM 0b11 ; ooh

#define MEMORY_MAPPER_HI_32K_INTRAM 0b0000
#define MEMORY_MAPPER_HI_EXTROM 0b0100
#define MEMORY_MAPPER_HI_EXTRAM 0b1000
#define MEMORY_MAPPER_HI_CART   0b1100

entry:
    call MODE_1 ; "text mode"

    ld hl, $0000
    ld de, $4000
    ld a, $00
    call FILL_VRAM ; wipe out video ram

    ; fill in some colours
    ld hl, MODE1_PATTERN_COLOR_TABLE
    ld de, 32
    ld a, $f4
    call FILL_VRAM ; see if this does anything

    call LOAD_ASCII ; load ascii font into vram

    ; set text-mode foreground and background colours
    ld b, $07   ; tc bc fields
    ld c, $02   ; light green background (2) black text (0)
    call WRITE_REGISTER

    ; enable display
    ld bc, $01c0 ; no interrupts
    call WRITE_REGISTER
    
    ; write text
    ld a, VDP_PATTERN_NAMETABLE
    ld de, 0
    ld hl, TEST_NAME_COLECOVISION
    ld iy, 11
    call PUT_VRAM 

    ; write test names
    ld a, VDP_PATTERN_NAMETABLE
    ld de, 0
    ld hl, TEST_NAME_COLECOVISION
    ld iy, 15
    call PUT_VRAM 

    ld a, VDP_PATTERN_NAMETABLE
    ld de, 32
    ld hl, TEST_NAME_SUPER_CV
    ld iy, 13
    call PUT_VRAM 

    ld a, VDP_PATTERN_NAMETABLE
    ld de, 64
    ld hl, TEST_NAME_ADAM_LOWER
    ld iy, 14
    call PUT_VRAM 

    ld a, VDP_PATTERN_NAMETABLE
    ld de, 96
    ld hl, TEST_NAME_ADAM_UPPER
    ld iy, 14
    call PUT_VRAM 

    di
    ; DANGER: past this point, consider the stack and BIOS work area wrecked

cv_test_start:
    ; tell them the test is ongoing in case it freezes
    ld bc, 10
    ld de, MODE1_PATTERN_NAME_TABLE + 17
    ld hl, TEST_ONGOING
    call WRITE_VRAM
    
    ; right now we are in the "cartridge" memory map,
    ; where we still delude ourselves into thinking
    ; we are a mere colecovision:
    ;   0000 - 2000: OS 7
    ;   2001 - 6fff: not for us to use
    ;   7000 - 73ff: colecovision 1k ram
    ;   8000 - ffff: cartridge rom
    ; we'll do a basic memory test to check if the colecovision ram
    ; is okay
    ld de, $7000
    ld bc, $3ff
    ld hl, after_call_cv
before_call_cv:
    jp basic_memory_test
after_call_cv:
    cp a, $1
    jr z, cv_test_failed
    ei
cv_test_passed:
    ; write text
    ld bc, 11
    ld de, MODE1_PATTERN_NAME_TABLE + 17
    ld hl, TEST_PASSED
    call WRITE_VRAM

    ; off to the next test

super_cv_test_start:
    ; switch to "super CV" mode (OS7 bios + 24k of ram, holy cow)
    ld a, MEMORY_MAPPER_LO_OS7_24K_RAM | MEMORY_MAPPER_HI_CART
    out (ADAM_MEMORY_MAPPER_PORT), a
    ; a whole new world awaits.

    ; "This option contains OS 7 and
    ; 24K of ADAM's intrinsic RAM. OS 7 is the 8K ROM installed in
    ; ColecoVision and ADAM. In Expansion Module #3, this ROM is
    ; in the ColecoVision. The description of the 32K Intrinsic
    ; RAM also applies to this 24K intrinsic RAM."

    ; This is not to be confused with "Super Games," which have 56K of RAM
    ; by running almost exclusively from RAM and expose EOS at the top alongside OS7.

    ld bc, 10
    ld de, MODE1_PATTERN_NAME_TABLE + 17 + 32
    ld hl, TEST_ONGOING
    call WRITE_VRAM

    ld de, $2000
    ld bc, $5fff ; wow!!!
    ld hl, after_call_24k
before_call_24k:
    jp basic_memory_test
after_call_24k:
    cp a, $1
    jr z, test_failed_24k
    ei
test_passed_24k:
    ; write text
    ld bc, 11
    ld de, MODE1_PATTERN_NAME_TABLE + 17 + 32
    ld hl, TEST_PASSED
    call WRITE_VRAM

adam_lower_test_start:
    ; switch to "Adam lower 32K RAM" mode
    ; this option, obviously, keeps us from being able to access
    ; the OS7 BIOS, so we're going to have to switch back to write
    ; our own text after this
    ld bc, 10
    ld de, MODE1_PATTERN_NAME_TABLE + 17 + 32 + 32
    ld hl, TEST_ONGOING
    call WRITE_VRAM

    ; TODO: It would be cool to test expansion RAM but I don't have any.
    ld a, MEMORY_MAPPER_LO_32K_INTRAM | MEMORY_MAPPER_HI_CART
    out (ADAM_MEMORY_MAPPER_PORT), a

    ld de, $0000
    ld bc, $7fff ; wow!!!
    ld hl, after_call_adam_low
before_call_adam_low:
    jp basic_memory_test
after_call_adam_low:
    cp a, $1
    jr z, test_failed_adam_low
    ei
test_passed_adam_low:
    ; get back to OS7
    ld a, MEMORY_MAPPER_LO_OS7_24K_RAM | MEMORY_MAPPER_HI_CART
    out (ADAM_MEMORY_MAPPER_PORT), a
    
    ; write text
    ld bc, 11
    ld de, MODE1_PATTERN_NAME_TABLE + 17 + 32 + 32
    ld hl, TEST_PASSED
    call WRITE_VRAM

    ; TODO: Figure out why AdamLow is instantly failing (looks like ROM is not getting demapped?)

    ; TODO: ADAM high means we need to copy a kernel into RAM somewhere
    ; and somehow not obliterate it, but luckily we just tested low to
    ; make sure it works reliably?

spin:
    jr spin
    ; TODO: Count up how much RAM we actually have in each mode

cv_test_failed:
    ; write text (smashed work area)
    ld bc, 11
    ld de, MODE1_PATTERN_NAME_TABLE + 17
    ld hl, TEST_FAILED
    call WRITE_VRAM

    jr spin

test_failed_24k:
    ; write text (smashed work area)
    ld bc, 11
    ld de, MODE1_PATTERN_NAME_TABLE + 17 + 32
    ld hl, TEST_FAILED
    call WRITE_VRAM

    jr spin

test_failed_adam_low:
    ; write text (we have to get back to OS7 first)
    ld a, MEMORY_MAPPER_LO_OS7_24K_RAM | MEMORY_MAPPER_HI_CART
    out (ADAM_MEMORY_MAPPER_PORT), a

    ; TODO: Rescue and print DE as the failure location?

    ld bc, 11
    ld de, MODE1_PATTERN_NAME_TABLE + 17 + 32 + 32
    ld hl, TEST_FAILED
    call WRITE_VRAM

    jr spin

HELLO_WORLD: .text "HELLO WORLD"
TEST_NAME_COLECOVISION: .text "COLECOVISION 1K"
TEST_NAME_ADAM_LOWER: .text "ADAM 32K LOWER"
TEST_NAME_ADAM_UPPER: .text "ADAM 32K UPPER"
TEST_NAME_SUPER_CV: .text "OS7+24K LOWER"
TEST_FAILED: .text "TEST FAILED"
TEST_PASSED: .text "TEST PASSED"
TEST_ONGOING: .text "TESTING..."

basic_memory_test:
    ; de - start of range
    ; bc - length of range
    ; hl - return address
    ; returns A - zero if success, one if failed
    ; TODO: Spinner
_basic_memory_test_loop:
    ld a, $cc ; TODO: Use more than this
    ld (de), a
    ld a, (de)
    cp a, $cc
    jr nz, _basic_memory_test_failed

    ld a, $55
    ld (de), a
    ld a, (de)
    cp a, $55
    jr nz, _basic_memory_test_failed

    inc de
    dec bc
    ld a, b
    or c
    jp nz, _basic_memory_test_loop
_basic_memory_test_end:
    ld a, 0
    jp (hl) ; do not rely on the stack being here
_basic_memory_test_failed:
    ld a, 1 ; failure
    jp (hl)

; TODO: hex print routine of some kind for writing fail locations
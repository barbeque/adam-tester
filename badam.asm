.org $8000

; standard colecovision header
HEADER_GAME: .db $aa, $55
; HEADER_TEST: .db $55 $aa

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

entry:
    jp entry

    ; TODO: Figure out how to print text
    ; TODO: Switch memory map into the various ADAM modes and do a RAM test
    ; TODO: Basic read/write
    ; TODO: Count up how much RAM we actually have in each mode
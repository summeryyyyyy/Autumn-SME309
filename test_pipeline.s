    AREA    MYCODE, CODE, READONLY, ALIGN=9
        ENTRY

; ------- <code memory (ROM mapped to Instruction Memory) begins>

    ; --- (1) RAW Hazard: Data written then read by dependent instruction ---
    LDR   R1, constant1           ; R1 = 5
    LDR   R2, constant2           ; R2 = 6
    ADD   R3, R1, R2              ; R3 = 5 + 6 = 11
    SUB   R4, R3, R1              ; R4 = 11 - 5 = 6

    ; --- (2) Memory-to-Memory Copy: Copy value V=3 from one place in memory to another ---
    LDR   R5, addr_src            ; R5 = 0x810
    LDR   R6, addr_dst            ; R6 = 0x820
    LDR   R7, [R5]                ; R7 = MEM[0x810] = 3   ; V=3
    STR   R7, [R6]                ; MEM[0x820] = 3        ; V=3 copied

    ; --- (3) Load-and-Use Hazard: Use a value immediately after loading ---
    LDR   R8, [R6]                ; R8 = MEM[0x820] = 3   ; V=3
    ADD   R9, R8, R2              ; R9 = 3 + 6 = 9

    ; --- (4) Control Hazard: Branch flushes branch-delay (filler) instructions ---
    B     skip                    ; Branch to 'skip'; next two are flushed
nop1: ADD   R10, R1, R2           ; (flushed) would be R10=5+6=11 if executed
nop2: SUB   R11, R2, R1           ; (flushed) would be R11=6-5=1 if executed
skip: MOV   R12, R4               ; R12 = 6 (from above)

    ; --- (5) No data dependency: Pipeline should run freely ---
    ADD   R1, R2, R3              ; R1 = 6 + 11 = 17
    SUB   R5, R6, R7              ; R5 = 0x820 - 3 = 0x81D

    ; --- (6) Multi-cycle data dependency: Stalls for MUL result ---
    MUL   R13, R2, R3             ; R13 = 6 * 11 = 66
    ADD   R14, R13, R2            ; R14 = 66 + 6 = 72

halt
    B     halt

; ------- <code memory (ROM mapped to DATA Memory) begins>
    AREA    CONSTANTS, DATA, READONLY, ALIGN=9

addr_src      DCD 0x00000810           ; address for source MEM[0x810]
addr_dst      DCD 0x00000820           ; address for destination MEM[0x820]

constant1     DCD 0x00000005           ; value 5
constant2     DCD 0x00000006           ; value 6

    AREA    DATA_V, DATA, READWRITE, ALIGN=9

; Initialize source memory with V = 3
    ORG     0x00000810 - .
val_V_src   DCD 0x00000003             ; MEM[0x810] = 3

    END

    AREA    MYCODE, CODE, READONLY, ALIGN=9
    ENTRY

; ------- <code memory (ROM mapped to Instruction Memory) begins>
	LDR R2, constant1; R2=5
	LDR R3, constant2; R3=6
	LDR R0, addr1; 810
	LDR R6, addr2; 820
	LDR R7,addr3; 830
    ; (1) RAW Hazard
    ADD   R1, R2, R3        ; R1 = R2 + R3
    SUB   R4, R1, R5        ; R4 = R1 - R5    (RAW hazard: uses just-written R1)

    ; (2) Memory-to-Memory copy
    LDR   R1, [R0]          ; R1 = MEM[R0]
    STR   R1, [R6]          ; MEM[R6] = R1

    ; (3) Load-and-Use Hazard
    LDR   R5, [R7]          ; R5 = MEM[R7]
    ADD   R8, R5, R9        ; R8 = R5 + R9    (uses just-loaded R5)

    ; (4) Control Hazard: Branch and flush pipeline
    B     skip              ; Branch (skip next two instructions)
NOP1: ADD   R2, R3, R4      ; Filler: Should be flushed if branch works
NOP2: SUB   R5, R6, R7      ; Filler: Should be flushed
skip: MOV   R10, R11        ; Branch target

    ; (5) No data dependency -- pipeline flows freely
    ADD   R2, R3, R4
    SUB   R5, R6, R7

    ; (6) Multi-cycle dependency (stalls until MUL completes)
    MUL   R4, R5, R6        ; R4 = R5 * R6
    ADD   R8, R4, R7        ; R8 = R4 + R7, Must wait for MUL R4

halt
    B     halt

; ------- <code memory (ROM mapped to DATA Memory) begins>
    AREA    DATA, DATA, READWRITE, ALIGN=9

addr1      DCD 0x00000810   ; Example memory address for LDR/STR
addr2      DCD 0x00000820   ; Example memory address for STR
addr3      DCD 0x00000830   ; Example memory address for LDR
constant1   DCD 0x00000005   ; Sample data for R2/R3 etc.
constant2   DCD 0x00000006
constant3   DCD 0x00000007

    END

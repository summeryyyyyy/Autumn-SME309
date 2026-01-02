	.syntax unified
	.cpu cortex-m3
	.thumb
	.global _start

_start:
	// 1. RAW Hazard: SUB depends on ADD result (R1)
	ADD   R1, R2, R3      // R1 = R2 + R3
	SUB   R4, R1, R5      // R4 = R1 - R5    (RAW hazard)

	// 2. Memory-to-Memory Copy
	LDR   R1, [R0]        // R1 = MEM[R0]
	STR   R1, [R6]        // MEM[R6] = R1

	// 3. Load-Use Hazard
	LDR   R5, [R7]        // R5 = MEM[R7]
	ADD   R8, R5, R9      // R8 = R5 + R9    (Uses value just loaded - hazard)

	// 4. Control Hazard: Branch over two instructions
	B     skip
NOP1:   ADD   R2, R3, R4 // (will be skipped; filler for branch delay)
NOP2:   SUB   R5, R6, R7 // (will be skipped)
skip:	MOV   R10, R11    // Branch target

	// 5. No Data Dependency: Pipeline can proceed freely
	ADD   R2, R3, R4
	SUB   R5, R6, R7

	// 6. Multi-cycle Data Dependency: Dependent on MUL (should cause stall)
	MUL   R4, R5, R6      // R4 = R5 * R6
	ADD   R8, R4, R7      // R8 = R4 + R7 (must wait for R4 from MUL)

	// End (Optional: Infinite Loop)
done:   B done           // Infinite loop
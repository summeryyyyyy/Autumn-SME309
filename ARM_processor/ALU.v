/* 
 * ALU MODULE: Arithmetic Logic Unit
 * Supports: ADD, SUB, AND, ORR
 * 
 * ALUControl Encoding:
 * 2'b00: ADD (Sum = A + B)
 * 2'b01: SUB (Sum = A - B)
 * 2'b10: AND (Result = A & B)
 * 2'b11: ORR (Result = A | B)
 */
module ALU(
    input [31:0] Src_A,          // Operand A
    input [31:0] Src_B,          // Operand B
    input [1:0] ALUControl,      // Control Signal (Selects operation)

    output [31:0] ALUResult,     // Calculation Result
    output [3:0] ALUFlags        // Status Flags: {Negative, Zero, Carry, Overflow}
    );

    // Internal signals
    wire [31:0] Src_B_Inv;       // Inverted B (used for subtraction)
    wire [31:0] Sum;             // Result of the Adder/Subtractor block
    wire Cout;                   // Carry Out from the Adder
    wire [31:0] A_and_B, A_or_B; // Logic operation results
    wire N, Z, C, V;             // Individual Flag bits

    // ================================================
    //               Arithmetic Logic
    // ================================================
    
    // 1. Prepare Operand B
    // If ALUControl[0] is 1 (SUB), we invert B to perform 2's complement subtraction.
    // Logic: A - B = A + (~B) + 1
    assign Src_B_Inv = ALUControl[0] ? ~Src_B : Src_B;

    // 2. Main Adder Block
    // Computes A + B_modified + Cin.
    // If ALUControl[0] is 1 (SUB), it adds 1 (Cin) to complete the 2's complement.
    assign {Cout, Sum} = Src_A + Src_B_Inv + ALUControl[0];

    // 3. Logic Operations
    assign A_and_B = Src_A & Src_B;
    assign A_or_B  = Src_A | Src_B;

    // 4. Result Selection MUX
    // ALUControl[1] == 0: Select Arithmetic (ADD/SUB)
    // ALUControl[1] == 1: Select Logic (AND/OR)
    //    Inside Logic: ALUControl[0] selects OR (1) vs AND (0)
    assign ALUResult = ALUControl[1] ? (ALUControl[0] ? A_or_B : A_and_B) : Sum;

    // ================================================
    //               ALUFlags Generation
    // ================================================
    
    // N (Negative): Set if the result is negative (MSB is 1).
    assign N = ALUResult[31];

    // Z (Zero): Set if the result is exactly 0.
    assign Z = (ALUResult == 32'b0);

    // C (Carry): 
    // For Arithmetic (ADD/SUB): Set to the adder's Carry Out.
    // For Logic (AND/OR): Carry is usually irrelevant/cleared (masked by ~ALUControl[1]).
    // Note: In ARM, SUB produces C=1 for "No Borrow" (Result >= 0) and C=0 for "Borrow".
    // This implementation correctly produces that behavior via the Adder logic.
    assign C = Cout & ~ALUControl[1];

    // V (Overflow):
    // Checks if the result sign is wrong given the operand signs (Signed Arithmetic).
    // Formula Breakdown:
    // 1. ~(Src_A[31] ^ Src_B[31] ^ ALUControl[0]): 
    //      - ADD (Op=0): True if A and B have the SAME sign.
    //      - SUB (Op=1): True if A and B have DIFFERENT signs (meaning A and -B have SAME sign).
    // 2. (Src_A[31] ^ Sum[31]): True if Result sign differs from A's sign.
    // 3. ~ALUControl[1]: Ensures V is never set for Logic instructions (AND/OR).
    assign V = ~(Src_A[31] ^ Src_B[31] ^ ALUControl[0]) & (Src_A[31] ^ Sum[31]) & ~ALUControl[1]; 

    // Concatenate flags into output vector
    assign ALUFlags = {N, Z, C, V};

endmodule
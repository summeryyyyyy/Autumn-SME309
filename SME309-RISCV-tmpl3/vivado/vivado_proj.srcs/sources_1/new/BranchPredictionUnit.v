module BranchPredictionUnit(
    input clk,
    input rst,
    input [31:0] if_pc,             // Current PC in IF stage

    // Prediction output
    output reg pred_taken,          // 1: Predict Taken, 0: Predict Not Taken
    output reg [31:0] pred_target,  // Predicted Target Address

    // Update Interface from EX stage
    input update_en,                // Enable update (e.g. on branch instruction in EX)
    input [31:0] update_pc,         // PC of the branch instruction in EX
    input [31:0] update_target,     // Calculated target address in EX
    input actual_taken              // Whether the branch was actually taken
);

    // Direct Mapped BTB
    // Size: 64 entries
    // Index: PC[7:2] (assuming 4-byte aligned instructions)
    parameter TABLE_SIZE = 64;
    parameter INDEX_WIDTH = 6;      // log2(64)
    parameter TAG_WIDTH = 32 - INDEX_WIDTH - 2; // Remaining bits

    reg [TAG_WIDTH-1:0] tag_table [0:TABLE_SIZE-1];
    reg [31:0] target_table [0:TABLE_SIZE-1];
    reg valid_table [0:TABLE_SIZE-1];
    
    // Simple 1-bit predictor table (or just use valid bit for "always taken if hit")
    // For this implementation, we'll use a valid bit + "Always Taken on Hit" policy first
    // because it's simplest and effective for loops.
    // Enhanced: Use 2-bit saturating counter for better prediction? 
    // Let's stick to simple Valid + Tag match = Predict Taken (like a cache of taken branches).
    // If it's in the BTB, we predict it jumps to the stored target.

    wire [INDEX_WIDTH-1:0] if_index = if_pc[INDEX_WIDTH+1 : 2];
    wire [TAG_WIDTH-1:0] if_tag = if_pc[31 : INDEX_WIDTH+2];
    
    wire [INDEX_WIDTH-1:0] update_index = update_pc[INDEX_WIDTH+1 : 2];
    wire [TAG_WIDTH-1:0] update_tag = update_pc[31 : INDEX_WIDTH+2];

    integer i;
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            for(i=0; i<TABLE_SIZE; i=i+1) begin
                valid_table[i] <= 1'b0;
                tag_table[i] <= 0;
                target_table[i] <= 0;
            end
        end else if(update_en) begin
            if(actual_taken) begin
                // Update or Insert: Store the target when branch is taken
                valid_table[update_index] <= 1'b1;
                tag_table[update_index] <= update_tag;
                target_table[update_index] <= update_target;
            end else if(valid_table[update_index] && tag_table[update_index] == update_tag) begin
                // If we predicted taken (hit) but actually not taken, we should remove validity/update predictor
                // For simple "cache of taken branches", we can invalidate it.
                valid_table[update_index] <= 1'b0;
            end
        end
    end

    always @(*) begin
        // Check if current PC matches an entry
        if(valid_table[if_index] && tag_table[if_index] == if_tag) begin
            pred_taken = 1'b1;
            pred_target = target_table[if_index];
        end else begin
            pred_taken = 1'b0;
            pred_target = if_pc + 4; // Default not taken
        end
    end

endmodule

module if_id(
    input clk, rst, pause, flush,
    input [31: 0] if_pc,
    input [31: 0] if_instr,

    // Prediction
    input if_pred_taken,
    output reg id_pred_taken,

    output reg [31: 0] id_pc,
    output reg [31: 0] id_instr
);

always @(posedge clk) begin
    if(rst || flush) begin
        id_pc = 32'd0;
        id_instr = {12'h0, 5'b0, 3'b000, 5'b0, 7'b0010011};
        id_pred_taken = 1'b0;
    end else if(pause) begin
        //
    end else begin
        id_pc <= if_pc;
        id_instr <= if_instr;
        id_pred_taken <= if_pred_taken;
    end
end

endmodule

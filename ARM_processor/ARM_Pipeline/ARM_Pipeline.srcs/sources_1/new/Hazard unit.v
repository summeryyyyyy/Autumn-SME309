module HazardUnit(
    input [3:0] RA1D,
    input [3:0] RA2D,
    
    input [3:0] RA1E,
    input [3:0] RA2E,
    input [3:0] WA3E,
    input MemtoRegE,
    input RegWriteE,
    
    input PCSrcD, PCSrcE, // EARLY BTA
    
    
    input M_BusyE,
    input [3:0] WA3M,
    input RegWriteM,
    input [3:0] RA2M,
    input MemWriteM,
    input [3:0] WA3W,
    input MemtoRegW,
    input RegWriteW,

    output StallF,
    output StallD,
    output FlushD,
    output StallE,
    output FlushE,
    output reg [1:0] ForwardAE,
    output reg [1:0] ForwardBE,
    output FlushM,
    output ForwardM
    );
    
    /* ========================================================== */
    /*                    FORWARDING LOGIC                        */
    /* ========================================================== */

    // 1. ALU Forwarding (EX Hazard & MEM Hazard)
    // Data forwarding for DP
    wire Match_1E_M, Match_2E_M, Match_1E_W, Match_2E_W;
    assign Match_1E_M = (RA1E == WA3M);
    assign Match_2E_M = (RA2E == WA3M);
    assign Match_1E_W = (RA1E == WA3W);
    assign Match_2E_W = (RA2E == WA3W);
    
    always @(*) begin
        if (Match_1E_M && RegWriteM) begin
            ForwardAE = 2'b10;
        end
        else if (Match_1E_W && RegWriteW) begin
            ForwardAE = 2'b01;
        end
        else begin
            ForwardAE = 2'b00;
        end
    end
    always @(*) begin
        if (Match_2E_M && RegWriteM) begin
            ForwardBE = 2'b10;
        end
        else if (Match_2E_W && RegWriteW) begin
            ForwardBE = 2'b01;
        end
        else begin
            ForwardBE = 2'b00;
        end
    end

    // 2. Memory-to-Memory Forwarding (For STR instructions)
    assign ForwardM = (RA2M == WA3W) & MemWriteM & MemtoRegW & RegWriteM;

    /* ========================================================== */
    /*                   STALL & FLUSH LOGIC                      */
    /* ========================================================== */

    // 1. Load-Use Hazard Detection
    wire Match_12D_E;
    assign Match_12D_E = (RA1D == WA3E) | (RA2D == WA3E); 
    wire Ldrstall;
    assign Ldrstall = Match_12D_E & MemtoRegE & RegWriteE;
    
    // Stalling for MCycle
    wire MCycleStall;
    assign MCycleStall = M_BusyE;

    assign StallF = Ldrstall || MCycleStall;
    assign StallD = Ldrstall || MCycleStall;
    assign StallE = MCycleStall;
    // 1. Flush Fetch (IF/ID) if:
        //    a. Branch Taken in Decode (Early BTA)
        //    b. Branch Taken in Execute (Late BTA for Conditional)
    assign FlushD = PCSrcD || PCSrcE;    
    assign FlushE = Ldrstall || PCSrcE;
    assign FlushM = MCycleStall;

    /* END: STALL_FLUSH SIGNAL */


endmodule
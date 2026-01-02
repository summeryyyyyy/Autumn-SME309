`timescale 1ns / 1ps

module tb_ARM();

    // Inputs to Wrapper
    reg CLK;
    reg RESET;
    reg [6:0] DIP; // Used to select data to display on LEDs

    // Outputs from Wrapper
    wire [15:0] LED;
    wire [31:0] SEVENSEGHEX;

    // Instantiate the Wrapper (which contains the ARM, Memories, and IO)
    Wrapper uut (
        .DIP(DIP), 
        .LED(LED), 
        .SEVENSEGHEX(SEVENSEGHEX), 
        .RESET(RESET), 
        .CLK(CLK)
    );

    // Clock Generation (10ns period = 100MHz)
    initial begin
        CLK = 0;
        forever #5 CLK = ~CLK;
    end

    // Test Sequence
    initial begin
        // 1. Initialize
        RESET = 1;
        DIP = 7'b0000000; // Display address 0 on 7-seg/LEDs
        
        // 2. Hold Reset for a few cycles
        #20;
        RESET = 0; // Release Reset -> Processor Starts!

        // 3. Run Simulation
        // Let it run long enough to execute your program
        #5000; 
        
        $stop;
    end

endmodule
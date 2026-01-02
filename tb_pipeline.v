`timescale 1ns / 1ps

module tb_ARM();

    reg CLK = 0;
    reg RESET = 1;
    reg [6:0] DIP = 0; // Change as necessary for memory test

    wire [15:0] LED;
    wire [31:0] SEVENSEGHEX;

    // Instantiate top module; adjust according to your hierarchy
    Wrapper uut (
        .DIP(DIP),
        .LED(LED),
        .SEVENSEGHEX(SEVENSEGHEX),
        .RESET(RESET),
        .CLK(CLK)
    );

    // Clock generator
    always #5 CLK = ~CLK; // 100MHz clock, 10ns period

    initial begin
        // Dump VCD waveform for viewing in GTKWAVE or similar
        $dumpfile("tb_ARM.vcd");
        $dumpvars(0, tb_ARM);

        // Apply reset
        RESET = 1;
        #20;
        RESET = 0;

        // Run the simulation for sufficient cycles
        #2000; // Change as needed
        $finish;
    end

endmodule
`include "CPU_define.v"
module CPU (
    input         clk,
    input         rst_n,
    input         run,

    // Interface to IROM
    output [31:0]  pc,
    input  [31:0]  instruction,

    // Interface to DRAM & MMIO
    output [31:0]  perip_addr,
    output [31:0]  perip_wdata,
    output         perip_wen,
    output [1:0]   perip_mask,
    input  [31:0]  perip_rdata
);

// TODO - remove following codes, replace by yours
assign pc = 32'b0;
assign perip_addr = 32'b0;
assign perip_wdata = 32'b0;
assign perip_wen = 1'b0;
assign perip_mask = 2'b0;

endmodule
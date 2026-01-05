/*
 * DIRECT MAPPED DATA CACHE: 4 Lines, Each 32-bit wide
 * Cache Line: {valid, tag[5:0], data[31:0]}
 */
module DCache(
    input        CLK,
    input        RESET,
    input [31:0] addr,
    input [31:0] wdata,
    input        write_en, // high to write
    input        read_en,  // high to read
    output reg [31:0] rdata,
    output reg        hit,
    output reg        busy, // signal to stall pipeline on miss
    output reg        miss,
    // memory interface
    output reg        mem_req,
    output reg [31:0] mem_addr,
    input             mem_ack,
    input [31:0]      mem_rdata,
    output reg        mem_write,
    output reg [31:0] mem_wdata
);

    localparam LINES = 4;
    localparam TAG_BITS = 6;
    wire [1:0] idx = addr[5:4];         // Index: 2 bits for 4 lines
    wire [TAG_BITS-1:0] addr_tag = addr[11:6]; // Tag: bits 11~6
    integer i;

    reg                  valid[0:LINES-1];
    reg [TAG_BITS-1:0]   tag[0:LINES-1];
    reg [31:0]           data[0:LINES-1];

    // Lookup
    always @(*) begin
        hit  = valid[idx] && (tag[idx] == addr_tag);
        miss = ~hit && (read_en || write_en);
        busy = miss && ~mem_ack;
        rdata = hit ? data[idx] : 32'b0;
    end

    // Memory request/output
    always @(*) begin
        mem_req   = miss;
        mem_addr  = addr;
        mem_write = miss && write_en;
        mem_wdata = wdata;
    end

    always @(posedge CLK or posedge RESET) begin
        if (RESET) begin
            for(i=0;i<LINES;i=i+1) begin
                valid[i] <= 0; tag[i] <= 0; data[i] <= 0;
            end
        end else if (hit) begin
            // hit: read or write
            if (write_en) begin
                data[idx] <= wdata; // Update cache line
            end
        end else if (miss && mem_ack) begin
            // Miss: refill from memory, optional write
            valid[idx] <= 1;
            tag[idx]   <= addr_tag;
            data[idx]  <= mem_rdata;
            if (write_en) data[idx] <= wdata; // write-after-fetch
        end
    end
endmodule
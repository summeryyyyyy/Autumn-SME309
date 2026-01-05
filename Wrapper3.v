`timescale 1ns / 1ps

module Wrapper
#(
	parameter N_LEDs = 16,       
	parameter N_DIPs = 7        
)
(
	input  [N_DIPs-1:0] DIP, 		 	
	output reg [N_LEDs-1:0] LED, 	
	output reg [31:0] SEVENSEGHEX, 		
	input  RESET,						
	input  CLK							
);                                             

//-------- ARM signals -----------
wire [31:0] PC, Instr, ALUResult, WriteData;
reg  [31:0] ReadData;
wire MemWrite;

//-------- Cache signals ----------
wire cache_hit, cache_busy, cache_miss;
wire [31:0] cache_rdata;
wire cache_mem_req, cache_mem_write;
wire [31:0] cache_mem_addr, cache_mem_wdata;
wire        cache_mem_ack;
wire [31:0] cache_mem_rdata;

//-------- 内存声明 -------------
reg [31:0] INSTR_MEM    [0:127]; // instruction memory
reg [31:0] DATA_CONST_MEM [0:127]; // const data memory
reg [31:0] DATA_VAR_MEM   [0:127]; // variable data memory
integer i;

//-------- 指令memory初始化 ----------
initial begin
    for(i = 0; i < 128; i = i+1) INSTR_MEM[i] = 32'h0;

        // --- (1) RAW Hazard ---
        INSTR_MEM[0] = 32'hE59F1000; // LDR R1, [PC] -> 5
        INSTR_MEM[1] = 32'hE59F2004; // LDR R2, [PC+4] -> 6
        INSTR_MEM[2] = 32'hE0813002; // ADD R3, R1, R2 -> 11
        INSTR_MEM[3] = 32'hE0434001; // SUB R4, R3, R1 -> 6
    
        // --- (2) Memory-to-Memory Copy ---
        INSTR_MEM[4] = 32'hE59F5008; // LDR R5...
        INSTR_MEM[5] = 32'hE59F600C; // LDR R6...
        INSTR_MEM[6] = 32'hE5957000; // LDR R7, [R5] -> 3
        INSTR_MEM[7] = 32'hE5867000; // STR R7, [R6]
    
        // --- (3) Load-and-Use Hazard ---
        INSTR_MEM[8] = 32'hE5968000; // LDR R8, [R6] -> 3
        INSTR_MEM[9] = 32'hE0889002; // ADD R9, R8, R2 -> 9
    
        // --- (4) Control Hazard (Early BTA) ---
        // Offset 1 Corrected
        INSTR_MEM[10] = 32'hEA000001; // B skip
        INSTR_MEM[11] = 32'hE081A002; // nop1 (Flushed)
        INSTR_MEM[12] = 32'hE042B001; // skipped
        // --- (5) No Dependency ---
        INSTR_MEM[13] = 32'hE1A0C004; // MOV R12, R4 -> 6
        
        INSTR_MEM[14] = 32'hE0821003; // ADD R1, R2, R3 -> 17 (0x11)
        
        INSTR_MEM[15] = 32'hE0465007; // SUB R5, R6, R7 -> 0x81D
        
        
    
        // --- (6) Multi-Cycle ---
        INSTR_MEM[16] = 32'hE00D0392; // MUL R13, R2, R3 -> 66 (0x42)
        
        INSTR_MEM[17] = 32'hE3A000AA;   // MOV   R0, #0xAA       R0 => 0xAA (170)
        
        // FIX 2: Corrected Hex for ADD R14, R13, R2
        INSTR_MEM[18] = 32'hE08DE002; // ADD R14, R13, R2 -> 72 (0x48)
    INSTR_MEM[19] = 32'hE580E800; // STR R14, [R0, #0x800]
        // Halt
        INSTR_MEM[20] = 32'hEAFFFFFE; 

// ... 你的指令初始化内容，省略 ...
end

//-------- 数据memory初始化 ----------
initial begin
    for(i = 0; i < 128; i = i+1) DATA_CONST_MEM[i] = 32'h0;
       // val1 (5) at Address 8 (Index 2)
        DATA_CONST_MEM[2] = 32'h00000005; 
    
        // val2 (6) at Address 16 (Index 4)
        DATA_CONST_MEM[4] = 32'h00000006; 
    
        // addr_src (0x810) at Address 32 (Index 8)
        DATA_CONST_MEM[8] = 32'h00000810; 
    
        // addr_dst (0x820) at Address 40 (Index 10)
        DATA_CONST_MEM[10] = 32'h00000820; 
end

initial begin
    for(i = 0; i < 128; i = i+1) DATA_VAR_MEM[i] = 32'h0;
   //    // Value 3 at Address 0x810 (Index 4)
        DATA_VAR_MEM[4] = 32'h00000003; // ... 初始化DATA_VAR_MEM，省略 ...
end

//-------- ARM实例（数据接口用ReadData/cache_busy） ------
ARM ARM1(
    .CLK(CLK),
    .Reset(RESET),
    .Instr(Instr),
    .ReadData(ReadData),
    .MemWrite(MemWrite),
    .PC(PC),
    .OpResult(ALUResult),
    .WriteData(WriteData),
    .cache_busy(cache_busy) // 新增接口（流水线暂停，见ARM3代码）
);

//-------- DCache实例 ---------
DCache dcache_inst(
    .CLK(CLK),
    .RESET(RESET),
    .addr(ALUResult),
    .wdata(WriteData),
    .write_en(MemWrite && (ALUResult >= 32'h00000200 && ALUResult <= 32'h000009FC)), //数据区
    .read_en((ALUResult >= 32'h00000200 && ALUResult <= 32'h000009FC)),
    .rdata(cache_rdata),
    .hit(cache_hit),
    .busy(cache_busy),
    .miss(cache_miss),
    .mem_req(cache_mem_req),
    .mem_addr(cache_mem_addr),
    .mem_ack(cache_mem_ack),
    .mem_rdata(cache_mem_rdata),
    .mem_write(cache_mem_write),
    .mem_wdata(cache_mem_wdata)
);

//-------- Cache与主存交互 --------
// 主存控制信号: 总是假设1周期响应
assign cache_mem_ack   = cache_mem_req ? 1'b1 : 1'b0;
assign cache_mem_rdata = DATA_VAR_MEM[cache_mem_addr[8:2]];
always @(posedge CLK) begin
    // Write-through: cache同时写主存
    if(cache_mem_req && cache_mem_write)
        DATA_VAR_MEM[cache_mem_addr[8:2]] <= cache_mem_wdata;
end

//-------- 数据读选择（变量区优先cache，常量区原始） --------
always @(*) begin
    if (ALUResult >= 32'h00000200 && ALUResult <= 32'h000009FC)
        ReadData = cache_rdata; //从cache读
    else if (ALUResult < 32'h00000200)
        ReadData = DATA_CONST_MEM[ALUResult[8:2]] ;
    else
        ReadData = 32'h0;
end

//------ 指令读取 --------
assign Instr = ((PC >= 32'h00000000) && (PC <= 32'h000001FC)) ? INSTR_MEM[PC[8:2]] : 32'h00000000 ; 

//----- LED显示等原有代码保持 -----
reg [31:0] LED_reg1, LED_reg2, LED_reg3;
always@(posedge CLK or posedge RESET) begin
    if(RESET) begin
        LED_reg1 <= 32'b0; LED_reg2 <= 32'b0; LED_reg3 <= 32'b0; LED <= 32'b0;
    end
    else begin
        LED_reg1 <= PC; LED_reg2 <= LED_reg1; LED_reg3 <= LED_reg2; LED <= LED_reg3;
    end
end

always @(posedge CLK or posedge RESET) begin
    if (RESET)
        SEVENSEGHEX <= 32'b0;
    else
        SEVENSEGHEX <= DATA_VAR_MEM[DIP[6:0]];
end
endmodule

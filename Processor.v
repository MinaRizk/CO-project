module CPU (clk) ;
input clk;

wire [31:0] Ain, Bin; //Input to the main ALU 
reg[31:0] PC; //Memory
wire[31:0] readDataMemory ; // output of dataMemory
wire [31:0] proceedingPC ; //  =pc+4
wire[31:0] nextPC ; // output of third mux chooses between proceedingPC(PC+4) and branch address
//reg[31:0] nextPCReg;
wire[31:0] nextPC_branch; // this is is the new address of pc if the instruction is beq 
wire signed [31:0] ALUResult;
wire signed [31:0]writeData;
wire [4:0] writeRegister; // the address of the registers to write output of the mux
wire [1:0] aluOP;

wire regWrite,regDst,aluSrc,memWrite,memToReg,memRead,branch,zeroDetection,selectorOfBranchMux;  

wire [3:0]operation;//input to mainAlu and output from Alucontrol

wire [4:0] rs, rt,rd,shamt ; // Access Instruction fields fields 
wire [5:0]funct,opCode;	     // Access Instruction fields fields 
wire [15:0]immediate_address;// Access Instruction fields fields 
wire [31:0]readData2;     // output of fileregister and input to the second mux
wire[31:0] instruction; // output of Instrection memory
wire[31:0]extended_immediate; // output of signExtension 
wire[31:0]extended_shiftedBy2; // output of signExtender after being shifted by 2 , used in beq

InstMem  IMemory(PC,clk,instruction);

Mux_5bits firstMux( rt , rd , regDst , writeRegister);  // mux before registerFile
	
RegisterFile registerFile(rs,rt,writeRegister,writeData,regWrite,clk,Ain,readData2);

SignExtender signExtend(immediate_address ,extended_immediate);

controlUnit mainControlUnit(opCode,regDst,branch,memRead,memToReg,aluOp,memWrite,aluSrc,regWrite);//control unit

Mux_32bits secondMux(readData2,extended_immediate,aluSrc,Bin);	 // mux before ALU

ALUControl aluControlUnit(operation, aluOp, funct);// alu control unit

OurALU mainAlu(ALUResult,xxxxx,Ain,Bin,operation,shamt); // main alu


Mux_32bits thirdMux(proceedingPC,nextPC_branch,selectorOfBranchMux,nextPC);	 // mux before ALU

DataMem DMemory( ALUResult ,readData2 ,memRead , memWrite  ,clk , readDataMemory ); //Data Memory

Mux_32bits fourthMux(ALUResult,readDataMemory , memToReg, writeData);// mux before WriteData in reg

// These assignments defines fields from the instruction
assign selectorOfBranchMux = branch & zeroDetection;
assign opCode = instruction [31:26];
assign rs = instruction[25:21];
assign rt = instruction [20:16];
assign rd = instruction [15:11];
assign shamt = instruction[10:6];	
assign funct = instruction[5:0];
assign immediate_address = instruction[15:0];	
assign extended_shiftedBy2 = (extended_immediate<<2);
assign proceedingPC = PC+4 ;
assign nextPC_branch = proceedingPC + extended_shiftedBy2;
assign zeroDetection = ((Ain-Bin)==0)?1:0; 
initial
begin
PC = 0;
//nextPCReg=0;
$monitor($time,,"PC = %d , instruction=%h, ,rs=%d,rt=%d,Bin = %d Ain = %d,AluResult = %d ",
PC,instruction,rs,rt,Bin,Ain,ALUResult);

end

always @(posedge clk)
begin

PC =nextPC;



end


endmodule

module cpuTestBench();

wire clk ;
 ClkGen c(clk);
 CPU a(clk) ;

endmodule
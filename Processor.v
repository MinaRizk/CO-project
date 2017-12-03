module CPU (clk) ;

input clk;

//1.declartions of each
//2.inst. of each
//3.blocking of each
//4.intial and its paremeter 
//5.non blocking of each





























////////////////////////////////////////////////////////////////////////////////////////// declartion of all////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////// stage 1/////////////////////////////////////////////////////


reg  [31:0] PC; //Memory
wire [31:0] proceedingPC ; //  =pc+4
wire [31:0] nextPC ; // output of third mux chooses between proceedingPC(PC+4) and branch address
wire [31:0] instruction; // output of Instrection memory	  
wire stallSignal;//if 1 then stall 

/////////////////////////////////////////////////////////////////////////////////////////// between stage 1 and 2//////////////////////////////////////////////

reg  [31:0]   IF_ID_IR  , IF_ID_pc  ;//in from inst and procceding pc
wire[4:0]IF_ID_rs,IF_ID_rt;
wire[4:0]IF_ID_rd;
///////////////////////////////////////////////////////////////////////////////////////////stage 2//////////////////////////////////////////////////////

wire [1:0] aluOP;///////////control unit outputs
wire regWrite,regDst,aluSrc,memWrite,memToReg,memRead,branch;/////////control unit outputs


wire  [5:0]opCode;// Access Instruction fields fields/
wire  [4:0] rs, rt ;

wire  [31:0] Ain;
wire  [31:0]readData2; // output of fileregister and input to through the pipeline the second mux
wire  [31:0]extended_immediate; // output of signExtension
wire  [15:0]immediate_address;// Access Instruction fields fields

/////////////////////////////////////////////////////////////////////////////////////// between stage 2 and 3//////////////////////////////////////////////////

reg [31:0]   ID_EX_IR  , ID_EX_pc;//in from last pipeline reg


reg     ID_EX_regWrite,        ID_EX_regDst,       ID_EX_aluSrc, 
        ID_EX_branch ,///in from control unit outputs
        ID_EX_memWrite,        ID_EX_memToReg,     ID_EX_memRead       ;///////in from control unit outputs
reg [1:0] ID_EX_aluOP;/////////in from control unit outputs


reg [31:0]   ID_EX_A     ;
reg [31:0]   ID_EX_B     ;//in from the register file

reg [31:0]   ID_EX_extended_immediate;//in from sign extended

wire[4:0] ID_EX_rs;
wire[4:0] ID_EX_rt;

wire[4:0] ID_EX_rd;

////////////////////////////////////////////////////////////////////////////////////////////////for stage 3///////////////////////////////////////////////////

wire  [31:0] Bin; //Input to the main ALU
wire  [4:0] shamt ;
wire  [5:0]  funct ; // Access Instruction fields fields ////
wire  [3:0]operation;//input to mainAlu and output from Alucontrol
wire signed [31:0] ALUResult;


wire  [31:0] extended_shiftedBy2; // output of signExtender after being shifted by 2 , used in beq
wire  [31:0] nextPC_branch; // this  is the new address of pc if the instruction is beq
wire zeroDetection;
wire selectorOfBranchMux;  

wire [1:0]forwardSignalForRs; 
wire [1:0]forwardSignalForRt;
wire signed[31:0]aluFirstInput;	
wire signed[31:0]aluSecondInput;
//////////////////////////////////////////////////////////////////////////////////////////// between stage 3 and 4////////////////////////////////////////////


reg  [31:0]   EX_MEM_IR , EX_MEM_pc;
reg  [31:0]   EX_MEM_B ,  EX_MEM_ALUOut;

reg     EX_MEM_regWrite,        EX_MEM_regDst ,
        EX_MEM_memWrite,        EX_MEM_memToReg,     EX_MEM_memRead       ;

 wire[4:0] EX_MEM_rd;
/////////////////////////////////////////////////////////////////////////////////////////////for stage 4//////////////////////////////////////////////


wire [31:0] readDataMemory ; // output of dataMemory
wire[4:0]MEM_WB_rd;
//////////////////////////////////////////////////////////////////////////////////////////// between stage 4 and 5/////////////////////////////////////////////


reg[31:0]   MEM_WB_IR , MEM_WB_pc;

reg    MEM_WB_regWrite,        MEM_WB_regDst , MEM_WB_memToReg ;
 



reg[31:0] MEM_WB_ALUOut ,  MEM_WB_readDataMemory ;


////////////////////////////////////////////////////////////////////////////////////////////for stage 5////////////////////////////////////////////////

wire signed [31:0]writeData;
wire  [4:0] writeRegister; // the address of the registers to write output of the mux

wire  [4:0] MEM_WB_rt_IF_ID , MEM_WB_rd_IF_ID ; 



//////////////////////////////////////////////////////////////////////////////////////////////end of declartions/////////////////////////////////////////////////











///////////////////////////////////////////////////////////////////////////////////////inst.////////////////////////////////////////////////////////

// for stage 1

// also the adder of proceding pc is here

InstMem  IMemory(PC,clk,instruction);//in the fetch stage

//for stage 2

controlUnit mainControlUnit(opCode,stallSignal,regDst,branch,memRead,memToReg,aluOP,memWrite,aluSrc,regWrite);//control unit//id stage and have effects in other stages

Mux_5bits firstMux( MEM_WB_rt_IF_ID , MEM_WB_rd_IF_ID , MEM_WB_regDst , writeRegister);  // mux before registerFile // fetch stage 


RegisterFile registerFile(rs,rt,        writeRegister,writeData, MEM_WB_regWrite ,                  clk, Ain,readData2,clk);// id stage

SignExtender signExtend(immediate_address ,extended_immediate);// before alu under the register file done //in the id stage	  

stallingControl sc1(memRead,IF_ID_rt,instruction[25:21],instruction[20:16],stallSignal);

//for stage 3

// also the branch is here 

ForwardControl FC_rs(ID_EX_regWrite,EX_MEM_regWrite,EX_MEM_rd,MEM_WB_rd,ID_EX_rs,forwardSignalForRs);//compare with rs	
ForwardControl FC_rt(EX_MEM_regWrite,MEM_WB_regWrite,EX_MEM_rd,MEM_WB_rd,ID_EX_rt,forwardSignalForRt);//compare with rt
Mux_32bits thirdMux( ID_EX_pc , nextPC_branch , selectorOfBranchMux , nextPC);	 // mux before pc

Mux_32bits secondMux( ID_EX_B , ID_EX_extended_immediate , ID_EX_aluSrc ,  Bin);	 // mux before ALU
Mux4To1_32bits rsDst(ID_EX_A,EX_MEM_ALUOut,MEM_WB_ALUOut,32'b0,forwardSignalForRs,aluFirstInput);//to decide the first alu destination
Mux4To1_32bits rtDst(Bin,EX_MEM_ALUOut,MEM_WB_ALUOut,32'b0,forwardSignalForRt,aluSecondInput);//to decide the second alu destination

OurALU mainAlu(ALUResult,xxxxx,aluFirstInput  ,      aluSecondInput      ,operation,shamt); // main alu


ALUControl aluControlUnit(operation, ID_EX_aluOP, funct);// alu control unit

//for stage 4

DataMem DMemory(         EX_MEM_ALUOut ,                EX_MEM_B ,          EX_MEM_memRead ,              EX_MEM_memWrite  ,clk , readDataMemory ); //Data Memory//mem

//for stage 5

Mux_32bits fourthMux(MEM_WB_ALUOut,MEM_WB_readDataMemory  , MEM_WB_memToReg ,  writeData);// mux before WriteData in reg//wb




/////////////////////////////////////////////////////////////////////////////////end of inst /////////////////////////////////////////////////////////////










 


parameter no_op = 32'b0000_0000_0000_0000_0000_0000_0000_0000; 

initial
begin

// for first inst only
PC = 0;

IF_ID_IR = no_op; ID_EX_IR = no_op; EX_MEM_IR = no_op; MEM_WB_IR = no_op; // put no-ops in pipeline registers 

$monitor($time,,"PC = %d , instruction=%h, ,rs=%d,rt=%d,Ain =%dBin = %d,AluResult = %d ,writeDataInMem=%d,writeDataInReg=%d", PC,instruction,rs,rt,aluFirstInput,aluSecondInput,ALUResult,EX_MEM_B,writeData);
//$monitor($time,,"PC = %d , instruction=%h, ,rs=%d,rt=%d,Ain =%dBin = %d,AluResult = %d , MEM_WB_regWrite =%d,writeDataInReg=%d", PC,instruction,rs,rt,aluFirstInput,aluSecondInput,ALUResult, MEM_WB_regWrite ,writeData);

end














////////////////////////////////////////////////////////////////////////////////non blocking assignments for each stage///////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////for stage 1/////////////////////////////////////////////////////////////////////
assign proceedingPC = PC+4 ;

/////////////////////////////////////////////////////////////////////////////// for stage 2/////////////////////////////////////////////////////////
assign opCode = IF_ID_IR [31:26];//to the control unit and from here we will take the signals of the control unit 
assign rs     = IF_ID_IR [25:21];//for regs
assign rt     = IF_ID_IR [20:16];//for regs	 
assign IF_ID_rs=IF_ID_IR [25:21];
assign IF_ID_rt=IF_ID_IR [20:16];
assign IF_ID_rd=IF_ID_IR [15:11];
assign immediate_address =IF_ID_IR  [15:0];// for sign extend
///////////////////////////////////////////////////////////////////////////////for stage 3//////////////////////////////////////////////////////////////

//alu
assign shamt = ID_EX_IR [10:6];
assign funct = ID_EX_IR [5:0];	   
assign ID_EX_rs=ID_EX_IR [25:21];
assign ID_EX_rt=ID_EX_IR [20:16];
assign ID_EX_rd=ID_EX_IR [15:11];
assign zeroDetection = ((ID_EX_A-Bin)==0)?1:0;

//branch
assign extended_shiftedBy2 = (ID_EX_extended_immediate<<2);//still need
assign nextPC_branch = ID_EX_pc + extended_shiftedBy2;
assign selectorOfBranchMux = ID_EX_branch & zeroDetection;





////////////////////////////////////////////////////////////////////////////////for stage 4///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////nothing/////////////////////////////////////////////////////////////////////

assign EX_MEM_rd = EX_MEM_IR[15:11];




//////////////////////////////////////////////////////////////////////////////for stage 5/////////////////////////////////////////////////////////////
assign MEM_WB_rt_IF_ID = MEM_WB_IR [20:16]; 
assign MEM_WB_rd_IF_ID = MEM_WB_IR [15:11];              

assign MEM_WB_rd=MEM_WB_IR[15:11];



////////////////////////////////////////////////////////////////////////////////end of blocking assignments /////////////////////////////////////////////








always @(posedge clk)

begin

/////////////////////////////////////////////////////////////////////////pipeline assignments all with parrellel blocking/////////////////////////////////////

//////////////////////////////////////////////////////////////////////////// for stage 1//////////////////////////////////////////////////////////////
//PC <=nextPC; 
if(stallSignal)
	
	PC <=PC;
	else
		PC <=proceedingPC;	


//$strobe($time,,"forwardSignalforRS=%b ",forwardSignalForRs); 
//$strobe($time,,"forwardSignalforRt=%b ",forwardSignalForRt);
///////////////////////////////////////////////////////////////// between stage 1 and 2 //////////////////////////////////////////////////////////
if(stallSignal)
	
	IF_ID_IR<=32'b0;
	else
		IF_ID_IR<=instruction;		  
//IF_ID_IR<=instruction;//from the inst memory
IF_ID_pc<=proceedingPC;

///////////////////////////////////////////////////////////////////////// for stage 2////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////nothing/////////////////////////////////////////////////////////////////////////////



///////////////////////////////////////////////////////////////// between stage 2 and 3////////////////////////////////////////////////////////////

ID_EX_IR  <= IF_ID_IR      ;
ID_EX_pc  <= IF_ID_pc      ;

ID_EX_regWrite<=  regWrite;       ID_EX_regDst  <=regDst;       //still need
ID_EX_memWrite<=  memWrite;       ID_EX_memToReg<=memToReg;      ID_EX_memRead<=memRead;//stillneed     
ID_EX_branch<=branch ;//die here
ID_EX_aluOP   <=aluOP; 
ID_EX_aluSrc <=aluSrc;//die here

ID_EX_A <=Ain; 
ID_EX_B <=readData2;
ID_EX_extended_immediate<=extended_immediate;


////////////////////////////////////////////////////////////// for stage 3////////////////////////////////////////////////////////////
////////////////////////////////////////nothing/////////////////////////////////////////////////





///////////////////////////////////////////////////////////////// between stage 3 and 4////////////////////////////////////////////////////////////
EX_MEM_IR <=ID_EX_IR;
EX_MEM_pc <=ID_EX_pc;



EX_MEM_regWrite<=  ID_EX_regWrite;      EX_MEM_regDst<= ID_EX_regDst  ;   EX_MEM_memToReg<=  ID_EX_memToReg;    //still need
EX_MEM_memWrite<=ID_EX_memWrite;          EX_MEM_memRead<= ID_EX_memRead;//die here

EX_MEM_B     <=ID_EX_B ;
EX_MEM_ALUOut<=ALUResult;


////////////////////////////////////////////////////////////// for stage 4////////////////////////////////////////////////////////////
////////////////////////////////////////nothing/////////////////////////////////////////////////



///////////////////////////////////////////////////////////////// between stage 4 and 5////////////////////////////////////////////////////////////

MEM_WB_IR<=EX_MEM_IR;
MEM_WB_pc<=EX_MEM_pc;

MEM_WB_regWrite<=EX_MEM_regWrite  ;      MEM_WB_regDst<=EX_MEM_regDst   ;   MEM_WB_memToReg<=EX_MEM_memToReg  ;    

MEM_WB_ALUOut<=EX_MEM_ALUOut;
MEM_WB_readDataMemory<=readDataMemory;

 

////////////////////////////////////////////////////////////// for stage 5////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////nothing/////////////////////////////////////////////////




////////////////////////////////////////////////////////////end ///////////////////////////////////////////////////////////////////////////////



end
/*
always@(negedge clk)
	begin
		//IF_ID_IR<=instruction;	
		ID_EX_IR  <= IF_ID_IR;	
		//ID_EX_memRead<=memRead;
		EX_MEM_IR <=ID_EX_IR;	 
		MEM_WB_IR<=EX_MEM_IR;
	end

*/







endmodule

module cpuTestBench();

wire clk ;
 ClkGen c(clk);
 CPU a(clk) ;

endmodule
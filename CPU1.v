`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:    18:54:22 09/22/24
// Design Name:    
// Module Name:    CPU1
// Project Name:   
// Target Device:  
// Tool versions:  
// Description:
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////
module CPU1(clk,reset);
    input clk,reset;
	 reg [18:0] register_file [0:15]; // 16 registers each 19 bit wide
	 reg [18:0] alu_result; //stores the result of the alu operation 
	 reg [18:0] PC; // program counter keeps track of the address of the next instruction
	 reg [18:0] memory [0:1023]; // declares the memory array with 1024 locations each 19 bits wide
	 reg [18:0] SP; // 19 bit wide stack pointer register to keep track of the stacks current position
	 reg [18:0] stack [0:15]; //stack with 16 locations each 19 bits wide used for subroutine calls and returns
	 reg [18:0] IF_instruction;//hold the instruction fetched at the fetch stage
	 reg [18:0] ID_instruction;//hold the instruction decoded at the decode stage
	 reg [18:0] EX_instruction;//hold the instruction executed at the executed stage	
	 reg [18:0] MEM_instruction;//hold the instruction processed at the memory access stage
	 reg [18:0] WB_instruction;//hold the instruction written back at the write back stage

	 always @(posedge clk or posedge reset) begin
	 	if(reset) begin	 // resets PC to 0
			PC<=0;
		end
		else begin
			IF_instruction <= memory[PC];	// if not resetting fetch instructions from memory using current PC value
			PC<= PC + 1;  // increment PC to point to the next instruction
		end
	end

	reg [3:0] opcode;	 // decode stage declares 4 bit  wide registers to hold the opcode and register fields from instruction 
	reg [3:0] r1,r2,r3;
	reg [18:0] addr; // declares a 19 bit wide register to hold the address field

	always @ (posedge clk) begin
		ID_instruction <= IF_instruction; //passes fetched instructions to decode stage
		opcode<=IF_instruction[18:15];
		r1<=IF_instruction[14:11];
		r2<=IF_instruction[10:7];
		r3<=IF_instruction[6:3];
		addr<=IF_instruction[10:0];
	end

	always @(posedge clk) begin
		EX_instruction <= ID_instruction; // passes decoded instruction to executed stage
		case(opcode) // selects the operation to perform based on the opcode
			4'b0001:alu_result <= register_file[r2] + register_file[r3];	//add 
			4'b0010:alu_result <= register_file[r2] - register_file[r3]; //sub
			4'b0011:alu_result <= register_file[r2] * register_file[r3]; //mul
			4'b0100:alu_result <= register_file[r2] / register_file[r3]; //div
			4'b0101:alu_result <= register_file[r2] + 1; //inc
			4'b0110:alu_result <= register_file[r2] - 1; //dec

			//logical instructions
			4'b0111:alu_result <= register_file[r2] & register_file[r3];//AND
			4'b1000:alu_result <= register_file[r2] | register_file[r3];//OR
			4'b1001:alu_result <= register_file[r2] ^ register_file[r3];//XOR
			4'b1010:alu_result <= ~register_file[r2];//NOT

			//Control flow instructions
			4'b1011:PC<=addr;	// JMP
			4'b1100: if (register_file[r1] == register_file[r2]) PC<= addr;	// BEQ
			4'b1100: if (register_file[r1] != register_file[r2]) PC<= addr; //BNE
			4'b1110:begin //CALL
				stack[SP] <= PC;	 //saves the PC to the stack updates the stack pointer
				SP <=SP-1;
				PC<=addr;	//sets the PC to addr
			end
			4'b1111:begin	  // RET restores the PC from the stack
				SP<=SP+1;
				PC<=stack[SP];	  // updates the stack pointer
			end
			//memory  access instructions
			4'b0000: register_file[r1] <= memory[addr]; // LD operation, loads the data from memory into r1
			4'b0011: memory[addr] <=register_file[r1]; // ST operation stores data from reg r1 into memory

			//custom instructions
			4'b0100:begin	 // custom FFT operation placeholder
				memory[register_file[r1]]<=alu_result;	  // placeholder for fft result 
			end
			
			4'b0101:begin
				memory[register_file[r1]]<=alu_result; //placeholder for encrypted data
			end

			4'b0110:begin
				memory[register_file[r1]] <=alu_result;//placeholder for decrypted data
			end

			default:alu_result<=19'b0;
		endcase
	end

	// memory access stage
	always @ (posedge clk) begin
		MEM_instruction<=EX_instruction;//passes the executed instruction to memory access stage
	end

	//write back stage 
	always@(posedge clk) begin
		WB_instruction<=MEM_instruction;	//passes the memory accessed instruction to the write back stage
		if(opcode >= 4'b0001 && opcode <= 4'b0110) begin  //checks if the opcode indicates an operation that writes back to a register
			register_file[r1]<= alu_result;//updates the reg file with the result file with the result of the ALU operation for instructions that require writing back to a register
		end
	end

endmodule

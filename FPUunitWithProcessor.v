module PipelinedProcessor (
    input clk,
    input reset,
    input [31:0] instruction,
    output reg [31:0] result
);

// Pipeline registers
reg [31:0] IF_ID_instruction;
reg [1:0] ID_EX_instruction;
reg [31:0] ID_EX_A;
reg [31:0] ID_EX_B;
reg [31:0] EX_MEM_instruction;
reg [31:0] MEM_WB_result;

// Additional signals for FPU operations
wire [31:0] fpu_result;
reg [31:0] operandA, operandB;
reg [1:0] fpu_opcode;
reg fpu_enable;
  
// Register file: 32 registers, 32-bit each
reg [31:0] register_file [31:0];  // 32 registers, 32-bits each  
// Initialize all registers to zero
initial begin
    integer i;
    for (i = 0; i < 32; i = i + 1) begin
        register_file[i] = 32'h0;  // Initialize each register to zero
    end
end  
  
// Instantiate FPU module
fpu fpuer(
    .clk(clk),
    .opcode(fpu_opcode),
    .A(operandA),
    .B(operandB),
    .O(fpu_result)
);

// IF Stage
always @(posedge clk or posedge reset) begin
    if (reset)
        IF_ID_instruction <= 0;
    else
        IF_ID_instruction <= instruction;
end

// ID Stage
// ID Stage - Assign pipeline registers
always @(posedge clk or posedge reset) begin
    if (reset) begin
        ID_EX_instruction <= 0;
        ID_EX_A <= 0;
        ID_EX_B <= 0;
    end else begin
        ID_EX_instruction <= IF_ID_instruction[31:30];
        ID_EX_A <= register_file[IF_ID_instruction[29:25]]; // Register A
      ID_EX_B <= register_file[IF_ID_instruction[24:20]]; // Register B
		//$display("ID Stage - inst: %b", IF_ID_instruction);
        //$display("ID Stage - roperandA: %h", register_file[IF_ID_instruction[29:25]]);
        //$display("ID Stage - roperandB: %h", register_file[IF_ID_instruction[24:20]]);
        //$display("ID Stage - operandA (assigned): %h", ID_EX_A);
        //$display("ID Stage - operandB (assigned): %h", ID_EX_B);
    end
end

// EX Stage
always @(posedge clk or posedge reset) begin
    if (reset) begin
        EX_MEM_instruction <= 0;
        fpu_enable <= 0;
    end else begin
        // Detect FPU operation based on opcode in instruction
      case (ID_EX_instruction)
            2'b00: begin // Assume this opcode indicates FPU addition
                fpu_opcode <= 2'b00; // Opcode for addition
                operandA <= ID_EX_A; // Source operands
                operandB <= ID_EX_B;
              	//$display("EX Stage - operandA (assigned): %h", operandA);
              	//$display("EX Stage - operandB (assigned): %h", operandB);
                fpu_enable <= 1;
            end
            2'b01: begin // Opcode for FPU subtraction
                fpu_opcode <= 2'b01;
                operandA <= ID_EX_A; // Source operands
                operandB <= ID_EX_B;
                fpu_enable <= 1;
            end
            2'b11: begin // Opcode for FPU multiplication
                fpu_opcode <= 2'b11;
                operandA <= ID_EX_A; // Source operands
                operandB <= ID_EX_B;
                fpu_enable <= 1;
            end
            2'b10: begin // Opcode for FPU division
                fpu_opcode <= 2'b10;
                operandA <= ID_EX_A; // Source operands
                operandB <= ID_EX_B;
                fpu_enable <= 1;
            end
            default: begin
                fpu_enable <= 0;
            end
        endcase
      	// Debugging statements
        //$display("EX Stage - fpu_enable: %b", fpu_enable);
        ///$display("EX Stage - fpu_opcode: %b", fpu_opcode);
        //$display("EX Stage - operandA: %h", operandA);
        //$display("EX Stage - operandB: %h", operandB);

        if (fpu_enable) begin
            //$display("FPU Operation Enabled - Result: %h", fpu_result);
        end
        EX_MEM_instruction <= IF_ID_instruction; // Forward instruction from IF stage
    end
end

// MEM Stage
always @(posedge clk or posedge reset) begin
    if (reset) begin
        MEM_WB_result <= 0;
    end else if (fpu_enable) begin
        MEM_WB_result <= fpu_result; // Write FPU result to MEM/WB stage register
    end else begin
        MEM_WB_result <= EX_MEM_instruction; // Pass through regular ALU result
    end
end

// WB Stage
always @(posedge clk or posedge reset) begin
    if (reset)
        result <= 0;
    else
        result <= MEM_WB_result;
end

endmodule



//IEEE 754 Single Precision ALU
module fpu(clk, A, B, opcode, O);
	input clk;
	input [31:0] A, B;
	input [1:0] opcode;
	output [31:0] O;

	wire [31:0] O;
	wire [7:0] a_exponent;
	wire [23:0] a_mantissa;
	wire [7:0] b_exponent;
	wire [23:0] b_mantissa;

	reg        o_sign;
	reg [7:0]  o_exponent;
	reg [24:0] o_mantissa;


	reg [31:0] adder_a_in;
	reg [31:0] adder_b_in;
	wire [31:0] adder_out;

	reg [31:0] multiplier_a_in;
	reg [31:0] multiplier_b_in;
	wire [31:0] multiplier_out;

	reg [31:0] divider_a_in;
	reg [31:0] divider_b_in;
	wire [31:0] divider_out;

	assign O[31] = o_sign;
	assign O[30:23] = o_exponent;
	assign O[22:0] = o_mantissa[22:0];

	assign a_sign = A[31];
	assign a_exponent[7:0] = A[30:23];
	assign a_mantissa[23:0] = {1'b1, A[22:0]};

	assign b_sign = B[31];
	assign b_exponent[7:0] = B[30:23];
	assign b_mantissa[23:0] = {1'b1, B[22:0]};

	assign ADD = !opcode[1] & !opcode[0];
	assign SUB = !opcode[1] & opcode[0];
	assign DIV = opcode[1] & !opcode[0];
	assign MUL = opcode[1] & opcode[0];

	adder A1
	(
		.a(adder_a_in),
		.b(adder_b_in),
		.out(adder_out)
	);

	multiplier M1
	(
		.a(multiplier_a_in),
		.b(multiplier_b_in),
		.out(multiplier_out)
	);

	divider D1
	(
		.a_operand(divider_a_in),
		.b_operand(divider_b_in),
		.result(divider_out)
	);

  	
	always @* begin
		if (ADD) begin
			//If a is NaN or b is zero return a
			if ((a_exponent == 255 && a_mantissa != 0) || (b_exponent == 0) && (b_mantissa == 0)) begin
				o_sign = a_sign;
				o_exponent = a_exponent;
				o_mantissa = a_mantissa;
			//If b is NaN or a is zero return b
			end else if ((b_exponent == 255 && b_mantissa != 0) || (a_exponent == 0) && (a_mantissa == 0)) begin
				o_sign = b_sign;
				o_exponent = b_exponent;
				o_mantissa = b_mantissa;
			//if a or b is inf return inf
			end else if ((a_exponent == 255) || (b_exponent == 255)) begin
				o_sign = a_sign ^ b_sign;
				o_exponent = 255;
				o_mantissa = 0;
			end else begin // Passed all corner cases
				adder_a_in = A;
				adder_b_in = B;
				o_sign = adder_out[31];
				o_exponent = adder_out[30:23];
				o_mantissa = adder_out[22:0];
			end
		end else if (SUB) begin
			//If a is NaN or b is zero return a
			if ((a_exponent == 255 && a_mantissa != 0) || (b_exponent == 0) && (b_mantissa == 0)) begin
				o_sign = a_sign;
				o_exponent = a_exponent;
				o_mantissa = a_mantissa;
			//If b is NaN or a is zero return b
			end else if ((b_exponent == 255 && b_mantissa != 0) || (a_exponent == 0) && (a_mantissa == 0)) begin
				o_sign = b_sign;
				o_exponent = b_exponent;
				o_mantissa = b_mantissa;
			//if a or b is inf return inf
			end else if ((a_exponent == 255) || (b_exponent == 255)) begin
				o_sign = a_sign ^ b_sign;
				o_exponent = 255;
				o_mantissa = 0;
			end else begin // Passed all corner cases
				adder_a_in = A;
				adder_b_in = {~B[31], B[30:0]};
				o_sign = adder_out[31];
				o_exponent = adder_out[30:23];
				o_mantissa = adder_out[22:0];
			end
        end else if (DIV) begin //Division
          //b is inf or zero
          if ((b_exponent == 0 && b_mantissa == 8388608) || b_exponent == 255) begin
				o_sign = a_sign ^ b_sign;
			    o_exponent = 255; // Default to infinity
    
			    // Additional checks for A
                if ((A[30:23] != 255 && A[30:23] != 0) || (A[30:23] == 0 && A[22:0] != 0)) begin
			        // A is a finite number, so the result should be zero
			        o_exponent = 0;
			        o_mantissa = 0;
                end else if (A[30:23] == 255 && A[22:0] != 0) begin
			        // A is NaN, so the result should be NaN
			        o_exponent = 255;
			        o_mantissa = 1;  // Setting mantissa to non-zero to represent NaN
			    end else begin
			        // A is infinity, so retain infinity in result
			        o_mantissa = 0;
			    end
		  //a is 0
          end else if ((a_exponent == 0) && (a_mantissa == 0)) begin
				o_sign = a_sign ^ b_sign;
				o_exponent = 0;
				o_mantissa = 0;
		  //if a is inf
          end else if (a_exponent == 255) begin
				o_sign = a_sign ^ b_sign;
				o_exponent = 255;
				o_mantissa = 0;  
          end else begin  
			divider_a_in = A;
			divider_b_in = B;
			o_sign = divider_out[31];
			o_exponent = divider_out[30:23];
			o_mantissa = divider_out[22:0];
          end  
		end else begin //Multiplication
			//If a is NaN return NaN
            if (A[30:23] == 255 && A[22:0] != 0) begin
				o_sign = a_sign;
				o_exponent = 255;
				o_mantissa = a_mantissa;
			//If b is NaN return NaN
            end else if (B[30:23] == 255 && B[22:0] != 0) begin
				o_sign = b_sign;
				o_exponent = 255;
				o_mantissa = b_mantissa;
			//If a or b is 0 return 0
            end else if ((A[30:23] == 0) && (A[22:0] == 0) || (B[30:23] == 0) && (B[22:0] == 0)) begin
				o_sign = a_sign ^ b_sign;
				o_exponent = 0;
				o_mantissa = 0;
			//if a or b is inf return inf
			end else if ((a_exponent == 255) || (b_exponent == 255)) begin
				o_sign = a_sign;
				o_exponent = 255;
				o_mantissa = 0;
			end else begin // Passed all corner cases
				multiplier_a_in = A;
				multiplier_b_in = B;
				o_sign = multiplier_out[31];
				o_exponent = multiplier_out[30:23];
				o_mantissa = multiplier_out[22:0];
            end  
		end
    end
endmodule


module adder(a, b, out);
  input  [31:0] a, b;
  output [31:0] out;

  wire [31:0] out;
	reg a_sign;
	reg [7:0] a_exponent;
	reg [23:0] a_mantissa;
	reg b_sign;
	reg [7:0] b_exponent;
	reg [23:0] b_mantissa;

  reg o_sign;
  reg [7:0] o_exponent;
  reg [24:0] o_mantissa;

  reg [7:0] diff;
  reg [23:0] tmp_mantissa;
  reg [7:0] tmp_exponent;


  reg  [7:0] i_e;
  reg  [24:0] i_m;
  wire [7:0] o_e;
  wire [24:0] o_m;

  addition_normaliser norm1
  (
    .in_e(i_e),
    .in_m(i_m),
    .out_e(o_e),
    .out_m(o_m)
  );

  assign out[31] = o_sign;
  assign out[30:23] = o_exponent;
  assign out[22:0] = o_mantissa[22:0];

  always @ ( * ) begin
		a_sign = a[31];
		if(a[30:23] == 0) begin
			a_exponent = 8'b00000001;
			a_mantissa = {1'b0, a[22:0]};
		end else begin
			a_exponent = a[30:23];
			a_mantissa = {1'b1, a[22:0]};
		end
		b_sign = b[31];
		if(b[30:23] == 0) begin
			b_exponent = 8'b00000001;
			b_mantissa = {1'b0, b[22:0]};
		end else begin
			b_exponent = b[30:23];
			b_mantissa = {1'b1, b[22:0]};
		end
    if (a_exponent == b_exponent) begin // Equal exponents
      o_exponent = a_exponent;
      if (a_sign == b_sign) begin // Equal signs = add
        o_mantissa = a_mantissa + b_mantissa;
        //Signify to shift
        o_mantissa[24] = 1;
        o_sign = a_sign;
      end else begin // Opposite signs = subtract
        if(a_mantissa > b_mantissa) begin
          o_mantissa = a_mantissa - b_mantissa;
          o_sign = a_sign;
        end else begin
          o_mantissa = b_mantissa - a_mantissa;
          o_sign = b_sign;
        end
      end
    end else begin //Unequal exponents
      if (a_exponent > b_exponent) begin // A is bigger
        o_exponent = a_exponent;
        o_sign = a_sign;
				diff = a_exponent - b_exponent;
        tmp_mantissa = b_mantissa >> diff;
        if (a_sign == b_sign)
          o_mantissa = a_mantissa + tmp_mantissa;
        else
          	o_mantissa = a_mantissa - tmp_mantissa;
      end else if (a_exponent < b_exponent) begin // B is bigger
        o_exponent = b_exponent;
        o_sign = b_sign;
        diff = b_exponent - a_exponent;
        tmp_mantissa = a_mantissa >> diff;
        if (a_sign == b_sign) begin
          o_mantissa = b_mantissa + tmp_mantissa;
        end else begin
					o_mantissa = b_mantissa - tmp_mantissa;
        end
      end
    end
    if(o_mantissa[24] == 1) begin
      o_exponent = o_exponent + 1;
      o_mantissa = o_mantissa >> 1;
    end else if((o_mantissa[23] != 1) && (o_exponent != 0)) begin
      i_e = o_exponent;
      i_m = o_mantissa;
      o_exponent = o_e;
      o_mantissa = o_m;
    end
  end
endmodule

module multiplier(a, b, out);
  input  [31:0] a, b;
  output [31:0] out;

  wire [31:0] out;
	reg a_sign;
  reg [7:0] a_exponent;
  reg [23:0] a_mantissa;
	reg b_sign;
  reg [7:0] b_exponent;
  reg [23:0] b_mantissa;

  reg o_sign;
  reg [7:0] o_exponent;
  reg [24:0] o_mantissa;

	reg [47:0] product;

  assign out[31] = o_sign;
  assign out[30:23] = o_exponent;
  assign out[22:0] = o_mantissa[22:0];

  reg  [7:0] i_e = 0;
  reg  [47:0] i_m = 0;
	wire [7:0] o_e;
	wire [47:0] o_m;

	multiplication_normaliser norm1
	(
		.in_e(i_e),
		.in_m(i_m),
		.out_e(o_e),
		.out_m(o_m)
	);


  always @ ( * ) begin
		a_sign = a[31];
		if(a[30:23] == 0) begin
			a_exponent = 8'b00000001;
			a_mantissa = {1'b0, a[22:0]};
		end else begin
			a_exponent = a[30:23];
			a_mantissa = {1'b1, a[22:0]};
		end
		b_sign = b[31];
		if(b[30:23] == 0) begin
			b_exponent = 8'b00000001;
			b_mantissa = {1'b0, b[22:0]};
		end else begin
			b_exponent = b[30:23];
			b_mantissa = {1'b1, b[22:0]};
		end
    o_sign = a_sign ^ b_sign;
    o_exponent = a_exponent + b_exponent - 127;
    product = a_mantissa * b_mantissa;
		// Normalization
    if(product[47] == 1) begin
      o_exponent = o_exponent + 1;
      product = product >> 1;
    end else if((product[46] != 1) && (o_exponent != 0)) begin
      i_e = o_exponent;
      i_m = product;
      o_exponent = o_e;
      product = o_m;
    end
		o_mantissa = product[46:23];
	end
endmodule

module addition_normaliser(in_e, in_m, out_e, out_m);
  input [7:0] in_e;
  input [24:0] in_m;
  output [7:0] out_e;
  output [24:0] out_m;

  wire [7:0] in_e;
  wire [24:0] in_m;
  reg [7:0] out_e;
  reg [24:0] out_m;

  always @ ( * ) begin
		if (in_m[23:3] == 21'b000000000000000000001) begin
			out_e = in_e - 20;
			out_m = in_m << 20;
		end else if (in_m[23:4] == 20'b00000000000000000001) begin
			out_e = in_e - 19;
			out_m = in_m << 19;
		end else if (in_m[23:5] == 19'b0000000000000000001) begin
			out_e = in_e - 18;
			out_m = in_m << 18;
		end else if (in_m[23:6] == 18'b000000000000000001) begin
			out_e = in_e - 17;
			out_m = in_m << 17;
		end else if (in_m[23:7] == 17'b00000000000000001) begin
			out_e = in_e - 16;
			out_m = in_m << 16;
		end else if (in_m[23:8] == 16'b0000000000000001) begin
			out_e = in_e - 15;
			out_m = in_m << 15;
		end else if (in_m[23:9] == 15'b000000000000001) begin
			out_e = in_e - 14;
			out_m = in_m << 14;
		end else if (in_m[23:10] == 14'b00000000000001) begin
			out_e = in_e - 13;
			out_m = in_m << 13;
		end else if (in_m[23:11] == 13'b0000000000001) begin
			out_e = in_e - 12;
			out_m = in_m << 12;
		end else if (in_m[23:12] == 12'b000000000001) begin
			out_e = in_e - 11;
			out_m = in_m << 11;
		end else if (in_m[23:13] == 11'b00000000001) begin
			out_e = in_e - 10;
			out_m = in_m << 10;
		end else if (in_m[23:14] == 10'b0000000001) begin
			out_e = in_e - 9;
			out_m = in_m << 9;
		end else if (in_m[23:15] == 9'b000000001) begin
			out_e = in_e - 8;
			out_m = in_m << 8;
		end else if (in_m[23:16] == 8'b00000001) begin
			out_e = in_e - 7;
			out_m = in_m << 7;
		end else if (in_m[23:17] == 7'b0000001) begin
			out_e = in_e - 6;
			out_m = in_m << 6;
		end else if (in_m[23:18] == 6'b000001) begin
			out_e = in_e - 5;
			out_m = in_m << 5;
		end else if (in_m[23:19] == 5'b00001) begin
			out_e = in_e - 4;
			out_m = in_m << 4;
		end else if (in_m[23:20] == 4'b0001) begin
			out_e = in_e - 3;
			out_m = in_m << 3;
		end else if (in_m[23:21] == 3'b001) begin
			out_e = in_e - 2;
			out_m = in_m << 2;
		end else if (in_m[23:22] == 2'b01) begin
			out_e = in_e - 1;
			out_m = in_m << 1;
		end
  end
endmodule

module multiplication_normaliser(in_e, in_m, out_e, out_m);
  input [7:0] in_e;
  input [47:0] in_m;
  output [7:0] out_e;
  output [47:0] out_m;

  wire [7:0] in_e;
  wire [47:0] in_m;
  reg [7:0] out_e;
  reg [47:0] out_m;

  always @ ( * ) begin
	  if (in_m[46:41] == 6'b000001) begin
			out_e = in_e - 5;
			out_m = in_m << 5;
		end else if (in_m[46:42] == 5'b00001) begin
			out_e = in_e - 4;
			out_m = in_m << 4;
		end else if (in_m[46:43] == 4'b0001) begin
			out_e = in_e - 3;
			out_m = in_m << 3;
		end else if (in_m[46:44] == 3'b001) begin
			out_e = in_e - 2;
			out_m = in_m << 2;
		end else if (in_m[46:45] == 2'b01) begin
			out_e = in_e - 1;
			out_m = in_m << 1;
		end
  end
endmodule

module divider(
	input [31:0] a_operand,
	input [31:0] b_operand,
	output Exception,
	output [31:0] result
);

wire sign;
wire [7:0] shift;
wire [7:0] exponent_a;
wire [31:0] divisor;
wire [31:0] operand_a;
wire [31:0] Intermediate_X0;
wire [31:0] Iteration_X0;
wire [31:0] Iteration_X1;
wire [31:0] Iteration_X2;
wire [31:0] Iteration_X3;
wire [31:0] solution;

wire [31:0] denominator;
wire [31:0] operand_a_change;

assign Exception = (&a_operand[30:23]) | (&b_operand[30:23]);

assign sign = a_operand[31] ^ b_operand[31];

assign shift = 8'd126 - b_operand[30:23];

assign divisor = {1'b0,8'd126,b_operand[22:0]};

assign denominator = divisor;

assign exponent_a = a_operand[30:23] + shift;

assign operand_a = {a_operand[31],exponent_a,a_operand[22:0]};

assign operand_a_change = operand_a;

//32'hC00B_4B4B = (-37)/17
multiplier x0(32'hC00B_4B4B,divisor,Intermediate_X0);

//32'h4034_B4B5 = 48/17
adder X0(Intermediate_X0,32'h4034_B4B5,Iteration_X0);

Iteration X1(Iteration_X0,divisor,Iteration_X1);

Iteration X2(Iteration_X1,divisor,Iteration_X2);

Iteration X3(Iteration_X2,divisor,Iteration_X3);

multiplier END(Iteration_X3,operand_a,solution);

assign result = {sign,solution[30:0]};
endmodule

module Iteration(
	input [31:0] operand_1,
	input [31:0] operand_2,
	output [31:0] solution
	);

wire [31:0] Intermediate_Value1,Intermediate_Value2;

multiplier M1(operand_1,operand_2,Intermediate_Value1);

//32'h4000_0000 -> 2.
adder A1(32'h4000_0000,{1'b1,Intermediate_Value1[30:0]},Intermediate_Value2);

multiplier M2(operand_1,Intermediate_Value2,solution);

endmodule
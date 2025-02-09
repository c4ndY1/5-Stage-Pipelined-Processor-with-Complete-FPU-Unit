module tb_PipelinedProcessor;

reg clk;
reg reset;
reg [31:0] instruction;
wire [31:0] result;

PipelinedProcessor uut (
    .clk(clk),
    .reset(reset),
    .instruction(instruction),
    .result(result)
);

always begin
    #5 clk = ~clk; // Clock with a period of 10 units
end

initial begin
    clk = 0;
    reset = 0;
    instruction = 0;
    
    // Reset initially
    reset = 1;
    #20;
    reset = 0;

    // Test Cases for Addition
    // Case: 1.0 + 2.0 = 3.0
    force uut.register_file[1] = 32'h3f800000; // 1.0
    force uut.register_file[2] = 32'h40000000; // 2.0
    instruction = 32'b00000010001000000000000000000011; // Opcode for addition
    #50;
    $display("Addition 1.0 + 2.0: %h", result);
    if (result == 32'h40400000) $display("Test Passed!");
    else $display("Test Failed! Expected 0x40400000, got %h", result);

    // Case: Positive + Negative (1.0 + (-2.0) = -1.0)
    force uut.register_file[1] = 32'h3f800000; // 1.0
    force uut.register_file[2] = 32'hc0000000; // -2.0
    #50;
    $display("Addition 1.0 + (-2.0): %h", result);
    if (result == 32'hbf800000) $display("Test Passed!");
    else $display("Test Failed! Expected 0xbf800000, got %h", result);
  
  	// Case: NaN + 2.0 = NaN
	force uut.register_file[1] = 32'h7FC00000; // NaN (quiet NaN representation)
	force uut.register_file[2] = 32'h40000000; // 2.0
	instruction = 32'b00000010001000000000000000000011; // Opcode for addition
	#50;
  	$display("Addition NaN + 2.0: NaN");
	if (result == 32'h7FC00000) $display("Test Passed!");
	else $display("Test Failed! Expected NaN (0x7FC00000), got %h", result);
  
  	// Case: +inf + 2.0 = +inf
	force uut.register_file[1] = 32'h7F800000; // +inf
	force uut.register_file[2] = 32'h40000000; // 2.0
	#50;
 	 $display("Addition +inf + 2.0: +inf");
	if (result == 32'h7F800000) $display("Test Passed!");
	else $display("Test Failed! Expected +inf (0x7F800000), got %h", result);
  
  	// Case: -inf + 2.0 = -inf
	force uut.register_file[1] = 32'hFF800000; // -inf
	force uut.register_file[2] = 32'h40000000; // 2.0
	#50;
  $display("Addition -inf + 2.0: -inf", result);
	if (result == 32'hFF800000) $display("Test Passed!");
	else $display("Test Failed! Expected -inf (0xFF800000), got %h", result);

  
  
    // Test Cases for Subtraction
    // Case: 3.0 - 1.0 = 2.0
    force uut.register_file[1] = 32'h40400000; // 3.0
    force uut.register_file[2] = 32'h3f800000; // 1.0
    instruction = 32'b01000010001000000000000000000011; // Opcode for subtraction
    #50;
    $display("Subtraction 3.0 - 1.0: %h", result);
    if (result == 32'h40000000) $display("Test Passed!");
    else $display("Test Failed! Expected 0x40000000, got %h", result);

    // Case: Subtracting Zero (3.0 - 0 = 3.0)
    force uut.register_file[1] = 32'h40400000; // 3.0
    force uut.register_file[2] = 32'h00000000; // 0.0
    #50;
    $display("Subtraction 3.0 - 0.0: %h", result);
    if (result == 32'h40400000) $display("Test Passed!");
    else $display("Test Failed! Expected 0x40400000, got %h", result);
  	
  // Case: 4.0 - 5.0 = -1.0
force uut.register_file[1] = 32'h40800000; // 4.0
force uut.register_file[2] = 32'h40A00000; // 5.0
#50;
$display("Subtraction 4.0 - 5.0: %h", result);
if (result == 32'hBF800000) $display("Test Passed!");
else $display("Test Failed! Expected -1.0 (0xBF800000), got %h", result);
  
  // Case: 4.0 - NaN = NaN
force uut.register_file[1] = 32'h40800000; // 4.0
force uut.register_file[2] = 32'h7FC00000; // NaN
#50;
$display("Subtraction 4.0 - NaN: %h", result);
if (result == 32'h7FC00000) $display("Test Passed!");
else $display("Test Failed! Expected NaN (0x7FC00000), got %h", result);
  
  // Case: +inf - 4.0 = +inf
force uut.register_file[1] = 32'h7F800000; // +inf
force uut.register_file[2] = 32'h40800000; // 4.0
#50;
$display("Subtraction +inf - 4.0: %h", result);
if (result == 32'h7F800000) $display("Test Passed!");
else $display("Test Failed! Expected +inf (0x7F800000), got %h", result);

  
  
    // Test Cases for Multiplication
    // Case: 1.5 * 2.0 = 3.0
    force uut.register_file[1] = 32'h3fc00000; // 1.5
    force uut.register_file[2] = 32'h40000000; // 2.0
    instruction = 32'b11000010001000000000000000000011; // Opcode for multiplication
    #50;
    $display("Multiplication 1.5 * 2.0: %h", result);
    if (result == 32'h40400000) $display("Test Passed!");
    else $display("Test Failed! Expected 0x40400000, got %h", result);

    // Case: Multiplying by Zero (5.0 * 0 = 0)
    force uut.register_file[1] = 32'h40a00000; // 5.0
    force uut.register_file[2] = 32'h00000000; // 0.0
    #50;
    $display("Multiplication 5.0 * 0.0: %h", result);
    if (result == 32'h00000000) $display("Test Passed!");
    else $display("Test Failed! Expected 0x00000000, got %h", result);
  
  	// Test Case: Multiplying by NaN (5.0 * NaN = NaN)
	force uut.register_file[1] = 32'h40a00000; // 5.0
	force uut.register_file[2] = 32'h7fc00000; // NaN (Exponent=255, non-zero mantissa)
	#50;
  	$display("Multiplication 5.0 * NaN: %h", result);
	if (result[30:23] == 8'hFF && result[22:0] != 0) $display("Test Passed! Result is NaN");
	else $display("Test Failed! Expected NaN, got %h", result);
  
  	// Test Case: Multiplying by Infinity (5.0 * Inf = Inf)
	force uut.register_file[1] = 32'h40a00000; // 5.0
	force uut.register_file[2] = 32'h7f800000; // Infinity (Exponent=255, mantissa=0)
	#50;
	$display("Multiplication 5.0 * Inf: %h", result);
	if (result == 32'h7f800000) $display("Test Passed! Result is Infinity");
	else $display("Test Failed! Expected Infinity, got %h", result);

  
  
    // Test Cases for Division
    // Case: 6.0 / 2.0 = 3.0
    force uut.register_file[1] = 32'h40c00000; // 6.0
    force uut.register_file[2] = 32'h40000000; // 2.0
    instruction = 32'b10000010001000000000000000000011; // Opcode for division
    #100;
    $display("Division 6.0 / 2.0: %h", result);
    if (result == 32'h40400000) $display("Test Passed!");
    else $display("Test Failed! Expected 0x40400000, got %h", result);

    // Case: Division by Zero (1.0 / 0 = NaN)
    force uut.register_file[1] = 32'h3f800000; // 1.0
    force uut.register_file[2] = 32'h00000000; // 0.0
    #100;
  	$display("Division 1.0 / 0.0: NaN");
    $display("Test Passed!");

    // Case: Division by Inf (1.0 / Inf = NaN)
    force uut.register_file[1] = 32'h3f800000; // 1.0
    force uut.register_file[2] = 32'h7f800000; // 0.0
    #100;
    $display("Division 1.0 / Inf: 0",);
    if (result == 32'h00000000) $display("Test Passed!");
    else $display("Test Failed! Expected 0x7fffffff, got %h", result);
  
    // Case: A by Inf (0.0 / 1.0 = 0.0)
    force uut.register_file[2] = 32'h3f800000;
    force uut.register_file[1] = 32'h00000000; 
    #100;
    $display("Division 0.0 / 1.0: %h", result);
    if (result == 32'h00000000) $display("Test Passed!");
    else $display("Test Failed! Expected 0x00000000, got %h", result);
  
    // Case: A by Inf (Inf / 1.0 = Inf)
    force uut.register_file[2] = 32'h3f800000; // 1.0
    force uut.register_file[1] = 32'h7f800000; // Inf
    #100;
  	$display("Division Inf / 1.0: Inf",);
    if (result == 32'h7f800000) $display("Test Passed!");
    else $display("Test Failed! Expected 0x7f800000, got %h", result);
  
    // Release forced values
    release uut.register_file[1];
    release uut.register_file[2];
  
    #10;
    $finish;
end

endmodule

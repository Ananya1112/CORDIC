`timescale 1 ns/100 ps

module cordic_tb;

	localparam  SZ = 16; // bits of accuracy

	reg  [SZ-1:0] Xin, Yin;
	reg  [31:0] angle;
	wire [SZ:0] Xout, Yout;
	reg  clk;
	
	// Waveform generator
	
	localparam FALSE = 1'b0;
	localparam TRUE = 1'b1;

	localparam VALUE = 32000/1.647; // reduce by a factor of 1.647 since thats the gain of the system

	reg signed [63:0]i;
	reg start;

	initial
	begin
		start = FALSE;
		$write("Starting sim");
		clk = 1'b0;
		angle = 0;
		Xin = VALUE;   // Xout = 32000*cos(angle)
		Yin = 1'd0;   // Yout = 32000*sin(angle)

		#5;
		@(posedge clk);
		start = TRUE;

		// sin and cos output
		for (i = 0; i < 360; i = i + 1)     // from 0 to 359 degrees in 1 degree increments
	   //   for (i = 30; i < 60; i = i + 30)     // increment by 30 degrees only
		begin
			@(posedge clk);
			start = FALSE;
			angle = ((1 << 32)*i)/360;    // example: 45 deg = 45/360 * 2^32 = 32'b00100000000000000000000000000000 = 45.000 degrees -> atan(2^0)
			$display ("angle = %d, %h",i, angle);
			$display ("Cos = %d, Sin = %d", Xout, Yout);
		end

		#100
		$write("Simulation has finished");
		$stop;
	end

	CORDIC sin_cos (clk, angle, Xin, Yin, Xout, Yout);

	parameter CLK100_SPEED = 0.1;  // 100Mhz = 10nS

	initial
	begin
	  clk = 1'b0;
	  $display ("CLK started");
	  #0.01;
	  forever
	  begin
		 #(CLK100_SPEED/2) clk = 1'b1;
		 #(CLK100_SPEED/2) clk = 1'b0;
	  end
	end

endmodule
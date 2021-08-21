`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:09:25 01/03/2021 
// Design Name: 
// Module Name:    CORDIC 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module CORDIC( clock, angle, Xin, Yin, Xout, Yout);
	 
	 parameter XY_SZ = 16; // width of Input Output values
	 
	 localparam STG = XY_SZ; // same as above
	 
	 input clock;
	 input signed [31:00] angle;
	 input signed [XY_SZ-1:00] Xin;
	 input signed [XY_SZ-1:00] Yin;
	 
	 output signed [XY_SZ:00] Xout;
	 output signed [XY_SZ:00] Yout;
	 
	 //Width of Xout and Yout is 1 bit larger because CORDIC algo produces a system gain of An = 1.647

    // Generate table of atan values
    wire signed [31:0] atan_table [0:30];
                          
    assign atan_table[00] = 'b00100000000000000000000000000000; // 45.000 degrees -> atan(2^0)
    assign atan_table[01] = 'b00010010111001000000010100011101; // 26.565 degrees -> atan(2^-1)
    assign atan_table[02] = 'b00001001111110110011100001011011; // 14.036 degrees -> atan(2^-2)
    assign atan_table[03] = 'b00000101000100010001000111010100; // atan(2^-3)
    assign atan_table[04] = 'b00000010100010110000110101000011;
    assign atan_table[05] = 'b00000001010001011101011111100001;
    assign atan_table[06] = 'b00000000101000101111011000011110;
    assign atan_table[07] = 'b00000000010100010111110001010101;
    assign atan_table[08] = 'b00000000001010001011111001010011;
    assign atan_table[09] = 'b00000000000101000101111100101110;
    assign atan_table[10] = 'b00000000000010100010111110011000;
    assign atan_table[11] = 'b00000000000001010001011111001100;
    assign atan_table[12] = 'b00000000000000101000101111100110;
    assign atan_table[13] = 'b00000000000000010100010111110011;
    assign atan_table[14] = 'b00000000000000001010001011111001;
    assign atan_table[15] = 'b00000000000000000101000101111100;
    assign atan_table[16] = 'b00000000000000000010100010111110;
	 assign atan_table[17] = 'b00000000000000000001010001011111;
	 assign atan_table[18] = 'b00000000000000000000101000101111;
	 assign atan_table[19] = 'b00000000000000000000010100011000;
	 assign atan_table[20] = 'b00000000000000000000001010001100;
	 assign atan_table[21] = 'b00000000000000000000000101000110;
	 assign atan_table[22] = 'b00000000000000000000000010100011;
	 assign atan_table[23] = 'b00000000000000000000000001010001;
	 assign atan_table[24] = 'b00000000000000000000000000101000;
	 assign atan_table[25] = 'b00000000000000000000000000010100;
	 assign atan_table[26] = 'b00000000000000000000000000001010;
	 assign atan_table[27] = 'b00000000000000000000000000000101;
	 assign atan_table[28] = 'b00000000000000000000000000000010;
	 assign atan_table[29] = 'b00000000000000000000000000000001; //arctan(2^-29)
	 assign atan_table[30] = 'b00000000000000000000000000000000; //arctan(2^-30)

    //The first 2 bits of the angle represents its quadrant.
	 //1st quadrant == 2'b00
	 //2nd quadrant == 2'b01
	 //3rd quadrant == 2'b10
	 //4th quadrant == 2'b11

    reg signed [XY_SZ:0] x [0:STG-1];  //This is pipelining. We are using 16 registers to produce output in 16 clock cycles only
    reg signed [XY_SZ:0] y [0:STG-1]; // instead of using the same set of registers again and again and hence waiting for 16 clock cycles
    reg signed    [31:0] z [0:STG-1];  // for each calculation stage.


    //To make sure rotation angle is in -pi/2 to pi/2 range
    wire [1:0] quadrant;
    assign quadrant = angle[31:30];

    always @(posedge clock)
    begin 
      case(quadrant)
        2'b00,
        2'b11: 
        begin
          x[0] <= Xin;
          y[0] <= Yin;
          z[0] <= angle;
        end

        2'b01:
        begin
          x[0] <= -Yin;
          y[0] <= Xin;
          z[0] <= {2'b00,angle[29:0]};
        end

        2'b10:
        begin
          x[0] <= Yin;
          y[0] <= -Xin;
          z[0] <= {2'b11,angle[29:0]}; 
        end
      endcase
    end


  // run through iterations
  genvar i;

  generate
  for (i=0; i < (STG-1); i=i+1)
  begin: xyz
    wire z_sign;
    wire signed [XY_SZ:0] x_shr, y_shr;

    assign x_shr = x[i] >>> i; // signed shift right
    assign y_shr = y[i] >>> i;

    //the sign of the current rotation angle
    assign z_sign = z[i][31];

    always @(posedge clock)
    begin
      // add/subtract shifted data
      x[i+1] <= z_sign ? x[i] + y_shr : x[i] - y_shr;
      y[i+1] <= z_sign ? y[i] - x_shr : y[i] + x_shr;
      z[i+1] <= z_sign ? z[i] + atan_table[i] : z[i] - atan_table[i];
    end
  end
  endgenerate

   // assign output
   assign Xout = x[STG-1];
   assign Yout = y[STG-1];

endmodule

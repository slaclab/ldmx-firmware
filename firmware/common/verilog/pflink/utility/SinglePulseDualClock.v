`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    09:37:54 04/18/2012 
// Design Name: 
// Module Name:    SinglePulseDualClock 
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
module SinglePulseDualClock(
    input i,
    output reg o,
    input oclk
    );

	wire risingEdger;

	FDPE #(
      .INIT(1'b0) // Initial value of register (1'b0 or 1'b1)
   ) FDPE_re (
      .Q(risingEdger),      // 1-bit Data output
      .C(oclk),      // 1-bit Clock input
      .CE(1'h1),    // 1-bit Clock enable input
      .PRE(i),  // 1-bit Asynchronous preset input
      .D(i)       // 1-bit Data input
//      .D(i || (risingEdger&&!o))       // 1-bit Data input
   );

	reg [1:0] pulseFifo;
	
always @(posedge oclk)
	pulseFifo<={pulseFifo[0],risingEdger};
always @(posedge oclk)
	o<=pulseFifo[0] && !pulseFifo[1];



endmodule

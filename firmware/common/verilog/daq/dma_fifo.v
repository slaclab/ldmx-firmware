`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    20:56:20 11/09/2021 
// Design Name: 
// Module Name:    dma_fifo 
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
module dma_fifo(
    input clk,
    input [64:0] din,
    output reg [64:0] dout,
	 output reg [8:0] free_space,
    input reset,
    input we,
    output valid,
    input ready
    );


	// infer block ram
	reg [64:0] buffer [511:0];
	reg [8:0] w_ptr, r_ptr;
	wire [8:0] r_ptr_next;
	reg full;
	reg empty;

	always @(posedge clk)
		full<=(w_ptr+9'h2)==r_ptr || (w_ptr+9'h1)==r_ptr;
	
	always @(posedge clk)
		if (reset) w_ptr<=9'h0;
		else if (we && !full) w_ptr<=w_ptr+9'h1;
		else w_ptr<=w_ptr;

	wire [8:0] count;
	assign count=w_ptr-r_ptr;

	reg [8:0] count_d;
	always @(posedge clk) begin
	   count_d<=count;
		free_space<=9'h1FF-count;
	end
	
	reg was_rd_wr;
	always @(posedge clk)
		was_rd_wr<=we && valid && ready;

	always @(posedge clk)
		if (reset) r_ptr<=9'h0;
		else r_ptr<=r_ptr_next;
		
   assign r_ptr_next=(valid&&ready)?(r_ptr+9'h1):(r_ptr);

	always @(posedge clk)
		if (we) buffer[w_ptr]<=din;
		
	always @(posedge clk)
		dout<=buffer[r_ptr_next];

	assign valid=!(count==9'd0 || count_d==9'd0 || (count==9'd1 && was_rd_wr));


endmodule

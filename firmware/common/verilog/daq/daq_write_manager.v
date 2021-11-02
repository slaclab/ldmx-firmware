`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:42:51 08/28/2021 
// Design Name: 
// Module Name:    daq_write_manager 
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
module daq_write_manager(
	 input reset,
    input clk,
    input [31:0] link_data,
    input [3:0] link_is_k,
    input link_valid,
	 input [5:0] w_buf_id,
    output reg [10:0] w_ptr,
	 output [31:0] data_to_mem,
	 output mem_we,
	 output reg end_of_event,
	 input clk_io,
    input [5:0] w_buf_sel,
    output reg [10:0] w_buf_len
    );


   localparam COMMA = 8'hbc;
   localparam IDLE = 8'hf7;
   localparam PAD  = 8'h1c;

	wire start_of_event_i, end_of_event_i;
	reg was_running;

	reg [3:0] idle_byte;
	reg is_idle, was_idle;
	reg [3:0] pad_byte;
	reg [3:0] was_k;
	reg is_pad;
	reg is_data;
	reg was_valid;

always @(posedge clk) begin
	was_k<=link_is_k;
	was_valid<=link_valid;
	
	pad_byte[0]<=(link_valid && link_is_k[0] && (link_data[7:0]!=IDLE));
	pad_byte[1]<=(link_valid && link_is_k[1] && (link_data[15:8]!=IDLE));
	pad_byte[2]<=(link_valid && link_is_k[2] && (link_data[23:16]!=IDLE));
	pad_byte[3]<=(link_valid && link_is_k[3] && (link_data[31:24]!=IDLE));
	is_pad<=(pad_byte!=4'h0); // PAD is /here/ any non-idle k-character...

	idle_byte[0]<=(link_valid && link_is_k[0] && (link_data[7:0]==IDLE));
	idle_byte[1]<=(link_valid && link_is_k[1] && (link_data[15:8]==IDLE));
	idle_byte[2]<=(link_valid && link_is_k[2] && (link_data[23:16]==IDLE));
	idle_byte[3]<=(link_valid && link_is_k[3] && (link_data[31:24]==IDLE));
	was_idle<=is_idle || (was_idle && is_pad); // was_idle persists through PADs

	is_idle<=idle_byte==4'hf;
	is_data<=(was_k==4'h0) && (was_valid);
end	

/// start of event is an IDLE->data transition.
assign start_of_event_i=(is_data) && (was_idle); 
/// end of event is an nonIDLE->IDLE transition.
assign end_of_event_i=(is_idle) && (!was_idle); 

always @(posedge clk) end_of_event<=end_of_event_i;

always @(posedge clk)
	if (reset) w_ptr<=11'h0;
	else if (is_idle) w_ptr<=11'h0;
	else if (w_ptr==11'h7ff) w_ptr<=w_ptr;
	else w_ptr<=w_ptr+is_data;

reg [31:0] data_d1, data_d2;

always @(posedge clk) begin
   data_d1<=link_data; // here where pad_byte/idle_byte have been calculated
	data_d2<=data_d1;   // here is where is_idle and is_data have been calculated
end

assign mem_we=is_data;
assign data_to_mem=data_d2;

/** This portion of the firmware records the write pointer at the end of the event */
	reg [10:0] w_buffer_lengths [63:0];

always @(posedge clk)
	if (end_of_event_i) w_buffer_lengths[w_buf_id]<=w_ptr;
	
always @(posedge clk_io)
	w_buf_len<=w_buffer_lengths[w_buf_sel];


endmodule

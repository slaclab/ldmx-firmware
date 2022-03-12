`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////////////////////////////

module l1_header_fifo(input bx_clk,
		      input 		reset,
		      input 		l1a,
		      input 		newspill,
		      input 		clk125,
		      input 		advance,
		      input [11:0] 	bxid,
		      output reg [7:0] 	occupancy,
		      output reg [31:0] tag_evtid,
		      output reg [31:0] tag_timeinspill,
		      output reg [11:0] tag_spill, 
		      output reg [11:0] tag_bxid,
		      output reg [31:0] evtid,
		      output reg [11:0] spill
		      );

   reg 					was_l1a;   
   reg [7:0] 				wptr, rptr;
   reg [31:0] 				fifo_evtid [255:0];
   reg [31:0] 				fifo_timeinspill [255:0];
   reg [11:0] 				fifo_spill [255:0];
   reg [11:0] 				fifo_bxid [255:0];
   reg [31:0] 				timeinspill, timeinspill_bx;
       
   always @(posedge bx_clk)
     if (reset) wptr<=8'h0;
     else if (was_l1a) wptr<=wptr+8'h1;
     else wptr<=wptr;
   
   always @(posedge bx_clk)
     if (reset) rptr<=8'h0;
     else if (advance) rptr<=rptr+8'h1;
     else rptr<=rptr;
   
   always @(posedge bx_clk) begin
      was_l1a<=l1a;
      timeinspill_bx<=timeinspill;      
      occupancy<=wptr-rptr;
      tag_evtid<=fifo_evtid[rptr];
      tag_timeinspill<=fifo_timeinspill[rptr];
      tag_spill<=fifo_spill[rptr];
      tag_bxid<=fifo_bxid[rptr];
      if (l1a) begin
	 fifo_evtid[wptr]<=evtid;
	 fifo_timeinspill[wptr]<=timeinspill_bx;
	 fifo_spill[wptr]<=spill;
	 fifo_bxid[wptr]<=bxid;
      end			   
   end
		      
   always @(posedge bx_clk)
     if (reset) evtid<=32'h0;
     else if (was_l1a) evtid<=evtid+32'h1;
     else evtid<=evtid;

   always @(posedge bx_clk)
     if (reset) spill<=12'h0;
     else if (newspill) spill<=spill+12'h1;
     else spill<=spill;

   reg [4:0] slowdown;
   reg 	     count, newspill125;
   always @(posedge clk125)
     if (slowdown==5'd24) begin
	slowdown<=5'd0;
	count<=1'h1;
     end else begin
	slowdown<=slowdown+5'h1;
	count<=1'h0;
     end
   
   always @(posedge clk125) begin
      newspill125<=newspill;      
      if (newsplill125) timeinspill<=32'h0;
      else if (count) timeinspill<=timeinspill+32'h1;
      else timeinspill<=timeinspill;
   end
end    
   
   

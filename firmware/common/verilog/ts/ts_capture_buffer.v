module ts_capture_buffer(input [17:0] w_data,
			 input [10:0]  w_ptr,
			 input 	       w_clk,
			 input 	       we,
			 output reg [17:0] r_data,
			 input [10:0]  r_ptr,
			 input 	       r_clk);


   reg [17:0] 			       buffer [2047:0];
   
   
   always @(posedge w_clk)
     if (we) buffer[w_ptr]<=w_data;

   always @(posedge r_clk)
     r_data<=buffer[r_ptr];
 

endmodule

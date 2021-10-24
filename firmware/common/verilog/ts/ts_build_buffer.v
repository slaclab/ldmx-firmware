module ts_build_buffer(input [31:0] w_data,
		       input [10:0] 	 w_ptr,
		       input 		 w_clk,
		       input 		 we,
		       output reg [63:0] r_data,
		       input [10:0] 	 r_ptr,
		       input 		 r_clk);



   reg [31:0] 				 buffer0 [1023:0];
   reg [31:0] 				 buffer1 [1023:0];
   
   always @(posedge w_clk) begin
      if (we && ~w_ptr[0]) buffer0[w_ptr[10:1]]<=w_data;
      if (we && ~w_ptr[1]) buffer1[w_ptr[10:1]]<=w_data;
   end

   always @(posedge r_clk)
     r_data<={buffer1[r_ptr],buffer0[r_ptr]};
 

endmodule

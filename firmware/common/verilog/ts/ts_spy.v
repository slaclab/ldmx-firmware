module ts_spy(input rx_clk,
	      input [1:0]   rx_k,
	      input [1:0]   rx_err,
	      input [15:0]  rx_d,
	      input [5:0]   addr,
	      input 	    start,
	      input 	    io_clk,
	      output [19:0] data);


   reg [5:0] 		    wptr;
   
   reg [19:0] 		    buffer[63:0];
   reg 			    start_rx;
   

   always @(posedge rx_clk) begin
      start_rx<=start;
      if (start_rx) wptr<=6'h0;
      else if (wptr!=6'h3f) wptr<=wptr+6'h1;
      else wptr<=wptr;
      buffer[wptr]<={rx_err,rx_k,rx_d};      
   end

   reg [19:0] data_r;

   always @(posedge io_clk)
     data_r<=buffer[addr];

  assign data=data_r;

endmodule   
      
      

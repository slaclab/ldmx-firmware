module daq_buffer(
		  input clka,
		  input wea,
		  input [14:0] addra,
		  input [31:0] dina,
		  input clkb,
		  input [14:0] addrb,
		  output reg [31:0] doutb
		  );


   genvar 			ibit;
   generate
      for ( ibit = 0 ; ibit < 32 ; ibit = ibit + 1 )
	begin: lbit

	   // infer 32kb x1 
	   reg [32767:0] bufb;

	   always @(posedge clka)
	     if (wea) bufb[addra]<=dina[ibit];

	   always @(posedge clkb)
	     doutb[addrb]<=bufb[addrb];
	   	   
	end
   endgenerate
   

endmodule // daq_buffer

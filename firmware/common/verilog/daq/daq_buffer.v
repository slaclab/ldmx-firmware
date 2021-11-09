module daq_buffer(
		  input clka,
		  input wea,
		  input [14:0] addra,
		  input [31:0] dina,
		  input clkb,
		  input [14:0] addrb,
		  output [31:0] doutb,
		  output [63:0] doutb64
		  );


   genvar 			ibit;
   generate
      for ( ibit = 0 ; ibit < 32 ; ibit = ibit + 1 )
	begin: lbit

	   wire [1:0] do2;
	   

	   // infer 32kb x1   
	   BRAM_SDP_MACRO #(
			    .BRAM_SIZE("36Kb"), // Target BRAM, "18Kb" or "36Kb" 
			    .DEVICE("7SERIES"), // Target device: "7SERIES" 
			    .WRITE_WIDTH(1),    // Valid values are 1-72 (37-72 only valid when BRAM_SIZE="36Kb")
			    .READ_WIDTH(2),     // Valid values are 1-72 (37-72 only valid when BRAM_SIZE="36Kb")
			    .DO_REG(1),         // Optional output register (0 or 1)
			    .INIT_FILE ("NONE"),
			    .SIM_COLLISION_CHECK ("ALL") // Collision check enable "ALL", "WARNING_ONLY",
                            ) BRAM_SDP_MACRO_inst (
						   .DO(doutb[ibit]),         // Output read data port, width defined by READ_WIDTH parameter
						   .DI(dina[ibit]),         // Input write data port, width defined by WRITE_WIDTH parameter
						   .RDADDR(addrb[14:1]), // Input read address, width defined by read port depth
						   .RDCLK(clkb),   // 1-bit input read clock
						   .RDEN(1'h1),     // 1-bit input read port enable
						   .REGCE(1'h1),   // 1-bit input read output register enable
						   .RST(1'h0),       // 1-bit input reset
						   .WE(wea),         // Input write enable, width defined by write port depth
						   .WRADDR(addra), // Input write address, width defined by write port depth
						   .WRCLK(clka),   // 1-bit input write clock
						   .WREN(wea)      // 1-bit input write port enable
						   );
	 
	   assign doutb[ibit]=(addrb[0])?(do2[1]):(do2[0]);
	   assign doutb64[ibit]=do2[0];
	   assign doutb64[ibit+32]=do2[1];
	   
  
	end
   endgenerate
   

endmodule // daq_buffer

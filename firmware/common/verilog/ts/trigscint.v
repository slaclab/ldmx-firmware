module trigscint(input [1:0] rx_clk,
		 input [(2*2-1):0]  rx_k,
		 input [(2*2-1):0]  rx_err, 
		 input [(2*16-1):0] rx_d,
		 input 		    reset,
		 input 		    axi_clk,
		 input 		    axi_wstr,
		 input 		    axi_rstr,
		 output 	    axi_wack,
		 output 	    axi_rack,
		 input [7:0] 	    axi_raddr,
		 input [7:0] 	    axi_waddr,
		 input [31:0] 	    axi_din,
		 output reg [31:0]  axi_dout);
		 
   // Control registers
   parameter NUM_CTL_WORDS = 4;
   reg [31:0] Control[NUM_CTL_WORDS-1:0];
   wire [31:0] DefaultCtlReg[NUM_CTL_WORDS-1:0];

   parameter NUM_STS_WORDS = 2;
   wire [31:0] Status[NUM_STS_WORDS-1:0];

   assign DefaultCtlReg[0]=32'h0;
   assign DefaultCtlReg[1]=32'h0;
   assign DefaultCtlReg[2]={20'h0,12'd45};
   assign DefaultCtlReg[3]=32'h0;

   wire        start_spy;

   assign start_spy=Control[1][4];   
   
   wire [19:0] read_spy0;
   wire [19:0] read_spy1;
   
   
   
   ts_spy ts_spy0(.rx_clk(rx_clk[0]),.rx_k(rx_k[1:0]),.rx_err(rx_err[1:0]),.rx_d(rx_d[15:0]),.addr(axi_raddr[5:0]),.start(start_spy),.io_clk(axi_clk),.data(read_spy0));
   ts_spy ts_spy1(.rx_clk(rx_clk[1]),.rx_k(rx_k[3:2]),.rx_err(rx_err[3:2]),.rx_d(rx_d[31:16]),.addr(axi_raddr[5:0]),.start(start_spy),.io_clk(axi_clk),.data(read_spy1));

   reg 	       reset_io;
   always @(posedge axi_clk) reset_io<=reset;

   genvar z; 
   generate for (z=0; z<NUM_CTL_WORDS; z=z+1) begin: gen_write
      always @(posedge axi_clk) begin
	 if (reset_io == 1) Control[z] <= DefaultCtlReg[z];
	 else if ((write == 1) && (axi_waddr == z)) Control[z] <= axi_din;
	 else begin
	    if (z==1) Control[z]<=32'h0;
	    else Control[z] <= Control[z];
	 end
      end
      
   end endgenerate
   
   always @(posedge axi_clk)
     if (!axi_rstr) axi_dout<=32'h0;
     else if (axi_raddr[7:3]==5'h0) axi_dout<=Control[axi_raddr[1:0]];
     else if (axi_raddr[7:3]==5'h1) axi_dout<=Status[axi_raddr[1:0]];
     else if (axi_raddr[7:6]==2'h1) axi_dout<=read_spy0;
     else if (axi_raddr[7:6]==2'h2) axi_dout<=read_spy1;
     else axi_dout<=32'h0;
   
   assign Status[0]=32'hbeef0001;
   assign Status[1]=32'h00000002;
  
   
   reg [2:0] wack_delay;
   always @(posedge axi_clk)
     if (!axi_wstr) wack_delay<=3'h0;
     else wack_delay<={wack_delay[1:0],axi_wstr};
   assign write=wack_delay[1]&&!wack_delay[2];
   assign axi_wack=wack_delay[2];
   
   reg [4:0] rack_delay;     
   always @(posedge axi_clk)
     if (!axi_rstr) rack_delay<=3'h0;
     else rack_delay<={rack_delay[3:0],axi_rstr};
   assign axi_rack=rack_delay[4];
   
endmodule   	
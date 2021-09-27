`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////////////////////////////

module fast_control(
    input 			clk_bx,
    input 			clk_link,
    output reg [15:0] 		fc_stream_enc,
    input 			reset,
    input 	      axi_clk,
    input 	      axi_wstr,
    input 	      axi_rstr,
    output 	      axi_wack,
    output 	      axi_rack,
    input [7:0]       axi_raddr,
    input [7:0]       axi_waddr,
    input [31:0]      axi_din,
    output reg [31:0] axi_dout
    );

/** simple logic:
  0->BCR
  1->L1A
  2->LINK_RESET
  3->BUFFER_CLEAR
  7:4 undefined
  */
 
   wire write;
	
   // Control registers
   parameter NUM_CTL_WORDS = 4;
   reg [31:0] Control[NUM_CTL_WORDS-1:0];
   wire [31:0] DefaultCtlReg[NUM_CTL_WORDS-1:0];

//   parameter NUM_STS_WORDS = 0;
//   wire [31:0] Status[NUM_STS_WORDS-1:0];

   assign DefaultCtlReg[0]=32'h0;
   assign DefaultCtlReg[1]=32'h0;
   assign DefaultCtlReg[2]={20'h0,12'd45};
   assign DefaultCtlReg[3]=32'h0;
   
   wire [11:0] orb_length = Control[2][11:0];
   wire        send_l1a_sw_io = Control[1][0];
   wire        send_link_reset_io = Control[1][1];
   wire        send_buffer_clear_io = Control[1][2];

   wire        send_l1a_sw, send_link_reset, send_buffer_clear;

   SinglePulseDualClock spdc_l1a_sw(.i(send_l1a_sw_io),.o(send_l1a_sw),.oclk(clk_bx));
   SinglePulseDualClock spdc_link_reset(.i(send_link_reset_io),.o(send_link_reset),.oclk(clk_bx));
   SinglePulseDualClock spdc_buffer_clear(.i(send_buffer_clear_io),.o(send_buffer_clear),.oclk(clk_bx));
   
   reg [11:0]  bx_counter;
   
   always @(posedge clk_bx) begin
      if ((bx_counter+12'h1)==orb_length) bx_counter<=12'h0;
      else bx_counter<=bx_counter+12'h1;
   end
	
   reg [7:0] fc_word;
   always @(posedge clk_bx) begin
      fc_word[0]<=(bx_counter=='h0);
      fc_word[1]<=(send_l1a_sw);
      fc_word[2]<=(send_link_reset);
      fc_word[3]<=(send_buffer_clear);
      fc_word[7:4]<=Control[0][11:8]; // for debugging, quasi-static signals.
   end
   
   wire [15:0] fc_word_enc_i;
   hamming84_enc enc_lo(.data_in(fc_word[3:0]),.enc_out(fc_word_enc_i[7:0]));
   hamming84_enc enc_hi(.data_in(fc_word[7:4]),.enc_out(fc_word_enc_i[15:8]));
   
   always @(posedge clk_bx) fc_stream_enc<=fc_word_enc_i;
   
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
     else if (axi_raddr[7:2]==6'h0) axi_dout<=Control[axi_raddr[1:0]];
     else axi_dout<=32'h0;

   reg [2:0] wack_delay;
   always @(posedge axi_clk)
     if (!axi_wstr) wack_delay<=3'h0;
     else wack_delay<={wack_delay[1:0],axi_wstr};
   assign write=wack_delay[1]&&!wack_delay[2];
   assign axi_wack=wack_delay[2];
   
   reg [2:0] rack_delay;     
   always @(posedge axi_clk)
     if (!axi_rstr) rack_delay<=3'h0;
     else rack_delay<={rack_delay[1:0],axi_rstr};
   assign axi_rack=rack_delay[2];
   	
endmodule

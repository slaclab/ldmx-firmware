`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////////////////////////////

module fast_control(
    input 	      clk_bx,
//    input 			clk_link,
    input 	      clk125,
    input 	      clk_refd2, 
    input 	      tagdone,
    input 	      external_l1a,
    input 	      external_spill, 
    output reg [87:0] evttag,
    output reg [15:0] fc_stream_enc,
    input 	      reset,
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

   parameter NUM_STS_WORDS = 9;
   wire [31:0] Status[NUM_STS_WORDS-1:0];

   assign DefaultCtlReg[0]=32'h0;
   assign DefaultCtlReg[1]=32'h0;
   assign DefaultCtlReg[2]={4'h0,4'h2,8'd20,4'h0,12'd45};
   assign DefaultCtlReg[3]={20'd1000,12'd320};
   
   wire [7:0]  calib_l1a_offset = Control[2][23:16];     
   wire [3:0]  calib_pulse_len = Control[2][27:24];
   wire [11:0] orb_length = Control[2][11:0];
   wire [11:0] l1a_veto_len = Control[3][11:0];
   wire [19:0] periodic_time = Control[3][31:12];
   
   
   wire        send_l1a_sw_io = Control[1][0];
   wire        send_link_reset_io = Control[1][1];
   wire        send_buffer_clear_io = Control[1][2];
   wire        send_calib_pulse_io = Control[1][3];
   wire        fifo_clear_io = Control[1][4];   
   wire        newspill_io = Control[1][8];

   wire        enable_external_l1a = Control[0][1];
   wire        enable_external_spill = Control[0][0];
   wire        enable_timer_l1a = Control[0][2];
      

   wire        send_l1a_sw, send_link_reset, send_buffer_clear, send_calib_pulse;
   reg 	       calib_l1a, veto_l1a, timer_l1a;
   
   SinglePulseDualClock spdc_l1a_sw(.i(send_l1a_sw_io),.o(send_l1a_sw),.oclk(clk_bx));
   SinglePulseDualClock spdc_link_reset(.i(send_link_reset_io),.o(send_link_reset),.oclk(clk_bx));
   SinglePulseDualClock spdc_buffer_clear(.i(send_buffer_clear_io),.o(send_buffer_clear),.oclk(clk_bx));
   SinglePulseDualClock spdc_calib_pulse(.i(send_calib_pulse_io),.o(send_calib_pulse),.oclk(clk_bx));
   SinglePulseDualClock spdc_l1a_sw(.i(send_l1a_sw_io),.o(send_l1a_sw),.oclk(clk_bx));
   
   SinglePulseDualClock spdc_l1a_ext(.i(external_l1a && enable_external_l1a),.o(send_l1a_ext),.oclk(clk_bx));

 
   reg [11:0]  bx_counter;
   
   always @(posedge clk_bx) begin
      if ((bx_counter+12'h1)==orb_length) bx_counter<=12'h0;
      else bx_counter<=bx_counter+12'h1;
   end

   reg [7:0] calib_l1a_delay, calib_pulse_ext;
   always @(posedge clk_bx) begin
      if (send_calib_pulse) calib_pulse_ext<=calib_pulse_len;
      else if (calib_pulse_ext!=4'h0) calib_pulse_ext<=calib_pulse_ext-4'h1;
      
      if (send_calib_pulse) calib_l1a_delay<=calib_l1a_offset;
      else if (calib_l1a_delay!=8'h0) calib_l1a_delay<=calib_l1a_delay-8'h1;
      else calib_l1a_delay<=8'h0;
      calib_l1a<=(calib_l1a_delay==8'h1);
   end

   reg [5:0] timer_prescale;
   reg [19:0] timer_counter;
      
   always @(posedge clk_bx) begin
      if (timer_prescale==6'd39 || fifo_reset) timer_prescale<=6'h0;
      else timer_prescale<=timer_prescale+6'h1;

      if (reset || !enable_timer_l1a) timer_counter<=20'h0;
      else if (timer_counter==20'h0) timer_counter<=periodic_time;
      else if (timer_prescale==6'h0) timer_counter<=timer_counter-20'h1;
      else timer_counter<=timer_counter;

      timer_l1a<=(timer_counter==20'h1) && (timer_prescale==6'h1); // single pulse at 40 MHz      
   end
   
   reg [11:0] veto_downcounter;
   reg [11:0] vetoed_counter;
   
   always @(posedge clk_bx) begin
      veto_l1a<=fc_word[1] || (veto_downcounter!=12'h0);
      if (fc_word[1]) veto_downcounter<=l1a_veto_len;
      else if (veto_downcounter!=12'h0) veto_downcounter<=veto_downcounter-12'h1;
      else veto_downcounter<=veto_downcounter;

      if (fifo_clear) vetoed_counter<=12'h0;
      else if (((send_l1a_sw)||(calib_l1a)||(timer_l1a)||(send_l1a_ext)) && veto_l1a) vetoed_counter<=vetoed_counter+12'h1;
      else vetoed_counter<=vetoed_counter;
            
   end
	
   reg [7:0] fc_word;
   always @(posedge clk_bx) begin
      fc_word[0]<=(bx_counter=='h0);
      fc_word[1]<=((send_l1a_sw)||(calib_l1a)||(timer_l1a)||(send_l1a_ext)) && !veto_l1a;
      fc_word[2]<=(send_link_reset);
      fc_word[3]<=(send_buffer_clear);
      fc_word[4]<=1'h0; 
      fc_word[5]<=send_calib_pulse || (calib_pulse_ext!=4'h0);
      fc_word[7:6]<=2'h0; 
   end
   
   wire [15:0] fc_word_enc_i;
   hamming84_enc enc_lo(.data_in(fc_word[3:0]),.enc_out(fc_word_enc_i[7:0]));
   hamming84_enc enc_hi(.data_in(fc_word[7:4]),.enc_out(fc_word_enc_i[15:8]));
   
   always @(posedge clk_bx) fc_stream_enc<=fc_word_enc_i;

   wire [7:0] header_occupancy;
   wire [31:0] event_count;
   wire [11:0] spill_count;
   wire [31:0] tag_evtid;
   wire [31:0] tag_timeinspill;
   wire [11:0] tag_spill;
   wire [11:0] tag_bxid;

   always @(posedge axi_clk)
     evttag<={tag_evtid,tag_timeinspill,tag_spill,tag_bxid};

   wire        tagdone_40, newspill_40, fifo_clear;
   
   SinglePulseDualClock spdc_spill_ext(.i(external_spill && enable_external_spill),.o(send_l1a_sw),.oclk(clk_bx));

   SinglePulseDualClock spdc_done(.i(tagdone),.o(tagdone_40),.oclk(clk_bx));
   SinglePulseDualClock spdc_spill(.i(newspill_io||enable_external_spill),.o(newspill_40),.oclk(clk_bx));   
   SinglePulseDualClock spdc_fifo_clear(.i(reset || fifo_clear_io),.o(fifo_clear),.oclk(clk_bx));   
      
l1_header_fifo header_fifo(.bx_clk(clk_bx),
			   .reset(fifo_clear),
			   .l1a(fc_word[1]),
			   .newspill(newspill_40),
			   .clk125(clk125),
			   .advance(tagdone_40),
			   .bxid(bx_counter),
			   .occupancy(header_occupancy),
			   .evtid(event_count),
			   .spill(spill_count),
			   .tag_evtid(tag_evtid),
			   .tag_timeinspill(tag_timeinspill),
			   .tag_spill(tag_spill),
			   .tag_bxid(tag_bxid)
			   );
   
   
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
     else if (axi_raddr[7:6]==2'h1) axi_dout<=Status[axi_raddr[3:0]];
     else axi_dout<=32'h0;

   assign Status[0]=32'habcd0001;
   assign Status[1]=32'h00000010;

   clkRateTool clkm125(.reset_in(reset),.clk125(clk125),.clktest(clk125),.value(Status[2]));
   clkRateTool clkmrefd2(.reset_in(reset),.clk125(clk125),.clktest(clk_refd2),.value(Status[3]));
   
   assign Status[4]={4'h0,spill_count, 8'h0,header_occupancy};
   assign Status[5]=event_count;
   assign Status[6]=tag_evtid;
   assign Status[7]=tag_timeinspill;
   assign Status[8]={4'h0,tag_spill,4'h0,tag_bxid};
   assign Status[9]={20'h0,vetoed_counter};   
  
   
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

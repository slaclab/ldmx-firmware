`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:24:38 08/28/2021 
// Design Name: 
// Module Name:    ldmx_daq 
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
module ldmx_daq(
		input 	      clk_link,
		input [31:0]  link_data,
		input [3:0]   link_is_k,
		input 	      link_valid,
		input 	      reset,
		input 	      dma_clk,
		input 	      dma_ready,
		output 	      dma_valid,
		output [63:0] dma_data,
		output 	      dma_done,
		input 	      axi_clk,
		input 	      axi_wstr,
		input 	      axi_rstr,
		output 	      axi_wack,
		output 	      axi_rack,
		input [11:0]  axi_raddr,
		input [11:0]  axi_waddr,
		input [31:0]  axi_din,
		output [31:0] axi_dout
		);
   
	reg reset_io;
	
	always @(posedge axi_clk) reset_io<=reset;

   // Command registers
   localparam NUM_CMD_WORDS = 8;
   reg [31:0] Command[NUM_CMD_WORDS-1:0];

   // Status registers
   localparam NUM_STS_WORDS = 8;
   wire [31:0] Status[NUM_STS_WORDS-1:0];
	
   // page_size=0 -> 512 word pages (good up to 6 HGCROCs)
   // page_size=1 -> 1024 word pages (good up to 12 HGCROCs)
   // page_size=2 -> 2048 word pages (good up to 24 HGCROCs)
   wire [1:0]  page_size_io; 
   wire        clear;
   reg [1:0]   page_size_link, page_size;
   wire        peek_lengths;
   wire        advance_read;
   wire        enable_dma_io;
   
   
   assign page_size_io=Command[0][1:0];
   assign enable_dma_io=Command[0][4];
   
   assign reset_daq_io=Command[1][0] || reset_io;
   assign advance_read=Command[1][1];

   localparam MAX_LOG2_BUFCOUNT = 6-1;
      
   reg [MAX_LOG2_BUFCOUNT:0] w_buf_id, next_w_buf_id;
   reg [MAX_LOG2_BUFCOUNT:0] r_buf_id;
   wire [MAX_LOG2_BUFCOUNT:0] dma_buf_id;   
   wire 		     full;
   wire 		     reset_daq;
   
	
   SinglePulseDualClock spdc_reset_daq(.i(reset_daq_io),.o(reset_daq),.oclk(clk_link));
	
   wire [10:0] 		     w_ptr;
   reg [14:0] 		     write_addr;
   reg [31:0] 		     write_data;
	
   wire 		     write_enable_i;
   reg 			     write_enable;
   wire 		     is_end_of_event;
   wire [31:0] 		     link_data_d;
   wire [10:0] 		     read_buffer_lengths;
   reg [8:0] 		     buf_len_read_which;
	
   always @(posedge dma_clk)
     if (enable_dma) buf_len_read_which<=dma_buf_id;
     else if (peek_lengths) buf_len_read_which<=axi_raddr[8:0];
     else buf_len_read_which<=r_buf_id;
   
   daq_write_manager write_manager(.reset(reset_daq),.clk(clk_link),
				   .link_data(link_data),.link_is_k(link_is_k),.link_valid(link_valid),
				   .w_buf_id(w_buf_id),
				   .w_ptr(w_ptr),.data_to_mem(link_data_d),.mem_we(write_enable_i),
				   .end_of_event(is_end_of_event),
				   .clk_io(dma_clk),.w_buf_sel(buf_len_read_which),
				   .w_buf_len(read_buffer_lengths));
   
   assign full=(next_w_buf_id==r_buf_id);
   
   always @(posedge clk_link) begin
      if (reset_daq) w_buf_id<='h0;
      else if (is_end_of_event && !full) w_buf_id<=next_w_buf_id;
      else w_buf_id<=w_buf_id;

      if (page_size_link==2'h0) next_w_buf_id<=w_buf_id+6'h1; // simple sum...
      else if (page_size_link==2'h1) begin 
	 next_w_buf_id[5]<=1'h0;
	 next_w_buf_id[4:0]<=w_buf_id[4:0]+5'h1; // only incrementing the lower bits
      end else begin
	 next_w_buf_id[5:4]<=2'h0;
	 next_w_buf_id[3:0]<=w_buf_id[3:0]+4'h1; // only incrementing the lower bits
      end	
   end

   reg empty, was_advance;
   reg [8:0] nevents;
	
   always @(posedge axi_clk) begin
      empty<=(w_buf_id==r_buf_id);
      nevents<=(w_buf_id-r_buf_id);
      was_advance<=advance_read;
      if (reset_daq_io) r_buf_id<=6'h0;
      else if (~advance_read && was_advance) begin
	 if (page_size_link==2'h0) r_buf_id<=r_buf_id+6'h1; // simple sum...
	 else if (page_size_link==2'h1) begin 
	    r_buf_id[5]<=1'h0;
	    r_buf_id[4:0]<=r_buf_id[4:0]+5'h1; // only incrementing the lower bits
	 end else begin
	    r_buf_id[5:4]<=2'h0;
	    r_buf_id[3:0]<=r_buf_id[3:0]+4'h1; // only incrementing the lower bits
	 end	
      end else r_buf_id<=r_buf_id;
   end
	
   always @(posedge clk_link) begin
      page_size_link<=page_size_io;
      if (page_size_link==2'h0) write_addr<={w_buf_id,w_ptr[8:0]};
      else if (page_size_link==2'h1) write_addr<={w_buf_id[4:0],w_ptr[9:0]};
      else write_addr<={w_buf_id[3:0],w_ptr[10:0]};
      write_enable<=write_enable_i;
      write_data<=link_data_d;
   end

   wire [31:0] read_data_32;
   wire [63:0] read_data_64;
   reg 	       reset_clk_dma;
   wire [10:0] dma_ptr;
   wire        dma_done_with_buffer;     
   
   daq_dma_manager daq_dma(.reset(reset_clk_dma),
			   .enable(enable_dma),
			   .clk(dma_clk),
			   .bundle_trigcount_async(l1a_bundle_factor),
			   .nreadouts_available_async(nevents),
			   .r_buf_id(r_buf_id),
			   .pick_buf_id(dma_buf_id),
			   .buf_len(read_buffer_lengths),
			   .fpga_id(),
			   .r_ptr(dma_ptr),
			   .data_from_buffer(read_data_64),
			   .dma_data(dma_data),
			   .dma_valid(dma_valid),
			   .dma_last(dma_done),
			   .done_with_buffer(dma_done_with_buffer),
			   .dma_ready(dma_ready),
			   .status(dma_status)
			   );

   reg [5:0]   r_buf_addr_overlay;
   reg [10:0]  axi_raddr_latch;
   reg 	       enable_dma;
   
         	
   always @(posedge dma_clk) begin
      reset_clk_dma<=reset;
      enable_dma<=enable_dma_io;
      
            
      page_size<=page_size_io;
      axi_raddr_latch<=axi_raddr;

      if (enable_dma) begin
	 if (page_size==2'h0) r_buf_addr_overlay<={dma_buf_id};
	 else if (page_size==2'h1) r_buf_addr_overlay<={dma_buf_id[4:0],1'h0};      
	 else r_buf_addr_overlay<={dma_buf_id[3:0],2'h0};
      end else begin
	 if (page_size==2'h0) r_buf_addr_overlay<={r_buf_id};
	 else if (page_size==2'h1) r_buf_addr_overlay<={r_buf_id[4:0],1'h0};      
	 else r_buf_addr_overlay<={r_buf_id[3:0],2'h0};
      end
   end

   wire [14:0] read_addr;
   assign read_addr[14:11]=r_buf_addr_overlay[5:2];
   assign read_addr[10:9]=(enable_dma)?(r_buf_addr_overlay[1:0]|dma_ptr[10:9]):(r_buf_addr_overlay[1:0]|axi_raddr_latch[10:9]);
   assign read_addr[8:0]=(enable_dma)?(dma_ptr[8:0]):(axi_raddr_latch[8:0]);   
	
   daq_buffer buffer(
		     .clka(clk_link),
		     .wea(write_enable),
		     .addra(write_addr),
		     .dina(write_data),
		     .clkb(dma_clk),
		     .addrb(read_addr),
		     .doutb(read_data_32),
		     .doutb64(read_data_64));
   

  //=========================================================================
   // axi interface.
   //=========================================================================

   reg [31:0] data_out;
   wire       write;
      
   genvar z; 
   generate for (z=0; z<NUM_CMD_WORDS; z=z+1) begin: gen_write
      always @(posedge axi_clk) begin
	 if (reset_io == 1) Command[z] <= 32'h0;
	 else if ((write == 1) && (axi_waddr == z)) Command[z] <= axi_din;
	 else begin
	    if (z==1) Command[z]<=32'h0;
	    else Command[z] <= Command[z];
	 end
      end
      
   end endgenerate   

   always @(posedge axi_clk)
     if (!axi_rstr) data_out<=32'h0;
     else if (axi_raddr[11:6]==6'h0 && axi_raddr[5:3]==3'h0) data_out<=Command[axi_raddr[2:0]];
     else if (axi_raddr[11:6]==6'h1 && axi_raddr[5:3]==3'h0) data_out<=Status[axi_raddr[2:0]];
     else if (axi_raddr[11:10]==2'b01) data_out<={21'h0,read_buffer_lengths};
     else if (axi_raddr[11]) data_out<=read_data_32;
     else data_out<=32'h0;
	
   assign axi_dout=data_out;

   assign Status[0]={8'h1,8'd32,8'd32,8'h01};   
   assign Status[1]={5'h0,read_buffer_lengths,3'h0,nevents,2'h0,full,empty};
   assign Status[2]={7'h0,r_buf_id,7'h0,w_buf_id};

   assign peek_lengths=(axi_raddr[11:10]==2'b01);    

   reg [2:0]  wack_delay;
   always @(posedge axi_clk)
     if (!axi_wstr) wack_delay<=3'h0;
     else wack_delay<={wack_delay[1:0],axi_wstr};
   assign write=wack_delay[1]&&!wack_delay[2];
   assign axi_wack=wack_delay[2];
   
   reg [3:0]  rack_delay;     
   always @(posedge axi_clk)
     if (!axi_rstr) rack_delay<=4'h0;
     else rack_delay<={rack_delay[2:0],axi_rstr};
   assign axi_rack=rack_delay[3];
   	

	


endmodule

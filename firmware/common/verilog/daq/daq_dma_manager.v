/**
 State machine does the following:
 (a) waits until enough readouts are available to bundle to make a full L1A
 (b) loops through readout length information to create header (padding to 64-bit words)
 (c) transmits header
 (d) transmits data from daq buffer, releasing buffers one by one as they are transmitted
 */
module daq_dma_manager (
         input reset,
			input clk,
			input enable,
			input [3:0]  bundle_trigcount_async, // how many readouts to bundle for an L1A
			input [8:0]  nreadouts_available_async,
			input [5:0]  r_buf_id, // what is the current read buffer base pointer
			output reg [5:0] pick_buf_id,
			input [9:0]  buf_len,
			input [7:0] fpga_id,
			output reg [9:0] r_ptr,
			input [63:0] data_from_buffer,
			output [63:0] dma_data,
			output dma_valid,
			output dma_last,
			output reg done_with_buffer,
			input dma_ready, 
			output reg [11:0] status
			);

   localparam FormatVersion = 4'h2;

   reg [63:0] 			     header [4:0];
   reg [3:0] 			     bundle_trigcount;   
   reg 				     ready_to_build;   
   reg [3:0] 			     state;
	wire [8:0]             buffer_space;

   reg [3:0] 			     pick_trig_count;
   

   localparam ST_IDLE                   = 4'h0;
   localparam ST_SPACE                  = 4'h1;
   localparam ST_LEN_PREP               = 4'h2;
   localparam ST_LEN_WAIT               = 4'h3;
   localparam ST_LEN_STORE              = 4'h4;
   localparam ST_COPY_HEADER            = 4'h5;
   localparam ST_NEXT_BUFFER            = 4'h6;
   localparam ST_NEXT_BUFFER_SPACE      = 4'h7;
   localparam ST_NEXT_BUFFER_SPACE_WAIT = 4'h8;
   localparam ST_NEXT_BUFFER_SPACE_WAIT2= 4'h9;
   localparam ST_NEXT_BUFFER_WAIT       = 4'ha;
   localparam ST_NEXT_BUFFER_WAIT2      = 4'hb;
   localparam ST_FIRST_BUFFER           = 4'hc;
   localparam ST_COPY                   = 4'hd;
   localparam ST_DONE                   = 4'hf;

	reg on_last_buffer;
	reg space_available;

always @(posedge clk)
  if (reset || !enable) state<=ST_IDLE;
  else if (state==ST_IDLE && ready_to_build) state<=ST_SPACE;
  else if (state==ST_SPACE && space_available) state<=ST_LEN_PREP;
  else if (state==ST_LEN_PREP) state<=ST_LEN_WAIT;
  else if (state==ST_LEN_WAIT) state<=ST_LEN_STORE;
  else if (state==ST_LEN_STORE) begin
     if ((pick_trig_count+4'h1)==bundle_trigcount) state<=ST_COPY_HEADER;
     else state<=ST_LEN_PREP;
  end 
  else if (state==ST_COPY_HEADER) begin
     if (r_ptr==9'h4) state<=ST_FIRST_BUFFER;
     else state<=ST_COPY_HEADER;     
  end else if (state==ST_COPY) begin
     if (r_ptr[9:1]==(buf_len[9:1]+buf_len[0]) && on_last_buffer) state<=ST_DONE;
	  else if (r_ptr[9:1]==(buf_len[9:1]+buf_len[0])) state<=ST_NEXT_BUFFER;
	  else state<=ST_COPY;
  end else if (state==ST_FIRST_BUFFER && space_available) state<=ST_NEXT_BUFFER_WAIT;
  else if (state==ST_NEXT_BUFFER) state<=ST_NEXT_BUFFER_SPACE_WAIT;
  else if (state==ST_NEXT_BUFFER_SPACE_WAIT) state<=ST_NEXT_BUFFER_SPACE_WAIT2;
  else if (state==ST_NEXT_BUFFER_SPACE_WAIT2) state<=ST_NEXT_BUFFER_SPACE;
  else if (state==ST_NEXT_BUFFER_SPACE && space_available) state<=ST_NEXT_BUFFER_WAIT;
  else if (state==ST_NEXT_BUFFER_WAIT) state<=ST_NEXT_BUFFER_WAIT2;
  else if (state==ST_NEXT_BUFFER_WAIT2) state<=ST_COPY;    
  else if (state==ST_DONE) state<=ST_IDLE;    
  else begin
     state<=state;
  end

always @(posedge clk)
  if (state==ST_IDLE) on_last_buffer<=1'h0;
  else if (state==ST_NEXT_BUFFER_WAIT && (pick_trig_count+4'h1==bundle_trigcount)) on_last_buffer<=1'h1;
  else on_last_buffer<=on_last_buffer;

   // capturing the buffer lengths
always @(posedge clk) begin
   header[0][31:0]<=32'hbeef2022;
   header[0][63:60]<=FormatVersion;
   header[0][59:52]<=fpga_id;
   header[0][51:48]<=bundle_trigcount;
   
   if (state==ST_IDLE) header[0][47:32]<=16'h5;
   else if (state==ST_LEN_STORE) header[0][47:32]<=header[0][47:32]+buf_len[9:1]+buf_len[0]; // counting 64-bit words to have enough space (also subpacket packing)
   else header[0][47:32]<=header[0][47:32];  

   if (state==ST_IDLE) header[1]<=64'h0;
   else begin
      if (state==ST_LEN_STORE && pick_trig_count==4'h0) header[1][15:0]<={4'h0,buf_len};
      if (state==ST_LEN_STORE && pick_trig_count==4'h1) header[1][31:16]<={4'h0,buf_len};
      if (state==ST_LEN_STORE && pick_trig_count==4'h2) header[1][47:32]<={4'h0,buf_len};
      if (state==ST_LEN_STORE && pick_trig_count==4'h3) header[1][63:48]<={4'h0,buf_len};
   end
   if (state==ST_IDLE) header[2]<=64'h0;
   else begin
      if (state==ST_LEN_STORE && pick_trig_count==4'h4) header[2][15:0]<={4'h0,buf_len};
      if (state==ST_LEN_STORE && pick_trig_count==4'h5) header[2][31:16]<={4'h0,buf_len};
      if (state==ST_LEN_STORE && pick_trig_count==4'h6) header[2][47:32]<={4'h0,buf_len};
      if (state==ST_LEN_STORE && pick_trig_count==4'h7) header[2][63:48]<={4'h0,buf_len};
   end
   if (state==ST_IDLE) header[3]<=64'h0;
   else begin
      if (state==ST_LEN_STORE && pick_trig_count==4'h8) header[3][15:0]<={4'h0,buf_len};
      if (state==ST_LEN_STORE && pick_trig_count==4'h9) header[3][31:16]<={4'h0,buf_len};
      if (state==ST_LEN_STORE && pick_trig_count==4'ha) header[3][47:32]<={4'h0,buf_len};
      if (state==ST_LEN_STORE && pick_trig_count==4'hb) header[3][63:48]<={4'h0,buf_len};
   end
   if (state==ST_IDLE) header[4]<=64'h0;
   else begin
      if (state==ST_LEN_STORE && pick_trig_count==4'hc) header[4][15:0]<={4'h0,buf_len};
      if (state==ST_LEN_STORE && pick_trig_count==4'hd) header[4][31:16]<={4'h0,buf_len};
      if (state==ST_LEN_STORE && pick_trig_count==4'he) header[4][47:32]<={4'h0,buf_len};
      if (state==ST_LEN_STORE && pick_trig_count==4'hf) header[4][63:48]<={4'h0,buf_len};
   end
  end

   
   reg [63:0] data_to_fifo;
   reg 	      fifo_we;
	reg lastSample;

   always @(posedge clk) begin      
      if (state==ST_COPY_HEADER) begin 
	 data_to_fifo<=header[r_ptr[2:0]];
      end
      else if ((state==ST_NEXT_BUFFER || state==ST_DONE) && buf_len[0]) data_to_fifo<={32'h0,data_from_buffer[31:0]};
      else data_to_fifo<=data_from_buffer;

      fifo_we<=(state==ST_COPY_HEADER || state==ST_COPY || state==ST_NEXT_BUFFER || state==ST_DONE);
      lastSample<=(state==ST_DONE);
      done_with_buffer<=(state==ST_NEXT_BUFFER || state==ST_DONE);
   end

   always @(posedge clk) begin
      if (state==ST_IDLE || state==ST_NEXT_BUFFER || state==ST_FIRST_BUFFER) r_ptr<=9'h0;
      else if (state==ST_COPY_HEADER) r_ptr<=r_ptr+9'h1;
      else if (state==ST_COPY_HEADER || state==ST_COPY || state==ST_NEXT_BUFFER_WAIT || state==ST_NEXT_BUFFER_WAIT2) r_ptr<=r_ptr+9'h2;
      else r_ptr<=r_ptr;
   end 
        
always @(posedge clk) begin
   if (state==ST_IDLE || state==ST_COPY_HEADER) begin
      pick_trig_count<=4'h0;
      pick_buf_id<=r_buf_id;
   end else if (state==ST_LEN_STORE || state==ST_NEXT_BUFFER) begin
      pick_trig_count<=pick_trig_count+4'h1;
      pick_buf_id<=pick_buf_id+6'h1;
   end	
end

always @(posedge clk) begin
  if (state==ST_SPACE || state==ST_IDLE) space_available<=(buffer_space>9'd5); // need a header's worth of space
  else if (state==ST_FIRST_BUFFER || state==ST_NEXT_BUFFER_SPACE) space_available<=(buffer_space>=buf_len);
  else if (state==ST_NEXT_BUFFER || state==ST_LEN_PREP) space_available<=1'h0;
  else space_available<=space_available;
end

   reg [8:0] 			     nreadouts_available;
	     
always @(posedge clk) begin
   nreadouts_available<=nreadouts_available_async;
   bundle_trigcount<=(bundle_trigcount_async==4'h0)?(4'h1):(bundle_trigcount_async);   
   ready_to_build<=(nreadouts_available>=bundle_trigcount);   
end

	wire dma_last_i;
	assign dma_last=dma_last_i && dma_valid;

dma_fifo theFifo(.clk(clk),
    .din({lastSample,data_to_fifo}),
    .dout({dma_last_i,dma_data}),
	 .free_space(buffer_space),
	 .reset(reset || !enable),
	 .we(fifo_we),
	 .valid(dma_valid),
	 .ready(dma_ready));

always @(posedge clk)
   status<={pick_trig_count,1'h0,space_available,dma_valid, dma_ready, state};
  
   
endmodule // daq_dma_manager

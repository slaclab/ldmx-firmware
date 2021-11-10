/**
 State machine does the following:
 (a) waits until enough readouts are available to bundle to make a full L1A
 (b) loops through readout length information to create header (padding to 64-bit words)
 (c) transmits header
 (d) transmits data from daq buffer, releasing buffers one by one as they are transmitted
 */
module daq_dma_manager (
			input 	     clk,
			input [3:0]  bundle_trigcount_async, // how many readouts to bundle for an L1A
			input [8:0]  nreadouts_available_async,
			input [5:0]  r_buf_id, // what is the current read buffer base pointer
			output reg [5:0] check_buf_id,
			input [9:0]  buf_len,
			output [63:0] data_dma,
			output dma_valid,
			input dma_ready
			);


   reg [63:0] 			     header [4:0];
   reg [3:0] 			     bundle_trigcount;   
   reg 				     ready_to_build;   
   reg [4:0] 			     state;

   reg [3:0] 			     pick_trig_count;
   reg [9:0] 			     ptr;
   

   localparam ST_IDLE              = 5'h0;
   localparam ST_LEN_PREP          = 5'h1;
   localparam ST_LEN_WAIT          = 5'h2;
   localparam ST_LEN_STORE         = 5'h3;
   localparam ST_COPY_HEADER       = 5'h4;
   localparam ST_COPY_PREP         = 5'h5;
   

always @(posedge clk)
  if (reset) state<=ST_IDLE;
  else if (state==ST_IDLE && ready_to_build) state<=ST_LEN_PREP;
  else if (state==ST_LEN_PREP) state<=ST_LEN_WAIT;
  else if (state==ST_LEN_WAIT) state<=ST_LEN_STORE;
  else if (state==ST_LEN_STORE) begin
     if ((pick_trig_count+4'h1)==bundle_trigcount) state<=ST_COPY_HEADER;
     else state<=ST_LEN_PREP;
  end 
  else if (state==ST_COPY_HEADER) begin
     if (ptr==9'h4) state<=ST_COPY_PREP;
     else state<=ST_COPY_HEADER;     
  end 
  else begin
     state<=state;
  end

   // capturing the buffer lengths
always @(posedge clk) begin
   header[0][31:0]<=32'hbeef2021;
   header[0][63:60]<=FormatVersion;
   header[0][59:52]<=fpga_id;
   header[0][51:48]<=bundle_trigcount;
   
   if (state==ST_IDLE) header[0][47:32]<=16'h5;
   else if (state==ST_LEN_STORE) header[0][47:32]<=header[0][47:32]+buf_len[9:1]+buf_len[0]; // counting 64-bit words
   else header[0][47:32]<=header[0][47:32];  

   if (state==ST_IDLE) header[1]<=64'h0;
   else begin
      if (state==ST_LEN_STORE && bundle_trigcount==4'h0) header[1][15:0]<={4'h0,buf_len};
      if (state==ST_LEN_STORE && bundle_trigcount==4'h1) header[1][31:16]<={4'h0,buf_len};
      if (state==ST_LEN_STORE && bundle_trigcount==4'h2) header[1][47:32]<={4'h0,buf_len};
      if (state==ST_LEN_STORE && bundle_trigcount==4'h3) header[1][63:48]<={4'h0,buf_len};
   end
   if (state==ST_IDLE) header[2]<=64'h0;
   else begin
      if (state==ST_LEN_STORE && bundle_trigcount==4'h4) header[2][15:0]<={4'h0,buf_len};
      if (state==ST_LEN_STORE && bundle_trigcount==4'h5) header[2][31:16]<={4'h0,buf_len};
      if (state==ST_LEN_STORE && bundle_trigcount==4'h6) header[2][47:32]<={4'h0,buf_len};
      if (state==ST_LEN_STORE && bundle_trigcount==4'h7) header[2][63:48]<={4'h0,buf_len};
   end
   if (state==ST_IDLE) header[3]<=64'h0;
   else begin
      if (state==ST_LEN_STORE && bundle_trigcount==4'h8) header[3][15:0]<={4'h0,buf_len};
      if (state==ST_LEN_STORE && bundle_trigcount==4'h9) header[3][31:16]<={4'h0,buf_len};
      if (state==ST_LEN_STORE && bundle_trigcount==4'ha) header[3][47:32]<={4'h0,buf_len};
      if (state==ST_LEN_STORE && bundle_trigcount==4'hb) header[3][63:48]<={4'h0,buf_len};
   end
   if (state==ST_IDLE) header[4]<=64'h0;
   else begin
      if (state==ST_LEN_STORE && bundle_trigcount==4'hc) header[4][15:0]<={4'h0,buf_len};
      if (state==ST_LEN_STORE && bundle_trigcount==4'hd) header[4][31:16]<={4'h0,buf_len};
      if (state==ST_LEN_STORE && bundle_trigcount==4'he) header[4][47:32]<={4'h0,buf_len};
      if (state==ST_LEN_STORE && bundle_trigcount==4'hf) header[4][63:48]<={4'h0,buf_len};
   end


   always @(posedge clk) begin
      if (state==ST_IDLE) ptr<=9'h0;
      else if (state==ST_COPY_HEADER) ptr<=ptr+9'h1;
      else ptr<=ptr;
      
   
   reg [63:0] data_to_fifo;
   reg 	      fifo_we;

   always @(posedge clk) begin      
      if (state==ST_COPY_HEADER) begin 
	 data_to_fifo<=header[ptr[2:0]];
      end

      fifo_we<=(state==ST_COPY_HEADER);
   end
      
  
   
   
always @(posedge clk) begin
   if (state==ST_IDLE) begin
      pick_trig_count<=4'h0;
      check_buf_id<=r_buf_id;
   end else if (state==ST_LEN_STORE) begin
      pick_trig_count<=pick_trig_count+4'h1;
      check_buf_id<=check_buf_id+6'h1;
   end
   

   reg [8:0] 			     nreadouts_available;
	  
   
always @(posedge clk) begin
   nreadouts_available<=nreadouts_available_async;
   bundle_trig_count<=(bundle_trigcount_async==4'h0)?(4'h1):(bundle_trigcount_async);   
   ready_to_build<=(nreadouts_available>bundle_trig_count);   
end

   wire empty, 

FIFO_SYNC_MACRO  #(
      .DEVICE("7SERIES"), // Target Device: "7SERIES" 
      .ALMOST_EMPTY_OFFSET(9'h010), // Sets the almost empty threshold
      .ALMOST_FULL_OFFSET(9'h080),  // Sets almost full threshold
      .DATA_WIDTH(64), // Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
      .DO_REG(1),     // Optional output register (0 or 1)
      .FIFO_SIZE ("36Kb")  // Target BRAM: "18Kb" or "36Kb" 
   ) FIFO_SYNC_MACRO_inst (
//      .ALMOSTEMPTY(ALMOSTEMPTY), // 1-bit output almost empty
//      .ALMOSTFULL(ALMOSTFULL),   // 1-bit output almost full
      .DO(data_dma),                   // Output data, width defined by DATA_WIDTH parameter
      .EMPTY(empty),             // 1-bit output empty
//      .FULL(FULL),               // 1-bit output full
      .CLK(clk),                 // 1-bit input clock
      .DI(data_to_fifo),                   // Input data, width defined by DATA_WIDTH parameter
      .RDEN(dma_rd),               // 1-bit input read enable
      .RST(1'h0),                 // 1-bit input reset
      .WREN(fifo_we)                // 1-bit input write enable
    );

   assign dma_valid=!empty;
   assign dma_rd=dma_valid && dma_ready;
   
   
endmodule // daq_dma_manager

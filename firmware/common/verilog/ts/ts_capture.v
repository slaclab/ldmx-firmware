module ts_capture(input clk_link,
		  input 	    rx_dv,
		  input [1:0] 	    rx_k,
		  input [15:0] 	    rx_d,
		  input 	    trigger, 
		  input [10:0] 	    offset,
		  input [7:0] 	    to_copy,
		  input 	    clk_work,
		  input 	    enable,
		  output reg [17:0] data_out,
		  output reg 	    data_valid,
		  output reg 	    done
		  );


   reg [17:0] 		       w_data_latch;
   reg [17:0] 		       w_data;
   reg 			       we, was_dv;   
   reg [10:0] 		       w_ptr;
   
   

// store the data, dropping any 
always @(posedge clk_link) begin
   w_data_latch<={rx_k,rx_d};
   w_data<=w_data_latch;
   was_dv<=rx_dv;
      
   if (reset_link) begin 
      w_ptr<=11'h0;
      we<=1'h0;
   end else if (!was_dv) begin
      w_ptr<=w_ptr;
      we<=1'h0;
   end else if (w_data_latch[17:16]==2'b00) begin
      w_ptr<=w_ptr+11'h1;
      we<=1'h1;
   end else if (w_data_latch[17:16]==2'b01 && w_data_latch[7:0]==8'bc) begin
      w_ptr<=w_ptr+11'h1;
      we<=1'h1;
   end else begin
      w_ptr<=w_ptr;
      we<=1'h0;
   end
end

   reg [10:0] r_base;
   wire       trigger_link, trigger_work;

   SinglePulseDualClock spdc_link(.i(trigger),.o(trigger_link),.oclk(clk_link));
   SinglePulseDualClock spdc_work(.i(trigger_link),.o(trigger_work),.oclk(clk_work));   

always @(posedge clk_link)
  if (trigger_link) r_base<=w_ptr;
  else r_base<=r_base;
   
   reg [3:0]  state;

   localparam ST_IDLE         = 4'h0;
   localparam ST_INIT         = 4'h1;   
   localparam ST_SEEK_FIRST   = 4'h1;
   localparam ST_SEEK_INC     = 4'h2;
   localparam ST_SEEK_WAIT    = 4'h3;
   localparam ST_SEEK_WAIT2   = 4'h4;
   localparam ST_START_COPY   = 4'h8;
   localparam ST_PRECOPY      = 4'h9;
   localparam ST_PRECOPY2     = 4'ha;
   localparam ST_COPY         = 4'hb;
    
   reg [7:0]  copied;
   wire [17:0] r_data;
   reg [10:0]  r_ptr;
   
   
     
always @(posedge clk_work)
  if (reset) state<=ST_IDLE;
  else if (state==ST_IDLE && trigger_work) state<=ST_INIT;
  else if (state==ST_INIT && enable) state<=ST_SEEK_WAIT;
  else if (state==ST_SEEK_FIRST) begin
     if (r_data[17:16]==2'b01) state<=ST_START_COPY;
     else state<=ST_SEEK_INC;
  end else if (state==ST_SEEK_INC) state<=ST_SEEK_WAIT;
  else if (state==ST_SEEK_WAIT) state<=ST_SEEK_WAIT2;
  else if (state==ST_SEEK_WAIT2) state<=ST_SEEK_FIRST;
  else if (state==ST_START_COPY) state<=ST_PRECOPY;
  else if (state==ST_PRECOPY) state<=ST_PRECOPY2;
  else if (state==ST_PRECOPY2) state<=ST_COPY;
  else if (state==ST_COPY) begin
     if (copied==to_copy) state<=ST_IDLE;
     else state<=ST_COPY;
  end

always @(posedge clk_work)   
  if (state==ST_STARTCOPY) copied<=8'h2; // correcting for offsets, delays
  else if (state==ST_COPY) copied<=copied+8'h1;
  else copied<=copied;
       
   
always @(posedge clk_work)
  if (state==ST_INIT) r_ptr<=r_base-offset;
  else if (state==ST_SEEK_INC) r_ptr<=r_ptr+11'h1;
  else if (state==ST_START_COPY || state==ST_PRECOPY || state==ST_PRECOPY2 || state==ST_COPY) r_ptr<=r_ptr+11'h1;
  else r_ptr<=rptr;

   always @(posedge clk_work) begin
      done<=(state==ST_IDLE);
      data_valid<=(state==ST_COPY);
      data_out<=r_data;
   end
     

        
ts_capture_buffer buffer(.w_data(w_data),.w_ptr(w_ptr),.w_clk(clk_link),.we(we),
			 .r_data(r_data),.r_ptr(r_ptr),.r_clk(clk_work));


endmodule

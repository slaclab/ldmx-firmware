`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////////////////////////////
module wb_bridge_axi(
    input 	      clk_link,
    //input 		     clkx,
    input 	      reset,
    output [15:0]     data_to_link,
    output [1:0]      k_to_link,
    input [31:0]      data_from_link,
    input [3:0]       k_from_link,
    input 	      link_valid,
    input [15:0]      fast_control_encoded,
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

   // Control registers
   localparam NUM_CMD_WORDS = 4;
   reg [31:0] Command[NUM_CMD_WORDS-1:0];

   // readonly status starts at 0x40
   localparam NUM_STS_WORDS = 4;
   wire [31:0] Status[NUM_STS_WORDS-1:0];
   wire        write;


// need to add firmware to handle 16-bit-halfword issue

   wire        wb_err, wb_ack, uplink_crc_err, downlink_crc_err;
   reg 	       wb_str;
   wire        recover_wb;
   wire [31:0] wb_dati;

   wb_master_be master(.clklink(clk_link),
		       .reset(reset),
		       .optical_data_out(data_to_link),
		       .optical_data_kout(k_to_link),
		       .optical_data_in(data_from_link),
		       .optical_data_kin(k_from_link),
		       .optical_data_valid(link_valid),
		       .encoded_fastcontrol(fast_control_encoded), 
		       .wb_reset(Command[2][29]),
		       .wb_we(wb_str && Command[2][28]),
		       .wb_dato(Command[3]),
		       .wb_addr(Command[2][17:0]),
		       .wb_target(Command[2][24:20]),
		       .wb_str(wb_str),
		       .wb_cyc(wb_str),
		       .wb_err(wb_err),
		       .wb_ack(wb_ack),
		       .wb_dati(wb_dati),
		       .downlink_crc_err(downlink_crc_err),
		       .uplink_crc_err(uplink_crc_err),
		       .crc_bypass(Command[0][4])
		       );

   wire        count_clear;

   SinglePulseDualClock spdc_start(.i(Command[1][0]),.o(start_cyc),.oclk(clk_link));
   SinglePulseDualClock spdc_recover(.i(Command[1][1]),.o(recover_wb),.oclk(clk_link));
   SinglePulseDualClock spdc_countclear(.i(Command[1][2]),.o(count_clear),.oclk(clk_link));
   reg 	       wb_done;

   always @(posedge clk_link)
     if (reset || Command[2][29] || recover_wb) begin 
	wb_str<=1'h0;
	wb_done<=1'h0;
     end else if (~wb_str && start_cyc) begin
	wb_str<=1'h1;
	wb_done<=1'h0;
     end
     else if (wb_ack) begin
	wb_str<=1'h0;
	wb_done<=1'h1;
     end
     else begin 
	wb_str<=wb_str;
	wb_done<=wb_done;
     end
   
   reg [11:0] duration;
   
   always @(posedge clk_link)
     if (start_cyc) duration<=12'h0;
     else duration<=duration+wb_str;
   
   reg [17:0] downlink_crc_err_counter, uplink_crc_err_counter, wb_err_counter; // should be always a multiple of 4 at least...
   
   always @(posedge clk_link) 
     if (reset || count_clear) downlink_crc_err_counter<=18'h0;
     else downlink_crc_err_counter<=downlink_crc_err_counter+downlink_crc_err;
   
   always @(posedge clk_link) 
     if (reset || count_clear) uplink_crc_err_counter<=18'h0;
     else uplink_crc_err_counter<=uplink_crc_err_counter+uplink_crc_err;
   
   always @(posedge clk_link) 
     if (reset || count_clear) wb_err_counter<=18'h0;
     else wb_err_counter<=wb_err_counter+wb_err;
   
   reg [31:0] wb_read_latch;
   always @(posedge clk_link)
     if (wb_ack) wb_read_latch<=wb_dati;
     else wb_read_latch<=wb_read_latch;
   
   wire [31:0] data_out;
   reg 	       reset_io;

   always @(posedge axi_clk)
     reset_io<=reset;
   
 
   
   genvar j1;
   generate for (j1=0; j1<NUM_CMD_WORDS; j1=j1+1) begin: gen_j1
      always @(posedge axi_clk) begin
	 if (reset_io == 1) Command[j1]<=32'h0;
	 else if ((write==1)&&(axi_waddr==(j1))) Command[j1] <= axi_din;
	 else if (j1==1) Command[j1]<=32'h0; // automatically clear
	 else Command[j1] <= Command[j1];
      end
   end endgenerate


   always @(posedge axi_clk)
     if (!axi_rstr) axi_dout<=32'h0;
     else if (axi_raddr[7:6]==2'h0 && axi_raddr[5:2]==4'h0) axi_dout<=Command[axi_raddr[1:0]];
     else if (axi_raddr[7:6]==2'h1 && axi_raddr[5:2]==4'h0) axi_dout<=Status[axi_raddr[1:0]];
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
   
   assign Status[0]={4'h0,duration,12'h0,2'h0,wb_done, wb_str};
   assign Status[1]=wb_read_latch;
   assign Status[2]={uplink_crc_err_counter[17:2], downlink_crc_err_counter[17:2]};
   assign Status[3]={16'h0, wb_err_counter[17:2]};
	
endmodule

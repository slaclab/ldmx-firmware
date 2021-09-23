`timescale 1ns / 1ps
`include "../ADDR_MAP.v"

//////////////////////////////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////////////////////////////
module wb_bridge(
    input 		     clk4x,
    //input 		     clkx,
    input 		     reset,
	 output [15:0]   data_to_link,
	 output [1:0] k_to_link,
	 input [31:0] data_from_link,
	 input [3:0] k_from_link,
	 input link_valid,
	 input [15:0] fast_control_encoded,
    input 		     reset_IPbus_clk,
    input 		     IPbus_clk,
    input 		     IPbus_strobe,
    input 		     IPbus_write,
    output 		     IPbus_ack,
    input [`MSB_wb_bridge:0] IPbus_addr,
    input [31:0] 	     IPbus_DataIn,
    output [31:0] 	     IPbus_DataOut	 
    );

   // Control registers
   localparam NUM_CMD_WORDS = 4;
   reg [31:0] Command[NUM_CMD_WORDS-1:0];

	// readonly status starts at 0x40
   localparam NUM_STS_WORDS = 4;
   wire [31:0] Status[NUM_STS_WORDS-1:0];
	wire write;


// need to add firmware to handle 16-bit-halfword issue

	wire wb_err, wb_ack, uplink_crc_err, downlink_crc_err;
	reg wb_str;
	wire recover_wb;
	wire [31:0] wb_dati;

   wb_master_be master(.clklink(clk4x),
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

	wire count_clear;

	SinglePulseDualClock spdc_start(.i(Command[1][0]),.o(start_cyc),.oclk(clk4x));
	SinglePulseDualClock spdc_recover(.i(Command[1][1]),.o(recover_wb),.oclk(clk4x));
	SinglePulseDualClock spdc_countclear(.i(Command[1][2]),.o(count_clear),.oclk(clk4x));
	reg wb_done;

	always @(posedge clk4x)
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
	
	always @(posedge clk4x)
		if (start_cyc) duration<=12'h0;
		else duration<=duration+wb_str;

   reg [17:0] downlink_crc_err_counter, uplink_crc_err_counter, wb_err_counter; // should be always a multiple of 4 at least...

	always @(posedge clk4x) 
		if (reset || count_clear) downlink_crc_err_counter<=18'h0;
		else downlink_crc_err_counter<=downlink_crc_err_counter+downlink_crc_err;

	always @(posedge clk4x) 
		if (reset || count_clear) uplink_crc_err_counter<=18'h0;
		else uplink_crc_err_counter<=uplink_crc_err_counter+uplink_crc_err;
		
	always @(posedge clk4x) 
		if (reset || count_clear) wb_err_counter<=18'h0;
		else wb_err_counter<=wb_err_counter+wb_err;
	
	reg [31:0] wb_read_latch;
	always @(posedge clk4x)
		if (wb_ack) wb_read_latch<=wb_dati;
		else wb_read_latch<=wb_read_latch;

	wire [31:0] data_out;

   // Local IPbus interface
   IPbus_local 
     #(.ADDR_MSB(`MSB_wb_bridge), 
       .WAIT_STATES(`WAIT_wb_bridge),
       .WRITE_PULSE_TICKS(`WTICKS_wb_bridge))
	 IPbus_local_x 
   (.reset(reset_IPbus_clk),
    .clk_local(IPbus_clk),
    .write_local(write),
    .DataOut_local(data_out),
    .IPbus_clk(IPbus_clk),
    .IPbus_strobe(IPbus_strobe),
    .IPbus_write(IPbus_write),
    .IPbus_ack(IPbus_ack),
    .IPbus_DataOut(IPbus_DataOut));

   genvar j1;
   generate for (j1=0; j1<NUM_CMD_WORDS; j1=j1+1) begin: gen_j1
      always @(posedge IPbus_clk) begin
	 if (reset_IPbus_clk == 1) Command[j1]<=32'h0;
	 else if ((write==1)&&(IPbus_addr==(j1))) Command[j1] <= IPbus_DataIn;
	 else if (j1==1) Command[j1]<=32'h0; // automatically clear
	 else Command[j1] <= Command[j1];
      end
   end endgenerate

	assign data_out=(IPbus_addr[7:6]==2'h0)?(Command[IPbus_addr[5:0]]):
		(IPbus_addr[7:6]==2'h1)?Status[IPbus_addr[5:0]]:
   	32'h0;	


   assign Status[0]={4'h0,duration,12'h0,2'h0,wb_done, wb_str};
	assign Status[1]=wb_read_latch;
	assign Status[2]={uplink_crc_err_counter[17:2], downlink_crc_err_counter[17:2]};
	assign Status[3]={16'h0, wb_err_counter[17:2]};
	
endmodule

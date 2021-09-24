`timescale 1ns / 1ps
`include "ADDR_MAP.v"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:41:41 03/27/2017 
// Design Name: 
// Module Name:    olink
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
module olink(
	 input clk_100,
    output clk_4x,
	 output clk_2x,
    output clk_x,
	 input reset,
	 input [1:0] rx_n, rx_p, clk_n, clk_p,
	 output [1:0] tx_n, tx_p,
	 
	 input [15:0] tx_d,
	 input [1:0] tx_k,
	 
	 output reg [31:0] rx_d,
	 output reg [3:0] rx_k,
	 output reg rx_v,
	 
    input 		     reset_IPbus_clk,
    input 		     IPbus_clk,
    input 		     IPbus_strobe,
    input 		     IPbus_write,
    output 		     IPbus_ack,
    input [`MSB_olink:0] IPbus_addr,
    input [31:0] 	     IPbus_DataIn,
    output [31:0] 	     IPbus_DataOut	 
    );

   // Control registers
   localparam NUM_CMD_WORDS = 4;
   reg [31:0] Command[NUM_CMD_WORDS-1:0];
	wire [31:0] DefaultCommand[NUM_CMD_WORDS-1:0];

	// readonly status starts at 0x40
   localparam NUM_STS_WORDS = 5;
   wire [31:0] Status[NUM_STS_WORDS-1:0];
	wire write;
	wire spy_rx_start;
	assign spy_rx_start=Command[1][4];
	wire counter_reset_io;
	assign counter_reset_io=Command[1][2];
	
	
	wire [7:0] gtx_status;
	wire [1:0] refclk;

	wire reset_gtx;
	wire [1:0] reset_status, pll_status;
	
	assign reset_gtx=Command[1][1] || reset;

	reg counter_reset_4x;

always @(posedge clk_4x)
	counter_reset_4x<=counter_reset_io || reset_gtx || ~gtx_status[0];

IBUFDS_GTXE1 buf_MGTREFCLK0P_114 (.I(clk_p[0]),.IB(clk_n[0]),
      .O(refclk[0]));
IBUFDS_GTXE1 buf_MGTREFCLK1P_114 (.I(clk_p[1]),.IB(clk_n[1]),
      .O(refclk[1]));

   localparam COMMA = 8'hbc;
   localparam IDLE = 8'hf7;
   localparam PAD  = 8'h1c;

   wire is_ok;
   reg [15:0] rx_d_r;
	reg was_ok;
	wire [15:0] rx_d_i;
	wire [1:0] rx_k_i, rx_nintable_i;
	reg [1:0] rx_k_r;
	reg [31:0] rx_d_4x;
	reg [3:0] rx_k_4x;
	reg rx_v_4x;

   assign is_ok = rx_nintable_i==2'b00 && gtx_status[4]==1'b1;
	
	reg phase_by_two;	
	
	reg was_comma, was_other_comma;
	always @(posedge clk_4x) begin
		was_comma<=(rx_k_i==2'b01) && (rx_d_i[7:0]==COMMA);

		phase_by_two<=(rx_k_i==2'b01)?(1'h1):(~phase_by_two);
		
		was_other_comma<=(rx_k_i==2'b10);
		was_ok<=is_ok;
		rx_d_r<=rx_d_i; 
		rx_k_r<=rx_k_i; 
		if (was_comma) begin 
			rx_d <= {rx_d_i,rx_d_r};
			rx_k <= {rx_k_i,2'b01};
			rx_v <= was_ok && is_ok;
		end else if (phase_by_two && rx_k_i==2'h0 && rx_k_r==2'h0) begin
			rx_d <= {rx_d_i,rx_d_r};
			rx_k <= 4'h0;
			rx_v <= was_ok && is_ok;			
		end else if (phase_by_two && rx_k_i==2'h3 && rx_k_r==2'h3) begin
			rx_d <= {rx_d_i,rx_d_r}; // should be IDLE, but...
			rx_k <= 4'hF;
			rx_v <= was_ok && is_ok;			
	   end else begin // PADDING for non-phase-by-two and any odd stuff
		   rx_d<={PAD,PAD,PAD,PAD};
			rx_k<=4'b1111;
			rx_v <= was_ok && is_ok;
		end
   end

   reg [31:0] spy_rx_buffer[63:0];
	reg [5:0] spy_rx_ptr;
	
always @(posedge clk_4x) begin
	if (spy_rx_start) spy_rx_ptr<=6'h0;
	else if (spy_rx_ptr!=6'h3f) spy_rx_ptr<=spy_rx_ptr+6'h1;
	else spy_rx_ptr<=spy_rx_ptr;
	spy_rx_buffer[spy_rx_ptr]<={rx_nintable_i,rx_k_i,rx_d_i};
end

   reg [31:0] spy_tx_buffer[63:0];
	reg [5:0] spy_tx_ptr;
	
always @(posedge clk_4x) begin
	if (spy_rx_start) spy_tx_ptr<=6'h0;
	else if (spy_tx_ptr!=6'h3f) spy_tx_ptr<=spy_tx_ptr+6'h1;
	else spy_tx_ptr<=spy_tx_ptr;
	spy_tx_buffer[spy_tx_ptr]<={tx_k,tx_d};
end


wire tx_out_clk, clk_tx_buf;
wire rx_rec_clk, clk_rec;
wire tx_pll_lock;

  BUFG buf_ref(.I(tx_out_clk),.O(clk_tx_buf));
  wire olink_clk_locked;

clk_man_olink clk_man_opti(.reset(~tx_pll_lock),
	.clk_olink(clk_tx_buf),
	.clk_bx(clk_x),
   .clk_16b(clk_4x),
   .clk_32b(clk_2x),
   .locked(olink_clk_locked)
    );

  BUFR#(
   .BUFR_DIVIDE("BYPASS"), // Values: "BYPASS, 1, 2, 3, 4, 5, 6, 7, 8" 
   .SIM_DEVICE("VIRTEX6")  // Must be set to "VIRTEX6" 
  ) buf_rec(.I(clk_rec),.O(rx_rec_clk),.CE(1'h1));
  reg [12:0] gtx_test;

ldmx_olink_gtx mylink
(
    //----------------- Receive Ports - RX Data Path interface -----------------
    .RXRESET_IN(Command[2][4]),
	 .RXDATA_OUT(rx_d_i),
	 .RXCHARISK_OUT(rx_k_i),
	 .RXNOTINTABLE_OUT(rx_nintable_i),
	 .RXBYTEISALIGNED_OUT(gtx_status[4]),
    .RXPOLARITY_IN(~Command[2][5]), // polarity inverted by default!
    //----- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
    .RXN_IN(rx_n[0]),
    .RXP_IN(rx_p[0]),
    .RXRECCLK_OUT(clk_rec), 
	 .RXUSRCLK2_IN(clk_4x),
    //----------------------- Transmit Ports - GTX Ports -----------------------
    //---------------- Transmit Ports - TX Data Path interface -----------------
    .TXDATA_IN(tx_d),
    .TXCHARISK_IN(tx_k),
    .TXOUTCLK_OUT(tx_out_clk),
    .TXRESET_IN(Command[2][3]),
    .TXUSRCLK2_IN(clk_4x),
    //-------------- Transmit Ports - TX Driver and OOB signaling --------------
    .TXDIFFCTRL_IN(Command[2][31:28]),
    .TXN_OUT(tx_n[0]),
    .TXP_OUT(tx_p[0]),
    .TXPOSTEMPHASIS_IN(Command[2][24:20]),
    //------------- Transmit Ports - TX Driver and OOB signalling --------------
    .TXPREEMPHASIS_IN(Command[2][19:16]),
    //--------------------- Transmit Ports - TX PLL Ports ----------------------
    .GTXTXRESET_IN(Command[2][2]||reset_gtx),
    .MGTREFCLKTX_IN(refclk),
    .PLLTXRESET_IN(Command[2][1]),
    .TXPLLLKDET_OUT(tx_pll_lock),
    .TXRESETDONE_OUT(gtx_status[0]),
    //------------------ Transmit Ports - TX Polarity Control ------------------
    .TXPOLARITY_IN(~Command[2][0]), // polarity inverted by default!
	 .GTXTEST_IN(gtx_test)
	 );
	 
reg [11:0] gtx_test_counter;
	
always @(posedge clk_100) begin
	if (reset || reset_gtx || ~tx_pll_lock) gtx_test_counter<=12'h0;
	else if (gtx_test_counter!=12'hfff) gtx_test_counter<=gtx_test_counter+12'h1;
	else gtx_test_counter<=gtx_test_counter;
   
	gtx_test[12:2]<={1'h1,10'h0};
	gtx_test[0]<={1'h0};

	if (gtx_test_counter>=12'd1024 && gtx_test_counter<=12'd1350) gtx_test[1]<=1'h1;
	else if (gtx_test_counter>=12'd2000 && gtx_test_counter<=12'd2350) gtx_test[1]<=1'h1;
	else gtx_test[1]<=1'h0;
end
	

assign gtx_status[1]=tx_pll_lock;	 
	 
clk_gtx_wrapper clkout(.reset(reset),.rx_p(rx_p[1]),.rx_n(rx_n[1]),.tx_p(tx_p[1]),.tx_n(tx_n[1]),
   .refclk(refclk),.stream(10'b0000011111),.gtx_reset_done(gtx_status[2]),.gtx_pll_lock(gtx_status[3]));

assign DefaultCommand[2]={4'h7,3'h0,5'h08,4'h3,12'h0,3'h0,1'h0};

	wire [31:0] data_out;

   // Local IPbus interface
   IPbus_local 
     #(.ADDR_MSB(`MSB_olink), 
       .WAIT_STATES(`WAIT_olink),
       .WRITE_PULSE_TICKS(`WTICKS_olink))
	 IPbus_local_sensor 
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
	 if (reset_IPbus_clk == 1) Command[j1]<=DefaultCommand[j1];
	 else if ((write==1)&&(IPbus_addr==(j1))) Command[j1] <= IPbus_DataIn;
	 else if (j1==1) Command[j1]<=32'h0; // automatically clear
	 else Command[j1] <= Command[j1];
      end
   end endgenerate


	assign data_out=(IPbus_addr[7:6]==2'h0)?(Command[IPbus_addr[4:0]]):
		(IPbus_addr[7:6]==2'h1)?Status[IPbus_addr[4:0]]:
		(IPbus_addr[7:6]==2'h2)?spy_rx_buffer[IPbus_addr[5:0]]:
		                        spy_tx_buffer[IPbus_addr[5:0]];
		
   assign Status[0]={olink_clk_locked,gtx_test[1],was_other_comma,was_comma,rx_v,was_ok, gtx_status};

clkRateTool2 testA(.reset_in(reset),.clk100(clk_100),.clktest(clk_4x),.value(Status[1]));
clkRateTool2 testB(.reset_in(reset),.clk100(clk_100),.clktest(rx_rec_clk),.value(Status[2]));
clkRateTool2 testK(.reset_in(reset),.clk100(clk_100),.clktest(was_comma),.value(Status[3]));

	
lowImpact32BitCounter countBad(.clk(clk_4x),.countenable(~was_ok),.reset(counter_reset_4x),.value(Status[4]));


endmodule

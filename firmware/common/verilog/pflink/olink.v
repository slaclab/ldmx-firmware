`timescale 1ns / 1ps
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
	     input 	       clk_125,
	     
	     output 	       clk_tx_raw,
	     output 	       clk_tx_mmcm_reset,
	     input 	       clk_link_lock,
	     input 	       clk_link,

	     input 	       reset,
	     input [1:0]       rx_n, rx_p,
	     output [1:0]      tx_n, tx_p,
	     input [1:0]       refclk,

             input 	       qpll_lock,
             input 	       qpll_clkout, 
             input 	       qpll_refclkout, 
             input 	       qpll_refclklost,
             output 	       qpll_reset,
	 
	     input [15:0]      tx_d,
	     input [1:0]       tx_k,
	 
	     output reg [31:0] rx_d,
	     output reg [3:0]  rx_k,
	     output reg        rx_v,

	     output 	       ts_rx_clk,
	     output [1:0]      ts_rx_k,
	     output [1:0]      ts_rx_err,
	     output [15:0]     ts_rx_d,

	     input 	       axi_clk,
	     input 	       axi_wstr,
	     input 	       axi_rstr,
	     output 	       axi_wack,
	     output 	       axi_rack,
	     input [7:0]       axi_raddr,
	     input [7:0]       axi_waddr,
	     input [31:0]      axi_din,
	     output reg [31:0] axi_dout
    );

   // Control registers
   localparam NUM_CMD_WORDS = 4;
   reg [31:0] 			  Command[NUM_CMD_WORDS-1:0];
   wire [31:0] 			  DefaultCommand[NUM_CMD_WORDS-1:0];
   
   // readonly status starts at 0x40
   localparam NUM_STS_WORDS = 6;   
   wire [31:0] 			  Status[NUM_STS_WORDS-1:0];
   wire 			  write;
   wire 			  spy_rx_start;
   assign spy_rx_start=Command[1][4];
   wire 			  counter_reset_io;
   assign counter_reset_io=Command[1][2];
   
	
   wire [7:0] 			  gtx_status;

   wire [9:0] 			  gtx_ctl_pulse;
   assign gtx_ctl_pulse=Command[1][17:8];
   
   wire [3:0] 			  gtx_ctl_level;
   assign gtx_ctl_level=Command[0][3:0];
   
   
   reg 				  counter_reset_link;

   localparam COMMA = 8'hbc;
   localparam IDLE = 8'hf7;
   localparam PAD  = 8'h1c;
   
   wire 			  is_ok;
   reg [15:0] 			  rx_d_r;
   reg 				  was_ok;
   wire [15:0] 			  rx_d_i;
   wire [1:0] 			  rx_k_i, rx_nintable_i;
   reg [1:0] 			  rx_k_r;
   reg [31:0] 			  rx_d_4x;
   reg [3:0] 			  rx_k_4x;
   reg 				  rx_v_4x;
   
   assign is_ok = rx_nintable_i==2'b00 && gtx_status[4]==1'b1;
	
   assign gtx_status[0]=qpll_lock;

   reg 				  phase_by_two;	
   
   reg 				  was_comma, was_other_comma;
   always @(posedge clk_link) begin
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
   reg [5:0]  spy_rx_ptr;
   reg [31:0] spy_rx_buffer_r;

   always @(posedge axi_clk)
     spy_rx_buffer_r<=spy_rx_buffer[axi_raddr[5:0]];
   
   always @(posedge clk_link) begin
	if (spy_rx_start) spy_rx_ptr<=6'h0;
	else if (spy_rx_ptr!=6'h3f) spy_rx_ptr<=spy_rx_ptr+6'h1;
	else spy_rx_ptr<=spy_rx_ptr;
	spy_rx_buffer[spy_rx_ptr]<={rx_nintable_i,rx_k_i,rx_d_i};
end

   reg [31:0] spy_tx_buffer[63:0];
   reg [5:0]  spy_tx_ptr;
   reg [31:0] spy_tx_buffer_r;

   always @(posedge axi_clk)
     spy_tx_buffer_r<=spy_tx_buffer[axi_raddr[5:0]];
   
   
always @(posedge clk_link) begin
	if (spy_rx_start) spy_tx_ptr<=6'h0;
	else if (spy_tx_ptr!=6'h3f) spy_tx_ptr<=spy_tx_ptr+6'h1;
	else spy_tx_ptr<=spy_tx_ptr;
	spy_tx_buffer[spy_tx_ptr]<={tx_k,tx_d};
end

wire tx_out_clk, clk_tx_buf;

  BUFH buf_ref(.I(tx_out_clk),.O(clk_tx_buf));
   assign clk_tx_raw=clk_tx_buf;
      
   always @(posedge clk_link)
     counter_reset_link<=counter_reset_io || ~clk_link_lock;

gt_pflink_init pflink(.sysclk_in(clk_125),
		      .soft_reset_tx_in(gtx_ctl_pulse[1]),
		      .soft_reset_rx_in(gtx_ctl_pulse[2]),
		      .dont_reset_on_data_error_in(1'h1),
		      .gt0_tx_fsm_reset_done_out(gtx_status[1]),
		      .gt0_rx_fsm_reset_done_out(gtx_status[2]),
		      .gt0_data_valid_in(1'h1),
		      .gt0_tx_mmcm_lock_in(clk_link_lock),
		      .gt0_tx_mmcm_reset_out(clk_tx_mmcm_reset),
		      .gt0_rx_mmcm_lock_in(clk_link_lock),
//output          gt0_rx_mmcm_reset_out,

//    output          gt0_cpllfbclklost_out,
//    .gt0_cplllock_out(gtx_status[0]),
//    input           gt0_cplllockdetclk_in,
//    .gt0_cpllreset_in(gtx_ctl_pulse[0]),
    //------------------------ Channel - Clocking Ports ------------------------
//    .gt0_gtrefclk0_in(refclk[0]),         .qpll_lock(qpll_lock), .qpll_clkout(qpll_clkout), .qpll_refclkout(qpll_refclkout), .qpll_refclklost(qpll_refclklost),

//    .gt0_gtrefclk1_in(refclk[1]),
    .gt0_qplllock_in(qpll_lock),
    .gt0_qpllrefclklost_in(qpll_refclklost),
    .gt0_qpllreset_out(qpll_reset),
    .gt0_qplloutclk_in(qpll_clkout),
    .gt0_qplloutrefclk_in(qpll_refclkout),
    //-------------------------- Channel - DRP Ports  --------------------------
    .gt0_drpaddr_in(12'h0),
    .gt0_drpclk_in(clk_125),
    .gt0_drpdi_in(16'h0),
//    output  [15:0]  gt0_drpdo_out,
    .gt0_drpen_in(1'h0),
//    output          gt0_drprdy_out,
    .gt0_drpwe_in(1'h0),
    //------------------------- Digital Monitor Ports --------------------------
//    output  [7:0]   gt0_dmonitorout_out,
    //------------------- RX Initialization and Reset Ports --------------------
    .gt0_eyescanreset_in(1'h0),
    .gt0_rxuserrdy_in(clk_link_lock),
    //------------------------ RX Margin Analysis Ports ------------------------
//    output          gt0_eyescandataerror_out,
    .gt0_eyescantrigger_in(1'h0),
    //---------------- Receive Ports - FPGA RX Interface Ports -----------------
    .gt0_rxusrclk_in(clk_link),
    .gt0_rxusrclk2_in(clk_link),
    //---------------- Receive Ports - FPGA RX interface Ports -----------------
    .gt0_rxdata_out(rx_d_i),
    .gt0_rxcharisk_out(rx_k_i),
    //---------------- Receive Ports - RX 8B/10B Decoder Ports -----------------
    //output  [1:0]   gt0_rxdisperr_out,
    .gt0_rxnotintable_out(rx_nintable_i),
    //------------------------- Receive Ports - RX AFE -------------------------
    .gt0_gtxrxp_in(rx_p[0]),
    .gt0_gtxrxn_in(rx_n[0]),
    //------------------- Receive Ports - RX Equalizer Ports -------------------
    .gt0_rxdfelpmreset_in(1'h0),
    .gt0_rxmonitorsel_in(2'h0),
    //------------- Receive Ports - RX Fabric Output Control Ports -------------
    .gt0_gtrxreset_in(gtx_ctl_pulse[4]),
    .gt0_rxpmareset_in(gtx_ctl_pulse[5]),
    .gt0_rxresetdone_out(gtx_status[4]),
    //------------------- TX Initialization and Reset Ports --------------------
    .gt0_gttxreset_in(gtx_ctl_pulse[3]),
    .gt0_txuserrdy_in(clk_link_lock),
    //---------------- Transmit Ports - FPGA TX Interface Ports ----------------
    .gt0_txusrclk_in(clk_link),
    .gt0_txusrclk2_in(clk_link),
    //---------------- Transmit Ports - TX Data Path interface -----------------
    .gt0_txdata_in(tx_d),
    .gt0_txcharisk_in(tx_k),
    //-------------- Transmit Ports - TX Driver and OOB signaling --------------
    .gt0_gtxtxn_out(tx_n[0]),
    .gt0_gtxtxp_out(tx_p[0]),
    //--------- Transmit Ports - TX Fabric Clock Output Control Ports ----------
    .gt0_txoutclk_out(tx_out_clk),
    .gt0_txresetdone_out(gtx_status[3]),
    //--------------- Transmit Ports - TX Polarity Control Ports ---------------
    .gt0_txpolarity_in(gtx_ctl_level[1]),
    .gt0_rxpolarity_in(gtx_ctl_level[2])
	     );

   wire [2:0] rx_status;
   
clk_gtx_wrapper clkout(.clk_125(clk_125),.soft_reset(gtx_ctl_pulse[6]),.pll_lock_in(clk_link_lock),
               .qpll_lock(qpll_lock), .qpll_clkout(qpll_clkout), .qpll_refclkout(qpll_refclkout), .qpll_refclklost(qpll_refclklost),

		       .clk_link(clk_link), .cpll_reset_in(gtx_ctl_pulse[7]),
		       .refclk(refclk[0]),
		       .reset_done_out(gtx_status[5]),.tx_p(tx_p[1]),.tx_n(tx_n[1]),
		       .rx_n(rx_n[1]),.rx_p(rx_p[1]),
		       .rx_status(rx_status),.rx_reset(gtx_ctl_pulse[8]),.rx_polarity(gtx_ctl_level[3]),
		       .rx_clk(ts_rx_clk),.rx_k(ts_rx_k),.rx_err(ts_rx_err),.rx_d(ts_rx_d)
		       );
  

   assign DefaultCommand[0]=32'h0;
   assign DefaultCommand[1]=32'h0;   
   assign DefaultCommand[2]={4'h7,3'h0,5'h08,4'h3,12'h0,3'h0,1'h0};
   assign DefaultCommand[3]=32'h0;

   reg 	       reset_io;
   always @(posedge axi_clk) reset_io<=reset;

   genvar z; 
   generate for (z=0; z<NUM_CMD_WORDS; z=z+1) begin: gen_write
      always @(posedge axi_clk) begin
	 if (reset_io == 1) Command[z] <= DefaultCommand[z];
	 else if ((write == 1) && (axi_waddr == z)) Command[z] <= axi_din;
	 else begin
	    if (z==1) Command[z]<=32'h0;
	    else Command[z] <= Command[z];
	 end
      end
      
   end endgenerate   

   always @(posedge axi_clk)
     if (!axi_rstr) axi_dout<=32'h0;
     else if (axi_raddr[7:6]==2'h0 && axi_raddr[5:2]==4'h0) axi_dout<=Command[axi_raddr[1:0]];
	 else if (axi_raddr[7:6]==2'h1 && axi_raddr[5:3]==3'h0) axi_dout<=Status[axi_raddr[2:0]];
	 else if (axi_raddr[7:6]==2'h2) axi_dout<=spy_rx_buffer_r;
	 else if (axi_raddr[7:6]==2'h3) axi_dout<=spy_tx_buffer_r;
	 else axi_dout<=32'h0;
	 
   assign Status[0]={16'h0010,16'h0002};   
   assign Status[1]={clk_link_lock,was_other_comma,was_comma,rx_v,was_ok, gtx_status};

   clkRateTool testA(.reset_in(reset),.clk125(clk_125),.clktest(clk_link),.value(Status[2][23:0])); assign Status[2][31:24]=8'h0;
   assign Status[3]=32'h0;
   clkRateTool testK(.reset_in(reset),.clk125(clk_125),.clktest(was_comma),.value(Status[4][23:0])); assign Status[4][31:24]=8'h0;

   reg [31:0] countBad;

   always @(posedge clk_link)
     if (counter_reset_link) countBad<=32'h0;
     else if (~was_ok) countBad<=countBad+32'h1;
     else countBad<=countBad;
   
   assign Status[5]=countBad;


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

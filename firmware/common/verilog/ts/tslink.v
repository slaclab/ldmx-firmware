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
module tslink(
	     input 	       clk_125,
	     input 	       reset_soft,
	     input [1:0]       rx_n, rx_p,
	     output [1:0]      tx_n, tx_p,
	     input 	       refclk_p, refclk_n,
	      
	     output reg [31:0] rx_d,
	     output reg [3:0]  rx_k,
	     output reg [1:0]  rx_err,
	     output [1:0]      rx_clk,

	     output [7:0]      reset_done,
	     input [1:0]       polarity,
	      input [2:0] loopback,
	     input 	       reset_rx,
	     output [3:0]      cpll_status,
	     input 	       cpll_reset
    );


   wire [31:0] 	    rx_d_i;
   wire [3:0] 	    rx_k_i;
   wire [3:0] 	    rx_disp_i;
   wire [3:0] 	    rx_notint_i;


   always @(posedge rx_clk[0]) begin
      rx_d[15:0]<=rx_d_i[15:0];
      rx_k[1:0]<=rx_k_i[1:0];
      rx_err[0]<=(rx_disp_i[1:0]!=0) || (rx_notint_i[1:0]!=0);
   end
   always @(posedge rx_clk[1]) begin
      rx_d[31:16]<=rx_d_i[31:16];
      rx_k[3:2]<=rx_k_i[3:2];
      rx_err[1]<=(rx_disp_i[3:2]!=0) || (rx_notint_i[3:2]!=0);
   end
      
   
   reg [1:0] 	    polarity_r;
   reg [2:0] 	    loopback_r;
   

   always @(posedge clk_125) begin
      polarity_r<=polarity;
      loopback_r<=loopback;
   end
      

   wire 	    tx_clk0;
   
   reg [7:0] 	    txc;

   always @(posedge tx_clk0)
     txc<=txc+8'h1;
   
   
   gtx_ts theGTXs(
		  .soft_reset_tx_in(reset_soft),
		  .soft_reset_rx_in(reset_soft),
		  .dont_reset_on_data_error_in(1'h1),
		  .q2_clk0_gtrefclk_pad_n_in(refclk_n),
		  .q2_clk0_gtrefclk_pad_p_in(refclk_p),
		  .gt0_tx_fsm_reset_done_out(reset_done[0]),
		  .gt0_rx_fsm_reset_done_out(reset_done[1]),
		  .gt0_data_valid_in(1'h1),
		  .gt1_tx_fsm_reset_done_out(reset_done[2]),
		  .gt1_rx_fsm_reset_done_out(reset_done[3]),
		  .gt1_data_valid_in(1'h1),
 
//    output   gt0_txusrclk_out,
    .gt0_txusrclk2_out(tx_clk0),
//    output   gt0_rxusrclk_out,
    .gt0_rxusrclk2_out(rx_clk[0]),
 
//    output   gt1_txusrclk_out,
//    output   gt1_txusrclk2_out,
//    output   gt1_rxusrclk_out,
    .gt1_rxusrclk2_out(rx_clk[1]),

		  .gt0_loopback_in(loopback_r),
		  .gt1_loopback_in(loopback_r),
		  
    //_________________________________________________________________________
    //GT0  (X1Y4)
    //____________________________CHANNEL PORTS________________________________
    //------------------------------- CPLL Ports -------------------------------
    .gt0_cpllfbclklost_out(cpll_status[0]),
    .gt0_cplllock_out(cpll_status[1]),
    .gt0_cpllreset_in(cpll_reset),
    .gt0_drpaddr_in(9'h0),
    .gt0_drpdi_in(16'h0),
    .gt0_drpen_in(1'h0),
    .gt0_drpwe_in(1'h0),
    .gt0_eyescanreset_in(1'h0),
    .gt0_rxuserrdy_in(1'h1),
    .gt0_eyescantrigger_in(1'h0),
    .gt0_rxdata_out(rx_d_i[15:0]),
    .gt0_rxdisperr_out(rx_disp_i[1:0]),
    .gt0_rxnotintable_out(rx_notint_i[1:0]),
    .gt0_gtxrxp_in(rx_p[0]),
    .gt0_gtxrxn_in(rx_n[0]),
    .gt0_rxdfelpmreset_in(1'h0),
    .gt0_rxmonitorsel_in(2'h0),
//    .gt0_rxoutclkfabric_out,
    .gt0_gtrxreset_in(reset_rx),
    .gt0_rxpmareset_in(1'h0),
    .gt0_rxpolarity_in(polarity_r[0]),
    .gt0_rxcharisk_out(rx_k_i[1:0]),
    .gt0_rxresetdone_out(reset_done[4]),
    .gt0_gttxreset_in(1'h0),
    .gt0_txuserrdy_in(1'h1),
    .gt0_txdata_in({txc,8'hbc}),
		  .gt0_txcharisk_in(2'b01),
    .gt0_gtxtxn_out(tx_n[0]),
    .gt0_gtxtxp_out(tx_p[0]),
//    .gt0_txoutclkfabric_out,
//    .gt0_txoutclkpcs_out,
    .gt0_txresetdone_out(reset_done[5]),
    .gt0_txpolarity_in(1'h0),

    //GT1  (X1Y5)
    //____________________________CHANNEL PORTS________________________________
    //------------------------------- CPLL Ports -------------------------------
   .gt1_cpllfbclklost_out(cpll_status[2]),
   .gt1_cplllock_out(cpll_status[3]),
   .gt1_cpllreset_in(cpll_reset),
   .gt1_drpaddr_in(9'h0),
   .gt1_drpdi_in(16'h0),
   .gt1_drpen_in(1'h0),
   .gt1_drpwe_in(1'h0),
   .gt1_eyescanreset_in(1'h0),
   .gt1_rxuserrdy_in(1'h0),
   .gt1_eyescantrigger_in(1'h0),
   .gt1_rxdata_out(rx_d_i[31:16]),
   .gt1_rxdisperr_out(rx_disp_i[3:2]),
   .gt1_rxnotintable_out(rx_notint_i[3:2]),
   .gt1_gtxrxp_in(rx_p[1]),
   .gt1_gtxrxn_in(rx_n[1]),
   .gt1_rxdfelpmreset_in(1'h0),
   .gt1_rxmonitorsel_in(2'h0),
   .gt1_gtrxreset_in(reset_rx),
   .gt1_rxpmareset_in(1'h0),
   .gt1_rxpolarity_in(polarity_r[1]),
   .gt1_rxcharisk_out(rx_k_i[3:2]),
   .gt1_rxresetdone_out(reset_done[6]),
   .gt1_gttxreset_in(1'h0),
   .gt1_txuserrdy_in(1'h1),
		  .gt1_txdata_in({8'h5c,8'hbc}),
		  .gt1_txcharisk_in(2'b01),
   .gt1_gtxtxn_out(tx_n[1]),
   .gt1_gtxtxp_out(tx_p[1]),
   .gt1_txresetdone_out(reset_done[7]),
   .gt1_txpolarity_in(1'h0),

    //____________________________COMMON PORTS________________________________
		  .sysclk_in(clk_125)
		  );
   
endmodule

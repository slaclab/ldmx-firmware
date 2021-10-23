module clk_gtx_wrapper(
		       input 	    clk_125,
		       input 	    soft_reset,
		       input 	    pll_lock_in,
		       input 	    clk_link,
		       input 	    cpll_reset_in,
		       input 	    refclk,
		       input 	    qpll_lock,
		       input 	    qpll_clkout, 
		       input 	    qpll_refclkout, 
		       input 	    qpll_refclklost,
//         output qpll_reset,
		       output 	    reset_done_out,
		       output [2:0] rx_status,
		       input 	    rx_polarity,
		       input 	    rx_reset,
		       output 	    rx_clk,
		       output [1:0] rx_k,
		       output [1:0] rx_err,
		       output [15:0] rx_d,
		       input 	    rx_p, rx_n, 
		       output 	    tx_p, tx_n		       
		       );

   wire 			    rec_clk;
   
   BUFH bufrx(.I(rec_clk),.O(rx_clk));
   

gt_pfclktx_core theGTX(
   .sysclk_in(clk_125),
   .soft_reset_tx_in(soft_reset),
		       .soft_reset_rx_in(soft_reset),
   .dont_reset_on_data_error_in(1'h1),
   .gt0_tx_fsm_reset_done_out(reset_done_out),
   .gt0_rx_fsm_reset_done_out(rx_status[2]),
   .gt0_data_valid_in(pll_lock_in),

    //_________________________________________________________________________
    //GT0  (X1Y0)
    //____________________________CHANNEL PORTS________________________________
    //------------------------------- CPLL Ports -------------------------------
    .gt0_cpllfbclklost_out(rx_status[0]),
    .gt0_cplllock_out(rx_status[1]),
    .gt0_cplllockdetclk_in(clk_125),
    .gt0_cpllreset_in(cpll_reset_in),
    //------------------------ Channel - Clocking Ports ------------------------
    .gt0_qplllock_in(qpll_lock),
    .gt0_qpllrefclklost_in(qpll_refclklost),
//    .gt0_qpllreset_out(qpll_reset),
    .gt0_qplloutclk_in(qpll_clkout),
    .gt0_qplloutrefclk_in(qpll_refclkout),
    .gt0_gtrefclk0_in(refclk),
    //input           gt0_gtrefclk1_in,
    //-------------------------- Channel - DRP Ports  --------------------------
    .gt0_drpaddr_in(12'h0),
    .gt0_drpclk_in(clk_125),
    .gt0_drpdi_in(16'h0),
//    .gt0_drpdo_out,
    .gt0_drpen_in(1'h0),
//    .gt0_drprdy_out,
    .gt0_drpwe_in(1'h0),
    //------------------------- Digital Monitor Ports --------------------------
//    output  [7:0]   gt0_dmonitorout_out,
    //------------------- RX Initialization and Reset Ports --------------------
    .gt0_eyescanreset_in(1'h0),
    //------------------------ RX Margin Analysis Ports ------------------------
 //   .gt0_eyescandataerror_out,
    .gt0_eyescantrigger_in(1'h0),
    //------------------- Receive Ports - RX Equalizer Ports -------------------
//    .gt0_rxmonitorout_out(),
    .gt0_rxmonitorsel_in('h0),
    //----------- Receive Ports - RX Initialization and Reset Ports ------------
    .gt0_gtrxreset_in(rx_reset),
    .gt0_rxpolarity_in(rx_polarity),
    //------------------- TX Initialization and Reset Ports --------------------
    .gt0_gttxreset_in(1'h0),
    .gt0_txuserrdy_in(pll_lock_in),
    //---------------- Transmit Ports - FPGA TX Interface Ports ----------------
    .gt0_txusrclk_in(clk_link),
    .gt0_txusrclk2_in(clk_link),
    .gt0_rxusrclk_in(rx_clk),
    .gt0_rxusrclk2_in(rx_clk),
    .gt0_rxoutclk_out(rec_clk),
    //---------------- Transmit Ports - TX Data Path interface -----------------
    .gt0_txdata_in(20'b00000111110000011111),
		       .gt0_rxdata_out(rx_d),
		       .gt0_rxnotintable_out(rx_err),
		       .gt0_rxcharisk_out(rx_k),
    //-------------- Transmit Ports - TX Driver and OOB signaling --------------
    .gt0_gtxtxn_out(tx_n),
    .gt0_gtxtxp_out(tx_p),
    .gt0_gtxrxn_in(rx_n),
    .gt0_gtxrxp_in(rx_p)
    //--------- Transmit Ports - TX Fabric Clock Output Control Ports ----------
//    output          gt0_txoutclk_out,
//    output          gt0_txoutclkfabric_out,
//    output          gt0_txoutclkpcs_out,
    //----------- Transmit Ports - TX Initialization and Reset Ports -----------
//    output          gt0_txresetdone_out,


    //____________________________COMMON PORTS________________________________
//    input      gt0_qplloutclk_in,
//    input      gt0_qplloutrefclk_in
		   );
   
   
endmodule

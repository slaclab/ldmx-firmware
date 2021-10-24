
`timescale 1ns/10ps

// Edge Module Definition
module LdmxDpm ( sysClk125, sysClk125Rst, sysClk200, sysClk200Rst, locRefClkP, locRefClkM, dtmRefClkG, axilClk, axilRst,
                 axilReadMaster_araddr, axilReadMaster_arprot, axilReadMaster_arvalid, axilReadMaster_rready, axilReadSlave_arready,
                 axilReadSlave_rdata, axilReadSlave_rresp, axilReadSlave_rvalid, axilWriteMaster_awaddr, axilWriteMaster_awprot,
                 axilWriteMaster_awvalid, axilWriteMaster_wdata, axilWriteMaster_wstrb, axilWriteMaster_wvalid, axilWriteMaster_bready,
                 axilWriteSlave_awready, axilWriteSlave_wready, axilWriteSlave_bresp, axilWriteSlave_bvalid, dmaClk, dmaRst,
                 dmaObMaster_tValid, dmaObMaster_tData, dmaObMaster_tStrb, dmaObMaster_tKeep, dmaObMaster_tLast, dmaObMaster_tDest,
                 dmaObMaster_tId, dmaObMaster_tUser, dmaObSlave_tReady, dmaIbMaster_tValid, dmaIbMaster_tData, dmaIbMaster_tStrb,
                 dmaIbMaster_tKeep, dmaIbMaster_tLast, dmaIbMaster_tDest, dmaIbMaster_tId, dmaIbMaster_tUser, dmaIbSlave_tReady, dpmToRtmHsP,
                 dpmToRtmHsM, rtmToDpmHsP, rtmToDpmHsM, distDivClk, distDivClkRst, trigger, spill, busy);

   // Clocks and Resets
   input  wire          sysClk125;
   input  wire          sysClk125Rst;
   input  wire          sysClk200;
   input  wire          sysClk200Rst;

   // External reference clock
   input  wire          locRefClkP;
   input  wire          locRefClkM;
   input  wire          dtmRefClkG;

   // AXI-Lite Interface
   input  wire          axilClk;
   input  wire          axilRst;
   input  wire [31:0]   axilReadMaster_araddr;
   input  wire [2:0]    axilReadMaster_arprot;
   input  wire          axilReadMaster_arvalid;
   input  wire          axilReadMaster_rready;
   output reg           axilReadSlave_arready;
   output wire [31:0]   axilReadSlave_rdata;
   output wire [1:0]    axilReadSlave_rresp;
   output wire          axilReadSlave_rvalid;
   input  wire [31:0]   axilWriteMaster_awaddr;
   input  wire [2:0]    axilWriteMaster_awprot;
   input  wire          axilWriteMaster_awvalid;
   input  wire [31:0]   axilWriteMaster_wdata;
   input  wire [3:0]    axilWriteMaster_wstrb;
   input  wire          axilWriteMaster_wvalid;
   input  wire          axilWriteMaster_bready;
   output reg           axilWriteSlave_awready;
   output wire          axilWriteSlave_wready;
   output wire [1:0]    axilWriteSlave_bresp;
   output wire          axilWriteSlave_bvalid;

   // DMA Interface (1 Stream on DMA0) -- 64 bits wide (RCEG3_AXIS_DMA_CONFIG_C)
   output wire          dmaClk;
   output wire          dmaRst;
   input  wire          dmaObMaster_tValid;
   input  wire [63:0]   dmaObMaster_tData;
   input  wire [7:0]    dmaObMaster_tStrb;
   input  wire [7:0]    dmaObMaster_tKeep;
   input  wire          dmaObMaster_tLast;
   input  wire [7:0]    dmaObMaster_tDest;
   input  wire [7:0]    dmaObMaster_tId;
   input  wire [63:0]   dmaObMaster_tUser;
   output wire          dmaObSlave_tReady;
   output wire          dmaIbMaster_tValid;
   output wire [63:0]   dmaIbMaster_tData;
   output wire [7:0]    dmaIbMaster_tStrb;
   output wire [7:0]    dmaIbMaster_tKeep;
   output wire          dmaIbMaster_tLast;
   output wire [7:0]    dmaIbMaster_tDest;
   output wire [7:0]    dmaIbMaster_tId;
   output wire [63:0]   dmaIbMaster_tUser;
   input  wire          dmaIbSlave_tReady;

   // High Speed Interface
   output wire [3:0]    dpmToRtmHsP;
   output wire [3:0]    dpmToRtmHsM;
   input  wire [3:0]    rtmToDpmHsP;
   input  wire [3:0]    rtmToDpmHsM;

   // COB Timing Interface
   input  wire          distDivClk;
   input  wire          distDivClkRst;
   input  wire          trigger;
   input  wire          spill;
   output wire          busy;

    reg [(31-2-12):0] axilReadMaster_araddr_r;
    reg [(31-2-12):0] axilWriteMaster_awaddr_r;

    reg axi_rstart;

 always @(posedge axilClk) begin
    if (axilRst) begin
       axilReadSlave_arready<=1'h0;
       axi_rstart<=1'h0;
    end else if (axilReadMaster_arvalid) begin
       axilReadSlave_arready<=1'h1;
       axi_rstart<=1'h1;
    end else begin
       axilReadSlave_arready<=1'h0;
       axi_rstart<=1'h0;
    end
    axilReadMaster_araddr_r<=axilReadMaster_araddr[19:2];
  end

 always @(posedge axilClk) begin
    if (axilRst) begin
       axilWriteSlave_awready<=1'h0;
    end else if (axilWriteMaster_awvalid) begin
       axilWriteSlave_awready<=1'h1;
    end else begin
       axilWriteSlave_awready<=1'h0;
    end
    axilWriteMaster_awaddr_r<=axilWriteMaster_awaddr[19:2];
  end

  wire fc_wstr, fc_wack, fc_rstr, fc_rack;
  wire [31:0] fc_dout;
   
  wire ts_wstr, ts_wack, ts_rstr, ts_rack;
  wire [31:0] ts_dout;
   
   
  wire [1:0] gt_wstr, gt_wack, gt_rstr, gt_rack;
  wire [(32*2-1):0] gt_dout;
  wire [1:0] wb_wstr, wb_wack, wb_rstr, wb_rack;
  wire [(32*2-1):0] wb_dout;

  wire clk_link;
  wire clk_bx;
  wire [1:0] clk_tx_raw;
  wire [15:0] fc_stream;
  wire [1:0] mmcm_reset;
  wire olink_clk_locked;

  clk_man_olink clk_man_opti(.reset((|mmcm_reset)),
			   .clk_tx(clk_tx_raw[0]),
			   .clk_bx(clk_bx),
			   .clk_olink(clk_link),
			   .locked(olink_clk_locked)
			   );

  fast_control fc_block(
    .clk_bx(clk_bx),
    .fc_stream_enc(fc_stream),
			.clk125(sysClk125),
			.clk_refd2(refClkD2),
    .reset(axilRst),
    .axi_clk(axilClk),
    .axi_wstr(fc_wstr),.axi_rstr(fc_rstr),
    .axi_wack(fc_wack),.axi_rack(fc_rack),
    .axi_raddr(axilReadMaster_araddr_r[7:0]),
    .axi_waddr(axilWriteMaster_awaddr_r[7:0]),
    .axi_din(axilWriteMaster_wdata),
    .axi_dout(fc_dout)
    );

   wire [1:0] ts_rx_clk;
   wire [(2*2-1):0] ts_rx_k;
   wire [(2*2-1):0] ts_rx_err;   
   wire [(2*16-1):0] ts_rx_d;
      
  trigscint ts_block(.clk125(sysClk125),
		     .rx_clk(ts_rx_clk),
		     .rx_k(ts_rx_k),
		     .rx_err(ts_rx_err),
		     .rx_d(ts_rx_d),
    .reset(axilRst),
    .axi_clk(axilClk),
    .axi_wstr(ts_wstr),.axi_rstr(ts_rstr),
    .axi_wack(ts_wack),.axi_rack(ts_rack),
    .axi_raddr(axilReadMaster_araddr_r[7:0]),
    .axi_waddr(axilWriteMaster_awaddr_r[7:0]),
    .axi_din(axilWriteMaster_wdata),
    .axi_dout(ts_dout)
    );


  wire locRefClk, refClkD2;
  IBUFDS_GTE2 #(
      .CLKCM_CFG("TRUE"),   // Refer to Transceiver User Guide
      .CLKRCV_TRST("TRUE"), // Refer to Transceiver User Guide
      .CLKSWING_CFG(2'b11)  // Refer to Transceiver User Guide
   )
   IBUFDS_GTE2_inst (
      .O(locRefClk),         // 1-bit output: Refer to Transceiver User Guide
      .ODIV2(refClkD2), // 1-bit output: Refer to Transceiver User Guide
      .CEB(1'h0),     // 1-bit input: Refer to Transceiver User Guide
      .I(locRefClkP),         // 1-bit input: Refer to Transceiver User Guide
      .IB(locRefClkM)        // 1-bit input: Refer to Transceiver User Guide
   );

    wire qpll_lock, qpll_clkout, qpll_refclkout, qpll_refclklost;
    wire [1:0] qpll_reset;

   gt_pfclktx_common qpll
(
    .QPLLREFCLKSEL_IN(3'b001),
    .GTREFCLK0_IN(locRefClk),
    .GTREFCLK1_IN(1'h0),
    .QPLLLOCK_OUT(qpll_lock),
    .QPLLLOCKDETCLK_IN(sysClk125),
    .QPLLOUTCLK_OUT(qpll_clkout),
    .QPLLOUTREFCLK_OUT(qpll_refclkout),
    .QPLLREFCLKLOST_OUT(qpll_refclklost),
    .QPLLRESET_IN(sysClk125Rst|qpll_reset[0]|qpll_reset[1])
);


   genvar i0;
   generate
      for ( i0 = 0 ; i0 < 2 ; i0 = i0 + 1 )
      begin: bkplane_l

        wire [15:0] data_to_link;
        wire [1:0] k_to_link;
        wire link_valid;
        wire [31:0] data_from_link;
        wire [3:0] k_from_link;

        wb_bridge_axi wb_bridge(
        .clk_link(clk_link),
        .reset(axilRst),
        .data_to_link(data_to_link),
        .k_to_link(k_to_link),
        .data_from_link(data_from_link),
        .k_from_link(k_from_link),
        .link_valid(link_valid),
        .fast_control_encoded(fc_stream),
        .axi_clk(axilClk),
        .axi_wstr(wb_wstr[i0]),.axi_rstr(wb_rstr[i0]),
        .axi_wack(wb_wack[i0]),.axi_rack(wb_rack[i0]),
        .axi_raddr(axilReadMaster_araddr_r[7:0]),
        .axi_waddr(axilWriteMaster_awaddr_r[7:0]),
        .axi_din(axilWriteMaster_wdata),
        .axi_dout(wb_dout[(31+i0*32):(i0*32)])
        );

        olink daqGTX(.clk_125(sysClk125),
	     .reset(sysClk125Rst),
         .clk_tx_raw(clk_tx_raw[i0]),
         .clk_tx_mmcm_reset(mmcm_reset[i0]),
         .clk_link_lock(olink_clk_locked),
         .clk_link(clk_link),
         .qpll_lock(qpll_lock), .qpll_clkout(qpll_clkout), .qpll_refclkout(qpll_refclkout), .qpll_refclklost(qpll_refclklost),
         .qpll_reset(qpll_reset[i0]),
         .rx_n(rtmToDpmHsM[(i0*2+1):(i0*2)]),
         .rx_p(rtmToDpmHsP[(i0*2+1):(i0*2)]),
         .tx_n(dpmToRtmHsM[(i0*2+1):(i0*2)]),
         .tx_p(dpmToRtmHsP[(i0*2+1):(i0*2)]),
	 .refclk({locRefClk,1'h0}),
         .tx_d(data_to_link),
         .tx_k(k_to_link),
         .rx_d(data_from_link),
         .rx_k(k_from_link),
         .rx_v(link_valid),
		     .ts_rx_clk(ts_rx_clk[i0]),
		     .ts_rx_k(ts_rx_k[(2*i0+1):(2*i0)]),
		     .ts_rx_err(ts_rx_err[(2*i0+1):(2*i0)]),
		     .ts_rx_d(ts_rx_d[(16*i0+15):(16*i0)]),
        .axi_clk(axilClk),
        .axi_wstr(gt_wstr[i0]),.axi_rstr(gt_rstr[i0]),
        .axi_wack(gt_wack[i0]),.axi_rack(gt_rack[i0]),
        .axi_raddr(axilReadMaster_araddr_r[7:0]),
        .axi_waddr(axilWriteMaster_awaddr_r[7:0]),
        .axi_din(axilWriteMaster_wdata),
        .axi_dout(gt_dout[(31+i0*32):(i0*32)])
         );
      end
   endgenerate


  axi_merge_ldmx_jm core_if_jm(.axilClk(axilClk),
   .axilRst(axilRst),
   .raddr(axilReadMaster_araddr_r),
   .rready(axilReadMaster_rready),
   .rstart(axi_rstart),
   .rdata(axilReadSlave_rdata),
   .rresp(axilReadSlave_rresp),
   .rvalid(axilReadSlave_rvalid),
   .waddr(axilWriteMaster_awaddr_r),
   .wstart(axilWriteMaster_wvalid),
   .bready(axilWriteMaster_bready),
   .wready(axilWriteSlave_wready),
   .bresp(axilWriteSlave_bresp),
   .bvalid(axilWriteSlave_bvalid),
   .fc_wstr(fc_wstr), .fc_rstr(fc_rstr),
   .fc_wack(fc_wack), .fc_rack(fc_rack),
   .fc_din(fc_dout),
   .ts_wstr(ts_wstr), .ts_rstr(ts_rstr),
   .ts_wack(ts_wack), .ts_rack(ts_rack),
   .ts_din(ts_dout),
   .gt_wstr(gt_wstr), .gt_rstr(gt_rstr),
   .gt_wack(gt_wack), .gt_rack(gt_rack),
   .gt_din(gt_dout),
   .wb_wstr(wb_wstr), .wb_rstr(wb_rstr),
   .wb_wack(wb_wack), .wb_rack(wb_rack),
   .wb_din(wb_dout)
   );

   assign dmaClk = sysClk200;
   assign dmaRst = sysClk200Rst;

   assign dmaObSlave_tReady   = dmaIbSlave_tReady;
   assign dmaIbMaster_tValid  = dmaObMaster_tValid;
   assign dmaIbMaster_tData   = dmaObMaster_tData;
   assign dmaIbMaster_tStrb   = dmaObMaster_tStrb;
   assign dmaIbMaster_tKeep   = dmaObMaster_tKeep;
   assign dmaIbMaster_tLast   = dmaObMaster_tLast;
   assign dmaIbMaster_tDest   = dmaObMaster_tDest;
   assign dmaIbMaster_tId     = dmaObMaster_tId;
   assign dmaIbMaster_tUser   = dmaObMaster_tUser;

   reg ibusy;

   always @(posedge distDivClk) begin
    if (distDivClkRst) begin
       ibusy <= 1'h0;
    end else begin
       ibusy <= trigger | spill;
    end
  end

  assign busy = ibusy;

endmodule

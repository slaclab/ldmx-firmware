
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
   output wire [1:0]    dpmToRtmHsP;
   output wire [1:0]    dpmToRtmHsM;
   input  wire [1:0]    rtmToDpmHsP;
   input  wire [1:0]    rtmToDpmHsM;

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

  trigscint ts_block(.clk125(sysClk125),
		     .refclk_p(locRefClkP),.refclk_n(locRefClkM),
		     .rx_p(rtmToDpmHsP[1:0]),.rx_n(rtmToDpmHsM[1:0]),
		     .tx_p(dpmToRtmHsP[1:0]),.tx_n(dpmToRtmHsM[1:0]),
    .reset(axilRst),
    .axi_clk(axilClk),
    .axi_wstr(ts_wstr),.axi_rstr(ts_rstr),
    .axi_wack(ts_wack),.axi_rack(ts_rack),
    .axi_raddr(axilReadMaster_araddr_r[7:0]),
    .axi_waddr(axilWriteMaster_awaddr_r[7:0]),
    .axi_din(axilWriteMaster_wdata),
    .axi_dout(ts_dout)
    );


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
   .ts_din(ts_dout)
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

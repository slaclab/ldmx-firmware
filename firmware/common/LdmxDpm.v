
`timescale 1ns/10ps

// Edge Module Definition
module LdmxDpm ( sysClk125, sysClk125Rst, sysClk200, sysClk200Rst, locRefClkP, locRefClkM, axilClk, axilRst,
                 axilReadMaster_araddr, axilReadMaster_arprot, axilReadMaster_arvalid, axilReadMaster_rready, axilReadSlave_arready,
                 axilReadSlave_rdata, axilReadSlave_rresp, axilReadSlave_rvalid, axilWriteMaster_awaddr, axilWriteMaster_awprot,
                 axilWriteMaster_awvalid, axilWriteMaster_wdata, axilWriteMaster_wstrb, axilWriteMaster_wvalid, axilWriteMaster_bready,
                 axilWriteSlave_awready, axilWriteSlave_wready, axilWriteSlave_bresp, axilWriteSlave_bvalid, dmaClk, dmaRst,
                 dmaObMaster_tValid, dmaObMaster_tData, dmaObMaster_tStrb, dmaObMaster_tKeep, dmaObMaster_tLast, dmaObMaster_tDest,
                 dmaObMaster_tId, dmaObMaster_tUser, dmaObSlave_tReady, dmaIbMaster_tValid, dmaIbMaster_tData, dmaIbMaster_tStrb,
                 dmaIbMaster_tKeep, dmaIbMaster_tLast, dmaIbMaster_tDest, dmaIbMaster_tId, dmaIbMaster_tUser, dmaIbSlave_tReady, dpmToRtmHsP,
                 dpmToRtmHsM, rtmToDpmHsP, rtmToDpmHsM, rxDataA, rxDataAEn, rxDataB, rxDataBEn, txData, txDataEn, txReady);

   // Clocks and Resets
   input  wire          sysClk125;
   input  wire          sysClk125Rst;
   input  wire          sysClk200;
   input  wire          sysClk200Rst;

   // External reference clock
   input  wire          locRefClkP;
   input  wire          locRefClkM;

   // AXI-Lite Interface
   input  wire          axilClk;
   input  wire          axilRst;
   input  wire [31:0]   axilReadMaster_araddr;
   input  wire [2:0]    axilReadMaster_arprot;
   input  wire          axilReadMaster_arvalid;
   input  wire          axilReadMaster_rready;
   output wire          axilReadSlave_arready;
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
   output wire          axilWriteSlave_awready;
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
   input  wire [9:0]    rxDataA;
   input  wire          rxDataAEn;
   input  wire [9:0]    rxDataB;
   input  wire          rxDataBEn;
   output wire [9:0]    txData;
   output wire          txDataEn;
   input  wire          txReady;






   assign axilReadSlave_arready  = 0;
   assign axilReadSlave_rdata    = 0;
   assign axilReadSlave_rresp    = 0;
   assign axilReadSlave_rvalid   = 0;
   assign axilWriteSlave_awready = 0;
   assign axilWriteSlave_wready  = 0;
   assign axilWriteSlave_bresp   = 0;
   assign axilWriteSlave_bvalid  = 0;

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

   assign txData   = rxDataA | rxDataB;
   assign txDataEn = rxDataAEn | rxDataBEn;








endmodule

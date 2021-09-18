
`timescale 1ns/10ps

// Edge Module Definition
module LdmxDtm ( sysClk125, sysClk125Rst, sysClk200, sysClk200Rst, locRefClkP, locRefClkM, axilClk, axilRst,
                 axilReadMaster_araddr, axilReadMaster_arprot, axilReadMaster_arvalid, axilReadMaster_rready, axilReadSlave_arready,
                 axilReadSlave_rdata, axilReadSlave_rresp, axilReadSlave_rvalid, axilWriteMaster_awaddr, axilWriteMaster_awprot,
                 axilWriteMaster_awvalid, axilWriteMaster_wdata, axilWriteMaster_wstrb, axilWriteMaster_wvalid, axilWriteMaster_bready,
                 axilWriteSlave_awready, axilWriteSlave_wready,
                 axilWriteSlave_bresp, axilWriteSlave_bvalid, dtmToRtmLsP, dtmToRtmLsM,
                 distClk, distClkRst, txDataA, txDataAEn, txDataB, txDataBEn, txReadyA, txReadyB, rxDataA,
                 rxDataAEn, rxDataB, rxDataBEn, rxDataC, rxDataCEn, rxDataD, rxDataDEn, rxDataE, rxDataEEn, rxDataF, rxDataFEn,
                 rxDataG, rxDataGEn, rxDataH, rxDataHEn, gtTxP, gtTxN, gtRxP, gtRxN);

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

   // RTM Signals
   inout  wire [5:0]    dtmToRtmLsP;
   inout  wire [5:0]    dtmToRtmLsM;

   // COB Timing Interface
   output wire          distClk;
   output wire          distClkRst;
   output wire [9:0]    txDataA;
   output wire          txDataAEn;
   output wire [9:0]    txDataB;
   output wire          txDataBEn;
   input  wire          txReadyA;
   input  wire          txReadyB;
   input  wire [9:0]    rxDataA;
   input  wire          rxDataAEn;
   input  wire [9:0]    rxDataB;
   input  wire          rxDataBEn;
   input  wire [9:0]    rxDataC;
   input  wire          rxDataCEn;
   input  wire [9:0]    rxDataD;
   input  wire          rxDataDEn;
   input  wire [9:0]    rxDataE;
   input  wire          rxDataEEn;
   input  wire [9:0]    rxDataF;
   input  wire          rxDataFEn;
   input  wire [9:0]    rxDataG;
   input  wire          rxDataGEn;
   input  wire [9:0]    rxDataH;
   input  wire          rxDataHEn;

   output wire          gtTxP;
   output wire          gtTxN;
   input  wire          gtRxP;
   input  wire          gtRxN;

   assign axilReadSlave_arready  = 0;
   assign axilReadSlave_rdata    = 0;
   assign axilReadSlave_rresp    = 0;
   assign axilReadSlave_rvalid   = 0;
   assign axilWriteSlave_awready = 0;
   assign axilWriteSlave_wready  = 0;
   assign axilWriteSlave_bresp   = 0;
   assign axilWriteSlave_bvalid  = 0;

   assign dtmToRtmLsP = 0;
   assign dtmToRtmLsM = 0;

   assign distClk = sysClk125;
   assign distRst = sysClk125Rst;

   assign txDataA = 0;
   assign txDataAEn = 0;
   assign txDataB = 0;
   assign txDataBEn = 0;

endmodule

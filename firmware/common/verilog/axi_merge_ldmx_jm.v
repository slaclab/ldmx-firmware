`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/24/2021 07:55:39 AM
// Design Name: 
// Module Name: axi_merge_ldmx_jm
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module axi_merge_ldmx_jm(
   input  wire          axilClk,
   input  wire          axilRst,
   input  wire [17:0]   raddr,
   input  wire          rready,
   input  wire          rstart,
   output reg [31:0]    rdata,
   output reg [1:0]     rresp,
   output reg           rvalid,
   input  wire [17:0]   waddr,
   input  wire          wstart,
   input  wire          bready,
   output reg           wready,
   output reg [1:0]     bresp,
   output reg           bvalid,
   output reg fc_wstr, fc_rstr,
   input wire fc_wack, fc_rack,
   input [31:0] fc_din, 
   output reg ts_wstr, ts_rstr,
   input wire ts_wack, ts_rack,
   input [31:0] ts_din
    );
    
    localparam ADDR_FASTCONTROL = 18'h00100; // 0x400 with shift
    localparam MASK_FASTCONTROL = 18'h3FF00;
    localparam ADDR_OLINK0      = 18'h01000; // 0x4000 with shift
    localparam MASK_OLINK0      = 18'h3F000; 
    localparam ADDR_OLINK1      = 18'h02000; // 0x8000 with shift
    localparam MASK_OLINK1      = 18'h3F000;
    localparam ADDR_WISHBONE0   = 18'h11000; // 0x44000 with shift
    localparam MASK_WISHBONE0   = 18'h3F000;
    localparam ADDR_WISHBONE1   = 18'h12000; // 0x48000 with shift
    localparam MASK_WISHBONE1   = 18'h3F000;
    localparam ADDR_TSLINKS     = 18'h14000; // 0x50000 with shift
    localparam MASK_TSLINKS     = 18'h3F000;

/// read logic    
    reg invalid_raddr_ack;

    always @(posedge axilClk) 
        if (axilRst || (rready && rvalid)) begin
           invalid_raddr_ack<=1'h0;
           fc_rstr<=1'h0;
           ts_rstr<=1'h0;
        end else if (rstart) begin
           /// address decoding
           if ((raddr&MASK_FASTCONTROL)==ADDR_FASTCONTROL) fc_rstr<=1'h1;
           else if ((raddr&MASK_TSLINKS)==ADDR_TSLINKS) ts_rstr<=1'h1;
           else invalid_raddr_ack<=1'h1;
        end 
    
    always @(posedge axilClk)
        if (axilRst) begin 
          rdata<=32'h0;
          rresp<=2'h0;
          rvalid<=1'h0;
        end else begin
           rdata<=fc_din | ts_din ;	   
          rvalid<=invalid_raddr_ack | fc_rack | ts_rack;
          if (invalid_raddr_ack) rresp<=2'h3;
          else rresp<=2'h0;
        end 

/// write logic    
    reg invalid_waddr_ack;
    reg wtrans;

    always @(posedge axilClk) 
        if (axilRst || (bready && bvalid)) begin
           invalid_waddr_ack<=1'h0;
           fc_wstr<=1'h0;
	   ts_wstr<=1'h0;	   
           wtrans<=1'h0;
        end else if (wstart) begin
           wtrans<=1'h1;
           /// address decoding
           if ((waddr&MASK_FASTCONTROL)==ADDR_FASTCONTROL) fc_wstr<=1'h1;
           else if ((waddr&MASK_TSLINKS)==ADDR_TSLINKS) ts_wstr<=1'h1;
           else invalid_waddr_ack<=1'h1;
        end 
    
    wire protowready;
    assign protowready=invalid_waddr_ack | fc_wack | ts_wack;
    reg was_protowready;    
    
    always @(posedge axilClk)
        if (axilRst) begin 
          wready<=1'h0;
          was_protowready=1'h0;
        end else begin
          wready<=(protowready && ~was_protowready);
          was_protowready<=protowready;
        end 

    wire got_wvalid;
    assign got_wvalid=wtrans; // logic of valid is here...
    reg got_wready;

    always @(posedge axilClk)
        if (axilRst || !wtrans || bvalid) got_wready<=1'h0;
        else if (wready) got_wready=1'h1;
        else got_wready<=got_wready;

    always @(posedge axilClk)
        if (axilRst) bvalid<=1'h0;
        else if (bready && bvalid) bvalid<=1'h0;
        else if (got_wvalid && got_wready) bvalid<=1'h1;
        else bvalid<=bvalid;

    always @(posedge axilClk)
        if (axilRst) begin 
          bresp<=2'h0;
        end else begin
          if (invalid_waddr_ack) bresp<=2'h3;
          else bresp<=2'h0;
        end 
        
    
endmodule

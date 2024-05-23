////////////////////////////////////////////////////////////////////////////////
// Copyright (C) 1999-2008 Easics NV.
// This source file may be used and distributed without restriction
// provided that this copyright statement is not removed from the file
// and that any derivative work contains the original copyright notice
// and the associated disclaimer.
//
// THIS SOURCE FILE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS
// OR IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
// WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
//
// Purpose : synthesizable CRC function
//   * polynomial: x^16 + x^12 + x^5 + 1
//   * data width: 32
//
// Info : tools@easics.be
//        http://www.easics.com
////////////////////////////////////////////////////////////////////////////////
module CRC16_D32(input [31:0] Data,
                 input 	       clk,
                 input 	       ce,
		 input  [1:0]  we,
                 input 	       reset,
                 output [15:0] crc);


   reg [15:0] 		       crc_i;
   assign crc = crc_i;

   wire [31:0] 		       DataEff;
   assign DataEff[15:0]=(we[0])?(Data[15:0]):(16'h0);
   assign DataEff[31:16]=(we[1])?(Data[31:16]):(16'h0);
   
   
   always @(posedge clk) begin
      if (~ce)
	crc_i <= crc_i;
      else begin
         if (reset) crc_i <= nextCRC16_D32(DataEff, 16'h0);
         else crc_i <= nextCRC16_D32(DataEff, crc_i);
      end
   end

  // polynomial: x^16 + x^12 + x^5 + 1
  // data width: 32
  // convention: the first serial bit is D[31]
  function [15:0] nextCRC16_D32;

    input [31:0] Data;
    input [15:0] crc;
    reg [31:0] d;
    reg [15:0] c;
    reg [15:0] newcrc;
  begin
    d = Data;
    c = crc;

    newcrc[0] = d[28] ^ d[27] ^ d[26] ^ d[22] ^ d[20] ^ d[19] ^ d[12] ^ d[11] ^ d[8] ^ d[4] ^ d[0] ^ c[3] ^ c[4] ^ c[6] ^ c[10] ^ c[11] ^ c[12];
    newcrc[1] = d[29] ^ d[28] ^ d[27] ^ d[23] ^ d[21] ^ d[20] ^ d[13] ^ d[12] ^ d[9] ^ d[5] ^ d[1] ^ c[4] ^ c[5] ^ c[7] ^ c[11] ^ c[12] ^ c[13];
    newcrc[2] = d[30] ^ d[29] ^ d[28] ^ d[24] ^ d[22] ^ d[21] ^ d[14] ^ d[13] ^ d[10] ^ d[6] ^ d[2] ^ c[5] ^ c[6] ^ c[8] ^ c[12] ^ c[13] ^ c[14];
    newcrc[3] = d[31] ^ d[30] ^ d[29] ^ d[25] ^ d[23] ^ d[22] ^ d[15] ^ d[14] ^ d[11] ^ d[7] ^ d[3] ^ c[6] ^ c[7] ^ c[9] ^ c[13] ^ c[14] ^ c[15];
    newcrc[4] = d[31] ^ d[30] ^ d[26] ^ d[24] ^ d[23] ^ d[16] ^ d[15] ^ d[12] ^ d[8] ^ d[4] ^ c[0] ^ c[7] ^ c[8] ^ c[10] ^ c[14] ^ c[15];
    newcrc[5] = d[31] ^ d[28] ^ d[26] ^ d[25] ^ d[24] ^ d[22] ^ d[20] ^ d[19] ^ d[17] ^ d[16] ^ d[13] ^ d[12] ^ d[11] ^ d[9] ^ d[8] ^ d[5] ^ d[4] ^ d[0] ^ c[0] ^ c[1] ^ c[3] ^ c[4] ^ c[6] ^ c[8] ^ c[9] ^ c[10] ^ c[12] ^ c[15];
    newcrc[6] = d[29] ^ d[27] ^ d[26] ^ d[25] ^ d[23] ^ d[21] ^ d[20] ^ d[18] ^ d[17] ^ d[14] ^ d[13] ^ d[12] ^ d[10] ^ d[9] ^ d[6] ^ d[5] ^ d[1] ^ c[1] ^ c[2] ^ c[4] ^ c[5] ^ c[7] ^ c[9] ^ c[10] ^ c[11] ^ c[13];
    newcrc[7] = d[30] ^ d[28] ^ d[27] ^ d[26] ^ d[24] ^ d[22] ^ d[21] ^ d[19] ^ d[18] ^ d[15] ^ d[14] ^ d[13] ^ d[11] ^ d[10] ^ d[7] ^ d[6] ^ d[2] ^ c[2] ^ c[3] ^ c[5] ^ c[6] ^ c[8] ^ c[10] ^ c[11] ^ c[12] ^ c[14];
    newcrc[8] = d[31] ^ d[29] ^ d[28] ^ d[27] ^ d[25] ^ d[23] ^ d[22] ^ d[20] ^ d[19] ^ d[16] ^ d[15] ^ d[14] ^ d[12] ^ d[11] ^ d[8] ^ d[7] ^ d[3] ^ c[0] ^ c[3] ^ c[4] ^ c[6] ^ c[7] ^ c[9] ^ c[11] ^ c[12] ^ c[13] ^ c[15];
    newcrc[9] = d[30] ^ d[29] ^ d[28] ^ d[26] ^ d[24] ^ d[23] ^ d[21] ^ d[20] ^ d[17] ^ d[16] ^ d[15] ^ d[13] ^ d[12] ^ d[9] ^ d[8] ^ d[4] ^ c[0] ^ c[1] ^ c[4] ^ c[5] ^ c[7] ^ c[8] ^ c[10] ^ c[12] ^ c[13] ^ c[14];
    newcrc[10] = d[31] ^ d[30] ^ d[29] ^ d[27] ^ d[25] ^ d[24] ^ d[22] ^ d[21] ^ d[18] ^ d[17] ^ d[16] ^ d[14] ^ d[13] ^ d[10] ^ d[9] ^ d[5] ^ c[0] ^ c[1] ^ c[2] ^ c[5] ^ c[6] ^ c[8] ^ c[9] ^ c[11] ^ c[13] ^ c[14] ^ c[15];
    newcrc[11] = d[31] ^ d[30] ^ d[28] ^ d[26] ^ d[25] ^ d[23] ^ d[22] ^ d[19] ^ d[18] ^ d[17] ^ d[15] ^ d[14] ^ d[11] ^ d[10] ^ d[6] ^ c[1] ^ c[2] ^ c[3] ^ c[6] ^ c[7] ^ c[9] ^ c[10] ^ c[12] ^ c[14] ^ c[15];
    newcrc[12] = d[31] ^ d[29] ^ d[28] ^ d[24] ^ d[23] ^ d[22] ^ d[18] ^ d[16] ^ d[15] ^ d[8] ^ d[7] ^ d[4] ^ d[0] ^ c[0] ^ c[2] ^ c[6] ^ c[7] ^ c[8] ^ c[12] ^ c[13] ^ c[15];
    newcrc[13] = d[30] ^ d[29] ^ d[25] ^ d[24] ^ d[23] ^ d[19] ^ d[17] ^ d[16] ^ d[9] ^ d[8] ^ d[5] ^ d[1] ^ c[0] ^ c[1] ^ c[3] ^ c[7] ^ c[8] ^ c[9] ^ c[13] ^ c[14];
    newcrc[14] = d[31] ^ d[30] ^ d[26] ^ d[25] ^ d[24] ^ d[20] ^ d[18] ^ d[17] ^ d[10] ^ d[9] ^ d[6] ^ d[2] ^ c[1] ^ c[2] ^ c[4] ^ c[8] ^ c[9] ^ c[10] ^ c[14] ^ c[15];
    newcrc[15] = d[31] ^ d[27] ^ d[26] ^ d[25] ^ d[21] ^ d[19] ^ d[18] ^ d[11] ^ d[10] ^ d[7] ^ d[3] ^ c[2] ^ c[3] ^ c[5] ^ c[9] ^ c[10] ^ c[11] ^ c[15];
    nextCRC16_D32 = newcrc;
  end
  endfunction
endmodule

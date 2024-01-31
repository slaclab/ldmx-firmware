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
//   * polynomial: x^8 + x^2 + x^1 + 1
//   * data width: 13
//
// Info : tools@easics.be
//        http://www.easics.com
////////////////////////////////////////////////////////////////////////////////
module CRC8_D13(input [12:0] data,
                output reg [7:0] crc);

  always @* begin
    crc = nextCRC8_D13(data, 8'b0);
  end

  // polynomial: x^8 + x^2 + x^1 + 1
  // data width: 13
  // convention: the first serial bit is D[12]
  function [7:0] nextCRC8_D13;

    input [12:0] Data;
    input [7:0] crc;
    reg [12:0] d;
    reg [7:0] c;
    reg [7:0] newcrc;
  begin
    d = Data;
    c = crc;

    newcrc[0] = d[12] ^ d[8] ^ d[7] ^ d[6] ^ d[0] ^ c[1] ^ c[2] ^ c[3] ^ c[7];
    newcrc[1] = d[12] ^ d[9] ^ d[6] ^ d[1] ^ d[0] ^ c[1] ^ c[4] ^ c[7];
    newcrc[2] = d[12] ^ d[10] ^ d[8] ^ d[6] ^ d[2] ^ d[1] ^ d[0] ^ c[1] ^ c[3] ^ c[5] ^ c[7];
    newcrc[3] = d[11] ^ d[9] ^ d[7] ^ d[3] ^ d[2] ^ d[1] ^ c[2] ^ c[4] ^ c[6];
    newcrc[4] = d[12] ^ d[10] ^ d[8] ^ d[4] ^ d[3] ^ d[2] ^ c[3] ^ c[5] ^ c[7];
    newcrc[5] = d[11] ^ d[9] ^ d[5] ^ d[4] ^ d[3] ^ c[0] ^ c[4] ^ c[6];
    newcrc[6] = d[12] ^ d[10] ^ d[6] ^ d[5] ^ d[4] ^ c[0] ^ c[1] ^ c[5] ^ c[7];
    newcrc[7] = d[11] ^ d[7] ^ d[6] ^ d[5] ^ c[0] ^ c[1] ^ c[2] ^ c[6];
    nextCRC8_D13 = newcrc;
  end
  endfunction
endmodule

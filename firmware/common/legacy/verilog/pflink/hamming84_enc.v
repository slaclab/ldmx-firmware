/**
  SECDED Hamming encoder.
  4-bit source data.
  8-bit encoding.

  University of Minnesota
  Elijah Berscheid
  5-21-2020
**/
module hamming84_enc(data_in, enc_out);
  input [3:0] data_in;
  output [7:0] enc_out;

  wire [3:0] d; // Shorthand for input data
  assign d = data_in;

  wire [3:0] c; // Parity bits

  // Index:         7     6     5     4     3     2     1     0
  // Bit position:  8     7     6     5     4     3     2     1
  assign enc_out = {c[3], d[3], d[2], d[1], c[2], d[0], c[1], c[0]};

  assign c[0] = d[3] ^ d[1] ^ d[0];
  assign c[1] = d[3] ^ d[2] ^ d[0];
  assign c[2] = d[3] ^ d[2] ^ d[1];
  assign c[3] = ^enc_out[6:0];

endmodule

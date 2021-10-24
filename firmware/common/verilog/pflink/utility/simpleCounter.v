module simpleCounter
  (input reset_in,
   input clk,
   input ce,
   output reg [23:0] value);
   

always @(posedge clk)
  if (reset_in) value<='h0;
  else value<=value+ce;
   
endmodule

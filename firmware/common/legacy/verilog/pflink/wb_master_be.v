module wb_master_be(input         clklink, // 4*BX-rate clock ("160")
                    input         reset,
                    output [15:0] optical_data_out, // to the fiber
                    output  [1:0] optical_data_kout,
                    input  [31:0] optical_data_in, // from the fiber
                    input   [3:0] optical_data_kin,
                    input         optical_data_valid,
                    input  [15:0] encoded_fastcontrol, // the fast-control word
                    input         wb_reset,
                    input         wb_we,
                    input  [31:0] wb_dato,
                    input  [17:0] wb_addr,
                    input   [4:0] wb_target,
                    input         wb_str,
                    input         wb_cyc,
                    output        wb_err,
                    output        wb_ack,
                    output [31:0] wb_dati,
                    output        downlink_crc_err,
						  output        uplink_crc_err,
						  input crc_bypass);

  localparam COMMA = 8'hbc;

  // 3 bit state counter
  reg [2:0] state;

  // The word to send
  reg  [15:0] word, word_d;
   reg 	      comma_now;
	reg         comma_d;
   
  wire [15:0] next_word;
  assign optical_data_out = word_d;
   assign optical_data_kout[1]=1'b0;
   assign optical_data_kout[0]=comma_d;
   
  // CRC 16 "checksum"
  wire [15:0] crc;

  // Input buffers
  reg        wb_reset_b;
  reg        wb_we_b;
  reg [31:0] wb_dato_b;
  reg [17:0] wb_addr_b;
  reg  [4:0] wb_target_b;
  reg        wb_str_b;
  reg        wb_cyc_b;

  // Downlink state machine
  always @(posedge clklink) begin
    // reset is synchronous
    if(reset == 1'b1) begin
      state <=  3'b0;
      word  <= 16'b0;
    end
    else begin
       state <= state + 3'b1; // overflow after 3'd7
		 word_d <= (state==3'h0)?(crc):(word);
       word  <= next_word;
		 comma_d <= comma_now;
       comma_now <= (state==3'h0 || state==3'h4)?(1'b1):(1'b0);       
    end

    // Set input buffers
    if(reset == 1'b1 || state == 3'd7) begin
      wb_reset_b  <= wb_reset;
      wb_we_b     <= wb_we;
      wb_dato_b   <= wb_dato;
      wb_addr_b   <= wb_addr;
      wb_target_b <= wb_target;
      wb_str_b    <= wb_str;
      wb_cyc_b    <= wb_cyc;
    end
  end

  // Downlink next state logic for 'word'
  assign next_word[15:8] =
    (state == 3'd0) ? {1'b0, 3'b0, wb_reset_b, wb_we_b, wb_str_b, wb_cyc_b} :
    (state == 3'd1) ? encoded_fastcontrol[15:8] :
    (state == 3'd2) ? wb_dato_b[15:8] :
    (state == 3'd3) ? wb_dato_b[31:24] :
    (state == 3'd4) ? {1'b1, wb_target_b[4:0], wb_addr_b[17:16]} :
    (state == 3'd5) ? encoded_fastcontrol[15:8] :
    (state == 3'd6) ? wb_addr_b[15:8] :
                      8'h0;
  assign next_word[7:0] =
    (state == 3'd0) ? COMMA :
    (state == 3'd1) ? encoded_fastcontrol[7:0] :
    (state == 3'd2) ? wb_dato_b[7:0] :
    (state == 3'd3) ? wb_dato_b[23:16] :
    (state == 3'd4) ? COMMA :
    (state == 3'd5) ? encoded_fastcontrol[7:0] :
    (state == 3'd6) ? wb_addr_b[7:0] :
                      8'h0;

  // Downlink CRC
  wire [1:0] crc_we;
  wire crc_ce;
  CRC16_D32 CRC16_downlink(.Data({next_word,word}),
                           .clk(clklink),
                           .ce(state[0]),
									.we(2'b11), // crc is fed in as zero
                           .reset(state == 3'd1),
                           .crc(crc));

  /* ====================================================== */

  wire comma_condition;
  assign comma_condition = (optical_data_in[7:0] == COMMA)
                            && (optical_data_kin == 4'b0001);
  wire [7:0] crc_uplink;
  wire crc_uplink_correct;
  assign crc_uplink_correct = optical_data_in[31:24] == crc_uplink;

  // Convenient decoded labels
  wire       recv_crc_err;
  wire [1:0] uplink_wb_byte;
  wire       uplink_wb_err;
  wire       uplink_wb_ack;
  wire [7:0] uplink_wb_dati_byte;
  assign recv_crc_err      = optical_data_in[12];
  assign uplink_wb_byte      = optical_data_in[11:10];
  assign uplink_wb_err       = optical_data_in[9];
  assign uplink_wb_ack       = optical_data_in[8];
  assign uplink_wb_dati_byte = optical_data_in[23:16];

  // Output registers from uplink
  reg        wb_err_i;  assign wb_err  = wb_err_i;
  reg        wb_ack_i;  assign wb_ack  = wb_ack_i;
  reg [31:0] wb_dati_i; assign wb_dati = wb_dati_i;
  reg        downlink_crc_err_i; assign downlink_crc_err = downlink_crc_err_i;
  reg        uplink_crc_err_i; assign uplink_crc_err = uplink_crc_err_i;

  // Each of the four bits indicates whether the
  // corresponding dati byte has been received.
  reg [3:0] wb_dati_byte_count;
  // Buffer for loading individual bytes
  reg [31:0] wb_dati_b;

  // Uplink block
  always @(posedge clklink) begin
    if (comma_condition) uplink_crc_err_i<=!(crc_uplink_correct);

    if(reset || ~optical_data_valid) begin
      wb_err_i  <=  1'b0; // Output regs
      wb_ack_i  <=  1'b0; //   |
      wb_dati_i <= 32'b0; //   |
      downlink_crc_err_i <=  1'b0; // <-+
      wb_dati_byte_count <= 4'b0; // Tracks which dati bytes have been received
      wb_dati_b <= 32'b0; // Buffer for collecting all four bytes
    end
    else if(comma_condition && (crc_uplink_correct || crc_bypass)) begin
      // Write mode (no data from slave)
      if(wb_we_b) begin
        // Just pass everything thru; ignore wb_dati
        wb_err_i  <= uplink_wb_err;
        wb_ack_i  <= uplink_wb_ack;
        downlink_crc_err_i <= recv_crc_err;
        // Reset the byte counter for future read cycles
        wb_dati_byte_count <= 4'b0;
      end
      // Read mode (need 4 pkts to load data from slave)
      else if(uplink_wb_ack) begin
        // Load the proper byte in the wb_dati buffer
        case(uplink_wb_byte)
          2'd3: wb_dati_b[31:24] <= uplink_wb_dati_byte;
          2'd2: wb_dati_b[23:16] <= uplink_wb_dati_byte;
          2'd1: wb_dati_b[15:8]  <= uplink_wb_dati_byte;
          2'd0: wb_dati_b[7:0]   <= uplink_wb_dati_byte;
        endcase
        // Record which wb_dati byte was set
        wb_dati_byte_count[uplink_wb_byte] <= 1'b1;
        // Update output regs when every wb_dati byte is received
        if(wb_dati_byte_count==4'b1111) begin
          wb_err_i  <= uplink_wb_err;
          wb_ack_i  <= 1'b1;
          downlink_crc_err_i <= recv_crc_err;
          wb_dati_i <= wb_dati_b;
          // Reset the byte counter for future read cycles
          wb_dati_byte_count <= 4'b0;
        end
      end
      else begin // ~uplink_wb_ack
        wb_ack_i <= 1'b0;
        wb_dati_byte_count <= 4'b0;
      end
    end // END else if block to process uplink fiber
  end // END always

  // CRC does not cover the BX, at least right now...
  CRC8_D13 CRC8_uplink(.data({optical_data_in[23:16],optical_data_in[12:8]}), .crc(crc_uplink));

endmodule


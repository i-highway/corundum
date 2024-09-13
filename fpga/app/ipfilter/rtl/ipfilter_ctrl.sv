// Copyright (c) 2024 Intellectual Highway. All rights reserved.

module ipfilter_ctrl #(
    parameter  DATA_WIDTH  = 32,
    parameter  ADDR_WIDTH  = 24,
    parameter  NUM_ENTRIES = 16,
    localparam STRB_WIDTH  = DATA_WIDTH / 8
) (
    input clk,
    input rst_n,

    input  [ADDR_WIDTH-1:0] s_axil_awaddr,
    input  [           2:0] s_axil_awprot,
    input                   s_axil_awvalid,
    output                  s_axil_awready,
    input  [DATA_WIDTH-1:0] s_axil_wdata,
    input  [STRB_WIDTH-1:0] s_axil_wstrb,
    input                   s_axil_wvalid,
    output                  s_axil_wready,
    output [           1:0] s_axil_bresp,
    output                  s_axil_bvalid,
    input                   s_axil_bready,
    input  [ADDR_WIDTH-1:0] s_axil_araddr,
    input  [           2:0] s_axil_arprot,
    input                   s_axil_arvalid,
    output                  s_axil_arready,
    output [DATA_WIDTH-1:0] s_axil_rdata,
    output [           1:0] s_axil_rresp,
    output                  s_axil_rvalid,
    input                   s_axil_rready,

    output        tx_vld         [NUM_ENTRIES],
    output [31:0] tx_ipv4_addr   [NUM_ENTRIES],
    output [31:0] tx_ipv4_netmask[NUM_ENTRIES],
    output        rx_vld         [NUM_ENTRIES],
    output [31:0] rx_ipv4_addr   [NUM_ENTRIES],
    output [31:0] rx_ipv4_netmask[NUM_ENTRIES],
    input  [31:0] tx_drop_cnt,
    input  [31:0] rx_drop_cnt
);

  typedef enum logic [1:0] {
    WIDLE,
    WRITE,
    WRESP
  } wmode_e;

  typedef enum logic {
    RIDLE,
    RRESP
  } rmode_e;

  // ctrl register value
  logic tx_vld_int[NUM_ENTRIES];
  logic [31:0] tx_ipv4_addr_int[NUM_ENTRIES];
  logic [31:0] tx_ipv4_netmask_int[NUM_ENTRIES];
  logic rx_vld_int[NUM_ENTRIES];
  logic [31:0] rx_ipv4_addr_int[NUM_ENTRIES];
  logic [31:0] rx_ipv4_netmask_int[NUM_ENTRIES];
  logic [31:0] tx_drop_cnt_int;
  logic [31:0] rx_drop_cnt_int;

  // reg
  wmode_e wmode;
  logic [ADDR_WIDTH-1:0] waddr;
  rmode_e rmode;
  logic [DATA_WIDTH-1:0] rdata;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (int i = 0; i < NUM_ENTRIES; i++) begin
        tx_vld_int[i] <= '0;
        tx_ipv4_addr_int[i] <= '0;
        tx_ipv4_netmask_int[i] <= '0;
        rx_vld_int[i] <= '0;
        rx_ipv4_addr_int[i] <= '0;
        rx_ipv4_netmask_int[i] <= '0;
      end
      tx_drop_cnt_int <= '0;
      rx_drop_cnt_int <= '0;

      wmode <= WIDLE;
      waddr <= '0;
      rmode <= RIDLE;
      rdata <= '0;
    end else begin
      tx_drop_cnt_int <= tx_drop_cnt;
      rx_drop_cnt_int <= rx_drop_cnt;

      // write transaction
      case (wmode)
        WIDLE: begin
          if (s_axil_awvalid) begin
            waddr <= s_axil_awaddr;
            wmode <= WRITE;
          end
        end
        WRITE: begin
          if (s_axil_wvalid) begin
            case (waddr)
              'h0: tx_vld_int[0] <= s_axil_wdata[0];
              'h4: tx_ipv4_addr_int[0] <= s_axil_wdata;
              'h8: tx_ipv4_netmask_int[0] <= s_axil_wdata;
              'hc: tx_vld_int[1] <= s_axil_wdata[0];
              'h10: tx_ipv4_addr_int[1] <= s_axil_wdata;
              'h14: tx_ipv4_netmask_int[1] <= s_axil_wdata;
              'h18: tx_vld_int[2] <= s_axil_wdata[0];
              'h1c: tx_ipv4_addr_int[2] <= s_axil_wdata;
              'h20: tx_ipv4_netmask_int[2] <= s_axil_wdata;
              'h24: tx_vld_int[3] <= s_axil_wdata[0];
              'h28: tx_ipv4_addr_int[3] <= s_axil_wdata;
              'h2c: tx_ipv4_netmask_int[3] <= s_axil_wdata;
              'h30: tx_vld_int[4] <= s_axil_wdata[0];
              'h34: tx_ipv4_addr_int[4] <= s_axil_wdata;
              'h38: tx_ipv4_netmask_int[4] <= s_axil_wdata;
              'h3c: tx_vld_int[5] <= s_axil_wdata[0];
              'h40: tx_ipv4_addr_int[5] <= s_axil_wdata;
              'h44: tx_ipv4_netmask_int[5] <= s_axil_wdata;
              'h48: tx_vld_int[6] <= s_axil_wdata[0];
              'h4c: tx_ipv4_addr_int[6] <= s_axil_wdata;
              'h50: tx_ipv4_netmask_int[6] <= s_axil_wdata;
              'h54: tx_vld_int[7] <= s_axil_wdata[0];
              'h58: tx_ipv4_addr_int[7] <= s_axil_wdata;
              'h5c: tx_ipv4_netmask_int[7] <= s_axil_wdata;
              'h60: tx_vld_int[8] <= s_axil_wdata[0];
              'h64: tx_ipv4_addr_int[8] <= s_axil_wdata;
              'h68: tx_ipv4_netmask_int[8] <= s_axil_wdata;
              'h6c: tx_vld_int[9] <= s_axil_wdata[0];
              'h70: tx_ipv4_addr_int[9] <= s_axil_wdata;
              'h74: tx_ipv4_netmask_int[9] <= s_axil_wdata;
              'h78: tx_vld_int[10] <= s_axil_wdata[0];
              'h7c: tx_ipv4_addr_int[10] <= s_axil_wdata;
              'h80: tx_ipv4_netmask_int[10] <= s_axil_wdata;
              'h84: tx_vld_int[11] <= s_axil_wdata[0];
              'h88: tx_ipv4_addr_int[11] <= s_axil_wdata;
              'h8c: tx_ipv4_netmask_int[11] <= s_axil_wdata;
              'h90: tx_vld_int[12] <= s_axil_wdata[0];
              'h94: tx_ipv4_addr_int[12] <= s_axil_wdata;
              'h98: tx_ipv4_netmask_int[12] <= s_axil_wdata;
              'h9c: tx_vld_int[13] <= s_axil_wdata[0];
              'ha0: tx_ipv4_addr_int[13] <= s_axil_wdata;
              'ha4: tx_ipv4_netmask_int[13] <= s_axil_wdata;
              'ha8: tx_vld_int[14] <= s_axil_wdata[0];
              'hac: tx_ipv4_addr_int[14] <= s_axil_wdata;
              'hb0: tx_ipv4_netmask_int[14] <= s_axil_wdata;
              'hb4: tx_vld_int[15] <= s_axil_wdata[0];
              'hb8: tx_ipv4_addr_int[15] <= s_axil_wdata;
              'hbc: tx_ipv4_netmask_int[15] <= s_axil_wdata;
              'h100: rx_vld_int[0] <= s_axil_wdata[0];
              'h104: rx_ipv4_addr_int[0] <= s_axil_wdata;
              'h108: rx_ipv4_netmask_int[0] <= s_axil_wdata;
              'h10c: rx_vld_int[1] <= s_axil_wdata[0];
              'h110: rx_ipv4_addr_int[1] <= s_axil_wdata;
              'h114: rx_ipv4_netmask_int[1] <= s_axil_wdata;
              'h118: rx_vld_int[2] <= s_axil_wdata[0];
              'h11c: rx_ipv4_addr_int[2] <= s_axil_wdata;
              'h120: rx_ipv4_netmask_int[2] <= s_axil_wdata;
              'h124: rx_vld_int[3] <= s_axil_wdata[0];
              'h128: rx_ipv4_addr_int[3] <= s_axil_wdata;
              'h12c: rx_ipv4_netmask_int[3] <= s_axil_wdata;
              'h130: rx_vld_int[4] <= s_axil_wdata[0];
              'h134: rx_ipv4_addr_int[4] <= s_axil_wdata;
              'h138: rx_ipv4_netmask_int[4] <= s_axil_wdata;
              'h13c: rx_vld_int[5] <= s_axil_wdata[0];
              'h140: rx_ipv4_addr_int[5] <= s_axil_wdata;
              'h144: rx_ipv4_netmask_int[5] <= s_axil_wdata;
              'h148: rx_vld_int[6] <= s_axil_wdata[0];
              'h14c: rx_ipv4_addr_int[6] <= s_axil_wdata;
              'h150: rx_ipv4_netmask_int[6] <= s_axil_wdata;
              'h154: rx_vld_int[7] <= s_axil_wdata[0];
              'h158: rx_ipv4_addr_int[7] <= s_axil_wdata;
              'h15c: rx_ipv4_netmask_int[7] <= s_axil_wdata;
              'h160: rx_vld_int[8] <= s_axil_wdata[0];
              'h164: rx_ipv4_addr_int[8] <= s_axil_wdata;
              'h168: rx_ipv4_netmask_int[8] <= s_axil_wdata;
              'h16c: rx_vld_int[9] <= s_axil_wdata[0];
              'h170: rx_ipv4_addr_int[9] <= s_axil_wdata;
              'h174: rx_ipv4_netmask_int[9] <= s_axil_wdata;
              'h178: rx_vld_int[10] <= s_axil_wdata[0];
              'h17c: rx_ipv4_addr_int[10] <= s_axil_wdata;
              'h180: rx_ipv4_netmask_int[10] <= s_axil_wdata;
              'h184: rx_vld_int[11] <= s_axil_wdata[0];
              'h188: rx_ipv4_addr_int[11] <= s_axil_wdata;
              'h18c: rx_ipv4_netmask_int[11] <= s_axil_wdata;
              'h190: rx_vld_int[12] <= s_axil_wdata[0];
              'h194: rx_ipv4_addr_int[12] <= s_axil_wdata;
              'h198: rx_ipv4_netmask_int[12] <= s_axil_wdata;
              'h19c: rx_vld_int[13] <= s_axil_wdata[0];
              'h1a0: rx_ipv4_addr_int[13] <= s_axil_wdata;
              'h1a4: rx_ipv4_netmask_int[13] <= s_axil_wdata;
              'h1a8: rx_vld_int[14] <= s_axil_wdata[0];
              'h1ac: rx_ipv4_addr_int[14] <= s_axil_wdata;
              'h1b0: rx_ipv4_netmask_int[14] <= s_axil_wdata;
              'h1b4: rx_vld_int[15] <= s_axil_wdata[0];
              'h1b8: rx_ipv4_addr_int[15] <= s_axil_wdata;
              'h1bc: rx_ipv4_netmask_int[15] <= s_axil_wdata;
              default: ;
            endcase
            wmode <= WRESP;
          end
        end
        WRESP: begin
          if (s_axil_bready) begin
            wmode <= WIDLE;
          end
        end
        default: ;
      endcase

      // read transaction
      case (rmode)
        RIDLE: begin
          if (s_axil_arvalid) begin
            case (s_axil_araddr)
              'h0: rdata <= DATA_WIDTH'(tx_vld_int[0]);
              'h4: rdata <= tx_ipv4_addr_int[0];
              'h8: rdata <= tx_ipv4_netmask_int[0];
              'hc: rdata <= DATA_WIDTH'(tx_vld_int[1]);
              'h10: rdata <= tx_ipv4_addr_int[1];
              'h14: rdata <= tx_ipv4_netmask_int[1];
              'h18: rdata <= DATA_WIDTH'(tx_vld_int[2]);
              'h1c: rdata <= tx_ipv4_addr_int[2];
              'h20: rdata <= tx_ipv4_netmask_int[2];
              'h24: rdata <= DATA_WIDTH'(tx_vld_int[3]);
              'h28: rdata <= tx_ipv4_addr_int[3];
              'h2c: rdata <= tx_ipv4_netmask_int[3];
              'h30: rdata <= DATA_WIDTH'(tx_vld_int[4]);
              'h34: rdata <= tx_ipv4_addr_int[4];
              'h38: rdata <= tx_ipv4_netmask_int[4];
              'h3c: rdata <= DATA_WIDTH'(tx_vld_int[5]);
              'h40: rdata <= tx_ipv4_addr_int[5];
              'h44: rdata <= tx_ipv4_netmask_int[5];
              'h48: rdata <= DATA_WIDTH'(tx_vld_int[6]);
              'h4c: rdata <= tx_ipv4_addr_int[6];
              'h50: rdata <= tx_ipv4_netmask_int[6];
              'h54: rdata <= DATA_WIDTH'(tx_vld_int[7]);
              'h58: rdata <= tx_ipv4_addr_int[7];
              'h5c: rdata <= tx_ipv4_netmask_int[7];
              'h60: rdata <= DATA_WIDTH'(tx_vld_int[8]);
              'h64: rdata <= tx_ipv4_addr_int[8];
              'h68: rdata <= tx_ipv4_netmask_int[8];
              'h6c: rdata <= DATA_WIDTH'(tx_vld_int[9]);
              'h70: rdata <= tx_ipv4_addr_int[9];
              'h74: rdata <= tx_ipv4_netmask_int[9];
              'h78: rdata <= DATA_WIDTH'(tx_vld_int[10]);
              'h7c: rdata <= tx_ipv4_addr_int[10];
              'h80: rdata <= tx_ipv4_netmask_int[10];
              'h84: rdata <= DATA_WIDTH'(tx_vld_int[11]);
              'h88: rdata <= tx_ipv4_addr_int[11];
              'h8c: rdata <= tx_ipv4_netmask_int[11];
              'h90: rdata <= DATA_WIDTH'(tx_vld_int[12]);
              'h94: rdata <= tx_ipv4_addr_int[12];
              'h98: rdata <= tx_ipv4_netmask_int[12];
              'h9c: rdata <= DATA_WIDTH'(tx_vld_int[13]);
              'ha0: rdata <= tx_ipv4_addr_int[13];
              'ha4: rdata <= tx_ipv4_netmask_int[13];
              'ha8: rdata <= DATA_WIDTH'(tx_vld_int[14]);
              'hac: rdata <= tx_ipv4_addr_int[14];
              'hb0: rdata <= tx_ipv4_netmask_int[14];
              'hb4: rdata <= DATA_WIDTH'(tx_vld_int[15]);
              'hb8: rdata <= tx_ipv4_addr_int[15];
              'hbc: rdata <= tx_ipv4_netmask_int[15];
              'h100: rdata <= DATA_WIDTH'(rx_vld_int[0]);
              'h104: rdata <= rx_ipv4_addr_int[0];
              'h108: rdata <= rx_ipv4_netmask_int[0];
              'h10c: rdata <= DATA_WIDTH'(rx_vld_int[1]);
              'h110: rdata <= rx_ipv4_addr_int[1];
              'h114: rdata <= rx_ipv4_netmask_int[1];
              'h118: rdata <= DATA_WIDTH'(rx_vld_int[2]);
              'h11c: rdata <= rx_ipv4_addr_int[2];
              'h120: rdata <= rx_ipv4_netmask_int[2];
              'h124: rdata <= DATA_WIDTH'(rx_vld_int[3]);
              'h128: rdata <= rx_ipv4_addr_int[3];
              'h12c: rdata <= rx_ipv4_netmask_int[3];
              'h130: rdata <= DATA_WIDTH'(rx_vld_int[4]);
              'h134: rdata <= rx_ipv4_addr_int[4];
              'h138: rdata <= rx_ipv4_netmask_int[4];
              'h13c: rdata <= DATA_WIDTH'(rx_vld_int[5]);
              'h140: rdata <= rx_ipv4_addr_int[5];
              'h144: rdata <= rx_ipv4_netmask_int[5];
              'h148: rdata <= DATA_WIDTH'(rx_vld_int[6]);
              'h14c: rdata <= rx_ipv4_addr_int[6];
              'h150: rdata <= rx_ipv4_netmask_int[6];
              'h154: rdata <= DATA_WIDTH'(rx_vld_int[7]);
              'h158: rdata <= rx_ipv4_addr_int[7];
              'h15c: rdata <= rx_ipv4_netmask_int[7];
              'h160: rdata <= DATA_WIDTH'(rx_vld_int[8]);
              'h164: rdata <= rx_ipv4_addr_int[8];
              'h168: rdata <= rx_ipv4_netmask_int[8];
              'h16c: rdata <= DATA_WIDTH'(rx_vld_int[9]);
              'h170: rdata <= rx_ipv4_addr_int[9];
              'h174: rdata <= rx_ipv4_netmask_int[9];
              'h178: rdata <= DATA_WIDTH'(rx_vld_int[10]);
              'h17c: rdata <= rx_ipv4_addr_int[10];
              'h180: rdata <= rx_ipv4_netmask_int[10];
              'h184: rdata <= DATA_WIDTH'(rx_vld_int[11]);
              'h188: rdata <= rx_ipv4_addr_int[11];
              'h18c: rdata <= rx_ipv4_netmask_int[11];
              'h190: rdata <= DATA_WIDTH'(rx_vld_int[12]);
              'h194: rdata <= rx_ipv4_addr_int[12];
              'h198: rdata <= rx_ipv4_netmask_int[12];
              'h19c: rdata <= DATA_WIDTH'(rx_vld_int[13]);
              'h1a0: rdata <= rx_ipv4_addr_int[13];
              'h1a4: rdata <= rx_ipv4_netmask_int[13];
              'h1a8: rdata <= DATA_WIDTH'(rx_vld_int[14]);
              'h1ac: rdata <= rx_ipv4_addr_int[14];
              'h1b0: rdata <= rx_ipv4_netmask_int[14];
              'h1b4: rdata <= DATA_WIDTH'(rx_vld_int[15]);
              'h1b8: rdata <= rx_ipv4_addr_int[15];
              'h1bc: rdata <= rx_ipv4_netmask_int[15];
              'h200: rdata <= tx_drop_cnt_int;
              'h204: rdata <= rx_drop_cnt_int;
              default: ;
            endcase
            rmode <= RRESP;
          end
        end
        RRESP: begin
          if (s_axil_rready) begin
            rmode <= RIDLE;
          end
        end
      endcase
    end
  end

  assign s_axil_awready = (wmode == WIDLE);
  assign s_axil_wready  = (wmode == WRITE);
  assign s_axil_bresp   = '0;
  assign s_axil_bvalid  = (wmode == WRESP);
  assign s_axil_arready = (rmode == RIDLE);
  assign s_axil_rdata   = rdata;
  assign s_axil_rresp   = '0;
  assign s_axil_rvalid  = (rmode == RRESP);

  for (genvar i = 0; i < NUM_ENTRIES; i++) begin
    assign tx_vld[i] = tx_vld_int[i];
    assign tx_ipv4_addr[i] = tx_ipv4_addr_int[i];
    assign tx_ipv4_netmask[i] = tx_ipv4_netmask_int[i];
    assign rx_vld[i] = rx_vld_int[i];
    assign rx_ipv4_addr[i] = rx_ipv4_addr_int[i];
    assign rx_ipv4_netmask[i] = rx_ipv4_netmask_int[i];
  end

endmodule

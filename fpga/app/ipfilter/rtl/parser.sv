// Copyright (c) 2024 Intellectual Highway. All rights reserved.

// parse ipv4 header for ipfilter
// tdata is in network byte order
// only support DATA_WIDTH=64
module parser #(
    parameter  DATA_WIDTH = 64,
    localparam KEEP_WIDTH = DATA_WIDTH / 8
) (
    input clk,
    input rst_n,

    // packet input
    input [DATA_WIDTH-1:0] axis_tdata,
    input axis_tvalid,
    input axis_tready,
    input axis_tlast,

    // parse result
    output result_vld,  // one shot when parsing is complete
    output ipv4,
    output [31:0] ipv4_src_addr,
    output [31:0] ipv4_dst_addr
);

  logic [2:0] wd_cnt, wd_cnt_w;
  logic result_vld_q, result_vld_w;
  logic ipv4_q, ipv4_w;
  logic [31:0] ipv4_src_addr_q, ipv4_src_addr_w;
  logic [31:0] ipv4_dst_addr_q, ipv4_dst_addr_w;

  always_comb begin
    wd_cnt_w = wd_cnt;
    result_vld_w = 1'b0;
    ipv4_w = ipv4_q;
    ipv4_src_addr_w = ipv4_src_addr_q;
    ipv4_dst_addr_w = ipv4_dst_addr_q;

    if (axis_tvalid && axis_tready) begin
      // parse header
      case (wd_cnt)
        3'h1: begin
          ipv4_w = (axis_tdata[16+:16] == 16'h0800);
        end
        3'h3: begin
          ipv4_src_addr_w = axis_tdata[16+:32];
          ipv4_dst_addr_w[31:16] = axis_tdata[0+:16];
        end
        3'h4: begin
          ipv4_dst_addr_w[15:0] = axis_tdata[48+:16];
        end
        default: ;
      endcase

      if (wd_cnt <= 'd4) begin
        wd_cnt_w = wd_cnt + 1'b1;
      end

      // completion
      if (wd_cnt == 'd4) begin
        result_vld_w = 1'b1;
      end

      if (axis_tlast) begin
        wd_cnt_w = '0;
      end
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wd_cnt <= '0;
      result_vld_q <= '0;
      ipv4_q <= '0;
      ipv4_src_addr_q <= '0;
      ipv4_dst_addr_q <= '0;
    end else begin
      wd_cnt <= wd_cnt_w;
      result_vld_q <= result_vld_w;
      ipv4_q <= ipv4_w;
      ipv4_src_addr_q <= ipv4_src_addr_w;
      ipv4_dst_addr_q <= ipv4_dst_addr_w;
    end
  end

  assign result_vld = result_vld_q;
  assign ipv4 = ipv4_q;
  assign ipv4_src_addr = ipv4_src_addr_q;
  assign ipv4_dst_addr = ipv4_dst_addr_q;

endmodule

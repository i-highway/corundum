// Copyright (c) 2024 Intellectual Highway. All rights reserved.

module ipfilter #(
    parameter DATA_WIDTH = 64,
    parameter TX_ID_WIDTH = 13,
    parameter RX_ID_WIDTH = 1,
    parameter TX_DEST_WIDTH = 4,
    parameter RX_DEST_WIDTH = 9,
    parameter TX_USER_WIDTH = 17,
    parameter RX_USER_WIDTH = 97,
    parameter PTP_TS_WIDTH = 96,
    parameter TX_TAG_WIDTH = 16,
    parameter NUM_ENTRIES = 16,
    localparam KEEP_WIDTH = DATA_WIDTH / 8
) (
    input clk,
    input rst_n,

    input  [   DATA_WIDTH-1:0] s_axis_tx_tdata,
    input  [   KEEP_WIDTH-1:0] s_axis_tx_tkeep,
    input                      s_axis_tx_tvalid,
    output                     s_axis_tx_tready,
    input                      s_axis_tx_tlast,
    input  [  TX_ID_WIDTH-1:0] s_axis_tx_tid,
    input  [TX_DEST_WIDTH-1:0] s_axis_tx_tdest,
    input  [TX_USER_WIDTH-1:0] s_axis_tx_tuser,

    output [   DATA_WIDTH-1:0] m_axis_tx_tdata,
    output [   KEEP_WIDTH-1:0] m_axis_tx_tkeep,
    output                     m_axis_tx_tvalid,
    input                      m_axis_tx_tready,
    output                     m_axis_tx_tlast,
    output [  TX_ID_WIDTH-1:0] m_axis_tx_tid,
    output [TX_DEST_WIDTH-1:0] m_axis_tx_tdest,
    output [TX_USER_WIDTH-1:0] m_axis_tx_tuser,

    input  [   DATA_WIDTH-1:0] s_axis_rx_tdata,
    input  [   KEEP_WIDTH-1:0] s_axis_rx_tkeep,
    input                      s_axis_rx_tvalid,
    output                     s_axis_rx_tready,
    input                      s_axis_rx_tlast,
    input  [  RX_ID_WIDTH-1:0] s_axis_rx_tid,
    input  [RX_DEST_WIDTH-1:0] s_axis_rx_tdest,
    input  [RX_USER_WIDTH-1:0] s_axis_rx_tuser,

    output [   DATA_WIDTH-1:0] m_axis_rx_tdata,
    output [   KEEP_WIDTH-1:0] m_axis_rx_tkeep,
    output                     m_axis_rx_tvalid,
    input                      m_axis_rx_tready,
    output                     m_axis_rx_tlast,
    output [  RX_ID_WIDTH-1:0] m_axis_rx_tid,
    output [RX_DEST_WIDTH-1:0] m_axis_rx_tdest,
    output [RX_USER_WIDTH-1:0] m_axis_rx_tuser,

    output [PTP_TS_WIDTH-1:0] m_axis_tx_cpl_ts,
    output [TX_TAG_WIDTH-1:0] m_axis_tx_cpl_tag,
    output                    m_axis_tx_cpl_valid,
    input                     m_axis_tx_cpl_ready,

    input         tx_vld         [NUM_ENTRIES],
    input  [31:0] tx_ipv4_addr   [NUM_ENTRIES],
    input  [31:0] tx_ipv4_netmask[NUM_ENTRIES],
    input         rx_vld         [NUM_ENTRIES],
    input  [31:0] rx_ipv4_addr   [NUM_ENTRIES],
    input  [31:0] rx_ipv4_netmask[NUM_ENTRIES],
    output [31:0] tx_drop_cnt,
    output [31:0] rx_drop_cnt
);

  // reg, wire
  logic [31:0] tx_drop_cnt_q, tx_drop_cnt_w;
  logic [31:0] rx_drop_cnt_q, rx_drop_cnt_w;

  // wire
  logic        tx_drop;
  logic        tx_result_tvalid;
  logic        tx_result_tready;
  logic [ 7:0] tx_result_tdata;
  logic        tx_data_tvalid;
  logic        tx_data_tready;
  logic        tx_result_vld;
  logic        tx_ipv4;
  logic [31:0] tx_ipv4_dst_addr;
  logic        rx_drop;
  logic        rx_result_tvalid;
  logic        rx_result_tready;
  logic [ 7:0] rx_result_tdata;
  logic        rx_data_tvalid;
  logic        rx_data_tready;
  logic        rx_result_vld;
  logic        rx_ipv4;
  logic [31:0] rx_ipv4_src_addr;

  always_comb begin
    // tx drop check
    tx_drop = 1'b0;
    for (int i = 0; i < NUM_ENTRIES; i++) begin
      if (tx_vld[i] && tx_ipv4 &&
          ((tx_ipv4_addr[i] & tx_ipv4_netmask[i]) == (tx_ipv4_dst_addr & tx_ipv4_netmask[i]))) begin
        tx_drop = 1'b1;
      end
    end

    // tx packet
    tx_result_tready = 1'b0;
    tx_data_tready = 1'b0;
    tx_drop_cnt_w = tx_drop_cnt_q;
    if (tx_result_tvalid) begin
      if (tx_result_tdata[0]) begin
        // drop tx packet
        tx_data_tready = 1'b1;
      end else begin
        // output tx packet
        tx_data_tready = m_axis_tx_tready;
      end

      // read next result
      if (tx_data_tvalid && tx_data_tready && m_axis_tx_tlast) begin
        if (!tx_result_tdata[0]) begin
          tx_result_tready = 1'b1;
        end else begin
          if (m_axis_tx_cpl_ready) begin
            tx_result_tready = 1'b1;
            tx_drop_cnt_w = tx_drop_cnt_q + 1'b1;
          end else begin
            tx_data_tready = 1'b0;
          end
        end
      end
    end

    // rx drop check
    rx_drop = 1'b0;
    for (int i = 0; i < NUM_ENTRIES; i++) begin
      if (rx_vld[i] && rx_ipv4 &&
          ((rx_ipv4_addr[i] & rx_ipv4_netmask[i]) == (rx_ipv4_src_addr & rx_ipv4_netmask[i]))) begin
        rx_drop = 1'b1;
      end
    end

    // rx packet
    rx_result_tready = 1'b0;
    rx_data_tready = 1'b0;
    rx_drop_cnt_w = rx_drop_cnt_q;
    if (rx_result_tvalid) begin
      if (rx_result_tdata[0]) begin
        // drop rx packet
        rx_data_tready = 1'b1;
      end else begin
        // output rx packet
        rx_data_tready = m_axis_rx_tready;
      end

      // read next result
      if (rx_data_tvalid && rx_data_tready && m_axis_rx_tlast) begin
        rx_result_tready = 1'b1;
        if (rx_result_tdata[0]) begin
          rx_drop_cnt_w = rx_drop_cnt_q + 1'b1;
        end
      end
    end
  end

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      tx_drop_cnt_q <= '0;
      rx_drop_cnt_q <= '0;
    end else begin
      tx_drop_cnt_q <= tx_drop_cnt_w;
      rx_drop_cnt_q <= rx_drop_cnt_w;
    end
  end

  // tx
  parser #(
      .DATA_WIDTH(DATA_WIDTH)
  ) i_parser_tx (
      .clk(clk),
      .rst_n(rst_n),
      .axis_tdata(s_axis_tx_tdata),
      .axis_tvalid(s_axis_tx_tvalid),
      .axis_tready(s_axis_tx_tready),
      .axis_tlast(s_axis_tx_tlast),
      .result_vld(tx_result_vld),
      .ipv4(tx_ipv4),
      .ipv4_src_addr(),
      .ipv4_dst_addr(tx_ipv4_dst_addr)
  );

  axis_fifo #(
      .DEPTH      (1024),
      .DATA_WIDTH (8),
      .ID_ENABLE  (1),
      .DEST_ENABLE(1)
  ) i_fifo_tx_result (
      .clk                (clk),
      .rst                (~rst_n),
      .s_axis_tdata       ({7'b0, tx_drop}),
      .s_axis_tkeep       (1'b1),
      .s_axis_tvalid      (tx_result_vld),
      .s_axis_tready      (),
      .s_axis_tlast       (1'b1),
      .s_axis_tid         ('0),
      .s_axis_tdest       ('0),
      .s_axis_tuser       ('0),
      .m_axis_tdata       (tx_result_tdata),
      .m_axis_tkeep       (),
      .m_axis_tvalid      (tx_result_tvalid),
      .m_axis_tready      (tx_result_tready),
      .m_axis_tlast       (),
      .m_axis_tid         (),
      .m_axis_tdest       (),
      .m_axis_tuser       (),
      .pause_req          (1'b0),
      .pause_ack          (),
      .status_depth       (),
      .status_depth_commit(),
      .status_overflow    (),
      .status_bad_frame   (),
      .status_good_frame  ()
  );

  axis_fifo #(
      .DEPTH      (32768),
      .DATA_WIDTH (DATA_WIDTH),
      .ID_ENABLE  (1),
      .ID_WIDTH   (TX_ID_WIDTH),
      .DEST_ENABLE(1),
      .DEST_WIDTH (TX_DEST_WIDTH),
      .USER_ENABLE(1),
      .USER_WIDTH (TX_USER_WIDTH)
  ) i_fifo_tx (
      .clk                (clk),
      .rst                (~rst_n),
      .s_axis_tdata       (s_axis_tx_tdata),
      .s_axis_tkeep       (s_axis_tx_tkeep),
      .s_axis_tvalid      (s_axis_tx_tvalid),
      .s_axis_tready      (s_axis_tx_tready),
      .s_axis_tlast       (s_axis_tx_tlast),
      .s_axis_tid         (s_axis_tx_tid),
      .s_axis_tdest       (s_axis_tx_tdest),
      .s_axis_tuser       (s_axis_tx_tuser),
      .m_axis_tdata       (m_axis_tx_tdata),
      .m_axis_tkeep       (m_axis_tx_tkeep),
      .m_axis_tvalid      (tx_data_tvalid),
      .m_axis_tready      (tx_data_tready),
      .m_axis_tlast       (m_axis_tx_tlast),
      .m_axis_tid         (m_axis_tx_tid),
      .m_axis_tdest       (m_axis_tx_tdest),
      .m_axis_tuser       (m_axis_tx_tuser),
      .pause_req          (1'b0),
      .pause_ack          (),
      .status_depth       (),
      .status_depth_commit(),
      .status_overflow    (),
      .status_bad_frame   (),
      .status_good_frame  ()
  );

  // rx
  parser #(
      .DATA_WIDTH(DATA_WIDTH)
  ) i_parser_rx (
      .clk          (clk),
      .rst_n        (rst_n),
      .axis_tdata   (s_axis_rx_tdata),
      .axis_tvalid  (s_axis_rx_tvalid),
      .axis_tready  (s_axis_rx_tready),
      .axis_tlast   (s_axis_rx_tlast),
      .result_vld   (rx_result_vld),
      .ipv4         (rx_ipv4),
      .ipv4_src_addr(rx_ipv4_src_addr),
      .ipv4_dst_addr()
  );

  axis_fifo #(
      .DEPTH      (1024),
      .DATA_WIDTH (8),
      .ID_ENABLE  (1),
      .DEST_ENABLE(1)
  ) i_fifo_rx_result (
      .clk                (clk),
      .rst                (~rst_n),
      .s_axis_tdata       ({7'b0, rx_drop}),
      .s_axis_tkeep       (1'b1),
      .s_axis_tvalid      (rx_result_vld),
      .s_axis_tready      (),
      .s_axis_tlast       (1'b1),
      .s_axis_tid         ('0),
      .s_axis_tdest       ('0),
      .s_axis_tuser       ('0),
      .m_axis_tdata       (rx_result_tdata),
      .m_axis_tkeep       (),
      .m_axis_tvalid      (rx_result_tvalid),
      .m_axis_tready      (rx_result_tready),
      .m_axis_tlast       (),
      .m_axis_tid         (),
      .m_axis_tdest       (),
      .m_axis_tuser       (),
      .pause_req          (1'b0),
      .pause_ack          (),
      .status_depth       (),
      .status_depth_commit(),
      .status_overflow    (),
      .status_bad_frame   (),
      .status_good_frame  ()
  );

  axis_fifo #(
      .DEPTH      (32768),
      .DATA_WIDTH (DATA_WIDTH),
      .ID_ENABLE  (1),
      .ID_WIDTH   (RX_ID_WIDTH),
      .DEST_ENABLE(1),
      .DEST_WIDTH (RX_DEST_WIDTH),
      .USER_ENABLE(1),
      .USER_WIDTH (RX_USER_WIDTH)
  ) i_fifo_rx (
      .clk                (clk),
      .rst                (~rst_n),
      .s_axis_tdata       (s_axis_rx_tdata),
      .s_axis_tkeep       (s_axis_rx_tkeep),
      .s_axis_tvalid      (s_axis_rx_tvalid),
      .s_axis_tready      (s_axis_rx_tready),
      .s_axis_tlast       (s_axis_rx_tlast),
      .s_axis_tid         (s_axis_rx_tid),
      .s_axis_tdest       (s_axis_rx_tdest),
      .s_axis_tuser       (s_axis_rx_tuser),
      .m_axis_tdata       (m_axis_rx_tdata),
      .m_axis_tkeep       (m_axis_rx_tkeep),
      .m_axis_tvalid      (rx_data_tvalid),
      .m_axis_tready      (rx_data_tready),
      .m_axis_tlast       (m_axis_rx_tlast),
      .m_axis_tid         (m_axis_rx_tid),
      .m_axis_tdest       (m_axis_rx_tdest),
      .m_axis_tuser       (m_axis_rx_tuser),
      .pause_req          (1'b0),
      .pause_ack          (),
      .status_depth       (),
      .status_depth_commit(),
      .status_overflow    (),
      .status_bad_frame   (),
      .status_good_frame  ()
  );

  assign m_axis_tx_tvalid = (tx_result_tvalid && !tx_result_tdata[0]) ? tx_data_tvalid : 1'b0;
  assign m_axis_tx_cpl_ts = '0;
  assign m_axis_tx_cpl_tag = m_axis_tx_tuser[TX_USER_WIDTH-1:1];
  assign m_axis_tx_cpl_valid = (tx_result_tvalid && tx_result_tdata[0] && tx_data_tvalid && m_axis_tx_tlast);
  assign m_axis_rx_tvalid = (rx_result_tvalid && !rx_result_tdata[0]) ? rx_data_tvalid : 1'b0;
  assign tx_drop_cnt = tx_drop_cnt_q;
  assign rx_drop_cnt = rx_drop_cnt_q;

endmodule

`timescale 1ns/1ps

`include "open_nic_shell_macros.vh"

module p2p_250mhz #(
  parameter int NUM_INTF = 1
) (
  axi_lite_if.slave    s_axil,
  axi_stream_if.slave  s_axis_qdma_h2c[NUM_INTF],
  axi_stream_if.master m_axis_qdma_c2h[NUM_INTF],
  axi_stream_if.master m_axis_adap_tx_250mhz[NUM_INTF],
  axi_stream_if.slave  s_axis_adap_rx_250mhz[NUM_INTF],

  input                mod_rstn,
  output               mod_rst_done,

  input                axil_aclk,
  input                axis_aclk
);

  wire axil_aresetn; // Reset is clocked by the 125MHz AXI-Lite clock
  wire axis_aresetn; // Reset is clocked by the 250MHz AXI-Lite clock

  generic_reset #(
    .NUM_INPUT_CLK  (1),
    .RESET_DURATION (100)
  ) axil_reset_inst (
    .mod_rstn     (mod_rstn),
    .mod_rst_done (mod_rst_done),
    .clk          (axil_aclk),
    .rstn         (axil_aresetn)
  );

  assign axis_aresetn = axil_aresetn;

  generate for (genvar i = 0; i < NUM_INTF; i++) begin
    wire user_metadata_out_valid;
    wire axis_qdma_c2h_tvalid;

    assign m_axis_qdma_c2h[i].valid = user_metadata_out_valid && axis_qdma_c2h_tvalid;

    wire [47:0] axis_qdma_h2c_tuser;
    wire [47:0] axis_qdma_c2h_tuser;
    wire [47:0] axis_adap_tx_250mhz_tuser;
    wire [47:0] axis_adap_rx_250mhz_tuser;

    assign axis_qdma_h2c_tuser[15:0]  = s_axis_qdma_h2c[i].user_size;
    assign axis_qdma_h2c_tuser[31:16] = s_axis_qdma_h2c[i].user_src;
    assign axis_qdma_h2c_tuser[47:32] = s_axis_qdma_h2c[i].user_dst;

    assign axis_adap_rx_250mhz_tuser[15:0]  = s_axis_adap_rx_250mhz[i].user_size;
    assign axis_adap_rx_250mhz_tuser[31:16] = s_axis_adap_rx_250mhz[i].user_src;
    assign axis_adap_rx_250mhz_tuser[47:32] = s_axis_adap_rx_250mhz[i].user_dst;

    assign m_axis_adap_tx_250mhz[i].user_size = axis_adap_tx_250mhz_tuser[15:0];
    assign m_axis_adap_tx_250mhz[i].user_src  = axis_adap_tx_250mhz_tuser[31:16];
    assign m_axis_adap_tx_250mhz[i].user_dst  = 16'h1 << (6 + i);

    assign m_axis_qdma_c2h[i].user_size = axis_qdma_c2h_tuser[15:0];
    assign m_axis_qdma_c2h[i].user_src  = axis_qdma_c2h_tuser[31:16];
    assign m_axis_qdma_c2h[i].user_dst  = 16'h1 << i;

    axi_stream_pipeline tx_ppl_inst (
      .s_axis_tvalid (s_axis_qdma_h2c[i].valid),
      .s_axis_tdata  (s_axis_qdma_h2c[i].data),
      .s_axis_tkeep  (s_axis_qdma_h2c[i].keep),
      .s_axis_tlast  (s_axis_qdma_h2c[i].last),
      .s_axis_tuser  (axis_qdma_h2c_tuser),
      .s_axis_tready (s_axis_qdma_h2c[i].ready),

      .m_axis_tvalid (m_axis_adap_tx_250mhz[i].valid),
      .m_axis_tdata  (m_axis_adap_tx_250mhz[i].data),
      .m_axis_tkeep  (m_axis_adap_tx_250mhz[i].keep),
      .m_axis_tlast  (m_axis_adap_tx_250mhz[i].last),
      .m_axis_tuser  (axis_adap_tx_250mhz_tuser),
      .m_axis_tready (m_axis_adap_tx_250mhz[i].ready),

      .aclk          (axis_aclk),
      .aresetn       (axil_aresetn)
    );

    rx_vitis_net_p4_core rx_vitis_net_p4_core_inst (
      .s_axis_aclk     (axis_aclk),
      .s_axis_aresetn  (axis_aresetn),
      .s_axi_aclk      (axil_aclk),
      .s_axi_aresetn   (axil_aresetn),
      .cam_mem_aclk    (axis_aclk),
      .cam_mem_aresetn (axis_aresetn),

      .user_metadata_in({
        axis_adap_rx_250mhz_tuser
      }),
      .user_metadata_in_valid(s_axis_adap_rx_250mhz[i].valid),

      .user_metadata_out({
        axis_qdma_c2h_tuser
      }),
      .user_metadata_out_valid(user_metadata_out_valid),

      .s_axis_tdata  (s_axis_adap_rx_250mhz[i].data),
      .s_axis_tkeep  (s_axis_adap_rx_250mhz[i].keep),
      .s_axis_tlast  (s_axis_adap_rx_250mhz[i].last),
      .s_axis_tvalid (s_axis_adap_rx_250mhz[i].valid),
      .s_axis_tready (s_axis_adap_rx_250mhz[i].ready),

      .m_axis_tdata  (m_axis_qdma_c2h[i].data),
      .m_axis_tkeep  (m_axis_qdma_c2h[i].keep),
      .m_axis_tlast  (m_axis_qdma_c2h[i].last),
      .m_axis_tvalid (axis_qdma_c2h_tvalid),
      .m_axis_tready (m_axis_qdma_c2h[i].ready),

      .s_axi_araddr  (s_axil.ar_addr),
      .s_axi_arready (s_axil.ar_ready),
      .s_axi_arvalid (s_axil.ar_valid),
      .s_axi_awaddr  (s_axil.aw_addr),
      .s_axi_awready (s_axil.aw_ready),
      .s_axi_awvalid (s_axil.aw_valid),
      .s_axi_bready  (s_axil.b_ready),
      .s_axi_bresp   (s_axil.b_resp),
      .s_axi_bvalid  (s_axil.b_valid),
      .s_axi_rdata   (s_axil.r_data),
      .s_axi_rready  (s_axil.r_ready),
      .s_axi_rresp   (s_axil.r_resp),
      .s_axi_rvalid  (s_axil.r_valid),
      .s_axi_wdata   (s_axil.w_data),
      .s_axi_wready  (s_axil.w_ready),
      .s_axi_wstrb   (4'b1111),
      .s_axi_wvalid  (s_axil.w_valid)
    );

  end endgenerate

endmodule: p2p_250mhz

`timescale 1ns/1ps

`include "open_nic_shell_macros.vh"

module p2p_250mhz #(
  parameter int NUM_PHYS_FUNC = 1,
  parameter int NUM_CMAC_PORT = 1
) (
  axi_lite_if.slave    s_axil,
  axi_stream_if.slave  s_axis_qdma_h2c[NUM_PHYS_FUNC],
  axi_stream_if.master m_axis_qdma_c2h[NUM_PHYS_FUNC],
  axi_stream_if.master m_axis_adap_tx_250mhz[NUM_CMAC_PORT],
  axi_stream_if.slave  s_axis_adap_rx_250mhz[NUM_CMAC_PORT],

  input                mod_rstn,
  output               mod_rst_done,

  input                axil_aclk,
  input                axis_aclk
);

  axi_stream_vnp4_if axis_vnp4_in();
  axi_stream_vnp4_if axis_vnp4_out();

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

  ingress_switch #(
    .NUM_PHYS_FUNC(NUM_PHYS_FUNC),
    .NUM_CMAC_PORT(NUM_CMAC_PORT)
  ) ingress_switch_inst (
    .s_axis_pf   (s_axis_qdma_h2c),
    .s_axis_cmac (s_axis_adap_rx_250mhz),
    .m_axis      (axis_vnp4_in),
    .aclk        (axis_aclk),
    .aresetn     (axis_aresetn)
  );

  vitis_net_p4_core vitis_net_p4_core_inst (
    .s_axis_aclk     (axis_aclk),
    .s_axis_aresetn  (axis_aresetn),
    .s_axi_aclk      (axil_aclk),
    .s_axi_aresetn   (axil_aresetn),
    .cam_mem_aclk    (axis_aclk),
    .cam_mem_aresetn (axis_aresetn),

    .user_metadata_in({
      axis_vnp4_in.user_size,
      axis_vnp4_in.user_src_pf,
      axis_vnp4_in.user_src_cmac,
      axis_vnp4_in.user_dst_pf,
      axis_vnp4_in.user_dst_cmac,
      axis_vnp4_in.user_from_direction,
      axis_vnp4_in.user_to_direction
    }),
    .user_metadata_in_valid(axis_vnp4_in.user_valid),

    .user_metadata_out({
      axis_vnp4_out.user_size,
      axis_vnp4_out.user_src_pf,
      axis_vnp4_out.user_src_cmac,
      axis_vnp4_out.user_dst_pf,
      axis_vnp4_out.user_dst_cmac,
      axis_vnp4_out.user_from_direction,
      axis_vnp4_out.user_to_direction
    }),
    .user_metadata_out_valid(axis_vnp4_out.user_valid),

    .s_axis_tdata    (axis_vnp4_in.data),
    .s_axis_tkeep    (axis_vnp4_in.keep),
    .s_axis_tlast    (axis_vnp4_in.last),
    .s_axis_tvalid   (axis_vnp4_in.valid),
    .s_axis_tready   (axis_vnp4_in.ready),

    .m_axis_tdata    (axis_vnp4_out.data),
    .m_axis_tkeep    (axis_vnp4_out.keep),
    .m_axis_tlast    (axis_vnp4_out.last),
    .m_axis_tvalid   (axis_vnp4_out.valid),
    .m_axis_tready   (axis_vnp4_out.ready),

    .s_axi_araddr    (s_axil.ar_addr),
    .s_axi_arready   (s_axil.ar_ready),
    .s_axi_arvalid   (s_axil.ar_valid),
    .s_axi_awaddr    (s_axil.aw_addr),
    .s_axi_awready   (s_axil.aw_ready),
    .s_axi_awvalid   (s_axil.aw_valid),
    .s_axi_bready    (s_axil.b_ready),
    .s_axi_bresp     (s_axil.b_resp),
    .s_axi_bvalid    (s_axil.b_valid),
    .s_axi_rdata     (s_axil.r_data),
    .s_axi_rready    (s_axil.r_ready),
    .s_axi_rresp     (s_axil.r_resp),
    .s_axi_rvalid    (s_axil.r_valid),
    .s_axi_wdata     (s_axil.w_data),
    .s_axi_wready    (s_axil.w_ready),
    .s_axi_wstrb     (4'b1111),
    .s_axi_wvalid    (s_axil.w_valid)
  );

  egress_switch #(
    .NUM_PHYS_FUNC(NUM_PHYS_FUNC),
    .NUM_CMAC_PORT(NUM_CMAC_PORT)
  ) egress_switch_inst (
    .s_axis      (axis_vnp4_out),
    .m_axis_pf   (m_axis_qdma_c2h),
    .m_axis_cmac (m_axis_adap_tx_250mhz),
    .aclk        (axis_aclk),
    .aresetn     (axis_aresetn)
  );

endmodule: p2p_250mhz


initial begin
  if (NUM_QDMA > 1) begin
    $fatal("More than two QDMAs are not supported.");
  end
  if (USE_PHYS_FUNC == 0) begin
    $fatal("No implementation for USE_PHYS_FUNC = %d", 0);
  end
end

// Make sure for all the unused reset pair, corresponding bits in
// "mod_rst_done" are tied to 0
localparam C_NUM_USER_BLOCK = 1;
assign mod_rst_done[15:C_NUM_USER_BLOCK] = {(16-C_NUM_USER_BLOCK){1'b1}};

axi_lite_if axil();
axi_stream_if axis_qdma_h2c[NUM_PHYS_FUNC] ();
axi_stream_if axis_qdma_c2h[NUM_PHYS_FUNC] ();
axi_stream_if axis_adap_tx_250mhz[NUM_CMAC_PORT] ();
axi_stream_if axis_adap_rx_250mhz[NUM_CMAC_PORT] ();

axi_lite_if_s_connector axi_lite_if_s_connector_inst(
  .s_axil_awvalid (s_axil_awvalid),
  .s_axil_awaddr  (s_axil_awaddr),
  .s_axil_awready (s_axil_awready),
  .s_axil_wvalid  (s_axil_wvalid),
  .s_axil_wdata   (s_axil_wdata),
  .s_axil_wready  (s_axil_wready),
  .s_axil_bvalid  (s_axil_bvalid),
  .s_axil_bresp   (s_axil_bresp),
  .s_axil_bready  (s_axil_bready),
  .s_axil_arvalid (s_axil_arvalid),
  .s_axil_araddr  (s_axil_araddr),
  .s_axil_arready (s_axil_arready),
  .s_axil_rvalid  (s_axil_rvalid),
  .s_axil_rdata   (s_axil_rdata),
  .s_axil_rresp   (s_axil_rresp),
  .s_axil_rready  (s_axil_rready),
  .m_axil         (axil)
);

axi_stream_if_s_connector #(
  .COUNTS(NUM_PHYS_FUNC)
) axis_qdma_h2c_connector_inst(
  .s_axis_tvalid     (s_axis_qdma_h2c_tvalid),
  .s_axis_tdata      (s_axis_qdma_h2c_tdata),
  .s_axis_tkeep      (s_axis_qdma_h2c_tkeep),
  .s_axis_tlast      (s_axis_qdma_h2c_tlast),
  .s_axis_tuser_size (s_axis_qdma_h2c_tuser_size),
  .s_axis_tuser_src  (s_axis_qdma_h2c_tuser_src),
  .s_axis_tuser_dst  (s_axis_qdma_h2c_tuser_dst),
  .s_axis_tready     (s_axis_qdma_h2c_tready),
  .m_axis            (axis_qdma_h2c)
);

axi_stream_if_m_connector #(
  .COUNTS(NUM_PHYS_FUNC)
) axis_qdma_c2h_connector_inst(
  .s_axis            (axis_qdma_c2h),
  .m_axis_tvalid     (m_axis_qdma_c2h_tvalid),
  .m_axis_tdata      (m_axis_qdma_c2h_tdata),
  .m_axis_tkeep      (m_axis_qdma_c2h_tkeep),
  .m_axis_tlast      (m_axis_qdma_c2h_tlast),
  .m_axis_tuser_size (m_axis_qdma_c2h_tuser_size),
  .m_axis_tuser_src  (m_axis_qdma_c2h_tuser_src),
  .m_axis_tuser_dst  (m_axis_qdma_c2h_tuser_dst),
  .m_axis_tready     (m_axis_qdma_c2h_tready)
);

axi_stream_if_m_connector #(
  .COUNTS(NUM_CMAC_PORT)
) axis_adap_tx_250mhz_connector_inst(
  .s_axis            (axis_adap_tx_250mhz),
  .m_axis_tvalid     (m_axis_adap_tx_250mhz_tvalid),
  .m_axis_tdata      (m_axis_adap_tx_250mhz_tdata),
  .m_axis_tkeep      (m_axis_adap_tx_250mhz_tkeep),
  .m_axis_tlast      (m_axis_adap_tx_250mhz_tlast),
  .m_axis_tuser_size (m_axis_adap_tx_250mhz_tuser_size),
  .m_axis_tuser_src  (m_axis_adap_tx_250mhz_tuser_src),
  .m_axis_tuser_dst  (m_axis_adap_tx_250mhz_tuser_dst),
  .m_axis_tready     (m_axis_adap_tx_250mhz_tready)
);

axi_stream_if_s_connector #(
  .COUNTS(NUM_CMAC_PORT)
) axis_adap_rx_250mhz_connector_inst(
  .s_axis_tvalid     (s_axis_adap_rx_250mhz_tvalid),
  .s_axis_tdata      (s_axis_adap_rx_250mhz_tdata),
  .s_axis_tkeep      (s_axis_adap_rx_250mhz_tkeep),
  .s_axis_tlast      (s_axis_adap_rx_250mhz_tlast),
  .s_axis_tuser_size (s_axis_adap_rx_250mhz_tuser_size),
  .s_axis_tuser_src  (s_axis_adap_rx_250mhz_tuser_src),
  .s_axis_tuser_dst  (s_axis_adap_rx_250mhz_tuser_dst),
  .s_axis_tready     (s_axis_adap_rx_250mhz_tready),
  .m_axis            (axis_adap_rx_250mhz)
);

p2p_250mhz #(
  .NUM_PHYS_FUNC (NUM_PHYS_FUNC),
  .NUM_CMAC_PORT (NUM_CMAC_PORT)
) p2p_250mhz_inst (
  .s_axil                (axil),
  .s_axis_qdma_h2c       (axis_qdma_h2c),
  .m_axis_qdma_c2h       (axis_qdma_c2h),
  .m_axis_adap_tx_250mhz (axis_adap_tx_250mhz),
  .s_axis_adap_rx_250mhz (axis_adap_rx_250mhz),

  .mod_rstn              (mod_rstn[0]),
  .mod_rst_done          (mod_rst_done[0]),

  .axil_aclk             (axil_aclk),
  .axis_aclk             (axis_aclk)
);

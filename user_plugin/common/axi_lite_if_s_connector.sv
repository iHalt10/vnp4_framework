`timescale 1ns/1ps

module axi_lite_if_s_connector (
  input         s_axil_awvalid,
  input  [31:0] s_axil_awaddr,
  output        s_axil_awready,
  input         s_axil_wvalid,
  input  [31:0] s_axil_wdata,
  output        s_axil_wready,
  output        s_axil_bvalid,
  output  [1:0] s_axil_bresp,
  input         s_axil_bready,
  input         s_axil_arvalid,
  input  [31:0] s_axil_araddr,
  output        s_axil_arready,
  output        s_axil_rvalid,
  output [31:0] s_axil_rdata,
  output  [1:0] s_axil_rresp,
  input         s_axil_rready,

  axi_lite_if.master m_axil
);

  assign m_axil.aw_valid = s_axil_awvalid;
  assign m_axil.aw_addr  = s_axil_awaddr;
  assign s_axil_awready  = m_axil.aw_ready;

  assign m_axil.w_valid = s_axil_wvalid;
  assign m_axil.w_data  = s_axil_wdata;
  assign s_axil_wready  = m_axil.w_ready;

  assign s_axil_bvalid  = m_axil.b_valid;
  assign s_axil_bresp   = m_axil.b_resp;
  assign m_axil.b_ready = s_axil_bready;

  assign m_axil.ar_valid = s_axil_arvalid;
  assign m_axil.ar_addr  = s_axil_araddr;
  assign s_axil_arready  = m_axil.ar_ready;

  assign s_axil_rvalid  = m_axil.r_valid;
  assign s_axil_rdata   = m_axil.r_data;
  assign s_axil_rresp   = m_axil.r_resp;
  assign m_axil.r_ready = s_axil_rready;

endmodule: axi_lite_if_s_connector

`timescale 1ns/1ps

`include "open_nic_shell_macros.vh"

import direction_pkg::PF;
import direction_pkg::CMAC;

module ingress_switch #(
  parameter int NUM_PHYS_FUNC = 1,
  parameter int NUM_CMAC_PORT = 1
) (
  axi_stream_if.slave       s_axis_pf[NUM_PHYS_FUNC],
  axi_stream_if.slave       s_axis_cmac[NUM_CMAC_PORT],
  axi_stream_vnp4_if.master m_axis,
  input aclk,
  input aresetn
);

  localparam int NUM_SLAVES = NUM_PHYS_FUNC + NUM_CMAC_PORT;

  wire [NUM_SLAVES-1:0]     s_axis_tvalid;
  wire [512*NUM_SLAVES-1:0] s_axis_tdata;
  wire [64*NUM_SLAVES-1:0]  s_axis_tkeep;
  wire [NUM_SLAVES-1:0]     s_axis_tlast;
  wire [49*NUM_SLAVES-1:0]  s_axis_tuser;
  wire [NUM_SLAVES-1:0]     s_axis_tready;

  wire        axis_tvalid;
  wire [48:0] axis_tuser;

  generate for (genvar i = 0; i < NUM_PHYS_FUNC; i++) begin
    assign s_axis_tdata[`getvec(512, i)] = s_axis_pf[i].data;
    assign s_axis_tkeep[`getvec(64, i)]  = s_axis_pf[i].keep;
    assign s_axis_tuser[`getvec(49, i)]  = {PF, s_axis_pf[i].user_dst, s_axis_pf[i].user_src, s_axis_pf[i].user_size};
    assign s_axis_tlast[i]               = s_axis_pf[i].last;
    assign s_axis_tvalid[i]              = s_axis_pf[i].valid;

    assign s_axis_pf[i].ready            = s_axis_tready[i];
  end endgenerate

  generate for (genvar i = 0; i < NUM_CMAC_PORT; i++) begin
    localparam int j = NUM_PHYS_FUNC + i;
    assign s_axis_tdata[`getvec(512, j)] = s_axis_cmac[i].data;
    assign s_axis_tkeep[`getvec(64, j)]  = s_axis_cmac[i].keep;
    assign s_axis_tuser[`getvec(49, j)]  = {CMAC, s_axis_cmac[i].user_dst, s_axis_cmac[i].user_src, s_axis_cmac[i].user_size};
    assign s_axis_tlast[j]               = s_axis_cmac[i].last;
    assign s_axis_tvalid[j]              = s_axis_cmac[i].valid;

    assign s_axis_cmac[i].ready          = s_axis_tready[j];
  end endgenerate

  axis_ingress_switch axis_ingress_switch_inst (
    .s_axis_tvalid (s_axis_tvalid),
    .s_axis_tdata  (s_axis_tdata),
    .s_axis_tkeep  (s_axis_tkeep),
    .s_axis_tlast  (s_axis_tlast),
    .s_axis_tuser  (s_axis_tuser),
    .s_axis_tready (s_axis_tready),

    .m_axis_tvalid (  axis_tvalid),
    .m_axis_tdata  (m_axis.data),
    .m_axis_tkeep  (m_axis.keep),
    .m_axis_tlast  (m_axis.last),
    .m_axis_tuser  (  axis_tuser),
    .m_axis_tready (m_axis.ready),

    .aclk          (aclk),
    .aresetn       (aresetn),
  
    .s_req_suppress('0),
    .s_decode_err()
  );

  assign m_axis.user_size     = axis_tuser[15:0];
  assign m_axis.user_src_pf   = axis_tuser[19:16];
  assign m_axis.user_src_cmac = axis_tuser[31:22];
  assign m_axis.user_dst_pf   = axis_tuser[35:32];
  assign m_axis.user_dst_cmac = axis_tuser[47:38];

  assign m_axis.user_from_direction = axis_tuser[48];
  assign m_axis.user_to_direction   = 0;

  assign m_axis.valid      = axis_tvalid;
  assign m_axis.user_valid = axis_tvalid;

endmodule: ingress_switch

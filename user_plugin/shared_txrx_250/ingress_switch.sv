`timescale 1ns/1ps

`include "open_nic_shell_macros.vh"

module ingress_switch #(
  parameter int NUM_QDMA = 1,
  parameter int NUM_PHYS_FUNC = 1,
  parameter int NUM_CMAC_PORT = 1
) (
  axi_stream_if.slave       s_axis_pf[NUM_QDMA * NUM_PHYS_FUNC],
  axi_stream_if.slave       s_axis_cmac[NUM_CMAC_PORT],
  axi_stream_vnp4_if.master m_axis,
  input aclk,
  input aresetn
);

  localparam int NUM_SLAVES = NUM_QDMA * NUM_PHYS_FUNC + NUM_CMAC_PORT;

  wire [NUM_SLAVES-1:0]     s_axis_tvalid;
  wire [512*NUM_SLAVES-1:0] s_axis_tdata;
  wire [64*NUM_SLAVES-1:0]  s_axis_tkeep;
  wire [NUM_SLAVES-1:0]     s_axis_tlast;
  wire [20*NUM_SLAVES-1:0]  s_axis_tuser;
  wire [NUM_SLAVES-1:0]     s_axis_tready;

  wire        axis_tvalid;
  wire [48:0] axis_tuser;

  generate
    for (genvar x = 0; x < NUM_QDMA; x++) begin
      for (genvar y = 0; y < NUM_PHYS_FUNC; y++) begin
        localparam int       index           = x * NUM_PHYS_FUNC + y;
        localparam bit [3:0] ingress_port_id = x * 4             + y;

        assign s_axis_tdata[`getvec(512, index)] = s_axis_pf[index].data;
        assign s_axis_tkeep[`getvec(64, index)]  = s_axis_pf[index].keep;
        assign s_axis_tuser[`getvec(20, index)]  = {ingress_port_id, s_axis_pf[index].user_size};
        assign s_axis_tlast[index]               = s_axis_pf[index].last;
        assign s_axis_tvalid[index]              = s_axis_pf[index].valid;
        assign s_axis_pf[index].ready            = s_axis_tready[index];
      end
    end

    for (genvar x = 0; x < NUM_CMAC_PORT; x++) begin
      localparam int       index           = NUM_QDMA * NUM_PHYS_FUNC + x;
      localparam bit [3:0] ingress_port_id = 8 + x;

      assign s_axis_tdata[`getvec(512, index)] = s_axis_cmac[x].data;
      assign s_axis_tkeep[`getvec(64, index)]  = s_axis_cmac[x].keep;
      assign s_axis_tuser[`getvec(20, index)]  = {ingress_port_id, s_axis_cmac[x].user_size};
      assign s_axis_tlast[index]               = s_axis_cmac[x].last;
      assign s_axis_tvalid[index]              = s_axis_cmac[x].valid;
      assign s_axis_cmac[x].ready              = s_axis_tready[index];
    end
  endgenerate

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

  assign m_axis.user_size         = axis_tuser[15:0];
  assign m_axis.user_ingress_port = axis_tuser[19:16];
  assign m_axis.user_egress_port  = '0;

  assign m_axis.valid      = axis_tvalid;
  assign m_axis.user_valid = axis_tvalid;

endmodule: ingress_switch

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
    for (genvar i = 0; i < NUM_QDMA; i++) begin
      for (genvar j = 0; j < NUM_PHYS_FUNC; j++) begin
        localparam int k = i * NUM_PHYS_FUNC + j;
        assign s_axis_tdata[`getvec(512, k)] = s_axis_pf[k].data;
        assign s_axis_tkeep[`getvec(64, k)]  = s_axis_pf[k].keep;
        assign s_axis_tuser[`getvec(20, k)]  = {encode_ingress_port_by_pf(i, s_axis_pf[k].user_src), s_axis_pf[k].user_size};
        assign s_axis_tlast[k]               = s_axis_pf[k].last;
        assign s_axis_tvalid[k]              = s_axis_pf[k].valid;
        assign s_axis_pf[k].ready            = s_axis_tready[k];
      end
    end

    for (genvar i = 0; i < NUM_CMAC_PORT; i++) begin
      localparam int j = NUM_PHYS_FUNC + i;
      assign s_axis_tdata[`getvec(512, j)] = s_axis_cmac[i].data;
      assign s_axis_tkeep[`getvec(64, j)]  = s_axis_cmac[i].keep;
      assign s_axis_tuser[`getvec(20, j)]  = {encode_ingress_port_by_cmac(s_axis_cmac[i].user_src), s_axis_cmac[i].user_size};
      assign s_axis_tlast[j]               = s_axis_cmac[i].last;
      assign s_axis_tvalid[j]              = s_axis_cmac[i].valid;
      assign s_axis_cmac[i].ready          = s_axis_tready[j];
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

  function automatic logic [3:0] encode_ingress_port_by_pf(
    input logic qdma_count,
    input logic [15:0] src
  );
    case ({qdma_count, src[3:0]})
      5'b00001: return 4'b0000;
      5'b00010: return 4'b0001;
      5'b00100: return 4'b0010;
      5'b01000: return 4'b0011;
      5'b10001: return 4'b0100;
      5'b10010: return 4'b0101;
      5'b10100: return 4'b0110;
      5'b11000: return 4'b0111;
    endcase
  endfunction

  function automatic logic [3:0] encode_ingress_port_by_cmac(
    input logic [15:0] src
  );
    case (src[15:6])
      10'b0000000001: return 4'b1000;
      10'b0000000010: return 4'b1001;
    endcase
  endfunction

endmodule: ingress_switch

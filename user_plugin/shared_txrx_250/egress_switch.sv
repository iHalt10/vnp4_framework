`timescale 1ns/1ps

`include "open_nic_shell_macros.vh"

module egress_switch #(
  parameter int NUM_QDMA = 1,
  parameter int NUM_PHYS_FUNC = 1,
  parameter int NUM_CMAC_PORT = 1
) (
  axi_stream_vnp4_if.slave s_axis,
  axi_stream_if.master     m_axis_pf[NUM_QDMA * NUM_PHYS_FUNC],
  axi_stream_if.master     m_axis_cmac[NUM_CMAC_PORT],
  input                    aclk,
  input                    aresetn
);

  localparam int NUM_MASTERS = NUM_QDMA * NUM_PHYS_FUNC + NUM_CMAC_PORT;

  wire [512*NUM_MASTERS-1:0] m_axis_tdata;
  wire [64*NUM_MASTERS-1:0]  m_axis_tkeep;
  wire [48*NUM_MASTERS-1:0]  m_axis_tuser;
  wire [NUM_MASTERS-1:0]     m_axis_tlast;
  wire [NUM_MASTERS-1:0]     m_axis_tvalid;
  wire [NUM_MASTERS-1:0]     m_axis_tready;

  generate
    for (genvar i = 0; i < NUM_QDMA; i++) begin
      for (genvar j = 0; j < NUM_PHYS_FUNC; j++) begin
        localparam int k = i * NUM_PHYS_FUNC + j;
        assign m_axis_pf[k].data      = m_axis_tdata[`getvec(512, k)];
        assign m_axis_pf[k].keep      = m_axis_tkeep[`getvec(64, k)];
        assign m_axis_pf[k].user_size = extract_user(m_axis_tuser[`getvec(48, k)], 0);
        assign m_axis_pf[k].user_src  = extract_user(m_axis_tuser[`getvec(48, k)], 1);
        assign m_axis_pf[k].user_dst  = extract_user(m_axis_tuser[`getvec(48, k)], 2);
        assign m_axis_pf[k].last      = m_axis_tlast[k];
        assign m_axis_pf[k].valid     = m_axis_tvalid[k];
        assign m_axis_tready[k]       = m_axis_pf[k].ready;
      end
    end
  endgenerate

  generate
    for (genvar i = 0; i < NUM_CMAC_PORT; i++) begin
      localparam int j = NUM_PHYS_FUNC + i;
      assign m_axis_cmac[i].data      = m_axis_tdata[`getvec(512, j)];
      assign m_axis_cmac[i].keep      = m_axis_tkeep[`getvec(64, j)];
      assign m_axis_cmac[i].user_size = extract_user(m_axis_tuser[`getvec(48, j)], 0);
      assign m_axis_cmac[i].user_src  = extract_user(m_axis_tuser[`getvec(48, j)], 1);
      assign m_axis_cmac[i].user_dst  = extract_user(m_axis_tuser[`getvec(48, j)], 2);
      assign m_axis_cmac[i].last      = m_axis_tlast[j];
      assign m_axis_cmac[i].valid     = m_axis_tvalid[j];
      assign m_axis_tready[j]         = m_axis_cmac[i].ready;
    end
  endgenerate

  reg [3:0]   reg_ingress_port;
  reg [3:0]   reg_egress_port;
  reg [15:0]  reg_user_size;
  wire [3:0]  ingress_port;
  wire [3:0]  egress_port;
  wire [15:0] user_size;
  wire [15:0] user_src;
  wire [15:0] user_dst;
  wire [47:0] s_axis_user;

  always_ff @(posedge aclk) begin
    if (!aresetn) begin
      reg_ingress_port <= 4'b1111;
      reg_egress_port <= 4'b1111;
      reg_user_size <= '0;
    end else begin
      if (s_axis.user_valid && !s_axis.last) begin
        reg_ingress_port <= s_axis.user_ingress_port;
        reg_egress_port <= s_axis.user_egress_port;
        reg_user_size <= s_axis.user_size;
      end else if (s_axis.last) begin
        reg_ingress_port <= 4'b1111;
        reg_egress_port <= 4'b1111;
        reg_user_size <= '0;
      end
    end
  end

  assign ingress_port = s_axis.user_valid ? s_axis.user_ingress_port : reg_ingress_port;
  assign egress_port  = s_axis.user_valid ? s_axis.user_egress_port : reg_egress_port;
  assign user_size    = s_axis.user_valid ? s_axis.user_size : reg_user_size;

  assign user_src = {decode_port_by_cmac(ingress_port), 2'b0, decode_port_by_pf(ingress_port)};
  assign user_dst = {decode_port_by_cmac(egress_port),  2'b0, decode_port_by_pf(egress_port)};
  assign s_axis_user = {user_dst, user_src, user_size};

  axis_egress_switch axis_egress_switch_inst (
    .s_axis_tvalid (s_axis.valid),
    .s_axis_tready (s_axis.ready),
    .s_axis_tdata  (s_axis.data),
    .s_axis_tkeep  (s_axis.keep),
    .s_axis_tlast  (s_axis.last),
    .s_axis_tdest  (egress_port),
    .s_axis_tuser  (s_axis_user),

    .m_axis_tvalid (m_axis_tvalid),
    .m_axis_tdata  (m_axis_tdata),
    .m_axis_tkeep  (m_axis_tkeep),
    .m_axis_tlast  (m_axis_tlast),
    .m_axis_tuser  (m_axis_tuser),
    .m_axis_tready (m_axis_tready),

    .aclk          (aclk),
    .aresetn       (aresetn),
  
    .s_decode_err()
  );

  function automatic logic [3:0] decode_port_by_pf(
    input logic [3:0] port
  );
    case (port)
      4'b0000: return 4'b0001;
      4'b0001: return 4'b0010;
      4'b0010: return 4'b0100;
      4'b0011: return 4'b1000;
      4'b0100: return 4'b0001;
      4'b0101: return 4'b0010;
      4'b0110: return 4'b0100;
      4'b0111: return 4'b1000;
      default: return 4'b0000;
    endcase
  endfunction

  function automatic logic [9:0] decode_port_by_cmac(
    input logic [3:0] port
  );
    case (port)
      4'b1000: return 10'b0000000001;
      4'b1001: return 10'b0000000010;
      default: return 10'b0000000000;
    endcase
  endfunction

  function automatic logic [15:0] extract_user(
    input logic [47:0] user,
    input int          i
  );
    return user[i*16 +: 16];
  endfunction

endmodule: egress_switch

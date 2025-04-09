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
    for (genvar x = 0; x < NUM_QDMA; x++) begin
      for (genvar y = 0; y < NUM_PHYS_FUNC; y++) begin
        localparam int index = x * NUM_PHYS_FUNC + y;
        assign m_axis_pf[index].data      = m_axis_tdata[`getvec(512, index)];
        assign m_axis_pf[index].keep      = m_axis_tkeep[`getvec(64, index)];
        assign m_axis_pf[index].user_size = extract_user(m_axis_tuser[`getvec(48, index)], 0);
        assign m_axis_pf[index].user_src  = extract_user(m_axis_tuser[`getvec(48, index)], 1);
        assign m_axis_pf[index].user_dst  = extract_user(m_axis_tuser[`getvec(48, index)], 2);
        assign m_axis_pf[index].last      = m_axis_tlast[index];
        assign m_axis_pf[index].valid     = m_axis_tvalid[index];
        assign m_axis_tready[index]       = m_axis_pf[index].ready;
      end
    end

    for (genvar x = 0; x < NUM_CMAC_PORT; x++) begin
      localparam int index = NUM_QDMA * NUM_PHYS_FUNC + x;
      assign m_axis_cmac[x].data      = m_axis_tdata[`getvec(512, index)];
      assign m_axis_cmac[x].keep      = m_axis_tkeep[`getvec(64, index)];
      assign m_axis_cmac[x].user_size = extract_user(m_axis_tuser[`getvec(48, index)], 0);
      assign m_axis_cmac[x].user_src  = extract_user(m_axis_tuser[`getvec(48, index)], 1);
      assign m_axis_cmac[x].user_dst  = extract_user(m_axis_tuser[`getvec(48, index)], 2);
      assign m_axis_cmac[x].last      = m_axis_tlast[index];
      assign m_axis_cmac[x].valid     = m_axis_tvalid[index];
      assign m_axis_tready[index]     = m_axis_cmac[x].ready;
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
    if (~aresetn) begin
      reg_ingress_port <= 4'b1111;
      reg_egress_port <= 4'b1111;
      reg_user_size <= '0;
    end else begin
      if (s_axis.user_valid && !s_axis.last) begin
        reg_ingress_port <= s_axis.user_ingress_port[3:0];
        reg_egress_port <= s_axis.user_egress_port[3:0];
        reg_user_size <= s_axis.user_size;
      end else if (s_axis.last) begin
        reg_ingress_port <= 4'b1111;
        reg_egress_port <= 4'b1111;
        reg_user_size <= '0;
      end
    end
  end

  assign ingress_port = s_axis.user_valid ? s_axis.user_ingress_port[3:0] : reg_ingress_port;
  assign egress_port  = s_axis.user_valid ? s_axis.user_egress_port[3:0] : reg_egress_port;
  assign user_size    = s_axis.user_valid ? s_axis.user_size : reg_user_size;

  assign user_src = decode_port(ingress_port);
  assign user_dst = decode_port(egress_port);
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

  function automatic logic [15:0] decode_port(
    input logic [3:0] port
  );
    case (port)
      4'b0000: return {10'b0000000000, 2'b00, 4'b0001};
      4'b0001: return {10'b0000000000, 2'b00, 4'b0010};
      4'b0010: return {10'b0000000000, 2'b00, 4'b0100};
      4'b0011: return {10'b0000000000, 2'b00, 4'b1000};
      4'b0100: return {10'b0000000000, 2'b00, 4'b0001};
      4'b0101: return {10'b0000000000, 2'b00, 4'b0010};
      4'b0110: return {10'b0000000000, 2'b00, 4'b0100};
      4'b0111: return {10'b0000000000, 2'b00, 4'b1000};
      4'b1000: return {10'b0000000001, 2'b00, 4'b0000};
      4'b1001: return {10'b0000000010, 2'b00, 4'b0000};
      default: return 16'b0;
    endcase
  endfunction

  function automatic logic [15:0] extract_user(
    input logic [47:0] user,
    input int          i
  );
    return user[i*16 +: 16];
  endfunction

endmodule: egress_switch

`timescale 1ns/1ps

import direction_pkg::is_pf;
import direction_pkg::is_cmac;

module egress_switch #(
  parameter int NUM_PHYS_FUNC = 1,
  parameter int NUM_CMAC_PORT = 1
) (
  axi_stream_vnp4_if.slave s_axis,
  axi_stream_if.master     m_axis_pf[NUM_PHYS_FUNC],
  axi_stream_if.master     m_axis_cmac[NUM_CMAC_PORT],
  input                    aclk,
  input                    aresetn
);

  axi_stream_vnp4_if axis_buff();
  reg is_buff_used;

  wire [3:0] pf_sel;
  wire [9:0] cmac_sel;
  assign pf_sel   = axis_buff.user_valid && is_pf(axis_buff.user_to_direction)   ? axis_buff.user_dst_pf   : '0;
  assign cmac_sel = axis_buff.user_valid && is_cmac(axis_buff.user_to_direction) ? axis_buff.user_dst_cmac : '0;

  wire dst_ready;
  wire [NUM_PHYS_FUNC-1:0] pf_ready;
  wire [NUM_CMAC_PORT-1:0] cmac_ready;

  generate
    for (genvar i = 0; i < NUM_PHYS_FUNC; i++) begin
      assign pf_ready[i] = m_axis_pf[i].ready && pf_sel[i];
    end
    for (genvar i = 0; i < NUM_CMAC_PORT; i++) begin
      assign cmac_ready[i] = m_axis_cmac[i].ready && cmac_sel[i];
    end
  endgenerate

  assign dst_ready = |pf_ready || |cmac_ready;

  always_ff @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      is_buff_used <= 1'b0;
      axis_buff.valid <= 1'b0;
      axis_buff.user_valid <= 1'b0;
    end else begin
      if (s_axis.valid && s_axis.user_valid && !is_buff_used) begin
        is_buff_used <= 1'b1;
        axis_buff.valid <= 1'b1;
        axis_buff.data <= s_axis.data;
        axis_buff.keep <= s_axis.keep;
        axis_buff.last <= s_axis.last;
        axis_buff.user_valid <= 1'b1;
        axis_buff.user_size <= s_axis.user_size;
        axis_buff.user_src_pf <= s_axis.user_src_pf;
        axis_buff.user_src_cmac <= s_axis.user_src_cmac;
        axis_buff.user_dst_pf <= s_axis.user_dst_pf;
        axis_buff.user_dst_cmac <= s_axis.user_dst_cmac;
        axis_buff.user_to_direction <= s_axis.user_to_direction;
      end else if (axis_buff.valid && dst_ready) begin
        is_buff_used <= 1'b0;
        axis_buff.valid <= 1'b0;
        axis_buff.user_valid <= 1'b0;
      end
    end
  end

  assign s_axis.ready = !is_buff_used;

  generate
    for (genvar i = 0; i < NUM_PHYS_FUNC; i++) begin
      assign m_axis_pf[i].valid     = axis_buff.valid && pf_sel[i];
      assign m_axis_pf[i].data      = axis_buff.data;
      assign m_axis_pf[i].keep      = axis_buff.keep;
      assign m_axis_pf[i].last      = axis_buff.last;
      assign m_axis_pf[i].user_size = axis_buff.user_size;
      assign m_axis_pf[i].user_src  = {axis_buff.user_src_cmac, 2'b0, axis_buff.user_src_pf};
      assign m_axis_pf[i].user_dst  = {axis_buff.user_dst_cmac, 2'b0, axis_buff.user_dst_pf};
    end

    for (genvar i = 0; i < NUM_CMAC_PORT; i++) begin
      assign m_axis_cmac[i].valid     = axis_buff.valid && cmac_sel[i];
      assign m_axis_cmac[i].data      = axis_buff.data;
      assign m_axis_cmac[i].keep      = axis_buff.keep;
      assign m_axis_cmac[i].last      = axis_buff.last;
      assign m_axis_cmac[i].user_size = axis_buff.user_size;
      assign m_axis_cmac[i].user_src  = {axis_buff.user_src_cmac, 2'b0, axis_buff.user_src_pf};
      assign m_axis_cmac[i].user_dst  = {axis_buff.user_dst_cmac, 2'b0, axis_buff.user_dst_pf};
    end
  endgenerate

endmodule

`timescale 1ns/1ps

`include "open_nic_shell_macros.vh"

module axi_stream_if_m_connector #(
  parameter int COUNTS = 1
) (
  axi_stream_if.slave s_axis[COUNTS],

  output     [COUNTS-1:0] m_axis_tvalid,
  output [512*COUNTS-1:0] m_axis_tdata,
  output  [64*COUNTS-1:0] m_axis_tkeep,
  output     [COUNTS-1:0] m_axis_tlast,
  output  [16*COUNTS-1:0] m_axis_tuser_size,
  output  [16*COUNTS-1:0] m_axis_tuser_src,
  output  [16*COUNTS-1:0] m_axis_tuser_dst,
  input      [COUNTS-1:0] m_axis_tready
);

  generate for (genvar i = 0; i < COUNTS; i++) begin
    assign m_axis_tvalid[i]                  = s_axis[i].valid;
    assign m_axis_tlast[i]                   = s_axis[i].last;

    assign m_axis_tdata[`getvec(512, i)]     = s_axis[i].data;
    assign m_axis_tkeep[`getvec(64, i)]      = s_axis[i].keep;

    assign m_axis_tuser_size[`getvec(16, i)] = s_axis[i].user_size;
    assign m_axis_tuser_src[`getvec(16, i)]  = s_axis[i].user_src;
    assign m_axis_tuser_dst[`getvec(16, i)]  = s_axis[i].user_dst;

    assign s_axis[i].ready                   = m_axis_tready[i];
  end endgenerate

endmodule: axi_stream_if_m_connector

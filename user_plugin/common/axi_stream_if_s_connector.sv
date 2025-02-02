`timescale 1ns/1ps

`include "open_nic_shell_macros.vh"

module axi_stream_if_s_connector #(
  parameter int COUNTS = 1
) (
  input      [COUNTS-1:0] s_axis_tvalid,
  input  [512*COUNTS-1:0] s_axis_tdata,
  input   [64*COUNTS-1:0] s_axis_tkeep,
  input      [COUNTS-1:0] s_axis_tlast,
  input   [16*COUNTS-1:0] s_axis_tuser_size,
  input   [16*COUNTS-1:0] s_axis_tuser_src,
  input   [16*COUNTS-1:0] s_axis_tuser_dst,
  output     [COUNTS-1:0] s_axis_tready,

  axi_stream_if.master m_axis[COUNTS]
);

  generate for (genvar i = 0; i < COUNTS; i++) begin
    assign m_axis[i].valid     = s_axis_tvalid[i];
    assign m_axis[i].last      = s_axis_tlast[i];

    assign m_axis[i].data      = s_axis_tdata[`getvec(512, i)];
    assign m_axis[i].keep      = s_axis_tkeep[`getvec(64, i)];

    assign m_axis[i].user_size = s_axis_tuser_size[`getvec(16, i)];
    assign m_axis[i].user_src  = s_axis_tuser_src[`getvec(16, i)];
    assign m_axis[i].user_dst  = s_axis_tuser_dst[`getvec(16, i)];

    assign s_axis_tready[i]    = m_axis[i].ready;
  end endgenerate

endmodule: axi_stream_if_s_connector

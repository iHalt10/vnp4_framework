
interface axi_stream_vnp4_if;
  logic         valid;
  logic [511:0] data;
  logic [63:0]  keep;
  logic         last;
  logic         user_valid;
  logic [15:0]  user_size;
  logic [3:0]   user_src_pf;
  logic [9:0]   user_src_cmac;
  logic [3:0]   user_dst_pf;
  logic [9:0]   user_dst_cmac;
  logic         user_from_direction;
  logic         user_to_direction;
  logic         ready;

  modport master (
    output valid, data, keep, last,
           user_valid, user_size,
           user_src_pf, user_src_cmac,
           user_dst_pf, user_dst_cmac,
           user_from_direction, user_to_direction,
    input  ready
  );

  modport slave (
    input  valid, data, keep, last,
           user_valid, user_size,
           user_src_pf, user_src_cmac,
           user_dst_pf, user_dst_cmac,
           user_from_direction, user_to_direction,
    output ready
  );

endinterface: axi_stream_vnp4_if

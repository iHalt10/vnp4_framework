
interface axi_stream_if;
  logic         valid;
  logic [511:0] data;
  logic [63:0]  keep;
  logic         last;
  logic [15:0]  user_size;
  logic [15:0]  user_src;
  logic [15:0]  user_dst;
  logic         ready;

  modport master (
    output valid, data, keep, last, user_size, user_src, user_dst,
    input  ready
  );

  modport slave (
    input  valid, data, keep, last, user_size, user_src, user_dst,
    output ready
  );

endinterface: axi_stream_if

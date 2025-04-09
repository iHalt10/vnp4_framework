
interface axi_stream_vnp4_if;
  logic         valid;
  logic [511:0] data;
  logic [63:0]  keep;
  logic         last;
  logic         user_valid;
  logic [15:0]  user_size;
  logic [8:0]   user_ingress_port;
  logic [8:0]   user_egress_port;
  logic         ready;

  modport master (
    output valid, data, keep, last,
           user_valid, user_size,
           user_ingress_port, user_egress_port,
    input  ready
  );

  modport slave (
    input  valid, data, keep, last,
           user_valid, user_size,
           user_ingress_port, user_egress_port,
    output ready
  );

endinterface: axi_stream_vnp4_if

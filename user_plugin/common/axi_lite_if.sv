
interface axi_lite_if;
  // Read Address Channel
  logic [31:0] ar_addr;
  logic        ar_ready;
  logic        ar_valid;

   // Write Address Channel
  logic [31:0] aw_addr;
  logic        aw_ready;
  logic        aw_valid;

  // Write Response Channel
  logic        b_ready;
  logic [1:0]  b_resp;
  logic        b_valid;

  // Read Data Channel
  logic [31:0] r_data;
  logic        r_ready;
  logic [1:0]  r_resp;
  logic        r_valid;

  // Write Data Channel
  logic [31:0] w_data;
  logic        w_ready;
  logic        w_valid;

  modport master (
    output ar_addr, ar_valid, aw_addr, aw_valid, b_ready, r_ready, w_data, w_valid,
    input  ar_ready, aw_ready, b_resp, b_valid, r_data, r_resp, r_valid, w_ready
  );

  modport slave (
    input  ar_addr, ar_valid, aw_addr, aw_valid, b_ready, r_ready, w_data, w_valid,
    output ar_ready, aw_ready, b_resp, b_valid, r_data, r_resp, r_valid, w_ready
  );

endinterface: axi_lite_if
